if SERVER then
    local function RoundAngleAxis(SnapAngles, Angles, Axis)
        local Value = Angles[Axis]
        local NewValue = Value

        NewValue = math.Round(Value / SnapAngles) * SnapAngles

        Angles[Axis] = NewValue
        return NewValue ~= Value
    end

    hook.Add("OnPhysgunFreeze", "PA_FixPhysgunRotationInaccuracy", function(_, PhysObj, _, Player)
        if not Player:KeyDown(IN_SPEED) then return end
        local ShouldSnap = Player:GetInfo("precision_align_snap_physgun")
        if ShouldSnap == 0 then return end

        local SnapAngles = Player:GetInfo("gm_snapangles")
        local Angles = PhysObj:GetAngles()
        -- This was for notifications, but those got kind of annoying.
        -- local Changed = false
        --[[if]] RoundAngleAxis(SnapAngles, Angles, 1) -- then Changed = true end
        --[[if]] RoundAngleAxis(SnapAngles, Angles, 2) -- then Changed = true end
        --[[if]] RoundAngleAxis(SnapAngles, Angles, 3) -- then Changed = true end
        PhysObj:SetAngles(Angles)
    end)
else
    CreateClientConVar("precision_align_snap_physgun", "1", true, true, "When enabled, this forces physgun snapping to always be 100% accurate to your desired gm_snapangles.", 0, 1)
end