// Derma UI for precision alignment stool (client only) - By Wenli
if SERVER then return end

local PA = "precision_align"
local PA_ = PA .. "_"

local ent_active = ents.GetByIndex( GetConVarNumber(PA_.."ent_active") )
PA_selected_point = 1
PA_selected_line = 1
PA_selected_plane = 1

PA_activeent = nil

include( "weapons/gmod_tool/stools/"..PA.."/manipulation_panel.lua" )
include( "weapons/gmod_tool/stools/"..PA.."/prop_functions.lua" )

local CPanel = controlpanel.Get( PA )

local BGColor = Color(50, 50, 50, 50)
local BGColor_Background = Color(103, 100, 110, 255)
local BGColor_Disabled = Color(160, 160, 160, 255)
local BGColor_Display = Color(170, 170, 170, 255)
local BGColor_Point = Color(170, 140, 140, 255)
local BGColor_Line = Color(140, 140, 170, 255)
local BGColor_Plane = Color(140, 170, 140, 255)


local function Warning( text )
	if GetConVarNumber( PA_.."display_warnings" ) == 1 then
		LocalPlayer():ChatPrint( "(PA) ERROR: " .. text )
	end
end

local function AddMenuText( text, x, y, parent )
	local Text = vgui.Create( "DLabel", parent )
	Text:SetFontInternal("Default")
	Text:SetText( text )
	Text:SizeToContents() 
	Text:SetPos( x, y )
	return Text
end

local function play_sound_true()
	LocalPlayer():EmitSound("buttons/button15.wav", 100, 100)
end

local function play_sound_false()
	LocalPlayer():EmitSound("buttons/lightswitch2.wav", 100, 100)
end


//********************************************************************************************************************//
// Custom Derma Controls
//********************************************************************************************************************//


/*---------------------------------------------------------
   Name: Stack_Num_Request
   Popup window to request stack_num
---------------------------------------------------------*/

local STACK_POPUP = {}

function STACK_POPUP:Init()
	self:SetSize( 300, 150 )
	self:Center()
	self:SetTitle( "Precision Alignment Multi-Stack Settings" )
	self:ShowCloseButton( true )
	self:SetDraggable( false )
	self:SetBackgroundBlur( true )
	self:SetDrawOnTop( true )
	
	self.text_stackamount = vgui.Create( "DLabel", self )
		self.text_stackamount:SetText( "Stack Amount:" )
		self.text_stackamount:SizeToContents()
		self.text_stackamount:SetContentAlignment( 8 )
		self.text_stackamount:SetTextColor( color_white )
		self.text_stackamount:StretchToParent( 5, 40, 5, 5 ) 
			
	self.slider_stackamount = vgui.Create( "DNumSlider", self )
		self.slider_stackamount:StretchToParent( 10, nil, 10, nil )
		self.slider_stackamount:AlignTop( 45 )
		self.slider_stackamount:SetText( "" )
		self.slider_stackamount:SetMinMax( 1, 20 )
		self.slider_stackamount:SetDecimals( 0 )
		self.slider_stackamount:SetValue( GetConVarNumber( PA_.."stack_num" ) )
		self.slider_stackamount.Text = self.slider_stackamount:GetTextArea()
		self.slider_stackamount.Text.OnEnter = function()
			self.button_ok:DoClick()
		end
		self.slider_stackamount.Text:RequestFocus()
	
	self.checkbox_nocollide = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_nocollide:SetText( "Nocollide" )
		self.checkbox_nocollide:SetToolTip( "Nocollide each stacked entity with the next" )
		self.checkbox_nocollide:SizeToContents()
		self.checkbox_nocollide:AlignBottom( 45 )
		self.checkbox_nocollide:AlignLeft( 10 )
		self.checkbox_nocollide:SetValue( GetConVarNumber( PA_.."stack_nocollide" ) )
	
	self.button_ok = vgui.Create( "DButton", self )
		self.button_ok:SetText( "OK" )
		self.button_ok:SizeToContents()
		self.button_ok:SetSize( 80, 25 )
		self.button_ok:AlignLeft( 5 )
		self.button_ok:AlignBottom( 5 )
		self.button_ok.DoClick = function()
			RunConsoleCommand( PA_.."stack_num", tostring( math.Clamp(self.slider_stackamount:GetValue(), 1, 20) ) )
			
			local nocollide = 0
			if self.checkbox_nocollide:GetChecked() then nocollide = 1 end
			RunConsoleCommand( PA_.."stack_nocollide", tostring( nocollide ) )
			
			self:Close()
		end
			
	self.button_cancel = vgui.Create( "DButton", self )
		self.button_cancel:SetText( "Cancel" )
		self.button_cancel:SizeToContents()
		self.button_cancel:SetSize( 80, 25 )
		self.button_cancel:SetPos( 5, 5 )
		self.button_cancel.DoClick = function() self:Close() end
		self.button_cancel:AlignRight( 5 )
		self.button_cancel:AlignBottom( 5 )
	
	self:MakePopup()
	self:DoModal()
end

		
function STACK_POPUP:Paint( w, h)
	if ( self.m_bBackgroundBlur ) then
		Derma_DrawBackgroundBlur( self, self.m_fCreateTime )
	end
	
	local width, height = self:GetSize()
	draw.RoundedBox(6, 0, 0, width, 25, BGColor_Display)
	draw.RoundedBox(6, 2, 2, width - 4, 21, BGColor_Background)
	
	draw.RoundedBox(6, 0, 25, width, height - 25, Color(0, 0, 0, 255))
	draw.RoundedBox(6, 1, 26, width - 2, height - 27, BGColor_Background )
end

vgui.Register("PA_Stack_Popup", STACK_POPUP, "DFrame")


/*---------------------------------------------------------
   Name: PA_Construct_ListView
   Standard construct list
---------------------------------------------------------*/

local CONSTRUCT_LISTVIEW = {}
function CONSTRUCT_LISTVIEW:Init()
	self:SetSize(110, 169)
	--self:SetSortable(false)
end

function CONSTRUCT_LISTVIEW:Text( title, text )
	self.construct_type = text
	self:AddColumn( "" .. title)
	for i = 1, 9 do
		local line = self:AddLine(text .. " " .. tostring(i))
		line.indicator = vgui.Create( "PA_Indicator", line )
	end
	
	// Format header
	local Header = self.Columns[1].Header
	Header:SetFont("DefaultBold")
	Header:SetContentAlignment( 5 )
end

function CONSTRUCT_LISTVIEW:SetIndicators()
	for i = 1, 9 do
		local line = self:GetLine(i)
		line.indicator = vgui.Create( "PA_Indicator", line )
	end
end

function CONSTRUCT_LISTVIEW:SetIndicatorOffset( offset )
	for i = 1, 9 do
		local indicator = self:GetLine(i).indicator
		indicator.offset = offset
	end
end

vgui.Register("PA_Construct_ListView", CONSTRUCT_LISTVIEW, "DListView")

// Indicator to tell whether construct is defined
local INDICATOR = {}

function INDICATOR:Init()
	self.offset = 0
end

function INDICATOR:PerformLayout()
	local width, height = self:GetParent():GetWide() - 5 - self.offset, self:GetParent():GetTall() - 4
	self:SetSize( height, height )
	self:SetPos( width - height, 2 )
end

function INDICATOR:Paint(w,h)
	local textbox = self:GetParent()
	
	if PA_funcs.construct_exists(textbox:GetListView().construct_type, textbox:GetID()) then
		draw.RoundedBox( 6, 0, 0, self:GetWide(), self:GetTall(), Color(0,230,0,255) )
	end
end

vgui.Register("PA_Indicator", INDICATOR, "DPanel")

/*---------------------------------------------------------
   Name: PA_XYZ_Sliders
   XYZ slider control for vector input/output
---------------------------------------------------------*/

local XYZ_SLIDER = {}
function XYZ_SLIDER:Init()
	--self:SetSize(130, 100) -- Keep the second number at 100
	--self:SetWide(200)
	self:SetMinMax( -50000, 50000 )
	self:SetDecimals( 3 )
	self:SetValue( 0 )
	
	// This is so we can identify the slider belongs to PA, so we can hook keyboard focus below
	self:GetTextArea().Type = "PA"
end

vgui.Register("PA_XYZ_Slider", XYZ_SLIDER, "DNumSlider")

local text = {}

function text:Init()
	self:SetSize(130,100)

end
vgui.Register("PA_Temp_textbox", text, "DLabel")

// These hooks allow the slider text boxes to steal keyboard focus
local function TextFocusOn( pnl )
	if	pnl:GetClassName() == "TextEntry" and pnl.Type == "PA" then
		PA_manipulation_panel:SetKeyBoardInputEnabled( true )
	end
end
hook.Add( "OnTextEntryGetFocus", "PAKeyboardFocusOn", TextFocusOn )

local function TextFocusOff( pnl )
	if	pnl:GetClassName() == "TextEntry" and pnl.Type == "PA" then
		PA_manipulation_panel:SetKeyBoardInputEnabled( false )
	end
end
hook.Add( "OnTextEntryLoseFocus", "PAKeyboardFocusOff", TextFocusOff )


local XYZ_SLIDERS = {}
function XYZ_SLIDERS:Init()
	self.slider_x = vgui.Create( "PA_XYZ_Slider", self )
	self.slider_y = vgui.Create( "PA_XYZ_Slider", self )
	self.slider_z = vgui.Create( "PA_XYZ_Slider", self )
	
	self.slider_x.Label:SetWide( 5 )
	self.slider_y.Label:SetWide( 5 )
	self.slider_z.Label:SetWide( 5 )
	
	self.slider_x:SetText("X")
	self.slider_y:SetText("Y")
	self.slider_z:SetText("Z")
end

function XYZ_SLIDERS:PerformLayout()
	local w, h = self:GetWide(), self:GetTall() - 10
	local x = 0
	local y1 = 0
	local y2 = h / 2 - 20
	local y3 = h - 40
	local width, height = w, 100
	
	self.slider_x:SetWide( width ) --:SetSize(width, height)
	self.slider_y:SetWide( width ) --:SetSize(width, height)
	self.slider_z:SetWide( width ) --:SetSize(width, height)
	
	self.slider_x:SetPos(x, y1)
	self.slider_y:SetPos(x, y2)
	self.slider_z:SetPos(x, y3)
end

function XYZ_SLIDERS:GetValues()
	local x, y, z
	x = self.slider_x:GetValue()
	y = self.slider_y:GetValue()
	z = self.slider_z:GetValue()
	
	return Vector( x, y, z )
end

function XYZ_SLIDERS:SetValues( vec )
	self.slider_x:SetValue(vec.x)
	self.slider_y:SetValue(vec.y)
	self.slider_z:SetValue(vec.z)
end

function XYZ_SLIDERS:SetRange( x )
	self.slider_x:SetMinMax( -x, x )
	self.slider_y:SetMinMax( -x, x )
	self.slider_z:SetMinMax( -x, x )
end

function XYZ_SLIDERS:Paint(w,h)
end

vgui.Register("PA_XYZ_Sliders", XYZ_SLIDERS, "DPanel")







/*---------------------------------------------------------
   Name: PA_Function_Button
   Standard button that can be assigned a function
---------------------------------------------------------*/

local FUNCTION_BUTTON = {}
function FUNCTION_BUTTON:Init()
	self:SetSize(200, 25)
end

function FUNCTION_BUTTON:SetFunction( func )
	self.DoClick = function()
		local ret = func()
		if ret == true then
			play_sound_true()
		elseif ret == false then
			play_sound_false()
		end
	end
end
vgui.Register("PA_Function_Button", FUNCTION_BUTTON, "DButton")

/*---------------------------------------------------------
   Name: PA_Function_Button_2
   Construct functions selection button
---------------------------------------------------------*/

local function_buttons_2_list = {}
local FUNCTION_BUTTON_2 = {}

function FUNCTION_BUTTON_2:Init()
	self:SetSize(130, 25)
	table.insert(function_buttons_2_list, self)
	
	self.DoClick = function()
		local T = self.selections
		local tab = self:GetParent()
		
		tab.activebutton = self
		tab:UpdateDescription()
		
		tab.list_point_primary:SetVisible(false)
		tab.list_line_primary:SetVisible(false)
		tab.list_plane_primary:SetVisible(false)
			
		if T[1] == "Point" then
			tab.colour_panel_1:SetColour(BGColor_Point)
			tab.list_point_primary:SetVisible(true)
		elseif T[1] == "Line" then
			tab.colour_panel_1:SetColour(BGColor_Line)
			tab.list_line_primary:SetVisible(true)
		elseif T[1] == "Plane" then
			tab.colour_panel_1:SetColour(BGColor_Plane)
			tab.list_plane_primary:SetVisible(true)
		else
			tab.colour_panel_1:SetColour(BGColor_Disabled)			
		end
				
		if  not (T[2] == 0) then
			//tab.point_text:SetText( "Select " .. tostring(T[2]) )
			tab.colour_panel_2:SetColour(BGColor_Point)
			tab.list_point_secondary:SetVisible(true)
		else
			//tab.point_text:SetText( "" )
			tab.colour_panel_2:SetColour(BGColor_Disabled)
			tab.list_point_secondary:SetVisible(false)
		end
		
		if T[3] ~= 0 then
			//tab.line_text:SetText( "Select " .. tostring(T[3]) )
			tab.colour_panel_3:SetColour(BGColor_Line)
			tab.list_line_secondary:SetVisible(true)
		else
			//tab.line_text:SetText( "" )
			tab.colour_panel_3:SetColour(BGColor_Disabled)
			tab.list_line_secondary:SetVisible(false)
		end
		
		if T[4] ~= 0 then
			//tab.plane_text:SetText( "Select " .. tostring(T[4]) )
			tab.colour_panel_4:SetColour(BGColor_Plane)
			tab.list_plane_secondary:SetVisible(true)
		else
			//tab.plane_text:SetText( "" )
			tab.colour_panel_4:SetColour(BGColor_Disabled)
			tab.list_plane_secondary:SetVisible(false)
		end		
	end
end

// Override mouse functions (make it into a toggle button)
function FUNCTION_BUTTON_2:OnMousePressed( mousecode )
	if !self.Depressed then
		// pop up any previously depressed buttons
		for k, v in pairs (function_buttons_2_list) do
			if v.Depressed then
				v.Depressed = false
			end
		end
		self.Depressed = true
		return self.DoClick()
	end
end

function FUNCTION_BUTTON_2:OnMouseReleased( mousecode )
end

vgui.Register("PA_Function_Button_2", FUNCTION_BUTTON_2, "DButton")

/*---------------------------------------------------------
   Name: PA_Function_Button_3
   Move Constructs selection button
---------------------------------------------------------*/

local function_buttons_3_list = {}
local FUNCTION_BUTTON_3 = {}

function FUNCTION_BUTTON_3:Init()
	self:SetSize(110, 25)
	table.insert(function_buttons_3_list, self)
	
	self.DoClick = function()
		local T = self.selections
		local tab = self:GetParent()
		
		tab.activebutton = self
		
		tab.list_point_1:SetVisible(false)
		tab.list_point_2:SetVisible(false)
		tab.list_line_1:SetVisible(false)
		tab.list_plane_1:SetVisible(false)
			
		if T == "Point" then
			tab.colour_panel_1:SetColour(BGColor_Point)
			tab.colour_panel_2:SetColour(BGColor_Point)
			tab.list_point_1:SetVisible(true)
			tab.list_point_2:SetVisible(true)
		elseif T == "Line" then
			tab.colour_panel_1:SetColour(BGColor_Disabled)
			tab.colour_panel_2:SetColour(BGColor_Line)
			tab.list_line_1:SetVisible(true)
		elseif T == "Plane" then
			tab.colour_panel_1:SetColour(BGColor_Disabled)
			tab.colour_panel_2:SetColour(BGColor_Plane)
			tab.list_plane_1:SetVisible(true)
		else
			tab.colour_panel_1:SetColour(BGColor_Disabled)
			tab.colour_panel_2:SetColour(BGColor_Disabled)		
		end
	end
end

// Override mouse functions (make it into a toggle button)
function FUNCTION_BUTTON_3:OnMousePressed( mousecode )
	if !self.Depressed then
		// pop up any previously depressed buttons
		for k, v in pairs (function_buttons_3_list) do
			if v.Depressed then
				v.Depressed = false
			end
		end
		self.Depressed = true
		return self.DoClick()
	end
end

function FUNCTION_BUTTON_3:OnMouseReleased( mousecode )
end

vgui.Register("PA_Function_Button_3", FUNCTION_BUTTON_3, "DButton")

/*---------------------------------------------------------
   Name: PA_Function_Button_Rotation
   Rotation Functions selection button
---------------------------------------------------------*/

local rotation_function_buttons_list = {}
local FUNCTION_BUTTON_ROTATION = {}

function FUNCTION_BUTTON_ROTATION:Init()
	self:SetSize(168, 25)
	table.insert(rotation_function_buttons_list, self)
	
	self.DoClick = function()
		local tab = self:GetParent()
		
		tab.activebutton = self
		tab:UpdateDescription()
		
		// Optional pivot point / axis selections
		if self.options[1] ~= 0 then
			tab.list_pivotpoint:SetVisible(true)
		else
			tab.list_pivotpoint:SetVisible(false)
		end
		
		if self.options[2] ~= 0 then
			tab.list_line_axis:SetVisible(true)
		else
			tab.list_line_axis:SetVisible(false)
		end
		
		// Main function selections
		if self.selections[1] ~= 0 then
			tab.colour_panel_1:SetColour(BGColor_Line)
			tab.list_line_1:SetVisible(true)
		else
			tab.colour_panel_1:SetColour(BGColor_Disabled)
			tab.list_line_1:SetVisible(false)
		end
		
		if self.selections[2] ~= 0 then
			tab.colour_panel_2:SetColour(BGColor_Line)
			tab.list_line_2:SetVisible(true)
		else
			tab.colour_panel_2:SetColour(BGColor_Disabled)
			tab.list_line_2:SetVisible(false)
		end
		
		if self.selections[3] ~= 0 then
			tab.colour_panel_3:SetColour(BGColor_Plane)
			tab.list_plane_1:SetVisible(true)
		else
			tab.colour_panel_3:SetColour(BGColor_Disabled)
			tab.list_plane_1:SetVisible(false)
		end
		
		if self.selections[4] ~= 0 then
			tab.colour_panel_4:SetColour(BGColor_Plane)
			tab.list_plane_2:SetVisible(true)
		else
			tab.colour_panel_4:SetColour(BGColor_Disabled)
			tab.list_plane_2:SetVisible(false)
		end		
	end
end

// Override mouse functions (make it into a toggle button)
function FUNCTION_BUTTON_ROTATION:OnMousePressed( mousecode )
	if !self.Depressed then
		// pop up any previously depressed buttons
		for k, v in pairs (rotation_function_buttons_list) do
			if v.Depressed then
				v.Depressed = false
			end
		end
		self.Depressed = true
		return self.DoClick()
	end
end

function FUNCTION_BUTTON_ROTATION:OnMouseReleased( mousecode )
end

vgui.Register("PA_Function_Button_Rotation", FUNCTION_BUTTON_ROTATION, "DButton")

/*---------------------------------------------------------
   Name: Standard manipulation window buttons
---------------------------------------------------------*/

local ZERO_BUTTON = {}
function ZERO_BUTTON:Init()
	self:SetSize(20, 20)
	self:SetText( "0" )
	self:SetToolTip( "Set slider values to 0" )
end

function ZERO_BUTTON:SetSliders( panel )
	self:SetFunction( function()
		panel:SetValues( Vector(0,0,0) )
		return true
	end )
end

vgui.Register("PA_Zero_Button", ZERO_BUTTON, "PA_Function_Button")


local NEGATE_BUTTON = {}
function NEGATE_BUTTON:Init()
	self:SetSize(20, 20)
	self:SetText( "-" )
	self:SetToolTip( "Negate slider values" )
end

function NEGATE_BUTTON:SetSliders( panel )
	self:SetFunction( function()
		local v = panel:GetValues()
		panel:SetValues( Vector(-v.x, -v.y, -v.z) )
		return true
	end )
end

vgui.Register("PA_Negate_Button", NEGATE_BUTTON, "PA_Function_Button")


local COPY_CLIPBOARD_BUTTON = {}
function COPY_CLIPBOARD_BUTTON:Init()
	self:SetSize(40, 20)
	self:SetText( "Copy" )
	self:SetToolTip( "Copy values to clipboard" )
end

function COPY_CLIPBOARD_BUTTON:SetSliders( panel )
	self:SetFunction( function()
		local v = panel:GetValues()
		// Format string for better use with E2
		local x = tostring( math.Round(v.x * 1000) / 1000 )
		local y = tostring( math.Round(v.y * 1000) / 1000 )
		local z = tostring( math.Round(v.z * 1000) / 1000 )
		
		local str = x .. ", " .. y .. ", " .. z
		SetClipboardText( str )
		return true
	end )
end

vgui.Register("PA_Copy_Clipboard_Button", COPY_CLIPBOARD_BUTTON, "PA_Function_Button")


local UPDATE_BUTTON = {}
function UPDATE_BUTTON:Init()
	self:SetSize(90, 25)
	self:SetText( "Update" )
	self:SetToolTip( "Update other sliders according to these values" )
end

vgui.Register("PA_Update_Button", UPDATE_BUTTON, "PA_Function_Button")


local COPY_BUTTON = {}
function COPY_BUTTON:Init()
	self:SetSize(26, 25)
	self:SetText( "=" )
	self:SetToolTip( "Set primary value equal to secondary" )
end

vgui.Register("PA_Copy_Button", COPY_BUTTON, "PA_Function_Button")


local ADD_BUTTON = {}
function ADD_BUTTON:Init()
	self:SetSize(26, 25)
	self:SetText( "+" )
	self:SetToolTip( "Add this value to primary value" )
end

vgui.Register("PA_Add_Button", ADD_BUTTON, "PA_Function_Button")


local SUBTRACT_BUTTON = {}
function SUBTRACT_BUTTON:Init()
	self:SetSize(26, 25)
	self:SetText( "-" )
	self:SetToolTip( "Subtract this value from primary value" )
end

vgui.Register("PA_Subtract_Button", SUBTRACT_BUTTON, "PA_Function_Button")


local COPY_RIGHT_BUTTON = {}
function COPY_RIGHT_BUTTON:Init()
	self:SetSize(26, 25)
	self:SetText( ">" )
	self:SetToolTip( "Copy value across to secondary slider" )
end

vgui.Register("PA_Copy_Right_Button", COPY_RIGHT_BUTTON, "PA_Function_Button")


local COPY_LEFT_BUTTON = {}
function COPY_LEFT_BUTTON:Init()
	self:SetSize(26, 25)
	self:SetText( "<" )
	self:SetToolTip( "Copy value across to primary slider" )
end

vgui.Register("PA_Copy_Left_Button", COPY_LEFT_BUTTON, "PA_Function_Button")


local MOVE_BUTTON = {}
function MOVE_BUTTON:SetFunction( func )
	self.DoClick = function()
		// Alt to bring up stack number query
		local alt = LocalPlayer():KeyDown( IN_WALK )
		if alt then
			vgui.Create( "PA_Stack_Popup" )
			return
		end
		
		local ret = func()
		if ret == true then
			play_sound_true()
		elseif ret == false then
			play_sound_false()
		end
	end
end

function MOVE_BUTTON:Think()
	if IsValid(PA_activeent) and self:GetDisabled() then
		self:SetDisabled(false)
	elseif !IsValid(PA_activeent) and !self:GetDisabled() then
		self:SetDisabled(true)
	end
end

vgui.Register("PA_Move_Button", MOVE_BUTTON, "DButton")

/*---------------------------------------------------------
   Name: PA_Colour_Panel
   Common background panel for listviews
---------------------------------------------------------*/

local COLOUR_PANEL = {}
function COLOUR_PANEL:Init()
	self.colour = table.Copy( BGColor_Disabled )
	self.setcolour = BGColor_Disabled
	local parent = self:GetParent()
	self:SetSize( 150, parent:GetTall()/2 - 15 )
end

function COLOUR_PANEL:SetColour( colour )
	self.setcolour = colour
end

function COLOUR_PANEL:Paint(w,h)
	for k, v in pairs (self.colour) do
		self.colour[k] = v + (self.setcolour[k] - v)/10
	end
	
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), self.colour)
	draw.RoundedBox(6, 5, 15, self:GetWide() - 10, self:GetTall() - 20, BGColor)
end

vgui.Register("PA_Colour_Panel", COLOUR_PANEL, "DPanel")

/*---------------------------------------------------------
   Name: Constraints Panels
   Standard panels for constraints tab
---------------------------------------------------------*/

local CONSTRAINT_TITLE_TEXT = {}
function CONSTRAINT_TITLE_TEXT:Init()
	self:SetSize( self:GetParent():GetWide(), 15 )
	self:SetFontInternal("Default")
	self:SetContentAlignment(2)
end

vgui.Register("PA_Constraint_Title_Text", CONSTRAINT_TITLE_TEXT, "DLabel")
 

local CONSTRAINTS_SHEET = {}

function CONSTRAINTS_SHEET:Paint(w,h)
	draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), Color(140,140,140,255))
end

// Taken from gamemodes/sandbox/gamemode/spawnmenu/controls/control_presets.lua
function CONSTRAINTS_SHEET:AddComboBox( data )
	local data = table.LowerKeyNames( data )
	local ctrl = vgui.Create( "ControlPresets", self )
	ctrl:SetPreset( data.folder )
	if ( data.options ) then
		for k, v in pairs( data.options ) do
			if ( k != "id" ) then // Some txt file configs still have an `ID'. But these are redundant now.
				ctrl:AddOption( k, v )
			end
		end
	end
   
	if ( data.cvars ) then
		for k, v in pairs( data.cvars ) do
			ctrl:AddConVar( v )
		end
	end
   
   ctrl:SetWide(300)
   
	return ctrl
end

vgui.Register("PA_Constraints_Sheet", CONSTRAINTS_SHEET, "DPanel")

local CONSTRAINT_SLIDER = {}

function CONSTRAINT_SLIDER:Init()
	-- self:SetSize(130, 100) -- Keep the second number at 100
	self.Label:SetSize( 100 )
	self:SetMinMax( 0, 50000 )
end

// Base this off PA_XYZ_Slider so the keyboard hook functions apply
vgui.Register("PA_Constraint_Slider", CONSTRAINT_SLIDER, "PA_XYZ_Slider")

/*---------------------------------------------------------
   Name: PA_ColourCircle
   HSV Colour selection wheel for displays tab
---------------------------------------------------------*/

local COLOUR_CIRCLE = {}
function COLOUR_CIRCLE:Init()
	local H = GetConVarNumber( PA_.."attachcolour_h" )
	local S = GetConVarNumber( PA_.."attachcolour_s" )
	self:SetColor( H,S )
end

function COLOUR_CIRCLE:TranslateValues( x, y )
	// Modified version of default TranslateValues function - so it won't print to console all the damn time
	x = x - 0.5
	y = y - 0.5
	local angle = math.atan2( x, y )
	local length = math.sqrt( x*x + y*y )
	length = math.Clamp( length, 0, 0.5 )
	x = 0.5 + math.sin( angle ) * length
	y = 0.5 + math.cos( angle ) * length
	
	self.H = math.deg( angle ) + 270
	self.S = length * 2
	
	self:OnChange( self.H, self.S )
	
	return x, y
end

function COLOUR_CIRCLE:GetColor()
	return self.H, self.S
end 

function COLOUR_CIRCLE:SetColor( H, S )
	self.H, self.S = H, S
	local x, y
	local length = S / 2
	local angle = math.rad( H - 270 )
	
	local x = 0.5 + math.sin( angle ) * length
	local y = 0.5 + math.cos( angle ) * length
	
	//self:SetSlideX( x )
	//self:SetValue( y )
	
	self:OnChange( self.H, self.S )
	
	return x, y
end

function COLOUR_CIRCLE:OnChange( H, S )
	// Overwrite in main body
end

vgui.Register("PA_ColourCircle", COLOUR_CIRCLE, "DColorCube")

/*---------------------------------------------------------
   Name: PA_ColourControl
   Full HSV Colour selection display for displays tab
---------------------------------------------------------*/

local HSV_COLOUR_CONTROL = {}
function HSV_COLOUR_CONTROL:Init()
	self:SetSize(300, 200)
	self.ColorMixer = vgui.Create( "DColorMixer", self )
		self.ColorMixer:SetPos( 0, 35 )
		self.ColorMixer:SetSize( 250, 150 )
		self.ColorMixer:SetPalette( false )
		self.ColorMixer.ValueChanged = function( panel, color )
			local H, S, V = ColorToHSV( color )
			local A = color.a or 255
			-- PrintTable( color ) -- print( tostring( color ) )
			-- PrintTable( self.ColorMixer:GetColor() )
			-- print( "changed: " .. H .. ", " .. S .. ", " .. V .. ", " .. A )
			RunConsoleCommand( self.convar .. "_h", H )
			RunConsoleCommand( self.convar .. "_s", S )
			RunConsoleCommand( self.convar .. "_v", V )
			RunConsoleCommand( self.convar .. "_a", A )
		end
		
	/*
	self.ColourCircle = vgui.Create("PA_ColourCircle", self)
		self.ColourCircle:SetPos(0, 35)
		self.ColourCircle:SetSize(150, 150)
		self.ColourCircle.OnChange = function( panel, H, S )
			local colour_brightness = HSVToColor( H, S, 1 )
			self.Bar_Brightness:SetFGColor( colour_brightness )
			
			local V = self.Bar_Brightness:GetColor()
			local colour_alpha = HSVToColor( H, S, V )
			self.Bar_Alpha:SetFGColor( colour_alpha )
			
			RunConsoleCommand( self.convar .. "_h", H )
			RunConsoleCommand( self.convar .. "_s", S )
		end 
	
	
	self.Bar_Brightness = vgui.Create( "DAlphaBar", self )
		-- self.Bar_Brightness:SetBGColor( "vgui/hsv-brightness" )
		self.Bar_Brightness:SetPaintBackground( "vgui/hsv-brightness" )
		self.Bar_Brightness:SetPos(160, 45)
		self.Bar_Brightness:SetSize(25, 130)
		self.Bar_Brightness.GetColor = function()
			return 1 - self.Bar_Brightness:GetValue()
		end
		
		self.Bar_Brightness.SetColor = function( panel, V )
			self.Bar_Brightness:SetValue( 1 - V )
			self.Bar_Brightness:OnChange( V * 255 )
		end
		
		self.Bar_Brightness.OnChange = function( panel, brightness )
			local V = brightness / 255
			local H, S = self.ColourCircle:GetColor()
			local colour_alpha = HSVToColor( H, S, V )
			self.Bar_Alpha:SetFGColor( colour_alpha )
			
			RunConsoleCommand( self.convar .. "_v", V )
		end 
		
		// Remove default alpha bar background image
--[[ 		self.Bar_Brightness.PerformLayout = function()
			DSlider.PerformLayout( self.Bar_Brightness )
		end
		self.Bar_Brightness.imgBackground:Remove() ]]
	
	AddMenuText( "HSV", 130, 182, self )
	

	self.Bar_Alpha = vgui.Create( "DAlphaBar", self )
		self.Bar_Alpha:SetPos(210, 45)
		self.Bar_Alpha:SetSize(25, 130)
		self.Bar_Alpha.GetColor = function()
			return ( 1 - self.Bar_Alpha:GetValue() ) * 255
		end
		
		self.Bar_Alpha.SetColor = function( panel, alpha )
			self.Bar_Alpha:SetValue( 1 - alpha / 255 )
			self.Bar_Alpha:OnChange( alpha )
		end
		
		self.Bar_Alpha.OnChange = function( panel, alpha )
			RunConsoleCommand( self.convar .. "_a", alpha )
		end
	 
	AddMenuText( "Alpha", 207, 182, self )
	
	
	*/
	self.button_defaults = vgui.Create( "PA_Function_Button", self )
		self.button_defaults:SetPos(200, 5)
		self.button_defaults:SetSize(90, 25)
		self.button_defaults:SetText( "Reset Defaults" )
		self.button_defaults:SetFunction( function()
			self:SetColor( self.default_H, self.default_S, self.default_V, self.default_A )
			return true
		end )
end

function HSV_COLOUR_CONTROL:SetConVar( convar )
	self.convar = convar
end

function HSV_COLOUR_CONTROL:SetDefaults( H, S, V, A )
	self.default_H = H
	self.default_S = S
	self.default_V = V
	self.default_A = A
end

function HSV_COLOUR_CONTROL:SetColor( H, S, V, A )
	local col = HSVToColor( H, S, V )
	col.a = A
	self.ColorMixer:SetColor( col )
	-- self.ColourCircle:SetColor( H, S )
	-- self.Bar_Brightness:SetColor( V )
	-- self.Bar_Alpha:SetColor( A )  
end

function HSV_COLOUR_CONTROL:GetColor()
	local col = self.ColorMixer:GetColor()
	local H, S, V = ColorToHSV( col )
	local A = col.a
	-- return self.ColorMixer:GetColor()
	-- local H, S = self.ColourCircle:GetColor()
	-- local V = self.Bar_Brightness:GetColor()
	-- local A = self.Bar_Alpha:GetColor()
	return H, S, V, A 
end

function HSV_COLOUR_CONTROL:Paint( w, h )
	
end

vgui.Register("PA_ColourControl", HSV_COLOUR_CONTROL, "DPanel")

/*---------------------------------------------------------
   Name: PA_Construct_Multiselect
   Multi construct selection for displays/move constructs tabs
---------------------------------------------------------*/

local CONSTRUCT_MULTISELECT = {}
function CONSTRUCT_MULTISELECT:Init()
	self:SetSize(555, 215)
	
	self.colour_panel_1 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_1:SetPos(0, 0)
		self.colour_panel_1:SetSize(150, 215)
		self.colour_panel_1:SetColour( BGColor_Point )
	
	self.list_points = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_points:Text( "Points", "Point", self.colour_panel_1 )
		self.list_points:SetToolTip( "Double click to deselect" )
		self.list_points:SetPos(20, 30)
		self.list_points:SetMultiSelect(true)
		self.list_points.DoDoubleClick = function( Line, LineID )
			self.list_points:ClearSelection()
		end
	
	self.colour_panel_2 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_2:SetPos(150, 0)
		self.colour_panel_2:SetSize(150, 215)
		self.colour_panel_2:SetColour( BGColor_Line )
	
	self.list_lines = vgui.Create( "PA_Construct_ListView", self.colour_panel_2 )
		self.list_lines:Text( "Lines", "Line", self.colour_panel_2 )
		self.list_lines:SetToolTip( "Double click to deselect" )
		self.list_lines:SetPos(20, 30)
		self.list_lines:SetMultiSelect(true)
		self.list_lines.DoDoubleClick = function( Line, LineID )
			self.list_lines:ClearSelection()
		end
	
	self.colour_panel_3 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_3:SetPos(300, 0)
		self.colour_panel_3:SetSize(150, 215)
		self.colour_panel_3:SetColour( BGColor_Plane )
	
	self.list_planes = vgui.Create( "PA_Construct_ListView", self.colour_panel_3 )
		self.list_planes:Text( "Planes", "Plane", self.colour_panel_3 )
		self.list_planes:SetToolTip( "Double click to deselect" )
		self.list_planes:SetPos(20, 30)
		self.list_planes:SetMultiSelect(true)
		self.list_planes.DoDoubleClick = function( Line, LineID )
			self.list_planes:ClearSelection()
		end
	
	
	self.button_selectall = vgui.Create( "PA_Function_Button", self )
		self.button_selectall:SetPos(462, 30)
		self.button_selectall:SetSize(80, 30)
		self.button_selectall:SetText( "Select All" )
		self.button_selectall:SetToolTip( "Select all constructs" )
		self.button_selectall:SetFunction( function()
			self:SelectAll( true )
			return true
		end )
	
	self.button_deselectall = vgui.Create( "PA_Function_Button", self )
		self.button_deselectall:SetPos(462, 65)
		self.button_deselectall:SetSize(80, 30)
		self.button_deselectall:SetText( "Deselect All" )
		self.button_deselectall:SetToolTip( "Deselect all constructs" )
		self.button_deselectall:SetFunction( function()
			self:SelectAll( false )
			return true
		end )
	
	self.button_attach = vgui.Create( "PA_Function_Button", self )
		self.button_attach:SetPos(462, 100)
		self.button_attach:SetSize(80, 30)
		self.button_attach:SetText( "Attach" )
		self.button_attach:SetToolTip( "Attach constructs to the selected entity (detach if no ent selected)" )
		self.button_attach:SetFunction( function()
			for k, v in pairs( self.list_points:GetSelected() ) do
				ID = v:GetID()
				if PA_funcs.construct_exists( "Point", ID ) then
					PA_funcs.attach_point( ID, PA_activeent )
				end
			end
			
			for k, v in pairs( self.list_lines:GetSelected() ) do
				ID = v:GetID()
				if PA_funcs.construct_exists( "Line", ID ) then
					PA_funcs.attach_line( ID, PA_activeent )
				end
			end
			
			for k, v in pairs( self.list_planes:GetSelected() ) do
				ID = v:GetID()
				if PA_funcs.construct_exists( "Plane", ID ) then
					PA_funcs.attach_plane( ID, PA_activeent )
				end
			end
			
			return true
		end )
	
	self.button_delete = vgui.Create( "PA_Function_Button", self )
		self.button_delete:SetPos(462, 135)
		self.button_delete:SetSize(80, 30)
		self.button_delete:SetText( "Delete" )
		self.button_delete:SetToolTip( "Delete the selected constructs" )
		self.button_delete:SetFunction( function()
			local ID
			
			for k, v in pairs( self.list_points:GetSelected() ) do
				ID = v:GetID()
				PA_funcs.delete_point( ID )
			end
			
			for k, v in pairs( self.list_lines:GetSelected() ) do
				ID = v:GetID()
				PA_funcs.delete_line( ID )
			end
			
			for k, v in pairs( self.list_planes:GetSelected() ) do
				ID = v:GetID()
				PA_funcs.delete_plane( ID )
			end
			
			return true
		end )
	
	self.button_deleteall = vgui.Create( "PA_Function_Button", self )
		self.button_deleteall:SetPos(462, 170)
		self.button_deleteall:SetSize(80, 30)
		self.button_deleteall:SetText( "Delete All" )
		self.button_deleteall:SetToolTip( "Delete all existing constructs" )
		self.button_deleteall:SetFunction( function()
			
			PA_funcs.delete_points()
			PA_funcs.delete_lines()
			PA_funcs.delete_planes()
			
			return true
		end )
end

function CONSTRUCT_MULTISELECT:SelectAll( value )
	local function SelectLines( value, panel, construct_table )
		for id = 1, 9 do
			local line = panel.Sorted[ id ]
			line:SetSelected( value )
			if self.visibility then
				construct_table[id].visible = value
			end
		end
	end
	
	SelectLines( value, self.list_points, precision_align_points )
	SelectLines( value, self.list_lines, precision_align_lines )
	SelectLines( value, self.list_planes, precision_align_planes )
end

function CONSTRUCT_MULTISELECT:GetSelection()
	local selection = {}
	selection.points = {}
	selection.lines = {}
	selection.planes = {}
	
	for k, v in pairs( self.list_points:GetSelected() ) do
		local ID = v:GetID()
		if PA_funcs.construct_exists( "Point", ID  ) then
			table.insert( selection.points, ID )
		end
	end
	
	for k, v in pairs( self.list_lines:GetSelected() ) do
		local ID = v:GetID()
		if PA_funcs.construct_exists( "Line", ID  ) then
			table.insert( selection.lines, ID )
		end
	end
	
	for k, v in pairs( self.list_planes:GetSelected() ) do
		local ID = v:GetID()
		if PA_funcs.construct_exists( "Plane", ID  ) then
			table.insert( selection.planes, ID )
		end
	end
	
	if ( #selection.points + #selection.lines + #selection.planes ) == 0 then
		selection = nil
	end
	
	return selection
end

function CONSTRUCT_MULTISELECT:Paint(w,h)
end

vgui.Register("PA_Construct_Multiselect", CONSTRUCT_MULTISELECT, "DPanel")


//********************************************************************************************************************//
// Custom CPanel Functions
//********************************************************************************************************************//


// Reduce width for lower resolutions to compensate for side scrollbar
local CPanel_Width
if ScrH() < 1050 then
	CPanel_Width = 281 --265
else
	CPanel_Width = 297 --281
end

local function create_buttons_standard( panel, text )
	panel.button_view = vgui.Create( "PA_Function_Button", panel )
		panel.button_view:SetPos(0, 120)
		panel.button_view:SetSize(CPanel_Width/2, 20)
		panel.button_view:SetText( "View" )
		panel.button_view:SetToolTip( "View the selected " .. text )

	panel.button_delete = vgui.Create( "PA_Function_Button", panel )
		panel.button_delete:SetPos(CPanel_Width/2, 120)
		panel.button_delete:SetSize(CPanel_Width/2, 20)
		panel.button_delete:SetText( "Delete" )
		panel.button_delete:SetToolTip( "Delete the selected " .. text )

	panel.button_attach = vgui.Create( "PA_Function_Button", panel )
		panel.button_attach:SetPos(0, 140)
		panel.button_attach:SetSize(CPanel_Width/2, 20)
		panel.button_attach:SetText( "Attach" )
		panel.button_attach:SetToolTip( "Attach " .. text .. " to selected entity (detach if no ent selected)" )

	panel.button_deleteall = vgui.Create( "PA_Function_Button", panel )
		panel.button_deleteall:SetPos(CPanel_Width/2, 140)
		panel.button_deleteall:SetSize(CPanel_Width/2, 20)
		panel.button_deleteall:SetText( "Delete All" )
		panel.button_deleteall:SetToolTip( "Delete all " .. text .. "s" )
end


//********************************************************************************************************************//
// CPanel Controls
//********************************************************************************************************************//


// Open a particular tab in the manipulation panel
local function Open_Manipulation_Tab( Tab )
	PA_manipulation_panel.panel:SetActiveTab( Tab )
	if !PA_manipulation_panel:IsVisible() then
		PA_manipulation_panel:SetVisible(true)
	end
end

// Perform double click function on a listview within the manipulation panel
local function Listview_DoDoubleClick( panel, LineID )
		panel:ClearSelection()
		
		local Line = panel:GetLine( LineID )
		panel:SelectItem( Line )
		panel:DoDoubleClick( Line, LineID )
end

local TOOL_POINT_PANEL = {}
function TOOL_POINT_PANEL:Init()
	AddMenuText("POINT", CPanel_Width/2 - 18, 0, self)
	
	self.list_primarypoint = vgui.Create("PA_Construct_ListView", self)
		self.list_primarypoint:Text( "", "Point" )
		self.list_primarypoint:SetToolTip( "Primary selection (functions will only affect this point)" )
		self.list_primarypoint:SetHeaderHeight( 1 )
		self.list_primarypoint:SetPos(0, 15)
		self.list_primarypoint:SetSize(CPanel_Width/2 - 5, 100)
		self.list_primarypoint:SetMultiSelect(false)
		self.list_primarypoint:SetIndicatorOffset( 15 )
		self.list_primarypoint.OnRowSelected = function( panel, line )
			PA_selected_point = line
		end
		
		self.list_primarypoint.DoDoubleClick = function( Line, LineID )
			local panel = PA_manipulation_panel.points_tab
			Open_Manipulation_Tab( panel.tab )
			Listview_DoDoubleClick( panel.list_primarypoint, LineID )
		end
		self.list_primarypoint:SelectFirstItem()
	
	self.list_secondarypoint = vgui.Create("PA_Construct_ListView", self)
		self.list_secondarypoint:Text( "", "Point" )
		self.list_secondarypoint:SetToolTip( "Secondary selection" )
		self.list_secondarypoint:SetHeaderHeight( 1 )
		self.list_secondarypoint:SetPos(CPanel_Width/2 + 5, 15)
		self.list_secondarypoint:SetSize(CPanel_Width/2 - 5, 100)
		self.list_secondarypoint:SetMultiSelect(false)
		self.list_secondarypoint:SetIndicatorOffset( 15 )
		
		self.list_secondarypoint.DoDoubleClick = function( Line, LineID )
			local panel = PA_manipulation_panel.points_tab
			Open_Manipulation_Tab( panel.tab )
			Listview_DoDoubleClick( panel.list_primarypoint, LineID )
		end
		self.list_secondarypoint:SelectFirstItem()
	
	create_buttons_standard( self, "point" )
	
		self.button_view:SetFunction( function()
			if !PA_funcs.construct_exists( "Point", PA_selected_point ) then return false end
			local point = PA_funcs.point_global( PA_selected_point )
			return PA_funcs.set_playerview( point.origin )
		end )
		
		self.button_delete:SetFunction( function()
			return PA_funcs.delete_point( PA_selected_point )
		end )

		self.button_attach:SetFunction( function()
			return PA_funcs.attach_point( PA_selected_point, PA_activeent )
		end )

		self.button_deleteall:SetFunction( function()
			self.list_primarypoint:SelectFirstItem()
			self.list_secondarypoint:SelectFirstItem()
			return PA_funcs.delete_points()
		end )
	
	self.button_moveentity = vgui.Create( "PA_Move_Button", self )
		self.button_moveentity:SetPos(0, 160)
		self.button_moveentity:SetSize(CPanel_Width, 20)
		self.button_moveentity:SetText( "Move Entity" )
		self.button_moveentity:SetToolTip( "Move entity by Primary -> Secondary" )
		self.button_moveentity:SetFunction( function()
			local PA_selected_point2 = self.list_secondarypoint:GetSelectedLine()
			if PA_selected_point == PA_selected_point2 then
				Warning("Cannot move between the same point!")
				return false
			end
			
			local point1 = PA_funcs.point_global( PA_selected_point )
			local point2 = PA_funcs.point_global( PA_selected_point2 )
			
			if !point1 or !point2 then
				Warning("Points not correctly defined")
				return false
			end
			
			if !PA_funcs.move_entity(point1.origin, point2.origin, PA_activeent) then return false end
		end )
end

function TOOL_POINT_PANEL:PerformLayout()
	self:SetSize(CPanel_Width, 180)
end

function TOOL_POINT_PANEL:Paint(w,h)
	draw.RoundedBox(6, 50, 0, CPanel_Width - 100, 14, BGColor_Point)
end

vgui.Register("PA_Tool_Point_Panel", TOOL_POINT_PANEL, "DPanel")



local TOOL_LINE_PANEL = {}
function TOOL_LINE_PANEL:Init()
	AddMenuText("LINE", CPanel_Width/2 - 12, 0, self)
	
	self.list_line = vgui.Create( "PA_Construct_ListView", self )
		self.list_line:Text( "", "Line" )
		self.list_line:SetHeaderHeight( 1 )
		self.list_line:SetPos(0, 15)
		self.list_line:SetSize(CPanel_Width, 100)
		self.list_line:SetMultiSelect(false)
		self.list_line:SetIndicatorOffset( 15 )
		self.list_line.OnRowSelected = function( panel, line )
			PA_selected_line = line
		end
		
		self.list_line.DoDoubleClick = function( Line, LineID )
			local panel = PA_manipulation_panel.lines_tab
			Open_Manipulation_Tab( panel.tab )
			Listview_DoDoubleClick( panel.list_primary, LineID )
		end
		self.list_line:SelectFirstItem()
	
	create_buttons_standard( self, "line" )
	
		self.button_view:SetFunction( function()
			if !PA_funcs.construct_exists( "Line", PA_selected_line ) then return false end
			local line = PA_funcs.line_global( PA_selected_line )
			return PA_funcs.set_playerview( line.startpoint )
		end )
		
		self.button_delete:SetFunction( function()
			return PA_funcs.delete_line(PA_selected_line)
		end )
		
		self.button_attach:SetFunction( function()
			return PA_funcs.attach_line(PA_selected_line, PA_activeent)
		end )
		
		self.button_deleteall:SetFunction( function()
			self.list_line:SelectFirstItem()
			return PA_funcs.delete_lines()
		end )
		
	self.button_moveentity = vgui.Create( "PA_Move_Button", self )
		self.button_moveentity:SetPos(0, 160)
		self.button_moveentity:SetSize(CPanel_Width, 20)
		self.button_moveentity:SetText( "Move Entity" )
		self.button_moveentity:SetToolTip( "Move entity by line" )
		self.button_moveentity:SetFunction( function()
			local line = PA_funcs.line_global(PA_selected_line)
			if !line then
				Warning("Line not correctly defined")
				return false
			end
			
			local point1 = line.startpoint
			local point2 = line.endpoint
			if !PA_funcs.move_entity(point1, point2, PA_activeent) then return false end
		end )
end

function TOOL_LINE_PANEL:PerformLayout()
	self:SetSize(CPanel_Width, 180)
end

function TOOL_LINE_PANEL:Paint(w,h)
	draw.RoundedBox(6, 50, 0, CPanel_Width - 100, 14, BGColor_Line)
end

vgui.Register("PA_Tool_Line_Panel", TOOL_LINE_PANEL, "DPanel")



local TOOL_PLANE_PANEL = {}
function TOOL_PLANE_PANEL:Init()
	AddMenuText("PLANE", CPanel_Width/2 - 17, 0, self)
	
	self.list_plane = vgui.Create( "PA_Construct_ListView", self )
		self.list_plane:Text( "", "Plane" )
		self.list_plane:SetHeaderHeight( 1 )
		self.list_plane:SetPos(0, 15)
		self.list_plane:SetSize(CPanel_Width, 100)
		self.list_plane:SetMultiSelect(false)
		self.list_plane:SetIndicatorOffset( 15 )
		self.list_plane.OnRowSelected = function( panel, line )
			PA_selected_plane = line
		end
		
		self.list_plane.DoDoubleClick = function( Line, LineID )
			local panel = PA_manipulation_panel.planes_tab
			Open_Manipulation_Tab( panel.tab )
			Listview_DoDoubleClick( panel.list_primary, LineID )
		end
		self.list_plane:SelectFirstItem()
	
	create_buttons_standard( self, "plane" )
	
		self.button_view:SetFunction( function()
			if !PA_funcs.construct_exists( "Plane", PA_selected_plane ) then return false end
			local plane = PA_funcs.plane_global( PA_selected_plane )
			return PA_funcs.set_playerview( plane.origin )
		end )
		
		self.button_delete:SetFunction( function()
			return PA_funcs.delete_plane(PA_selected_plane)
		end )
		
		self.button_attach:SetFunction( function()
			return PA_funcs.attach_plane(PA_selected_plane, PA_activeent)
		end )
		
		self.button_deleteall:SetFunction( function()
			self.list_plane:SelectFirstItem()
			return PA_funcs.delete_planes()
		end )
end

function TOOL_PLANE_PANEL:PerformLayout()
	self:SetSize(CPanel_Width, 160)
end

function TOOL_PLANE_PANEL:Paint(w,h)
	draw.RoundedBox(6, 50, 0, CPanel_Width - 100, 14, BGColor_Plane)
end

vgui.Register("PA_Tool_Plane_Panel", TOOL_PLANE_PANEL, "DPanel")


local TOOL_LIST = {}
function TOOL_LIST:Init()
	self.list_tooltype = vgui.Create("DListView", self)
		self.list_tooltype:SetPos(0, 0)
		self.list_tooltype:SetSize(CPanel_Width, 153)
		self.list_tooltype:SetToolTip( "Select left-click function" )
		self.list_tooltype:SetHeaderHeight( 0 )
		self.list_tooltype:SetSortable(false)
		self.list_tooltype:SetMultiSelect(false)
		self.list_tooltype:AddColumn("")
		//self.list_tooltype:AddColumn("                     Left Click Assignment")
		
		self.list_tooltype:AddLine("Point - Hitpos")
		self.list_tooltype:AddLine("Point - Coordinate Centre")
		self.list_tooltype:AddLine("Point - Mass Centre")
		self.list_tooltype:AddLine("Point - Bounding Box Centre")
		self.list_tooltype:AddLine("Line  - Start / End (Alt)")
		self.list_tooltype:AddLine("Line  - Hitpos + Hitnormal")
		self.list_tooltype:AddLine("Line  - Hitnormal")
		self.list_tooltype:AddLine("Plane - Hitpos + Hitnormal")
		self.list_tooltype:AddLine("Plane - Hitnormal")
		self.list_tooltype:SelectItem( self.list_tooltype:GetLine(GetConVarNumber(PA_.."tooltype")) )
		self.list_tooltype.OnRowSelected = function(parent, line, isselected)
			RunConsoleCommand( PA_.."tooltype", tostring(line) )
		end
	
	// Draw coloured tool option backgrounds
	for i = 1, 9 do
		local line = self.list_tooltype:GetLine(i)
		local height = line:GetTall()
		local DrawColourOutline
		
		if i < 5 then
			DrawColourOutline = table.Copy(BGColor_Point)
		elseif i < 8 then
			DrawColourOutline = table.Copy(BGColor_Line)
		else
			DrawColourOutline = table.Copy(BGColor_Plane)
		end
		
		local DrawColour = DrawColourOutline
		
		line.Paint = function( w, h )
			if line:IsSelected() then
				DrawColour.a = 150
			else
				DrawColour.a = 200
			end
			surface.SetDrawColor( DrawColour )
			surface.DrawRect( 0, 0, CPanel_Width, height - 7 )
			
			surface.SetDrawColor( DrawColourOutline )
			surface.DrawOutlinedRect(0, 0, CPanel_Width - 2, height-7)
		end
		
		line.Columns[1]:SetTextColor( color_black )
		line.Columns[1].UpdateColours = function() end
	end
end

function TOOL_LIST:PerformLayout()
	self:SetSize(CPanel_Width, 153)
end

function TOOL_LIST:Paint(w,h)
end

vgui.Register("PA_CPanel_tool_list", TOOL_LIST, "DPanel")

local TOOL_OPTIONS = {}
function TOOL_OPTIONS:Init()
	self.checkbox_display = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_display:SetPos(0, 2)
		self.checkbox_display:SetText( "Enable construct displays" )
		self.checkbox_display:SetDark( true )
		self.checkbox_display:SetValue( 1 )
		self.checkbox_display:SizeToContents()
		self.checkbox_display:SetToolTip( "Show/Hide all constructs" )
		self.checkbox_display:SetConVar(  PA_.."displayhud" )

	self.checkbox_snap_edge = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_snap_edge:SetPos(0, 21)
		self.checkbox_snap_edge:SetText( "Snap to Edges" )
		self.checkbox_snap_edge:SetDark( true )
		self.checkbox_snap_edge:SizeToContents()
		self.checkbox_snap_edge:SetToolTip( "Snap to the edges of props when placing constructs" )
		self.checkbox_snap_edge:SetConVar( PA_.."edge_snap" )
	
	self.checkbox_snap_centre = vgui.Create( "DCheckBoxLabel", self )
		self.checkbox_snap_centre:SetPos(0, 40)
		self.checkbox_snap_centre:SetText( "Snap to Centre Lines" )
		self.checkbox_snap_centre:SetDark( true )
		self.checkbox_snap_centre:SizeToContents()
		self.checkbox_snap_centre:SetToolTip( "Snap to the centre-lines of props when placing constructs" )
		self.checkbox_snap_centre:SetConVar( PA_.."centre_snap" )

	self.slider_snap_dist = vgui.Create( "DNumSlider", self )
		self.slider_snap_dist:SetPos(0, 59)
		-- self.slider_snap_dist:SetSize(CPanel_Width, 30)
		self.slider_snap_dist.Label:SetSize( 80 )
		self.slider_snap_dist:SetWide( CPanel_Width )
		self.slider_snap_dist:SetText( "Snap Sensitivity" )
		self.slider_snap_dist.Label:SetDark( true )
		self.slider_snap_dist:SetMinMax( 0.1, 100 )
		self.slider_snap_dist:SetDecimals( 1 )
		self.slider_snap_dist.Slider:SetNotches( self.slider_snap_dist.Slider:GetWide() / 4 )
		self.slider_snap_dist:SetToolTip( "Sets the maximum distance for edge/centre snap detection (in units)" )
		self.slider_snap_dist:SetConVar( PA_.."snap_distance" )
	
	// Help button
	self.button_help = vgui.Create( "PA_Function_Button", self )
		self.button_help:SetSize(60, 20)
		self.button_help:SetPos(CPanel_Width - self.button_help:GetWide(), 2)
		self.button_help:SetText( "Help" )
		self.button_help:SetToolTip( "Open online help using the Steam in-game browser" )
		self.button_help:SetFunction( function()
			return gui.OpenURL( "https://sourceforge.net/userapps/mediawiki/wenli/index.php?title=Precision_Alignment" )
		end )
end

function TOOL_OPTIONS:PerformLayout()
	self:SetSize(CPanel_Width, 100)
end

function TOOL_OPTIONS:Paint(w,h)
end

vgui.Register("PA_CPanel_tool_options", TOOL_OPTIONS, "DPanel")
 

//********************************************************************************************************************//
// CPanel Layout
//********************************************************************************************************************//

CPanel:Clear()

local tool_list = vgui.Create( "PA_CPanel_tool_list" )
CPanel:AddItem( tool_list )
CPanel.tool_list = tool_list

local tool_options = vgui.Create( "PA_CPanel_tool_options" )
CPanel:AddItem( tool_options )
CPanel.tool_options = tool_options

local point_window = vgui.Create( "PA_Tool_Point_Panel" )
CPanel:AddItem( point_window )
CPanel.point_window = point_window

local line_window = vgui.Create( "PA_Tool_Line_Panel" )
CPanel:AddItem( line_window )
CPanel.line_window = line_window

local plane_window = vgui.Create( "PA_Tool_Plane_Panel" )
CPanel:AddItem( plane_window )
CPanel.plane_window = plane_window

//********************************************************************************************************************//
// Usermessages
//********************************************************************************************************************//


local function select_next_point()
	if PA_selected_point < 9 then
		if PA_funcs.construct_exists( "Point", PA_selected_point ) then
			PA_selected_point = PA_selected_point + 1
			local dlist_points = controlpanel.Get( PA ).point_window.list_primarypoint
			dlist_points:ClearSelection()
			dlist_points:SelectItem( dlist_points:GetLine(PA_selected_point) )
			return true
		end
	end
	return false
end

local function select_next_line()
	if PA_selected_line < 9 then
		if PA_funcs.construct_exists( "Line", PA_selected_line ) then
			PA_selected_line = PA_selected_line + 1
			local dlist_lines = controlpanel.Get( PA ).line_window.list_line
			dlist_lines:ClearSelection()
			dlist_lines:SelectItem( dlist_lines:GetLine(PA_selected_line) )
			return true
		end
	end
	return false
end

local function select_next_plane()
	if PA_selected_plane < 9 then
		if PA_funcs.construct_exists( "Plane", PA_selected_plane ) then
			PA_selected_plane = PA_selected_plane + 1
			local dlist_planes = controlpanel.Get( PA ).plane_window.list_plane
			dlist_planes:ClearSelection()
			dlist_planes:SelectItem( dlist_planes:GetLine(PA_selected_plane) )
			return true
		end
	end
	return false
end

// Called when the server sends click data - used to add a new point/line
local function umsg_click_hook()
	local point = Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() )
	local normal = Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() )
	local ent = net.ReadEntity()
	
	local shift = LocalPlayer():KeyDown( IN_SPEED )
	local alt = LocalPlayer():KeyDown( IN_WALK )
	
	local tooltype = GetConVarNumber( PA_.. "tooltype" )
	
	// Points
	if tooltype <= 4 then
		if shift then
			select_next_point()
		end
		
		PA_funcs.set_point(PA_selected_point, point)
		// Auto-attach to selected ent
		if alt then
			if PA_activeent then
				PA_funcs.attach_point( PA_selected_point, PA_activeent )
			elseif precision_align_points[PA_selected_point].entity then
				PA_funcs.attach_point( PA_selected_point, nil )
			end
		elseif precision_align_points[PA_selected_point].entity ~= ent then
			PA_funcs.attach_point( PA_selected_point, ent )
		end
		
	// Lines
	elseif tooltype == 5 then
		if shift then
			select_next_line()
		end
		
		// Alt-click will place end point
		if alt then
			PA_funcs.set_line( PA_selected_line, nil, point, nil, nil )
		else
			PA_funcs.set_line( PA_selected_line, point, nil, nil, nil )
			
			// Only auto-attach by start point, not end point
			if PA_funcs.construct_exists( "Line", PA_selected_line ) and precision_align_lines[PA_selected_line].entity ~= ent then
				PA_funcs.attach_line( PA_selected_line, ent )
			end
		end	
	
	elseif tooltype == 6 then
		if shift then
			select_next_line()
		end
		
		PA_funcs.set_line( PA_selected_line, point, nil, normal, nil )
		if alt then
			if PA_activeent then
				PA_funcs.attach_line( PA_selected_line, PA_activeent )
			elseif precision_align_lines[PA_selected_line].entity then
				PA_funcs.attach_line( PA_selected_line, nil )
			end
		elseif precision_align_lines[PA_selected_line].entity ~= ent then
			PA_funcs.attach_line( PA_selected_line, ent )
		end
		
	elseif tooltype == 7 then
		PA_funcs.set_line( PA_selected_line, nil, nil, normal, nil )
		
	// Planes
	elseif tooltype == 8 then
		if shift then
			select_next_plane()
		end
		
		PA_funcs.set_plane( PA_selected_plane, point, normal )
		if alt then
			if PA_activeent then
				PA_funcs.attach_plane( PA_selected_plane, PA_activeent )
			elseif precision_align_planes[PA_selected_plane].entity then
				PA_funcs.attach_plane( PA_selected_plane, nil )
			end
		elseif precision_align_planes[PA_selected_plane].entity ~= ent then
			PA_funcs.attach_plane( PA_selected_plane, ent )
		end
		
	elseif tooltype == 9 then
		PA_funcs.set_plane( PA_selected_plane, nil, normal )
	end
end
net.Receive( PA_ .. "click", umsg_click_hook )

// Called when the server sends entity data - so the client knows which entity is selected
local function umsg_entity_hook()
	PA_activeent = net.ReadEntity()
end
net.Receive( PA_ .. "ent", umsg_entity_hook )


//********************************************************************************************************************//
// HUD Display
//********************************************************************************************************************//


// Construct draw sizes
local point_size_min = math.max( GetConVarNumber( PA_.."size_point" ), 1 )
local point_size_max = GetConVarNumber( PA_.."size_point" ) * 1000

local line_size_start = GetConVarNumber( PA_.."size_line_start" )
local line_size_min = GetConVarNumber( PA_.."size_line_end" )	-- End (double bar)
local line_size_max = line_size_min * 1000

local plane_size = GetConVarNumber( PA_.."size_plane" )
local plane_size_normal = GetConVarNumber( PA_.."size_plane_normal" )
local text_min, text_max = 1, 4500

local draw_attachments = LocalPlayer():GetInfo( PA_.."draw_attachments" )

cvars.AddChangeCallback( PA_.."size_point", function( CVar, Prev, New ) point_size_min = tonumber(math.max(New, 1)); point_size_max = tonumber(New) * 1000 end )
cvars.AddChangeCallback( PA_.."size_line_start",  function( CVar, Prev, New ) line_size_start = tonumber(New) end  )
cvars.AddChangeCallback( PA_.."size_line_end",  function( CVar, Prev, New ) line_size_min = tonumber(New); line_size_max  = line_size_min * 1000 end  )
cvars.AddChangeCallback( PA_.."size_plane", function( CVar, Prev, New ) plane_size = tonumber(New) end  )
cvars.AddChangeCallback( PA_.."size_plane_normal", function( CVar, Prev, New ) plane_size_normal = tonumber(New) end  )

// Manage attachment line colour changes
local H = GetConVarNumber( PA_.."attachcolour_h" )
local S = GetConVarNumber( PA_.."attachcolour_s" )
local V = GetConVarNumber( PA_.."attachcolour_v" )
local A = GetConVarNumber( PA_.."attachcolour_a" )
local attachcolourHSV = { h = H, s = S, v = V, a = A }
local attachcolourRGB = HSVToColor( H, S, V )
attachcolourRGB.a = A

local function SetAttachColour(CVar, Prev, New)
	if CVar == PA_.."attachcolour_h" then
		attachcolourHSV.h = New
	elseif CVar == PA_.."attachcolour_s" then
		attachcolourHSV.s = New
	elseif CVar == PA_.."attachcolour_v" then
		attachcolourHSV.v = New
	elseif CVar == PA_.."attachcolour_a" then
		attachcolourHSV.a = New
	end
	
	attachcolourRGB = HSVToColor( attachcolourHSV.h, attachcolourHSV.s, attachcolourHSV.v )
	attachcolourRGB.a = attachcolourHSV.a
end

cvars.AddChangeCallback( PA_.."attachcolour_h", SetAttachColour )
cvars.AddChangeCallback( PA_.."attachcolour_s", SetAttachColour )
cvars.AddChangeCallback( PA_.."attachcolour_v", SetAttachColour )
cvars.AddChangeCallback( PA_.."attachcolour_a", SetAttachColour )


local function inview( pos2D )
	if	pos2D.x > -ScrW() and
		pos2D.y > -ScrH() and
		pos2D.x < ScrW() * 2 and
		pos2D.y < ScrH() * 2 then
			return true
	end
	return false
end

// HUD draw function	
local function precision_align_draw( w, h)
	local playerpos = LocalPlayer():GetShootPos()
	
	// Points
	for k, v in ipairs (precision_align_points) do
		if v.visible and v.origin then
		
			//Check if point exists
			local point_temp = PA_funcs.point_global(k)
			if point_temp then
				local origin = point_temp.origin
				local point = origin:ToScreen()
				if inview( point ) then
					local distance = playerpos:Distance( origin )
					local size = math.Clamp( point_size_max / distance, point_size_min, point_size_max )
					local text_dist = math.Clamp(text_max / distance, text_min, text_max)
					
					surface.SetDrawColor( pointcolour.r, pointcolour.g, pointcolour.b, pointcolour.a )
					
					surface.DrawLine( point.x - size, point.y, point.x + size, point.y )
					surface.DrawLine( point.x, point.y + size, point.x, point.y - size )
					
					draw.DrawText( tostring(k), "Default", point.x + text_dist, point.y + text_dist/1.5, Color(pointcolour.r, pointcolour.g, pointcolour.b, pointcolour.a), 0 )
					
					// Draw attachment line
					if draw_attachments then
						if IsValid(v.entity) then
							local entpos = v.entity:GetPos():ToScreen()
							surface.SetDrawColor( attachcolourRGB.r, attachcolourRGB.g, attachcolourRGB.b, attachcolourRGB.a )
							surface.DrawLine( point.x, point.y, entpos.x, entpos.y )
						end
					end
				end
			end
		end
	end
	
	// Lines
	for k, v in ipairs (precision_align_lines) do
		if v.visible and v.startpoint and v.endpoint then
		
			//Check if line exists
			local line_temp = PA_funcs.line_global(k)
			if line_temp then
				local startpoint = line_temp.startpoint
				local endpoint = line_temp.endpoint
			
				local line_start = startpoint:ToScreen()
				local line_end = endpoint:ToScreen()
				
				local distance1 = playerpos:Distance( startpoint )
				local distance2 = playerpos:Distance( endpoint )
				
				local size2 = math.Clamp(line_size_max / distance2, line_size_min, line_size_max)
				local text_dist = math.Clamp(text_max / distance1, text_min, text_max)
				
				surface.SetDrawColor( linecolour.r, linecolour.g, linecolour.b, linecolour.a )
				
				// Start X
				local normal = (endpoint - startpoint):GetNormal()
				local dir1, dir2
				
				if IsValid(v.entity) then
					local up = v.entity:GetUp()
					if normal:Dot(up) < 0.9 then
						dir1 = (normal:Cross(up)):GetNormal()
					else
						dir1 = (normal:Cross(v.entity:GetForward())):GetNormal()
					end
				else
					if math.abs(normal.z) < 0.9 then
						dir1 = (normal:Cross(Vector(0,0,1))):GetNormal()
					else
						dir1 = (normal:Cross(Vector(1,0,0))):GetNormal()
					end
				end
				
				dir2 = (dir1:Cross(normal)):GetNormal() * line_size_start
				dir1 = dir1 * line_size_start
				
				local v1 = (startpoint + dir1 + dir2):ToScreen()
				local v2 = (startpoint - dir1 + dir2):ToScreen()
				local v3 = (startpoint - dir1 - dir2):ToScreen()
				local v4 = (startpoint + dir1 - dir2):ToScreen()
				
				// Start X
				if inview( line_start ) then
					surface.DrawLine(v1.x, v1.y, v3.x, v3.y)
					surface.DrawLine(v2.x, v2.y, v4.x, v4.y)
				end
				
				// Line
				surface.DrawLine( line_start.x, line_start.y, line_end.x, line_end.y )
				
				// End =
				if inview( line_end ) then
					local line_dir_2D = Vector(line_end.x - line_start.x, line_end.y - line_start.y, 0):GetNormalized()
					local norm_dir_2D = {x = -line_dir_2D.y, y = line_dir_2D.x}
					surface.DrawLine( line_end.x - norm_dir_2D.x * size2, line_end.y - norm_dir_2D.y * size2,
									  line_end.x + norm_dir_2D.x * size2, line_end.y + norm_dir_2D.y * size2 )
					surface.DrawLine( line_end.x + (line_dir_2D.x/3 - norm_dir_2D.x) * size2, line_end.y + (line_dir_2D.y/3 - norm_dir_2D.y) * size2,
									  line_end.x + (line_dir_2D.x/3 + norm_dir_2D.x) * size2, line_end.y + (line_dir_2D.y/3 + norm_dir_2D.y) * size2 )
				end
				
				draw.DrawText( tostring(k), "Default", line_start.x + text_dist, line_start.y - text_dist/1.5 - 15, Color(linecolour.r, linecolour.g, linecolour.b, linecolour.a), 3 )

				// Draw attachment line
				if draw_attachments then
					if IsValid(v.entity) then
						local entpos = v.entity:GetPos():ToScreen()
						surface.SetDrawColor( attachcolourRGB.r, attachcolourRGB.g, attachcolourRGB.b, attachcolourRGB.a )
						surface.DrawLine( line_start.x, line_start.y, entpos.x, entpos.y )
					end
				end
			end
		end
	end
	
	// Planes
	for k, v in ipairs (precision_align_planes) do
		if v.visible and v.origin and v.normal then
		
			//Check if plane exists
			local plane_temp = PA_funcs.plane_global(k)
			if plane_temp then
			
				local origin = plane_temp.origin
				local normal = plane_temp.normal
			
				// Draw normal line
				local line_start = origin:ToScreen()
				if inview( line_start ) then
				
					local line_end = ( origin + normal * plane_size_normal ):ToScreen()
						
					local distance = playerpos:Distance( origin )
					local text_dist = math.Clamp(text_max / distance, text_min, text_max)
					
					surface.SetDrawColor( planecolour.r, planecolour.g, planecolour.b, planecolour.a )
					surface.DrawLine( line_start.x, line_start.y, line_end.x, line_end.y )
					
					// Draw plane surface
					local dir1, dir2
					if IsValid(v.entity) then
						local up = v.entity:GetUp()
						if math.abs(normal:Dot(up)) < 0.9 then
							dir1 = (normal:Cross(up)):GetNormal()
						else
							dir1 = (normal:Cross(v.entity:GetForward())):GetNormal()
						end
					else
						if math.abs(normal.z) < 0.9 then
							dir1 = (normal:Cross(Vector(0,0,1))):GetNormal()
						else
							dir1 = (normal:Cross(Vector(1,0,0))):GetNormal()
						end
					end
					
					dir2 = (dir1:Cross(normal)):GetNormal() * plane_size
					dir1 = dir1 * plane_size
					
					local v1 = (origin + dir1 + dir2):ToScreen()
					local v2 = (origin - dir1 + dir2):ToScreen()
					local v3 = (origin - dir1 - dir2):ToScreen()
					local v4 = (origin + dir1 - dir2):ToScreen()
					
					surface.DrawLine( v1.x, v1.y, v2.x, v2.y )
					surface.DrawLine( v2.x, v2.y, v3.x, v3.y )
					surface.DrawLine( v3.x, v3.y, v4.x, v4.y )
					surface.DrawLine( v4.x, v4.y, v1.x, v1.y )
					
					draw.DrawText( tostring(k), "Default", line_start.x - text_dist, line_start.y + text_dist/1.5, Color(planecolour.r, planecolour.g, planecolour.b, planecolour.a), 1 )
					//Default
					// Draw attachment line
					if draw_attachments then
						if IsValid(v.entity) then
							local entpos = v.entity:GetPos():ToScreen()
							surface.SetDrawColor( attachcolourRGB.r, attachcolourRGB.g, attachcolourRGB.b, attachcolourRGB.a )
							surface.DrawLine( line_start.x, line_start.y, entpos.x, entpos.y )
						end
					end
				end
			end
		end
	end
end
hook.Add("HUDPaint", "draw_precision_align", precision_align_draw)


local function precision_align_displayhud_func( ply, cmd, args )
	local enabled = tobool( args[1] )
	if !enabled then
		hook.Remove( "HUDPaint", "draw_precision_align" )
	else 
		hook.Add("HUDPaint", "draw_precision_align", precision_align_draw)
	end
	return true
end
concommand.Add( PA_.."displayhud", precision_align_displayhud_func )

PA_manipulation_panel = vgui.Create( "PA_Manipulation_Frame" )
PA_manipulation_panel:SetVisible(false)

local function precision_align_open_panel_func( ply, cmd, args )
	if !PA_manipulation_panel then
		local PA_manipulation_panel = vgui.Create( "PA_Manipulation_Frame" )
	else
		if PA_manipulation_panel:IsVisible() then
			RememberCursorPosition()
			PA_manipulation_panel:SetVisible(false)
		else
			PA_manipulation_panel:SetVisible(true)
			RestoreCursorPosition()
		end
	end
end
concommand.Add( PA_.."open_panel", precision_align_open_panel_func ) /*