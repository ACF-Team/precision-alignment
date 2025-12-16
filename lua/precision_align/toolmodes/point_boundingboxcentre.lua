local MODE = PrecisionAlign.PointToolMode("Bounding Box Centre", 1030)

function MODE:GetClickPosition(_, _, Ent, _)
    if not IsValid(Ent) then return end

    return Ent:PA_LocalToWorld(Ent:OBBCenter())
end