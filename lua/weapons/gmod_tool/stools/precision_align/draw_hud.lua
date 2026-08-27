local PA = "precision_align"
local PA_ = PA .. "_"

local attachHCvar = GetConVar( PA_ .. "attachcolour_h" )
local attachSCvar = GetConVar( PA_ .. "attachcolour_s" )
local attachVCvar = GetConVar( PA_ .. "attachcolour_v" )
local attachACvar = GetConVar( PA_ .. "attachcolour_a" )
local sizePointCvar = GetConVar( PA_ .. "size_point" )
local sizeLineStartCvar = GetConVar( PA_ .. "size_line_start" )
local sizeLineEndCvar = GetConVar( PA_ .. "size_line_end" )
local sizePlaneCvar = GetConVar( PA_ .. "size_plane" )
local sizePlaneNormCvar = GetConVar( PA_ .. "size_plane_normal" )
local borderSizeCvar = GetConVar( PA_ .. "border_size" )
local lineThicknessCvar = GetConVar( PA_ .. "line_thickness" )

surface.CreateFont("PA_GizmoFont", {
    font = "Arial",
    size = ScrW() / 60,
    weight = 900,
})

local pointcolour = PrecisionAlign.GetConstructColor(PrecisionAlign.CONSTRUCT_POINT):Copy()
local linecolour  = PrecisionAlign.GetConstructColor(PrecisionAlign.CONSTRUCT_LINE):Copy()
local planecolour = PrecisionAlign.GetConstructColor(PrecisionAlign.CONSTRUCT_PLANE):Copy()

local VECTOR, ANGLE = FindMetaTable("Vector"), FindMetaTable("Angle")
-- Thank you github.com/Pugsworth: https://github.com/ACF-Team/precision-alignment/issues/14#issuecomment-4242933012
local CachedViewSetup = {origin = Vector(0, 0, 0), angle = Angle(0, 0, 0)}
local function RefreshCachedViewSetup()
    CachedViewSetup = render.GetViewSetup()
end
local function ClippedToScreen(StartPos, EndPos)
    local CamPos = CachedViewSetup.origin
    local CamForward = ANGLE.Forward(CachedViewSetup.angle)

    -- Use the near clipping plane to determine visibility instead of the ToScreen().visible property since that isn't reliable, especially if there was an error in a rendering hook (open issue).
    local Epsilon = view.znear

    local DotA = VECTOR.Dot(CamForward, StartPos - CamPos)
    local DotB = VECTOR.Dot(CamForward, EndPos - CamPos)

    -- Both points are culled by the near plane
    if DotA < Epsilon and DotB < Epsilon then return nil end

    -- Partial occlusion: perform clipping
    if DotA < Epsilon or DotB < Epsilon then
        local VecVisible = DotA >= Epsilon and StartPos or EndPos
        local VecBehind = DotA < Epsilon and StartPos or EndPos

        local DotVisible = VECTOR.Dot(CamForward, VecVisible - CamPos)
        local DotBehind  = VECTOR.Dot(CamForward, VecBehind - CamPos)

        -- Calculate the intersection factor to obtain a new world vector that would sit directly on the camera's znear plane.
        -- This makes the occluded point always on or near enough to the actual screen that ToScreen can give valid results.
        local T = (Epsilon - DotVisible) / (DotBehind - DotVisible)
        local ClippedPoint = VecVisible + T * (VecBehind - VecVisible)

        return VECTOR.ToScreen(VecVisible), VECTOR.ToScreen(ClippedPoint)
    end

    -- Otherwise fully visible
    return VECTOR.ToScreen(StartPos), VECTOR.ToScreen(EndPos)
end

pointcolour:SetBrightness(0.98)
pointcolour:SetSaturation(0.8)
linecolour:SetBrightness(0.98)
linecolour:SetSaturation(0.8)
planecolour:SetBrightness(0.98)
planecolour:SetSaturation(0.8)

local planecolour_a = planecolour:Copy()
planecolour_a.a = 255

-- HUD display
local point_size_min = math.max( sizePointCvar:GetInt(), 1 )
local point_size_max = sizePointCvar:GetInt() * 1000

local line_size_start = sizeLineStartCvar:GetInt()
local line_size_min = sizeLineEndCvar:GetInt() -- End (double bar)
local line_size_max = line_size_min * 1000

local plane_size = sizePlaneCvar:GetInt()
local plane_size_normal = sizePlaneNormCvar:GetInt()
local text_min, text_max = 1, 3500

local draw_attachments = LocalPlayer():GetInfo( PA_ .. "draw_attachments" )

cvars.AddChangeCallback( PA_ .. "size_point", function( _, _, New ) point_size_min = tonumber(math.max(New, 1)); point_size_max = tonumber(New) * 1000 end )
cvars.AddChangeCallback( PA_ .. "size_line_start",  function( _, _, New ) line_size_start = tonumber(New) end  )
cvars.AddChangeCallback( PA_ .. "size_line_end",  function( _, _, New ) line_size_min = tonumber(New); line_size_max  = line_size_min * 1000 end  )
cvars.AddChangeCallback( PA_ .. "size_plane", function( _, _, New ) plane_size = tonumber(New) end  )
cvars.AddChangeCallback( PA_ .. "size_plane_normal", function( _, _, New ) plane_size_normal = tonumber(New) end  )

-- Manage attachment line colour changes
local H = attachHCvar:GetInt()
local S = attachSCvar:GetInt()
local V = attachVCvar:GetInt()
local A = attachACvar:GetInt()
local attachcolourHSV = { h = H, s = S, v = V, a = A }
local attachcolourRGB = HSVToColor( H, S, V )
attachcolourRGB.a = A

local function SetAttachColour(CVar, _, New)
    if CVar == PA_ .. "attachcolour_h" then
        attachcolourHSV.h = New
    elseif CVar == PA_ .. "attachcolour_s" then
        attachcolourHSV.s = New
    elseif CVar == PA_ .. "attachcolour_v" then
        attachcolourHSV.v = New
    elseif CVar == PA_ .. "attachcolour_a" then
        attachcolourHSV.a = New
    end

    attachcolourRGB = HSVToColor( attachcolourHSV.h, attachcolourHSV.s, attachcolourHSV.v )
    attachcolourRGB.a = attachcolourHSV.a
end

cvars.AddChangeCallback( PA_ .. "attachcolour_h", SetAttachColour )
cvars.AddChangeCallback( PA_ .. "attachcolour_s", SetAttachColour )
cvars.AddChangeCallback( PA_ .. "attachcolour_v", SetAttachColour )
cvars.AddChangeCallback( PA_ .. "attachcolour_a", SetAttachColour )


local function inview( pos2D )
    if	pos2D.x > -ScrW() and
        pos2D.y > -ScrH() and
        pos2D.x < ScrW() * 2 and
        pos2D.y < ScrH() * 2 then
            return true
    end
    return false
end

local v1, v2 = Vector(), Vector()
local function drawLine(startX, startY, endX, endY, thickness, color, cap)
    if not startX then return end
    if not startY then return end
    if not endX then return end
    if not endY then return end

    thickness = math.max(1, thickness or 1)
    color = color or color_white

    if thickness <= 1 then -- Thickness of 1 looks better without the mesh method.
        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        surface.DrawLine(startX, startY, endX, endY)
        return
    end

    local x, y   = endX - startX, endY - startY
    local cx, cy = (startX + endX) / 2, (startY + endY) / 2
    local dist   = (math.sqrt((x^2) + (y^2))) + (cap == false and 0 or thickness * 1.5)

    local a      = -math.atan2(y, x)
    local s, c   = math.sin(a), math.cos(a)

    v1:SetUnpacked(cx, cy, 0)
    v2:SetUnpacked(s, c, -thickness)
    render.SetColorMaterial()
    mesh.Begin(MATERIAL_QUADS, 1)
    xpcall(function()
        mesh.QuadEasy(v1, v2, dist, thickness, color)
        mesh.End()
    end, function() mesh.End() print(debug.traceback(err)) end)
end

local lines = {}
local lineCount
local linecolor, linethickness, lineborder_color
local function beginLineStrip(thickness, color, border_color)
    lineCount = 0
    linecolor, linethickness, lineborder_color = color, thickness, border_color
end
local function pushLine(sx, sy, ex, ey, thickness, color, cap)
    lineCount = lineCount + 1
    if not lines[lineCount] then
        lines[lineCount] = {sx, sy, ex, ey, linethickness, linecolor, cap}
    else
        local tbl = lines[lineCount]
        tbl[1] = sx
        tbl[2] = sy
        tbl[3] = ex
        tbl[4] = ey
        tbl[5] = thickness or linethickness
        tbl[6] = color or linecolor
        tbl[7] = cap
    end
end
local function renderLines()
    if lineborder_color and borderSizeCvar:GetFloat() > 0 then
        for i = 1, lineCount do
            local line = lines[i]
            drawLine(line[1], line[2], line[3], line[4], line[5] and line[5] + borderSizeCvar:GetFloat() or linethickness + borderSizeCvar:GetFloat(), lineborder_color, line[7])
        end
    end

    for i = 1, lineCount do
        local line = lines[i]
        drawLine(unpack(line))
    end
end

local textMatrix    = Matrix()
local textVectorTrn = Vector()
local textVectorScl = Vector()
local function drawText(Distance, Text, X, Y, DistX, DistY, Color, ...)
    local Dist = math.Clamp(Distance * 9, text_min, text_max)
    local Sc   = math.Round(math.Remap(Dist, text_min, text_max, 1, 0.5) * 50) / 50

    textVectorTrn:SetUnpacked(math.Remap(Dist, text_max, text_min, X, X + DistX), math.Remap(Dist, text_max, text_min, Y, Y + DistY), 0)
    textVectorScl:SetUnpacked(Sc, Sc, 1)

    textMatrix:Identity()
    textMatrix:Translate(textVectorTrn)
    textMatrix:Scale(textVectorScl)

    cam.PushModelMatrix(textMatrix)
        draw.SimpleTextOutlined(Text, "PA_GizmoFont", 0, 0, Color, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT, borderSizeCvar:GetFloat() >= 1 and 2 or 0, color_black)
    cam.PopModelMatrix()
end

-- HUD draw function
local function precision_align_draw()
    local playerpos = LocalPlayer():GetShootPos()
    RefreshCachedViewSetup()
    -- Points
    for k, v in ipairs (PrecisionAlign.Points) do
        if v.visible and v.origin then

            --Check if point exists
            local point_temp = PrecisionAlign.Functions.point_global(k)
            if point_temp then
                local origin = point_temp.origin
                local point = origin:ToScreen()
                if inview( point ) then
                    local distance = playerpos:Distance( origin )
                    local size = math.Clamp( point_size_max / distance, point_size_min, point_size_max )
                    local text_dist = math.Clamp(text_max / distance, text_min, text_max)

                    local lineSize = math.Clamp(math.Remap(distance, text_min, text_max, lineThicknessCvar:GetFloat(), 1), 1, lineThicknessCvar:GetFloat())
                    beginLineStrip(lineSize, pointcolour, color_black)
                    pushLine(point.x - size, point.y, point.x + size, point.y)
                    pushLine(point.x, point.y + size, point.x, point.y - size)

                    drawText(distance, tostring(k), point.x, point.y, text_dist, text_dist / 1.5, pointcolour, 0)

                    -- Draw attachment line
                    if draw_attachments and IsValid(v.entity) then
                        local entpos = v.entity:GetPos():ToScreen()
                        pushLine(point.x, point.y, entpos.x, entpos.y, 2, attachcolourRGB)
                    end
                    renderLines()
                end
            end
        end
    end

    -- Lines
    for k, v in ipairs (PrecisionAlign.Lines) do
        if v.visible and v.startpoint and v.endpoint then

            --Check if line exists
            local line_temp = PrecisionAlign.Functions.line_global(k)
            if line_temp then
                local startpoint = line_temp.startpoint
                local endpoint = line_temp.endpoint

                local line_start = startpoint:ToScreen()
                local line_end = endpoint:ToScreen()

                local distance1 = playerpos:Distance( startpoint )
                local distance2 = playerpos:Distance( endpoint )

                local size2 = math.Clamp(line_size_max / distance2, line_size_min, line_size_max)
                local text_dist = math.Clamp(text_max / distance1, text_min, text_max)

                local lineSize = math.Clamp(math.Remap(distance1, text_min, text_max, lineThicknessCvar:GetFloat(), 1), 1, lineThicknessCvar:GetFloat())
                beginLineStrip(lineSize, linecolour, color_black)
                -- Start X
                local normal = (endpoint - startpoint):GetNormal()
                local dir1, dir2

                if IsValid(v.entity) then
                    local up = v.entity:GetUp()
                    if normal:Dot(up) < 0.9 then
                        dir1 = (normal:Cross(up)):GetNormal()
                    else
                        dir1 = (normal:Cross(v.entity:GetForward())):GetNormal()
                    end
                else
                    if math.abs(normal.z) < 0.9 then
                        dir1 = (normal:Cross(Vector(0, 0, 1))):GetNormal()
                    else
                        dir1 = (normal:Cross(Vector(1, 0, 0))):GetNormal()
                    end
                end

                dir2 = (dir1:Cross(normal)):GetNormal() * line_size_start
                dir1 = dir1 * line_size_start

                local v1 = (startpoint + dir1 + dir2):ToScreen()
                local v2 = (startpoint - dir1 + dir2):ToScreen()
                local v3 = (startpoint - dir1 - dir2):ToScreen()
                local v4 = (startpoint + dir1 - dir2):ToScreen()

                -- Start X
                if inview( line_start ) then
                    pushLine(v1.x, v1.y, v3.x, v3.y)
                    pushLine(v2.x, v2.y, v4.x, v4.y)

                    -- Line flush
                    renderLines()
                    beginLineStrip(lineSize, linecolour, color_black)
                end

                -- Line
                pushLine( line_start.x, line_start.y, line_end.x, line_end.y, nil, nil, false )

                -- End =
                if inview( line_end ) then
                    local line_dir_2D = Vector(line_end.x - line_start.x, line_end.y - line_start.y, 0):GetNormalized()
                    local norm_dir_2D = {x = -line_dir_2D.y, y = line_dir_2D.x}
                    pushLine( line_end.x - norm_dir_2D.x * size2, line_end.y - norm_dir_2D.y * size2,
                                    line_end.x + norm_dir_2D.x * size2, line_end.y + norm_dir_2D.y * size2 )
                    pushLine( line_end.x + (line_dir_2D.x / 3 - norm_dir_2D.x) * size2, line_end.y + (line_dir_2D.y / 3 - norm_dir_2D.y) * size2,
                                    line_end.x + (line_dir_2D.x / 3 + norm_dir_2D.x) * size2, line_end.y + (line_dir_2D.y / 3 + norm_dir_2D.y) * size2 )
                end

                drawText(distance1, tostring(k), line_start.x, line_start.y, text_dist, text_dist / 1.5 - 15, Color(linecolour.r, linecolour.g, linecolour.b, linecolour.a), 3 )

                -- Draw attachment line
                if draw_attachments and IsValid(v.entity) then
                    local entpos = v.entity:GetPos():ToScreen()
                    pushLine( line_start.x, line_start.y, entpos.x, entpos.y, 2, attachcolourRGB )
                end

                renderLines()
            end
        end
    end

    -- Planes
    for k, v in ipairs ( PrecisionAlign.Planes ) do
        if v.visible and v.origin and v.normal then

            -- Check if plane exists
            local plane_temp = PrecisionAlign.Functions.plane_global(k)
            if plane_temp then

                local origin = plane_temp.origin
                local normal = plane_temp.normal

                -- Draw normal line
                local line_start = origin:ToScreen()
                if inview( line_start ) then

                    local line_end = ( origin + normal * plane_size_normal ):ToScreen()

                    local distance = playerpos:Distance( origin )
                    local text_dist = math.Clamp(text_max / distance, text_min, text_max)

                    local lineSize = math.Clamp(math.Remap(distance, text_min, text_max, lineThicknessCvar:GetFloat(), 1), 1, lineThicknessCvar:GetFloat())

                    -- Draw plane surface
                    local dir1, dir2
                    if IsValid( v.entity ) then
                        local up = v.entity:GetUp()
                        dir1 = math.abs( normal:Dot( up ) ) < 0.9 and up or v.entity:GetForward()
                    else
                        dir1 = math.abs( normal.z ) < 0.9 and Vector( 0, 0, 1 ) or Vector( 1, 0, 0 )
                    end

                    dir1 = ( normal:Cross( dir1 ) ):GetNormal()
                    dir2 = ( dir1:Cross( normal ) ):GetNormal() * plane_size
                    dir1 = dir1 * plane_size

                    local p1 = origin + dir1 + dir2
                    local p2 = origin - dir1 + dir2
                    local p3 = origin - dir1 - dir2
                    local p4 = origin + dir1 - dir2
                    local v1 = p1:ToScreen()
                    local v2 = p2:ToScreen()
                    local v3 = p3:ToScreen()
                    local v4 = p4:ToScreen()

                    beginLineStrip(lineSize, planecolour, color_black)
                    pushLine( v1.x, v1.y, v2.x, v2.y, nil, nil, false )
                    pushLine( v2.x, v2.y, v3.x, v3.y, nil, nil, false )
                    pushLine( v3.x, v3.y, v4.x, v4.y, nil, nil, false )
                    pushLine( v4.x, v4.y, v1.x, v1.y, nil, nil, false )

                    -- Line flush so the normal indicator overlaps correctly.
                    renderLines()
                    beginLineStrip(lineSize, planecolour, color_black)

                    pushLine( line_start.x, line_start.y, line_end.x, line_end.y )

                    drawText(distance, tostring( k ), line_start.x, line_start.y, text_dist, text_dist / 1.5, Color( planecolour.r, planecolour.g, planecolour.b, planecolour.a ), 1 )
                    -- Default
                    -- Draw attachment line
                    if draw_attachments and IsValid(v.entity) then
                        local entpos = v.entity:GetPos():ToScreen()
                        pushLine( line_start.x, line_start.y, entpos.x, entpos.y, 2, attachcolourRGB )
                    end

                    renderLines()
                end
            end
        end
    end
end
hook.Add("HUDPaint", "draw_precision_align", precision_align_draw)

local function precision_align_displayhud_func( _, _, args )
    local enabled = tobool( args[1] )
    if not enabled then
        hook.Remove( "HUDPaint", "draw_precision_align" )
    else
        hook.Add("HUDPaint", "draw_precision_align", precision_align_draw)
    end
    return true
end
concommand.Add( PA_ .. "displayhud", precision_align_displayhud_func )