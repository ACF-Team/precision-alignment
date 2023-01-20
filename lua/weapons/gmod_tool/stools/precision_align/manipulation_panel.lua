// Derma UI for Precision Alignment stool (client only) - window opens on tool Reload - By Wenli

if SERVER then return end

local PA_VERSION = 9
	
// Standard functions
local PA = "precision_align"
local PA_ = PA .. "_"

// Relative to data directory
local help_file = "Precision Alignment Help/index.html"

// Table cloning
local function clone( T )
	T2 = {}
	for k, v in pairs (T) do
		T2[k] = v
	end
	return T2
end

local function Message(text)
	if GetConVarNumber(PA_.."display_messages") == 1 then
		LocalPlayer():ChatPrint("(PA) " .. text)
	end
end

local function Warning( text )
	if GetConVarNumber(PA_.."display_warnings") == 1 then
		LocalPlayer():ChatPrint("(PA) ERROR: " .. text)
	end
end

local function NormAng( ang )
	local ang_temp = Angle()
	ang_temp.p = math.NormalizeAngle(ang.p)
	ang_temp.y = math.NormalizeAngle(ang.y)
	ang_temp.r = math.NormalizeAngle(ang.r)
	return ang_temp
end

local function AddMenuText( text, x, y, parent )
	local Text = vgui.Create( "DLabel", parent )
	//Text:SetFont("TabLarge")
	Text:SetFontInternal("Default")
	Text:SetText( text )
	Text:SizeToContents() 
	Text:SetPos( x, y )
	return Text
end


//********************************************************************************************************************//
// Manipulation Window
//********************************************************************************************************************//


local BGColor = Color(50, 50, 50, 50)
local BGColor_Background = Color(103, 100, 110, 255)
local BGColor_Disabled = Color(160, 160, 160, 255)
local BGColor_Display = Color(170, 170, 170, 255)
local BGColor_Point = Color(170, 140, 140, 255)
local BGColor_Line = Color(140, 140, 170, 255)
local BGColor_Plane = Color(140, 170, 140, 255)
local BGColor_Rotation = Color(140, 170, 170, 255)


local function play_sound_true()
	LocalPlayer():EmitSound("buttons/button15.wav", 100, 100)
end

local function play_sound_false()
	LocalPlayer():EmitSound("buttons/lightswitch2.wav", 100, 100)
end


local MANIPULATION_FRAME = {}
function MANIPULATION_FRAME:Init()
	self:SetSize(900, 500)
	self:Center()
	self:SetTitle( "Precision Alignment Manipulation Panel" )
	self:SetVisible( true )
	self:SetDraggable( true )
	self:SetSizable( false )
	self:ShowCloseButton( true )
	self:SetDeleteOnClose( false )
	self:MakePopup()
	self:SetKeyBoardInputEnabled( false )
	
	-- self.version_text = AddMenuText( "v1.5", 885, 5, self )
	self.version_text = AddMenuText( "(unofficial v" .. PA_VERSION .. ")", 735, 5, self )
	
	self.body = vgui.Create( "PA_Manipulation_Body", self )
	self.panel = vgui.Create( "PA_Manipulation_Panel", self.body )
	
	self.displays_tab = vgui.Create( "PA_Displays_Tab", self.body )
	self.points_tab = vgui.Create( "PA_Points_Tab", self.body )
	self.lines_tab = vgui.Create( "PA_Lines_Tab", self.body )
	self.planes_tab = vgui.Create( "PA_Planes_Tab", self.body )
	self.move_tab = vgui.Create( "PA_Move_Tab", self.body )
	self.functions_tab = vgui.Create( "PA_Functions_Tab", self.body )
	self.rotation_tab = vgui.Create( "PA_Rotation_Tab", self.body )
	self.rotation_functions_tab = vgui.Create( "PA_Rotation_Functions_Tab", self.body )
	self.constraints_tab = vgui.Create( "PA_Constraints_Tab", self.body )

	self.panel:AddSheet( "Display Options", self.displays_tab, "icon16/picture_edit.png", false, false )
	self.panel:AddSheet( "Points", self.points_tab, "icon16/add.png", false, false )
		self.points_tab.tab = self.panel.Items[2].Tab
	self.panel:AddSheet( "Lines", self.lines_tab, "icon16/tick.png", false, false )
		self.lines_tab.tab = self.panel.Items[3].Tab
	self.panel:AddSheet( "Planes", self.planes_tab, "icon16/world.png", false, false )
		self.planes_tab.tab = self.panel.Items[4].Tab
	self.panel:AddSheet( "Move Constructs", self.move_tab, "icon16/folder_go.png", false, false )
	self.panel:AddSheet( "Functions", self.functions_tab, "icon16/plugin.png", false, false )
	self.panel:AddSheet( "Rotation", self.rotation_tab, "icon16/arrow_refresh.png", false, false )
	self.panel:AddSheet( "Rotation Functions", self.rotation_functions_tab, "icon16/arrow_refresh.png", false, false )
	self.panel:AddSheet( "Constraints", self.constraints_tab, "icon16/anchor.png", false, false )
	
	
	// Help button
	self.button_help = vgui.Create( "PA_Function_Button", self )
		-- self.button_help:SetPos(875, 30)
		self.button_help:SetPos(830, 30)
		self.button_help:SetSize(60, 20)
		self.button_help:SetText( "Help" )
		self.button_help:SetToolTip( "Open online help using the Steam in-game browser" )
		self.button_help:SetFunction( function()
			return gui.OpenURL( "https://sourceforge.net/userapps/mediawiki/wenli/index.php?title=Precision_Alignment" )
		end )
	
	
	// Alpha slider
	--self.slider_alpha = vgui.Create( "DAlphaBar", self )
	--	self.slider_alpha:SetPos(910, 55)
	--	self.slider_alpha:SetSize(25, 435)
		-- self.slider_alpha.imgBackground:Remove()
		-- self.slider_alpha.PerformLayout = function() DSlider.PerformLayout( self.slider_alpha ) end
	--	self.slider_alpha.OnChange = function( panel, alpha )
	--		self.body:SetAlpha(alpha)
	--		panel:SetAlpha(255)
	--	end
	--	self.slider_alpha:SetValue(0)
	
	
	// Initialize colour settings
	local function SetBarColour()
		local H = GetConVarNumber( PA_.."selectcolour_h" )
		local S = GetConVarNumber( PA_.."selectcolour_s" )
		local V = GetConVarNumber( PA_.."selectcolour_v" )
		-- self.slider_alpha:SetFGColor( HSVToColor( H, S, V ) )
	end
	cvars.AddChangeCallback( PA_.."selectcolour_h", SetBarColour )
	cvars.AddChangeCallback( PA_.."selectcolour_s", SetBarColour )
	cvars.AddChangeCallback( PA_.."selectcolour_v", SetBarColour )
	SetBarColour()
end


function MANIPULATION_FRAME:Paint()
		local width, height = self:GetSize()
		local offset = 60
		
		draw.RoundedBox(6, 0, 0, width, 25, BGColor_Display)
		draw.RoundedBox(6, 2, 2, width - 4, 21, BGColor_Background)
		
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawLine(offset, height - 1, width - offset, height - 1)
		surface.DrawLine(1, offset, 1, height - offset)
		surface.DrawLine(width - 1, offset, width - 1, height - offset)
end

vgui.Register("PA_Manipulation_Frame", MANIPULATION_FRAME, "DFrame")


local MANIPULATION_BODY = {}
function MANIPULATION_BODY:Init()
	self:CopyBounds( self:GetParent() )
	self:SetTall(475)
	self:SetPos(0, 25)
end

function MANIPULATION_BODY:Paint()
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), Color(0,0,0,255))
	draw.RoundedBox(6, 1, 1, self:GetWide() - 2, self:GetTall() - 2, BGColor_Background)
end

vgui.Register("PA_Manipulation_Body", MANIPULATION_BODY, "DPanel")

local MANIPULATION_PANEL = {}
function MANIPULATION_PANEL:Init()
	self:SetPos(0, 5)
	self:SetSize(900, 470)
end

function MANIPULATION_PANEL:Paint()
end

vgui.Register("PA_Manipulation_Panel", MANIPULATION_PANEL, "DPropertySheet")


//********************************************************************************************************************//
// Displays  Tab
//********************************************************************************************************************//


local DISPLAYS_TAB = {}
function DISPLAYS_TAB:Init()
	self:SetPos(5, 30)
	self:CopyBounds( self:GetParent() )
		
	local function update_visibility( panel, construct_table )
		local selection = panel:GetSelected()
		local keytable = {}
		for k, v in pairs( selection ) do
			keytable[ selection[k]:GetID() ] = true
		end
		
		for I = 1, 9 do
			if keytable[I] then
				construct_table[I].visible = true
			else
				construct_table[I].visible = false
			end
		end
	end
	
	self.panel_multiselect = vgui.Create( "PA_Construct_Multiselect", self )
	self.panel_multiselect.button_attach:Remove()
	self.panel_multiselect.button_delete:Remove()
	
	// This flag will make the selection buttons affect visibility
	self.panel_multiselect.visibility = true
	self.panel_multiselect:SelectAll( true )
	
	AddMenuText( "Construct Visibility", 10, 5, self.panel_multiselect.colour_panel_1 )
	
	self.panel_multiselect.list_points.OnRowSelected = function( Panel, Line )
		update_visibility( Panel, precision_align_points )
	end
	
	self.panel_multiselect.list_lines.OnRowSelected = function( Panel, Line )
		update_visibility( Panel, precision_align_lines )
	end
	
	self.panel_multiselect.list_planes.OnRowSelected = function( Panel, Line )
		update_visibility( Panel, precision_align_planes )
	end
	
	AddMenuText( "Construct Draw Sizes", 10, self:GetTall()/2 - 10, self )
	AddMenuText( "Tool Messages", 290, self:GetTall()/2 - 10, self )

	self.checkbox_messages = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_messages:SetPos(300, 252)
		self.checkbox_messages:SetText( "Display Debug Messages" )
		self.checkbox_messages:SizeToContents()
		self.checkbox_messages:SetToolTip( "Enable detailed tool debug messages" )
		self.checkbox_messages:SetConVar( PA_.."display_messages" )
	
	self.checkbox_warnings = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_warnings:SetPos(300, 272)
		self.checkbox_warnings:SetText( "Display Error Messages" )
		self.checkbox_warnings:SizeToContents()
		// self.checkbox_warnings:SetToolTip( "Enable error messages" )
		self.checkbox_warnings:SetConVar( PA_.."display_warnings" )
	
	self.slider_pointsize = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_pointsize:SetPos(25, 220)
		self.slider_pointsize:SetSize(230, 100)
		self.slider_pointsize:SetText( "Point" )
		self.slider_pointsize:SetMinMax( 0, 30 )
		self.slider_pointsize:SetDecimals( 1 )
		self.slider_pointsize:SetConVar( PA_.."size_point" )
	
	self.slider_line_startsize = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_line_startsize:SetPos(25, 285)
		self.slider_line_startsize:SetSize(230, 100)
		self.slider_line_startsize:SetText( "Line Start (Cross)" )
		self.slider_line_startsize:SetMinMax( 0, 30 )
		self.slider_line_startsize:SetDecimals( 1 )
		self.slider_line_startsize:SetConVar( PA_.."size_line_start" )
	
	self.slider_line_endsize = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_line_endsize:SetPos(300, 285)
		self.slider_line_endsize:SetSize(230, 100)
		self.slider_line_endsize:SetText( "Line End (Double Bar)" )
		self.slider_line_endsize:SetMinMax( 0, 30 )
		self.slider_line_endsize:SetDecimals( 1 )
		self.slider_line_endsize:SetConVar( PA_.."size_line_end" )
	
	self.slider_planesize = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_planesize:SetPos(25, 350)
		self.slider_planesize:SetSize(230, 100)
		self.slider_planesize:SetText( "Plane (Square)" )
		self.slider_planesize:SetMinMax( 0, 30 )
		self.slider_planesize:SetDecimals( 1 )
		self.slider_planesize:SetConVar( PA_.."size_plane" )
	
	self.slider_planesize_normal = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_planesize_normal:SetPos(300, 350)
		self.slider_planesize_normal:SetSize(230, 100)
		self.slider_planesize_normal:SetText( "Plane Normal (Length)" )
		self.slider_planesize_normal:SetMinMax( 0, 30 )
		self.slider_planesize_normal:SetDecimals( 1 )
		self.slider_planesize_normal:SetConVar( PA_.."size_plane_normal" )
	
	
	self.button_size_defaults = vgui.Create( "PA_Function_Button", self )
		self.button_size_defaults:SetPos(465, 235)
		self.button_size_defaults:SetSize(90, 25)
		self.button_size_defaults:SetText( "Reset Defaults" )
		self.button_size_defaults:SetFunction( function()
			RunConsoleCommand( PA_.."display_messages", 0 )
			RunConsoleCommand( PA_.."display_warnings", 1 )
			self.checkbox_messages:SetValue( false )
			self.checkbox_warnings:SetValue( true )
			
			RunConsoleCommand( PA_.."size_point", 5 )
			RunConsoleCommand( PA_.."size_line_start", 4 )
			RunConsoleCommand( PA_.."size_line_end", 4 )
			RunConsoleCommand( PA_.."size_plane", 10 )
			RunConsoleCommand( PA_.."size_plane_normal", 20 )
			return true
		end )
	
	
	AddMenuText( "Entity Selection Colour", 575, 5, self )
	
	self.colourcircle_enthighlight = vgui.Create("PA_ColourControl", self)
		self.colourcircle_enthighlight:SetPos(590, 15)
		self.colourcircle_enthighlight:SetConVar( PA_ .. "selectcolour" )
		self.colourcircle_enthighlight:SetDefaults( 230, 0.6, 1, 255 )
	
	
	AddMenuText( "Attachment Line Colour", 575, 225, self )
	
	self.colourcircle_attachment = vgui.Create("PA_ColourControl", self)
		self.colourcircle_attachment:SetPos(590, 235)
		self.colourcircle_attachment:SetConVar( PA_ .. "attachcolour" )
		self.colourcircle_attachment:SetDefaults( 180, 1, 1, 150 )
	
	
	// Initialize colour settings
	self.colourcircle_enthighlight:SetColor(	GetConVarNumber(PA_.."selectcolour_h"),
												GetConVarNumber(PA_.."selectcolour_s"),
												GetConVarNumber(PA_.."selectcolour_v"),
												GetConVarNumber(PA_.."selectcolour_a")
											)
	
	self.colourcircle_attachment:SetColor(	GetConVarNumber(PA_.."attachcolour_h"),
											GetConVarNumber(PA_.."attachcolour_s"),
											GetConVarNumber(PA_.."attachcolour_v"),
											GetConVarNumber(PA_.."attachcolour_a")
										)
	
end

function DISPLAYS_TAB:Paint()
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), BGColor_Display)
	
	draw.RoundedBox(6, 0, 15, 555, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 565, 15, 320, self:GetTall()/2 - 20, BGColor)
	
	draw.RoundedBox(6, 0, self:GetTall()/2 + 15, 555, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 565, self:GetTall()/2 + 15, 320, self:GetTall()/2 - 20, BGColor)
	
	// Construct Draw Size coloured background
	draw.RoundedBox(6, 0, 235, 280, 66, BGColor_Point)
	draw.RoundedBox(6, 0, 301, 555, 67, BGColor_Line)
	draw.RoundedBox(6, 0, 368, 555, 67, BGColor_Plane)
	
	draw.RoundedBox(6, 15, 246, 250, 46, BGColor)
	
	draw.RoundedBox(6, 15, 312, 250, 46, BGColor)
	draw.RoundedBox(6, 15, 379, 250, 46, BGColor)
	
	draw.RoundedBox(6, 290, 312, 250, 46, BGColor)
	draw.RoundedBox(6, 290, 379, 250, 46, BGColor)
	
	// Display messages background box
	draw.RoundedBox(6, 290, 246, 161, 46, BGColor)
	
	// Selection colour preview
	-- local H, S, V, A = self.colourcircle_enthighlight:GetColor()
	//local colour = HSVToColor( H, S, V 
	-- local colour = Color(H, S, V ,A)
	//colour.a = A
	
	-- surface.SetDrawColor( colour.r, colour.g, colour.b, colour.a )
	-- surface.DrawRect( 840, 100, 35, 55 )
	
	// Attachment Line Preview
	-- H, S, V, A = self.colourcircle_attachment:GetColor()
	-- colour = HSVToColor( H, S, V )
	-- colour.a = A
	
	-- surface.SetDrawColor( colour.r, colour.g, colour.b, colour.a )
	-- surface.DrawLine( 860, 280, 860, 410 )
end

vgui.Register("PA_Displays_Tab", DISPLAYS_TAB, "DPanel")


//********************************************************************************************************************//
// Points Tab
//********************************************************************************************************************//


local POINTS_TAB = {}
function POINTS_TAB:Init()
	local ent_relative_1 = false
	local ent_relative_2 = false
	
	self:CopyBounds( self:GetParent() )
	
	AddMenuText( "Point Adjustment", 10, 5, self )
	
	local function update_primary_listview()
		local selection = self.list_primarypoint:GetSelectedLine()
		if !selection then return false end
		
		local point_temp = PA_funcs.point_global( selection )
		local vec
		
		if !point_temp then
			vec = Vector(0,0,0)
		else
			vec = point_temp.origin
			if self.checkbox_relative1:GetChecked() then
				if IsValid(PA_activeent) then
					vec = PA_activeent:WorldToLocal(vec)
				else
					self.checkbox_relative1:SetValue(false)
				end
			end
		end
		
		self.sliders_origin1:SetValues( vec )
		return true
	end
	
	self.list_primarypoint = vgui.Create( "PA_Construct_ListView", self )
		self.list_primarypoint:Text( "Primary", "Point", self )
		self.list_primarypoint:SetToolTip( "Double click to update sliders" )
		self.list_primarypoint:SetPos(15, 30)
		self.list_primarypoint:SetMultiSelect(false)
		self.list_primarypoint.DoDoubleClick = function( Line, LineID )
			update_primary_listview()
			play_sound_true()
		end
	
	self.checkbox_relative1 = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_relative1:SetPos(140, 30)
		self.checkbox_relative1:SetText( "Relative to\nEntity" )
		self.checkbox_relative1:SetSize(100,30)
		self.checkbox_relative1.OnChange = function()
			if !update_primary_listview() and self.checkbox_relative1:GetChecked() then
				self.checkbox_relative1:SetValue(false)
			end
		end
	
	self.button_set = vgui.Create( "PA_Function_Button", self )
		self.button_set:SetPos(140, 69)
		self.button_set:SetSize(80, 70)
		self.button_set:SetText( "Set" )
		self.button_set:SetToolTip( "Set the selected point according to these x/y/z values" )
		self.button_set:SetFunction( function()
			local selection = self.list_primarypoint:GetSelectedLine()
			if selection then
				local vec = self.sliders_origin1:GetValues()
				
				if self.checkbox_relative1:GetChecked() and IsValid(PA_activeent) then
					vec = PA_activeent:LocalToWorld(vec)
				end
				
				return PA_funcs.set_point( selection, vec )
			end
			Warning("No selection")
			return false
		end )
	
	self.button_delete = vgui.Create( "PA_Function_Button", self )
		self.button_delete:SetPos(140, 144)
		self.button_delete:SetSize(80, 25)
		self.button_delete:SetText( "Delete" )
		self.button_delete:SetFunction( function()
			local selection = self.list_primarypoint:GetSelectedLine()
			if selection then
				return PA_funcs.delete_point(selection)
			end
			Warning("No selection")
			return false
		end )
	
	self.button_deleteall = vgui.Create( "PA_Function_Button", self )
		self.button_deleteall:SetPos(140, 174)
		self.button_deleteall:SetSize(80, 25)
		self.button_deleteall:SetText( "Delete All" )
		self.button_deleteall:SetFunction( function()
			return PA_funcs.delete_points()
		end )
	
	self.sliders_origin1 = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_origin1:SetPos(230, 64)
		self.sliders_origin1:SetSize(230, 150)
	
	self.button_zero1 = vgui.Create( "PA_Zero_Button", self )
		self.button_zero1:SetPos(413, 30)
		self.button_zero1:SetSliders( self.sliders_origin1 )
	
	self.button_copy_clipboard1 = vgui.Create( "PA_Copy_Clipboard_Button", self )
		self.button_copy_clipboard1:SetPos(313, 30)
		self.button_copy_clipboard1:SetSliders( self.sliders_origin1 )
	
	
	local function update_secondary_listview()
		local selection = self.list_secondarypoint:GetSelectedLine()
		if !selection then return false end
		
		local point_temp = PA_funcs.point_global( selection )
		local vec
		
		if !point_temp then
			vec = Vector(0,0,0)
		else
			vec = point_temp.origin
			if self.checkbox_relative2:GetChecked() then
				if IsValid(PA_activeent) then
					vec = PA_activeent:WorldToLocal(vec)
				else
					self.checkbox_relative2:SetValue(false)
				end
			end
		end
		
		self.sliders_origin2:SetValues( vec )
		return true
	end
	
	
	self.list_secondarypoint = vgui.Create( "PA_Construct_ListView", self )
		self.list_secondarypoint:Text( "Secondary", "Point", self )
		self.list_secondarypoint:SetPos(765, 30)
		self.list_secondarypoint:SetMultiSelect(false)
		self.list_secondarypoint.DoDoubleClick = function( Line, LineID )
			update_secondary_listview()
			play_sound_true()
		end
	
	
	self.checkbox_relative2 = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_relative2:SetPos(463, 30)
		self.checkbox_relative2:SetSize(100,30)
		self.checkbox_relative2:SetText( "Relative to\nEntity" )
		self.checkbox_relative2.OnChange = function()
			if !update_secondary_listview() and self.checkbox_relative2:GetChecked() then
				self.checkbox_relative2:SetValue(false)
			end
		end
		
	
	self.sliders_origin2 = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_origin2:SetPos(550, 64)
		self.sliders_origin2:SetSize(230, 150)
		
	self.button_zero2 = vgui.Create( "PA_Zero_Button", self )
		self.button_zero2:SetPos(730, 30)
		self.button_zero2:SetSliders( self.sliders_origin2 )
		
	self.button_copy_clipboard2 = vgui.Create( "PA_Copy_Clipboard_Button", self )
		self.button_copy_clipboard2:SetPos(630, 30)
		self.button_copy_clipboard2:SetSliders( self.sliders_origin2 )
	
	
	
	self.button_copy_x = vgui.Create( "PA_Copy_Left_Button", self )
		self.button_copy_x:SetPos(460, 70)
		self.button_copy_x:SetFunction( function()
			self.sliders_origin1.slider_x:SetValue( self.sliders_origin2.slider_x:GetValue() )
			return true
		end )
	
	self.button_copy_y = vgui.Create( "PA_Copy_Left_Button", self )
		self.button_copy_y:SetPos(460, 120)
		self.button_copy_y:SetFunction( function()
			self.sliders_origin1.slider_y:SetValue( self.sliders_origin2.slider_y:GetValue() )
			return true
		end )
		
	self.button_copy_z = vgui.Create( "PA_Copy_Left_Button", self )
		self.button_copy_z:SetPos(460, 170)
		self.button_copy_z:SetFunction( function()
			self.sliders_origin1.slider_z:SetValue( self.sliders_origin2.slider_z:GetValue() )
			return true
		end )
	
	self.button_subtract_x = vgui.Create( "PA_Subtract_Button", self )
		self.button_subtract_x:SetPos(486, 70)
		self.button_subtract_x:SetFunction( function()
			self.sliders_origin1.slider_x:SetValue( self.sliders_origin1.slider_x:GetValue() - self.sliders_origin2.slider_x:GetValue() )
			return true
		end )
		
	self.button_subtract_y = vgui.Create( "PA_Subtract_Button", self )
		self.button_subtract_y:SetPos(486, 120)
		self.button_subtract_y:SetFunction( function()
			self.sliders_origin1.slider_y:SetValue( self.sliders_origin1.slider_y:GetValue() - self.sliders_origin2.slider_y:GetValue() )
			return true
		end )
		
	self.button_subtract_z = vgui.Create( "PA_Subtract_Button", self )
		self.button_subtract_z:SetPos(486, 170)
		self.button_subtract_z:SetFunction( function()
			self.sliders_origin1.slider_z:SetValue( self.sliders_origin1.slider_z:GetValue() - self.sliders_origin2.slider_z:GetValue() )
			return true
		end )
	
	self.button_add_x = vgui.Create( "PA_Add_Button", self )
		self.button_add_x:SetPos(512, 70)
		self.button_add_x:SetFunction( function()
			self.sliders_origin1.slider_x:SetValue( self.sliders_origin1.slider_x:GetValue() + self.sliders_origin2.slider_x:GetValue() )
			return true
		end )
		
	self.button_add_y = vgui.Create( "PA_Add_Button", self )
		self.button_add_y:SetPos(512, 120)
		self.button_add_y:SetFunction( function()
			self.sliders_origin1.slider_y:SetValue( self.sliders_origin1.slider_y:GetValue() + self.sliders_origin2.slider_y:GetValue() )
			return true
		end )
		
	self.button_add_z = vgui.Create( "PA_Add_Button", self )
		self.button_add_z:SetPos(512, 170)
		self.button_add_z:SetFunction( function()
			self.sliders_origin1.slider_z:SetValue( self.sliders_origin1.slider_z:GetValue() + self.sliders_origin2.slider_z:GetValue() )
			return true
		end )
	
	
	AddMenuText( "Point Functions", 10, self:GetTall()/2 - 10, self )
		
	self.functions_list_functionpoints = vgui.Create( "PA_Construct_ListView", self )
		self.functions_list_functionpoints:SetPos(15, 250)
		self.functions_list_functionpoints:Text( "Function Selection", "Point", self )
		self.functions_list_functionpoints.OnRowSelected = function( LineID, Line )
		end
	
	self.functions_button_negate = vgui.Create( "PA_Function_Button", self )
		self.functions_button_negate:SetPos(160, 250)
		self.functions_button_negate:SetText( "Negate Values" )
		self.functions_button_negate:SetToolTip( "Negate values" )
		self.functions_button_negate:SetFunction( function()
			self.sliders_origin1:SetValues(-self.sliders_origin1:GetValues())
			return true
		end )
		
	self.functions_button_copy_origin = vgui.Create( "PA_Function_Button", self )
		self.functions_button_copy_origin:SetPos(405, 250)
		self.functions_button_copy_origin:SetText( "Copy Point" )
		self.functions_button_copy_origin:SetToolTip( "Copy the selected point's values into the primary sliders" )
		self.functions_button_copy_origin:SetFunction( function()
			local selection = self.functions_list_functionpoints:GetSelected()
			if #selection == 1 then
				local pointID = selection[1]:GetID()
				if PA_funcs.construct_exists( "Point", pointID ) then
					local point = PA_funcs.point_global(pointID)
					self.sliders_origin1:SetValues(point.origin)
					return true
				end
			else
				Warning("Select 1 point")
			end
			return false
		end )
		
	self.functions_button_pointsaverage = vgui.Create( "PA_Function_Button", self )
		self.functions_button_pointsaverage:SetPos(650, 250)
		self.functions_button_pointsaverage:SetText( "Centre of points" )
		self.functions_button_pointsaverage:SetToolTip( "Set primary values to the centre (average) of the selected points" )
		self.functions_button_pointsaverage:SetFunction( function()
			local selection_table = {}
			selection_table = self.functions_list_functionpoints:GetSelected()
			if #selection_table > 1 then
				local vec = PA_funcs.point_function_average(selection_table)
				if vec then
					self.sliders_origin1:SetValues( vec )
					return true
				end
			else
				Warning("Select 2 or more points")
			end
			return false
		end )
	
	
	self.button_moveentity = vgui.Create( "PA_Move_Button", self )
		self.button_moveentity:SetPos(self:GetWide() - 160, self:GetTall() - 90)
		self.button_moveentity:SetSize(100, 50)
		self.button_moveentity:SetText( "Move Entity" )
		self.button_moveentity:SetToolTip( "Move entity by Primary -> Secondary" )
		self.button_moveentity:SetFunction( function()
			local selected_point1 = self.list_primarypoint:GetSelectedLine()
			local selected_point2 = self.list_secondarypoint:GetSelectedLine()
			
			if !selected_point1 or !selected_point2 then
				Warning("Select both a primary and secondary point")
				return false
			end
			
			if selected_point1 == selected_point2 then
				Warning("Cannot move between the same point!")
				return false
			end
			
			local point1 = PA_funcs.point_global(selected_point1)
			local point2 = PA_funcs.point_global(selected_point2)
			
			if !point1 or !point2 then
				Warning("Points not correctly defined")
				return false
			end
			
			if !PA_funcs.move_entity(point1.origin, point2.origin, PA_activeent) then return false end
		end )
	
end

function POINTS_TAB:Paint()
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), BGColor_Point)
	draw.RoundedBox(6, 5, 15, 440, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 455, 15, 430, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 5, self:GetTall()/2 + 15, self:GetWide() - 10, self:GetTall()/2 - 20, BGColor)
end

vgui.Register("PA_Points_Tab", POINTS_TAB, "DPanel")


//********************************************************************************************************************//
// Lines Tab
//********************************************************************************************************************//


local LINES_TAB = {}
function LINES_TAB:Init()
	self:CopyBounds( self:GetParent() )
	
	AddMenuText( "Line Adjustment", 10, 5, self )
	
	local function update_sliders(startpoint, endpoint, direction, length, angle)
		self.sliders_startpoint:SetValues(startpoint)
		self.sliders_endpoint:SetValues(endpoint)
		self.sliders_direction:SetValues(direction)
		self.slider_length:SetValue(length)
	
		if direction == Vector(0,0,0) then angle = Angle(0,0,0) end
		if math.abs(angle.p) == 90 then	angle.y = 0	end
		
		self.slider1_ang_p:SetValue(angle.p)
		self.slider1_ang_y:SetValue(angle.y)
		return true
	end
	
	local function update_primary_listview()
		local selection = self.list_primary:GetSelectedLine()
		if !selection then return false end
		
		local line_temp = PA_funcs.line_global( selection )
		local startpoint, endpoint, direction, length, angle
		
		if !line_temp then
			startpoint = Vector(0,0,0)
			endpoint = Vector(0,0,0)
			direction = Vector(0,0,0)
			length = 0
			angle = Angle(0,0,0)
		else
			startpoint = line_temp.startpoint
			endpoint = line_temp.endpoint
			if self.checkbox_relative:GetChecked() then
				if IsValid(PA_activeent) then
					startpoint = PA_activeent:WorldToLocal(startpoint)
					endpoint = PA_activeent:WorldToLocal(endpoint)
				else
					self.checkbox_relative:SetValue(false)
				end
			end
			
			local vec = endpoint - startpoint
			direction = vec:GetNormal()
			length = vec:Length()
			
			if direction:Length() == 0 then
				angle = Angle(0,0,0)
			else
				angle = NormAng(vec:Angle())
			end
		end
		
		return update_sliders(startpoint, endpoint, direction, length, angle)
	end
	
	
	self.list_primary = vgui.Create( "PA_Construct_ListView", self )
		self.list_primary:Text( "Primary", "Line", self )
		self.list_primary:SetToolTip( "Double click to update sliders" )
		self.list_primary:SetPos(15, 30)
		self.list_primary:SetMultiSelect(false)
		self.list_primary.DoDoubleClick = function( Line, LineID )
			update_primary_listview()
			play_sound_true()
		end
	
	self.button_set = vgui.Create( "PA_Function_Button", self )
		self.button_set:SetPos(140, 69)
		self.button_set:SetSize(80, 70)
		self.button_set:SetText( "Set" )
		self.button_set:SetToolTip( "Set the selected line according to these start/end point values" )
		self.button_set:SetFunction( function()
			local selection = self.list_primary:GetSelectedLine()
			if selection then
				local startpoint = self.sliders_startpoint:GetValues()
				local endpoint = self.sliders_endpoint:GetValues()
				
				if startpoint == endpoint then
					Warning("Cannot set line of zero length")
					return false
				end
				
				if self.checkbox_relative:GetChecked() and IsValid(PA_activeent) then
					startpoint = PA_activeent:LocalToWorld(startpoint)
					endpoint = PA_activeent:LocalToWorld(endpoint)
				end
				
				return PA_funcs.set_line( selection, startpoint, endpoint )
			end
			Warning("No selection")
			return false
		end )
	
	self.button_delete = vgui.Create( "PA_Function_Button", self )
		self.button_delete:SetPos(140, 144)
		self.button_delete:SetSize(80, 25)
		self.button_delete:SetText( "Delete" )
		self.button_delete:SetFunction( function()
			local selection = self.list_primary:GetSelectedLine()
			if selection then
				return PA_funcs.delete_line(selection)
			end
			Warning("No selection")
			return false
		end )
	
	self.button_deleteall = vgui.Create( "PA_Function_Button", self )
		self.button_deleteall:SetPos(140, 174)
		self.button_deleteall:SetSize(80, 25)
		self.button_deleteall:SetText( "Delete All" )
		self.button_deleteall:SetFunction( function()
			return PA_funcs.delete_lines()
		end )
	
	self.checkbox_relative = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_relative:SetPos(140, 30)
		self.checkbox_relative:SetText( "Relative to\nEntity" )
		self.checkbox_relative:SetSize(100,30)
		self.checkbox_relative.OnChange = function()
			if !update_primary_listview() and self.checkbox_relative:GetChecked() then
				self.checkbox_relative:SetValue(false)
			end
		end
	
	
	AddMenuText( "Start Point", 295, 20, self )
	
	local function update_sliders_point()
		local startpoint, endpoint, direction, length, angle
		
		startpoint = self.sliders_startpoint:GetValues()
		endpoint = self.sliders_endpoint:GetValues()
		local vec = endpoint - startpoint
		direction = vec:GetNormal()
		length = vec:Length()
		angle = NormAng(vec:Angle())
		
		return update_sliders(startpoint, endpoint, direction, length, angle)
	end
	
	self.sliders_startpoint = vgui.Create( "PA_XYZ_Sliders", self )
		-- self.sliders_startpoint:SetPos(200, 44)
		self.sliders_startpoint:SetPos(255, 44)
		-- self.sliders_startpoint:SetSize(220, 150)
		self.sliders_startpoint:SetSize(160, 150)
	
	self.button_zero_startpoint = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_startpoint:SetPos(380, 15)
		self.button_zero_startpoint:SetSliders( self.sliders_startpoint )
	
	self.button_update_startpoint = vgui.Create( "PA_Update_Button", self )
		self.button_update_startpoint:SetPos(280, 183)
		self.button_update_startpoint:SetFunction( function()
			return update_sliders_point()
		end )
	
	
	AddMenuText( "End Point", 459, 20, self )
	
	self.sliders_endpoint = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_endpoint:SetPos(415, 44) -- (360, 44)
		self.sliders_endpoint:SetSize(160, 150)
	
	self.button_zero_endpoint = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_endpoint:SetPos(540, 15)
		self.button_zero_endpoint:SetSliders( self.sliders_endpoint )
	
	self.button_update_endpoint = vgui.Create( "PA_Update_Button", self )
		self.button_update_endpoint:SetPos(440, 183)
		self.button_update_endpoint:SetFunction( function()
			return update_sliders_point()
		end )
	
	
	AddMenuText( "Direction", 619, 20, self )
	
	local function update_sliders_direction()
		local startpoint, endpoint, direction, length, angle
		
		startpoint = self.sliders_startpoint:GetValues()
		direction = self.sliders_direction:GetValues():GetNormal()
		if direction == Vector(0,0,0) then direction = Vector(1,0,0) end
		
		length = self.slider_length:GetValue()
		endpoint = startpoint + direction * length
		angle = NormAng(direction:Angle())
		
		return update_sliders(startpoint, endpoint, direction, length, angle)
	end
	
	self.sliders_direction = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_direction:SetPos(575, 44) -- (520, 44)
		self.sliders_direction:SetSize(160, 150)
		self.sliders_direction:SetRange(1)
	
	self.button_zero_direction = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_direction:SetPos(700, 15)
		self.button_zero_direction:SetSliders( self.sliders_direction )
	
	self.button_update_direction = vgui.Create( "PA_Update_Button", self )
		self.button_update_direction:SetPos(600, 183)
		self.button_update_direction:SetFunction( function()
			return update_sliders_direction()
		end )
		
	
	AddMenuText( "Length / Angle", 764, 20, self )
		
	local function update_sliders_length()
		local startpoint, endpoint, direction, length, angle
		
		startpoint = self.sliders_startpoint:GetValues()
		angle = Angle(self.slider1_ang_p:GetValue(), self.slider1_ang_y:GetValue(), 0)
		direction = angle:Forward()
		length = self.slider_length:GetValue()
		endpoint = startpoint + direction * length
		
		return update_sliders(startpoint, endpoint, direction, length, angle)
	end
	
	self.slider_length = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_length:SetPos(735, 49)
		self.slider_length:SetSize(160, 20)
		self.slider_length:SetText( "Length" )
		self.slider_length.Label:SetWide( 35 )
		self.slider_length:SetMinMax( 0.001, 1000 )
	
	self.slider1_ang_p = vgui.Create( "PA_XYZ_Slider", self )
		self.slider1_ang_p:SetPos(735, 99)
		self.slider1_ang_p:SetSize(160, 20)
		self.slider1_ang_p:SetText( "Pitch" )
		self.slider1_ang_p.Label:SetWide( 35 )
		self.slider1_ang_p:SetMinMax( -90, 90 )
		
	self.slider1_ang_y = vgui.Create( "PA_XYZ_Slider", self )
		self.slider1_ang_y:SetPos(735, 149)
		self.slider1_ang_y:SetSize(160, 20)
		self.slider1_ang_y:SetText( "Yaw" )
		self.slider1_ang_y.Label:SetWide( 35 )
		self.slider1_ang_y:SetMinMax( -180, 180 )
	
	self.button_update_length = vgui.Create( "PA_Update_Button", self )
		self.button_update_length:SetPos(760, 183)
		self.button_update_length:SetFunction( function()
			return update_sliders_length()
		end )
	
	
	AddMenuText( "Line Functions", 10, self:GetTall()/2 - 10, self )
	
	self.functions_list_functionlines = vgui.Create( "PA_Construct_ListView", self )
		self.functions_list_functionlines:Text( "Function Selection", "Line" )
		self.functions_list_functionlines:SetPos(15, 250)
		self.functions_list_functionlines.OnRowSelected = function( panel, line )
		end
	
	
	self.functions_button_reversedirection = vgui.Create( "PA_Function_Button", self )
		self.functions_button_reversedirection:SetPos(160, 250)
		self.functions_button_reversedirection:SetText( "Reverse Direction" )
		self.functions_button_reversedirection:SetToolTip( "Reverse direction values" )
		self.functions_button_reversedirection:SetFunction( function()
			self.sliders_direction:SetValues(Vector(0,0,0) - self.sliders_direction:GetValues())
			return update_sliders_direction()
		end )
	
	self.functions_button_reverseline = vgui.Create( "PA_Function_Button", self )
		self.functions_button_reverseline:SetPos(160, 280)
		self.functions_button_reverseline:SetText( "Switch Start/End" )
		self.functions_button_reverseline:SetToolTip( "Switch start point and end point" )
		self.functions_button_reverseline:SetFunction( function()
			local startpoint = self.sliders_startpoint:GetValues()
			local endpoint = self.sliders_endpoint:GetValues()
			self.sliders_startpoint:SetValues(endpoint)
			self.sliders_endpoint:SetValues(startpoint)
			
			return update_sliders_point()
		end )
	
	local function single_line_selection()
		local selection = self.functions_list_functionlines:GetSelected()
		if #selection == 1 then
			local lineID = selection[1]:GetID()
			if PA_funcs.construct_exists( "Line", lineID ) then
				local line = PA_funcs.line_global(lineID)
				return line
			end
		end
		Warning("Select 1 line")
		return false
	end
	
	self.functions_button_default_length = vgui.Create( "PA_Function_Button", self )
		self.functions_button_default_length:SetPos(160, 310)
		self.functions_button_default_length:SetText( "Set Default Length" )
		self.functions_button_default_length:SetToolTip( "Sets the default length to the current length slider value" )
		self.functions_button_default_length:SetFunction( function()
			local length = self.slider_length:GetValue()
			if !(length > 0) then
				Warning("Length must be greater than 0")
				return false
			end
			RunConsoleCommand( PA_.."default_linelength", length )			
			Message("Default line length set to " .. tostring(length) .. " units")
			return true
		end )
	
	
	self.functions_button_copy_start = vgui.Create( "PA_Function_Button", self )
		self.functions_button_copy_start:SetPos(405, 250)
		self.functions_button_copy_start:SetText( "Copy Start Point" )
		self.functions_button_copy_start:SetToolTip( "Copy start point from the selected line" )
		self.functions_button_copy_start:SetFunction( function()
			local line = single_line_selection()
			if !line then
				return false
			end
			self.sliders_startpoint:SetValues(line.startpoint)
			return true
		end )
	
	self.functions_button_copy_end = vgui.Create( "PA_Function_Button", self )
		self.functions_button_copy_end:SetPos(405, 280)
		self.functions_button_copy_end:SetText( "Copy End Point" )
		self.functions_button_copy_end:SetToolTip( "Copy end point from the selected line" )
		self.functions_button_copy_end:SetFunction( function()
			local line = single_line_selection()
			if !line then
				return false
			end
			self.sliders_endpoint:SetValues(line.endpoint)
			return true
		end )
	
	self.functions_button_copy_dir = vgui.Create( "PA_Function_Button", self )
		self.functions_button_copy_dir:SetPos(405, 310)
		self.functions_button_copy_dir:SetText( "Copy Direction" )
		self.functions_button_copy_dir:SetToolTip( "Copy direction from the selected line" )
		self.functions_button_copy_dir:SetFunction( function()
			local line = single_line_selection()
			if !line then
				return false
			end
			local dir = (line.endpoint - line.startpoint):GetNormal()
			self.sliders_direction:SetValues(dir)
			return true
		end )
	
	self.functions_button_copy_length = vgui.Create( "PA_Function_Button", self )
		self.functions_button_copy_length:SetPos(405, 340)
		self.functions_button_copy_length:SetText( "Copy Length" )
		self.functions_button_copy_length:SetToolTip( "Copy length from the selected line" )
		self.functions_button_copy_length:SetFunction( function()
			local line = single_line_selection()
			if !line then
				return false
			end
			local length = (line.endpoint - line.startpoint):Length()
			self.slider_length:SetValue(length)
			return true
		end )
	
	self.functions_button_perpendicular = vgui.Create( "PA_Function_Button", self )
		self.functions_button_perpendicular:SetPos(650, 250)
		self.functions_button_perpendicular:SetText( "Find Perpendicular Direction" )
		self.functions_button_perpendicular:SetToolTip( "Set direction perpendicular to two lines" )
		self.functions_button_perpendicular:SetFunction( function()
			local selection = self.functions_list_functionlines:GetSelected()
			if #selection == 2 then
				local lineID1, lineID2 = selection[1]:GetID(), selection[2]:GetID()
				local dir = PA_funcs.line_function_perpendicular( lineID1, lineID2 )
				if dir then
					self.sliders_direction:SetValues(dir)
					return update_sliders_direction()
				end
			else
				Warning("Select 2 lines")
			end
			return false
		end )
	
	self.functions_button_addlines = vgui.Create( "PA_Function_Button", self )
		self.functions_button_addlines:SetPos(650, 280)
		self.functions_button_addlines:SetText( "Add Line Vectors" )
		self.functions_button_addlines:SetToolTip( "Add the selected lines as vectors to the current endpoint" )
		self.functions_button_addlines:SetFunction( function()
			local selection = self.functions_list_functionlines:GetSelected()
			if !selection then
				Warning("Select at least 1 line")
				return false
			end
			
			local lineID, line
			local totalvec = self.sliders_endpoint:GetValues()
			
			for k, v in pairs (selection) do
				lineID = v:GetID()
				if PA_funcs.construct_exists( "Line", lineID ) then
					line = PA_funcs.line_global( lineID )
					totalvec = totalvec + line.endpoint - line.startpoint
				end
			end
			
			self.sliders_endpoint:SetValues( totalvec )
			return update_sliders_point()
		end )
	
	
	self.button_moveentity = vgui.Create( "PA_Move_Button", self )
		self.button_moveentity:SetPos(self:GetWide() - 160, self:GetTall() - 90)
		self.button_moveentity:SetSize(100, 50)
		self.button_moveentity:SetText( "Move Entity" )
		self.button_moveentity:SetToolTip( "Move entity by line" )
		self.button_moveentity:SetFunction( function()		
			local selection = self.list_primary:GetSelectedLine()
			if !selection then
				Warning("Select a line")
				return false
			end
			
			if !PA_funcs.construct_exists( "Line", selection ) then
				Warning("Line not correctly defined")
				return false
			end
			
			local line = PA_funcs.line_global(selection)
			if !PA_funcs.move_entity(line.startpoint, line.endpoint, PA_activeent) then return false end
		end )
end

function LINES_TAB:Paint()
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), BGColor_Line)
	draw.RoundedBox(6, 5, 15, 230, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 250, 15, 150, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 410, 15, 150, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 570, 15, 150, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 730, 15, 150, 65, BGColor)
	draw.RoundedBox(6, 730, 85, 150, 130, BGColor)
	draw.RoundedBox(6, 5, self:GetTall()/2 + 15, self:GetWide() - 10, self:GetTall()/2 - 20, BGColor)
end

vgui.Register("PA_Lines_Tab", LINES_TAB, "DPanel")


//********************************************************************************************************************//
// Planes  Tab
//********************************************************************************************************************//


local PLANES_TAB = {}
function PLANES_TAB:Init()
	self:CopyBounds( self:GetParent() )
	
	AddMenuText( "Plane Adjustment", 10, 5, self )
	
	local function update_sliders(origin, normal, angle)
		if origin then self.sliders_origin:SetValues(origin) end
		if normal then self.sliders_normal:SetValues(normal) end
		
		if angle then
			if !normal or normal == Vector(0,0,0) then angle = Angle(0,0,0) end
			if math.abs(angle.p) > 89.999 then	angle.y = 0	end
			
			self.slider_ang_p:SetValue(angle.p)
			self.slider_ang_y:SetValue(angle.y)
		end
		return true
	end
	
	local function update_primary_listview()
		local selection = self.list_primary:GetSelectedLine()
		if !selection then return false end
		
		local plane_temp = PA_funcs.plane_global( selection )
		local origin, normal, angle
		
		if !plane_temp then
			origin = Vector(0,0,0)
			normal = Vector(0,0,0)
			angle = Angle(0,0,0)
		else
			if self.checkbox_relative:GetChecked() then
				if IsValid(PA_activeent) then
					plane_temp.origin = PA_activeent:WorldToLocal(plane_temp.origin)
					plane_temp.normal = ( PA_activeent:WorldToLocal(PA_activeent:GetPos() + plane_temp.normal) ):GetNormal()
				else
					self.checkbox_relative:SetValue(false)
				end
			end
			
			origin = plane_temp.origin
			normal = plane_temp.normal
			
			if normal:Length() == 0 then
				angle = Angle(0,0,0)
			else
				angle = NormAng(normal:Angle())
			end
		end
		
		return update_sliders(origin, normal, angle)
	end
	
	
	self.list_primary = vgui.Create( "PA_Construct_ListView", self )
		self.list_primary:Text( "Primary", "Plane", self )
		self.list_primary:SetToolTip( "Double click to update sliders" )
		self.list_primary:SetPos(15, 30)
		self.list_primary:SetMultiSelect(false)
		self.list_primary.DoDoubleClick = function( Line, LineID )
			update_primary_listview()
			play_sound_true()
		end
	
	
	self.button_set = vgui.Create( "PA_Function_Button", self )
		self.button_set:SetPos(140, 69)
		self.button_set:SetSize(80, 70)
		self.button_set:SetText( "Set" )
		self.button_set:SetToolTip( "Set the selected plane according to these values" )
		self.button_set:SetFunction( function()
			local selection = self.list_primary:GetSelectedLine()
			if selection then
				local origin = self.sliders_origin:GetValues()
				local normal = self.sliders_normal:GetValues()
				
				if self.checkbox_relative:GetChecked() and IsValid(PA_activeent) then
					origin = PA_activeent:LocalToWorld(origin)
					normal = ( PA_activeent:LocalToWorld(normal) - PA_activeent:GetPos()):GetNormal()
				end
				
				return PA_funcs.set_plane( selection, origin, normal )
			end
			Warning("No selection")
			return false
		end )
	
	self.button_delete = vgui.Create( "PA_Function_Button", self )
		self.button_delete:SetPos(140, 144)
		self.button_delete:SetSize(80, 25)
		self.button_delete:SetText( "Delete" )
		self.button_delete:SetFunction( function()
			local selection = self.list_primary:GetSelectedLine()
			if selection then
				return PA_funcs.delete_plane(selection)
			end
			Warning("No selection")
			return false
		end )
	
	self.button_deleteall = vgui.Create( "PA_Function_Button", self )
		self.button_deleteall:SetPos(140, 174)
		self.button_deleteall:SetSize(80, 25)
		self.button_deleteall:SetText( "Delete All" )
		self.button_deleteall:SetFunction( function()
			return PA_funcs.delete_planes()
		end )
	
	self.checkbox_relative = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_relative:SetPos(140, 30)
		self.checkbox_relative:SetText( "Relative to\nEntity" )
		self.checkbox_relative:SetSize(100,30)
		self.checkbox_relative.OnChange = function()
			if !update_primary_listview() and self.checkbox_relative:GetChecked() then
				self.checkbox_relative:SetValue(false)
			end
		end
	
	
	AddMenuText( "Origin", 328, 20, self )
	
	self.sliders_origin = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_origin:SetPos(255, 44)
		self.sliders_origin:SetSize(210, 138)
	
	self.button_zero_origin = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_origin:SetPos(430, 15)
		self.button_zero_origin:SetSliders( self.sliders_origin )
	
	
	AddMenuText( "Normal", 536, 20, self )
	
	self.sliders_normal = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_normal:SetPos(470, 44)
		self.sliders_normal:SetSize(210, 138)
	
	local function update_sliders_normal()
		local normal = self.sliders_normal:GetValues():GetNormal()
		local angle = NormAng(normal:Angle())
		return update_sliders(origin, normal, angle)
	end
	
	self.button_zero_normal = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_normal:SetPos(645, 15)
		self.button_zero_normal:SetSliders( self.sliders_normal )
	
	self.button_update_normal = vgui.Create( "PA_Update_Button", self )
		self.button_update_normal:SetPos(517, 183)
		self.button_update_normal:SetFunction( function()
			return update_sliders_normal()
		end )
	
	
	AddMenuText( "Angle", 757, 20, self )
	
	self.slider_ang_p = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_ang_p:SetPos( 685, 50 )
		self.slider_ang_p:SetSize( 210, 40 )
		self.slider_ang_p:SetText( "Pitch" )
		self.slider_ang_p.Label:SetWide( 25 )
		self.slider_ang_p:SetMinMax( -90, 90 )
	
	self.slider_ang_y = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_ang_y:SetPos( 685, 120 )
		self.slider_ang_y:SetSize( 210, 40 )
		self.slider_ang_y:SetText( "Yaw" )
		self.slider_ang_y.Label:SetWide( 25 )
		self.slider_ang_y:SetMinMax( -180, 180 )
	
	self.button_update_angle = vgui.Create( "PA_Update_Button", self )
		self.button_update_angle:SetPos(732, 183)
		self.button_update_angle:SetFunction( function()
			local angle = Angle( self.slider_ang_p:GetValue(), self.slider_ang_y:GetValue(), 0 )
			local vec = angle:Forward()
			self.sliders_normal:SetValues(vec)
			return true
		end )
	
	
	local function single_plane_selection()
		local selection = self.functions_list_functionplanes:GetSelected()
		if #selection == 1 then
			local planeID = selection[1]:GetID()
			if PA_funcs.construct_exists( "Plane", planeID ) then
				local plane = PA_funcs.plane_global(planeID)
				return plane
			end
		end
		Warning("Select 1 plane")
		return false
	end
	
	
	AddMenuText( "Plane Functions", 10, self:GetTall()/2 - 10, self )
	
	self.functions_list_functionplanes = vgui.Create( "PA_Construct_ListView", self )
		self.functions_list_functionplanes:Text( "Function Selection", "Plane" )
		self.functions_list_functionplanes:SetPos(15, 250)
		self.functions_list_functionplanes.OnRowSelected = function( panel, line )
		end
		
	self.functions_button_reversenormal = vgui.Create( "PA_Function_Button", self )
		self.functions_button_reversenormal:SetPos(160, 250)
		self.functions_button_reversenormal:SetText( "Reverse Normal" )
		self.functions_button_reversenormal:SetToolTip( "Reverse normal values" )
		self.functions_button_reversenormal:SetFunction( function()
			self.sliders_normal:SetValues(-self.sliders_normal:GetValues())
			return update_sliders_normal()
		end )
	
	self.functions_button_copy_origin = vgui.Create( "PA_Function_Button", self )
		self.functions_button_copy_origin:SetPos(405, 250)
		self.functions_button_copy_origin:SetText( "Copy Origin" )
		self.functions_button_copy_origin:SetToolTip( "Copy origin from the selected plane" )
		self.functions_button_copy_origin:SetFunction( function()
			local plane = single_plane_selection()
			if !plane then
				return false
			end
			self.sliders_origin:SetValues(plane.origin)
			return true
		end )
	
	self.functions_button_copy_normal = vgui.Create( "PA_Function_Button", self )
		self.functions_button_copy_normal:SetPos(405, 280)
		self.functions_button_copy_normal:SetText( "Copy Normal" )
		self.functions_button_copy_normal:SetToolTip( "Copy normal from the selected plane" )
		self.functions_button_copy_normal:SetFunction( function()
			local plane = single_plane_selection()
			if !plane then
				return false
			end
			self.sliders_normal:SetValues(plane.normal)
			return update_sliders_normal()
		end )
	
	self.functions_button_perpendicular = vgui.Create( "PA_Function_Button", self )
		self.functions_button_perpendicular:SetPos(650, 250)
		self.functions_button_perpendicular:SetText( "Find Perpendicular Normal" )
		self.functions_button_perpendicular:SetToolTip( "Set normal perpendicular to two planes" )
		self.functions_button_perpendicular:SetFunction( function()
			local selection = self.functions_list_functionplanes:GetSelected()
			if #selection == 2 then
				local planeID1, planeID2 = selection[1]:GetID(), selection[2]:GetID()
				local normal = PA_funcs.plane_function_perpendicular( planeID1, planeID2 )
				if normal then
					self.sliders_normal:SetValues(normal)
					return update_sliders_normal()
				end
			else
				Warning("Select 2 planes")
			end
			return false
		end )
end

function PLANES_TAB:Paint()
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), BGColor_Plane)
	draw.RoundedBox(6, 5, 15, 230, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 245, 15, 205, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 460, 15, 205, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 675, 15, 205, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 5, self:GetTall()/2 + 15, self:GetWide() - 10, self:GetTall()/2 - 20, BGColor)
end

vgui.Register("PA_Planes_Tab", PLANES_TAB, "DPanel")


//********************************************************************************************************************//
// Move Constructs Tab
//********************************************************************************************************************//


local MOVE_TAB = {}
function MOVE_TAB:Init()	
	self:CopyBounds( self:GetParent() )
	
	self.panel_multiselect = vgui.Create( "PA_Construct_Multiselect", self )
	
	AddMenuText( "Primary Selection", 10, 5, self.panel_multiselect.colour_panel_1 )
	
	
	// Rotate Around Axis ************************************************************************************************
	
	AddMenuText( "Rotate Around Axis", 575, 5, self )
	
	self.list_line_axis = vgui.Create( "PA_Construct_ListView", self )
		self.list_line_axis:Text( "Axis Selection", "Line", self )
		self.list_line_axis:SetPos(585, 30)
		self.list_line_axis:SetMultiSelect(false)
	
	self.slider_rotate_axis = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_rotate_axis:SetPos( 700, 55 )
		self.slider_rotate_axis:SetSize( 200, 50 )
		self.slider_rotate_axis:SetText( "Angle" )
		self.slider_rotate_axis.Label:SetWide( 30 )
		self.slider_rotate_axis:SetMinMax( -180, 180 )
	
	// If no pivot, then the constructs won't move; only their directions will change
	local function rotate_constructs( selection_constructs, pivot, axis, degrees )
		if pivot then
			for k, v in pairs ( selection_constructs.points ) do
				local point = PA_funcs.point_global(v)
				
				local vec = point.origin - pivot
				local ang = vec:Angle()
				ang:RotateAroundAxis( axis, degrees )
				
				vec = ang:Forward() * vec:Length()
				PA_funcs.set_point( v, pivot + vec )
			end
		end
		
		for k, v in pairs ( selection_constructs.lines ) do
			local line = PA_funcs.line_global(v)
			local vec1 = Vector(0,0,0)
			local pivot_temp = pivot
			
			if pivot_temp then
				vec1 = line.startpoint - pivot_temp
				local ang1 = vec1:Angle()
				ang1:RotateAroundAxis( axis, degrees )
				vec1 = ang1:Forward() * vec1:Length()
			else
				pivot_temp = line.startpoint
			end
			
			local vec2 = line.endpoint - pivot_temp
			local ang2 = vec2:Angle()
			ang2:RotateAroundAxis( axis, degrees )
			vec2 = ang2:Forward() * vec2:Length()
			
			PA_funcs.set_line( v, pivot_temp + vec1, pivot_temp + vec2 )
		end
		
		for k, v in pairs ( selection_constructs.planes ) do
			local plane = PA_funcs.plane_global(v)
			local vec1 = Vector(0,0,0)
			local pivot_temp = pivot
			
			if pivot_temp then
				vec1 = plane.origin - pivot_temp
				local ang1 = vec1:Angle()
				ang1:RotateAroundAxis( axis, degrees )
				vec1 = ang1:Forward() * vec1:Length()
			else
				pivot_temp = plane.origin
			end	
			
			local vec2 = plane.normal
			local ang2 = vec2:Angle()
			ang2:RotateAroundAxis( axis, degrees )
			vec2 = ang2:Forward()
			
			PA_funcs.set_plane( v, pivot_temp + vec1, vec2 )
		end
		
		return true
	end
	
	self.button_axisrotate_angle = vgui.Create( "PA_Function_Button", self )
		self.button_axisrotate_angle:SetPos(750, 150)
		self.button_axisrotate_angle:SetSize(80, 25)
		self.button_axisrotate_angle:SetText( "Rotate" )
		self.button_axisrotate_angle:SetToolTip( "Rotate constructs around the selected axis" )
		self.button_axisrotate_angle:SetFunction( function()
			local selected_line = self.list_line_axis:GetSelectedLine()
			
			if !selected_line then
				Warning("Select an axis line")
				return false
			end
			
			if !PA_funcs.construct_exists( "Line", selected_line ) then
				Warning("Line not correctly defined")
				return false
			end
			
			// Check construct selections
			local selection_constructs = self.panel_multiselect:GetSelection()
			
			if !selection_constructs then
				Warning( "No valid constructs selected for move" )
				return false
			end
			
			local degrees = self.slider_rotate_axis:GetValue()
			if degrees == 0 then return false end
			
			local line = PA_funcs.line_global(selected_line)
			local axis = ( line.endpoint - line.startpoint ):GetNormal()
			
			// Check pivot selection
			local pivot_selection = self.list_pivotpoint:GetSelectedLine()
			local pivot = line.startpoint
			if pivot_selection then
				if PA_funcs.construct_exists( "Point", pivot_selection ) then
					pivot = PA_funcs.point_global( pivot_selection ).origin
				end
			end
			
			return rotate_constructs( selection_constructs, pivot, axis, degrees )
		end )
	
	self.button_negate_axisangle = vgui.Create( "PA_Negate_Button", self )
		self.button_negate_axisangle:SetPos(779, 50)
		self.button_negate_axisangle:SetFunction( function()
			self.slider_rotate_axis:SetValue( -self.slider_rotate_axis:GetValue() )
			return true
		end )
	
	
	// Move Constructs ************************************************************************************************
	
	self.colour_panel_1 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_1:SetPos(0, 220)
	
	AddMenuText( "Move Constructs", 10, 5, self.colour_panel_1 )
	
	self.list_point_1 = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_point_1:Text( "Point 1 Selection", "Point", self.colour_panel_1 )
		self.list_point_1:SetPos(20, 30)
		self.list_point_1:SetMultiSelect(false)
		self.list_point_1:SetVisible(false)
	
	
	self.colour_panel_2 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_2:SetPos(150, 220)
	
	self.list_point_2 = vgui.Create( "PA_Construct_ListView", self.colour_panel_2 )
		self.list_point_2:Text( "Point 2 Selection", "Point", self.colour_panel_2 )
		self.list_point_2:SetPos(20, 30)
		self.list_point_2:SetMultiSelect(false)
		self.list_point_2:SetVisible(false)
	
	self.list_line_1 = vgui.Create( "PA_Construct_ListView", self.colour_panel_2 )
		self.list_line_1:Text( "Line Selection", "Line", self.colour_panel_2 )
		self.list_line_1:SetPos(20, 30)
		self.list_line_1:SetMultiSelect(false)
		self.list_line_1:SetVisible(false)
	
	self.list_plane_1 = vgui.Create( "PA_Construct_ListView", self.colour_panel_2 )
		self.list_plane_1:Text( "Plane Selection", "Plane", self.colour_panel_2 )
		self.list_plane_1:SetPos(20, 30)
		self.list_plane_1:SetMultiSelect(false)
		self.list_plane_1:SetVisible(false)
	
	self.button_move_constructs = vgui.Create( "PA_Function_Button", self )
		self.button_move_constructs:SetPos(320, 360)
		self.button_move_constructs:SetSize(90, 60)
		self.button_move_constructs:SetText( "Set" )
		self.button_move_constructs:SetToolTip( "Move the selected constructs" )
		self.button_move_constructs:SetFunction( function()
			if !self.activebutton then
				Warning("No function selected")
				return false
			end
			
			local selection_type = self.activebutton.selections
			local selection_primary, selection_1, selection_2, selection_3
			
			// Check primary selection
			if selection_type == "Point" then
				local point1, point2 = self.list_point_1:GetSelectedLine(), self.list_point_2:GetSelectedLine()
				if !point1 then
					Warning( "Select Point 1" ) return false
				elseif !point2 then
					Warning( "Select Point 2" ) return false
				elseif !PA_funcs.construct_exists( "Point", point1 ) then
					Warning( "Point " .. tostring(point1) .. " not defined" ) return false
				elseif !PA_funcs.construct_exists( "Point", point2 ) then
					Warning( "Point " .. tostring(point2) .. " not defined" ) return false
				end
				selection_primary = { point1, point2 }
			elseif selection_type == "Line" then
				local line = self.list_line_1:GetSelectedLine()
				if !line then
					Warning( "Select Line 1" ) return false
				elseif !PA_funcs.construct_exists( "Line", line ) then
					Warning( "Line " .. tostring(line) .. " not defined" ) return false
				end
				selection_primary = { line }
			elseif selection_type == "Plane" then
				local plane = self.list_plane_1:GetSelectedLine()
				if !plane then
					Warning( "Select Plane 1" ) return false
				elseif !PA_funcs.construct_exists( "Plane", plane ) then
					Warning( "Plane " .. tostring(plane) .. " not defined" ) return false
				end
				selection_primary = { plane }
			else
				Warning( "Function selection type not valid" )
				return false
			end
			
			// Check construct selections
			local selection_constructs = self.panel_multiselect:GetSelection()
			
			if !selection_constructs then
				Warning( "No valid constructs selected for move" )
				return false
			end
			
			
			return self.activebutton.func( selection_primary, selection_constructs )
		end )
	
	local function move_constructs( selection_constructs, vec )
		for k, v in pairs ( selection_constructs.points ) do
			local point = PA_funcs.point_global(v)
			PA_funcs.set_point( v, point.origin + vec )
		end
		
		for k, v in pairs ( selection_constructs.lines ) do
			local line = PA_funcs.line_global(v)
			PA_funcs.set_line( v, line.startpoint + vec, line.endpoint + vec )
		end
		
		for k, v in pairs ( selection_constructs.planes ) do
			local plane = PA_funcs.plane_global(v)
			PA_funcs.set_plane( v, plane.origin + vec )
		end
		
		return true
	end
	
	self.button_move_points = vgui.Create( "PA_Function_Button_3", self )
		self.button_move_points:SetPos(310, 250)
		self.button_move_points:SetText( "Move by 2 Points" )
		self.button_move_points.selections = "Point"
		self.button_move_points.func = function( selection_primary, selection_constructs )
			local point1 = PA_funcs.point_global( selection_primary[1] )
			local point2 = PA_funcs.point_global( selection_primary[2] )
			
			local vec = point2.origin - point1.origin
			return move_constructs( selection_constructs, vec )
		end
	
	self.button_move_line = vgui.Create( "PA_Function_Button_3", self )
		self.button_move_line:SetPos(310, 280)
		self.button_move_line:SetText( "Move by Line" )
		self.button_move_line.selections = "Line"
		self.button_move_line.func = function( selection_primary, selection_constructs )
			local line = PA_funcs.line_global( selection_primary[1] )
			
			local vec = line.endpoint - line.startpoint
			return move_constructs( selection_constructs, vec )
		end
	
	self.button_move_mirror = vgui.Create( "PA_Function_Button_3", self )
		self.button_move_mirror:SetPos(310, 310)
		self.button_move_mirror:SetText( "Mirror Across Plane" )
		self.button_move_mirror.selections = "Plane"
		self.button_move_mirror.func = function( selection_primary, selection_constructs )
			local plane = PA_funcs.plane_global( selection_primary[1] )
			local origin, normal = plane.origin, plane.normal
			
			for k, v in pairs ( selection_constructs.points ) do
				local point = PA_funcs.point_global(v)
				PA_funcs.set_point( v, PA_funcs.point_mirror( point.origin, origin, normal ) )
			end
			
			for k, v in pairs ( selection_constructs.lines ) do
				local line = PA_funcs.line_global(v)
				PA_funcs.set_line( v, PA_funcs.point_mirror( line.startpoint, origin, normal ), PA_funcs.point_mirror( line.endpoint, origin, normal ) )
			end
		
			for k, v in pairs ( selection_constructs.planes ) do
				local plane = PA_funcs.plane_global(v)
				PA_funcs.set_plane( v, PA_funcs.point_mirror( plane.origin, origin, normal ), PA_funcs.direction_mirror( plane.normal, normal ) )
			end
			
			return true
		end
	
	
	// Rotate Around World Axes ************************************************************************************************
	
	AddMenuText( "Rotate Around World Axes", 453, self:GetTall()/2 - 10, self )
	
	self.list_pivotpoint = vgui.Create( "PA_Construct_ListView", self )
		self.list_pivotpoint:Text( "Pivot Point", "Point", self )
		self.list_pivotpoint:SetPos(463, 250)
		self.list_pivotpoint:SetToolTip( "Double click to deselect" )
		self.list_pivotpoint:SetMultiSelect(false)
		self.list_pivotpoint.DoDoubleClick = function( Line, LineID )
			self.list_pivotpoint:ClearSelection()
		end
	
	self.sliders_angle_world = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_angle_world:SetSize(280, 150)
		self.sliders_angle_world:SetPos(605, 284)
		self.sliders_angle_world:SetRange( 180 )
		self.sliders_angle_world.slider_x:SetText("Pitch")
		self.sliders_angle_world.slider_y:SetText("Yaw")
		self.sliders_angle_world.slider_z:SetText("Roll")
		self.sliders_angle_world.slider_x.Label:SetWide( 35 )
		self.sliders_angle_world.slider_y.Label:SetWide( 35 )
		self.sliders_angle_world.slider_z.Label:SetWide( 35 )
	
	self.button_zero_world = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_world:SetPos(845, 250)
		self.button_zero_world:SetSliders( self.sliders_angle_world )
	
	self.button_negate_world = vgui.Create( "PA_Negate_Button", self )
		self.button_negate_world:SetPos(724, 250)
		self.button_negate_world:SetSliders( self.sliders_angle_world )
	
	self.button_worldrotate = vgui.Create( "PA_Function_Button", self )
		self.button_worldrotate:SetPos(605, 250)
		self.button_worldrotate:SetSize(80, 25)
		self.button_worldrotate:SetText( "Rotate" )
		self.button_worldrotate:SetToolTip( "Rotate constructs by these values" )
		self.button_worldrotate:SetFunction( function()
			local rotang = self.sliders_angle_world:GetValues()
			if rotang == Vector(0,0,0) then return false end
			
			// Check pivot selection
			local pivot_selection = self.list_pivotpoint:GetSelectedLine()
			local pivot
			if pivot_selection then
				if PA_funcs.construct_exists( "Point", pivot_selection ) then
					pivot = PA_funcs.point_global( pivot_selection ).origin
				end
			end
			
			// Check construct selections
			local selection_constructs = self.panel_multiselect:GetSelection()
			
			if !selection_constructs then
				Warning( "No valid constructs selected for move" )
				return false
			end
			
			// Pitch, Yaw, Roll
			rotate_constructs( selection_constructs, pivot, Vector(0,1,0), rotang.x )
			rotate_constructs( selection_constructs, pivot, Vector(0,0,1), rotang.y )
			rotate_constructs( selection_constructs, pivot, Vector(1,0,0), rotang.z )
			
			return true
		end )
end

function MOVE_TAB:Paint()
	draw.RoundedBox(6, 0, 15, 555, self:GetTall()/2 - 20, BGColor)
	
	draw.RoundedBox(6, 563, 0, 327, 235, BGColor_Rotation)
	draw.RoundedBox(6, 570, 15, 315, self:GetTall()/2 - 20, BGColor)
	
	
	draw.RoundedBox(6, 0, self:GetTall()/2 + 15, 433, self:GetTall()/2 - 20, BGColor)
	
	draw.RoundedBox(6, 441, 220, 449, 220, BGColor_Rotation)
	draw.RoundedBox(6, 448, self:GetTall()/2 + 15, 437, self:GetTall()/2 - 20, BGColor)
end

vgui.Register("PA_Move_Tab", MOVE_TAB, "DPanel")


//********************************************************************************************************************//
// Combined Functions Tab
//********************************************************************************************************************//


local FUNCTIONS_TAB = {}
function FUNCTIONS_TAB:Init()
	self:CopyBounds( self:GetParent() )
	
	local width = 148.3
	local string_table = {"Point", "Line", "Plane"}
	local selection_lists = {}
	
	
	self.colour_panel_1 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_1:SetPos(0, 0)
	
	AddMenuText( "Selection", 10, 5, self.colour_panel_1 )
	
	self.list_point_primary = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_point_primary:Text( "Primary", "Point", self.colour_panel_1 )
		self.list_point_primary:SetPos(20, 30)
		self.list_point_primary:SetMultiSelect(false)
		self.list_point_primary:SetVisible(false)
	
	self.list_line_primary = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_line_primary:Text( "Primary", "Line", self.colour_panel_1 )
		self.list_line_primary:SetPos(20, 30)
		self.list_line_primary:SetMultiSelect(false)
		self.list_line_primary:SetVisible(false)
	
	self.list_plane_primary = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_plane_primary:Text( "Primary", "Plane", self.colour_panel_1 )
		self.list_plane_primary:SetPos(20, 30)
		self.list_plane_primary:SetMultiSelect(false)
		self.list_plane_primary:SetVisible(false)
	
	
	self.colour_panel_2 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_2:SetPos(width, 0)
	
	self.point_text = AddMenuText( "", 0, 10, self.colour_panel_2 )
	self.point_text:SetSize(width, 20)
	self.point_text:SetContentAlignment(2) 
	
	self.list_point_secondary = vgui.Create( "PA_Construct_ListView", self.colour_panel_2 )
		self.list_point_secondary:Text( "Point Selection", "Point", self.colour_panel_2 )
		self.list_point_secondary:SetPos(20, 30)
		self.list_point_secondary:SetVisible(false)
		table.insert(selection_lists, self.list_point_secondary)
	
	
	self.colour_panel_3 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_3:SetPos(width * 2, 0)
	
	 self.line_text = AddMenuText( "", 0, 10, self.colour_panel_3 )
	self.line_text:SetSize(width, 20)
	self.line_text:SetContentAlignment(2) 
	
	self.list_line_secondary = vgui.Create( "PA_Construct_ListView", self.colour_panel_3 )
		self.list_line_secondary:Text( "Line Selection", "Line", self.colour_panel_3 )
		self.list_line_secondary:SetPos(20, 30)
		self.list_line_secondary:SetVisible(false)
		table.insert(selection_lists, self.list_line_secondary)
	
		
	self.colour_panel_4 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_4:SetPos(width * 3, 0)
	
	 self.plane_text = AddMenuText( "", 0, 10, self.colour_panel_4 )
	self.plane_text:SetSize(width, 20)
	self.plane_text:SetContentAlignment(2) 
	
	self.list_plane_secondary = vgui.Create( "PA_Construct_ListView", self.colour_panel_4 )
		self.list_plane_secondary:Text( "Plane Selection", "Plane", self.colour_panel_4 )
		self.list_plane_secondary:SetPos(20, 30)
		self.list_plane_secondary:SetVisible(false)
		table.insert(selection_lists, self.list_plane_secondary)
	
	
	AddMenuText( "Function description", width * 4 + 10, 5, self )
	
	self.text_background = vgui.Create( "DPanel", self )
		self.text_background:SetPos( width * 4 + 10, 20 )
		self.text_background:SetSize( width * 2 - 19, self:GetTall() / 2  - 45 )
	
	self.text_title = vgui.Create( "DLabel", self )
		self.text_title:SetPos( width * 4 + 15, 25 )
		self.text_title:SetWide( width * 2 - 29 )
		self.text_title:SetContentAlignment(7)
		self.text_title:SetTextColor( Color(20,20,20,255) )
		self.text_title:SetText("- Select a function -")
	
	self.text_description = vgui.Create( "DLabel", self )
		self.text_description:SetPos( width * 4 + 15, 50 )
		self.text_description:SetSize( width * 2 - 29, self:GetTall() / 2  - 78 )
		self.text_description:SetWrap( true )
		self.text_description:SetContentAlignment(7)
		self.text_description:SetTextColor( Color(20,20,20,255) )
		self.text_description:SetText("")
	
	
	self.button_set = vgui.Create( "PA_Function_Button", self )
		self.button_set:SetPos(775, 165)
		self.button_set:SetSize(100, 40)
		self.button_set:SetText( "Set" )
		self.button_set:SetToolTip( "Execute the selected function" )
		self.button_set:SetFunction( function()
			if !self.activebutton then
				Warning("No function selected")
				return false
			end
			
			local selection_type = self.activebutton.selections
			local selection_primary, selection_1, selection_2, selection_3
			local selection_secondary = {}
			
			// Check primary selection
			if selection_type[1] == "Point" then
				selection_primary = self.list_point_primary:GetSelectedLine()
			elseif selection_type[1] == "Line" then
				selection_primary = self.list_line_primary:GetSelectedLine()
			else
				selection_primary = self.list_plane_primary:GetSelectedLine()
			end
			
			if !selection_primary then
				Warning( "Select a primary " .. string.lower(selection_type[1]) )
				return false
			end
						
			// Check secondary selections
			for k, v in pairs (selection_lists) do
				if v:IsVisible() then
					local selection = v:GetSelected()
					local numselections = selection_type[k + 1]
					
					// Check the right number of selections have been made
					if #selection ~= numselections then
						local str = "Selections not correct - " .. string_table[k] .. " selection requires " .. tostring(selection_type[k + 1]) .. " item"
						if selection_type[k + 1] > 1 then
							str = str .. "s"
						end
						Warning( str )
						return false
					end
					
					// Check the selections point to valid constructs
					for l, w in pairs (selection) do
						local ID = w:GetID()
						if !PA_funcs.construct_exists( string_table[k], ID ) then
							Warning( string_table[k] .. " " .. tostring(ID) .. " has not been defined" )
							return false
						end
						table.insert( selection_secondary, ID )	-- the way this is done, it will return points, then lines, then planes, in the required amounts
					end
				end
			end
			
			return self.activebutton.func( selection_primary, selection_secondary )
		end )
		
	
	
	AddMenuText( "Functions", 10, self:GetTall()/2 - 10, self )
	
	// POINTS ************************************************************************************************
	
	self.button_point_linestart = vgui.Create( "PA_Function_Button_2", self )
		self.button_point_linestart:SetPos(15, 250)
		self.button_point_linestart:SetText( "Line Start Point" )
		self.button_point_linestart.description = "Sets a point at the start of a line"
		self.button_point_linestart.selections = { "Point", 0, 1, 0 }
		self.button_point_linestart.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.line_global( selection_secondary[1] ).startpoint
			return PA_funcs.set_point( selection_primary, origin )
		end
	
	self.button_point_lineend = vgui.Create( "PA_Function_Button_2", self )
		self.button_point_lineend:SetPos(152, 250)
		self.button_point_lineend:SetText( "Line End Point" )
		self.button_point_lineend.description = "Sets a point at the end of a line"
		self.button_point_lineend.selections = { "Point", 0, 1, 0 }
		self.button_point_lineend.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.line_global( selection_secondary[1] ).endpoint
			return PA_funcs.set_point( selection_primary, origin )
		end
	
	self.button_point_planeorigin = vgui.Create( "PA_Function_Button_2", self )
		self.button_point_planeorigin:SetPos(15, 280)
		self.button_point_planeorigin:SetText( "Plane Origin" )
		self.button_point_planeorigin.description = "Sets a point at the origin of a plane"
		self.button_point_planeorigin.selections = { "Point", 0, 0, 1 }
		self.button_point_planeorigin.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.plane_global( selection_secondary[1] ).origin
			return PA_funcs.set_point( selection_primary, origin )
		end
	
	self.button_point_threeplanes = vgui.Create( "PA_Function_Button_2", self )
		self.button_point_threeplanes:SetPos(152, 280)
		self.button_point_threeplanes:SetText( "Intersection of 3 Planes" )
		self.button_point_threeplanes.description = "Finds the point where three planes intersect"
		self.button_point_threeplanes.selections = { "Point", 0, 0, 3 }
		self.button_point_threeplanes.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.point_3plane_intersection( selection_secondary[1], selection_secondary[2], selection_secondary[3] )
			if origin then
				return PA_funcs.set_point( selection_primary, origin )
			end
			return false
		end
	
	self.button_point_twolines = vgui.Create( "PA_Function_Button_2", self )
		self.button_point_twolines:SetPos(15, 310)
		self.button_point_twolines:SetText( "Line/Line Intersection" )
		self.button_point_twolines.description = "Sets a point where two lines intersect\n\nIf the two lines do not meet, the point will be set halfway between where the two lines are closest"
		self.button_point_twolines.selections = { "Point", 0, 2, 0 }
		self.button_point_twolines.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.point_2line_intersection( selection_secondary[1], selection_secondary[2] )
			if origin then
				return PA_funcs.set_point( selection_primary, origin )
			end
			return false
		end
	
	self.button_point_lineplane = vgui.Create( "PA_Function_Button_2", self )
		self.button_point_lineplane:SetPos(152, 310)
		self.button_point_lineplane:SetText( "Line/Plane Intersection" )
		self.button_point_lineplane.description = "Sets a point where a line intersects a plane"
		self.button_point_lineplane.selections = { "Point", 0, 1, 1 }
		self.button_point_lineplane.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.point_lineplane_intersection( selection_secondary[1], selection_secondary[2] )
			if origin then
				return PA_funcs.set_point( selection_primary, origin )
			end
			return false
		end
	
	self.button_point_lineprojection = vgui.Create( "PA_Function_Button_2", self )
		self.button_point_lineprojection:SetPos(15, 340)
		self.button_point_lineprojection:SetText( "Point - Line Projection" )
		self.button_point_lineprojection.description = "Finds the point on a line closest to the selected point"
		self.button_point_lineprojection.selections = { "Point", 1, 1, 0 }
		self.button_point_lineprojection.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.point_line_projection( selection_secondary[1], selection_secondary[2] )
			if origin then
				return PA_funcs.set_point( selection_primary, origin )
			end
			return false
		end
	
	self.button_point_planeprojection = vgui.Create( "PA_Function_Button_2", self )
		self.button_point_planeprojection:SetPos(152, 340)
		self.button_point_planeprojection:SetText( "Point - Plane Projection" )
		self.button_point_planeprojection.description = "Finds the point on a plane closest to the selected point"
		self.button_point_planeprojection.selections = { "Point", 1, 0, 1 }
		self.button_point_planeprojection.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.point_plane_projection( selection_secondary[1], selection_secondary[2] )
			if origin then
				return PA_funcs.set_point( selection_primary, origin )
			end
			return false
		end
	
	// LINES ************************************************************************************************
	
	self.button_line_point_startpoint = vgui.Create( "PA_Function_Button_2", self )
		self.button_line_point_startpoint:SetPos(width * 2 + 15, 250)
		self.button_line_point_startpoint:SetText( "Startpoint from Point" )
		self.button_line_point_startpoint.description = "Sets the startpoint of a line at selected point"
		self.button_line_point_startpoint.selections = { "Line", 1, 0, 0 }
		self.button_line_point_startpoint.func = function( selection_primary, selection_secondary )
			local startpoint = PA_funcs.point_global( selection_secondary[1] ).origin
			return PA_funcs.set_line( selection_primary, startpoint )
		end
		
	self.button_line_point_endpoint = vgui.Create( "PA_Function_Button_2", self )
		self.button_line_point_endpoint:SetPos(width * 2 + 152, 250)
		self.button_line_point_endpoint:SetText( "Endpoint from Point" )
		self.button_line_point_endpoint.description = "Sets the endpoint of a line at the selected point"
		self.button_line_point_endpoint.selections = { "Line", 1, 0, 0 }
		self.button_line_point_endpoint.func = function( selection_primary, selection_secondary )
			local endpoint = PA_funcs.point_global( selection_secondary[1] ).origin
			return PA_funcs.set_line( selection_primary, nil, endpoint )
		end
	
	self.button_line_move_startpoint = vgui.Create( "PA_Function_Button_2", self )
		self.button_line_move_startpoint:SetPos(width * 2 + 15, 280)
		self.button_line_move_startpoint:SetText( "Move Line to Point" )
		self.button_line_move_startpoint.description = "Position an existing line so that its start point moved to the selected point. This will maintain the direction and length of the line"
		self.button_line_move_startpoint.selections = { "Line", 1, 0, 0 }
		self.button_line_move_startpoint.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.point_global( selection_secondary[1] ).origin
			
			if PA_funcs.construct_exists( "Line", selection_primary ) then
				local startpoint = PA_funcs.line_global( selection_primary ).startpoint
				local endpoint = PA_funcs.line_global( selection_primary ).endpoint
				
				return PA_funcs.set_line( selection_primary, origin, origin + endpoint - startpoint )
			else
				Warning( "Line not defined" )
			end
			return false
		end
	
	self.button_line_2points = vgui.Create( "PA_Function_Button_2", self )
		self.button_line_2points:SetPos(width * 2 + 152, 280)
		self.button_line_2points:SetText( "Line from 2 Points" )
		self.button_line_2points.description = "Sets a line with start/end determined by the two selected points"
		self.button_line_2points.selections = { "Line", 2, 0, 0 }
		self.button_line_2points.func = function( selection_primary, selection_secondary )
			local startpoint = PA_funcs.point_global( selection_secondary[1] ).origin
			local endpoint = PA_funcs.point_global( selection_secondary[2] ).origin
			return PA_funcs.set_line( selection_primary, startpoint, endpoint )
		end
	
	self.button_line_2planes = vgui.Create( "PA_Function_Button_2", self )
		self.button_line_2planes:SetPos(width * 2 + 15, 310)
		self.button_line_2planes:SetText( "Intersection of 2 Planes" )
		self.button_line_2planes.description = "Sets a line at the intersection of two planes\n\nThe start point will be set halfway between the plane origins"
		self.button_line_2planes.selections = { "Line", 0, 0, 2 }
		self.button_line_2planes.func = function( selection_primary, selection_secondary )
			local line = PA_funcs.line_2plane_intersection( selection_secondary[1], selection_secondary[2] )
			if line then
				return PA_funcs.set_line( selection_primary, line.startpoint, nil, line.direction )
			end
			return false
		end
	
	self.button_line_plane = vgui.Create( "PA_Function_Button_2", self )
		self.button_line_plane:SetPos(width * 2 + 152, 310)
		self.button_line_plane:SetText( "Line from Plane" )
		self.button_line_plane.description = "Sets a line with startpoint/direction determined by the selected plane"
		self.button_line_plane.selections = { "Line", 0, 0, 1 }
		self.button_line_plane.func = function( selection_primary, selection_secondary )
			local plane = PA_funcs.plane_global( selection_secondary[1] )
			return PA_funcs.set_line( selection_primary, plane.origin, nil, plane.normal )
		end
	
	self.button_line_plane_direction = vgui.Create( "PA_Function_Button_2", self )
		self.button_line_plane_direction:SetPos(width * 2 + 15, 340)
		self.button_line_plane_direction:SetText( "Direction from Plane" )
		self.button_line_plane_direction.description = "Sets a line's direction determined by the direction of the selected plane"
		self.button_line_plane_direction.selections = { "Line", 0, 0, 1 }
		self.button_line_plane_direction.func = function( selection_primary, selection_secondary )
			local plane = PA_funcs.plane_global( selection_secondary[1] )
			return PA_funcs.set_line( selection_primary, nil, nil, plane.normal )
		end
	
	self.button_line_plane_projection = vgui.Create( "PA_Function_Button_2", self )
		self.button_line_plane_projection:SetPos(width * 2 + 152, 340)
		self.button_line_plane_projection:SetText( "Line - Plane Projection" )
		self.button_line_plane_projection.description = "Finds the projection of a line on a plane"
		self.button_line_plane_projection.selections = { "Line", 0, 1, 1 }
		self.button_line_plane_projection.func = function( selection_primary, selection_secondary )
			local line = PA_funcs.line_plane_projection( selection_secondary[1], selection_secondary[2] )
			if line then
				return PA_funcs.set_line( selection_primary, line.startpoint, line.endpoint )
			end
			return false
		end
		
	// PLANES ************************************************************************************************
	
	self.button_plane_point_origin = vgui.Create( "PA_Function_Button_2", self )
		self.button_plane_point_origin:SetPos(width * 4 + 15, 250)
		self.button_plane_point_origin:SetText( "Origin from Point" )
		self.button_plane_point_origin.description = "Sets a plane's origin at the selected point"
		self.button_plane_point_origin.selections = { "Plane", 1, 0, 0 }
		self.button_plane_point_origin.func = function( selection_primary, selection_secondary )
			local origin = PA_funcs.point_global( selection_secondary[1] ).origin
			return PA_funcs.set_plane( selection_primary, origin )
		end
	
	self.button_plane_3points = vgui.Create( "PA_Function_Button_2", self )
		self.button_plane_3points:SetPos(width * 4 + 152, 250)
		self.button_plane_3points:SetText( "Plane from 3 Points" )
		self.button_plane_3points.description = "Sets a plane determined by the 3 selected points\n\nThe plane's origin will be set at the centre of the 3 points"
		self.button_plane_3points.selections = { "Plane", 3, 0, 0 }
		self.button_plane_3points.func = function( selection_primary, selection_secondary )
			local plane_temp = PA_funcs.plane_3points( selection_secondary[1], selection_secondary[2], selection_secondary[3] )
			if plane_temp then
				return PA_funcs.set_plane( selection_primary, plane_temp.origin, plane_temp.direction )
			end
			return false
		end
	
	self.button_plane_line = vgui.Create( "PA_Function_Button_2", self )
		self.button_plane_line:SetPos(width * 4 + 15, 280)
		self.button_plane_line:SetText( "Plane from Line" )
		self.button_plane_line.description = "Sets a plane with origin/direction determined by the selected line"
		self.button_plane_line.selections = { "Plane", 0, 1, 0 }
		self.button_plane_line.func = function( selection_primary, selection_secondary )
			local line = PA_funcs.line_global( selection_secondary[1] )
			local direction = (line.endpoint - line.startpoint):GetNormal()
			return PA_funcs.set_plane( selection_primary, line.startpoint, direction )
		end
	
	self.button_plane_line_direction = vgui.Create( "PA_Function_Button_2", self )
		self.button_plane_line_direction:SetPos(width * 4 + 152, 280)
		self.button_plane_line_direction:SetText( "Direction from Line" )
		self.button_plane_line_direction.description = "Sets a plane's direction determined by the direction of the selected line"
		self.button_plane_line_direction.selections = { "Plane", 0, 1, 0 }
		self.button_plane_line_direction.func = function( selection_primary, selection_secondary )
			local line = PA_funcs.line_global( selection_secondary[1] )
			local direction = (line.endpoint - line.startpoint):GetNormal()
			return PA_funcs.set_plane( selection_primary, nil, direction )
		end
	
	self.button_plane_2lines = vgui.Create( "PA_Function_Button_2", self )
		self.button_plane_2lines:SetPos(width * 4 + 15, 310)
		self.button_plane_2lines:SetText( "Plane from 2 Lines" )
		self.button_plane_2lines.description = "Sets a plane determined by the 2 selected lines\n\nThe plane's origin will be set halfway between the line startpoints"
		self.button_plane_2lines.selections = { "Plane", 0, 2, 0 }
		self.button_plane_2lines.func = function( selection_primary, selection_secondary )
			local direction = PA_funcs.line_function_perpendicular( selection_secondary[1], selection_secondary[2] )
			if !direction then return false end
			local origin = ( PA_funcs.line_global(selection_secondary[1]).startpoint + PA_funcs.line_global(selection_secondary[2]).startpoint ) * 0.5
			return PA_funcs.set_plane( selection_primary, origin, direction )
		end
end

function FUNCTIONS_TAB:Paint()
	local width = self:GetWide()/3
	local height = self:GetTall()/2
	
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), BGColor_Display)
	
	draw.RoundedBox(6, 0, height, width, height, BGColor_Point)
	draw.RoundedBox(6, 5, height + 15, width - 11, height - 20, BGColor)
	
	draw.RoundedBox(6, width, height, width, height, BGColor_Line)
	draw.RoundedBox(6, width + 5, height + 15, width - 12, height - 20, BGColor)
	
	draw.RoundedBox(6, width * 2, height, width, height, BGColor_Plane)
	draw.RoundedBox(6, width * 2 + 5, height + 15, width - 10, height - 20, BGColor)
	
	draw.RoundedBox(6, width * 2 + 5, 15, width - 10, height - 20, BGColor_Disabled)
end

function FUNCTIONS_TAB:UpdateDescription()
	if self.activebutton then
		self.text_title:SetText( "- " .. self.activebutton:GetValue() .. " -")
		self.text_description:SetText(self.activebutton.description)
	end
end

vgui.Register("PA_Functions_Tab", FUNCTIONS_TAB, "DPanel")


//********************************************************************************************************************//
// Rotation Tab
//********************************************************************************************************************//


local ROTATION_TAB = {}
function ROTATION_TAB:Init()
	
	local function ToVector( ang )
		return Vector( ang.p, ang.y, ang.r )
	end
	
	local function ToAngle( vec )
		return Angle( vec.x, vec.y, vec.z )
	end
	
	self:CopyBounds( self:GetParent() )
	
	AddMenuText( "Entity Angles", 10, 5, self )
	
	self.list_pivotpoint = vgui.Create( "PA_Construct_ListView", self )
		self.list_pivotpoint:Text( "Pivot Point", "Point", self )
		self.list_pivotpoint:SetPos(15, 30)
		self.list_pivotpoint:SetToolTip( "Double click to deselect" )
		self.list_pivotpoint:SetMultiSelect(false)
		self.list_pivotpoint.DoDoubleClick = function( Line, LineID )
			self.list_pivotpoint:ClearSelection()
		end

	self.checkbox_relative1 = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_relative1:SetPos(140, 30)
		self.checkbox_relative1:SetText( "Relative to\nEntity" )
		self.checkbox_relative1:SetSize(100,30)
		self.checkbox_relative1.OnChange = function()
			local ent, ang
			if !PA_activeent and self.checkbox_relative1:GetChecked() then
				self.checkbox_relative1:SetValue(false)
			elseif self.checkbox_relative1:GetChecked() then
				self.checkbox_relative1.lastentity = PA_activeent
				ang = self.sliders_angle1:GetValues()
				ang = PA_activeent:WorldToLocalAngles( ToAngle(ang) )
				self.sliders_angle1:SetValues( ToVector(ang) )
			else
				if !PA_activeent then
					if self.checkbox_relative1.lastentity then
						ent = self.checkbox_relative1.lastentity
						self.checkbox_relative1.lastentity = nil
					else
						return false
					end
				else
					ent = PA_activeent
				end
				
				ang = self.sliders_angle1:GetValues()
				ang = ent:LocalToWorldAngles( ToAngle(ang) )
				self.sliders_angle1:SetValues( ToVector(ang) )
			end
		end
	
	self.button_rotate = vgui.Create( "PA_Move_Button", self )
		self.button_rotate:SetPos(140, 95)
		self.button_rotate:SetSize(80, 70)
		self.button_rotate:SetText( "Rotate Entity" )
		self.button_rotate:SetToolTip( "Set the entity's angles to the current values" )
		self.button_rotate:SetFunction( function()
			local ang = ToAngle( self.sliders_angle1:GetValues() )
			
			local pivot = self.list_pivotpoint:GetSelectedLine()
			local vec
			if pivot then
				if PA_funcs.construct_exists( "Point", pivot ) then
					vec = PA_funcs.point_global( pivot ).origin
				end
			end
			
			local relative = 0
			if self.checkbox_relative1:GetChecked() then
				relative = 1
				//ang = PA_activeent:LocalToWorldAngles( ang )
			end
			if !PA_funcs.rotate_entity(ang, vec, relative, PA_activeent) then return false end
		end )
	
	self.button_get1 = vgui.Create( "PA_Move_Button", self )
		self.button_get1:SetPos(232, 30)
		self.button_get1:SetSize(80, 25)
		self.button_get1:SetText( "Get Angles" )
		self.button_get1:SetToolTip( "Get angle values from the selected entity" )
		self.button_get1:SetFunction( function()
			local ang			
			if self.checkbox_relative1:GetChecked() and PA_activeent then
				ang = Angle(0,0,0)
			else
				ang = PA_activeent:GetAngles()
			end
			
			self.sliders_angle1:SetValues( ToVector(ang) )
			return true
		end )
	
	
	self.sliders_angle1 = vgui.Create( "PA_XYZ_Sliders", self )
		--self.sliders_angle1:SetWide(240)
		self.sliders_angle1:SetSize(240, 150)
		self.sliders_angle1:SetPos(233, 64)
		self.sliders_angle1:SetRange( 180 )
		self.sliders_angle1.slider_x.Label:SetWide( 35 )
		self.sliders_angle1.slider_y.Label:SetWide( 35 )
		self.sliders_angle1.slider_z.Label:SetWide( 35 )
		self.sliders_angle1.slider_x:SetText("Pitch")
		self.sliders_angle1.slider_y:SetText("Yaw")
		self.sliders_angle1.slider_z:SetText("Roll")
	
	self.button_zero_angle1 = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_angle1:SetPos(453, 30)
		self.button_zero_angle1:SetSliders( self.sliders_angle1 )
	
	self.button_negate_angle1 = vgui.Create( "PA_Negate_Button", self )
		self.button_negate_angle1:SetPos(342, 30)
		self.button_negate_angle1:SetSliders( self.sliders_angle1 )
	
	
	// Arithmetic buttons
	self.button_copy_right_p = vgui.Create( "PA_Copy_Right_Button", self )
		self.button_copy_right_p:SetPos(487, 70)
		self.button_copy_right_p:SetFunction( function()
			self.sliders_angle2.slider_x:SetValue( self.sliders_angle1.slider_x:GetValue() )
			return true
		end )
		
	self.button_copy_right_y = vgui.Create( "PA_Copy_Right_Button", self )
		self.button_copy_right_y:SetPos(487, 120)
		self.button_copy_right_y:SetFunction( function()
			self.sliders_angle2.slider_y:SetValue( self.sliders_angle1.slider_y:GetValue() )
			return true
		end )
		
	self.button_copy_right_r = vgui.Create( "PA_Copy_Right_Button", self )
		self.button_copy_right_r:SetPos(487, 170)
		self.button_copy_right_r:SetFunction( function()
			self.sliders_angle2.slider_z:SetValue( self.sliders_angle1.slider_z:GetValue() )
			return true
		end )
	
	self.button_copy_left_p = vgui.Create( "PA_Copy_Left_Button", self )
		self.button_copy_left_p:SetPos(537, 70)
		self.button_copy_left_p:SetFunction( function()
			self.sliders_angle1.slider_x:SetValue( self.sliders_angle2.slider_x:GetValue() )
			return true
		end )
	
	self.button_copy_left_y = vgui.Create( "PA_Copy_Left_Button", self )
		self.button_copy_left_y:SetPos(537, 120)
		self.button_copy_left_y:SetFunction( function()
			self.sliders_angle1.slider_y:SetValue( self.sliders_angle2.slider_y:GetValue() )
			return true
		end )
		
	self.button_copy_left_r = vgui.Create( "PA_Copy_Left_Button", self )
		self.button_copy_left_r:SetPos(537, 170)
		self.button_copy_left_r:SetFunction( function()
			self.sliders_angle1.slider_z:SetValue( self.sliders_angle2.slider_z:GetValue() )
			return true
		end )
	
	self.button_subtract_p = vgui.Create( "PA_Subtract_Button", self )
		self.button_subtract_p:SetPos(563, 70)
		self.button_subtract_p:SetFunction( function()
			self.sliders_angle1.slider_x:SetValue( self.sliders_angle1.slider_x:GetValue() - self.sliders_angle2.slider_x:GetValue() )
			return true
		end )
		
	self.button_subtract_y = vgui.Create( "PA_Subtract_Button", self )
		self.button_subtract_y:SetPos(563, 120)
		self.button_subtract_y:SetFunction( function()
			self.sliders_angle1.slider_y:SetValue( self.sliders_angle1.slider_y:GetValue() - self.sliders_angle2.slider_y:GetValue() )
			return true
		end )
		
	self.button_subtract_r = vgui.Create( "PA_Subtract_Button", self )
		self.button_subtract_r:SetPos(563, 170)
		self.button_subtract_r:SetFunction( function()
			self.sliders_angle1.slider_z:SetValue( self.sliders_angle1.slider_z:GetValue() - self.sliders_angle2.slider_z:GetValue() )
			return true
		end )
	
	self.button_add_p = vgui.Create( "PA_Add_Button", self )
		self.button_add_p:SetPos(589, 70)
		self.button_add_p:SetFunction( function()
			self.sliders_angle1.slider_x:SetValue( self.sliders_angle1.slider_x:GetValue() + self.sliders_angle2.slider_x:GetValue() )
			return true
		end )
		
	self.button_add_y = vgui.Create( "PA_Add_Button", self )
		self.button_add_y:SetPos(589, 120)
		self.button_add_y:SetFunction( function()
			self.sliders_angle1.slider_y:SetValue( self.sliders_angle1.slider_y:GetValue() + self.sliders_angle2.slider_y:GetValue() )
			return true
		end )
		
	self.button_add_r = vgui.Create( "PA_Add_Button", self )
		self.button_add_r:SetPos(589, 170)
		self.button_add_r:SetFunction( function()
			self.sliders_angle1.slider_z:SetValue( self.sliders_angle1.slider_z:GetValue() + self.sliders_angle2.slider_z:GetValue() )
			return true
		end )
	
	
	self.checkbox_relative2 = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_relative2:SetPos(540, 30)
		self.checkbox_relative2:SetText( "Relative to\nEntity" )
		self.checkbox_relative2:SetSize(100,30)
		self.checkbox_relative2.OnChange = function()
			local ent, ang
			if !PA_activeent and self.checkbox_relative2:GetChecked() then
				self.checkbox_relative2:SetValue(false)
			elseif self.checkbox_relative2:GetChecked() then
				self.checkbox_relative2.lastentity = PA_activeent
				ang = self.sliders_angle2:GetValues()
				ang = PA_activeent:WorldToLocalAngles( ToAngle(ang) )
				self.sliders_angle2:SetValues( ToVector(ang) )
			else
				if !PA_activeent then
					if self.checkbox_relative2.lastentity then
						ent = self.checkbox_relative2.lastentity
						self.checkbox_relative2.lastentity = nil
					else
						return false
					end
				else
					ent = PA_activeent
				end
				
				ang = self.sliders_angle2:GetValues()
				ang = ent:LocalToWorldAngles( ToAngle(ang) )
				self.sliders_angle2:SetValues( ToVector(ang) )
			end
		end
	
	self.sliders_angle2 = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_angle2:SetSize(240, 150)
		self.sliders_angle2:SetPos(632, 64)
		self.sliders_angle2:SetRange( 180 )
		self.sliders_angle2.slider_x.Label:SetWide( 35 )
		self.sliders_angle2.slider_y.Label:SetWide( 35 )
		self.sliders_angle2.slider_z.Label:SetWide( 35 )
		self.sliders_angle2.slider_x:SetText("Pitch")
		self.sliders_angle2.slider_y:SetText("Yaw")
		self.sliders_angle2.slider_z:SetText("Roll")
	
	self.button_zero_angle2 = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_angle2:SetPos(852, 30)
		self.button_zero_angle2:SetSliders( self.sliders_angle2 )
	
	self.button_negate_angle2 = vgui.Create( "PA_Negate_Button", self )
		self.button_negate_angle2:SetPos(741, 30)
		self.button_negate_angle2:SetSliders( self.sliders_angle2 )
	
	self.button_get2 = vgui.Create( "PA_Move_Button", self )
		self.button_get2:SetPos(631, 30)
		self.button_get2:SetSize(80, 25)
		self.button_get2:SetText( "Get Angles" )
		self.button_get2:SetToolTip( "Get angle values from the selected entity" )
		self.button_get2:SetFunction( function()
			local ang			
			if self.checkbox_relative2:GetChecked() and PA_activeent then
				ang = Angle(0,0,0)
			else
				ang = PA_activeent:GetAngles()
			end
			
			self.sliders_angle2:SetValues( ToVector(ang) )
			return true
		end )
	
	
	AddMenuText( "Rotate Around Axis", 10, self:GetTall()/2 - 10, self )
	
	self.list_line_axis = vgui.Create( "PA_Construct_ListView", self )
		self.list_line_axis:Text( "Axis", "Line", self )
		self.list_line_axis:SetPos(15, 250)
		self.list_line_axis:SetMultiSelect(false)
	
	self.slider_axisangle = vgui.Create( "PA_XYZ_Slider", self )
		self.slider_axisangle:SetPos(140, 280)
		self.slider_axisangle:SetWide(335)
		self.slider_axisangle.Label:SetWide( 35 )
		self.slider_axisangle:SetText( "Angle" )
		self.slider_axisangle:SetMinMax( -180, 180 )
	
	self.button_negate_axisangle = vgui.Create( "PA_Negate_Button", self )
		self.button_negate_axisangle:SetPos(296, 250)
		self.button_negate_axisangle:SetFunction( function()
			self.slider_axisangle:SetValue( -self.slider_axisangle:GetValue() )
			return true
		end )
		
	self.button_axisrotate_angle = vgui.Create( "PA_Function_Button", self )
		self.button_axisrotate_angle:SetPos(205, 350)
		self.button_axisrotate_angle:SetSize(80, 40)
		self.button_axisrotate_angle:SetText( "Rotate Angle" )
		self.button_axisrotate_angle:SetToolTip( "Rotate the primary slider values around the selected axis" )
		self.button_axisrotate_angle:SetFunction( function()
			local selected_line = self.list_line_axis:GetSelectedLine()
			
			if !selected_line then
				Warning("Select an axis line")
				return false
			end
			
			if !PA_funcs.construct_exists( "Line", selected_line ) then
				Warning("Line not correctly defined")
				return false
			end
			
			local line = PA_funcs.line_global(selected_line)
			
			local degrees = self.slider_axisangle:GetValue()
			if degrees == 0 then return false end
			
			local direction = ( line.endpoint - line.startpoint ):GetNormal()
			local ang = ToAngle( self.sliders_angle1:GetValues() )
			ang:RotateAroundAxis( direction, degrees )
			
			self.sliders_angle1:SetValues( ToVector(ang) )
			return true
		end )
	
	self.button_axisrotate_entity = vgui.Create( "PA_Move_Button", self )
		self.button_axisrotate_entity:SetPos(325, 350)
		self.button_axisrotate_entity:SetSize(80, 70)
		self.button_axisrotate_entity:SetText( "Rotate Entity" )
		self.button_axisrotate_entity:SetToolTip( "Rotate the active entity around the selected axis, pivot is line startpoint" )
		self.button_axisrotate_entity:SetFunction( function()
			local selected_line = self.list_line_axis:GetSelectedLine()
			
			if !selected_line then
				Warning("Select a line")
				return false
			end
			
			local line = PA_funcs.line_global(selected_line)
			
			if !line then
				Warning("Line not correctly defined")
				return false
			end
			
			local degrees = self.slider_axisangle:GetValue()
			if degrees == 0 then return false end
			
			local direction = (line.endpoint - line.startpoint):GetNormal()
			local ang = ToAngle( direction * degrees )
			-- local ang = PA_activeent:GetAngles()
			-- ang:RotateAroundAxis( direction, degrees )
			
			local pivot = self.list_pivotpoint:GetSelectedLine()
			local vec = line.startpoint
			if pivot then
				if PA_funcs.construct_exists( "Point", pivot ) then
					vec = PA_funcs.point_global( pivot ).origin
				end
			end
			
			local relative = 3
			
			if !PA_funcs.rotate_entity(ang, vec, relative, PA_activeent) then return false end
		end )
	
	
	AddMenuText( "Rotate Around World Axes", 505, self:GetTall()/2 - 10, self )
	
	self.sliders_angle_world = vgui.Create( "PA_XYZ_Sliders", self )
		self.sliders_angle_world:SetSize(240, 150)
		self.sliders_angle_world:SetPos(632, 284)
		self.sliders_angle_world:SetRange( 180 )
		-- self.sliders_angle_world.slider_tx:SetText("Pitch")
		-- self.sliders_angle_world.slider_ty:SetText("Yaw")
		-- self.sliders_angle_world.slider_tz:SetText("Roll")
	
	self.button_zero_world = vgui.Create( "PA_Zero_Button", self )
		self.button_zero_world:SetPos(852, 250)
		self.button_zero_world:SetSliders( self.sliders_angle_world )
	
	self.button_negate_world = vgui.Create( "PA_Negate_Button", self )
		self.button_negate_world:SetPos(741, 250)
		self.button_negate_world:SetSliders( self.sliders_angle_world )
	
	self.button_worldrotate = vgui.Create( "PA_Function_Button", self )
		self.button_worldrotate:SetPos(525, 300)
		self.button_worldrotate:SetSize(80, 40)
		self.button_worldrotate:SetText( "Rotate Angle" )
		self.button_worldrotate:SetToolTip( "Rotate the primary slider values by these values" )
		self.button_worldrotate:SetFunction( function()
			local rotang = self.sliders_angle_world:GetValues()
			
			if rotang == Vector(0,0,0) then return false end
			
			local ang = ToAngle( self.sliders_angle1:GetValues() )
			ang = PA_funcs.rotate_world( ang, Angle(rotang.x, rotang.y, rotang.z) )
			
			self.sliders_angle1:SetValues( ToVector(ang) )
			return true
		end )
	
	self.button_worldrotate_entity = vgui.Create( "PA_Move_Button", self )
		self.button_worldrotate_entity:SetPos(525, 350)
		self.button_worldrotate_entity:SetSize(80, 70)
		self.button_worldrotate_entity:SetText( "Rotate Entity" )
		self.button_worldrotate_entity:SetToolTip( "Rotate the active entity relative to the world axes" )
		self.button_worldrotate_entity:SetFunction( function()
			local ang = ToAngle( self.sliders_angle_world:GetValues() )
			if ang == Angle(0,0,0) then return false end
			
			local pivot = self.list_pivotpoint:GetSelectedLine()
			local vec
			if pivot then
				if PA_funcs.construct_exists( "Point", pivot ) then
					vec = PA_funcs.point_global( pivot ).origin
				end
			end
			
			local relative = 2
			
			if !PA_funcs.rotate_entity(ang, vec, relative, PA_activeent) then return false end
		end )
end

function ROTATION_TAB:Paint()
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), BGColor_Rotation)
	draw.RoundedBox(6, 5, 15, 515, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 530, 15, 355, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 5, self:GetTall()/2 + 15, 485, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 500, self:GetTall()/2 + 15, 385, self:GetTall()/2 - 20, BGColor)
end

vgui.Register("PA_Rotation_Tab", ROTATION_TAB, "DPanel")


//********************************************************************************************************************//
// Rotation Functions Tab
//********************************************************************************************************************//


local ROTATION_FUNCTIONS_TAB = {}
function ROTATION_FUNCTIONS_TAB:Init()	
	self:CopyBounds( self:GetParent() )
	
	local width = 148.3
	local string_table = {"Line 1", "Line 2", "Plane 1", "Plane 2"}
	local string_table2 = {"Line", "Line", "Plane", "Plane"}
	local selection_lists = {}
	
	AddMenuText( "Selection", 10, 5, self )
	
	self.colour_panel_1 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_1:SetPos(0, 0)
	
	self.list_line_1 = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_line_1:Text( "Line 1 Selection", "Line", self.colour_panel_1 )
		self.list_line_1:SetPos(20, 30)
		self.list_line_1:SetMultiSelect(false)
		self.list_line_1:SetVisible(false)
		table.insert(selection_lists, self.list_line_1)
	
	
	self.colour_panel_2 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_2:SetPos(width, 0)
	
	self.list_line_2 = vgui.Create( "PA_Construct_ListView", self.colour_panel_2 )
		self.list_line_2:Text( "Line 2 Selection", "Line", self.colour_panel_2 )
		self.list_line_2:SetPos(20, 30)
		self.list_line_2:SetMultiSelect(false)
		self.list_line_2:SetVisible(false)
		table.insert(selection_lists, self.list_line_2)
	
	
	self.colour_panel_3 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_3:SetPos(width * 2, 0)
	
	self.list_plane_1 = vgui.Create( "PA_Construct_ListView", self.colour_panel_3 )
		self.list_plane_1:Text( "Plane 1 Selection", "Plane", self.colour_panel_3 )
		self.list_plane_1:SetPos(20, 30)
		self.list_plane_1:SetMultiSelect(false)
		self.list_plane_1:SetVisible(false)
		table.insert(selection_lists, self.list_plane_1)
	
	
	self.colour_panel_4 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_4:SetPos(width * 3, 0)
	
	self.list_plane_2 = vgui.Create( "PA_Construct_ListView", self.colour_panel_4 )
		self.list_plane_2:Text( "Plane 2 Selection", "Plane", self.colour_panel_4 )
		self.list_plane_2:SetPos(20, 30)
		self.list_plane_2:SetMultiSelect(false)
		self.list_plane_2:SetVisible(false)
		table.insert(selection_lists, self.list_plane_2)
	
	
	AddMenuText( "Function description", width * 4 + 10, 5, self )
	
	self.text_background = vgui.Create( "DPanel", self )
		self.text_background:SetPos( width * 4 + 10, 20 )
		self.text_background:SetSize( width * 2 - 19, self:GetTall() / 2  - 45 )
	
	self.text_title = vgui.Create( "DLabel", self )
		self.text_title:SetPos( width * 4 + 15, 25 )
		self.text_title:SetWide( width * 2 - 29 )
		self.text_title:SetContentAlignment(7)
		self.text_title:SetTextColor( Color(20,20,20,255) )
		self.text_title:SetText("- Select a function -")
	
	self.text_description = vgui.Create( "DLabel", self )
		self.text_description:SetPos( width * 4 + 15, 50 )
		self.text_description:SetSize( width * 2 - 29, self:GetTall() / 2  - 78 )
		self.text_description:SetWrap( true )
		self.text_description:SetContentAlignment(7)
		self.text_description:SetTextColor( Color(20,20,20,255) )
		self.text_description:SetText("")
	
	
	self.button_set = vgui.Create( "PA_Move_Button", self )
		self.button_set:SetPos(775, 165)
		self.button_set:SetSize(100, 40)
		self.button_set:SetText( "Rotate Entity" )
		self.button_set:SetToolTip( "Execute the selected function" )
		self.button_set:SetFunction( function()
			if !self.activebutton then
				Warning("No function selected")
				return false
			end
			
			local selection_type = self.activebutton.selections
			local selection_pivot, selection_axis
			local selections = {}
						
			// Check selections
			for k, v in pairs (selection_lists) do
				if v:IsVisible() then
					local selection = v:GetSelectedLine()
					if !selection then
						local str = "Selections not correct - " .. string_table[k] .. " must be selected"
						Warning( str )
						return false
					end
					
					if !PA_funcs.construct_exists( string_table2[k], selection ) then
						Warning( string_table2[k] .. " " .. tostring(selection) .. " has not been defined" )
						return false
					end
					table.insert( selections, selection )	-- the way this is done, it will return points, then lines, then planes, in the required amounts
				end
			end
			
			// Filter out non-existant pivot / axis selections before passing to functions
			local pivot = self.list_pivotpoint:GetSelectedLine()
			if pivot then
				if !PA_funcs.construct_exists( "Point", pivot ) then
					pivot = nil
				else
					pivot = PA_funcs.point_global( pivot ).origin
				end
			end
			
			local axis = self.list_line_axis:GetSelectedLine()
			if axis then
				if !PA_funcs.construct_exists( "Line", axis ) then
					axis = nil
				else
					axis = PA_funcs.line_global( axis )
				end
			end
			
			if !self.activebutton.func( pivot, axis, selections ) then
				return false
			end
		end )
	
	// OPTIONAL SELECTIONS ************************************************************************************************
	
	AddMenuText( "Optional selections", 10, self:GetTall()/2 - 10, self )
	
	self.list_pivotpoint = vgui.Create( "PA_Construct_ListView", self )
		self.list_pivotpoint:Text( "Pivot Point", "Point", self )
		self.list_pivotpoint:SetPos(20, 250)
		self.list_pivotpoint:SetToolTip( "Double click to deselect" )
		self.list_pivotpoint:SetMultiSelect(false)
		self.list_pivotpoint.DoDoubleClick = function( Line, LineID )
			self.list_pivotpoint:ClearSelection()
		end
		
	self.list_line_axis = vgui.Create( "PA_Construct_ListView", self )
		self.list_line_axis:Text( "Axis", "Line", self )
		self.list_line_axis:SetPos(width + 20, 250)
		self.list_line_axis:SetToolTip( "Double click to deselect" )
		self.list_line_axis:SetMultiSelect(false)
		self.list_line_axis.DoDoubleClick = function( Line, LineID )
			self.list_line_axis:ClearSelection()
		end
	
	// FUNCTION BUTTONS ************************************************************************************************
	
	AddMenuText( "Functions", width * 2 + 10, self:GetTall()/2 - 10, self )
	
	self.button_angle_2lines = vgui.Create( "PA_Function_Button_Rotation", self )
		self.button_angle_2lines:SetPos(323, 250)
		self.button_angle_2lines:SetText( "Angle Between 2 Lines" )
		self.button_angle_2lines.description = "Rotates the selected entity according to the angle between two lines\n\n" ..
											   "This is the angle line 1 must be rotated by until it lies in the same direction as line 2\n\n" ..
											   "If no pivot point is selected, by default this will pivot about the start point of line 1"
		self.button_angle_2lines.selections = { 1, 1, 0, 0 }
		self.button_angle_2lines.options = { 1, 0 }
		self.button_angle_2lines.func = function( pivot, axis, selections )			
			return PA_funcs.rotate_2lines_parallel( pivot, selections[1], selections[2], PA_activeent )
		end
	
	self.button_angle_2planes = vgui.Create( "PA_Function_Button_Rotation", self )
		self.button_angle_2planes:SetPos(323, 280)
		self.button_angle_2planes:SetText( "Angle Between 2 Plane Normals" )
		self.button_angle_2planes.description = "Rotates the selected entity according to the angle between two plane normals\n\n" ..
												"This is the angle plane 1 must be rotated by until it lies in the same direction as plane 2\n\n" ..
												"If no pivot point is selected, by default this will pivot about the origin of plane 1"
		self.button_angle_2planes.selections = { 0, 0, 1, 1 }
		self.button_angle_2planes.options = { 1, 0 }
		self.button_angle_2planes.func = function( pivot, axis, selections )			
			return PA_funcs.rotate_2planes_parallel( pivot, selections[1], selections[2], PA_activeent )
		end
	
	self.button_lineplane_normal = vgui.Create( "PA_Function_Button_Rotation", self )
		self.button_lineplane_normal:SetPos(323, 310)
		self.button_lineplane_normal:SetText( "Angle from Line to Plane Normal" )
		self.button_lineplane_normal.description = "Rotates the selected entity according to the angle between a line and a plane normal\n\n" ..
												   "This is the angle line 1 must be rotated by until it lies in the same direction as the plane normal"
		self.button_lineplane_normal.selections = { 1, 0, 1, 0 }
		self.button_lineplane_normal.options = { 1, 0 }
		self.button_lineplane_normal.func = function( pivot, axis, selections )
			return PA_funcs.rotate_lines_planenormal_parallel( pivot, selections[1], selections[2], PA_activeent )
		end
	
	self.button_lineplane = vgui.Create( "PA_Function_Button_Rotation", self )
		self.button_lineplane:SetPos(509, 250)
		self.button_lineplane:SetText( "Angle from Line to Plane" )
		self.button_lineplane.description = "Rotates the selected entity according to the angle between a line and a plane\n\n" ..
											"This is the angle line 1 must be rotated by until it lies parallel to the plane"
		self.button_lineplane.selections = { 1, 0, 1, 0 }
		self.button_lineplane.options = { 1, 1 }
		self.button_lineplane.func = function( pivot, axis, selections )			
			return PA_funcs.rotate_line_plane_parallel( pivot, axis, selections[1], selections[2], PA_activeent )
		end
	
	-- self.button_2line_intersect = vgui.Create( "PA_Function_Button_Rotation", self )
		-- self.button_2line_intersect:SetPos(509, 280)
		-- self.button_2line_intersect:SetText( "Line/Line Intersection" )
		-- self.button_2line_intersect.description = "The rotation angle will be determined by how much line 1 must be rotated until it intersects line 2\n\nBy default, the entity's coordinate centre will be used as the pivot point, and the direction of line 2 will be used as the axis of rotation"
		-- self.button_2line_intersect.selections = { 1, 1, 0, 0 }
		-- self.button_2line_intersect.options = { 1, 1 }
		-- self.button_2line_intersect.func = function( pivot, axis, selections )
		-- end
		-- self.button_2line_intersect:SetDisabled(true)
	
	self.button_align_2lines = vgui.Create( "PA_Function_Button_Rotation", self )
		self.button_align_2lines:SetPos(695, 250)
		self.button_align_2lines:SetText( "Align 2 Lines" )
		self.button_align_2lines.description = "Moves and rotates the selected entity according to the difference in direction and position of the two selected lines, so that line 1 will end up parallel to line 2\n\n" ..
											   "This is identical to the 'Angle Between 2 Lines' rotation function, except that it will also move the entity along the vector from line 1's start point to line 2's start point."
		self.button_align_2lines.selections = { 1, 1, 0, 0 }
		self.button_align_2lines.options = { 0, 0 }
		self.button_align_2lines.func = function( pivot, axis, selections )
			if PA_funcs.rotate_2lines_parallel( pivot, selections[1], selections[2], PA_activeent ) then
				local vec1 = PA_funcs.line_global( selections[1] ).startpoint
				local vec2 = PA_funcs.line_global( selections[2] ).startpoint
				if !vec1 or !vec2 then
					return false
				end
				
				return PA_funcs.move_entity( vec1, vec2, PA_activeent )
			end
			return false
		end
	
	self.button_mirror = vgui.Create( "PA_Function_Button_Rotation", self )
		self.button_mirror:SetPos(695, 280)
		self.button_mirror:SetText( "Mirror Across Plane" )
		self.button_mirror.description = "This will move and rotate the selected entity so that it will be mirrored about the selected plane, rotating about the prop's centre of mass\n\n" ..
										 "Note that some props have different planes of symmetry - this can usually be remedied by rotating the prop in some direction by 90 or 180 degrees relative to itself about its centre of mass"
		self.button_mirror.selections = { 0, 0, 1, 0 }
		self.button_mirror.options = { 0, 0 }
		self.button_mirror.func = function( pivot, axis, selections )
			return PA_funcs.plane_mirror_entity( selections[1], PA_activeent )
		end
end

function ROTATION_FUNCTIONS_TAB:Paint()
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), BGColor_Rotation)
	draw.RoundedBox(6, 598, 15, 287, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 5, self:GetTall()/2 + 15, 140, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 153, self:GetTall()/2 + 15, 140, self:GetTall()/2 - 20, BGColor)
	draw.RoundedBox(6, 301, self:GetTall()/2 + 15, 584, self:GetTall()/2 - 20, BGColor)
end

function ROTATION_FUNCTIONS_TAB:UpdateDescription()
	if self.activebutton then
		self.text_title:SetText( "- " .. self.activebutton:GetValue() .. " -" )
		self.text_description:SetText(self.activebutton.description)
	end
end

vgui.Register("PA_Rotation_Functions_Tab", ROTATION_FUNCTIONS_TAB, "DPanel")


//********************************************************************************************************************//
// Constraints Tab
//********************************************************************************************************************//

local CONSTRAINTS_TAB = {}
function CONSTRAINTS_TAB:Init()
	self:CopyBounds( self:GetParent() )
	
	AddMenuText( "Anchor Points", 32, 9, self )
	
	self.colour_panel_1 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_1:SetPos(5, 31)
		self.colour_panel_1:SetSize(136, 202)
		self.colour_panel_1:SetColour( BGColor_Point )
	
	self.text_LPos1 = vgui.Create( "PA_Constraint_Title_Text", self.colour_panel_1 )
		self.text_LPos1:SetText("Entity 1")
	
	self.list_point_LPos1 = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_point_LPos1:Text( "Pos 1", "Point", self )
		self.list_point_LPos1:SetPos(13, 22)
		self.list_point_LPos1:SetMultiSelect(false)
	
	
	self.colour_panel_2 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_2:SetPos(5, 233)
		self.colour_panel_2:SetSize(136, 202)
		self.colour_panel_2:SetColour( BGColor_Point )
	
	self.text_LPos2 = vgui.Create( "PA_Constraint_Title_Text", self.colour_panel_2 )
		self.text_LPos2:SetText("Entity 2")
	
	self.list_point_LPos2 = vgui.Create( "PA_Construct_ListView", self.colour_panel_2 )
		self.list_point_LPos2:Text( "Pos 2", "Point", self )
		self.list_point_LPos2:SetPos(13, 22)
		self.list_point_LPos2:SetToolTip( "Double click to deselect" )
		self.list_point_LPos2:SetMultiSelect(false)
		self.list_point_LPos2.DoDoubleClick = function( Line, LineID )
			self.list_point_LPos2:ClearSelection()
		end
	
	
	self.panel = vgui.Create("PA_Constraints_Panel", self)
	
	self.axis_tab = vgui.Create("PA_Constraints_Axis_Tab", self.panel)
	self.ballsocket_tab = vgui.Create("PA_Constraints_Ballsocket_Tab", self.panel)
	self.ballsocket_adv_tab = vgui.Create("PA_Constraints_Ballsocket_Adv_Tab", self.panel)
	self.elastic_tab = vgui.Create("PA_Constraints_Elastic_Tab", self.panel)
	self.rope_tab = vgui.Create("PA_Constraints_Rope_Tab", self.panel)
	self.slider_tab = vgui.Create("PA_Constraints_Slider_Tab", self.panel)
	self.wire_hydraulic_tab = vgui.Create("PA_Constraints_Wire_Hydraulic_Tab", self.panel)

	self.panel:AddSheet("Axis", self.axis_tab, false, false, false )
	self.panel:AddSheet("Ball Socket", self.ballsocket_tab, false, false, false )
	self.panel:AddSheet("Ball Socket Adv", self.ballsocket_adv_tab, false, false, false )
	self.panel:AddSheet("Elastic", self.elastic_tab, false, false, false )
	self.panel:AddSheet("Rope", self.rope_tab, false, false, false )
	self.panel:AddSheet("Slider", self.slider_tab, false, false, false )
	self.panel:AddSheet("Wire Hydraulic", self.wire_hydraulic_tab, false, false, false )
	
	
	AddMenuText( "Constraint Description", 721, 9, self )
	
	self.text_description = vgui.Create( "DLabel", self )
		self.text_description:SetPos( 690, 36 )
		self.text_description:SetSize( 195, 284 )
		self.text_description:SetWrap( true )
		self.text_description:SetContentAlignment(7)
		self.text_description:SetTextColor( Color(20,20,20,255) )
	self:UpdateText()
	
	self.button_constraint = vgui.Create( "PA_Function_Button", self )
		self.button_constraint:SetPos(687, 378)
		self.button_constraint:SetSize(191, 50)
		self.button_constraint:SetText("Create Constraint")
		self.button_constraint:SetFunction( function()
			local selection1 = self.list_point_LPos1:GetSelectedLine()
			local selection2 = self.list_point_LPos2:GetSelectedLine()
			
			if !selection1 then
				Warning("Select a point for Pos 1")
				return false
			end
			
			if !PA_funcs.construct_exists( "Point", selection1 ) then
				Warning("Point 1 has not been defined")
				return false
			end
			
			local activepanel = self.panel:GetActiveTab():GetPanel()
			local constraint_type = activepanel.Constraint
			
			if constraint_type ~= "Axis" and constraint_type ~= "Ballsocket" and constraint_type ~= "Ballsocket Advanced" then
				if !selection2 then
					Warning("Select a point for Pos 2")
					return false
				end
			
				if !PA_funcs.construct_exists( "Point", selection2 ) then
					Warning("Point 2 has not been defined")
					return false
				end
			end
			
			// Send local info if possible, no point in converting it to/from global if the constraint requires local coords
			local point1 = precision_align_points[ selection1 ]
			local point2
			
			if !PA_funcs.construct_exists( "Point", selection2 ) then
				point2 = { ["origin"] = PA_funcs.point_global(selection1).origin + Vector(0,0,1) }	-- Set so default axis dir is (0,0,1)
			else
				point2 = precision_align_points[ selection2 ]
			end
			
			local Ent1 = point1.entity
			local Ent2 = point2.entity
						
			if !Ent1 and !Ent2 then
				Warning("At least one point must be attached to an entity")
				return false
			end
			
			if Ent1 == Ent2 and constraint_type ~= "Rope" then
				Warning("Cannot constrain entity to itself")
				return false
			end
			
			Ent1 = Ent1 or Entity(0)
			Ent2 = Ent2 or Entity(0)
			
			local constraint_vars = activepanel.Constraint_Func()
			if constraint_vars == nil then return false end
			
			local LPos1 = point1.origin
			local LPos2 = point2.origin
			
			local data = {}
			data.Type = activepanel.Constraint
			data.Ent1 = Ent1:EntIndex()
			data.Ent2 = Ent2:EntIndex()
			data.LPos1 = { x = LPos1.x, y = LPos1.y, z = LPos1.z }
			data.LPos2 = { x = LPos2.x, y = LPos2.y, z = LPos2.z }
			data.vars = constraint_vars
			
			net.Start( PA_.. "constraint" )
			net.WriteTable( data )
			net.SendToServer()
		end )
		
	
		
	// Create function in each sheet tab to update description text
	for _, v in pairs (self.panel.Items) do
		local Tab = v.Tab
		if Tab then
			Tab.OnMousePressed = function( mcode )
				if self.panel:GetActiveTab() ~= Tab then
					self.panel:SetActiveTab( Tab )
					self:UpdateText()
				end
			end
		end
	end
end

function CONSTRAINTS_TAB:Paint()
	//draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), Color(100,100,100,255))
	
	// "Anchor Points" Background
	draw.RoundedBox(6, 5, 5, 136, 22, BGColor_Point)
	
	// Text background
	draw.RoundedBox(6, 680, 5, 205, 22, BGColor_Display)
	draw.RoundedBox(6, 682, 7, 201, 18, BGColor_Background)
	draw.RoundedBox(6, 680, 31, 205, 404, BGColor_Display)
end

function CONSTRAINTS_TAB:UpdateText()
	local sheet = self.panel:GetActiveTab():GetPanel()
	local constraint_type = sheet.Constraint
	local text = sheet.Description
	if constraint_type and text then
		self.text_description:SetText( "- " .. constraint_type .. " -\n\n" .. text )
	else
		self.text_description:SetText( "" )
	end
end

vgui.Register("PA_Constraints_Tab", CONSTRAINTS_TAB, "DPanel")


local CONSTRAINTS_PANEL = {}
function CONSTRAINTS_PANEL:Init()
	self:SetPos(140, 5)
	self:SetSize( 540, 435 )
end

function CONSTRAINTS_PANEL:Paint()
	//draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), Color(100,100,100,255))
end

vgui.Register("PA_Constraints_Panel", CONSTRAINTS_PANEL, "DPropertySheet")

local CONSTRAINTS_AXIS_TAB = {}
function CONSTRAINTS_AXIS_TAB:Init()	
	self:CopyBounds( self:GetParent() )
	
	self.Constraint = "Axis"
	self.Description =	"Create an axis constraint with the rotation axis between Pos 1 and Pos 2\n\n" ..
						"If Axis is selected, the rotation axis will be in the direction of the selected line\n\n" ..
						"In this case Pos 2 is not used, but is still required to define the entity being constrained"
	
	self.colour_panel_1 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_1:SetPos(15, 15)
		self.colour_panel_1:SetSize(136, 202)
		self.colour_panel_1:SetColour( BGColor_Line )
	
	self.text_axis = vgui.Create( "PA_Constraint_Title_Text", self.colour_panel_1 )
		self.text_axis:SetText("Optional")
	
	self.list_point_axis = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_point_axis:Text( "Axis", "Line", self )
		self.list_point_axis:SetPos(13, 22)
		self.list_point_axis:SetToolTip( "Double click to deselect" )
		self.list_point_axis:SetMultiSelect(false)
		self.list_point_axis.DoDoubleClick = function( Line, LineID )
			self.list_point_axis:ClearSelection()
		end
	
	self.combobox = self:AddComboBox(
		{
			Label = "#Presets",
			MenuButton = 1,
			Folder = PA,
			Options = {},
			CVars =
			{
				[0] = PA_ .. "axis_forcelimit",
				[1] = PA_ .. "axis_torquelimit",
				[2] = PA_ .. "axis_friction",
				[3] = PA_ .. "axis_nocollide"
			}
		}
	)
		self.combobox:SetPos(180, 20)
		self.combobox:SetWide(300)
	
	self.slider_forcelimit = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_forcelimit:SetPos(180, 60)
		self.slider_forcelimit:SetWide(300)
		self.slider_forcelimit:SetText( "Force Limit" )
		self.slider_forcelimit:SetConVar( PA_ .. "axis_forcelimit" )
	
	self.slider_torquelimit = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_torquelimit:SetPos(180, 110)
		self.slider_torquelimit:SetWide(300)
		self.slider_torquelimit:SetText( "Torque Limit" )
		self.slider_torquelimit:SetConVar( PA_ .. "axis_torquelimit" )
	
	self.slider_friction = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_friction:SetWide(300)
		self.slider_friction:SetPos(180, 160)
		self.slider_friction:SetText( "Friction" )
		self.slider_friction:SetConVar( PA_ .. "axis_friction" )
	
	self.checkbox_nocollide = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_nocollide:SetPos(180, 220)
		self.checkbox_nocollide:SetText( "Nocollide" )
		self.checkbox_nocollide:SetSize(100,30)
		self.checkbox_nocollide:SetConVar( PA_ .. "axis_nocollide" )
	
	// Send extra constraint info - if this returns false then no data is sent to the server
	self.Constraint_Func = function()
		local axis_selection = self.list_point_axis:GetSelectedLine()
		local axis = 0
		local line
		if axis_selection and PA_funcs.construct_exists( "Line", axis_selection ) then
			line = PA_funcs.line_global( axis_selection )
			axis = ( line.endpoint - line.startpoint ):GetNormal()
			axis = { x = axis.x, y = axis.y, z = axis.z }
		end
		
		return axis 
	end
end

vgui.Register("PA_Constraints_Axis_Tab", CONSTRAINTS_AXIS_TAB, "PA_Constraints_Sheet")


local CONSTRAINTS_BALLSOCKET_TAB = {}
function CONSTRAINTS_BALLSOCKET_TAB:Init()	
	self:CopyBounds( self:GetParent() )
	
	self.Constraint = "Ballsocket"
	self.Description =	"Create a ball socket constraint about Pos 1\n\n" ..
						"Pos 2 is not used, but is still required to define the entity being constrained"
	
	self.combobox = self:AddComboBox(
		{
			Label = "#Presets",
			MenuButton = 1,
			Folder = PA,
			Options = {},
			CVars =
			{
				[0] = PA_ .. "ballsocket_forcelimit",
				[1] = PA_ .. "ballsocket_torquelimit",
				[2] = PA_ .. "ballsocket_nocollide"
			}
		}
	)
		self.combobox:SetPos(50, 20)
		self.combobox:SetWide(430)
	
	self.slider_forcelimit = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_forcelimit:SetWide(300)
		self.slider_forcelimit:SetPos(50, 60)
		self.slider_forcelimit:SetText( "Force Limit" )
		self.slider_forcelimit:SetConVar( PA_ .. "ballsocket_forcelimit" )
	
	self.slider_torquelimit = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_torquelimit:SetWide(300)
		self.slider_torquelimit:SetPos(50, 110)
		self.slider_torquelimit:SetText( "Torque Limit" )
		self.slider_torquelimit:SetConVar( PA_ .. "ballsocket_torquelimit" )
	
	self.checkbox_nocollide = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_nocollide:SetPos(50, 170)
		self.checkbox_nocollide:SetText( "Nocollide" )
		self.checkbox_nocollide:SetSize(100,30)
		self.checkbox_nocollide:SetConVar( PA_ .. "ballsocket_nocollide" )
	
	self.Constraint_Func = function()
		return 0
	end
end

vgui.Register("PA_Constraints_Ballsocket_Tab", CONSTRAINTS_BALLSOCKET_TAB, "PA_Constraints_Sheet")


local CONSTRAINTS_BALLSOCKET_ADV_TAB = {}
function CONSTRAINTS_BALLSOCKET_ADV_TAB:Init()	
	self:CopyBounds( self:GetParent() )
	
	self.Constraint = "Ballsocket Advanced"
	self.Description =	"Create an advanced ball socket constraint about Pos 1\n\n" ..
						"Pos 2 is not used, but is still required to define the entity being constrained\n\n" ..
						"X/Y/Z Min/Max/Friction values are all in the direction of the world axes\n\n" ..
						"Free Movement will allow the two constrained entities to move independently of each other, rather than maintaining a set distance about Pos 1"
						
	
	self.combobox = self:AddComboBox(
		{
			Label = "#Presets",
			MenuButton = 1,
			Folder = PA,
			Options = {},
			CVars =
			{
				[0] = PA_ .. "ballsocket_adv_forcelimit",
				[1] = PA_ .. "ballsocket_adv_torquelimit",
				[2] = PA_ .. "ballsocket_adv_xmin",
				[3] = PA_ .. "ballsocket_adv_ymin",
				[4] = PA_ .. "ballsocket_adv_zmin",
				[5] = PA_ .. "ballsocket_adv_xmax",
				[6] = PA_ .. "ballsocket_adv_ymax",
				[7] = PA_ .. "ballsocket_adv_zmax",
				[8] = PA_ .. "ballsocket_adv_xfric",
				[9] = PA_ .. "ballsocket_adv_yfric",
				[10] = PA_ .. "ballsocket_adv_zfric",
				[11] = PA_ .. "ballsocket_adv_onlyrotation",
				[12] = PA_ .. "ballsocket_adv_nocollide"
			}
		}
	)
		self.combobox:SetPos(50, 20)
		self.combobox:SetWide(430)
	
	self.slider_forcelimit = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_forcelimit:SetWide(300)
		self.slider_forcelimit:SetPos(50, 60)
		self.slider_forcelimit:SetText( "Force Limit" )
		self.slider_forcelimit:SetConVar( PA_ .. "ballsocket_adv_forcelimit" )
	
	self.slider_torquelimit = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_torquelimit:SetWide(300)
		self.slider_torquelimit:SetPos(50, 110)
		self.slider_torquelimit:SetText( "Torque Limit" )
		self.slider_torquelimit:SetConVar( PA_ .. "ballsocket_adv_torquelimit" )
	
	self.slider_xmin = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_xmin.Label:SetSize( 50 )
		self.slider_xmin:SetPos(20, 170)
		self.slider_xmin:SetWide(150)
		self.slider_xmin:SetMinMax(-180, 180)
		self.slider_xmin:SetText( "X Min" )
		self.slider_xmin:SetConVar( PA_ .. "ballsocket_adv_xmin" )
	
	self.slider_ymin = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_ymin.Label:SetSize( 50 )
		self.slider_ymin:SetPos(20, 220)
		self.slider_ymin:SetWide(150)
		self.slider_ymin:SetMinMax(-180, 180)
		self.slider_ymin:SetText( "Y Min" )
		self.slider_ymin:SetConVar( PA_ .. "ballsocket_adv_ymin" )
	
	self.slider_zmin = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_zmin.Label:SetSize( 50 )
		self.slider_zmin:SetPos(20, 270)
		self.slider_zmin:SetWide(150)
		self.slider_zmin:SetMinMax(-180, 180)
		self.slider_zmin:SetText( "Z Min" )
		self.slider_zmin:SetConVar( PA_ .. "ballsocket_adv_zmin" )
	
	self.slider_xmax = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_xmax.Label:SetSize( 50 )
		self.slider_xmax:SetPos(190, 170)
		self.slider_xmax:SetWide(150)
		self.slider_xmax:SetMinMax(-180, 180)
		self.slider_xmax:SetText( "X Max" )
		self.slider_xmax:SetConVar( PA_ .. "ballsocket_adv_xmax" )
	
	self.slider_ymax = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_ymax.Label:SetSize( 50 )
		self.slider_ymax:SetPos(190, 220)
		self.slider_ymax:SetWide(150)
		self.slider_ymax:SetMinMax(-180, 180)
		self.slider_ymax:SetText( "Y Max" )
		self.slider_ymax:SetConVar( PA_ .. "ballsocket_adv_ymax" )
	
	self.slider_zmax = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_zmax.Label:SetSize( 50 )
		self.slider_zmax:SetPos(190, 270)
		self.slider_zmax:SetWide(150)
		self.slider_zmax:SetMinMax(-180, 180)
		self.slider_zmax:SetText( "Z Max" )
		self.slider_zmax:SetConVar( PA_ .. "ballsocket_adv_zmax" )
	
	self.slider_xfric = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_xfric.Label:SetSize( 50 )
		self.slider_xfric:SetPos(360, 170)
		self.slider_xfric:SetWide(150)
		self.slider_xfric:SetMinMax(-180, 180)
		self.slider_xfric:SetText( "X Friction" )
		self.slider_xfric:SetConVar( PA_ .. "ballsocket_adv_xfric" )
	
	self.slider_yfric = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_yfric.Label:SetSize( 50 )
		self.slider_yfric:SetPos(360, 220)
		self.slider_yfric:SetWide(150)
		self.slider_yfric:SetMinMax(-180, 180)
		self.slider_yfric:SetText( "Y Friction" )
		self.slider_yfric:SetConVar( PA_ .. "ballsocket_adv_yfric" )
	
	self.slider_zfric = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_zfric.Label:SetSize( 50 )
		self.slider_zfric:SetPos(360, 270)
		self.slider_zfric:SetWide(150)
		self.slider_zfric:SetMinMax(-180, 180)
		self.slider_zfric:SetText( "Z Friction" )
		self.slider_zfric:SetConVar( PA_ .. "ballsocket_adv_zfric" )
	
	self.checkbox_free = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_free:SetPos(50, 335)
		self.checkbox_free:SetText( "Free Movement" )
		self.checkbox_free:SetSize(100,30)
		self.checkbox_free:SetConVar( PA_ .. "ballsocket_adv_onlyrotation" )
	
	self.checkbox_nocollide = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_nocollide:SetPos(50, 363)
		self.checkbox_nocollide:SetText( "Nocollide" )
		self.checkbox_nocollide:SetSize(100,30)
		self.checkbox_nocollide:SetConVar( PA_ .. "ballsocket_adv_nocollide" )
	
	self.Constraint_Func = function()
		return 0
	end	
end

vgui.Register("PA_Constraints_Ballsocket_Adv_Tab", CONSTRAINTS_BALLSOCKET_ADV_TAB, "PA_Constraints_Sheet")


local CONSTRAINTS_ELASTIC_TAB = {}
function CONSTRAINTS_ELASTIC_TAB:Init()	
	self:CopyBounds( self:GetParent() )
	
	self.Constraint = "Elastic"
	self.Description =	"Create an elastic constraint between Pos 1 and Pos 2"
	
	self.combobox = self:AddComboBox(
		{
			Label = "#Presets",
			MenuButton = 1,
			Folder = PA,
			Options = {},
			CVars =
			{
				[0] = PA_ .. "elastic_constant",
				[1] = PA_ .. "elastic_damping",
				[2] = PA_ .. "elastic_rdamping",
				[3] = PA_ .. "elastic_material",
				[4] = PA_ .. "elastic_width",
				[5] = PA_ .. "elastic_stretchonly"
			}
		}
	)
		self.combobox:SetPos(25, 20)
		self.combobox:SetWide(225)
	
	self.slider_constant = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_constant.Label:SetSize( 75 )
		self.slider_constant:SetWide( 225 )
		self.slider_constant:SetPos(25, 60)
		self.slider_constant:SetText( "Spring Constant" )
		self.slider_constant:SetConVar( PA_ .. "elastic_constant" )
	
	self.slider_damping = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_damping.Label:SetSize( 75 )
		self.slider_damping:SetWide( 225 )
		self.slider_damping:SetPos(25, 110)
		self.slider_damping:SetMax(10000)
		self.slider_damping:SetText( "Damping Constant" )
		self.slider_damping:SetConVar( PA_ .. "elastic_damping" )
	
	self.slider_rdamping = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_rdamping.Label:SetSize( 75 )
		self.slider_rdamping:SetWide( 225 )
		self.slider_rdamping:SetPos(25, 160)
		self.slider_rdamping:SetMax(100)
		self.slider_rdamping:SetText( "Relative Damping Constant" )
		self.slider_rdamping:SetConVar( PA_ .. "elastic_rdamping" )
	
	self.slider_width = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_width.Label:SetSize( 75 )
		self.slider_width:SetWide( 225 )
		self.slider_width:SetPos(25, 210)
		self.slider_width:SetMax(20)
		self.slider_width:SetText( "Width" )
		self.slider_width:SetConVar( PA_ .. "elastic_width" )
	
	self.checkbox_stretch = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_stretch:SetPos(50, 260)
		self.checkbox_stretch:SetText( "Stretch Only" )
		self.checkbox_stretch:SetSize(100,30)
		self.checkbox_stretch:SetConVar( PA_ .. "elastic_stretchonly" )
	
	self.matselect = vgui.Create( "RopeMaterial", self )
		self.matselect:SetPos(250, 20)
		self.matselect:SetWide(250)
		self.matselect:SetConVar( PA_ .. "elastic_material" )
	
	self.Constraint_Func = function()
		return 0
	end	
end

vgui.Register("PA_Constraints_Elastic_Tab", CONSTRAINTS_ELASTIC_TAB, "PA_Constraints_Sheet")


local CONSTRAINTS_ROPE_TAB = {}
function CONSTRAINTS_ROPE_TAB:Init()	
	self:CopyBounds( self:GetParent() )
	
	self.Constraint = "Rope"
	self.Description =	"Create a rope constraint between Pos 1 and Pos 2\n\n" ..
						"By setting Set Length, the length of the rope can be controlled directly\n\n" ..
						"If this is 0, then the length of the rope will be determined by the distance between Pos 1 and Pos 2, plus Add Length\n\n"
	
	self.combobox = self:AddComboBox(
		{
			Label = "#Presets",
			MenuButton = 1,
			Folder = PA,
			Options = {},
			CVars =
			{
				[0] = PA_ .. "rope_forcelimit",
				[1] = PA_ .. "rope_addlength",
				[2] = PA_ .. "rope_width",
				[3] = PA_ .. "rope_material",
				[4] = PA_ .. "rope_rigid",
				[5] = PA_ .. "rope_setlength"
			}
		}
	)
		self.combobox:SetPos(25, 20)
		self.combobox:SetWide(225)
	
	self.slider_forcelimit = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_forcelimit.Label:SetSize( 75 )
		self.slider_forcelimit:SetWide(225)
		self.slider_forcelimit:SetPos(25, 60)
		self.slider_forcelimit:SetText( "Force Limit" )
		self.slider_forcelimit:SetConVar( PA_ .. "rope_forcelimit" )
	
	self.slider_addlength = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_addlength.Label:SetSize( 75 )
		self.slider_addlength:SetWide(225)
		self.slider_addlength:SetPos(25, 110)
		self.slider_addlength:SetMinMax(-1000, 1000)
		self.slider_addlength:SetText( "Add Length" )
		self.slider_addlength:SetConVar( PA_ .. "rope_addlength" )
	
	self.slider_width = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_width.Label:SetSize( 75 )
		self.slider_width:SetWide(225)
		self.slider_width:SetPos(25, 160)
		self.slider_width:SetMax(20)
		self.slider_width:SetText( "Width" )
		self.slider_width:SetConVar( PA_ .. "rope_width" )
	
	self.slider_setlength = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_setlength.Label:SetSize( 75 )
		self.slider_setlength:SetWide(225)
		self.slider_setlength:SetPos(25, 210)
		self.slider_setlength:SetMax(2000)
		self.slider_setlength:SetText( "Set Length" )
		self.slider_setlength:SetConVar( PA_ .. "rope_setlength" )
	
	self.checkbox_rigid = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_rigid:SetPos(50, 260)
		self.checkbox_rigid:SetText( "Rigid" )
		self.checkbox_rigid:SetSize(100,30)
		self.checkbox_rigid:SetConVar( PA_ .. "rope_rigid" )
	
	self.matselect = vgui.Create( "RopeMaterial", self )
		-- self.matselect:SetPos(50, 220)
		self.matselect:SetPos(250, 20)
		self.matselect:SetWide(250)
		self.matselect:SetConVar( PA_ .. "rope_material" )
	
	self.Constraint_Func = function()
		return 0
	end	
end

vgui.Register("PA_Constraints_Rope_Tab", CONSTRAINTS_ROPE_TAB, "PA_Constraints_Sheet")


local CONSTRAINTS_SLIDER_TAB = {}
function CONSTRAINTS_SLIDER_TAB:Init()
	self:CopyBounds( self:GetParent() )
	
	self.Constraint = "Slider"
	self.Description =	"Create a slider constraint between Pos 1 and Pos 2\n\n" ..
						"The direction of the slider will always be between Pos 1 and Pos 2"
	
	self.slider_width = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_width:SetWide(300)
		self.slider_width:SetPos(50, 20)
		self.slider_width:SetMax(20)
		self.slider_width:SetText( "Width" )
		self.slider_width:SetConVar( PA_ .. "slider_width" )
	
	self.Constraint_Func = function()
		return 0
	end	
end

vgui.Register("PA_Constraints_Slider_Tab", CONSTRAINTS_SLIDER_TAB, "PA_Constraints_Sheet")


local CONSTRAINTS_WIRE_HYDRAULIC_TAB = {}
function CONSTRAINTS_WIRE_HYDRAULIC_TAB:Init()
	self:CopyBounds( self:GetParent() )
	
	self.Constraint = "Wire Hydraulic"
	self.Description =	"This is for editing wire hydraulic constraints that have already been created\n\n" ..
						"Select the hydraulic controller with right click, then set the constraint according to Pos 1 and Pos 2 to overwrite the existing hydraulic\n\n" ..
						"For technical reasons there is no 'fixed' option, but this can be done easily by creating a slider constraint manually\n\n" ..
						"As a result, it is adviseable not to use this on fixed hydraulics without first removing the existing hydraulic slider"
	
	self.slider_width = vgui.Create( "PA_Constraint_Slider", self )
		self.slider_width.Label:SetSize( 75 )
		self.slider_width:SetWide(225)
		self.slider_width:SetPos(25, 20)
		self.slider_width:SetMax(20)
		self.slider_width:SetText( "Width" )
		self.slider_width:SetConVar( PA_ .. "wire_hydraulic_width" )
		
	self.matselect = vgui.Create( "RopeMaterial", self )
		self.matselect:SetPos(250, 20)
		self.matselect:SetWide(250)
		self.matselect:SetConVar( PA_ .. "wire_hydraulic_material" )
	
	self.Constraint_Func = function()
		if !IsValid( PA_activeent ) then
			Warning( "Select a wire hydraulic controller" )
			return false
		end
		
		if PA_activeent:GetClass() ~= "gmod_wire_hydraulic" then
			Warning( "Select a wire hydraulic controller" )
			return false
		end
		
		return PA_activeent:EntIndex() 
	end
end

vgui.Register("PA_Constraints_Wire_Hydraulic_Tab", CONSTRAINTS_WIRE_HYDRAULIC_TAB, "PA_Constraints_Sheet")