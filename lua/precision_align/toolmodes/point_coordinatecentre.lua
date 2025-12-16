local MODE = PrecisionAlign.PointToolMode("Coordinate Centre", 1010)

function MODE:GetClickPosition(_, _, Ent, _)
    if not IsValid(Ent) then return end

    return Ent:PA_GetPos()
end