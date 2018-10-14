Forge._TargetTracker = {}

function Forge._TargetTracker:Construct(pTargetName, pNotifyFunc, pNotifyParam)
	self.TargetName = pTargetName
	self.TrackingUnitID = nil
	self.NotifyFunc = pNotifyFunc
	self.NotifyParam = pNotifyParam
	self.TargetIsInCombat = false
	self.TargetLostCombatTime = nil
	self.PlayerIsInCombat = false
	
	self.Health = 0
	self.HealthMax = 0
	self.Mana = 0
	self.ManaMax = 0
end

function Forge._TargetTracker:StartTracking()
	self.TargetIsInCombat = false
	
	self.SchedulerLib:ScheduleRepeatingTask(0.25, self.Update, self)
end

function Forge._TargetTracker:StopTracking(pTargetName, pNotifyFunc, pNotifyParam)
	self.SchedulerLib:UnscheduleTask(self.Update, self)
end

function Forge._TargetTracker:Update()
	-- If there's no unit or the unit is no longer tracking the target
	-- then search for a new unit
	
	if not self.TrackingUnitID
	or not UnitExists(self.TrackingUnitID)
	or not UnitExists(self.TrackingUnitID.."target")
	or UnitName(self.TrackingUnitID.."target") ~= self.TargetName then
		local vUnitID = MCRaidLib:FindUnitWithTarget(self.TargetName)
		local vPresenceChanged = (vUnitID == nil) ~= (self.TrackingUnitID == nil)
		
		self.TrackingUnitID = vUnitID
		
		if vPresenceChanged and self.NotifyFunc then
			self.NotifyFunc(self.NotifyParam, self, "FOUND", vUnitID ~= nil)
		end
		
		if not self.TrackingUnitID then
			self:SetHealthMana(0, 0, 0, 0)
			return
		end
	end
	
	local vTargetUnitID = self.TrackingUnitID.."target"
	
	self:SetHealthMana(
		UnitHealth(vTargetUnitID),
		UnitHealthMax(vTargetUnitID),
		UnitPower(vTargetUnitID),
		UnitPowerMax(vTargetUnitID))
	
	local vTargetTargetUnitID = vTargetUnitID.."target"
	local vTargetName = UnitName(vTargetTargetUnitID)
	local vTargetIsInCombat = vTargetName ~= nil and MCRaidLib.Players[vTargetName] ~= nil
	
	-- If the target was in combat but no longer appears to have a target, force a 
	-- delay before we're sure he's left combat
	
	if vTargetIsInCombat then
		self.TargetLostCombatTime = nil
	elseif self.TargetIsInCombat
	and UnitAffectingCombat(vTargetUnitID) then
		vTargetIsInCombat = true
	elseif self.TargetIsInCombat then
		if not self.TargetLostCombatTime then
			self.TargetLostCombatTime = GetTime()
			vTargetIsInCombat = true
		elseif (GetTime() - self.TargetLostCombatTime) < 5 then
			vTargetIsInCombat = true
		end
	end
	
	-- If the target is in combat then consider the player in combat, otherwise if the raid is out
	-- of combat then don't count the player as in combat anymore
	
	if vTargetIsInCombat then
		self.PlayerIsInCombat = true
	elseif not MCRaidLib.PlayerInCombat then
		self.PlayerIsInCombat = false
	end
	
	-- Force the target as in combat if the player is in combat to prevent false triggers
	-- from stuns/fears/etc
	
	if not vTargetIsInCombat
	and self.PlayerIsInCombat then
		vTargetIsInCombat = true
	end
	
	-- Notify clients when the target enters or leaves combat
	
	if self.TargetIsInCombat ~= vTargetIsInCombat then
		self.TargetIsInCombat = vTargetIsInCombat
		
		if self.NotifyFunc then
			self.NotifyFunc(self.NotifyParam, self, "COMBAT", vTargetIsInCombat)
		end
	end
	
	-- Notify clients if the target canges
	
	if self.TrackingUnitID then
		local vTargetTargetName = UnitName(self.TrackingUnitID.."targettarget")
		
		if vTargetTargetName ~= self.TargetTargetName then
			self.TargetTargetName = vTargetTargetName
			
			if self.NotifyFunc then
				self.NotifyFunc(self.NotifyParam, self, "TARGET_CHANGED", vTargetTargetName)
			end
		end
	else
		self.TargetTargetName = nil
	end
end

function Forge._TargetTracker:SetHealthMana(pHealth, pHealthMax, pMana, pManaMax)
	if self.Health == pHealth
	and self.HealthMax == pHealthMax
	and self.Mana == pMana
	and self.ManaMax == pManaMax then
		return
	end
	
	self.Health = pHealth
	self.HealthMax = pHealthMax
	self.Mana = pMana
	self.ManaMax = pManaMax
	
	if self.NotifyFunc then
		self.NotifyFunc(self.NotifyParam, self, "HEALTHMANA", true)
	end
end
