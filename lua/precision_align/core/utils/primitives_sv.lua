-- Serverside handler for the "Primitives" manipulation panel tab: takes a list of
-- world-space points the client picked from its PA point stack and spawns a
-- primitive_convex_hull entity (from the separate "primitive" addon) using them
-- as vertices. Soft dependency: if that addon isn't loaded, the net message
-- just gets dropped, since the primitive_convex_hull class won't exist to check for.

local PA, PA_ = PrecisionAlign.PA, PrecisionAlign.PA_

util.AddNetworkString( PA_ .. "primitive" )

local MIN_POINTS = 4
local MAX_POINTS = 10

net.Receive( PA_ .. "primitive", function( _, ply )
	local count = net.ReadUInt( 8 )
	if count < MIN_POINTS or count > MAX_POINTS then return end

	local points = {}
	for i = 1, count do
		points[i] = net.ReadVector()
	end

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
end )
