-- Serverside handler for the Primitives tab: spawns a primitive_shape cube (3 points) or primitive_convex_hull (4-10 points) from the "primitive" addon at the client's selected PA points.

local PA_ = PrecisionAlign.PA_

util.AddNetworkString( PA_ .. "primitive" )

local MIN_POINTS = 3
local MAX_POINTS = 10
local CUBE_POINTS = 3

local nextSpawn = {}

-- Heron's formula: triangle area from its 3 side lengths.
local function herons( a, b, c )
	return 0.25 * math.sqrt( 4 * a ^ 2 * b ^ 2 - ( a ^ 2 + b ^ 2 - c ^ 2 ) ^ 2 )
end

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

local function spawnCube( ply, points )
	if not scripted_ents.GetStored( "primitive_shape" ) then
		Warning( "Precision Alignment: primitive_shape entity is not registered, is the \"primitive\" addon installed?\n" )
		return
	end

	if scripted_ents.GetMember( "primitive_shape", "AdminOnly" ) and not ply:IsAdmin() then return end
	if not gamemode.Call( "PlayerSpawnProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl" ) then return end
	if not ply:CheckLimit( "props" ) then return end

	local P1, P2, P3 = points[1], points[2], points[3]

	local D1 = ( P2 - P1 ):GetNormalized()
	local D2 = ( P3 - P1 ):GetNormalized()
	local normal = D1:Cross( D2 )
	if normal:LengthSqr() < 1e-12 then return end -- points are collinear, no plane to build a cube on
	normal:Normalize()

	local S1 = P1:Distance( P2 )
	local S2 = P2:Distance( P3 )
	local S3 = P3:Distance( P1 )
	local area = herons( S1, S2, S3 )

	local length = S1
	local width = length > 0 and ( 2 * area / length ) or 0

	local edge = P2 - P1
	local S4 = edge:Length() > 0 and ( ( P3 - P1 ):Dot( edge ) / edge:Length() ) or 0
	length = math.max( length, S4 )

	local minSize = Primitive and Primitive.minSize or 1
	length = math.max( length, minSize )
	width = math.max( width, minSize )

	local thickness = PrecisionAlign.PRIMITIVE_CUBE_THICKNESS

	-- In-plane direction perpendicular to D1, pointing toward P3's side.
	local widthDir = normal:Cross( D1 )
	widthDir:Normalize()
	if widthDir:Dot( D2 ) < 0 then widthDir = -widthDir end

	-- Box is symmetric about its center, so compute the center directly instead of via a local corner.
	-- Extrude entirely to the +normal side, so the P1/P2/P3 winding order picks which face the points define.
	local center = P1 + D1 * ( length * 0.5 ) + widthDir * ( width * 0.5 ) + normal * ( thickness * 0.5 )

	local ent = ents.Create( "primitive_shape" )
	if not IsValid( ent ) then return end

	ent:SetPos( center )
	ent:SetAngles( Angle( 0, 0, 0 ) )
	ent:Spawn()
	ent:Activate()

	if isfunction( ent.PrimitiveSetup ) then
		ent:PrimitiveSetup( true, { "cube", true, 48 } )
	end

	ent:SetPrimSIZE( Vector( length, width, thickness ) )

	local ang = Angle( 0, 0, 0 )
	ang = alignAxis( ang, ang:Up(), normal )
	ang = alignAxis( ang, ang:Forward(), D1 )
	ent:SetAngles( ang )

	ent:SetVar( "Player", ply )
	ply:AddCount( "props", ent )
	ply:AddCleanup( "primitive", ent )

	undo.Create( "primitive" )
		undo.SetPlayer( ply )
		undo.AddEntity( ent )
		undo.SetCustomUndoText( "Undone primitive ( primitive_shape cube )" )
	undo.Finish( "primitive ( primitive_shape cube )" )

	DoPropSpawnedEffect( ent )

	gamemode.Call( "PlayerSpawnedProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl", ent )
end

local function spawnConvexHull( ply, points, count )
	if not scripted_ents.GetStored( "primitive_convex_hull" ) then
		Warning( "Precision Alignment: primitive_convex_hull entity is not registered, is the \"primitive\" addon installed?\n" )
		return
	end

	if scripted_ents.GetMember( "primitive_convex_hull", "AdminOnly" ) and not ply:IsAdmin() then return end
	if not gamemode.Call( "PlayerSpawnProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl" ) then return end
	if not ply:CheckLimit( "props" ) then return end

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

net.Receive( PA_ .. "primitive", function( _, ply )
	local count = net.ReadUInt( 8 )
	if count < MIN_POINTS or count > MAX_POINTS then return end

	if ( nextSpawn[ply] or 0 ) > SysTime() then return end
	nextSpawn[ply] = SysTime() + PrecisionAlign.PRIMITIVE_SPAWN_COOLDOWN

	local points = {}
	for i = 1, count do
		points[i] = net.ReadVector()
	end

	if count == CUBE_POINTS then
		spawnCube( ply, points )
	else
		spawnConvexHull( ply, points, count )
	end
end )
