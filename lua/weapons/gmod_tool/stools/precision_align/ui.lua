if SERVER then return end

local PA = "precision_align"
local PA_ = PA .. "_"

PrecisionAlign.SelectedPoint = 1
PrecisionAlign.SelectedLine = 1
PrecisionAlign.SelectedPlane = 1

PrecisionAlign.ActiveEnt = nil

include("weapons/gmod_tool/stools/" .. PA .. "/manipulation_panel.lua")

local tooltypeCvar = GetConVar( PA_ .. "toolname" )

local CPanel = controlpanel.Get(PA)
local Warning = PrecisionAlign.Warning

do
    local PA_CPanel_tool_list = {}

    function PA_CPanel_tool_list:AddLine(ToolMode)
        local Line = self:Add("PA_ToolModeSelector")
        Line:SetMode(ToolMode)
        Line:Dock(TOP)
        Line:SetSize(0, 18)
        if tooltypeCvar:GetString() == ToolMode then
            Line:SelectNode()
        end
        return Line
    end

    function PA_CPanel_tool_list:Init()
        local H = 0
        for ToolMode in PrecisionAlign.GetToolModes() do
            local Line = self:AddLine(ToolMode)
            H = H + Line:GetTall()
        end

        self:SetSize(0, H)
    end

    function PA_CPanel_tool_list:GetSelectedNode()
        return self.SelectedNode
    end

    function PA_CPanel_tool_list:SetSelectedNode(Node)
        self.SelectedNode = Node
    end

    vgui.Register("PA_CPanel_tool_list", PA_CPanel_tool_list, "DPanel")
end

local PA_manipulation_panel = false
local function precision_align_open_panel_func(visible)
    if not PA_manipulation_panel then
        PA_manipulation_panel = vgui.Create( "PA_Manipulation_Frame" )
        if visible ~= false then
            visible = true
        end
    end
    if type(visible) ~= "boolean" then
        visible = not PA_manipulation_panel:IsVisible()
    end
    if visible then
        PA_manipulation_panel:SetVisible(true)
        PA_manipulation_panel:MakePopup() -- Focus the panel, RequestFocus wasn't working for me
        RestoreCursorPosition()
    else
        RememberCursorPosition()
        PA_manipulation_panel:SetVisible(false)
    end
end
concommand.Add( PA_ .. "open_panel", precision_align_open_panel_func )

-- Open a particular tab in the manipulation panel
local function OpenManipulationTab( tabName )
    precision_align_open_panel_func( true )
    local tab = PA_manipulation_panel[tabName]
    PA_manipulation_panel.panel:SetActiveTab( tab.tab )

    return tab
end

-- Perform double click function on a listview within the manipulation panel
local function ListView_DoDoubleClick( panel, lineID )
    panel:ClearSelection()

    local line = panel:GetLine( lineID )
    panel:SelectItem( line )
    panel:DoDoubleClick( line, lineID )
end

do
    local PA_ToolModeSelector = {}

    function PA_ToolModeSelector:SetMode(ToolMode)
        self.ToolMode = ToolMode
        local ToolModeObj = PrecisionAlign.ToolModes[ToolMode]
        if not ToolModeObj then return ErrorNoHalt("Couldn't set the mode!") end

        self.DrawColor                    = ToolModeObj:GetBackgroundColor():Copy()
        self.DrawColor:AddBrightness(0.08) -- To adjust for the default skin

        self.SelectedDrawColor            = self.DrawColor:Copy()
        self.SelectedHighlightedDrawColor = self.DrawColor:Copy()
        self.HighlightDrawColor           = self.DrawColor:Copy()
        self.DepressedDrawColor           = self.DrawColor:Copy()

        self.SelectedDrawColor:SetBrightness(0.95)
        self.SelectedHighlightedDrawColor:SetBrightness(1)
        self.HighlightDrawColor:SetBrightness(0.8)
        self.DepressedDrawColor:SetBrightness(0.5)

        self:SetText("")
    end

    function PA_ToolModeSelector:DoClick()
        self:SelectNode(self)
        self.SelectTime = RealTime()
        RunConsoleCommand( PA_ .. "toolname", self.ToolMode)
    end

    function PA_ToolModeSelector:IsSelectedNode()
        return self:GetParent():GetSelectedNode() == self
    end

    function PA_ToolModeSelector:SelectNode()
        self:GetParent():SetSelectedNode(self)
    end

    function PA_ToolModeSelector:Paint(width, height)
        local DrawColor
        local TextColor = color_black
        if self:IsSelectedNode() then
            if self.Hovered then
                if input.IsMouseDown(MOUSE_LEFT) then
                    DrawColor = self.DepressedDrawColor
                else
                    DrawColor = self.SelectedHighlightedDrawColor
                end
            else
                DrawColor = self.SelectedDrawColor
            end
            TextColor = color_white
            DrawColor = DrawColor:Copy()
            if not self.SelectTime then
                self.SelectTime = RealTime()
            end
            DrawColor:AddBrightness(math.Remap(math.cos((RealTime() - self.SelectTime) * 6), -1, 1, 0, -0.2))
        elseif input.IsMouseDown(MOUSE_LEFT) and self.Hovered then
            DrawColor = self.DepressedDrawColor
        elseif self.Hovered then
            DrawColor = self.HighlightDrawColor
        else
            DrawColor = self.DrawColor
        end

        self:GetSkin().tex.Button(0, 0, width, height, DrawColor)

        draw.SimpleText(self.ToolMode or "UNKNOWN", "DermaDefault", 4, height / 2, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    vgui.Register("PA_ToolModeSelector", PA_ToolModeSelector, "DButton")
end

do
    local PA_ConstructList = {}

    function PA_ConstructList:Init()
        self:AddColumn("")
        self:SetHideHeaders(true)
        self:SetMultiSelect(false)
    end

    function PA_ConstructList:Setup(Construct, Click, DbClick)
        self.construct_type = Construct
        local Name = PrecisionAlign.GetConstructName(Construct)
        for I = 1, 9 do
            local Line = self:AddLine(Name .. " " .. I)
            Line.Indicator = Line:Add "PA_Indicator"
        end

        if Click then
            self.OnRowSelected = function(_, Line) Click(Line) end
        end

        if DbClick then
            self.DoDoubleClick = function(_, Line) DbClick(Line) end
        end

        self:SelectFirstItem()
    end

    vgui.Register("PA_ConstructList", PA_ConstructList, "DListView")
end

do
    local PA_ConstructSelectionPanel = {}

    function PA_ConstructSelectionPanel:PerformLayout(w, h)
        if not IsValid(self.Left) then return end

        local Padding = 4
        if IsValid(self.Right) then
            self.Left:SetPos(Padding, Padding)
            self.Left:SetSize((w / 2) - Padding, h - (Padding * 2))

            self.Right:SetPos(Padding + (w / 2), Padding)
            self.Right:SetSize((w / 2) - Padding, h - (Padding * 2))
        else
            self.Left:SetPos(Padding, Padding)
            self.Left:SetSize(w - (Padding * 2), h - (Padding * 2))
        end
    end

    function PA_ConstructSelectionPanel:Setup(Construct, LeftClick, LeftDbClick, RightClick, RightDbClick)
        self.Left = self:Add("PA_ConstructList")
        self.Left:Setup(Construct, LeftClick, LeftDbClick)
        if RightClick and RightDbClick then
            self.Right = self:Add("PA_ConstructList")
            self.Right:Setup(Construct, RightClick, RightDbClick)
        end

        return self.Left, self.Right
    end

    vgui.Register("PA_ConstructSelectionPanel", PA_ConstructSelectionPanel, "DPanel")
end

do
    local PA_ButtonFlex = {}

    function PA_ButtonFlex:Init()
        self:SetPaintBackground(false)
    end

    function PA_ButtonFlex:PerformLayout(w, h)
        local Children = self:GetChildren()
        local ChildrenCount = #Children
        local Padding = 2
        for I, Child in ipairs(Children) do
            local X = Padding + math.Remap(I, 1, ChildrenCount + 1, 0, w)
            Child:SetPos(X, Padding)
            Child:SetSize((w - (Padding * 2)) / ChildrenCount, h - Padding)
        end
    end

    vgui.Register("PA_ButtonFlex", PA_ButtonFlex, "DPanel")
end

do
    local PA_Tool_Construct_Panel = {}
    function PA_Tool_Construct_Panel:SetConstructType(Construct)
        self.Header.Text = string.upper(PrecisionAlign.GetConstructName(Construct)) .. ""
        self.Header.Color = (Construct and PrecisionAlign.GetConstructColor(Construct) or color_black)
        self.Construct = Construct
    end

    function PA_Tool_Construct_Panel:SetTextColor(Text, Color)
        self.Header.Text = Text
        self.Header.Color = Color
    end

    function PA_Tool_Construct_Panel:SetSelectionMode(LeftClick, LeftDbClick, RightClick, RightDbClick)
        if IsValid(self.Selection) then self.Selection:Remove() end
        self.Selection = self:Add("PA_ConstructSelectionPanel")
        self.Selection:Dock(FILL)
        return self.Selection:Setup(self.Construct, LeftClick, LeftDbClick, RightClick, RightDbClick)
    end

    function PA_Tool_Construct_Panel:AddButtons(CanMoveEntity)
        local text = string.lower(PrecisionAlign.GetConstructName(self.Construct))

        local MoveBtn
        if CanMoveEntity then
            local MoveBtnContainer = self:Add("PA_ButtonFlex")
            MoveBtnContainer:Dock(BOTTOM)
            MoveBtnContainer:SetSize(0, 20)

            MoveBtn = MoveBtnContainer:Add("PA_Move_Button")
            MoveBtn:SetText("Move Entity")
        end

        local Attach_DeleteAll = self:Add("PA_ButtonFlex")
        Attach_DeleteAll:Dock(BOTTOM)
        Attach_DeleteAll:SetSize(0, 20)

        local AttachBtn    = Attach_DeleteAll:Add("PA_Function_Button")
        AttachBtn:SetText("Attach")
        AttachBtn:SetTooltip("Attach " .. text .. " to selected entity (detach if no ent selected)")

        local DeleteAllBtn = Attach_DeleteAll:Add("PA_Function_Button")
        DeleteAllBtn:SetText("Delete All")
        DeleteAllBtn:SetTooltip("Delete all " .. text .. "s")

        local View_Delete = self:Add("PA_ButtonFlex")
        View_Delete:Dock(BOTTOM)
        View_Delete:SetSize(0, 20)

        local ViewBtn   = View_Delete:Add("PA_Function_Button")
        ViewBtn:SetText("View")
        ViewBtn:SetTooltip("View the selected " .. text)

        local DeleteBtn = View_Delete:Add("PA_Function_Button")
        DeleteBtn:SetTooltip("Delete the selected " .. text)
        DeleteBtn:SetText("Delete")

        return ViewBtn, DeleteBtn, AttachBtn, DeleteAllBtn, MoveBtn
    end

    function PA_Tool_Construct_Panel:Init()
        self:Dock(TOP)
        self:SetSize(0, 170)
        self.Header = self:Add("DButton")
        self.Header:Dock(TOP)
        self.Header:SetSize(0, 14)
        self.Header:SetText("")
        self.Header.DefaultColor = color_black
        self.Header.Paint = self.PaintButton
    end

    function PA_Tool_Construct_Panel:Paint()

    end

    function PA_Tool_Construct_Panel:PaintButton(w, h)
        local BackColor =  (self.Color or color_black):Copy()
        if self.Hovered then
            if input.IsMouseDown(MOUSE_LEFT) then
                BackColor:AddBrightness(-0.2)
                BackColor:AddSaturation(0.14)
            else
                BackColor:AddBrightness(0.1)
                BackColor:AddSaturation(0.1)
            end
        end

        local drawBack = w - 140
        draw.RoundedBox(6, w / 2 - (drawBack / 2), 0, drawBack, h, BackColor)
        draw.SimpleText(self.Text or "INVALID", "Default", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    vgui.Register("PA_Tool_Construct_Panel", PA_Tool_Construct_Panel, "DPanel")
end

-- These hooks allow the slider text boxes to steal keyboard focus
local function TextFocusOn( pnl )
    if	pnl:GetClassName() == "TextEntry" and pnl.Type == "PA" then
        PA_manipulation_panel:SetKeyboardInputEnabled( true )
    end
end
hook.Add( "OnTextEntryGetFocus", "PAKeyboardFocusOn", TextFocusOn )

local function TextFocusOff( pnl )
    if pnl:GetClassName() == "TextEntry" and pnl.Type == "PA" then
        PA_manipulation_panel:SetKeyboardInputEnabled( false )
    end
end
hook.Add( "OnTextEntryLoseFocus", "PAKeyboardFocusOff", TextFocusOff )


-- Set up the full UI.
do
    CPanel:Clear()

    local ToolList = vgui.Create "PA_CPanel_tool_list"
    CPanel:AddItem(ToolList)
    CPanel.ToolList = ToolList

    local CheckboxHelpContainer = vgui.Create "DPanel"
    CPanel:AddItem(CheckboxHelpContainer)
    CheckboxHelpContainer:SetPaintBackground(false)
    CheckboxHelpContainer:Dock(TOP)
    CheckboxHelpContainer:SetSize(0, 54)

    local HelpContainer = CheckboxHelpContainer:Add("DPanel")

    HelpContainer:SetPaintBackground(false)
    HelpContainer:Dock(RIGHT)
    HelpContainer:SetSize(64, 0)

    local Help = HelpContainer:Add("DButton")
    Help:SetText("Help")
    Help:Dock(TOP)

    local Checkboxes = CheckboxHelpContainer:Add("DPanel")

    Checkboxes:SetPaintBackground(false)
    Checkboxes:Dock(FILL)

    local EnableConstructDisplays = Checkboxes:Add("DCheckBoxLabel")
    EnableConstructDisplays:Dock(TOP)
    EnableConstructDisplays:SetDark(true)
    EnableConstructDisplays:SetText("Enable Construct Displays")
    EnableConstructDisplays:SetValue(1)
    EnableConstructDisplays:SetTooltip("Show/Hide all constructs")
    EnableConstructDisplays:DockMargin(0, 0, 0, 4)
    function EnableConstructDisplays:OnChange(checked)
        LocalPlayer():ConCommand(PA_ .. "displayhud " .. (checked and "1" or "0"))
    end

    local SnapToEdges = Checkboxes:Add("DCheckBoxLabel")
    SnapToEdges:Dock(TOP)
    SnapToEdges:SetDark(true)
    SnapToEdges:SetText("Snap to Edges")
    SnapToEdges:SetTooltip("Snap to the edges of props when placing constructs")
    SnapToEdges:SetConVar(PA_ .. "edge_snap")
    SnapToEdges:DockMargin(0, 0, 0, 4)

    local SnapToCentreLines = Checkboxes:Add("DCheckBoxLabel")
    SnapToCentreLines:Dock(TOP)
    SnapToCentreLines:SetDark(true)
    SnapToCentreLines:SetText("Snap to Centre Lines")
    SnapToCentreLines:SetTooltip("Snap to the centre-lines of props when placing constructs")
    SnapToCentreLines:SetConVar(PA_ .. "centre_snap")
    SnapToCentreLines:DockMargin(0, 0, 0, 4)

    local SnapSensitivity = vgui.Create "DNumSlider"
    CPanel:AddItem(SnapSensitivity)
    SnapSensitivity:Dock(TOP)
    SnapSensitivity:SetDark(true)
    SnapSensitivity:SetText("Snap Sensitivity")
    SnapSensitivity:SetMinMax(0.1, 100)
    SnapSensitivity:SetDecimals(1)
    SnapSensitivity:SetSize(0, 24)
    SnapSensitivity.Slider:SetNotches(SnapSensitivity.Slider:GetWide() / 4)
    SnapSensitivity:SetTooltip("Sets the maximum distance for edge/centre snap detection (in units)")
    SnapSensitivity:SetConVar(PA_ .. "snap_distance")

    local Points = vgui.Create("PA_Tool_Construct_Panel")
    CPanel.point_window = Points
    CPanel:AddItem(Points)
    Points:SetConstructType(PrecisionAlign.CONSTRUCT_POINT)

    local function SelectPoint(ID) PrecisionAlign.SelectedPoint = ID end
    local function SelectPoint2() end
    local function PointDbClick(ID)
        local panel = OpenManipulationTab("points_tab")
        ListView_DoDoubleClick(panel.list_primarypoint, ID)
    end
    local function Point2DbClick(ID)
        local panel = OpenManipulationTab("points_tab")
        ListView_DoDoubleClick(panel.list_secondarypoint, ID)
    end
    Points.list_primarypoint, Points.list_secondarypoint = Points:SetSelectionMode(SelectPoint, PointDbClick, SelectPoint2, Point2DbClick) -- Assignment for backwards compat
    do
        local View, Delete, Attach, DeleteAll, MoveEntity = Points:AddButtons(true)
        View:SetFunction(function()
            if not PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_POINT, PrecisionAlign.SelectedPoint ) then return false end
            local point = PrecisionAlign.Functions.point_global( PrecisionAlign.SelectedPoint )
            return PrecisionAlign.Functions.set_playerview( point.origin )
        end)

        Delete:SetFunction(function()
            return PrecisionAlign.Functions.delete_point( PrecisionAlign.SelectedPoint )
        end)

        Attach:SetFunction(function()
            return PrecisionAlign.Functions.attach_point( PrecisionAlign.SelectedPoint, PrecisionAlign.ActiveEnt )
        end)

        DeleteAll:SetFunction(function()
            Points.list_primarypoint:SelectFirstItem()
            Points.list_secondarypoint:SelectFirstItem()
            return PrecisionAlign.Functions.delete_points()
        end)

        MoveEntity:SetTooltip("Move entity by Primary -> Secondary point")
        MoveEntity:SetFunction(function()
            PrecisionAlign.SelectedPoint2 = Points.list_secondarypoint:GetSelectedLine()
            if PrecisionAlign.SelectedPoint == PrecisionAlign.SelectedPoint2 then
                Warning("Cannot move between the same point!")
                return false
            end

            local point1 = PrecisionAlign.Functions.point_global( PrecisionAlign.SelectedPoint )
            local point2 = PrecisionAlign.Functions.point_global( PrecisionAlign.SelectedPoint2 )

            if not point1 or not point2 then
                Warning("Points not correctly defined")
                return false
            end

            if not PrecisionAlign.Functions.move_entity(point1.origin, point2.origin, PrecisionAlign.ActiveEnt) then return false end
        end)

        local AnimStart
        local function DrawMoveEntity()
            local FirstPoint  = Points.list_primarypoint:GetSelectedLine()
            local SecondPoint = Points.list_secondarypoint:GetSelectedLine()
            if FirstPoint == SecondPoint then return end

            local Point1 = PrecisionAlign.Functions.point_global(FirstPoint)
            local Point2 = PrecisionAlign.Functions.point_global(SecondPoint)
            if not IsValid(PrecisionAlign.ActiveEnt) then return end
            if not Point1 then return end
            if not Point2 then return end

            local duration = 1
            local animTime = ((RealTime() - AnimStart) % duration) / duration

            local startPos = Point1.origin
            local endPos   = Point2.origin
            local offset   = LerpVector(math.ease.OutExpo(animTime), startPos, endPos) - startPos
            PrecisionAlign.ActiveEnt:SetRenderOrigin(PrecisionAlign.ActiveEnt:GetPos() + offset)
            PrecisionAlign.ActiveEnt:SetupBones()
            local Blend = render.GetBlend() render.SetBlend(math.ease.InCubic(1 - animTime) / 2)
            PrecisionAlign.ActiveEnt:DrawModel()
            PrecisionAlign.ActiveEnt:SetRenderOrigin(nil)
            PrecisionAlign.ActiveEnt:SetupBones()
            render.SetBlend(Blend)
        end
        MoveEntity:SetHoverFunction(function() end, function(_, Time)
            AnimStart = Time
            hook.Add("PostDrawTranslucentRenderables", MoveEntity, DrawMoveEntity)
        end, function()
            hook.Remove("PostDrawTranslucentRenderables", MoveEntity)
        end)
    end
    local Lines  = vgui.Create("PA_Tool_Construct_Panel")
    CPanel.line_window = Lines
    CPanel:AddItem(Lines)
    Lines:SetConstructType(PrecisionAlign.CONSTRUCT_LINE)

    local function SelectLine(ID) PrecisionAlign.SelectedLine = ID end
    local function LineDbClick(ID)
        local panel = OpenManipulationTab("lines_tab")
        ListView_DoDoubleClick(panel.list_primary, ID)
    end
    Lines.list_line = Lines:SetSelectionMode(SelectLine, LineDbClick) -- Assignment for backwards compat
    do
        local View, Delete, Attach, DeleteAll, MoveEntity = Lines:AddButtons(true)
        View:SetFunction(function()
            if not PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_LINE, PrecisionAlign.SelectedLine ) then return false end
            local line = PrecisionAlign.Functions.line_global( PrecisionAlign.SelectedLine )
            return PrecisionAlign.Functions.set_playerview( line.startpoint )
        end)

        Delete:SetFunction(function()
            return PrecisionAlign.Functions.delete_line(PrecisionAlign.SelectedLine)
        end)

        Attach:SetFunction(function()
            return PrecisionAlign.Functions.attach_line(PrecisionAlign.SelectedLine, PrecisionAlign.ActiveEnt)
        end)

        DeleteAll:SetFunction(function()
            Lines.list_line:SelectFirstItem()
            return PrecisionAlign.Functions.delete_lines()
        end)

        MoveEntity:SetTooltip("Move entity by line")
        MoveEntity:SetFunction(function()
            local line = PrecisionAlign.Functions.line_global(PrecisionAlign.SelectedLine)
            if not line then
                Warning("Line not correctly defined")
                return false
            end

            local point1 = line.startpoint
            local point2 = line.endpoint
            if not PrecisionAlign.Functions.move_entity(point1, point2, PrecisionAlign.ActiveEnt) then return false end

            return true
        end)
    end

    local Planes = vgui.Create("PA_Tool_Construct_Panel")
    CPanel.plane_window = Planes
    CPanel:AddItem(Planes)
    Planes:SetConstructType(PrecisionAlign.CONSTRUCT_PLANE)

    local function SelectPlane(ID) PrecisionAlign.SelectedPlane = ID end
    local function PlaneDbClick(ID)
        local panel = OpenManipulationTab("planes_tab")
        ListView_DoDoubleClick(panel.list_primary, ID)
    end
    Planes.list_plane = Planes:SetSelectionMode(SelectPlane, PlaneDbClick) -- Assignment for backwards compat
    do
        local View, Delete, Attach, DeleteAll = Planes:AddButtons()

        View:SetFunction(function()
            if not PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_PLANE, PrecisionAlign.SelectedPlane ) then return false end
            local plane = PrecisionAlign.Functions.plane_global( PrecisionAlign.SelectedPlane )
            return PrecisionAlign.Functions.set_playerview( plane.origin )
        end)

        Delete:SetFunction(function()
            return PrecisionAlign.Functions.delete_plane(PrecisionAlign.SelectedPlane)
        end)

        Attach:SetFunction(function()
            return PrecisionAlign.Functions.attach_plane(PrecisionAlign.SelectedPlane, PrecisionAlign.ActiveEnt)
        end)

        DeleteAll:SetFunction(function()
            Planes.list_plane:SelectFirstItem()
            return PrecisionAlign.Functions.delete_planes()
        end)
    end
end

-- Networking
-- Called when the server sends click data - used to add a new point/line
local function umsg_click_hook()
    local point = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
    local normal = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
    local ent = net.ReadEntity()

    local shift = LocalPlayer():KeyDown(IN_SPEED)
    local alt = LocalPlayer():KeyDown(IN_WALK)

    local tooltype = tooltypeCvar:GetString()
    local ToolMode = PrecisionAlign.ToolModes[tooltype]

    ToolMode:OnClick(ent, point, normal, shift, alt)
end
net.Receive(PA_ .. "click", umsg_click_hook)

-- Called when the server sends entity data - so the client knows which entity is selected
local function umsg_entity_hook()
    PrecisionAlign.ActiveEnt = net.ReadEntity()
end
net.Receive(PA_ .. "ent", umsg_entity_hook)

include("weapons/gmod_tool/stools/" .. PA .. "/draw_hud.lua")