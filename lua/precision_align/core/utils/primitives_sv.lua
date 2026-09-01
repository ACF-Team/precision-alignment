-- Serverside handler for the Primitives tab: spawns a primitive_shape or primitive_convex_hull entity from the client's selected PA points and shape choice.

local PA_ = PrecisionAlign.PA_

util.AddNetworkString( PA_ .. "primitive" )

local nextSpawn = {}

-- Rotates `ang` so that `from` (a local axis on the not-yet-rotated entity) points along `to` (world-space).
local function alignAxis( ang, from, to )
	local axis = from:Cross( to )
	if axis:LengthSqr() < 1e-12 then return ang end
	axis:Normalize()

	local dot = math.Clamp( from:Dot( to ), -1, 1 )
	local angle = math.deg( math.acos( dot ) )

	ang:RotateAroundAxis( axis, angle )
	return ang
end

-- Derives a flat box's placement from PA points: edge 1-2 and point 3's plane set the axes, extra points extend the footprint, thickness is fixed.
local function ComputePlatePlacement( points, extendToAllPoints )
	local P1, P2, P3 = points[1], points[2], points[3]

	local D1 = ( P2 - P1 ):GetNormalized()
	local D2 = ( P3 - P1 ):GetNormalized()
	local normal = D1:Cross( D2 )
	if normal:LengthSqr() < 1e-12 then return end -- points are collinear, no plane to build on

	normal:Normalize()

	-- In-plane direction perpendicular to D1, pointing toward P3's side.
	local widthDir = normal:Cross( D1 )
	widthDir:Normalize()
	if widthDir:Dot( D2 ) < 0 then widthDir = -widthDir end

	-- Project every point onto the two in-plane axes and track the bounds along each.
	local uMin, uMax, vMin, vMax = 0, 0, 0, 0
	local count = extendToAllPoints and #points or 3

	for i = 1, count do
		local offset = points[i] - P1
		local u = offset:Dot( D1 )
		local v = offset:Dot( widthDir )

		if u < uMin then uMin = u elseif u > uMax then uMax = u end
		if v < vMin then vMin = v elseif v > vMax then vMax = v end
	end

	local minSize = Primitive and Primitive.minSize or 1
	local length = math.max( uMax - uMin, minSize )
	local width = math.max( vMax - vMin, minSize )
	local thickness = PrecisionAlign.PRIMITIVE_CUBE_THICKNESS

	-- Center of the footprint on the P1/P2/P3 plane, extruded half the (fixed) thickness along +normal.
	local center = P1 + D1 * ( ( uMin + uMax ) * 0.5 ) + widthDir * ( ( vMin + vMax ) * 0.5 ) + normal * ( thickness * 0.5 )

	return length, width, thickness, normal, D1, center
end

-- Like ComputePlatePlacement, but also derives thickness from the points' spread along the plane's normal.
local function ComputeCubePlacement( points )
	local P1, P2, P3 = points[1], points[2], points[3]

	local D1 = ( P2 - P1 ):GetNormalized()
	local D2 = ( P3 - P1 ):GetNormalized()
	local normal = D1:Cross( D2 )
	if normal:LengthSqr() < 1e-12 then return end -- points are collinear, no plane to build on

	normal:Normalize()

	local widthDir = normal:Cross( D1 )
	widthDir:Normalize()
	if widthDir:Dot( D2 ) < 0 then widthDir = -widthDir end

	-- Track bounds on all 3 axes; wExtra sums points 4+ along `normal` to tell which side of the plane they're on.
	local uMin, uMax, vMin, vMax, wMin, wMax = 0, 0, 0, 0, 0, 0
	local wExtra = 0

	for i = 1, #points do
		local offset = points[i] - P1
		local u = offset:Dot( D1 )
		local v = offset:Dot( widthDir )
		local w = offset:Dot( normal )

		if u < uMin then uMin = u elseif u > uMax then uMax = u end
		if v < vMin then vMin = v elseif v > vMax then vMax = v end
		if w < wMin then wMin = w elseif w > wMax then wMax = w end

		if i > 3 then wExtra = wExtra + w end
	end

	local minSize = Primitive and Primitive.minSize or 1
	local length = math.max( uMax - uMin, minSize )
	local width = math.max( vMax - vMin, minSize )
	local thickness = math.max( wMax - wMin, minSize )

	local center = P1 + D1 * ( ( uMin + uMax ) * 0.5 ) + widthDir * ( ( vMin + vMax ) * 0.5 ) + normal * ( ( wMin + wMax ) * 0.5 )

	-- Flip so local +dz (base-to-peak) points towards the extra points, not wherever winding order put `normal`.
	local alignNormal = wExtra < 0 and -normal or normal

	return length, width, thickness, alignNormal, D1, center
end

-- Builds a Spawn( ply, points ) function for a box-inscribed primitive_shape type, given its placement function.
local function spawnBoxShape( shapeType, computePlacement )
	return function( ply, points )
		if not scripted_ents.GetStored( "primitive_shape" ) then
			Warning( "Precision Alignment: primitive_shape entity is not registered, is the \"primitive\" addon installed?\n" )
			return
		end

		if scripted_ents.GetMember( "primitive_shape", "AdminOnly" ) and not ply:IsAdmin() then return end
		if not gamemode.Call( "PlayerSpawnProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl" ) then return end
		if not ply:CheckLimit( "props" ) then return end

		local length, width, thickness, normal, D1, center = computePlacement( points )
		if not length then return end

		local ent = ents.Create( "primitive_shape" )
		if not IsValid( ent ) then return end

		ent:SetPos( center )
		ent:SetAngles( Angle( 0, 0, 0 ) )
		ent:Spawn()
		ent:Activate()

		if isfunction( ent.PrimitiveSetup ) then
			ent:PrimitiveSetup( true, { shapeType, true, 48 } )
		end

		ent:SetPrimSIZE( Vector( width, length, thickness ) )

		local ang = Angle( 0, 0, 0 )
		ang = alignAxis( ang, ang:Up(), normal )
		ang = alignAxis( ang, ang:Right(), -D1 )
		ent:SetAngles( ang )

		ent:SetVar( "Player", ply )
		ply:AddCount( "props", ent )
		ply:AddCleanup( "primitive", ent )

		undo.Create( "primitive" )
			undo.SetPlayer( ply )
			undo.AddEntity( ent )
			undo.SetCustomUndoText( "Undone primitive ( primitive_shape " .. shapeType .. " )" )
		undo.Finish( "primitive ( primitive_shape " .. shapeType .. " )" )

		DoPropSpawnedEffect( ent )

		gamemode.Call( "PlayerSpawnedProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl", ent )
	end
end

local function spawnConvexHull( ply, points )
	if not scripted_ents.GetStored( "primitive_convex_hull" ) then
		Warning( "Precision Alignment: primitive_convex_hull entity is not registered, is the \"primitive\" addon installed?\n" )
		return
	end

	if scripted_ents.GetMember( "primitive_convex_hull", "AdminOnly" ) and not ply:IsAdmin() then return end
	if not gamemode.Call( "PlayerSpawnProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl" ) then return end
	if not ply:CheckLimit( "props" ) then return end

	local count = #points

	-- centroid becomes the entity's own position; vertices are stored relative to it
	local centroid = Vector( 0, 0, 0 )
	for i = 1, count do
		centroid = centroid + points[i]
	end
	centroid = centroid / count

	local ent = ents.Create( "primitive_convex_hull" )
	if not IsValid( ent ) then return end

	ent:SetPos( centroid )
	ent:SetAngles( Angle( 0, 0, 0 ) )
	ent:Spawn()
	ent:Activate()

	if isfunction( ent.PrimitiveSetup ) then
		ent:PrimitiveSetup( true )
	end

	ent:SetPrimPOINTS( count )
	for i = 1, count do
		local local_point = points[i] - centroid

		ent[ "SetPrimPX" .. i ]( ent, local_point.x )
		ent[ "SetPrimPY" .. i ]( ent, local_point.y )
		ent[ "SetPrimPZ" .. i ]( ent, local_point.z )
	end

	ent:SetVar( "Player", ply )
	ply:AddCount( "props", ent )
	ply:AddCleanup( "primitive", ent )

	undo.Create( "primitive" )
		undo.SetPlayer( ply )
		undo.AddEntity( ent )
		undo.SetCustomUndoText( "Undone primitive ( primitive_convex_hull )" )
	undo.Finish( "primitive ( primitive_convex_hull )" )

	DoPropSpawnedEffect( ent )

	gamemode.Call( "PlayerSpawnedProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl", ent )
end

PrecisionAlign.PRIMITIVE_TYPES.plate.Spawn = spawnBoxShape( "cube", function( points ) return ComputePlatePlacement( points, true ) end )
PrecisionAlign.PRIMITIVE_TYPES.cube.Spawn = spawnBoxShape( "cube", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.wedge.Spawn = spawnBoxShape( "wedge", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.pyramid.Spawn = spawnBoxShape( "pyramid", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.plane.Spawn = spawnBoxShape( "plane", ComputePlatePlacement )
PrecisionAlign.PRIMITIVE_TYPES.cube_hole.Spawn = spawnBoxShape( "cube_hole", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.dome_hollow.Spawn = spawnBoxShape( "dome_hollow", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.cone.Spawn = spawnBoxShape( "cone", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.cube_magic.Spawn = spawnBoxShape( "cube_magic", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.cylinder.Spawn = spawnBoxShape( "cylinder", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.dome.Spawn = spawnBoxShape( "dome", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.parallelogram.Spawn = spawnBoxShape( "parallelogram", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.sphere.Spawn = spawnBoxShape( "sphere", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.torus.Spawn = spawnBoxShape( "torus", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.tube.Spawn = spawnBoxShape( "tube", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.wedge_corner.Spawn = spawnBoxShape( "wedge_corner", ComputeCubePlacement )
PrecisionAlign.PRIMITIVE_TYPES.convex_hull.Spawn = spawnConvexHull

net.Receive( PA_ .. "primitive", function( _, ply )
	local id = net.ReadString()
	local count = net.ReadUInt( 8 )

	local entry = PrecisionAlign.PRIMITIVE_TYPES[id]
	if not entry or not entry.Spawn then return end
	if count < entry.minPoints or count > entry.maxPoints then return end

	if ( nextSpawn[ply] or 0 ) > SysTime() then return end
	nextSpawn[ply] = SysTime() + PrecisionAlign.PRIMITIVE_SPAWN_COOLDOWN

	local points = {}
	for i = 1, count do
		points[i] = net.ReadVector()
	end

	entry.Spawn( ply, points )
end )
