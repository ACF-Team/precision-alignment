-- Instructions for the Precision Alignment storyboards: the tool's constructs (points, lines and planes)
-- and the entity operations its manipulation panel performs, drawn on Ponder's models.

-- The tool's own colours, brightened like its HUD does
local function KindColor(kind)
	local color = PrecisionAlign.GetConstructColor(PrecisionAlign["CONSTRUCT_" .. string.upper(kind)]):Copy()

	color:SetBrightness(0.98)
	color:SetSaturation(0.8)
	return color
end

local function Constructs(env)
	env.PAConstructs = env.PAConstructs or {}
	return env.PAConstructs
end

local function NewConstruct(name, kind, instruction)
	local Instruction = Ponder.API.NewInstruction(name)
	Instruction.Name   = ""
	Instruction.Label  = "" -- Drawn next to the construct, like its slot number
	Instruction.Length = 0
	function Instruction:First(playback)
		local construct = {Kind = kind, Label = self.Label}
		instruction(self, construct)
		Constructs(playback.Environment)[self.Name] = construct
	end
	return Instruction
end

local Point = NewConstruct("PAPoint", "Point", function(self, construct) construct.Position = self.Position end)
Point.Position = vector_origin

local Line = NewConstruct("PALine", "Line", function(self, construct) construct.Start, construct.End = self.Start, self.End end)
Line.Start = vector_origin
Line.End   = Vector(0, 0, 100)

local Plane = NewConstruct("PAPlane", "Plane", function(self, construct) construct.Origin, construct.Normal, construct.Size = self.Origin, self.Normal, self.Size end)
Plane.Origin = vector_origin
Plane.Normal = Vector(1, 0, 0)
Plane.Size   = 40 -- Half the width of the square

local Remove = Ponder.API.NewInstruction("PARemoveConstruct")
Remove.Name   = ""
Remove.Length = 0

function Remove:First(playback)
	Constructs(playback.Environment)[self.Name] = nil
end

-- Constructs attached to a prop follow it, so this slides a point to where the prop carries it
local MovePoint = Ponder.API.NewInstruction("PAMovePoint")
MovePoint.Name     = ""
MovePoint.Position = vector_origin
MovePoint.Length   = 1

function MovePoint:First(playback)
	local construct = Constructs(playback.Environment)[self.Name]
	self.From = construct and construct.Position
end

local function SlidePoint(self, playback, fraction)
	local construct = Constructs(playback.Environment)[self.Name]
	if construct and self.From then construct.Position = LerpVector(fraction, self.From, self.Position) end
end

function MovePoint:Update(playback) SlidePoint(self, playback, playback:GetInstructionProgress(self)) end
function MovePoint:Last(playback) SlidePoint(self, playback, 1) end

-- Reflects the named model across a plane like Mirror Across Plane does: its position and its facing both flip.
-- With Copy set, the original stays and a mirrored copy is made instead, like holding Shift does
local MirrorModel = Ponder.API.NewInstruction("PAMirrorModel")
MirrorModel.Target    = ""
MirrorModel.Origin    = vector_origin
MirrorModel.Normal    = Vector(1, 0, 0)
MirrorModel.Copy      = "" -- The name of the copy
MirrorModel.CopyColor = nil -- The copy's colour, which is the original's by default
MirrorModel.Length    = 0

local function Reflect(vec, normal) return vec - 2 * vec:Dot(normal) * normal end

function MirrorModel:First(playback)
	local env = playback.Environment
	local model = env:GetNamedModel(self.Target)
	if not IsValid(model) then return Ponder.Print("PAMirrorModel: no model " .. self.Target) end

	local normal = self.Normal:GetNormalized()
	local forward, up = Reflect(model:GetForward(), normal), Reflect(model:GetUp(), normal)
	local position, angles = self.Origin + Reflect(model:GetPos() - self.Origin, normal), forward:AngleEx(up)

	if self.Copy ~= "" then
		local color = self.CopyColor or model:GetColor()

		model = env:NewModel(model:GetModel(), self.Copy)
		model:SetColor(color)
		model:SetRenderMode(RENDERMODE_TRANSCOLOR)
	end

	model:SetPos(position)
	model:SetAngles(angles)
end

-- Turns the named model about a line through Pivot like Rotate Around Axis does
local RotateAround = Ponder.API.NewInstruction("PARotateModel")
RotateAround.Target  = ""
RotateAround.Pivot   = vector_origin
RotateAround.Axis    = Vector(0, 0, 1)
RotateAround.Degrees = 90
RotateAround.Length  = 1

function RotateAround:First(playback)
	local model = playback.Environment:GetNamedModel(self.Target)
	if not IsValid(model) then return Ponder.Print("PARotateModel: no model " .. self.Target) end

	self.Start = Matrix()
	self.Start:SetTranslation(model:GetPos())
	self.Start:SetAngles(model:GetAngles())
end

local function ApplyRotation(self, playback, fraction)
	local model = playback.Environment:GetNamedModel(self.Target)
	if not IsValid(model) or not self.Start then return end

	local turn = Angle()
	turn:RotateAroundAxis(self.Axis:GetNormalized(), self.Degrees * fraction)

	local matrix = Matrix()
	matrix:Translate(self.Pivot)
	matrix:Rotate(turn)
	matrix:Translate(-self.Pivot)
	matrix = matrix * self.Start

	model:SetPos(matrix:GetTranslation())
	model:SetAngles(matrix:GetAngles())
end

function RotateAround:Update(playback) ApplyRotation(self, playback, playback:GetInstructionProgress(self)) end
function RotateAround:Last(playback) ApplyRotation(self, playback, 1) end

-- The tool's own spawn menu. Its UI file builds into the global control panel, so that is pointed at a panel of ours while
-- it runs. The lists then read the storyboard's constructs instead of the viewer's, and the selected mode is set on the panel only.
local ToolMenu = Ponder.API.NewInstruction("PAToolMenu")
ToolMenu.Name   = ""
ToolMenu.Mode   = "Point - Hitpos"
ToolMenu.Length = 0.3

-- The first panel under parent that passes the check
local function FindChild(parent, check)
	for _, child in ipairs(parent:GetChildren()) do
		if check(child) then return child end

		local found = FindChild(child, check)
		if found then return found end
	end
end

-- Part of a panel an instruction applies to, like a tab, named by one of its fields. Nil is the whole panel
local function Scope(panel, within)
	return within and panel[within] or panel
end

-- A button in a panel: the one in a field of it, like button_axisrotate_entity, or else the first one showing the text
local function GetButton(menu, within, field, text)
	local scope = Scope(menu, within)
	return field and scope[field] or FindChild(scope, function(child) return child.GetText and child:GetText() == text end)
end

local function BuildMenu(panel)
	local PA = "precision_align"
	local real = controlpanel.Get
	local saved = {PrecisionAlign.SelectedPoint, PrecisionAlign.SelectedLine, PrecisionAlign.SelectedPlane, PrecisionAlign.ActiveEnt}

	controlpanel.Get = function(name) return name == PA and panel or real(name) end
	local ok, err = pcall(include, "weapons/gmod_tool/stools/" .. PA .. "/ui.lua")
	controlpanel.Get = real

	PrecisionAlign.SelectedPoint, PrecisionAlign.SelectedLine, PrecisionAlign.SelectedPlane, PrecisionAlign.ActiveEnt = unpack(saved, 1, 4)
	if not ok then return Ponder.Print("PAToolMenu: " .. tostring(err)) end
end

-- Cuts the menu off from the viewer's tool. Buttons like Move Entity turn on by themselves once a prop is selected, so they
-- start off here and PAMenuEnable turns them on. The lists' indicators light up for the storyboard's constructs instead of the viewer's
local function Detach(parent, env, mode)
	for _, child in ipairs(parent:GetChildren()) do
		if child.ClassName == "PA_Move_Button" then
			child.Think = function() end
			child:SetDisabled(true)
		elseif child.ClassName == "PA_Indicator" then
			function child:Paint(w, h)
				local line = self:GetParent()
				local kind = PrecisionAlign.GetConstructName(line:GetListView().construct_type)

				for _, construct in pairs(Constructs(env)) do
					if construct.Kind == kind and tonumber(construct.Label) == line:GetID() then
						draw.RoundedBox(6, 0, 0, w, h, Color(126, 255, 126))
					end
				end
			end
		end

		if child.m_strConVar then child.m_strConVar, child.Think, child.OnChange = nil, function() end, function() end end
		if child.ToolMode == mode then child:SelectNode() end

		Detach(child, env, mode)
	end
end

function ToolMenu:First(playback)
	local env = playback.Environment
	local panel = env:NewNamedObject("VGUIPanel", self.Name, "ControlPanel")

	panel:SetSize(300, ScrH() * 0.72)
	panel:SetPos(ScrW() * 0.8, ScrH() * 0.13)
	panel:SetMouseInputEnabled(false)
	panel:SetLabel("Precision Alignment")
	panel.PAMenu = true

	BuildMenu(panel)
	Detach(panel, env, self.Mode)
	panel:InvalidateLayout(true)
end

local function FadeIn(self, playback)
	playback.Environment:GetNamedObject("VGUIPanel", self.Name):SetAlpha(playback:GetInstructionProgress(self) * 255)
end

ToolMenu.Update = FadeIn

-- Highlights another mode in the menu's list, as if it had been picked. The viewer's own mode is not changed
local MenuMode = Ponder.API.NewInstruction("PAMenuMode")
MenuMode.Name   = ""
MenuMode.Mode   = ""
MenuMode.Length = 0

function MenuMode:First(playback)
	local menu = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
	local node = menu and FindChild(menu, function(child) return child.ToolMode == self.Mode end)
	if not node then return Ponder.Print("PAMenuMode: no mode " .. self.Mode) end

	node:SelectNode()
	node.SelectTime = RealTime()
end

-- Picks a row of a list in the menu, like Shift clicking does for the primary (left) point list. The tool keeps its
-- selected point in a global that the list's click handler writes, so it is put back afterwards
local MenuSelect = Ponder.API.NewInstruction("PAMenuSelect")
MenuSelect.Name   = ""
MenuSelect.Within = nil -- The part of the panel holding the list, like point_window or rotation_functions_tab
MenuSelect.List   = "" -- The list's field, like list_primarypoint
MenuSelect.Line   = 2 -- Or a table of rows, for lists that select several
MenuSelect.Length = 0

function MenuSelect:First(playback)
	local menu = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
	local list = Scope(menu, self.Within)[self.List]
	local selected = PrecisionAlign.SelectedPoint

	list:ClearSelection()
	for _, line in ipairs(istable(self.Line) and self.Line or {self.Line}) do list:SelectItem(list:GetLine(line)) end
	PrecisionAlign.SelectedPoint = selected
end

-- Sets a slider in the menu, like dragging it does, or picks the choice of a dropdown showing the value
local MenuValue = Ponder.API.NewInstruction("PAMenuValue")
MenuValue.Name   = ""
MenuValue.Within = nil
MenuValue.Field  = "" -- The slider's or dropdown's field, like slider_axisangle
MenuValue.Value  = 0
MenuValue.Length = 0

function MenuValue:First(playback)
	local field = Scope(playback.Environment:GetNamedObject("VGUIPanel", self.Name), self.Within)[self.Field]

	if field.ChooseOptionID then
		field:ChooseOptionID(table.KeyFromValue(field.Choices, self.Value))
	else
		field:SetValue(self.Value)
	end
end

-- Turns on a button the tool disables until a prop is selected
local MenuEnable = Ponder.API.NewInstruction("PAMenuEnable")
MenuEnable.Name   = ""
MenuEnable.Text   = "Move Entity"
MenuEnable.Within = nil
MenuEnable.Field  = nil
MenuEnable.Length = 0

function MenuEnable:First(playback)
	local menu = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
	GetButton(menu, self.Within, self.Field, self.Text):SetDisabled(false)
end

-- Pulses a button in the menu, then shows it pressed. Label is the text the button shows while held, like the
-- stacking text some buttons switch to when Shift is down. Activate also does what clicking a function button does
local MenuPress = Ponder.API.NewInstruction("PAMenuPress")
MenuPress.Name     = ""
MenuPress.Text     = "Move Entity"
MenuPress.Within   = nil
MenuPress.Field    = nil
MenuPress.Label    = nil
MenuPress.Activate = false
MenuPress.Length   = 1.2

function MenuPress:First(playback)
	local menu = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
	self.Button = GetButton(menu, self.Within, self.Field, self.Text)

	self.Button.PulseTime = 0
	if self.Label then self.Button:SetText(self.Label) end
	function self.Button:PaintOver(w, h)
		local time = self.PulseTime
		if not time then return end

		if time < 0.75 then
			surface.SetDrawColor(255, 210, 90, 255 * (0.5 - 0.5 * math.cos(time / 0.75 * math.pi * 4)))
			surface.DrawOutlinedRect(0, 0, w, h, 3)
		else
			surface.SetDrawColor(255, 255, 255, 90)
			surface.DrawRect(0, 0, w, h)
		end
	end
end

function MenuPress:Update(playback)
	if self.Button then self.Button.PulseTime = playback:GetInstructionProgress(self) * self.Length end
end

function MenuPress:Last()
	if not self.Button then return end

	self.Button.PulseTime = nil
	if self.Label then self.Button:SetText(self.Text) end
	if self.Activate then self.Button:OnMousePressed() end
end

-- The tool's manipulation panel, opened with Reload: the real panel on one of its tabs, named by a field of it like
-- rotation_tab, with the mouse and keyboard turned off. It is centred across the screen, low enough to leave room for captions and keys above it
local Manipulation = Ponder.API.NewInstruction("PAManipulationPanel")
Manipulation.Name   = ""
Manipulation.Tab    = "rotation_functions_tab"
Manipulation.Length = 0.3
Manipulation.Update = FadeIn

function Manipulation:First(playback)
	local env = playback.Environment
	local frame = env:NewNamedObject("VGUIPanel", self.Name, "PA_Manipulation_Frame")
	local tab = frame[self.Tab]

	frame:CenterHorizontal()
	frame:SetY(ScrH() * 0.33)
	frame:SetDraggable(false)
	frame:SetMouseInputEnabled(false)
	frame:SetKeyboardInputEnabled(false)
	frame:SetAlpha(0)
	frame.panel:SetFadeTime(0)
	frame.PAMenu = true

	for _, item in ipairs(frame.panel.Items) do
		if item.Panel == tab then frame.panel:SetActiveTab(item.Tab) end
	end

	Detach(tab, env, "")
end

-- Aims the toolgun at a position and presses a mouse button there. Held keys are shown beside it through the click
local Click = Ponder.API.NewInstructionMacro("PAClick")

function Click:Run(chapter, parameters)
	local keys = {}

	chapter:AddInstruction("MoveToolgunTo", {Position = Vector(90, -90, 90), Length = 0.45})
	chapter:AddDelay(0.525)
	for index, key in ipairs(parameters.Held or {}) do
		keys[index] = chapter:AddInstruction("KeyPress", {Name = "held" .. index, Key = key, Position = Vector(0.4, 0.27, 0)})
		chapter:AddDelay(keys[index].PressedAt)
	end
	chapter:AddDelay(chapter:AddInstruction("KeyPress", {Name = "key", Key = parameters.Button, Position = Vector(parameters.Held and 0.54 or 0.5, 0.27, 0)}).PressedAt)
	chapter:AddInstruction("ClickToolgun", {Position = parameters.Position, Length = 0.375})
	chapter:AddDelay(0.375)
	for _, key in ipairs(keys) do key:ReleaseAt(chapter.Time) end
end

local Renderer = Ponder.API.NewRenderer("PAConstructRenderer")

-- Seeking frees the environment and replays from the start of a chapter, so constructs from the old run have to go
function Renderer:Initialize(env)
	env.PAConstructs = nil
end

local function DrawPlane(origin, normal, size)
	local color = KindColor("Plane")
	local angles = normal:Angle()
	local right, up = angles:Right() * size, angles:Up() * size
	local a, b, c, d = origin - right - up, origin + right - up, origin + right + up, origin - right + up
	local fill = ColorAlpha(color, 70)

	render.SetColorMaterial()
	render.DrawQuad(a, b, c, d, fill)
	render.DrawQuad(d, c, b, a, fill)
	for _, edge in ipairs({{a, b}, {b, c}, {c, d}, {d, a}}) do render.DrawLine(edge[1], edge[2], color, true) end
	render.DrawLine(origin, origin + normal * size, color, true)
end

function Renderer:Render3D(env)
	for _, construct in pairs(Constructs(env)) do
		if construct.Kind == "Point" then
			construct.Screen = construct.Position:ToScreen()
		elseif construct.Kind == "Line" then
			local color = KindColor("Line")

			render.SetColorMaterial()
			render.DrawBeam(construct.Start, construct.End, 2, 0, 1, color)
			render.DrawSphere(construct.Start, 2.5, 12, 12, color)
			construct.Screen = construct.Start:ToScreen()
		else
			DrawPlane(construct.Origin, construct.Normal, construct.Size)
			construct.Screen = construct.Origin:ToScreen()
		end
	end
end

-- Constructs are drawn like the tool's HUD does: thick lines with a black border, and a number whose size and offset follow the distance
surface.CreateFont("PAPonder_GizmoFont", {font = "Arial", size = ScrW() / 60, weight = 900})

local function Setting(name) return GetConVar("precision_align_" .. name):GetFloat() end

local function DrawThickLine(x1, y1, x2, y2, thickness, color)
	local dx, dy = x2 - x1, y2 - y1
	local angle = -math.atan2(dy, dx)
	local center, direction = Vector((x1 + x2) / 2, (y1 + y2) / 2, 0), Vector(math.sin(angle), math.cos(angle), -thickness)

	render.SetColorMaterial()
	mesh.Begin(MATERIAL_QUADS, 1)
	mesh.QuadEasy(center, direction, math.sqrt(dx * dx + dy * dy) + thickness * 1.5, thickness, color)
	mesh.End()
end

local function DrawBorderedCross(x, y, size, thickness, color)
	local border = Setting("border_size")
	local lines = {{x - size, y, x + size, y}, {x, y + size, x, y - size}}

	if border > 0 then
		for _, line in ipairs(lines) do DrawThickLine(line[1], line[2], line[3], line[4], thickness + border, color_black) end
	end
	for _, line in ipairs(lines) do DrawThickLine(line[1], line[2], line[3], line[4], thickness, color) end
end

local function DrawNumber(distance, text, x, y, color)
	local textMax = 3500
	local dist = math.Clamp(distance * 9, 1, textMax)
	local scale = math.Round(math.Remap(dist, 1, textMax, 1, 0.5) * 50) / 50
	local offset = math.Clamp(textMax / distance, 1, textMax)
	local matrix = Matrix()

	matrix:Translate(Vector(math.Remap(dist, textMax, 1, x, x + offset), math.Remap(dist, textMax, 1, y, y + offset / 1.5), 0))
	matrix:Scale(Vector(scale, scale, 1))
	cam.PushModelMatrix(matrix)
		draw.SimpleTextOutlined(text, "PAPonder_GizmoFont", 0, 0, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT, Setting("border_size") >= 1 and 2 or 0, color_black)
	cam.PopModelMatrix()
end

function Renderer:Render2D(env)
	-- The tool's sizes assume a player's 90 degree view. The narrower view here makes props look as if they were that much closer
	local distance = env.CameraPosition and env.CameraPosition:Distance(env.LastLookat or vector_origin) or 1400
	distance = distance * math.tan(math.rad((env.CameraFOV or 90) / 2))

	for _, construct in pairs(Constructs(env)) do
		local screen = construct.Screen
		if screen and screen.visible then
			local color = KindColor(construct.Kind)

			if construct.Kind == "Point" then
				local size = math.Clamp(Setting("size_point") * 1000 / distance, math.max(Setting("size_point"), 1), Setting("size_point") * 1000)
				local thickness = math.Clamp(math.Remap(distance, 1, 3500, Setting("line_thickness"), 1), 1, Setting("line_thickness"))
				DrawBorderedCross(screen.x, screen.y, size, thickness, color)
			end

			if construct.Label ~= "" then DrawNumber(distance, construct.Label, screen.x, screen.y, color) end
		end
	end

	-- The tool's HUD is drawn under its menus. Renderers run in no set order, so the menus are painted again on top
	for _, panel in ipairs(env:GetAllNamedObjects("VGUIPanel")) do
		if IsValid(panel) and panel.PAMenu then panel:PaintManual(true) end
	end
end
