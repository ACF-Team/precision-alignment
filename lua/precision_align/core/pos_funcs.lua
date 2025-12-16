-- InfMap support, ported to use a slightly more flexible structure.
-- Credit to WFL (https://steamcommunity.com/sharedfiles/filedetails/?id=3030265921) for this.

local ENTITY = FindMetaTable("Entity")

function ENTITY:PA_GetPos()
    if InfMap then
        return self:InfMap_GetPos()
    else
        return self:GetPos()
    end
end

function ENTITY:PA_LocalToWorld(Pos)
    if InfMap then
        return self:InfMap_LocalToWorld(Pos)
    else
        return self:LocalToWorld(Pos)
    end
end

if SERVER then
    function ENTITY:PA_WorldToLocal(Pos)
        if InfMap then
            return self:InfMap_WorldToLocal(Pos)
        else
            return self:WorldToLocal(Pos)
        end
    end
end

function PrecisionAlign.GetTraceHitPos(Trace)
    if InfMap then
        return InfMap.localize_vector(Trace.HitPos)
    else
        return Trace.HitPos
    end
end
