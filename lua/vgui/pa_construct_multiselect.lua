local BGColor_Point      = PrecisionAlign.TOOLMODE_BACKGROUND_COLOR_POINT
local BGColor_Line       = PrecisionAlign.TOOLMODE_BACKGROUND_COLOR_LINE
local BGColor_Plane      = PrecisionAlign.TOOLMODE_BACKGROUND_COLOR_PLANE

local CONSTRUCT_MULTISELECT = {}
function CONSTRUCT_MULTISELECT:Init()
	self:SetSize(555, 215)

	self.colour_panel_1 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_1:SetPos(0, 0)
		self.colour_panel_1:SetSize(150, 215)
		self.colour_panel_1:SetColour( BGColor_Point )

	self.list_points = vgui.Create( "PA_Construct_ListView", self.colour_panel_1 )
		self.list_points:Text( "Points", PrecisionAlign.CONSTRUCT_POINT, self.colour_panel_1 )
		self.list_points:SetTooltip( "Double click to deselect" )
		self.list_points:SetPos(20, 30)
		self.list_points:SetMultiSelect(true)
		self.list_points.DoDoubleClick = function()
			self.list_points:ClearSelection()
		end

	self.colour_panel_2 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_2:SetPos(150, 0)
		self.colour_panel_2:SetSize(150, 215)
		self.colour_panel_2:SetColour( BGColor_Line )

	self.list_lines = vgui.Create( "PA_Construct_ListView", self.colour_panel_2 )
		self.list_lines:Text( "Lines", PrecisionAlign.CONSTRUCT_LINE, self.colour_panel_2 )
		self.list_lines:SetTooltip( "Double click to deselect" )
		self.list_lines:SetPos(20, 30)
		self.list_lines:SetMultiSelect(true)
		self.list_lines.DoDoubleClick = function()
			self.list_lines:ClearSelection()
		end

	self.colour_panel_3 = vgui.Create( "PA_Colour_Panel", self )
		self.colour_panel_3:SetPos(300, 0)
		self.colour_panel_3:SetSize(150, 215)
		self.colour_panel_3:SetColour( BGColor_Plane )

	self.list_planes = vgui.Create( "PA_Construct_ListView", self.colour_panel_3 )
		self.list_planes:Text( "Planes", PrecisionAlign.CONSTRUCT_PLANE, self.colour_panel_3 )
		self.list_planes:SetTooltip( "Double click to deselect" )
		self.list_planes:SetPos(20, 30)
		self.list_planes:SetMultiSelect(true)
		self.list_planes.DoDoubleClick = function()
			self.list_planes:ClearSelection()
		end


	self.button_selectall = vgui.Create( "PA_Function_Button", self )
		self.button_selectall:SetPos(462, 30)
		self.button_selectall:SetSize(80, 30)
		self.button_selectall:SetText( "Select All" )
		self.button_selectall:SetTooltip( "Select all constructs" )
		self.button_selectall:SetFunction( function()
			self:SelectAll( true )
			return true
		end )

	self.button_deselectall = vgui.Create( "PA_Function_Button", self )
		self.button_deselectall:SetPos(462, 65)
		self.button_deselectall:SetSize(80, 30)
		self.button_deselectall:SetText( "Deselect All" )
		self.button_deselectall:SetTooltip( "Deselect all constructs" )
		self.button_deselectall:SetFunction( function()
			self:SelectAll( false )
			return true
		end )

	self.button_attach = vgui.Create( "PA_Function_Button", self )
		self.button_attach:SetPos(462, 100)
		self.button_attach:SetSize(80, 30)
		self.button_attach:SetText( "Attach" )
		self.button_attach:SetTooltip( "Attach constructs to the selected entity (detach if no ent selected)" )
		self.button_attach:SetFunction( function()
			local ID

			for _, v in pairs( self.list_points:GetSelected() ) do
				ID = v:GetID()
				if PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_POINT, ID ) then
					PrecisionAlign.Functions.attach_point( ID, PrecisionAlign.ActiveEnt )
				end
			end

			for _, v in pairs( self.list_lines:GetSelected() ) do
				ID = v:GetID()
				if PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_LINE, ID ) then
					PrecisionAlign.Functions.attach_line( ID, PrecisionAlign.ActiveEnt )
				end
			end

			for _, v in pairs( self.list_planes:GetSelected() ) do
				ID = v:GetID()
				if PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_PLANE, ID ) then
					PrecisionAlign.Functions.attach_plane( ID, PrecisionAlign.ActiveEnt )
				end
			end

			return true
		end )

	self.button_delete = vgui.Create( "PA_Function_Button", self )
		self.button_delete:SetPos(462, 135)
		self.button_delete:SetSize(80, 30)
		self.button_delete:SetText( "Delete" )
		self.button_delete:SetTooltip( "Delete the selected constructs" )
		self.button_delete:SetFunction( function()
			local ID

			for _, v in pairs( self.list_points:GetSelected() ) do
				ID = v:GetID()
				PrecisionAlign.Functions.delete_point( ID )
			end

			for _, v in pairs( self.list_lines:GetSelected() ) do
				ID = v:GetID()
				PrecisionAlign.Functions.delete_line( ID )
			end

			for _, v in pairs( self.list_planes:GetSelected() ) do
				ID = v:GetID()
				PrecisionAlign.Functions.delete_plane( ID )
			end

			return true
		end )

	self.button_deleteall = vgui.Create( "PA_Function_Button", self )
		self.button_deleteall:SetPos(462, 170)
		self.button_deleteall:SetSize(80, 30)
		self.button_deleteall:SetText( "Delete All" )
		self.button_deleteall:SetTooltip( "Delete all existing constructs" )
		self.button_deleteall:SetFunction( function()

			PrecisionAlign.Functions.delete_points()
			PrecisionAlign.Functions.delete_lines()
			PrecisionAlign.Functions.delete_planes()

			return true
		end )
end

function CONSTRUCT_MULTISELECT:SelectAll( value )
	local function SelectLines( panel, construct_table )
		for id = 1, PrecisionAlign.MAX_CONSTRUCTS do
			local line = panel.Sorted[ id ]
			line:SetSelected( value )
			if self.visibility then
				construct_table[id].visible = value
			end
		end
	end

	SelectLines( self.list_points, PrecisionAlign.Points )
	SelectLines( self.list_lines, PrecisionAlign.Lines )
	SelectLines( self.list_planes, PrecisionAlign.Planes )
end

function CONSTRUCT_MULTISELECT:GetSelection()
	local selection = {}
	selection.points = {}
	selection.lines = {}
	selection.planes = {}

	for _, v in pairs( self.list_points:GetSelected() ) do
		local ID = v:GetID()
		if PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_POINT, ID  ) then
			table.insert( selection.points, ID )
		end
	end

	for _, v in pairs( self.list_lines:GetSelected() ) do
		local ID = v:GetID()
		if PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_LINE, ID  ) then
			table.insert( selection.lines, ID )
		end
	end

	for _, v in pairs( self.list_planes:GetSelected() ) do
		local ID = v:GetID()
		if PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_PLANE, ID  ) then
			table.insert( selection.planes, ID )
		end
	end

	if ( #selection.points + #selection.lines + #selection.planes ) == 0 then
		selection = nil
	end

	return selection
end

function CONSTRUCT_MULTISELECT:Paint()
end

vgui.Register("PA_Construct_Multiselect", CONSTRUCT_MULTISELECT, "DPanel")