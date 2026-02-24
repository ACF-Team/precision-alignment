local MOVE_BUTTON = {}
function MOVE_BUTTON:SetFunction( func )
	self.DoClick = function()
		-- Alt to bring up stack number query
		local alt = LocalPlayer():KeyDown( IN_WALK )
		if alt then
			vgui.Create( "PA_Stack_Popup" )
			return
		end

		local ret = func()
		if ret == true then
			PrecisionAlign.PlaySoundTrue()
		elseif ret == false then
			PrecisionAlign.PlaySoundFalse()
		end
	end
end

function MOVE_BUTTON:SetHoverFunction(Hover, HoverEnter, HoverExit, ...)
	local WasHovering = false
	local HoverStartTime = RealTime()
	hook.Add("Think", self, function()
		local Hovering = vgui.GetHoveredPanel() == self
		if Hovering and not WasHovering and HoverEnter then
			HoverStartTime = RealTime()
			HoverEnter(self, HoverStartTime)
		end

		if Hovering and Hover then Hover(self, RealTime() - HoverStartTime) end

		if not Hovering and WasHovering and HoverExit then
			HoverExit(self, RealTime() - HoverStartTime)
			HoverStartTime = 0
		end
		WasHovering = Hovering
	end)
end

function MOVE_BUTTON:Think()
	local locPly = LocalPlayer()
	local alt = locPly:KeyDown( IN_WALK )
	local shift = locPly:KeyDown( IN_SPEED )

	if alt and not self.OldText then
		self.OldText = self:GetText()
		self:SetText("(ALT) Stacking\nOptions")
	elseif shift and not self.OldText then
		self.OldText = self:GetText()
		self:SetText("(SHIFT) Stack Entity")
	elseif not alt and not shift and self.OldText then
		self:SetText(self.OldText)
		self.OldText = nil
	end

	if IsValid(PrecisionAlign.ActiveEnt) and self:GetDisabled() then
		self:SetDisabled(false)
	elseif not IsValid(PrecisionAlign.ActiveEnt) and not self:GetDisabled() then
		self:SetDisabled(true)
	end
end

vgui.Register("PA_Move_Button", MOVE_BUTTON, "DButton")