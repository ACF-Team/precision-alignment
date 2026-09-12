local CONSTRUCT_LISTVIEW = {}
function CONSTRUCT_LISTVIEW:Init()
	self:SetSize(110, 169)
end

-- Like GetSelected(), but ordered by ascending point/line/plane ID.
function CONSTRUCT_LISTVIEW:GetSelectedSorted()
	local sorted = self:GetSelected()
	table.sort( sorted, function( a, b ) return a:GetID() < b:GetID() end )
	return sorted
end

function CONSTRUCT_LISTVIEW:Text( title, construct )
	self.construct_type = construct
	self:AddColumn( "" .. title)
	for i = 1, PrecisionAlign.MAX_CONSTRUCTS do
		local line = self:AddLine(PrecisionAlign.GetConstructName(construct) .. " " .. tostring(i))
		line.indicator = vgui.Create( "PA_Indicator", line )
	end

	-- Format header
	local Header = self.Columns[1].Header
	Header:SetFont("DermaDefaultBold")
	Header:SetContentAlignment( 5 )
end

local function firstValidNumber(s)
	for token in s:gmatch("%S+") do
		local num = tonumber(token)
		if num ~= nil then
			return num
		end
	end
	return nil
end

function CONSTRUCT_LISTVIEW:SortByColumn(ColumnID, Desc)
	table.sort(self.Sorted, function(a, b)
		if Desc then
			a, b = b, a
		end

		local aval = a:GetSortValue(ColumnID) or a:GetColumnText(ColumnID)
		local bval = b:GetSortValue(ColumnID) or b:GetColumnText(ColumnID)

		local anum = firstValidNumber(aval)
		local bnum = firstValidNumber(bval)

		if anum and bnum then return anum < bnum end

		return tostring(aval) < tostring(bval)
	end)

	self:SetDirty(true)
	self:InvalidateLayout()
end

function CONSTRUCT_LISTVIEW:SetIndicators()
	for i = 1, PrecisionAlign.MAX_CONSTRUCTS do
		local line = self:GetLine(i)
		line.indicator = vgui.Create( "PA_Indicator", line )
	end
end

function CONSTRUCT_LISTVIEW:SetIndicatorOffset( offset )
	for i = 1, PrecisionAlign.MAX_CONSTRUCTS do
		local indicator = self:GetLine(i).indicator
		indicator.offset = offset
	end
end

vgui.Register("PA_Construct_ListView", CONSTRUCT_LISTVIEW, "DListView")