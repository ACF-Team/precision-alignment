// Precision Alignment STool code - By Wenli

TOOL.Category		= "Constraints"
TOOL.Name			= "#Tool.precision_align.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

local PA = "precision_align"
local PA_ = PA .. "_"

AddCSLuaFile( PA.."/ui.lua" )
AddCSLuaFile( PA.."/manipulation_panel.lua" )
AddCSLuaFile( PA.."/prop_functions.lua" )
AddCSLuaFile( PA.."/tool_screen.lua" )

include( "weapons/gmod_tool/stools/"..PA.."/tool_screen.lua" )

TOOL.ClientConVar =
{
	// Tool menu options
	["edge_snap"] 			= "1",
	["centre_snap"] 		= "1",
	["snap_distance"] 		= "100",
	["display_messages"] 	= "0",
	["display_warnings"] 	= "1",
	["tooltype"]			= "1",
	["draw_attachments"]	= "0",
	["default_linelength"]	= "200",
	
	// Construct draw sizes
	["size_point"]			= "5",
	["size_line_start"]		= "4",
	["size_line_end"]		= "4",
	["size_plane"]			= "10",
	["size_plane_normal"]	= "20",
	
	// Ent Selection colour
	["selectcolour_h"]		= "230",
	["selectcolour_s"]		= "0.6",
	["selectcolour_v"]		= "1",
	["selectcolour_a"]		= "255",
	
	// Attachment line colour
	["attachcolour_h"]		= "120",
	["attachcolour_s"]		= "1",
	["attachcolour_v"]		= "1",
	["attachcolour_a"]		= "150",
	
	// Constraints
	["axis_forcelimit"]		= "0",
	["axis_torquelimit"]	= "0",
	["axis_friction"]		= "0",
	["axis_nocollide"]		= "0",
	
	["ballsocket_forcelimit"]	= "0",
	["ballsocket_torquelimit"]	= "0",
	["ballsocket_nocollide"]	= "0",
	
	["ballsocket_adv_forcelimit"]	= "0",
	["ballsocket_adv_torquelimit"]	= "0",
	["ballsocket_adv_xmin"]			= "-180",
	["ballsocket_adv_ymin"]			= "-180",
	["ballsocket_adv_zmin"]			= "-180",
	["ballsocket_adv_xmax"]			= "180",
	["ballsocket_adv_ymax"]			= "180",
	["ballsocket_adv_zmax"]			= "180",
	["ballsocket_adv_xfric"]		= "0",
	["ballsocket_adv_yfric"]		= "0",
	["ballsocket_adv_zfric"]		= "0",
	["ballsocket_adv_onlyrotation"]	= "0",
	["ballsocket_adv_nocollide"]	= "0",
	
	["elastic_constant"]	= "100",
	["elastic_damping"]		= "0",
	["elastic_rdamping"]	= "0",
	["elastic_material"]	= "cable/rope",
	["elastic_width"]		= "1",
	["elastic_stretchonly"]	= "0",
	
	["rope_forcelimit"]		= "0",
	["rope_addlength"]		= "0",
	["rope_width"]			= "1",
	["rope_material"]		= "cable/rope",
	["rope_rigid"]			= "0",
	["rope_setlength"]		= "0",
	
	["slider_width"]		= "1",
	
	["wire_hydraulic_width"]	= "1",
	["wire_hydraulic_material"]	= "cable/rope",
	
	// Stack number
	["stack_num"]			= "1",
	["stack_nocollide"]		= "0"
}

// Client

if CLIENT then
	precision_align_points = {}
	precision_align_lines = {}
	precision_align_planes = {}
	
	pointcolour = { r = 255, g = 0, b = 0, a = 255 }
	linecolour = { r = 0, g = 0, b = 255, a = 255 }
	planecolour = { r = 0, g = 230, b = 0, a = 255 }
	
	
	// Initialize tables, set defaults
	for i = 1, 9 do
		precision_align_points[i] = {visible = true}
		precision_align_lines[i] = {visible = true}
		precision_align_planes[i] = {visible = true}
	end
	
	language.Add("Tool.precision_align.name", "Precision Alignment")
	language.Add("Tool.precision_align.desc", "Precision prop alignment tool")
	language.Add("Tool.precision_align.0", "Primary: Place constructs, Secondary: Select entity, Reload: Open/close manipulation window")
	language.Add("Tool.precision_align.1", "Click again to place line end point, right click to cancel")
	
	language.Add("Undone_precision_align", "Undone Precision Align")
end

// Tool functions

if SERVER then
	function TOOL:SendClickData( point, normal, ent )
		net.Start( PA_ .. "click" )
		
		// Send vectors using floats - was losing precision using just vectors
		net.WriteFloat( point.x )
		net.WriteFloat( point.y )
		net.WriteFloat( point.z )
		
		net.WriteFloat( normal.x )
		net.WriteFloat( normal.y )
		net.WriteFloat( normal.z )
		
		net.WriteEntity( ent )
		
		net.Send( self:GetOwner() )
	end
	
	function TOOL:SendEntityData( ent )
		net.Start( PA_ .. "ent" )
		net.WriteEntity( ent )
		net.Send( self:GetOwner() )
	end
	
	function TOOL:SetActive( ent )
		local ply = self:GetOwner()
		local activeent = ply.PA_activeent
		
		local function Deselect( ent )
			if IsValid( ent ) and ent.PA then
				local colour = ent.PA.TrueColour
				
				if colour then
					ent:SetColor(  colour  )
				end
				
				ent.PA.Ply.PA_activeent = nil
				ent.PA = nil
			end
		end
		
		// Deselect last ent
		if activeent then
			Deselect( activeent )
		end
		
		// Select new ent
		if IsValid( ent ) then
			// Check for existing player selection
			if ent.PA then
				Deselect( ent )
			end
			
			ply.PA_activeent = ent
			ent.PA = {}
			ent.PA.Ply = ply
			
			local TrueColour = ent:GetColor()
			ent.PA.TrueColour = TrueColour
			
			local H = ply:GetInfoNum( PA_ .. "selectcolour_h", 230 )
			local S = ply:GetInfoNum( PA_ .. "selectcolour_s", 0.6 )
			local V = ply:GetInfoNum( PA_ .. "selectcolour_v", 1 )
			local A = ply:GetInfoNum( PA_ .. "selectcolour_a", 255 )
			
			local highlight = HSVToColor( H, S, V )
			highlight.a = A
			ent:SetColor(highlight)
			if A < 255 then ent:SetRenderMode( RENDERMODE_TRANSALPHA ) end
			duplicator.StoreEntityModifier( ent, "colour", { Color = TrueColour } )
			
			self:SendEntityData( ent )
			return true
		else
			ply.PA_activeent = nil
			
			self:SendEntityData()
			return false
		end
	end
end

// Build CPanel
if CLIENT then
	function TOOL.BuildCPanel( pnl )
		include( "weapons/gmod_tool/stools/"..PA.."/ui.lua" )
	end
	
	local BuildCPanel = TOOL.BuildCPanel
	local function reloadui_func()
		local CPanel = controlpanel.Get( PA )
		CPanel:Clear()
		
		BuildCPanel( CPanel )
		
		include( "weapons/gmod_tool/stools/"..PA.."/tool_screen.lua" )
		
		MsgAll("Reloading UI\n")
	end
	concommand.Add( PA_.."reloadui", reloadui_func )
end
	
// Calculate local position of nearest edge
local function Nearest_Edge( HitPosL, BoxMin, BoxMax, BoxCentre, Snap_Dist )
	local EdgePosL = Vector( HitPosL.x, HitPosL.y, HitPosL.z )
	
	// This is used to kee
	local Snapped_Edges = {}
	
	local function Find_Edge( k )
		if ( HitPosL[k] > BoxCentre[k] and ( BoxMax[k] - Snap_Dist ) <= HitPosL[k] ) then
			EdgePosL[k] = BoxMax[k]
			Snapped_Edges[k] = true
		elseif ( HitPosL[k] < BoxCentre[k] and ( BoxMin[k] + Snap_Dist ) >= HitPosL[k] ) then
			EdgePosL[k] = BoxMin[k]
			Snapped_Edges[k] = true
		end
	end
	
	Find_Edge( "x" )
	Find_Edge( "y" )
	Find_Edge( "z" )
		
	return EdgePosL, Snapped_Edges
end

function TOOL:GetClickPosition( trace )
	local pos
	local Ent = trace.Entity
	local Phys = Ent:GetPhysicsObjectNum( trace.PhysicsBone )
	local Edge_Snap = self:GetClientNumber( "edge_snap" ) ~= 0
	local Centre_Snap = self:GetClientNumber( "centre_snap" ) ~= 0
	local Snap_Dist = math.max(0, self:GetClientNumber( "snap_distance" ))
	
	local tooltype = self:GetClientNumber( "tooltype" )
	
	if ( !Phys or !Ent or Ent:IsWorld() ) then
		Pos = trace.HitPos
	
	// Coordinate Centre
	elseif tooltype == 2 then
		Pos = Ent:GetPos()
		
	// Mass Centre
	elseif tooltype == 3 then
		Pos = Ent:LocalToWorld(Phys:GetMassCenter())
		
	// BB Centre
	elseif tooltype == 4 then
		Pos = Ent:LocalToWorld(Ent:OBBCenter())
	
	elseif Edge_Snap or Centre_Snap then
		local HitPosL = Ent:WorldToLocal( trace.HitPos )
		local BoxMin, BoxMax = Phys:GetAABB()
		local BoxCentre = Ent:OBBCenter()
		
		local NewPosL = Vector( HitPosL.x, HitPosL.y, HitPosL.z )
		
		local EdgePosL, Edge_Dist
		local CentrePosL, Centre_Dist
		
		// These keep track of whether the point is being snapped to an edge or centre line
		local Snapped_Edges = {}
		local Snapped_Centres = {}
		
		// Calculate local position of nearest edge
		if Edge_Snap then
			EdgePosL, Snapped_Edges = Nearest_Edge( HitPosL, BoxMin, BoxMax, BoxCentre, Snap_Dist )
			NewPosL = EdgePosL
			
		// We need at least some edge snap if using Centre_Snap, else NewPosL will snap away from the surface being clicked on
		elseif Centre_Snap then
			EdgePosL, Snapped_Edges = Nearest_Edge( HitPosL, BoxMin, BoxMax, BoxCentre, 0.1 )
			NewPosL = EdgePosL
		end
		
		// Calculate local position of nearest centre line
		if Centre_Snap then
			CentrePosL = Vector( HitPosL.x, HitPosL.y, HitPosL.z )
			
			if math.abs( CentrePosL.x - BoxCentre.x ) < Snap_Dist then
				CentrePosL.x = BoxCentre.x
				Snapped_Centres.x = true
			end
			
			if math.abs( CentrePosL.y - BoxCentre.y ) < Snap_Dist then
				CentrePosL.y = BoxCentre.y
				Snapped_Centres.y = true
			end
			
			if math.abs( CentrePosL.z - BoxCentre.z ) < Snap_Dist then
				CentrePosL.z = BoxCentre.z
				Snapped_Centres.z = true
			end
			
			NewPosL = CentrePosL
			
			Edge_Dist = EdgePosL - HitPosL
			Centre_Dist = CentrePosL - HitPosL
			
			// NewPosL is already equal to CentrePosL, so only need to set cases where EdgePosL is smaller
			if ( math.abs( Edge_Dist.x ) < math.abs( Centre_Dist.x ) and Snapped_Edges.x ) or !Snapped_Centres.x then
				NewPosL.x = EdgePosL.x
			end
			
			if ( math.abs( Edge_Dist.y ) < math.abs( Centre_Dist.y ) and Snapped_Edges.y ) or !Snapped_Centres.y  then
				NewPosL.y = EdgePosL.y
			end
			
			if ( math.abs( Edge_Dist.z ) < math.abs( Centre_Dist.z ) and Snapped_Edges.z ) or !Snapped_Centres.z  then
				NewPosL.z = EdgePosL.z
			end
		end
		
		Pos = Ent:LocalToWorld(NewPosL)
	else
		Pos = trace.HitPos
	end
	
	return Pos
end

// Place Constructs
function TOOL:LeftClick( trace )
	if !trace.HitPos then return false end	
	if CLIENT then return true end
	
	local point = self:GetClickPosition( trace )
	local normal = trace.HitNormal
	local ent = trace.Entity
	
	if !IsValid(ent) then
		ent = nil
	end
	
	self:SendClickData( point, normal, ent )
		
	return true
end

// Select Entities
function TOOL:RightClick( trace )
	if CLIENT then return true end
	if trace.Entity:IsWorld() then
		self:SetActive()
		return true
	end

	if !IsValid(trace.Entity) then
		return false
	elseif !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then
		return false
	elseif trace.Entity:IsPlayer() then
		return false
	end
	
	self:SetActive( trace.Entity )
	
	// Repeat last PA move
	local ply = self:GetOwner()
	local alt = ply:KeyDown( IN_SPEED )
	if alt then
		precision_align_lastaction_func( ply )
	end
	
	return true
end

// Open Manipulation Panel
function TOOL:Reload( trace )
	if CLIENT then return false end
	local ply = self:GetOwner()
	ply:ConCommand( PA_.."open_panel" )
	return false
end

function TOOL:DrawToolScreen( w, h )
	PA_DrawToolScreen()
end