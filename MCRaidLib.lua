local gMCRaidLib_Version = 3

if not MCRaidLib or MCRaidLib.Version < gMCRaidLib_Version then
	if not MCRaidLib then
		MCRaidLib =
		{
			Version = gMCRaidLib_Version,
			NumPlayers = 0,
			Players = {},
			PlayersByUnitID = {},
			PlayerInCombat = false,
			PlayerInRaid = false,
		}
		
		MCDebugLib:InstallDebugger("MCRaidLib", MCRaidLib, {r=1,g=0.6,b=0.2})
		MCEventLib:InstallEventDispatcher(MCRaidLib)
	end
	
	if MCRaidLib.Version < gMCRaidLib_Version then
		MCEventLib:UnregisterAllEvents(nil, MCRaidLib)
		MCSchedulerLib:UnscheduleTask(MCRaidLib.Synchronize, MCRaidLib)
		MCEventLib:InstallEventDispatcher(MCRaidLib)
	end
	
	function MCRaidLib:Synchronize()
		-- Mark all existing players as unused
		
		for vPlayerName, vPlayerInfo in pairs(self.Players) do
			vPlayerInfo.Unused = true
		end
		
		-- Update/add members
		
		local vNumRaidMembers = GetNumGroupMembers()
		local vRaidLeaderZoneChanged = false
		
		self.NumPlayers = 0
		
		if vNumRaidMembers > 0 then
			if IsInRaid() and not self.PlayerInRaid then
				self.PlayerInRaid = true
				self:DispatchEvent("JOINED_RAID")
			end
			
			for vIndex = 1, vNumRaidMembers do
				local vName, vRank, vSubgroup, vLevel, vClass, vClassID, vZone, vOnline, vIsDead, vRole, vMasterLooter = GetRaidRosterInfo(vIndex)
				local vOffline = not vOnline
				
				if vName and vClassID then
					local vUnitID = "raid"..vIndex
					local vPlayerInfo, vNewPlayer = self:AddPlayer(vName, vClassID, vUnitID)
			
					self.NumPlayers = self.NumPlayers + 1
					
					if vNewPlayer then
						vPlayerInfo.Constructing = nil
						self:DispatchEvent("PLAYER_JOINED", vPlayerInfo)
					end
				end
			end
		else
			if self.PlayerInRaid then
				self.PlayerInRaid = false
				self:DispatchEvent("LEFT_RAID")
			end
			
			for vIndex = 0, MAX_PARTY_MEMBERS do
				local vUnitID = nil
				
				if vIndex == 0 then
					vUnitID = "player"
				elseif GetPartyMember(vIndex) then
					vUnitID = "party"..vIndex
				else
					vUnitID = nil
				end
				
				if vUnitID then
					local vName = UnitName(vUnitID)
					local _, vClassID = UnitClass(vUnitID)
					
					if vName and vClassID then
						local vPlayerInfo, vNewPlayer = self:AddPlayer(vName, vClassID, vUnitID)
						local vRank
						
						if GetNumGroupMembers() == 0 or UnitIsGroupLeader(vUnitID) then
							vRank = 2
						else
							vRank = 1
						end
						
						if vPlayerInfo.Rank ~= vRank then
							vPlayerInfo.Rank = vRank
							vPlayerInfo.StatusChanged = true
						end
						
						if vPlayerInfo.Party ~= 1 then
							vPlayerInfo.Party = 1
							vPlayerInfo.StatusChanged = true
						end
						
						self.NumPlayers = self.NumPlayers + 1

						if vNewPlayer then
							vPlayerInfo.Constructing = nil
							self:DispatchEvent("PLAYER_JOINED", vPlayerInfo)
						end
					end -- if vName and vClassID
				end -- if vUnitID
			end -- for vIndex
		end -- else
		
		-- Clear any unused players from the ID map
		
		for vUnitID, vPlayerInfo in pairs(self.PlayersByUnitID) do
			if vPlayerInfo.Unused or vPlayerInfo.UnitID ~= vUnitID then
				self.PlayersByUnitID[vUnitID] = nil
			end
		end
		
		-- Free any players who've left the raid
		
		for vPlayerName, vPlayerInfo in pairs(self.Players) do
			if vPlayerInfo.Unused then
				self.Players[vPlayerName] = nil
				self:NotifyUnit(vPlayerInfo, "UNIT_DELETED")
			else
				if vPlayerInfo.StatusChanged then
					self:NotifyUnit(vPlayerInfo, "STATUS_CHANGED")
					vPlayerInfo.StatusChanged = nil
				end
			end
		end
	end

	function MCRaidLib:AddPlayer(pPlayerName, pClassID, pUnitID)
		local vPlayerInfo = self.Players[pPlayerName]

		if vPlayerInfo then
			vPlayerInfo.Unused = nil
			
			if vPlayerInfo.UnitID ~= pUnitID then
				vPlayerInfo.UnitID = pUnitID
				self.PlayersByUnitID[pUnitID] = vPlayerInfo
				vPlayerInfo.StatusChanged = true
			end
			
			return vPlayerInfo, false
		else
			vPlayerInfo =
			{
				Name = pPlayerName,
				ClassID = pClassID,
				UnitID = pUnitID,
				Constructing = true,
			}
			
			self.Players[pPlayerName] = vPlayerInfo
			self.PlayersByUnitID[pUnitID] = vPlayerInfo
			
			return vPlayerInfo, true
		end
	end
	
	function MCRaidLib:Subscribe(pPlayerInfo, pFunction, pParam)
		if not pPlayerInfo.Subscribers then
			pPlayerInfo.Subscribers = {}
		end
		
		table.insert(pPlayerInfo.Subscribers, {Function = pFunction, Param = pParam})
	end

	function MCRaidLib:Unsubscribe(pPlayerInfo, pFunction, pParam)
		if not pPlayerInfo.Subscribers then
			pPlayerInfo.Subscribers = {}
		end
		
		for vIndex, vSubscriber in ipairs(pPlayerInfo.Subscribers) do
			if (pFunction == nil or pFunction == vSubscriber.Function)
			and (pParam == nil or pParam == vSubscriber.Param) then
				table.remove(pPlayerInfo.Subscribers, vIndex)
				return
			end
		end
	end

	function MCRaidLib:NotifyUnit(pPlayerInfo, ...)
		if not pPlayerInfo.Subscribers then
			return
		end
		
		for vIndex, vSubscriber in ipairs(pPlayerInfo.Subscribers) do
			vSubscriber.Function(vSubscriber.Param, pPlayerInfo, ...)
		end
	end

	function MCRaidLib:PlayerCombatStart()
		self.PlayerInCombat = true
		MCSchedulerLib:SetTaskInterval(1.5, self.Synchronize, self)
	end

	function MCRaidLib:PlayerCombatStop()
		self.PlayerInCombat = false
		MCSchedulerLib:SetTaskInterval(0.5, self.Synchronize, self)
	end

	function MCRaidLib:RaidInCombat()
		if self.PlayerInCombat then
			return true
		end
		
		for vPlayerName, vPlayerInfo in pairs(self.Players) do
			if UnitAffectingCombat(vPlayerInfo.UnitID) then
				return true
			end
		end
		
		return false
	end

	function MCRaidLib:FindUnitWithTarget(pTargetName)
		for vPlayerName, vPlayerInfo in pairs(self.Players) do
			if UnitExists(vPlayerInfo.UnitID)
			and UnitExists(vPlayerInfo.UnitID.."target")
			and UnitName(vPlayerInfo.UnitID.."target") == pTargetName then
				return vPlayerInfo.UnitID
			end
		end
		
		return nil
	end

	function MCRaidLib:PlayerIsLeader(pPlayerName)
		vPlayerInfo = self.Players[pPlayerName]
		
		return vPlayerInfo ~= nil and vPlayerInfo.Rank == 2
	end

	function MCRaidLib:PlayerIsAssistant(pPlayerName)
		vPlayerInfo = self.Players[pPlayerName]
		
		return vPlayerInfo ~= nil and vPlayerInfo.Rank == 1
	end
	
	MCEventLib:RegisterEvent("PLAYER_LOGIN", MCRaidLib.Synchronize, MCRaidLib, true)
	MCEventLib:RegisterEvent("GROUP_ROSTER_UPDATE", MCRaidLib.Synchronize, MCRaidLib, true)
	MCEventLib:RegisterEvent("PARTY_LEADER_CHANGED", MCRaidLib.Synchronize, MCRaidLib, true)

	-- Combat

	MCEventLib:RegisterEvent("PLAYER_ENTERING_WORLD", MCRaidLib.PlayerCombatStop, MCRaidLib, true)
	MCEventLib:RegisterEvent("PLAYER_REGEN_ENABLED", MCRaidLib.PlayerCombatStop, MCRaidLib, true)
	MCEventLib:RegisterEvent("PLAYER_REGEN_DISABLED", MCRaidLib.PlayerCombatStart, MCRaidLib, true)

	MCSchedulerLib:ScheduleRepeatingTask(2, MCRaidLib.Synchronize, MCRaidLib)

	MCRaidLib:Synchronize()
end	
