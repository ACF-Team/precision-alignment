-- Primitives Tab. Lets the user pick 4-10 PA points and spawn a
-- primitive_convex_hull entity (from the "primitive" addon) whose vertices are
-- those points. Soft dependency: if the primitive addon isn't loaded, the tab
-- still shows but the create button just warns instead of doing anything.
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

local MIN_POINTS = 4
local MAX_POINTS = 10

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
		self.list_points:SetTooltip( "Select 4-10 points to use as the convex hull's vertices" )
		self.list_points:SetPos( 20, 30 )
		self.list_points:SetMultiSelect( true )

	AddMenuText( "Primitive: Convex Hull", 330, 9, self )

	self.text_description = vgui.Create( "DLabel", self )
		self.text_description:SetPos( 330, 36 )
		self.text_description:SetSize( 400, 300 )
		self.text_description:SetWrap( true )
		self.text_description:SetContentAlignment( 7 )
		self.text_description:SetTextColor( self:GetSkin().Colours.Label.Dark )
		self.text_description:SetText(
			"Select 4 to 10 points, then hit Create.\n\n" ..
			"The physics engine builds the hull, so point order doesn't matter.\n\n" ..
			"Requires the \"primitive\" addon."
		)

	self.button_create = vgui.Create( "PA_Function_Button", self )
		self.button_create:SetPos( 330, 378 )
		self.button_create:SetSize( 191, 50 )
		self.button_create:SetText( "Create Primitive" )
		self.button_create:SetTooltip( "Spawn a convex hull from the selected points" )
		self.button_create:SetFunction( function()
			local selected = self.list_points:GetSelected()

			local points = {}
			for _, v in pairs( selected ) do
				local ID = v:GetID()
				if PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_POINT, ID ) then
					points[#points + 1] = PrecisionAlign.Functions.point_global( ID ).origin
				end
			end

			if #points < MIN_POINTS then
				Warning( "Select at least " .. MIN_POINTS .. " defined points" )
				return false
			end

			if #points > MAX_POINTS then
				Warning( "Select at most " .. MAX_POINTS .. " points" )
				return false
			end

			net.Start( PA_ .. "primitive" )
				net.WriteUInt( #points, 8 )
				for i = 1, #points do
					net.WriteVector( points[i] )
				end
			net.SendToServer()

			return true
		end )
end

vgui.Register( "PA_Primitives_Tab", PRIMITIVES_TAB, "DPanel" )
