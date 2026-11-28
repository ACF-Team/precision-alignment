local MIN_BOUNDS = MIN_COORD_FLOAT or -50000
local MAX_BOUNDS = MAX_COORD_FLOAT or 50000

local XYZ_SLIDER = {}
function XYZ_SLIDER:Init()
	--self:SetSize(130, 100) -- Keep the second number at 100
	--self:SetWide(200)
	self:SetMinMax( MIN_BOUNDS, MAX_BOUNDS )
	self:SetDecimals( 3 )
	self:SetValue( 0 )

	-- This is so we can identify the slider belongs to PA, so we can hook keyboard focus
	self:GetTextArea().Type = "PA"
end

vgui.Register("PA_XYZ_Slider", XYZ_SLIDER, "DNumSlider")