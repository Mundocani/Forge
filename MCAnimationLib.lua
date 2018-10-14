MCAddon.AnimationLib =
{
	Version = 1,
	Animations = {},
	SortAnimations = false,
	InUpdate = false,
	Actions = {},
	Time = 0,
	Addon = MCAddon
}

function MCAddon.AnimationLib:Update(pTime)
	if self.InUpdate then
		return
	end
	
	self.InUpdate = true
	self.Time = pTime
	
	while true do
		if self.SortAnimations then
			table.sort(self.Animations, function (pSeq1, pSeq2) if not pSeq1.NextUpdateTime then return pSeq2.NextUpdateTime ~= nil; end; if not pSeq2.NextUpdateTime then return false; end; return pSeq1.NextUpdateTime < pSeq2.NextUpdateTime; end)
			self.SortAnimations = false
		end
		
		if not next(self.Animations) then
			MCSchedulerLib:UnscheduleTask(self.Update, self)
			break
		end
		
		local vAnimationData = self.Animations[1]
		
		if not vAnimationData.NextUpdateTime
		or self.Time >= vAnimationData.NextUpdateTime then
			if vAnimationData.UpdateInterval and vAnimationData.UpdateInterval > 0 then
				vAnimationData.NextUpdateTime = self.Time + vAnimationData.UpdateInterval
			else
				vAnimationData.NextUpdateTime = self.Time + 0.01
			end
			
			self:CallAnimation("UPDATE", vAnimationData)
			self.SortAnimations = true
		else
			MCSchedulerLib:UnscheduleTask(self.Update, self)
			MCSchedulerLib:ScheduleTask(vAnimationData.NextUpdateTime - self.Time, self.Update, self)
			break
		end
	end

	self.InUpdate = false
end

function MCAddon.AnimationLib:StartAnimation(pFrames, pAnimation, pTime)
	if pTime then
		self.Time = pTime
	else
		self.Time = GetTime()
	end
	
	local vAnimationData =
	{
		Animation = pAnimation,
		Frames = pFrames,
		StartTime = self.Time,
	}
	
	self:CallAnimation("NEW", vAnimationData)
	
	self:ResumeAnimation(vAnimationData)
	
	return vAnimationData
end

function MCAddon.AnimationLib:StopAnimation(pFrame, pAnimation)
	local vIndex = 1
	local vNumAnimations = #self.Animations
	
	while vIndex <= vNumAnimations do
		if self.Animations[vIndex].Frames == pFrame
		and self.Animations[vIndex].Animation == pAnimation then
			self:EndAnimation(self.Animations[vIndex])
			vNumAnimations = #self.Animations
		else
			vIndex = vIndex + 1
		end
	end
end

function MCAddon.AnimationLib:StopFrameAnimations(pFrame)
	local vIndex = 1
	local vNumAnimations = #self.Animations
	
	while vIndex <= vNumAnimations do
		if self.Animations[vIndex].Frames == pFrame then
			self:EndAnimation(self.Animations[vIndex])
			vNumAnimations = #self.Animations
		else
			vIndex = vIndex + 1
		end
	end
end

function MCAddon.AnimationLib:SuspendAnimation(pAnimationData)
	self:RemoveAnimation(pAnimationData)
end

function MCAddon.AnimationLib:ResumeAnimation(pAnimationData)
	table.insert(self.Animations, pAnimationData)
	self.SortAnimations = true
	
	self:Update(self.Time)
end

function MCAddon.AnimationLib:RemoveAnimation(pAnimationData)
	for vIndex, vAnimationData in ipairs(self.Animations) do
		if vAnimationData == pAnimationData then
			table.remove(self.Animations, vIndex)
			return
		end
	end
end

function MCAddon.AnimationLib:EndAnimation(pAnimationData)
	self:RemoveAnimation(pAnimationData)
	
	if pAnimationData.ParentAnimation then
		self:ResumeAnimation(pAnimationData.ParentAnimation)
		pAnimationData.ParentAnimation = nil
	end
end

function MCAddon.AnimationLib:CallAnimation(pOpcode, pAnimationData)
	local vActionFunc = self.Actions[pAnimationData.Animation.Action]
	
	if not vActionFunc then
		self:EndAnimation(pAnimationData)
		return
	end
	
	return vActionFunc(self, pOpcode, pAnimationData)
end

function MCAddon.AnimationLib.Actions:Sequence(pOpcode, pAnimationData)
	if pOpcode == "NEW" then
		pAnimationData.Index = 0
		pAnimationData.Count = 1
	elseif pOpcode == "DELETE" then
		--
	elseif pOpcode == "UPDATE" then
		while true do
			pAnimationData.Index = pAnimationData.Index + 1
			
			if pAnimationData.Index > #pAnimationData.Animation.Actions then
				pAnimationData.Index = 1
				pAnimationData.Count = pAnimationData.Count + 1
				
				if not pAnimationData.Animation.Repeat
				or pAnimationData.Count > pAnimationData.Animation.Repeat then
					self:EndAnimation(pAnimationData)
					break
				end
			end
			
			local vAction = pAnimationData.Animation.Actions[pAnimationData.Index]
			local vAnimationData = self:StartAnimation(pAnimationData.Frames, vAction, self.Time)
			
			if not vAction.Asynch then
				vAnimationData.ParentAnimation = pAnimationData
				self:SuspendAnimation(pAnimationData)
				break
			end
		end -- while true
	end -- UPDATE
end

function MCAddon.AnimationLib.Actions:FlashFrame(pOpcode, pAnimationData)
	if pOpcode == "UPDATE" then
		--Forge:TestMessage("UIFrameFlashStop(%s)", tostring(pAnimationData.Frames))
		UIFrameFlashStop(pAnimationData.Frames)
		
		local vFadeInTime = pAnimationData.Animation.FadeInTime
		
		if not vFadeInTime then
			vFadeInTime = 0
		end
		
		local vFadeOutTime = pAnimationData.Animation.FadeOutTime
		
		if not vFadeOutTime then
			vFadeOutTime = 0
		end
		
		local vHoldHiddenTime = pAnimationData.Animation.HoldHiddenTime
		
		if not vHoldHiddenTime then
			vHoldHiddenTime = 0
		end
		
		local vHoldShownTime = pAnimationData.Animation.HoldShownTime
		
		if not vHoldShownTime then
			vHoldShownTime = 0
		end
		
		local vRepeatCount = pAnimationData.Animation.RepeatCount
		
		if not vRepeatCount then
			vRepeatCount = 1
		end
		
		local vCycleTime = vFadeInTime + vHoldShownTime + vFadeOutTime + vHoldHiddenTime
		local vDuration
		
		if pAnimationData.Animation.ShowWhenDone then
			vDuration = vCycleTime * vRepeatCount + vFadeInTime
		else
			vDuration = vCycleTime * vRepeatCount
		end
		
		pAnimationData.Frames:Show()
		pAnimationData.Frames:SetAlpha(0)
		--Forge:TestMessage("UIFrameFlash(%s, %s, %s, %s, %s, %s, %s)", tostring(pAnimationData.Frames), tostring(vFadeInTime), tostring(vFadeOutTime), tostring(vDuration), tostring(pAnimationData.Animation.ShowWhenDone), tostring(vHoldShownTime), tostring(vHoldHiddenTime))
		UIFrameFlash(pAnimationData.Frames, vFadeInTime, vFadeOutTime, vDuration, pAnimationData.Animation.ShowWhenDone, vHoldShownTime, vHoldHiddenTime)
		
		self:EndAnimation(pAnimationData)
	end
end

function MCAddon.AnimationLib.Actions:SetScale(pOpcode, pAnimationData)
	if pOpcode == "NEW" then
		pAnimationData.StartScale = pAnimationData.Frames:GetScale()
		
		if pAnimationData.Animation.AbsoluteScale then
			pAnimationData.ScaleFactor = 1 / pAnimationData.Frames:GetParent():GetEffectiveScale()
			pAnimationData.StartScale = pAnimationData.StartScale / pAnimationData.ScaleFactor
		else
			pAnimationData.ScaleFactor = 1
		end
		
	elseif pOpcode == "UPDATE" then
		local vElapsed = self.Time - pAnimationData.StartTime
		
		if not pAnimationData.Animation.Duration
		or vElapsed >= pAnimationData.Animation.Duration then
			pAnimationData.Frames:SetScale(pAnimationData.Animation.Value * pAnimationData.ScaleFactor)
			self:EndAnimation(pAnimationData)
			return
		end
		
		local vTimeFactor = vElapsed / pAnimationData.Animation.Duration
		
		local vScale = pAnimationData.StartScale + vTimeFactor * (pAnimationData.Animation.Value - pAnimationData.StartScale)
		
		pAnimationData.Frames:SetScale(vScale * pAnimationData.ScaleFactor)
	end
end

function MCAddon.AnimationLib.Actions:LerpValue(pOpcode, pAnimationData)
	if pOpcode == "NEW" then
		pAnimationData.StartValue = pAnimationData.Animation.Function(pAnimationData.Frames, "GET_VALUE")
		
	elseif pOpcode == "UPDATE" then
		local vElapsed = self.Time - pAnimationData.StartTime
		
		if not pAnimationData.Animation.Duration
		or vElapsed >= pAnimationData.Animation.Duration then
			pAnimationData.Animation.Function(pAnimationData.Frames, "SET_VALUE", pAnimationData.Animation.Value)
			self:EndAnimation(pAnimationData)
			return
		end
		
		local vTimeFactor = vElapsed / pAnimationData.Animation.Duration
		local vValue = pAnimationData.StartValue + vTimeFactor * (pAnimationData.Animation.Value - pAnimationData.StartValue)
		
		pAnimationData.Animation.Function(pAnimationData.Frames, "SET_VALUE", vValue)
	end
end

function MCAddon.AnimationLib.Actions:LerpValue2(pOpcode, pAnimationData)
	if pOpcode == "NEW" then
		pAnimationData.StartValue1, pAnimationData.StartValue2 = pAnimationData.Animation.Function(pAnimationData.Frames, "GET_VALUE")
		
	elseif pOpcode == "UPDATE" then
		local vElapsed = self.Time - pAnimationData.StartTime
		
		if not pAnimationData.Animation.Duration
		or vElapsed >= pAnimationData.Animation.Duration then
			pAnimationData.Animation.Function(pAnimationData.Frames, "SET_VALUE", pAnimationData.Animation.Value1, pAnimationData.Animation.Value2)
			self:EndAnimation(pAnimationData)
			return
		end
		
		local vTimeFactor = vElapsed / pAnimationData.Animation.Duration
		local vValue1 = pAnimationData.StartValue1 + vTimeFactor * (pAnimationData.Animation.Value1 - pAnimationData.StartValue1)
		local vValue2 = pAnimationData.StartValue2 + vTimeFactor * (pAnimationData.Animation.Value2 - pAnimationData.StartValue2)
		
		pAnimationData.Animation.Function(pAnimationData.Frames, "SET_VALUE", vValue1, vValue2)
	end
end

function MCAddon.AnimationLib.Actions:SetTextHeight(pOpcode, pAnimationData)
	if pOpcode == "NEW" then
		pAnimationData.StartHeight = 12
		
		if pAnimationData.Animation.AbsoluteScale then
			pAnimationData.ScaleFactor = 1 / pAnimationData.Frames:GetParent():GetEffectiveScale()
			pAnimationData.StartHeight = pAnimationData.StartHeight / pAnimationData.ScaleFactor
		else
			pAnimationData.ScaleFactor = 1
		end
		
	elseif pOpcode == "UPDATE" then
		local vElapsed = self.Time - pAnimationData.StartTime
		
		if not pAnimationData.Animation.Duration
		or vElapsed >= pAnimationData.Animation.Duration then
			pAnimationData.Frames:SetTextHeight(pAnimationData.Animation.Value * pAnimationData.ScaleFactor)
			self:EndAnimation(pAnimationData)
			return
		end
		
		local vTimeFactor = vElapsed / pAnimationData.Animation.Duration
		
		local vScale = pAnimationData.StartHeight + vTimeFactor * (pAnimationData.Animation.Value - pAnimationData.StartHeight)
		
		pAnimationData.Frames:SetTextHeight(vScale * pAnimationData.ScaleFactor)
	end
end

function MCAddon.AnimationLib.Actions:SetPosition(pOpcode, pAnimationData)
end

function MCAddon.AnimationLib.Actions:Delay(pOpcode, pAnimationData)
	if pOpcode == "NEW" then
		pAnimationData.NextUpdateTime = self.Time + pAnimationData.Animation.Duration
	else
		self:EndAnimation(pAnimationData)
	end
end
