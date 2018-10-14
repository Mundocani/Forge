Forge.TimerBars = {}

function Forge.TimerBars:Initialize()
	self.ActiveTimerBars = {}
	self.FreeTimerBars = {}
	self.AnimatingTimerBars = {}
end

function Forge.TimerBars:Test()
	local vTimerInfo =
	{
		Label = "Fear",
		
		Duration = 30,
		WarningTime = 10,
		WarningSound = "Sound\\Doodad\\G_HornofEcheyakee.wav",
		
		--AutoRestart = true,
	}
	
	self:NewTimer("TIMER_TEST", vTimerInfo, GetTime())
	
	Forge.WarningMessage:ShowMessage("This is a note", nil, "NOTE", "This is subtext")
end

function Forge.TimerBars:NewTimer(pTimerID, pTimerInfo, pTime, pLabelParams, pActionFunc, pActionFuncParam)
	local vTimerBar
	
	if pTimerID then
		vTimerBar = self:FindTimerByID(pTimerID)
	end
	
	if not vTimerBar then
		if #self.FreeTimerBars > 0 then
			vTimerBar = table.remove(self.FreeTimerBars, #self.FreeTimerBars)
		else
			vTimerBar = Forge:New(Forge._TimerBar)
		end
		
		if #self.ActiveTimerBars == 0 then
			Forge.SchedulerLib:ScheduleRepeatingTask(0.1, self.UpdateTimers, self)
		end
		
		table.insert(self.ActiveTimerBars, vTimerBar)
	end
	
	vTimerBar:StartTimer(pTimerID, pTimerInfo, pTime, pLabelParams, pActionFunc, pActionFuncParam)
	
	self:StackTimers()
	
	return vTimerBar
end

function Forge.TimerBars:NewProgress(pTimerID, pLabel, pColor)
	local vTimerBar
	
	if pTimerID then
		vTimerBar = self:FindTimerByID(pTimerID)
	end
	
	if not vTimerBar then
		if #self.FreeTimerBars > 0 then
			vTimerBar = table.remove(self.FreeTimerBars, #self.FreeTimerBars)
		else
			vTimerBar = Forge:New(Forge._TimerBar)
		end
		
		if #self.ActiveTimerBars == 0 then
			Forge.SchedulerLib:ScheduleRepeatingTask(0.1, self.UpdateTimers, self)
		end
		
		table.insert(self.ActiveTimerBars, vTimerBar)
	end
	
	vTimerBar:StartProgress(pTimerID, pLabel, pColor)
	
	self:StackTimers()
	
	return vTimerBar
end

function Forge.TimerBars:DeleteAllTimers()
	while #self.ActiveTimerBars > 0 do
		self:DeleteBar(self.ActiveTimerBars[1])
	end
end

function Forge.TimerBars:DeleteBar(pTimerBar)
	pTimerBar:Delete()
	
	for vIndex, vTimerBar in ipairs(self.ActiveTimerBars) do
		if vTimerBar == pTimerBar then
			table.remove(self.ActiveTimerBars, vIndex)
			break
		end
	end
	
	if #self.ActiveTimerBars == 0 then
		Forge.SchedulerLib:UnscheduleTask(self.UpdateTimers, self)
	end
end

function Forge.TimerBars:FindTimerByID(pTimerID)
	for vIndex, vTimerBar in ipairs(self.ActiveTimerBars) do
		if vTimerBar.ID == pTimerID then
			return vTimerBar
		end
	end
end

function Forge.TimerBars:DeleteByID(pTimerID)
	local vTimerBar = self:FindTimerByID(pTimerID)
	
	if not vTimerBar then
		return
	end
	
	vTimerBar:Delete()
end

function Forge.TimerBars:UpdateTimers(pTime)
	for vIndex, vTimerBar in ipairs(self.ActiveTimerBars) do
		vTimerBar:Update(pTime)
	end
end

function Forge.TimerBars:StartAnimating(pTimerBar)
	if not self.AnimatingTimerBars[self] then
		if not next(self.AnimatingTimerBars) then
			Forge.SchedulerLib:ScheduleRepeatingTask(0, self.AnimateTimers, self)
		end
		
		self.AnimatingTimerBars[pTimerBar] = pTimerBar
	end
end

function Forge.TimerBars:StopAnimating(pTimerBar)
	self.AnimatingTimerBars[pTimerBar] = nil
	
	if not next(self.AnimatingTimerBars) then
		Forge.SchedulerLib:UnscheduleTask(self.AnimateTimers, self)
	end
end

function Forge.TimerBars:AnimateTimers(pTime)
	for _, vTimerBar in pairs(self.AnimatingTimerBars) do
		vTimerBar:Animate(pTime)
	end
end

function Forge.TimerBars:StackTimers()
	table.sort(self.ActiveTimerBars, Forge._TimerBar.Compare)
	
	local vSpacing = 40
	
	local vScreenHeight = UIParent:GetHeight()
	local vPosition = -vScreenHeight * 0.3
	local vWarningPosition = -vScreenHeight * 0.7
	
	local vStackingTop = true
	
	for vIndex, vTimerBar in ipairs(self.ActiveTimerBars) do
		vTimerBar:ClearAllPoints()
		
		if (vTimerBar.IsWarning or vTimerBar.IsProgress)
		and vStackingTop then
			vPosition = vWarningPosition
			vStackingTop = false
		end
		
		vTimerBar:MoveToPosition(vPosition)
		vPosition = vPosition - vSpacing
		
		vTimerBar:Show()
	end
end

----------------------------------------
Forge._TimerBar = {}
----------------------------------------

function Forge._TimerBar:New()
	return CreateFrame("StatusBar", nil, UIParent)
end

function Forge._TimerBar:Construct()
	self:SetWidth(250)
	self:SetHeight(13)
	
	self:SetFrameStrata("BACKGROUND")
	
	self.BackgroundTexture = self:CreateTexture(nil, "BACKGROUND")
	self.BackgroundTexture:SetAllPoints()
	self.BackgroundTexture:SetTexture(0, 0, 0, 0.5)
	
	self.BorderTexture = self:CreateTexture(nil, "BORDER")
	self.BorderTexture:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
	self.BorderTexture:SetWidth(334)
	self.BorderTexture:SetHeight(66)
	self.BorderTexture:SetPoint("TOP", self, "TOP", 0, 26)
	
	self.SparkTexture = self:CreateTexture(nil, "ARTWORK")
	self.SparkTexture:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	self.SparkTexture:SetBlendMode("ADD")
	self.SparkTexture:SetWidth(32)
	self.SparkTexture:SetHeight(32)
	self.SparkTexture:SetPoint("CENTER", self, "CENTER", 0, 0)
	
	self.FlashTexture = self:CreateTexture(nil, "ARTWORK")
	self.FlashTexture:Hide()
	self.FlashTexture:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash")
	self.FlashTexture:SetBlendMode("ADD")
	self.FlashTexture:SetWidth(334)
	self.FlashTexture:SetHeight(66)
	self.FlashTexture:SetPoint("TOP", self, "TOP", 0, 26)
	
	self.LabelText = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	self.LabelText:SetPoint("RIGHT", self, "LEFT", -15, 1)
	
	self.RemainingFrame = CreateFrame("Frame", nil, self)
	self.RemainingFrame:SetWidth(48)
	self.RemainingFrame:SetHeight(25)
	self.RemainingFrame:SetPoint("CENTER", self, "CENTER")
	
	self.RemainingFrame.BackgroundTexture = self.RemainingFrame:CreateTexture(nil, "BACKGROUND")
	self.RemainingFrame.BackgroundTexture:SetAllPoints()
	self.RemainingFrame.BackgroundTexture:SetTexture(0, 0, 0, 0.55)
	
	self.RemainingFrame.BorderTexture = self.RemainingFrame:CreateTexture(nil, "BORDER")
	self.RemainingFrame.BorderTexture:SetTexture("Interface\\Addons\\ForgeWay\\Textures\\CountdownFrame")
	self.RemainingFrame.BorderTexture:SetWidth(64)
	self.RemainingFrame.BorderTexture:SetHeight(64)
	self.RemainingFrame.BorderTexture:SetPoint("CENTER", self.RemainingFrame, "CENTER")
	
	self.RemainingFrame.WholeText = self.RemainingFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	self.RemainingFrame.WholeText:SetPoint("CENTER", self.RemainingFrame, "CENTER")
	
	self:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	self:SetStatusBarColor(1, 0.7, 0)
end

function Forge._TimerBar:StartTimer(pTimerID, pTimerInfo, pTime, pLabelParams, pActionFunc, pActionFuncParam)
	self.IsProgress = nil
	self.ID = pTimerID
	self.TimerInfo = pTimerInfo
	self.StartTime = pTime
	
	self.BarValue = pTimerInfo.Duration
	self.MaxBarValue = pTimerInfo.Duration
	
	self.LabelText:SetText(string.gsub(pTimerInfo.Label, "%$(%w+)", pLabelParams))
	self:SetMinMaxValues(0, pTimerInfo.Duration)
	
	if pTimerInfo.Color then
		self:SetStatusBarColor(pTimerInfo.Color.r, pTimerInfo.Color.g, pTimerInfo.Color.b)
	else
		self:SetStatusBarColor(1, 0.7, 0)
	end
	
	self.AnimatingPosition = nil
	self.IsWarning = false
	self:SetPosition(40)
	
	self.ActionFunc = pActionFunc
	self.ActionFuncParam = pActionFuncParam
	
	self:Update(pTime)
end

function Forge._TimerBar:StartProgress(pTimerID, pLabel, pColor)
	self.IsProgress = true
	self.ID = pTimerID
	self.TimerInfo = nil
	
	self.BarValue = 0
	self.MaxBarValue = 100
	
	self.LabelText:SetText(pLabel)
	self:SetMinMaxValues(0, 100)
	
	local vColor = pColor
	
	if pColor then
		self:SetStatusBarColor(pColor.r, pColor.g, pColor.b)
	else
		self:SetStatusBarColor(0, 1, 0)
	end
	
	self.AnimatingPosition = nil
	self.IsWarning = false
	self:SetPosition(40)
end

function Forge._TimerBar:Start(pStartTime)
	self.StartTime = pStartTime
	
	self.IsWarning = false
	self:SetPosition(40)
	
	self:Update(pStartTime)
end

function Forge._TimerBar:Delete()
	self.AnimatingPosition = nil
	self.IsWarning = false
	self.Flashing = false
	self:StopAnimating()
	
	self.ActionFunc = nil
	self.ActionFuncParam = nil
	
	self:Hide()
end

function Forge._TimerBar:SetBarValue(pValue, pText)
	self.BarValue = pValue
	
	self:SetValue(pValue)
	
	-- Update the spark position
	
	local vSparkPosition = self:GetWidth() * pValue / self.MaxBarValue
	
	self.SparkTexture:SetPoint("CENTER", self, "LEFT", vSparkPosition, 0)
	
	if pText then
		self.RemainingFrame.WholeText:SetText(pText)
	else
		self.RemainingFrame.WholeText:SetText(pValue)
	end
end

function Forge._TimerBar:Update(pTime)
	if self.IsProgress then	
		return
	end
	
	local vElapsed = pTime - self.StartTime
	
	self.Remaining = self.TimerInfo.Duration - vElapsed
	
	if not self.IsWarning
	and self.Remaining <= self.TimerInfo.WarningTime then
		self.IsWarning = true
		
		if self.TimerInfo.WarningSound then
			PlaySoundFile(self.TimerInfo.WarningSound)
		end
		
		if self.TimerInfo.WarningActions then
			self.ActionFunc(self.ActionFuncParam, self.TimerInfo.WarningActions, nil, self.StartTime + self.TimerInfo.Duration - self.TimerInfo.WarningTime)
		end
		
		self:StartFlashing(pTime)
		
		Forge.TimerBars:StackTimers()
	end
	
	if self.Remaining <= 0 then
		if self.ActionFunc
		and self.TimerInfo.ExpirationActions then
			self.ActionFunc(self.ActionFuncParam, self.TimerInfo.ExpirationActions, nil, self.StartTime + self.TimerInfo.Duration)
		end
		
		if self.TimerInfo.AutoRestart then
			self:Start(self.StartTime + (self.TimerInfo.RestartDuration or self.TimerInfo.Duration))
		else
			Forge.TimerBars:DeleteBar(self)
		end
	else
		local vWholeSecondsRemaining = math.ceil(self.Remaining)
		local vWholeMinutesRemaining = math.floor(vWholeSecondsRemaining / 60)
		
		vWholeSecondsRemaining = vWholeSecondsRemaining - (vWholeMinutesRemaining * 60)
		
		local vText
		
		if vWholeMinutesRemaining > 0 then
			vText = string.format("%d:%02d", vWholeMinutesRemaining, vWholeSecondsRemaining)
		else
			vText = vWholeSecondsRemaining
		end
		
		self:SetBarValue(self.Remaining, vText)
	end
end

function Forge._TimerBar:Animate(pTime)
	if self.AnimatingPosition then
		local vElapsed = pTime - self.StartPositionTime
		local vFraction = vElapsed / self.PositionDuration
		
		if vFraction >= 1 then
			self:SetPosition(self.EndPositionY)
			self.AnimatingPosition = false
			self:StopAnimating()
		else
			self:SetPosition((self.EndPositionY - self.StartPositionY) * vFraction + self.StartPositionY)
		end
	end
	
	if self.IsFlashing then
		self:UpdateFlashing(pTime)
	end
end

function Forge._TimerBar:StartFlashing(pTime)
	self.Flashing = true
	self.FlashTexture:Show()
	self.FlashIn = true
	self.FlashStartTime = pTime
	
	self:StartAnimating()
end

function Forge._TimerBar:StopFlashing()
	self.Flashing = false
	self:StopAnimating()
end

function Forge._TimerBar:UpdateFlashing(pTime)
	local vElapsed = pTime - self.FlashStartTime
	local vPercent = vElapsed / 0.5
	
	if vPercent > 1 then
		vPercent = 1
	end
	
	if self.FlashIn then
		self.FlashTexture:SetAlpha(vPercent)
	else
		self.FlashTexture:SetAlpha(1 - vPercent)
	end
	
	if vPercent >= 1 then
		self.FlashIn = not self.FlashIn
		self.FlashStartTime = pTime - (vElapsed - 0.5)
	end
end

function Forge._TimerBar:SetPosition(pPositionY)
	self.PositionY = pPositionY
	self:SetPoint("TOP", UIParent, "TOP", 0, pPositionY)
end

function Forge._TimerBar:MoveToPosition(pPositionY)
	self.AnimatingPosition = true
	self.StartPositionY = self.PositionY
	self.EndPositionY = pPositionY
	self.StartPositionTime = GetTime()
	self.PositionDuration = 0.5
	
	self:StartAnimating()
end

function Forge._TimerBar:StartAnimating()
	Forge.TimerBars:StartAnimating(self)
end

function Forge._TimerBar:StopAnimating()
	if self.AnimatingPosition
	or self.IsFlashing then
		return
	end
	
	Forge.TimerBars:StopAnimating(self)
end

function Forge._TimerBar:Compare(pTimerFrame)
	if self.IsProgress ~= pTimerFrame.IsProgress then
		return not self.IsProgress
	end
	
	if self.IsProgress then
		return self.Value > pTimerFrame.Value
	end
	
	if self.IsWarning ~= pTimerFrame.IsWarning then
		return not self.IsWarning
	end
	
	if self.IsWarning then
		return self.Remaining < pTimerFrame.Remaining
	else
		return self.Remaining > pTimerFrame.Remaining
	end
end

function Forge._TimerBar:ClampTimer(pMinTime, pMaxTime, pTime)
	local vElapsed = pTime - self.StartTime
	local vRemaining = self.TimerInfo.Duration - vElapsed

	if pMinTime and vRemaining < pMinTime then
		local vPadding = pMinTime - vRemaining
		
		self.StartTime = self.StartTime + vPadding
		
		if self.IsWarning and pMinTime > self.TimerInfo.WarningTime then
			self.IsWarning = false
			UIFrameFlashStop(self.Flash)
			self.Flash:Hide()
		end
		
	elseif pMaxTime and vRemaining > pMaxTime then
		local vPadding = vRemaining - pMaxTime
		
		self.StartTime = self.StartTime - vPadding
	else
		return
	end
	
	self:Update(pTime)
	
	Forge.TimerBars:StackTimers()
end

Forge.EventLib:RegisterCustomEvent("FORGE_INIT", Forge.TimerBars.Initialize, Forge.TimerBars)
