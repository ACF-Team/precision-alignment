-- Precision Alignment STool code - By Wenli

TOOL.Category		= "Constraints"
TOOL.Name			= "#Tool.precision_align.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.Information	= {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" }
}

local PA = "precision_align"
local PA_ = PA .. "_"

AddCSLuaFile( PA .. "/ui.lua" )
AddCSLuaFile( PA .. "/draw_hud.lua" )
AddCSLuaFile( PA .. "/manipulation_panel.lua" )
AddCSLuaFile( PA .. "/primitives_panel.lua" )

-- local typeCvar = GetConVar("precision_align_tooltype")

TOOL.ClientConVar =
{
	-- Tool menu options
	["edge_snap"] 			= "1",
	["centre_snap"] 		= "1",
	["snap_distance"] 		= "100",
	["toolname"]			= "Point - Hitpos",
	["draw_attachments"]	= "0",

	-- Construct draw sizes
	["size_point"]			= "5",
	["size_line_start"]		= "4",
	["size_line_end"]		= "4",
	["size_plane"]			= "10",
	["size_plane_normal"]	= "20",

	["border_size"]         = "3",
	["line_thickness"]      = "3",

	-- Ent Selection colour
	["selectcolour_h"]		= "230",
	["selectcolour_s"]		= "0.6",
	["selectcolour_v"]		= "1",
	["selectcolour_a"]		= "255",

	-- Attachment line colour
	["attachcolour_h"]		= "120",
	["attachcolour_s"]		= "1",
	["attachcolour_v"]		= "1",
	["attachcolour_a"]		= "150",

	-- Constraints
	["axis_forcelimit"]		= "0",
	["axis_torquelimit"]	= "0",
	["axis_friction"]		= "0",
	["axis_nocollide"]		= "0",

	["ballsocket_forcelimit"]	= "0",
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
	["elastic_color_r"]		= "255",
	["elastic_color_g"]		= "255",
	["elastic_color_b"]		= "255",

	["rope_forcelimit"]		= "0",
	["rope_addlength"]		= "0",
	["rope_width"]			= "1",
	["rope_material"]		= "cable/rope",
	["rope_rigid"]			= "0",
	["rope_setlength"]		= "0",
	["rope_color_r"]		= "255",
	["rope_color_g"]		= "255",
	["rope_color_b"]		= "255",

	["slider_width"]		= "1",
	["slider_material"]		= "cable/rope",
	["slider_color_r"]		= "255",
	["slider_color_g"]		= "255",
	["slider_color_b"]		= "255",

	["wire_hydraulic_width"]		= "3",
	["wire_hydraulic_material"]		= "cable/rope",
	["wire_hydraulic_speed"]		= "16",
	["wire_hydraulic_stretchonly"]	= "0",

	-- Stack number
	["stack_nocollide"]		= "0"
}

-- Client

if CLIENT then
	language.Add("Tool.precision_align.name", "Precision Alignment")
	language.Add("Tool.precision_align.desc", "Precision prop alignment tool")
	language.Add("Tool.precision_align.left", "Place constructs")
	language.Add("Tool.precision_align.right", "Select entity (Shift to repeat last action)")
	language.Add("Tool.precision_align.reload", "Open/close manipulation window")
	language.Add("Tool.precision_align.0", "Primary: Place constructs, Secondary: Select entity, Reload: Open/close manipulation window")
	language.Add("Tool.precision_align.1", "Click again to place line end point, right click to cancel")

	language.Add("Undone_precision_align", "Undone Precision Align")
end

-- Tool functions

if SERVER then
	function TOOL:SendClickData( point, normal, ent )
		net.Start( PA_ .. "click" )

		-- Send vectors using floats - was losing precision using just vectors
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
		local activeent = ply.PrecisionAlign_ActiveEnt

		local function Deselect( oldent )
			if IsValid( oldent ) and oldent.PA then
				local colour = oldent.PA.TrueColour

				if colour then
					oldent:SetColor( colour )
				end

				oldent.PA.Ply.PrecisionAlign_ActiveEnt = nil
				oldent.PA = nil
			end
		end

		-- Deselect last ent
		if activeent then
			Deselect( activeent )
		end

		-- Select new ent
		if IsValid( ent ) then
			-- Check for existing player selection
			if ent.PA then
				Deselect( ent )
			end

			ply.PrecisionAlign_ActiveEnt = ent
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
			ply.PrecisionAlign_ActiveEnt = nil

			self:SendEntityData()
			return false
		end
	end
end

-- Build CPanel
if CLIENT then
	function TOOL.BuildCPanel()
		include( "weapons/gmod_tool/stools/" .. PA .. "/ui.lua" )
	end

	local BuildCPanel = TOOL.BuildCPanel
	local function reloadui_func()
		local CPanel = controlpanel.Get( PA )
		CPanel:Clear()

		BuildCPanel( CPanel )

		MsgAll("Reloading UI\n")
	end
	concommand.Add( PA_ .. "reloadui", reloadui_func )
end

-- Calculate local position of nearest edge
local function Nearest_Edge( HitPosL, BoxMin, BoxMax, BoxCentre, Snap_Dist )
	local EdgePosL = Vector( HitPosL.x, HitPosL.y, HitPosL.z )

	-- This is used to kee
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

function TOOL:GetClickPosition(trace)
	local Pos
	local Ent = trace.Entity
	local Phys = Ent:GetPhysicsObjectNum(trace.PhysicsBone)
	local Edge_Snap = self:GetClientNumber("edge_snap") ~= 0
	local Centre_Snap = self:GetClientNumber("centre_snap") ~= 0
	local Snap_Dist = math.max(0, self:GetClientNumber("snap_distance"))

	local tooltype = self:GetClientInfo("toolname")
	local toolmode = PrecisionAlign.ToolModes[tooltype]

	if toolmode.GetClickPosition then
		PrecisionAlign.SetNextMessageTarget(self:GetOwner())
		Pos = toolmode:GetClickPosition(trace, trace.HitPos, Ent, Phys)
		PrecisionAlign.SetNextMessageTarget()
	end

	if Pos then return Pos end

	if not IsValid(Phys) or not IsValid(Ent) or Ent:IsWorld() then
		Pos = trace.HitPos
	elseif Edge_Snap or Centre_Snap then
		local BoxMin, BoxMax = Phys:GetAABB()
		if not BoxMin or not BoxMax then
			Pos = trace.HitPos
			PrecisionAlign.SetNextMessageTarget(self:GetOwner())
			PrecisionAlign.Warning("Phys:GetAABB(): BoxMin and/or BoxMax returned nil. Can't continue")
			PrecisionAlign.SetNextMessageTarget()
		else
			local HitPosL = Ent:WorldToLocal( trace.HitPos )
			local BoxCentre = Ent:OBBCenter()

			local NewPosL = Vector( HitPosL.x, HitPosL.y, HitPosL.z )

			local EdgePosL, Edge_Dist
			local CentrePosL, Centre_Dist

			-- These keep track of whether the point is being snapped to an edge or centre line
			local Snapped_Edges = {}
			local Snapped_Centres = {}

			-- Calculate local position of nearest edge
			if Edge_Snap then
				EdgePosL, Snapped_Edges = Nearest_Edge( HitPosL, BoxMin, BoxMax, BoxCentre, Snap_Dist )
				NewPosL = EdgePosL

			-- We need at least some edge snap if using Centre_Snap, else NewPosL will snap away from the surface being clicked on
			elseif Centre_Snap then
				EdgePosL, Snapped_Edges = Nearest_Edge( HitPosL, BoxMin, BoxMax, BoxCentre, 0.1 )
				NewPosL = EdgePosL
			end

			-- Calculate local position of nearest centre line
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

				-- NewPosL is already equal to CentrePosL, so only need to set cases where EdgePosL is smaller
				if ( math.abs( Edge_Dist.x ) < math.abs( Centre_Dist.x ) and Snapped_Edges.x ) or not Snapped_Centres.x then
					NewPosL.x = EdgePosL.x
				end

				if ( math.abs( Edge_Dist.y ) < math.abs( Centre_Dist.y ) and Snapped_Edges.y ) or not Snapped_Centres.y  then
					NewPosL.y = EdgePosL.y
				end

				if ( math.abs( Edge_Dist.z ) < math.abs( Centre_Dist.z ) and Snapped_Edges.z ) or not Snapped_Centres.z  then
					NewPosL.z = EdgePosL.z
				end
			end

			Pos = Ent:LocalToWorld(NewPosL)
		end
	else
		Pos = trace.HitPos
	end

	return Pos
end

-- Place Constructs
function TOOL:LeftClick( trace )
	if not trace.HitPos then return false end
	if CLIENT then return true end

	local point = self:GetClickPosition( trace )
	local normal = trace.HitNormal
	local ent = trace.Entity

	if not IsValid(ent) then
		ent = nil
	end

	self:SendClickData( point, normal, ent )

	return true
end

-- Select Entities
function TOOL:RightClick( trace )
	if CLIENT then return true end
	if trace.Entity:IsWorld() then
		self:SetActive()
		return true
	end

	if not IsValid(trace.Entity) then
		return false
	elseif not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then
		return false
	elseif trace.Entity:IsPlayer() then
		return false
	end

	self:SetActive( trace.Entity )

	-- Repeat last PA move
	local ply = self:GetOwner()
	local alt = ply:KeyDown( IN_SPEED )
	if alt then
		PrecisionAlign.LastAction( ply )
	end

	return true
end

-- Open Manipulation Panel
function TOOL:Reload()
	if CLIENT then return false end
	local ply = self:GetOwner()
	ply:ConCommand( PA_ .. "open_panel" )
	return false
end

-- Tool screen for precision alignment stool (client only) - By Wenli
if SERVER then return end

local BGColor            = PrecisionAlign.TOOLMODE_BACKGROUND_COLOR
local BGColor_Background = PrecisionAlign.TOOLMODE_BACKGROUND_COLOR_BACKGROUND

-- surface.CreateFont( "HUDNumber", {60, 400, true, false, "PAToolScreen_Title"} )
surface.CreateFont("PAToolScreen_Title", {font = "Verdana", size = 60, weight = 400, antialias = true, additive = false})
-- surface.CreateFont( "TabLarge",{ 70, 400, true, false, "PAToolScreen_ToolType"} )
surface.CreateFont("PAToolScreen_ToolType", {font = "Verdana", size = 70, weight = 400, antialias = true, additive = false})
-- surface.CreateFont( "TabLarge",{ 29, 400, true, false, "PAToolScreen_ToolDesc"} )
surface.CreateFont("PAToolScreen_ToolDesc", {font = "Verdana", size = 29, weight = 400, antialias = true, additive = false})

local CONSTRUCT_POINT = PrecisionAlign.CONSTRUCT_POINT
local CONSTRUCT_LINE  = PrecisionAlign.CONSTRUCT_LINE
local CONSTRUCT_PLANE = PrecisionAlign.CONSTRUCT_PLANE

local function construct_exists( construct_type, ID )
	if not construct_type or not ID then return false end

	if construct_type == CONSTRUCT_POINT then
		if PrecisionAlign.Points[ID].origin then
			return true
		end
	elseif construct_type == CONSTRUCT_LINE then
		if PrecisionAlign.Lines[ID].startpoint and PrecisionAlign.Lines[ID].endpoint then
			return true
		end
	elseif construct_type == CONSTRUCT_PLANE then
		if PrecisionAlign.Planes[ID].origin and PrecisionAlign.Planes[ID].normal then
			return true
		end
	end

	return false
end

local function GetConstructNum( curToolType )
	local ToolMode = PrecisionAlign.ToolModes[curToolType]
	if ToolMode.Construct == CONSTRUCT_POINT then
		ToolNum = PrecisionAlign.SelectedPoint
	elseif ToolMode.Construct == CONSTRUCT_LINE then
		ToolNum = PrecisionAlign.SelectedLine
	elseif ToolMode.Construct == CONSTRUCT_PLANE then
		ToolNum = PrecisionAlign.SelectedPlane
	end
	return ToolNum
end

-- Taken from Garry's tool code
local function DrawScrollingText( text, y, texwide )
	local w, _ = surface.GetTextSize( text  )
	w = w + 64

	local x = math.fmod( CurTime() * 150, w ) * -1

	while x < texwide do
		surface.SetTextColor( 0, 0, 0, 255 )
		surface.SetTextPos( x + 5, y + 5 )
		surface.DrawText( text )

		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( x, y )
		surface.DrawText( text )

		x = x + w
	end
end

local function DrawText_ToolType( y, curToolType )
	surface.SetFont( "PAToolScreen_ToolType" )
	surface.SetTextColor( 255, 255, 255, 255 )

	local ToolMode = PrecisionAlign.ToolModes[curToolType]

	local text = PrecisionAlign.GetConstructName(ToolMode.Construct) or "Unknown Toolmode"
	text = text .. " " .. tostring( GetConstructNum( curToolType ) )

	local w = surface.GetTextSize( text )

	surface.SetTextPos( 125 - w / 2, y )
	surface.DrawText( text )
end

local function DrawText_ToolDesc( y, curToolType )
	surface.SetFont( "PAToolScreen_ToolDesc" )
	surface.SetTextColor( 255, 255, 255, 255 )

	local ToolMode = PrecisionAlign.ToolModes[curToolType]
	local text = ToolMode:GetName() or "No tool option selected"
	local w = surface.GetTextSize( text )

	surface.SetTextPos( 125 - w / 2, y )
	surface.DrawText( text )
end

local function DrawIndicators( x, y, w, curToolType )
	local radius = 8
	local diameter = radius * 2 + 1
	local separation = (w - 4) / 9

	-- Background
	draw.RoundedBox( 10, x, y, w, diameter + 15, Color(50, 50, 50, 100) )

	local xpos = x + radius
	local ypos = y + radius

	-- Indicators
	local IndicatorColour
	local ConstructNum = GetConstructNum( curToolType )
	for i = 1, 9 do
		-- Draw construct selection ring
		if i == ConstructNum then
			draw.RoundedBox( radius + 4, xpos - 4, ypos - 4, diameter + 8, diameter + 8, Color(255, 255, 255, 255) )
		end

		-- Draw indicator status
		local ToolMode = PrecisionAlign.ToolModes[curToolType]
		if construct_exists(ToolMode.Construct, i) then
			IndicatorColour = Color(0, 230, 0, 255)
		else
			IndicatorColour = Color(50, 50, 50, 255)
		end

		draw.RoundedBox( radius, xpos, ypos, diameter, diameter, IndicatorColour )
		xpos = xpos + separation
	end
end

local Colour_Current = PrecisionAlign.TOOLMODE_BACKGROUND_COLOR_DISPLAY
-- Main Draw Function
local function PA_DrawToolScreen( w, h )
	local r, e = pcall( function()
		w = tonumber(w) or 256
		h = tonumber(h) or 256

		local curToolType = GetConVar("precision_align_toolname"):GetString()
		local toolMode    = PrecisionAlign.ToolModes[curToolType]
		-- Background colour
		local Colour_Selected = toolMode:GetBackgroundColor()

		for k, v in pairs (Colour_Current) do
			Colour_Current[k] = v + (Colour_Selected[k] - v) / 10
		end
		surface.SetDrawColor( Colour_Current )
		surface.DrawRect( 0, 0, w, h )

		-- Title text / background
		surface.SetFont( "PAToolScreen_Title" )
		local titletext = "Precision Alignment"
		local _, texth = surface.GetTextSize( titletext )

		surface.SetDrawColor( BGColor_Background )
		surface.DrawRect( 0, 10, w, texth + 4 )
		DrawScrollingText( titletext, 6, w )

		-- Lower background box
		draw.RoundedBox( 10, 10, texth + 22, w - 20, h - texth - 30, BGColor )

		-- Tool type text
		DrawText_ToolType( 85, curToolType )
		DrawText_ToolDesc( 160, curToolType )

		-- Construct indicators
		DrawIndicators( 10, 212, w - 20, curToolType )
	end )

	if not r then
		ErrorNoHalt( e, "\n" )
	end
end

function TOOL:DrawToolScreen()
	PA_DrawToolScreen()
end
