local sb = Ponder.API.NewStoryboard("precision_align", "tutorials", "move-and-repeat")
sb:WithMenuName("Aligning props")
sb:WithPlaybackName("Aligning props")
sb:WithModelIcon("models/hunter/blocks/cube1x1x1.mdl")
sb:WithDescription("Move one prop onto another with two points, then repeat the move with Shift.")
sb:SetPrimaryLanguage("en")
sb:WithIndexOrder(3) -- Ponder lists the highest first

local Model, Half, ToolPos = "models/hunter/blocks/cube1x1x1.mdl", 23.725, Vector(90, -90, 90)
local APos, BPos = Vector(-60, 0, 40), Vector(80, 0, 90)
local CPos, DPos = Vector(80, 0, 90), Vector(80, 0, 90 + 2 * Half + 0.05)
local Camera = {Target = Vector(10, 0, 65), Distance = 1400, Angle = 15, Height = 350, Length = 0.6}
-- The bottom corners facing each other on the front of the orange and blue props. The prop moves from point 2 to point 1
local P1, P2 = APos + Vector(Half, Half, -Half), BPos + Vector(-Half, Half, -Half)
local Move = P1 - P2

---------------------------------------------
-- Placing the points
---------------------------------------------
local c = sb:Chapter("Placing the points")
c:AddInstruction("MoveCameraLookAt", Camera)
c:AddInstruction("PlaceModel", {Name = "a", Model = Model, Position = APos, Length = 0})
c:AddInstruction("ColorModel", {Target = "a", Color = Color(230, 170, 60), Length = 0})
c:AddInstruction("PlaceModel", {Name = "b", Model = Model, Position = BPos, Length = 0})
c:AddInstruction("ColorModel", {Target = "b", Color = Color(120, 160, 220), Length = 0})
c:AddInstruction("ShowToolgun", {Tool = "precision_align", Position = ToolPos, Length = 0.375})
c:AddInstruction("Caption", {Text = "Precision Alignment moves props between points you place. Here the blue prop will be moved against the orange one.", FadeInOutTime = 0.225, TextLength = 4.5})
c:AddDelay(5)
c:AddInstruction("PAToolMenu", {Name = "menu"})
c:AddDelay(0.5)
c:AddInstruction("Caption", {Text = "Left click where you want the prop to end up. This is point 1.", FadeInOutTime = 0.225, TextLength = 3.5})
c:AddDelay(1)
c:AddInstruction("PAClick", {Button = "Left Click", Position = P1})
c:AddInstruction("PAPoint", {Name = "p1", Position = P1, Label = "1"})
c:AddDelay(2.5)
c:AddInstruction("Caption", {Text = "Hold Shift while left clicking to move on to the next point, then click the spot on the prop you want to move. This is point 2.", FadeInOutTime = 0.225, TextLength = 5})
c:AddDelay(1)
c:AddInstruction("PAClick", {Button = "Left Click", Position = P2, Held = {"Shift"}})
c:AddInstruction("PAPoint", {Name = "p2", Position = P2, Label = "2"})
c:AddInstruction("PAMenuSelect", {Name = "menu", Within = "point_window", List = "list_primarypoint", Line = 2})
c:AddDelay(3)

---------------------------------------------
-- Moving the prop
---------------------------------------------
c = sb:Chapter("Moving the prop")
c:AddInstruction("Caption", {Text = "Right click the prop you want to move to select it.", FadeInOutTime = 0.225, TextLength = 3})
c:AddDelay(0.75)
c:AddInstruction("PAClick", {Button = "Right Click", Position = BPos})
c:AddInstruction("ColorModel", {Target = "b", Color = Color(150, 200, 255), Length = 0.3})
c:AddInstruction("PAMenuEnable", {Name = "menu"})
c:AddDelay(2.5)
c:AddInstruction("Caption", {Text = "In the menu, the left list is where the prop moves from and the right list is where it moves to. Shift clicking already selected point 2 on the left, and point 1 stays selected on the right.", FadeInOutTime = 0.225, TextLength = 7})
c:AddDelay(7.5)
c:AddInstruction("Caption", {Text = "Press Move Entity. The selected prop moves from point 2 to point 1.", FadeInOutTime = 0.225, TextLength = 4})
c:AddDelay(0.75)
c:AddDelay(c:AddInstruction("PAMenuPress", {Name = "menu", Text = "Move Entity"}).Length)
c:AddInstruction("TransformModel", {Target = "b", Position = BPos + Move, Length = 1})
c:AddInstruction("PAMovePoint", {Name = "p2", Position = P1, Length = 1})
c:AddDelay(3)
c:AddInstruction("PARemoveConstruct", {Name = "p1"})
c:AddInstruction("PARemoveConstruct", {Name = "p2"})
c:AddInstruction("RemoveModel", {Name = "b", Length = 0.4})
c:AddDelay(0.5)

---------------------------------------------
-- Repeating the move
---------------------------------------------
c = sb:Chapter("Repeating the move")
c:AddInstruction("PlaceModel", {Name = "c", Model = Model, Position = CPos, Length = 0.4})
c:AddInstruction("ColorModel", {Target = "c", Color = Color(120, 160, 220), Length = 0})
c:AddInstruction("PlaceModel", {Name = "d", Model = Model, Position = DPos, Length = 0.4})
c:AddInstruction("ColorModel", {Target = "d", Color = Color(120, 160, 220), Length = 0})
c:AddInstruction("Caption", {Text = "To move more props the same way, hold Shift while right clicking them. The last move is repeated on each.", FadeInOutTime = 0.225, TextLength = 5.5})
c:AddDelay(2)
c:AddInstruction("PAClick", {Button = "Right Click", Position = CPos, Held = {"Shift"}})
c:AddInstruction("TransformModel", {Target = "c", Position = CPos + Move, Length = 1})
c:AddDelay(2)
c:AddInstruction("PAClick", {Button = "Right Click", Position = DPos, Held = {"Shift"}})
c:AddInstruction("TransformModel", {Target = "d", Position = DPos + Move, Length = 1})
c:AddDelay(2.5)
c:AddInstruction("RemovePanel", {Name = "menu", Length = 0.3})
c:AddInstruction("HideToolgun", {Length = 0.375})
c:AddDelay(0.375)
