-- Primitives Tab. Lets the user pick a registered primitive shape and points to spawn it; warns if the "primitive" addon isn't loaded.
--********************************************************************************************************************

if SERVER then return end

local PA = "precision_align"
local PA_ = PA .. "_"

local BGColor_Point = PrecisionAlign.TOOLMODE_BACKGROUND_COLOR_POINT

local function AddMenuText( text, x, y, parent )
	local Text = vgui.Create( "DLabel", parent )
	Text:SetFont( "Default" )
	Text:SetText( text )
	Text:SizeToContents()
	Text:SetPos( x, y )
	return Text
end

local PRIMITIVES_TAB = {}
function PRIMITIVES_TAB:Init()
	self:CopyBounds( self:GetParent() )

	AddMenuText( "Points", 32, 9, self )

	self.colour_panel = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel:SetPos( 5, 31 )
		self.colour_panel:SetSize( 300, 404 )
		self.colour_panel:SetColour( BGColor_Point )

	self.list_points = vgui.Create( "PA_Construct_ListView", self.colour_panel )
		self.list_points:Text( "Points", PrecisionAlign.CONSTRUCT_POINT, self.colour_panel )
		self.list_points:SetTooltip( "Select the points required by the chosen primitive below" )
		self.list_points:SetPos( 20, 30 )
		self.list_points:SetMultiSelect( true )

	AddMenuText( "Primitive", 330, 9, self )

	self.text_requires_addon = vgui.Create( "DLabel", self )
		self.text_requires_addon:SetPos( 330, 30 )
		self.text_requires_addon:SetSize( 400, 60 )
		self.text_requires_addon:SetWrap( true )
		self.text_requires_addon:SetContentAlignment( 7 )
		self.text_requires_addon:SetText(
			"Requires the \"primitive\" addon.\n\n" ..
			PrecisionAlign.PRIMITIVE_GENERIC_DESCRIPTION
		)
		self.text_requires_addon:SetTextColor( self:GetSkin().Colours.Label.Dark )

	self.combo_primitive = vgui.Create( "DComboBox", self )
		self.combo_primitive:SetPos( 330, 94 )
		self.combo_primitive:SetSize( 191, 22 )
		self.combo_primitive:SetSortItems( false )

	self.text_description = vgui.Create( "DLabel", self )
		self.text_description:SetPos( 330, 126 )
		self.text_description:SetSize( 400, 220 )
		self.text_description:SetWrap( true )
		self.text_description:SetContentAlignment( 7 )
		self.text_description:SetTextColor( self:GetSkin().Colours.Label.Dark )

	for _, id in ipairs( PrecisionAlign.PRIMITIVE_ORDER ) do
		local data = PrecisionAlign.PRIMITIVE_TYPES[id]
		self.combo_primitive:AddChoice( data.label, id )
	end

	self.combo_primitive.OnSelect = function( _, _, _, id )
		local data = PrecisionAlign.PRIMITIVE_TYPES[id]
		self.selected_primitive = data

		local points_req = data.minPoints == data.maxPoints
			and ( data.minPoints .. " point" .. ( data.minPoints ~= 1 and "s" or "" ) )
			or ( data.minPoints .. "-" .. data.maxPoints .. " points" )

		local text = "Requires " .. points_req .. "."
		if data.description ~= "" then text = text .. "\n\n" .. data.description end

		self.text_description:SetText( text )
	end

	self.combo_primitive:ChooseOptionID( 1 )

	self.button_create = vgui.Create( "PA_Function_Button", self )
		self.button_create:SetPos( 330, 378 )
		self.button_create:SetSize( 191, 50 )
		self.button_create:SetText( "Create Primitive" )
		self.button_create:SetTooltip( "Spawn the selected primitive from the selected points" )
		self.button_create:SetFunction( function()
			local data = self.selected_primitive
			if not data then
				PrecisionAlign.Warning( "Select a primitive" )
				return false
			end

			local selected = self.list_points:GetSelectedSorted()

			local points = {}
			for _, v in ipairs( selected ) do
				local ID = v:GetID()
				if PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_POINT, ID ) then
					points[#points + 1] = PrecisionAlign.Functions.point_global( ID ).origin
				end
			end

			if #points < data.minPoints then
				PrecisionAlign.Warning( "Select at least " .. data.minPoints .. " defined points" )
				return false
			end

			if #points > data.maxPoints then
				PrecisionAlign.Warning( "Select at most " .. data.maxPoints .. " points" )
				return false
			end

			if not scripted_ents.GetStored( data.entity ) then
				PrecisionAlign.Warning( "The \"primitive\" addon is not installed" )
				return false
			end

			net.Start( PA_ .. "primitive" )
				net.WriteString( data.id )
				net.WriteUInt( #points, 8 )
				for i = 1, #points do
					net.WriteVector( points[i] )
				end
			net.SendToServer()

			return true
		end )
end

vgui.Register( "PA_Primitives_Tab", PRIMITIVES_TAB, "DPanel" )
