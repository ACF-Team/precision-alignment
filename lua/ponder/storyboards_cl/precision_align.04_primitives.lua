local sb = Ponder.API.NewStoryboard("precision_align", "tutorials", "primitives")
sb:WithMenuName("Primitives")
sb:WithPlaybackName("Primitives")
sb:WithModelIcon("models/hunter/blocks/cube2x2x1.mdl")
sb:WithDescription("Place points that fit a primitive shape, then create it.")
sb:SetPrimaryLanguage("en")
sb:WithIndexOrder(0) -- Ponder lists the highest first

local Half, Size, ToolPos = 23.725, 47.45, Vector(90, -90, 90)
local Floor = 40 - Half
local PadAng = Angle(0, 20, 0)
local Forward, Left, Up = PadAng:Forward(), -PadAng:Right(), Vector(0, 0, 1)
local PadPos = Vector(0, 0, Floor + 1.5)

-- A spot on top of the blue pad, from its centre along its edges
local function OnPad(x, y) return PadPos + Vector(0, 0, 1.5) + Forward * x + Left * y end

-- The orange post stands against the pad's right side and is as tall as the shape will be
local PostPos = OnPad(Size + Half, Size - Half) + Vector(0, 0, Half - 3)
-- Points 1 and 2 are the near edge of the pad, point 3 is its far corner, and point 4 is the top of the post
local P1, P2, P3 = OnPad(-Size, -Size), OnPad(Size, -Size), OnPad(-Size, Size)
local P4 = OnPad(Size, Size) + Vector(0, 0, 2 * Half - 3)

-- The cube the Primitives tab spawns: along the edge, across the plane and up to point 4.
-- It is inset a little so its faces do not flicker against the pad and the post.
-- Meshes are not lit here, so each face is shaded by how much it faces a light
local Shaded = CreateMaterial("PAPonder_Primitive", "UnlitGeneric", {["$basetexture"] = "color/white", ["$vertexcolor"] = 1})
local Light = Vector(0.4, -0.6, 1):GetNormalized()

local function Box(origin, x, y, z)
	local triangles = {}
	local function Face(a, b, c, d, normal)
		local shade = 255 * (0.45 + 0.55 * math.max(normal:Dot(Light), 0))
		if (b - a):Cross(c - a):Dot(normal) > 0 then a, b, c, d = d, c, b, a end
		for _, pos in ipairs({a, b, c, a, c, d}) do triangles[#triangles + 1] = {pos = pos, normal = normal, color = Color(shade, shade, shade), u = 0, v = 0} end
	end

	local o = origin
	Face(o, o + x, o + x + y, o + y, -z:GetNormalized())
	Face(o + z, o + x + z, o + x + y + z, o + y + z, z:GetNormalized())
	Face(o, o + x, o + x + z, o + z, -y:GetNormalized())
	Face(o + y, o + x + y, o + x + y + z, o + y + z, y:GetNormalized())
	Face(o, o + y, o + y + z, o + z, -x:GetNormalized())
	Face(o + x, o + x + y, o + x + y + z, o + x + z, x:GetNormalized())
	return triangles
end

local Inset = 0.2
local Cube = Box(P1 + (Forward + Left + Up) * Inset, Forward * (2 * Size - 2 * Inset), Left * (2 * Size - 2 * Inset), Up * (P4.z - P1.z - 2 * Inset))

---------------------------------------------
-- Placing the points
---------------------------------------------
local c = sb:Chapter("Placing the points")
c:AddInstruction("MoveCameraLookAt", {Target = Vector(20, 10, 50), Distance = 1400, Angle = 145, Height = 450, Length = 0.6})
c:AddInstruction("PlaceModel", {Name = "pad", Model = "models/hunter/plates/plate2x2.mdl", Position = PadPos, Angles = PadAng, Length = 0})
c:AddInstruction("ColorModel", {Target = "pad", Color = Color(120, 160, 220), Length = 0})
c:AddInstruction("PlaceModel", {Name = "post", Model = "models/hunter/blocks/cube1x1x1.mdl", Position = PostPos, Angles = PadAng, Length = 0})
c:AddInstruction("ColorModel", {Target = "post", Color = Color(230, 170, 60), Length = 0})
c:AddInstruction("ShowToolgun", {Tool = "precision_align", Position = ToolPos, Length = 0.375})
c:AddInstruction("Caption", {Text = "The Primitives tab builds a shape from points you place. Here a cube will be fitted to the blue pad, as tall as the orange post. It needs the primitive addon.", FadeInOutTime = 0.225, TextLength = 6})
c:AddDelay(6.5)
c:AddInstruction("PAToolMenu", {Name = "menu"})
c:AddDelay(0.5)
c:AddInstruction("Caption", {Text = "Points 1 and 2 define an edge the shape is aligned to. Left click one end of the edge for point 1.", FadeInOutTime = 0.225, TextLength = 4.5})
c:AddDelay(1)
c:AddInstruction("PAClick", {Button = "Left Click", Position = P1})
c:AddInstruction("PAPoint", {Name = "p1", Position = P1, Label = "1"})
c:AddDelay(3)
c:AddInstruction("Caption", {Text = "Hold Shift while left clicking to move on to the next point, then click the other end of the edge for point 2.", FadeInOutTime = 0.225, TextLength = 5})
c:AddDelay(1)
c:AddInstruction("PAClick", {Button = "Left Click", Position = P2, Held = {"Shift"}})
c:AddInstruction("PAPoint", {Name = "p2", Position = P2, Label = "2"})
c:AddInstruction("PAMenuSelect", {Name = "menu", Within = "point_window", List = "list_primarypoint", Line = 2})
c:AddInstruction("DebugLine", {Name = "edge", Start = P1, End = P2, Color = Color(255, 220, 60), IgnoreZ = true})
c:AddDelay(3.5)
c:AddInstruction("Caption", {Text = "Point 3 defines a plane together with the edge. The shape is built on this plane.", FadeInOutTime = 0.225, TextLength = 4.5})
c:AddDelay(1)
c:AddInstruction("PAClick", {Button = "Left Click", Position = P3, Held = {"Shift"}})
c:AddInstruction("PAPoint", {Name = "p3", Position = P3, Label = "3"})
c:AddInstruction("PAMenuSelect", {Name = "menu", Within = "point_window", List = "list_primarypoint", Line = 3})
c:AddInstruction("DebugTriangle", {Name = "plane", P1 = P1 + Up * 0.3, P2 = P2 + Up * 0.3, P3 = P3 + Up * 0.3, Color = Color(255, 220, 60, 60)})
c:AddDelay(3)
c:AddInstruction("Caption", {Text = "Point 4 and any after it set the depth. The shape reaches out from the plane as far as they go.", FadeInOutTime = 0.225, TextLength = 5})
c:AddDelay(1)
c:AddInstruction("PAClick", {Button = "Left Click", Position = P4, Held = {"Shift"}})
c:AddInstruction("PAPoint", {Name = "p4", Position = P4, Label = "4"})
c:AddInstruction("PAMenuSelect", {Name = "menu", Within = "point_window", List = "list_primarypoint", Line = 4})
c:AddInstruction("DebugLine", {Name = "depth", Start = OnPad(Size, Size), End = P4, Color = Color(255, 220, 60), IgnoreZ = true})
c:AddDelay(4.5)

---------------------------------------------
-- Creating the primitive
---------------------------------------------
c = sb:Chapter("Creating the primitive")
c:AddInstruction("RemovePanel", {Name = "menu", Length = 0.3})
c:AddInstruction("Caption", {Text = "Press Reload to open the manipulation panel.", FadeInOutTime = 0.225, TextLength = 3})
c:AddDelay(c:AddInstruction("KeyPress", {Name = "reload", Key = "R", Position = Vector(0.5, 0.27, 0)}).PressedAt)
c:AddInstruction("PAManipulationPanel", {Name = "manip", Tab = "primitives_tab"})
c:AddDelay(3.5)
c:AddInstruction("Caption", {Text = "On the Primitives tab, select points 1 to 4, then pick Cube from the dropdown.", FadeInOutTime = 0.225, TextLength = 4.5})
c:AddDelay(1)
c:AddInstruction("PAMenuSelect", {Name = "manip", Within = "primitives_tab", List = "list_points", Line = {1, 2, 3, 4}})
c:AddDelay(1.2)
c:AddInstruction("PAMenuValue", {Name = "manip", Within = "primitives_tab", Field = "combo_primitive", Value = "Cube"})
c:AddDelay(3.3)
c:AddInstruction("Caption", {Text = "Press Create Primitive to build it.", FadeInOutTime = 0.225, TextLength = 3})
c:AddDelay(1)
c:AddDelay(c:AddInstruction("PAMenuPress", {Name = "manip", Within = "primitives_tab", Field = "button_create", Length = 1.2}).Length)
c:AddInstruction("RemovePanel", {Name = "manip", Length = 0.3})
c:AddDelay(0.4)
c:AddInstruction("RemoveDebugOverlay", {Name = "edge"})
c:AddInstruction("RemoveDebugOverlay", {Name = "plane"})
c:AddInstruction("RemoveDebugOverlay", {Name = "depth"})
c:AddInstruction("PlaceMesh", {Name = "cube", Triangles = Cube, Material = Shaded, Color = Color(150, 210, 150), Length = 0.5})
c:AddDelay(1)
c:AddInstruction("Caption", {Text = "The cube lines up with the edge from point 1 to 2, sits on the plane and reaches up to point 4.", FadeInOutTime = 0.225, TextLength = 5})
c:AddDelay(6)
c:AddInstruction("HideToolgun", {Length = 0.375})
c:AddDelay(0.375)
