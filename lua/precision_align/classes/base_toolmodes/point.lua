PrecisionAlign.PointToolMode = PrecisionAlign.Class(PrecisionAlign.ToolMode)
function PrecisionAlign.PointToolMode:__new(Name, SortIndex)
    PrecisionAlign.ToolMode.__new(self, PrecisionAlign.CONSTRUCT_POINT, Name, SortIndex)
end

local PA = PrecisionAlign.PA
function PrecisionAlign.SelectNextPoint()
    if not PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_POINT, PrecisionAlign.SelectedPoint ) then
        return false
    end

    local NextPoint = nil
    if GetConVar(PrecisionAlign.PA_ .. "shiftclick_overwrite"):GetBool() then
        -- Old behavior: always advance by one slot, regardless of occupancy
        if PrecisionAlign.SelectedPoint < PrecisionAlign.MAX_CONSTRUCTS then
            NextPoint = PrecisionAlign.SelectedPoint + 1
        end
    else
        -- Scan forward for the first unoccupied slot so we don't clobber an existing point
        for i = PrecisionAlign.SelectedPoint + 1, PrecisionAlign.MAX_CONSTRUCTS do
            if not PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_POINT, i ) then
                NextPoint = i
                break
            end
        end
    end

    if not NextPoint then
        return false
    end

    PrecisionAlign.SelectedPoint = NextPoint
    local dlist_points = controlpanel.Get( PA ).point_window.list_primarypoint
    dlist_points:ClearSelection()
    dlist_points:SelectItem( dlist_points:GetLine(PrecisionAlign.SelectedPoint) )
    return true
end

function PrecisionAlign.PointToolMode:OnClick(Entity, Point, _, Shift, Alt)
    if Shift then
        PrecisionAlign.SelectNextPoint()
    end

    PrecisionAlign.Functions.set_point(PrecisionAlign.SelectedPoint, Point)
    -- Auto-attach to selected ent
    if Alt then
        if PrecisionAlign.ActiveEnt then
            PrecisionAlign.Functions.attach_point(PrecisionAlign.SelectedPoint, PrecisionAlign.ActiveEnt)
        elseif PrecisionAlign.Points[PrecisionAlign.SelectedPoint].entity then
            PrecisionAlign.Functions.attach_point(PrecisionAlign.SelectedPoint, nil)
        end
    elseif PrecisionAlign.Points[PrecisionAlign.SelectedPoint].entity ~= Entity then
        PrecisionAlign.Functions.attach_point(PrecisionAlign.SelectedPoint, Entity)
    end
end