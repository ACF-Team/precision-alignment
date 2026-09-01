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