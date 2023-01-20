// Tool screen for precision alignment stool (client only) - By Wenli
if SERVER then return false end


local BGColor = Color(50, 50, 50, 50)
local BGColor_Background = Color(103, 100, 110, 255)
local BGColor_Display = Color(170, 170, 170, 255)
local BGColor_Point = Color(170, 140, 140, 255)
local BGColor_Line = Color(140, 140, 170, 255)
local BGColor_Plane = Color(140, 170, 140, 255)

//surface.CreateFont( "HUDNumber", {60, 400, true, false, "PAToolScreen_Title"} )
surface.CreateFont("PAToolScreen_Title",{font = "HUDNumber",size = 60 , weight = 400 , antialias 	= true ,additive = false})
//surface.CreateFont( "TabLarge",{ 70, 400, true, false, "PAToolScreen_ToolType"} )
surface.CreateFont("PAToolScreen_ToolType",{font = "TabLarge",size = 70 , weight = 400 , antialias 	= true ,additive = false})
//surface.CreateFont( "TabLarge",{ 29, 400, true, false, "PAToolScreen_ToolDesc"} )
surface.CreateFont("PAToolScreen_ToolDesc",{font = "TabLarge",size = 29 , weight = 400 , antialias 	= true ,additive = false})

local ToolType_Current = GetConVarNumber("precision_align_tooltype")
local ToolTypeLookup = {
	[1] = {"Point", "Hitpos"},
	[2] = {"Point", "Coordinate Centre"},
	[3] = {"Point", "Mass Centre"},
	[4] = {"Point", "Bounding Box Centre"},
	[5] = {"Line", "Start / End (Alt)"},
	[6] = {"Line", "Hitpos + Hitnormal"},
	[7] = {"Line", "Hitnormal"},
	[8] = {"Plane", "Hitpos + Hitnormal"},
	[9] = {"Plane", "Hitnormal"}
}

local Colour_Current = BGColor_Display
local ColourLookup = {
	[1] = BGColor_Point,
	[2] = BGColor_Point,
	[3] = BGColor_Point,
	[4] = BGColor_Point,
	[5] = BGColor_Line,
	[6] = BGColor_Line,
	[7] = BGColor_Line,
	[8] = BGColor_Plane,
	[9] = BGColor_Plane
}


local function construct_exists( construct_type, ID )
	if !construct_type or !ID then return false end

	if construct_type == "Point" then
		if precision_align_points[ID].origin then
			return true
		end
	elseif construct_type == "Line" then
		if precision_align_lines[ID].startpoint and precision_align_lines[ID].endpoint then
			return true
		end
	elseif construct_type == "Plane" then
		if precision_align_planes[ID].origin and precision_align_planes[ID].normal then
			return true
		end
	end
	
	return false
end


local function GetConstructNum()
	local ToolNum
	if ToolType_Current >= 1 and ToolType_Current <= 4 then
		ToolNum = PA_selected_point
	elseif ToolType_Current >= 5 and ToolType_Current <= 7 then
		ToolNum = PA_selected_line
	elseif ToolType_Current >= 8 and ToolType_Current <= 9 then
		ToolNum = PA_selected_plane
	end
	return ToolNum
end


// Taken from Garry's tool code
local function DrawScrollingText( text, y, texwide )
	local w, h = surface.GetTextSize( text  )
	w = w + 64
	
	local x = math.fmod( CurTime() * 150, w ) * -1
	
	while ( x < texwide ) do
		surface.SetTextColor( 0, 0, 0, 255 )
		surface.SetTextPos( x + 5, y + 5 )
		surface.DrawText( text )
		
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( x, y )
		surface.DrawText( text )
		
		x = x + w
	end
end


local function DrawText_ToolType( y )
	surface.SetFont( "PAToolScreen_ToolType" )
	surface.SetTextColor( 255, 255, 255, 255 )
	
	local text = ToolTypeLookup[ ToolType_Current ][1] or "-"
	text = text .. " " .. tostring( GetConstructNum() )
	
	local w, h = surface.GetTextSize( text  )
	
	surface.SetTextPos( 125 - w/2, y )
	surface.DrawText( text )
end


local function DrawText_ToolDesc( y )
	surface.SetFont( "PAToolScreen_ToolDesc" )
	surface.SetTextColor( 255, 255, 255, 255 )
	
	local text = ToolTypeLookup[ ToolType_Current ][2] or "No tool option selected"
	local w, h = surface.GetTextSize( text  )
	
	surface.SetTextPos( 125 - w/2, y )
	surface.DrawText( text )
end


local function DrawIndicators( x, y, w )
	local radius = 8
	local diameter = radius * 2 + 1
	local separation = (w - 4) / 9
	
	// Background
	draw.RoundedBox( 10, x, y, w, diameter + 15, Color(50, 50, 50, 100) )
	
	local xpos = x + radius
	local ypos = y + radius
	
	// Indicators
	local IndicatorColour
	local ConstructNum = GetConstructNum()
	for i = 1, 9 do
		// Draw construct selection ring
		if i == ConstructNum then
			draw.RoundedBox( radius + 4, xpos - 4, ypos - 4, diameter + 8, diameter + 8, Color(255, 255, 255, 255) )
		end
		
		// Draw indicator status
		if construct_exists( ToolTypeLookup[ ToolType_Current ][1], i) then
			IndicatorColour = Color(0, 230, 0, 255)
		else
			IndicatorColour = Color(50, 50, 50, 255)
		end
		
		draw.RoundedBox( radius, xpos, ypos, diameter, diameter, IndicatorColour )
		xpos = xpos + separation
	end
end


// Main Draw Function
function PA_DrawToolScreen( w, h )
	local r, e = pcall( function()
		local w = tonumber(w) or 256
		local h = tonumber(h) or 256
		
		ToolType_Current = GetConVarNumber("precision_align_tooltype")
		
		// Background colour
		local Colour_Selected = ColourLookup[ ToolType_Current ] or BGColor_Display
		for k, v in pairs (Colour_Current) do
			Colour_Current[k] = v + (Colour_Selected[k] - v) / 10
		end
		surface.SetDrawColor( Colour_Current )
		surface.DrawRect( 0, 0, w, h )
		
		// Title text / background
		surface.SetFont( "PAToolScreen_Title" )
		local titletext = "Precision Alignment (unofficial)"
		local textw, texth = surface.GetTextSize( titletext )
		
		surface.SetDrawColor( BGColor_Background )
		surface.DrawRect( 0, 10, w, texth + 4 )
		DrawScrollingText( titletext, 6, w )
		
		// Lower background box
		draw.RoundedBox( 10, 10, texth + 22, w - 20, h - texth - 30, BGColor )
		
		// Tool type text
		DrawText_ToolType( 85 )
		DrawText_ToolDesc( 160 )
		
		// Construct indicators
		DrawIndicators( 10, 212, w - 20 )
		
	end )
	
	if !r then
		ErrorNoHalt( e, "\n" )
	end
end