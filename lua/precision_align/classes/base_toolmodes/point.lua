PrecisionAlign.PointToolMode = PrecisionAlign.Class(PrecisionAlign.ToolMode)
function PrecisionAlign.PointToolMode:__new(Name, SortIndex)
    PrecisionAlign.ToolMode.__new(self, PrecisionAlign.CONSTRUCT_POINT, Name, SortIndex)
end

local PA = PrecisionAlign.PA
function PrecisionAlign.SelectNextPoint()
    if PrecisionAlign.SelectedPoint < PrecisionAlign.MAX_CONSTRUCTS and PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_POINT, PrecisionAlign.SelectedPoint ) then
        PrecisionAlign.SelectedPoint = PrecisionAlign.SelectedPoint + 1
        local dlist_points = controlpanel.Get( PA ).point_window.list_primarypoint
        dlist_points:ClearSelection()
        dlist_points:SelectItem( dlist_points:GetLine(PrecisionAlign.SelectedPoint) )
        return true
    end
    return false
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