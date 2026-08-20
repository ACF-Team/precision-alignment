PrecisionAlign.PlaneToolMode = PrecisionAlign.Class(PrecisionAlign.ToolMode)
function PrecisionAlign.PlaneToolMode:__new(Name, SortIndex)
    PrecisionAlign.ToolMode.__new(self, PrecisionAlign.CONSTRUCT_PLANE, Name, SortIndex)
end

local PA = PrecisionAlign.PA
function PrecisionAlign.SelectNextPlane()
    if PrecisionAlign.SelectedPlane < PrecisionAlign.MAX_CONSTRUCTS and PrecisionAlign.Functions.construct_exists( PrecisionAlign.CONSTRUCT_PLANE, PrecisionAlign.SelectedPlane ) then
        PrecisionAlign.SelectedPlane = PrecisionAlign.SelectedPlane + 1
        local dlist_planes = controlpanel.Get( PA ).plane_window.list_plane
        dlist_planes:ClearSelection()
        dlist_planes:SelectItem( dlist_planes:GetLine(PrecisionAlign.SelectedPlane) )
        return true
    end
    return false
end