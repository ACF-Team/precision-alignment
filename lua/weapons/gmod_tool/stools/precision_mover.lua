TOOL.Category = "Constraints"
TOOL.Name = "Precision Mover"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.MenuColor = Color(0, 220, 0, 255)

if (CLIENT) then
    TOOL.Information = {
        { name = "left" },
        { name = "right" },
        { name = "reload" }
    }
    language.Add("Tool.precision_mover.name", "Precision Mover")
    language.Add("Tool.precision_mover.desc", "Allows precise prop and Precision Alignment construct movement")
    language.Add("Tool.precision_mover.left", "Select a prop - hold SPRINT to select a base point")
    language.Add("Tool.precision_mover.right", "Grab an axis - hold SPRINT to enable snapping")
    language.Add("Tool.precision_mover.reload", "Deselect prop")
    --language.Add("Tool.precision_mover.0", "Left: Select a prop, Shift+Left: Select a base point, Right: Grab axis, Shift+Right: Snap, R: Unselect")
    JG = JG or {}
    JG.stools = JG.stools or {}
    JG.stools.loadedP = JG.stools.loadedP or {}
    JG.stools.loadedP.precision_mover = JG.stools.loadedP.precision_mover or false
    JG = JG or {}
    JG.stools = JG.stools or {}
    JG.stools.CP = JG.stools.CP or {}
    JG.stools.CP.precision_mover = JG.stools.CP.precision_mover or {}
    JG.stools.Data = JG.stools.Data or {}
    JG.stools.Data.precision_mover = JG.stools.Data.precision_mover or {}
end

if SERVER then
    util.AddNetworkString(TOOL.Name .. "_LeftClick")
    util.AddNetworkString(TOOL.Name .. "_RightClick")
    util.AddNetworkString(TOOL.Name .. "_R")
end

TOOL.enttbl = {}

TOOL.ClientConVar = {
    ["radius"] = "500",
    ["vehpro"] = 0,
    ["gmodpro"] = 0,
    ["gwirepro"] = 0,
    ["onlyparent"] = 0,
    ["timer"] = 3
}

TOOL.Ent = NULL
TOOL.BasePos = NULL

local isSingleplayer = game.SinglePlayer()

function TOOL:LeftClick(trace)
    local owner = self:GetOwner()

    if not isSingleplayer and CPPI and not trace.Entity:CPPICanTool(owner, "prop_mover") then return false end

    if SERVER then
        if isSingleplayer then
            net.Start(self.Name .. "_LeftClick")
            net.Send(player.GetHumans()[1])
        end

        return true
    end

    if owner:KeyDown(IN_SPEED) then
        if PA_funcs and PA_funcs.point_global(PA_selected_point) == false then
            JG.stools.Data.precision_mover.BasePos = trace.HitPos
        else
            JG.stools.Data.precision_mover.BasePos = PA_funcs.point_global(PA_selected_point).origin
        end
    else
        JG.stools.Data.precision_mover.Ent = trace.Entity:IsValid() and not trace.Entity:IsNPC() and not trace.Entity:IsPlayer() and not trace.Entity:IsWorld() and trace.Entity or NULL

        if JG.stools.Data.precision_mover.Ent ~= NULL then
            JG.stools.CP.precision_mover.DAdjustableModelPanel[1]:SetModel(JG.stools.Data.precision_mover.Ent:GetModel())
            JG.stools.CP.precision_mover.DLabel[1]:SetText(JG.stools.Data.precision_mover.Ent:GetModel())
            JG.stools.CP.precision_mover.DLabel[1]:SizeToContents()
            JG.stools.Data.precision_mover.Ent:SetRenderMode(1)
        end
    end

    return true
end

TOOL.lat = {
    pos = Vector(),
    lopos = Vector(),
    act = false,
    ang = Angle(),
    laang = Angle(),
    angdir = Vector(),
    val1 = Vector()
}

TOOL.Time = CurTime()
TOOL.Leng = 0
TOOL.Axis = false
TOOL.Copy = false

function TOOL:IntersectRayWithPlane(planepoint, norm, line, linenormal)
    local linepoint = line * 1
    local x = norm:Dot(planepoint - linepoint) / norm:Dot(linenormal)
    local vec = linepoint + x * linenormal

    return vec
end

local math = math

function TOOL:RightClick(trace)
    if SERVER then
        if isSingleplayer then
            net.Start(self.Name .. "_RightClick")
            net.Send(player.GetHumans()[1])
        end

        return true
    end

    if JG.stools.Data.precision_mover.Ent:IsValid() == false then return end

    if self.coordS > 0 or self.AngS > 0 then
        local owner = self:GetOwner()
        local World = {
            x = Vector(1, 0, 0),
            y = Vector(0, -1, 0),
            z = Vector(0, 0, 1)
        }

        self.Hold = true

        if self.lat.act == false then
            self.lat.act = true
            self.lat.pos = JG.stools.Data.precision_mover.BasePos == NULL and JG.stools.Data.precision_mover.Ent:GetPos() or JG.stools.Data.precision_mover.BasePos
            self.lat.pos1 = JG.stools.Data.precision_mover.Ent:GetPos()
            self.lat.mainpos = JG.stools.Data.precision_mover.Ent:GetPos()
            self.lat.ang = JG.stools.Data.precision_mover.Ent:GetAngles()

            if self.AngS > 0 then
                local amount, dir = Vector(), Vector()

                if JG.stools.Data.precision_mover.WL == false then
                    if self.AngS == 1 then
                        dir = JG.stools.Data.precision_mover.Ent:GetForward()
                        amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                    elseif self.AngS == 2 then
                        dir = JG.stools.Data.precision_mover.Ent:GetRight()
                        amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                    elseif self.AngS == 3 then
                        dir = JG.stools.Data.precision_mover.Ent:GetUp()
                        amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                    end
                else
                    if self.AngS == 1 then
                        dir = World.x
                        amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                    elseif self.AngS == 2 then
                        dir = World.y
                        amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                    elseif self.AngS == 3 then
                        dir = World.z
                        amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                    end
                end

                amount = (amount - self.lat.pos):GetNormalized()
                local val1 = amount:Angle()
                val1:Normalize()
                val1 = val1:Right():Dot(dir)
                self.lat.val1 = val1 > 0 and 1 or -1
                self.lat.angdir = amount + Vector()
                self.lat.planedir = dir + Vector()
            end
        end
        local Lalt = input.IsKeyDown(KEY_LALT)
        if self.coordS > 0 then
            local vec = trace.HitPos - self.lat.pos
            local vec2
            local len
            local dir

            if JG.stools.Data.precision_mover.WL == false then
                if self.coordS == 1 then
                    dir = JG.stools.Data.precision_mover.Ent:GetForward()
                    vec = self:IntersectRayWithPlane(self.lat.pos + dir * self.dist, JG.stools.Data.precision_mover.Ent:GetUp(), owner:EyePos(), owner:EyeAngles():Forward())
                elseif self.coordS == 2 then
                    dir = JG.stools.Data.precision_mover.Ent:GetRight()
                    vec = self:IntersectRayWithPlane(self.lat.pos + dir * self.dist, JG.stools.Data.precision_mover.Ent:GetUp(), owner:EyePos(), owner:EyeAngles():Forward())
                elseif self.coordS == 3 then
                    dir = JG.stools.Data.precision_mover.Ent:GetUp()
                    local val1 = (self.lat.pos - owner:EyePos()):Angle()
                    val1.p = 0
                    val1 = val1:Forward()
                    vec = self:IntersectRayWithPlane(self.lat.pos + dir * self.dist, val1, owner:EyePos(), owner:EyeAngles():Forward())
                end
            else
                if self.coordS == 1 then
                    dir = World.x
                    vec = self:IntersectRayWithPlane(self.lat.pos + dir * self.dist, World.z, owner:EyePos(), owner:EyeAngles():Forward())
                elseif self.coordS == 2 then
                    dir = World.y
                    vec = self:IntersectRayWithPlane(self.lat.pos + dir * self.dist, World.z, owner:EyePos(), owner:EyeAngles():Forward())
                elseif self.coordS == 3 then
                    dir = World.z
                    local val1 = (self.lat.pos - owner:EyePos()):Angle()
                    val1.p = 0
                    val1 = val1:Forward()
                    vec = self:IntersectRayWithPlane(self.lat.pos + dir * self.dist, val1, owner:EyePos(), owner:EyeAngles():Forward())
                end
            end

            len = self.lat.pos - vec
            vec = len:GetNormalized()
            len = len:Length()
            vec2 = vec:Dot(dir)
            local var3 = vec2 * len + self.dist

            if owner:KeyDown(IN_SPEED) then
                local val = JG.stools.CP.precision_mover.DNumSlider[2]:GetValue()
                local val2 = var3 < 0 and math.Round(var3 / val) * val or math.floor(var3 / val) * val
                JG.stools.Data.precision_mover.Ent:SetPos(self.lat.pos - dir * val2)
                local val3 = self.coordS
                self.Leng = val3 == 2 and val2 or -val2
            else
                JG.stools.Data.precision_mover.Ent:SetPos(self.lat.pos - dir * var3)
                self.Leng = -var3
            end
        elseif self.AngS > 0 then
            local amount, dir

            if JG.stools.Data.precision_mover.WL == false then
                if self.AngS == 1 then
                    dir = self.lat.ang:Forward()
                    amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                elseif self.AngS == 2 then
                    dir = self.lat.ang:Right()
                    amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                elseif self.AngS == 3 then
                    dir = self.lat.ang:Up()
                    amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                end
            else
                if self.AngS == 1 then
                    dir = World.x
                    amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                elseif self.AngS == 2 then
                    dir = World.y
                    amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                elseif self.AngS == 3 then
                    dir = World.z
                    amount = self:IntersectRayWithPlane(self.lat.pos, dir, owner:EyePos(), owner:EyeAngles():Forward())
                end
            end

            amount = (amount - self.lat.pos):GetNormalized()
            local dot = self.lat.angdir:Dot(amount)
            local val1 = self.lat.angdir:Angle() + Angle()
            local p1 = val1 + Angle()
            p1:RotateAroundAxis(dir, 90)
            val1:Normalize()
            local val2, val3
            local ang = self.lat.ang + Angle()
            ang:Normalize()

            if Lalt == false then
                val2 = p1:Forward():Dot(amount)
                amount = (math.acos(dot)) * 180 / math.pi + 90 * math.pi / 180
                amount = string.Left(amount, 3) == "nan" and 0 or amount
                val3 = (val2 > 0 and 1 or -1)

                if owner:KeyDown(IN_SPEED) then
                    local val = JG.stools.CP.precision_mover.DNumSlider[1]:GetValue()
                    local mon = amount * val3
                    mon = mon < 0 and math.ceil(mon / val) * val or math.floor(mon / val) * val
                    ang:RotateAroundAxis(dir, mon)
                else
                    ang:RotateAroundAxis(dir, amount * val3)
                end

                self.amount = amount * val3
            else
                if owner:KeyDown(IN_SPEED) then
                    local val = JG.stools.CP.precision_mover.DNumSlider[1]:GetValue()
                    local var0 = amount
                    local val0 = self.lat.planedir:Angle()
                    val0:Normalize()
                    local toDeg = 180 / math.pi
                    amount = 0
                    local var1 = self.lat.ang
                    local var2 = math.acos(var1:Forward():Dot(-val0:Up())) * toDeg
                    local var3 = val0:Right():Dot(var1:Forward())
                    var3 = var3 < 0 and -1 or 1
                    amount = var2 * var3
                    amount = string.Left(amount, 3) == "nan" and 0 or amount
                    var2 = math.acos(var0:Dot(-val0:Up())) * toDeg
                    var3 = val0:Right():Dot(var0)
                    var3 = var3 < 0 and -1 or 1
                    local var4 = var2 * var3
                    var4 = math.floor(var4 / val) * val
                    -- end
                    amount = amount - var4
                    amount = string.Left(amount, 3) == "nan" and 0 or amount
                    ang:RotateAroundAxis(val0:Forward(), amount)
                    self.amount = var4
                else
                    local var0 = amount
                    local val0 = self.lat.planedir:Angle() + Angle()
                    val0:Normalize()
                    local toDeg = 180 / math.pi
                    amount = 0
                    local var1 = self.lat.ang
                    local var2 = math.acos(var1:Forward():Dot(-val0:Up())) * toDeg
                    local var3 = val0:Right():Dot(var1:Forward())
                    var3 = var3 < 0 and -1 or 1
                    amount = var2 * var3
                    self.amount1 = amount
                    amount = string.Left(amount, 3) == "nan" and 0 or amount
                    var2 = math.acos(var0:Dot(-val0:Up())) * toDeg
                    var3 = val0:Right():Dot(var0)
                    var3 = var3 < 0 and -1 or 1
                    amount = amount - var2 * var3
                    amount = string.Left(amount, 3) == "nan" and 0 or amount
                    ang:RotateAroundAxis(val0:Forward(), amount)
                    self.amount = -var2 * var3
                end
            end

            JG.stools.Data.precision_mover.Ent:SetAngles(ang)

            if JG.stools.Data.precision_mover.BasePos ~= NULL then
                local vec = self.lat.mainpos - JG.stools.Data.precision_mover.BasePos
                local len = vec:Length()
                dir = vec:GetNormalized()
                ang = dir:Angle()
                ang:Normalize()
                local snap = self.UseSnap

                if JG.stools.Data.precision_mover.WL == false then
                    local mon

                    if Lalt == false then
                        if snap == true then
                            local var1 = JG.stools.CP.precision_mover.DNumSlider[1]:GetValue()
                            mon = amount * (val2 > 0 and 1 or -1) --* self.lat.val1
                            mon = mon < 0 and math.ceil(mon / var1) * var1 or math.floor(mon / var1) * var1
                        else
                            mon = amount * (val2 > 0 and 1 or -1)
                        end
                    else
                        if snap == true then
                            local var1 = JG.stools.CP.precision_mover.DNumSlider[1]:GetValue()
                            mon = self.amount1 + self.amount
                            mon = mon < 0 and math.ceil(mon / var1) * var1 or math.floor(mon / var1) * var1
                            mon = -mon
                        else
                            mon = self.amount1 + self.amount
                        end
                    end

                    if self.AngS == 1 then
                        ang:RotateAroundAxis(JG.stools.Data.precision_mover.Ent:GetForward(), mon)
                    elseif self.AngS == 2 then
                        ang:RotateAroundAxis(JG.stools.Data.precision_mover.Ent:GetRight(), mon)
                    elseif self.AngS == 3 then
                        ang:RotateAroundAxis(JG.stools.Data.precision_mover.Ent:GetUp(), mon)
                    end
                elseif JG.stools.Data.precision_mover.WL == true then
                    local mon

                    if Lalt == false then
                        if snap == true then
                            local var1 = JG.stools.CP.precision_mover.DNumSlider[1]:GetValue()
                            mon = amount * (val2 > 0 and 1 or -1)
                            mon = mon < 0 and math.ceil(mon / var1) * var1 or math.floor(mon / var1) * var1
                        else
                            mon = amount * (val2 > 0 and 1 or -1)
                        end
                    else
                        if snap == true then
                            mon = -self.amount
                        else
                            mon = self.amount
                        end
                    end

                    if self.AngS == 1 then
                        ang:RotateAroundAxis(World.x, mon)
                    elseif self.AngS == 2 then
                        ang:RotateAroundAxis(World.y, mon)
                    elseif self.AngS == 3 then
                        ang:RotateAroundAxis(World.z, mon)
                    end
                end

                JG.stools.Data.precision_mover.Ent:SetPos(JG.stools.Data.precision_mover.BasePos + ang:Forward() * len)
            end
        end

        self.lat.lopos = JG.stools.Data.precision_mover.Ent:GetPos()
        self.lat.loang = JG.stools.Data.precision_mover.Ent:GetAngles()
    end

    return false
end

TOOL.amount = 0
TOOL.la = false
TOOL.first = false
TOOL.WL = false

function TOOL:Think()
    if SERVER then return end

    if self.Hold then
        local owner = self:GetOwner()
        self.la = true

        local tr = util.TraceLine({
            start = owner:EyePos(),
            endpos = owner:EyePos() + owner:EyeAngles():Forward() * 50000,
            filter = {self, owner, JG.stools.Data.precision_mover.Ent}
        })

        self:RightClick(tr)
    end

    if self.la == true and self.Hold == false then
        if (self.lat.lopos - self.lat.pos):Length() < 5000 then
            net.Start("Inf_Move")
            net.WriteInt(self.coordS, 3)
            net.WriteInt(self.AngS, 3)
            net.WriteInt(JG.stools.Data.precision_mover.Copy == true and 1 or 0, 2)
            net.WriteInt(JG.stools.Data.precision_mover.Ent:EntIndex(), 12)
            net.WriteVector(self.lat.lopos)
            net.WriteAngle(self.lat.loang)
            net.WriteVector(self.lat.pos1)
            net.WriteAngle(self.lat.ang)
            net.SendToServer()
            GAMEMODE:AddNotify("Successfully Sent", NOTIFY_HINT, 5)
            surface.PlaySound("buttons/button15.wav")
        else
            GAMEMODE:AddNotify("Failed : Abnormal Pos", NOTIFY_ERROR, 5)
            surface.PlaySound("buttons/button10.wav")
        end

        self.la = false
        self.lat.act = false
    end

    if self.first == false then
        net.Receive(self.Name .. "_LeftClick", function()
            local EP, EA = EyePos(), EyeAngles()
            local forward = EA:Forward()

            local tr = util.TraceLine({
                start = EP,
                endpos = EP + forward * 50000,
                filter = LocalPlayer()
            })

            self:LeftClick(tr)
        end)

        net.Receive(self.Name .. "_RightClick", function()
            local EP, EA = EyePos(), EyeAngles()
            local forward = EA:Forward()

            local tr = util.TraceLine({
                start = EP,
                endpos = EP + forward * 50000,
                filter = LocalPlayer()
            })

            self:RightClick(tr)
        end)

        net.Receive(self.Name .. "_R", function()
            local EP, EA = EyePos(), EyeAngles()
            local forward = EA:Forward()

            local tr = util.TraceLine({
                start = EP,
                endpos = EP + forward * 50000,
                filter = LocalPlayer()
            })

            self:Reload(tr)
        end)

        concommand.Add("mover_reloadui", function()
            self.first = false
            JG.stools.loadedP.precision_mover = false
        end)

        self.first = true
        self.ratio = ScrW() / ScrH()

        if JG.stools.loadedP.precision_mover == false then
            self.panel = controlpanel.Get("precision_mover")

            if self.panel:GetInitialized() == false or (g_SpawnMenu:IsVisible() == false and g_ContextMenu:IsVisible() == false) then
                timer.Simple(0.01, function()
                    RunConsoleCommand("mover_reloadui")
                end)

                return
            end

            self.panel:Clear()

            JG.stools.Data.precision_mover = {
                Ent = NULL,
                BasePos = NULL,
                WL = false,
                Lat = NULL,
                la = false,
                Copy = false
            }

            for _, v in pairs(self.panel:GetChildren()) do
                if v == self.panel then continue end
                local x, y = v:GetPos()
                local _, h = v:GetSize()
                if x == 0 and y == 0 and h == 20 then continue end

                if v.IsValid and v:IsValid() then
                    v:Remove()
                end
            end

            JG.stools.CP.precision_mover.DComboBox = {}
            local t = JG.stools.CP.precision_mover.DComboBox
            local baseY = 30

            t[1] = vgui.Create("DComboBox", self.panel)
            t[1]:SetPos(10, baseY)
            t[1]:SetSize(90, 25)
            t[1]:SetValue("Local")
            t[1]:AddChoice("World")
            t[1]:AddChoice("Local")

            t[1].OnSelect = function(_, index)
                if index == 2 then
                    JG.stools.Data.precision_mover.WL = false
                else
                    JG.stools.Data.precision_mover.WL = true
                end
            end

            JG.stools.CP.precision_mover.DCheckBox = {}
            t = JG.stools.CP.precision_mover.DCheckBox
            t[1] = vgui.Create("DCheckBoxLabel", self.panel)
            t[1]:SetPos(10, baseY + 35)
            t[1]:SetSize(130, 20)
            t[1]:SetText("Rotate - Point")
            t[1]:SetTooltip("Uses Axis function from Precision Alignment.\nYou may rotate props by grabbing axis.")
            t[1].Label:SetTextColor(Color(255, 0, 0, 255))

            t[1].OnChange = function(panel, a)
                JG.stools.Data.precision_mover.Axis = a

                if a == true then
                    panel:SetText("Rotate - Axis")
                    panel.Label:SetTextColor(Color(0, 0, 255, 255))
                else
                    panel:SetText("Rotate - Point")
                    panel.Label:SetTextColor(Color(255, 0, 0, 255))
                end
            end

            t[2] = vgui.Create("DCheckBoxLabel", self.panel)
            t[2]:SetPos(10, baseY + 185)
            t[2]:SetSize(130, 20)
            t[2]:SetText("Copy - DeActive")
            t[2].Label:SetTextColor(Color(255, 0, 0, 255))
            t[2]:SetTooltip("Each time you move props,\nduplicates the prop on original position.")

            t[2].OnChange = function(panel, a)
                JG.stools.Data.precision_mover.Copy = a

                if a == true then
                    panel:SetText("Copy - Active")
                    panel.Label:SetTextColor(Color(0, 255, 0, 255))
                else
                    panel:SetText("Copy - DeActive")
                    panel.Label:SetTextColor(Color(255, 0, 0, 255))
                end
            end

            JG.stools.CP.precision_mover.Binder = {}
            t = JG.stools.CP.precision_mover.Binder
            t[1] = vgui.Create("DBinder", self.panel)
            t[1]:SetSize(90, 40)
            t[1]:SetPos(10, baseY + 60)
            JG.stools.CP.precision_mover.Buttons = {}
            t = JG.stools.CP.precision_mover.Buttons
            t[1] = vgui.Create("DButton", self.panel)
            t[1]:SetPos(10, baseY + 100)
            t[1]:SetSize(90, 40)
            t[1]:SetText("Reset BasePos")

            t[1].DoClick = function()
                JG.stools.Data.precision_mover.BasePos = NULL
            end

            t = JG.stools.CP.precision_mover.Buttons
            t[2] = vgui.Create("DButton", self.panel)
            t[2]:SetPos(10, baseY + 140)
            t[2]:SetSize(90, 40)
            t[2]:SetText("Reset Ent Info")

            t[2].DoClick = function()
                JG.stools.Data.precision_mover.Ent = NULL
            end

            JG.stools.CP.precision_mover.DNumSlider = {}
            t = JG.stools.CP.precision_mover.DNumSlider
            t[1] = vgui.Create("DNumSlider", self.panel)
            t[1]:SetPos(10, baseY + 200)
            t[1]:SetText("Snap Amount Deg")
            t[1]:SetSize(240, 30)
            t[1].Label:SetSize(90)
            t[1].Label:SetDark(1)
            t[1]:SetDecimals(1)
            t[1]:SetMax(90)
            t[1]:SetMin(0)
            t[1]:SetValue(45)

            --[[t[1].Paint = function()
                draw.RoundedBox(3, 0, 0, 100, 100, Color(255, 255, 255, 100))
            end]]

            t = JG.stools.CP.precision_mover.DNumSlider
            t[2] = vgui.Create("DNumSlider", self.panel)
            t[2]:SetPos(10, baseY + 230)
            t[2]:SetText("Snap Amount Pos")
            t[2]:SetSize(240, 30)
            t[2].Label:SetSize(90)
            --t[2].Label:SetTextColor(Color(0, 0, 0, 255))
            t[2]:SetDecimals(1)
            t[2]:SetMax(100)
            t[2]:SetMin(0)
            t[2]:SetValue(50)

            --[[t[2].Paint = function()
                draw.RoundedBox(3, 0, 0, 100, 100, Color(255, 255, 255, 100))
            end]]

            JG.stools.CP.precision_mover.DLabel = {}
            t = JG.stools.CP.precision_mover.DLabel
            t[1] = vgui.Create("DLabel", self.panel)
            t[1]:SetPos(10, baseY + 260)
            t[1]:SetSize(10, 10)
            t[1]:SetText("Default")
            t[1]:SizeToContents()
            t[1]:SetPaintBackground(true)

            JG.stools.CP.precision_mover.DPanel = {}
            t = JG.stools.CP.precision_mover.DPanel
            t[1] = vgui.Create("DPanel", self.panel)
            t[1]:SetPos(10, baseY + 290)
            local val = self.panel:GetSize()
            t[1]:SetSize(val - 20, 300)

            t[1].Paint = function(a)
                val = self.panel:GetSize()
                val = val - 20
                t[1]:SetSize(val, 300)
                JG.stools.CP.precision_mover.DAdjustableModelPanel[1]:SetSize(val, val)
                local _, y = a:GetSize()
                draw.RoundedBox(6, 5, 5, val - 10, y - 10, Color(0, 0, 0, 100))
                draw.RoundedBox(6, 0, 0, val, y, Color(0, 0, 0, 100))
            end

            JG.stools.CP.precision_mover.DAdjustableModelPanel = {}
            t = JG.stools.CP.precision_mover.DAdjustableModelPanel
            t[1] = vgui.Create("DModelPanel", JG.stools.CP.precision_mover.DPanel[1])
            t[1]:SetPos(0, 0)
            t[1]:SetSize(200, 200)
            t[1]:SetLookAt(vector_origin)
            t[1]:SetModel("models/props_borealis/bluebarrel001.mdl")

            local params = {
                ["$basetexture"] = "models/debug/debugwhite",
                ["$ignorez"] = "1"
            }

            self.Mat = CreateMaterial("JG_MoverMat", "UnlitGeneric", params)

            hook.Add("PostDrawTranslucentRenderables", "Mover_Render", function()
                local ent = JG.stools.Data.precision_mover.Ent
                if not IsValid(ent) then return end
                local wep = LocalPlayer():GetActiveWeapon()

                if wep:IsValid() == false then
                    self.la = false
                    self.Hold = false

                    return
                end

                if wep:GetClass() ~= "gmod_tool" then
                    self.la = false
                    self.Hold = false

                    return
                end

                if wep:GetMode() ~= "precision_mover" then
                    self.la = false
                    self.Hold = false

                    return
                end

                local tmp = HSVToColor(CurTime() * 50 % 360, 1, 1)
                local Mat = self.Mat
                render.SuppressEngineLighting(true)
                render.SetColorModulation(tmp.r / 255, tmp.g / 255, tmp.b / 255)
                render.MaterialOverride(Mat)
                render.SetBlend(0.6)
                ent:DrawModel()
                render.MaterialOverride()
                render.SuppressEngineLighting(false)
            end)

            JG.stools.loadedP.precision_mover = true
        end
    end
end

if SERVER then
    util.AddNetworkString("Inf_MoveP")
    util.AddNetworkString("Inf_MoveA")
    util.AddNetworkString("Inf_Move")

    net.Receive("Inf_MoveP", function()
        local _, _, _, EntInd, Vec = net.ReadInt(3), net.ReadInt(3), net.ReadInt(1), net.ReadInt(12), Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
        local ent = ents.GetByIndex(EntInd)
        ent:SetPos(Vec)
        local phys = ent:GetPhysicsObject()

        if phys:IsValid() then
            phys:EnableMotion(false)
        end
    end)

    net.Receive("Inf_Move", function(_, ply)
        local _, _, Copy, EntInd, Vec = net.ReadInt(3), net.ReadInt(3), net.ReadInt(2), net.ReadInt(12), net.ReadVector()
        local ang = net.ReadAngle()
        local ent = ents.GetByIndex(EntInd)
        local pos1, ang1 = net.ReadVector(), net.ReadAngle()

        if ent:IsValid() then
            if math.abs(Vec.x) > 30000 or math.abs(Vec.y) > 30000 or math.abs(Vec.z) > 30000 then
                Vec.x = math.Clamp(Vec.x, -30000, 30000)
                Vec.y = math.Clamp(Vec.y, -30000, 30000)
                Vec.z = math.Clamp(Vec.z, -30000, 30000)
                print("nan Values")
            end

            local cop

            if Copy == 1 then
                local copT = duplicator.CopyEntTable(ent)
                cop = duplicator.CreateEntityFromTable(ply, copT)
                duplicator.DoGeneric(cop, copT)
            end

            if ent:GetParent() == NULL then
                ent:SetPos(Vec)
                ent:SetAngles(ang)
                local phys = ent:GetPhysicsObject()

                if phys:IsValid() then
                    phys:EnableMotion(false)
                    phys:Wake()
                end
            else
                local par = ent:GetParent()
                ent:SetParent()
                ent:SetPos(Vec)
                ent:SetAngles(ang)
                local phys = ent:GetPhysicsObject()

                if phys:IsValid() then
                    phys:EnableMotion(false)
                    phys:Wake()
                end

                ent:SetParent(par)
            end

            undo.Create("Precision Mover")
            undo.SetPlayer(ply)

            undo.AddFunction(function(_, e, pos, undoAng)
                if e:IsValid() == false then return end
                local par = e:GetParent()

                if par == NULL then
                    e:SetPos(pos)
                    e:SetAngles(undoAng)
                    local phys = e:GetPhysicsObject()

                    if phys:IsValid() then
                        phys:EnableMotion(false)
                        phys:Wake()
                    end
                else
                    e:SetParent()
                    e:SetPos(pos)
                    e:SetAngles(undoAng)
                    local phys = e:GetPhysicsObject()

                    if phys:IsValid() then
                        phys:EnableMotion(false)
                        phys:Wake()
                    end

                    e:SetParent(par)
                end
            end, ent, pos1, ang1)

            undo.Finish()

            if Copy > 0 then
                undo.Create("Mover - Copied Entity")
                undo.SetPlayer(ply)
                undo.AddEntity(cop)
                undo.Finish()
            end
        else
            return
        end
    end)

    net.Receive("Inf_MoveA", function()
        local ent, ang = ents.GetByIndex(net.ReadInt(12)), Angle(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
        local phys = ent:GetPhysicsObject()
        ent:SetAngles(ang)

        if phys:IsValid() then
            phys:EnableMotion(false)
        end
    end)
end

function TOOL:Reload()
    if SERVER then
        if isSingleplayer then
            net.Start(self.Name .. "_R")
            net.Send(player.GetHumans()[1])
        end

        return true
    end

    self.XYVal = {}
    self.AABB = {}
    JG.stools.Data.precision_mover.Ent = NULL
    JG.stools.Data.precision_mover.BasePos = NULL
    JG.stools.CP.precision_mover.DAdjustableModelPanel[1]:SetModel("models/props_borealis/bluebarrel001.mdl")
    JG.stools.CP.precision_mover.DLabel[1]:SetText("Default")

    return true
end

TOOL.Lat = NULL
TOOL.AABB = {}

function TOOL:GetSign(a, b)
    local tmp = a + Vector()

    if b == 2 then
        tmp.x, tmp.y, tmp.z = -tmp.x, tmp.y, tmp.z
    elseif b == 3 then
        tmp.x, tmp.y, tmp.z = -tmp.x, -tmp.y, tmp.z
    elseif b == 4 then
        tmp.x, tmp.y, tmp.z = tmp.x, -tmp.y, tmp.z
    elseif b == 5 then
        tmp.x, tmp.y, tmp.z = -tmp.x, -tmp.y, tmp.z
    elseif b == 6 then
        tmp.x, tmp.y, tmp.z = tmp.x, -tmp.y, tmp.z
    elseif b == 7 then
        tmp.x, tmp.y, tmp.z = tmp.x, tmp.y, tmp.z
    elseif b == 8 then
        tmp.x, tmp.y, tmp.z = -tmp.x, tmp.y, tmp.z
    end

    local val = JG.stools.Data.precision_mover.Ent:LocalToWorld(tmp)

    return self:ToScreen2(val)
end

function TOOL:ToScreen2(v, v1)
    local owner = self:GetOwner()
    local cPos, cAng, cFov, scrW, scrH

    if v1 == nil then
        cPos, cAng, cFov, scrW, scrH = v - owner:EyePos(), owner:EyeAngles(), owner:GetFOV() / 180 * math.pi, ScrW(), ScrH()
    else
        cPos, cAng, cFov, scrW, scrH = v - owner:EyePos(), owner:EyeAngles(), owner:GetFOV() / 180 * math.pi, ScrW(), ScrH()
    end

    local vDir = cAng:Forward()
    vDir = cPos - vDir
    local d = 4 * scrH / (6 * math.tan(0.5 * cFov))
    local fdp = cAng:Forward():Dot(vDir)
    if (fdp == 0) then return 0, 0, false, false end
    local vProj = (d / fdp) * vDir
    local x = 0.5 * scrW + cAng:Right():Dot(vProj)
    local y = 0.5 * scrH - cAng:Up():Dot(vProj)

    if fdp < -0.1 then
        x, y = 30000, 30000
    end

    return {
        x = x,
        y = y,
        visible = (-300 < x and x < scrW + 300 and -300 < y and y < scrH + 300) and fdp > 0,
        tmp = fdp > 0
    }
end

TOOL.XYVal = {}

local function Vec2L(a, b)
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

TOOL.colList = {
    x = Color(255, 0, 0, 255),
    y = Color(0, 255, 0, 255),
    z = Color(0, 0, 255, 255)
}

TOOL.AngS = 0
TOOL.coordS = 0
TOOL.Hold = false
TOOL.UseSnap = false

function TOOL:Hud1()
    local owner = self:GetOwner()

    if self.Hold == true and owner:KeyDown(IN_ATTACK2) == false then
        self.Hold = false
    end

    if self.Hold == false then
        self.lat.act = false
    end

    self.UseSnap = owner:KeyDown(IN_SPEED)

    if IsValid(JG.stools.Data.precision_mover.Ent) then
        local pos = JG.stools.Data.precision_mover.BasePos == NULL and JG.stools.Data.precision_mover.Ent:GetPos() or JG.stools.Data.precision_mover.BasePos

        if self.Lat ~= JG.stools.Data.precision_mover.Ent then
            self.AABB[1], self.AABB[2] = JG.stools.Data.precision_mover.Ent:WorldSpaceAABB()
            self.AABB[1], self.AABB[2] = pos - self.AABB[1], pos - self.AABB[2]
        end

        local Ang = JG.stools.Data.precision_mover.Ent:GetAngles()
        local Vec2, Vec1 = {}, pos + Vector()
        self.dist = (Vec1 - owner:EyePos()):Length()
        local Vec2_2 = self:ToScreen2(Vec1)
        local font = "ChatFont"
        local dot = {}

        if self.Hold == false then
            self.AngS = 0
            self.coordS = 0
        end

        self.dist = math.min(self.dist, 600) / 6

        local World = {
            x = Vector(1, 0, 0),
            y = Vector(0, -1, 0),
            z = Vector(0, 0, 1)
        }

        if JG.stools.Data.precision_mover.WL == false then
            Vec2[1] = self:ToScreen2(Vec1 + Ang:Forward() * 2 * self.dist)
            dot[1] = self:ToScreen2(Vec1 + Ang:Forward() * self.dist)
            Vec2[2] = self:ToScreen2(Vec1 + Ang:Right() * 2 * self.dist)
            dot[2] = self:ToScreen2(Vec1 + Ang:Right() * self.dist)
            Vec2[3] = self:ToScreen2(Vec1 + Ang:Up() * 2 * self.dist)
            dot[3] = self:ToScreen2(Vec1 + Ang:Up() * self.dist)
        else
            Vec2[1] = self:ToScreen2(Vec1 + World.x * 2 * self.dist)
            dot[1] = self:ToScreen2(Vec1 + World.x * self.dist)
            Vec2[2] = self:ToScreen2(Vec1 + World.y * 2 * self.dist)
            dot[2] = self:ToScreen2(Vec1 + World.y * self.dist)
            Vec2[3] = self:ToScreen2(Vec1 + World.z * 2 * self.dist)
            dot[3] = self:ToScreen2(Vec1 + World.z * self.dist)
        end

        local List = {
            x = {},
            y = {},
            z = {}
        }

        local dis = self.dist

        if JG.stools.Data.precision_mover.WL == false then
            for i = 1, 36 do
                local va = Ang + Angle()
                va:RotateAroundAxis(Ang:Forward(), 10 * i)
                List.x[i] = self:ToScreen2(Vec1 + va:Up() * 2 * dis)
                va = Ang + Angle()
                va:RotateAroundAxis(Ang:Right(), 10 * i)
                List.y[i] = self:ToScreen2(Vec1 + va:Forward() * 2 * dis)
                va = Ang + Angle()
                va:RotateAroundAxis(Ang:Up(), 10 * i)
                List.z[i] = self:ToScreen2(Vec1 + va:Forward() * 2 * dis)
            end
        else
            for i = 1, 36 do
                local va = Angle()
                va:RotateAroundAxis(World.x, 10 * i)
                List.x[i] = self:ToScreen2(Vec1 + va:Up() * 2 * dis)
                va = Angle()
                va:RotateAroundAxis(World.y, 10 * i)
                List.y[i] = self:ToScreen2(Vec1 + va:Forward() * 2 * dis)
                va = Angle()
                va:RotateAroundAxis(World.z, 10 * i)
                List.z[i] = self:ToScreen2(Vec1 + va:Forward() * 2 * dis)
            end
        end

        if self.Hold then
            for i = 1, 36 do
                local tmp = i > 35 and 1 or i + 1

                if self.AngS == 1 then
                    surface.SetDrawColor(self.colList.x)
                    surface.DrawLine(List.x[i].x, List.x[i].y, List.x[tmp].x, List.x[tmp].y)
                elseif self.AngS == 2 then
                    surface.SetDrawColor(self.colList.y)
                    surface.DrawLine(List.y[i].x, List.y[i].y, List.y[tmp].x, List.y[tmp].y)
                elseif self.AngS == 3 then
                    surface.SetDrawColor(self.colList.z)
                    surface.DrawLine(List.z[i].x, List.z[i].y, List.z[tmp].x, List.z[tmp].y)
                end
            end
        else
            for i = 1, 36 do
                local tmp = i > 35 and 1 or i + 1
                surface.SetDrawColor(self.colList.x)
                surface.DrawLine(List.x[i].x, List.x[i].y, List.x[tmp].x, List.x[tmp].y)
                surface.SetDrawColor(self.colList.y)
                surface.DrawLine(List.y[i].x, List.y[i].y, List.y[tmp].x, List.y[tmp].y)
                surface.SetDrawColor(self.colList.z)
                surface.DrawLine(List.z[i].x, List.z[i].y, List.z[tmp].x, List.z[tmp].y)
            end
        end

        if self.Hold then
            surface.SetDrawColor(Color(255, 255, 0, 255))

            if JG.stools.Data.precision_mover.WL == false then
                local val = self:ToScreen2(Vec1 + self.lat.angdir * dis * 2)

                if self.UseSnap then
                    if self.AngS == 1 then
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                        local val2 = (self:IntersectRayWithPlane(self.lat.pos, JG.stools.Data.precision_mover.Ent:GetForward(), owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos)
                        val = self:ToScreen2(Vec1 + val2:GetNormalized() * 2 * dis)
                        surface.SetDrawColor(Color(255, 0, 0, 255))
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    elseif self.AngS == 2 then
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                        val = self:ToScreen2(Vec1 + (self:IntersectRayWithPlane(self.lat.pos, JG.stools.Data.precision_mover.Ent:GetRight(), owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos):GetNormalized() * 2 * dis)
                        surface.SetDrawColor(Color(0, 255, 0, 255))
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    elseif self.AngS == 3 then
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                        val = self:ToScreen2(Vec1 + (self:IntersectRayWithPlane(self.lat.pos, JG.stools.Data.precision_mover.Ent:GetUp(), owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos):GetNormalized() * 2 * dis)
                        surface.SetDrawColor(Color(0, 0, 255, 255))
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    end
                else
                    if self.AngS == 1 then
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                        val = self:ToScreen2(Vec1 + (self:IntersectRayWithPlane(self.lat.pos, JG.stools.Data.precision_mover.Ent:GetForward(), owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos):GetNormalized() * 2 * dis)
                        surface.SetDrawColor(Color(255, 0, 0, 255))
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    elseif self.AngS == 2 then
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                        val = self:ToScreen2(Vec1 + (self:IntersectRayWithPlane(self.lat.pos, JG.stools.Data.precision_mover.Ent:GetRight(), owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos):GetNormalized() * 2 * dis)
                        surface.SetDrawColor(Color(0, 255, 0, 255))
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    elseif self.AngS == 3 then
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                        val = self:ToScreen2(Vec1 + (self:IntersectRayWithPlane(self.lat.pos, JG.stools.Data.precision_mover.Ent:GetUp(), owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos):GetNormalized() * 2 * dis)
                        surface.SetDrawColor(Color(0, 0, 255, 255))
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    end
                end
            else
                local val = self:ToScreen2(Vec1 + self.lat.angdir * dis * 2)

                if self.AngS == 1 then
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    val = self:ToScreen2(Vec1 + (self:IntersectRayWithPlane(self.lat.pos, World.x, owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos):GetNormalized() * 2 * dis)
                    surface.SetDrawColor(Color(255, 0, 0, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                elseif self.AngS == 2 then
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    val = self:ToScreen2(Vec1 + (self:IntersectRayWithPlane(self.lat.pos, World.y, owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos):GetNormalized() * 2 * dis)
                    surface.SetDrawColor(Color(0, 255, 0, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                elseif self.AngS == 3 then
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                    val = self:ToScreen2(Vec1 + (self:IntersectRayWithPlane(self.lat.pos, World.z, owner:EyePos(), owner:EyeAngles():Forward()) - self.lat.pos):GetNormalized() * 2 * dis)
                    surface.SetDrawColor(Color(0, 0, 255, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, val.x, val.y)
                end
            end

            if self.AngS > 0 then
                local val = self:ToScreen2(Vec1 + self.lat.angdir * dis)
                local TAC = TEXT_ALIGN_CENTER

                if self.UseSnap then
                    local val2 = JG.stools.CP.precision_mover.DNumSlider[1]:GetValue()
                    local mon = self.amount < 0 and math.ceil(self.amount / val2) * val2 or math.floor(self.amount / val2) * val2
                    draw.SimpleText("Local Degree : " .. string.format("%.1f", mon) .. "º", font, val.x, val.y, Color(200, 0, 0, 255), TAC, TAC)
                else
                    draw.SimpleText("Local Degree : " .. string.format("%.1f", self.amount) .. "º", font, val.x, val.y, Color(200, 0, 0, 255), TAC, TAC)
                end
            end
        end

        if not self.Hold then
            local mouse = {
                x = ScrW() / 2,
                y = ScrH() / 2
            }

            local entry = {9999, 9999}

            for i = 1, 3 do
                local tmp = Vec2L(mouse, dot[i])

                if tmp < 13 and entry[1] > tmp then
                    entry[1] = tmp
                    self.coordS = i
                end
            end

            local va = {30099, 30099, 30099}

            for i = 1, 36 do
                local len = Vec2L(List.x[i], mouse)

                if va[1] > len and len < 20 then
                    va[1] = len
                end

                len = Vec2L(List.y[i], mouse)

                if va[2] > len and len < 20 then
                    va[2] = len
                end

                len = Vec2L(List.z[i], mouse)

                if va[3] > len and len < 20 then
                    va[3] = len
                end
            end

            for k, v in ipairs(va) do
                if entry[2] > v then
                    entry[2] = v
                    self.AngS = k
                end
            end

            local a = 9999
            local t = 0

            for k, v in ipairs(entry) do
                if a > v then
                    a = v
                    t = k
                end
            end

            if t == 1 then
                self.AngS = 0
            elseif t == 2 then
                self.coordS = 0
            end
        end

        self.colList.x, self.colList.y, self.colList.z = self.AngS == 1 and Color(255, 255, 0, 255) or Color(255, 0, 0, 255), self.AngS == 2 and Color(255, 255, 0, 255) or Color(0, 255, 0, 255), self.AngS == 3 and Color(255, 255, 0, 255) or Color(0, 0, 255, 255)
        local col

        if JG.stools.Data.precision_mover.BasePos == NULL then
            if self.Hold then
                if JG.stools.Data.precision_mover.WL == false then
                    col = Color(255, 255, 0, 255)
                    local TAC = TEXT_ALIGN_CENTER

                    if self.coordS == 1 then
                        surface.SetDrawColor(col)
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[1].x, Vec2[1].y)
                        draw.SimpleText("+Forward Roll : " .. string.format("%.1f", Ang.r) .. "º", font, Vec2[1].x, Vec2[1].y, Color(200, 0, 0, 255), TAC, TAC)
                        surface.DrawCircle(dot[1].x, dot[1].y, 10, col)
                        draw.SimpleText("Length ( inch , m , cm) : " .. string.format("%.2f", self.Leng) .. " , " .. string.format("%.2f", self.Leng * 0.0254) .. " , " .. string.format("%.2f", self.Leng * 2.54), font, Vec2[1].x, Vec2[1].y + 30, Color(2000, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        col = Color(0, 255, 255, 255)
                        local val1 = self:ToScreen2(self.lat.pos + JG.stools.Data.precision_mover.Ent:GetForward() * self.dist)
                        surface.DrawCircle(val1.x, val1.y, 20, col)
                    elseif self.coordS == 2 then
                        surface.SetDrawColor(col)
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[2].x, Vec2[2].y)
                        draw.SimpleText("+Right Pitch : " .. string.format("%.1f", Ang.p) .. "º", font, Vec2[2].x, Vec2[2].y, Color(0, 200, 0, 255), TAC, TAC)
                        surface.DrawCircle(dot[2].x, dot[2].y, 10, col)
                        draw.SimpleText("Length ( inch , m , cm) : " .. string.format("%.2f", self.Leng) .. " , " .. string.format("%.2f", self.Leng * 0.0254) .. " , " .. string.format("%.2f", self.Leng * 2.54), font, Vec2[2].x, Vec2[2].y + 30, Color(0, 200, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        col = Color(0, 255, 255, 255)
                        local val1 = self:ToScreen2(self.lat.pos + JG.stools.Data.precision_mover.Ent:GetRight() * self.dist)
                        surface.DrawCircle(val1.x, val1.y, 20, col)
                    elseif self.coordS == 3 then
                        surface.SetDrawColor(col)
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[3].x, Vec2[3].y)
                        draw.SimpleText("+Up Yaw : " .. string.format("%.1f", Ang.y) .. "º", font, Vec2[3].x, Vec2[3].y, Color(0, 0, 200, 255), TAC, TAC)
                        surface.DrawCircle(dot[3].x, dot[3].y, 10, col)
                        draw.SimpleText("Length ( inch , m , cm) : " .. string.format("%.2f", self.Leng) .. " , " .. string.format("%.2f", self.Leng * 0.0254) .. " , " .. string.format("%.2f", self.Leng * 2.54), font, Vec2[3].x, Vec2[3].y + 30, Color(0, 0, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        col = Color(0, 255, 255, 255)
                        local val1 = self:ToScreen2(self.lat.pos + JG.stools.Data.precision_mover.Ent:GetUp() * self.dist)
                        surface.DrawCircle(val1.x, val1.y, 20, col)
                    end
                else
                    col = Color(255, 255, 0, 255)
                    local TAC = TEXT_ALIGN_CENTER

                    if self.coordS == 1 then
                        surface.SetDrawColor(col)
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[1].x, Vec2[1].y)
                        draw.SimpleText("+Forward Roll", font, Vec2[1].x, Vec2[1].y, Color(200, 0, 0, 255), TAC, TAC)
                        surface.DrawCircle(dot[1].x, dot[1].y, 10, col)
                        draw.SimpleText("Length ( inch , m , cm) : " .. string.format("%.2f", self.Leng) .. " , " .. string.format("%.2f", self.Leng * 0.0254) .. " , " .. string.format("%.2f", self.Leng * 2.54), font, Vec2[1].x, Vec2[1].y + 30, Color(2000, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        col = Color(0, 255, 255, 255)
                        local val1 = self:ToScreen2(self.lat.pos + JG.stools.Data.precision_mover.Ent:GetForward() * self.dist)
                        surface.DrawCircle(val1.x, val1.y, 20, col)
                    elseif self.coordS == 2 then
                        surface.SetDrawColor(col)
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[2].x, Vec2[2].y)
                        draw.SimpleText("+Right Pitch", font, Vec2[2].x, Vec2[2].y, Color(0, 200, 0, 255), TAC, TAC)
                        surface.DrawCircle(dot[2].x, dot[2].y, 10, col)
                        draw.SimpleText("Length ( inch , m , cm) : " .. string.format("%.2f", self.Leng) .. " , " .. string.format("%.2f", self.Leng * 0.0254) .. " , " .. string.format("%.2f", self.Leng * 2.54), font, Vec2[2].x, Vec2[2].y + 30, Color(0, 200, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        col = Color(0, 255, 255, 255)
                        local val1 = self:ToScreen2(self.lat.pos + JG.stools.Data.precision_mover.Ent:GetRight() * self.dist)
                        surface.DrawCircle(val1.x, val1.y, 20, col)
                    elseif self.coordS == 3 then
                        surface.SetDrawColor(col)
                        surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[3].x, Vec2[3].y)
                        draw.SimpleText("+Up Yaw", font, Vec2[3].x, Vec2[3].y, Color(0, 0, 200, 255), TAC, TAC)
                        surface.DrawCircle(dot[3].x, dot[3].y, 10, col)
                        draw.SimpleText("Length ( inch , m , cm) : " .. string.format("%.2f", self.Leng) .. " , " .. string.format("%.2f", self.Leng * 0.0254) .. " , " .. string.format("%.2f", self.Leng * 2.54), font, Vec2[3].x, Vec2[3].y + 30, Color(0, 0, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        col = Color(0, 255, 255, 255)
                        local val1 = self:ToScreen2(self.lat.pos + JG.stools.Data.precision_mover.Ent:GetUp() * self.dist)
                        surface.DrawCircle(val1.x, val1.y, 20, col)
                    end
                end
                --draw.SimpleText("" , Color(0 ,0,200,255) , TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            else
                if JG.stools.Data.precision_mover.WL == false then
                    local TAC = TEXT_ALIGN_CENTER
                    surface.SetDrawColor(self.coordS == 1 and Color(255, 255, 0, 255) or Color(255, 0, 0, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[1].x, Vec2[1].y)
                    draw.SimpleText("+Forward Roll : " .. string.format("%.1f", Ang.r) .. "º", font, Vec2[1].x, Vec2[1].y, Color(200, 0, 0, 255), TAC, TAC)
                    surface.SetDrawColor(self.coordS == 2 and Color(255, 255, 0, 255) or Color(0, 255, 0, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[2].x, Vec2[2].y)
                    draw.SimpleText("+Right Pitch : " .. string.format("%.1f", Ang.p) .. "º", font, Vec2[2].x, Vec2[2].y, Color(0, 200, 0, 255), TAC, TAC)
                    surface.SetDrawColor(self.coordS == 3 and Color(255, 255, 0, 255) or Color(0, 0, 255, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[3].x, Vec2[3].y)
                    draw.SimpleText("+Up Yaw : " .. string.format("%.1f", Ang.y) .. "º", font, Vec2[3].x, Vec2[3].y, Color(0, 0, 200, 255), TAC, TAC)
                    col = self.coordS == 1 and Color(255, 255, 0, 255) or Color(255, 127, 0, 255)
                    surface.DrawCircle(dot[1].x, dot[1].y, 10, col)
                    col = self.coordS == 2 and Color(255, 255, 0, 255) or Color(255, 127, 0, 255)
                    surface.DrawCircle(dot[2].x, dot[2].y, 10, col)
                    col = self.coordS == 3 and Color(255, 255, 0, 255) or Color(255, 127, 0, 255)
                    surface.DrawCircle(dot[3].x, dot[3].y, 10, col)
                else
                    local TAC = TEXT_ALIGN_CENTER
                    surface.SetDrawColor(self.coordS == 1 and Color(255, 255, 0, 255) or Color(255, 0, 0, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[1].x, Vec2[1].y)
                    draw.SimpleText("+Forward Roll", font, Vec2[1].x, Vec2[1].y, Color(200, 0, 0, 255), TAC, TAC)
                    surface.SetDrawColor(self.coordS == 2 and Color(255, 255, 0, 255) or Color(0, 255, 0, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[2].x, Vec2[2].y)
                    draw.SimpleText("+Right Pitch", font, Vec2[2].x, Vec2[2].y, Color(0, 200, 0, 255), TAC, TAC)
                    surface.SetDrawColor(self.coordS == 3 and Color(255, 255, 0, 255) or Color(0, 0, 255, 255))
                    surface.DrawLine(Vec2_2.x, Vec2_2.y, Vec2[3].x, Vec2[3].y)
                    draw.SimpleText("+Up Yaw", font, Vec2[3].x, Vec2[3].y, Color(0, 0, 200, 255), TAC, TAC)
                    col = self.coordS == 1 and Color(255, 255, 0, 255) or Color(255, 127, 0, 255)
                    surface.DrawCircle(dot[1].x, dot[1].y, 10, col)
                    col = self.coordS == 2 and Color(255, 255, 0, 255) or Color(255, 127, 0, 255)
                    surface.DrawCircle(dot[2].x, dot[2].y, 10, col)
                    col = self.coordS == 3 and Color(255, 255, 0, 255) or Color(255, 127, 0, 255)
                    surface.DrawCircle(dot[3].x, dot[3].y, 10, col)
                end
            end

            local TAC = TEXT_ALIGN_CENTER
            draw.SimpleText(tostring(JG.stools.Data.precision_mover.Ent:GetAngles()), "ChatFont", Vec2_2.x, Vec2_2.y, Color(255, 0, 255, 255), TAC, TAC)
        end
    end

    self.Lat = JG.stools.Data.precision_mover.Ent
end

TOOL.ratio = 0

function TOOL:Hud2()
    local SW, SH = ScrW(), ScrH()
    local hSW, hSH = SW / 2, SH / 4
    -- local font, col = "ChatFont", Color(200, 0, 0, 240)
    local TAC = TEXT_ALIGN_CENTER

    if not PA_funcs then
        local col2 = Color((math.sin(SysTime() * 2) + 1) * 127.5, 0, 0)
        draw.SimpleText("WARNING: Precision Alignment not loaded! Some features may not function properly!", "Trebuchet24", hSW, hSH, col2, TAC)
        draw.SimpleText("Open the Precision Alignment tool at least once before using this tool.", "Trebuchet24", hSW, hSH + 20, col2, TAC)
    end
end

function TOOL:DrawToolScreen( width, height )
    surface.SetDrawColor( Color( 20, 20, 20 ) )
    surface.DrawRect( 0, 0, width, height )

    if PA_funcs then
        draw.SimpleText( "[PA Points/Lines]", "DermaLarge", width / 2, 24, Color( 200, 200, 200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

        local po, li = PA_selected_point, PA_selected_line
        draw.SimpleText( "Selected Point Index:", "DermaLarge", width / 2, height / 2 - 64, Color( 200, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        draw.SimpleText( po .. " -> " .. tostring(type(PA_funcs.point_global(po)) == "table"), "DermaLarge", width / 2, height / 2 - 32, Color( 200, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

        draw.SimpleText( "Selected Line Index:", "DermaLarge", width / 2, height / 2 + 32, Color( 0, 200, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        draw.SimpleText( li .. " -> " .. tostring(type(PA_funcs.point_global(li)) == "table"), "DermaLarge", width / 2, height / 2 + 64, Color( 0, 200, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    else
        draw.SimpleText( "Precision Alignment", "DermaLarge", width / 2, height / 2 - 16, Color( 200, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        draw.SimpleText( "Not loaded!", "DermaLarge", width / 2, height / 2 + 16, Color( 200, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end
end

function TOOL:DrawHUD()
    if JG.stools.loadedP.precision_mover == false then return end
    self:Hud1()
    self:Hud2()
end