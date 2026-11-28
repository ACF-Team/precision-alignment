local MODE = PrecisionAlign.PointToolMode("World/Phys. Vertex", 1060)

local MIN_BOUNDS = MIN_COORD_FLOAT or -16384
local MAX_BOUNDS = MAX_COORD_FLOAT or 16384

local WorldVertices
local function GetWorldVertices()
    if WorldVertices then return WorldVertices end
    WorldVertices = PrecisionAlign.Octree(Vector(MIN_BOUNDS, MIN_BOUNDS, MIN_BOUNDS), Vector(MAX_BOUNDS, MAX_BOUNDS, MAX_BOUNDS), 1)

    for _, SurfaceInfo in ipairs(game.GetWorld():GetBrushSurfaces()) do
        for _, Vertex in ipairs(SurfaceInfo:GetVertices()) do
            local Key = string.format("%.4f_%.4f_%.4f", Vertex[1], Vertex[2], Vertex[3])
            WorldVertices:Insert(Vertex, Key)
        end
    end

    return WorldVertices
end

function MODE:GetClickPosition(Trace, Pos, _, Phys)
    if Trace.HitWorld then
        -- Octree test instead
        local _, Nearest = GetWorldVertices():GetNearestNeighbor(Pos, 3000)
        if not Nearest then
            PrecisionAlign.Warning("Could not find a world vertex?")
        end
        return Nearest
    end

    local ClosestVertex
    local ClosestVertexDistance = 100000000000

    local Vertices = Phys:GetMesh()
    if not Vertices then
        -- Spherical? So we should just return the trace hitpos I guess.
        return Pos
    end

    for _, Vertex in ipairs(Vertices) do
        local VertexPos = Phys:LocalToWorld(Vertex.pos)

        local Dist = Pos:Distance(VertexPos)
        if Dist < ClosestVertexDistance then
            ClosestVertex = VertexPos
            ClosestVertexDistance = Dist
        end
    end

    if ClosestVertex then
        return ClosestVertex
    else
        PrecisionAlign.Warning("Could not find any vertices on this entity???")
        return Pos
    end
end