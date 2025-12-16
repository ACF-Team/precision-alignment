-- Multiplayer precision fixes ported to use a slightly more flexible structure.
-- Credit to WFL (https://steamcommunity.com/sharedfiles/filedetails/?id=3030265921) for the fixes.

if CLIENT then
    PrecisionAlign.StaticCLEntities = PrecisionAlign.StaticCLEntities or {}
    local StaticCLEntities = PrecisionAlign.StaticCLEntities

    local PA_POS = Vector(0, 0, 0)
    local PA_ANG = Angle(0, 0, 0)

    local function RemoveStaticCLEntFn(self)
        StaticCLEntities[self] = nil
    end

    net.Receive("PA_serverside_correction", function()
        local Ent = net.ReadEntity()
        if not IsValid(Ent) then return end

        if not net.ReadBool() then
            if IsValid(StaticCLEntities[Ent]) then StaticCLEntities[Ent]:Remove() end
            StaticCLEntities[Ent] = nil
            Ent:RemoveCallOnRemove("PA_ClearTableEntry")
            return
        end

        PA_POS:SetUnpacked(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
        PA_ANG:SetUnpacked(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())

        local FakeEnt = StaticCLEntities[Ent]
        if not IsValid(FakeEnt) then
            FakeEnt = ClientsideModel(Ent:GetModel())
            StaticCLEntities[Ent] = FakeEnt
            FakeEnt:SetPos(PA_POS)
            FakeEnt:SetAngles(PA_ANG)
            FakeEnt:SetNoDraw(true)
            FakeEnt:Spawn()
            FakeEnt:CallOnRemove("PA_ClearTableEntry", RemoveStaticCLEntFn)
            return
        end

        FakeEnt:SetPos(PA_POS)
        FakeEnt:SetAngles(PA_ANG)
    end)

    function PrecisionAlign.GetCLEnt(Ent)
        return StaticCLEntities[Ent]
    end

    function PrecisionAlign.GetActiveCLEnt()
        return PrecisionAlign.GetCLEnt(PrecisionAlign.ActiveEnt)
    end
else
    util.AddNetworkString("PA_serverside_correction")
    util.AddNetworkString("PA_serverside_listview")

    local TrackEnts = {}
    local function RemoveTrackEntFn(self)
        TrackEnts[self] = nil
    end

    function PrecisionAlign.SendServersideCorrection(Ent, Player)
        if IsValid(Ent) then
            local Pos, Ang = Ent:PA_GetPos(), Ent:GetAngles()

            net.Start("PA_serverside_correction")
                net.WriteEntity(Ent)
                net.WriteBool(true)
                net.WriteFloat(Pos[1])
                net.WriteFloat(Pos[2])
                net.WriteFloat(Pos[3])
                net.WriteFloat(Ang[1])
                net.WriteFloat(Ang[2])
                net.WriteFloat(Ang[3])
            net.Send(Player)

            local Data = TrackEnts[Ent]
            if not Data then
                Data = {}
                TrackEnts[Ent] = Data
            end

            Data.Entity    = Ent
            Data.StoredPos = Pos
            Data.StoredAng = Ang
            Data.Player    = Player

            Ent:CallOnRemove("PA_CleanupTrack", RemoveTrackEntFn)
        end
    end

    function PrecisionAlign.SendServersideStopCorrection(Ent, Player)
        net.Start("PA_serverside_correction")
            net.WriteEntity(Ent)
            net.WriteBool(false)
        net.Send(Player)

        TrackEnts[Ent] = nil
        Ent:RemoveCallOnRemove("PA_CleanupTrack")
    end

    hook.Add("Think", "PrecisionAlign_TrackEnts", function()
        for _, B in pairs(TrackEnts) do
            if IsValid(B.Entity) then
                local Pos, Ang = B.Entity:PA_GetPos(), B.Entity:GetAngles()
                if B.StoredPos ~= Pos or B.StoredAng ~= Ang then
                    net.Start("PA_serverside_correction")
                        net.WriteEntity(B.Entity)
                        net.WriteBool(true)
                        net.WriteFloat(Pos[1])
                        net.WriteFloat(Pos[2])
                        net.WriteFloat(Pos[3])
                        net.WriteFloat(Ang[1])
                        net.WriteFloat(Ang[2])
                        net.WriteFloat(Ang[3])
                    net.Send(B.Player)
                    B.StoredPos = Pos
                    B.StoredAng = Ang
                end
            end
        end
    end)

    net.Receive("PA_serverside_listview", function()
        local Vec = Vector(0, 0, 0)
        local ListView = net.ReadInt(8)
        local Ent = net.ReadEntity()
        local Ply = net.ReadEntity()

        Vec[1] = net.ReadFloat()
        Vec[2] = net.ReadFloat()
        Vec[3] = net.ReadFloat()

        local WTL = Ent:PA_WorldToLocal(Vec)

        net.Start("PA_serverside_listview")
        net.WriteInt(ListView, 8)
        net.WriteEntity(Ent)
        net.WriteFloat(WTL[1])
        net.WriteFloat(WTL[2])
        net.WriteFloat(WTL[3])
        net.Send(Ply)
    end)


end