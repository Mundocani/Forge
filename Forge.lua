----------------------------------------
-- Forge
----------------------------------------

gForge_GlobalSettings = {}
gForge_CharacterSettings = {}

function Forge:Initialize()
	if self.Initialized then	
		return
	end
	
	self.Initialized = true
	
	Forge.CharacterSettings = gForge_CharacterSettings

	self.CharacterSettings = gForge_CharacterSettings
	self.GlobalSettings = gForge_GlobalSettings
	
	--
	-- Window stuff should be moved to ForgeUI
	--self.CharacterSettings.WindowSettings = self.WindowLib:VariablesLoaded(self.CharacterSettings.WindowSettings)
	
	-- Slash commands
	
	SlashCmdList.FORGE = function (...) Forge:ExecuteCommand(...) end
	SLASH_FORGE1 = "/forge"
	
	self:AddSlashCommand("help", self.ShowAllHelp, self, nil, "Shows this list")
	-- Window stuff should be moved to ForgeUI
	--self:AddSlashCommand("show", self.ShowMainWindow, self, nil, "Shows the main window")
	--self:AddSlashCommand("hide", self.HideMainWindow, self, nil, "Hides the main window")
	self:AddSlashCommand("id", self.IdentifyFramesUnderCursor, self, nil, "Identifies frames and regions under the mouse point")

	-- Create the main window
	-- Window stuff should be moved to ForgeUI
	--self.MainWindow = Forge._MainWindow:New()
	--self.MainWindow:Hide()
	
	--self.RaidLib:RegisterEvent("JOINED_RAID", self.PlayerJoinedRaid, self)
	--self.RaidLib:RegisterEvent("LEFT_RAID", self.PlayerLeftRaid, self)
	
	--
	
	self:NoteMessage("Use /forge for a list of commands")
	
	self.EventLib:DispatchEvent("FORGE_INIT")
end

----------------------------------------
-- Main window
----------------------------------------
--[[
function Forge:ShowMainWindow()
	self.MainWindow:Show()
end

function Forge:HideMainWindow()
	self.MainWindow:Hide()
end

function Forge:PlayerJoinedRaid()
	self:ShowMainWindow()
end

function Forge:PlayerLeftRaid()
	self:HideMainWindow()
end

----------------------------------------
Forge._MainWindow = {}
----------------------------------------

Forge._MainWindow._Inherits = Forge.WindowLib._SimpleWindowFrame

function Forge._MainWindow:New()
	return Forge.WindowLib:NewWindow("ForgeMainWindow", self, "Forge", UIParent, 300, 400)
end

function Forge._MainWindow:Construct()
	Forge.WindowLib._SimpleWindowFrame.Construct(self)
	
	self.HeaderBackground = Forge._SolidFrameBackground:New(self.ContentFrame)
	self.HeaderBackground:SetHeight(70)
	self.HeaderBackground:Show()
	
	self.ContentFrame:Stack(self.HeaderBackground, "TOP")
end

----------------------------------------
Forge._SolidFrameBackground = {}
----------------------------------------

function Forge._SolidFrameBackground:New(pParent)
	local vFrame = CreateFrame("Frame", nil, pParent)
	
	Forge.WindowLib:ConstructFrame(vFrame, self)
	
	return vFrame
end

Forge._SolidFrameBackground.cTextureWidth = 128
Forge._SolidFrameBackground.cTextureHeight = 32

Forge._SolidFrameBackground.cLeftWidth = 8
Forge._SolidFrameBackground.cRightWidth = 8
Forge._SolidFrameBackground.cTopHeight = 8
Forge._SolidFrameBackground.cBottomHeight = 8

Forge._SolidFrameBackground.cLeftOffset = 44

Forge._SolidFrameBackground.cHorizTexCoord0 = Forge._SolidFrameBackground.cLeftOffset / Forge._SolidFrameBackground.cTextureWidth
Forge._SolidFrameBackground.cHorizTexCoord1 = (Forge._SolidFrameBackground.cLeftOffset + Forge._SolidFrameBackground.cLeftWidth) / Forge._SolidFrameBackground.cTextureWidth
Forge._SolidFrameBackground.cHorizTexCoord2 = (Forge._SolidFrameBackground.cTextureWidth - Forge._SolidFrameBackground.cRightWidth) / Forge._SolidFrameBackground.cTextureWidth
Forge._SolidFrameBackground.cHorizTexCoord3 = 1

Forge._SolidFrameBackground.cVertTexCoord0 = 0
Forge._SolidFrameBackground.cVertTexCoord1 = Forge._SolidFrameBackground.cTopHeight / Forge._SolidFrameBackground.cTextureHeight
Forge._SolidFrameBackground.cVertTexCoord2 = (Forge._SolidFrameBackground.cTextureHeight - Forge._SolidFrameBackground.cBottomHeight) / Forge._SolidFrameBackground.cTextureHeight
Forge._SolidFrameBackground.cVertTexCoord3 = 1

function Forge._SolidFrameBackground:Construct()
	self.TopLeft = self:CreateTexture(nil, "BACKGROUND")
	self.TopLeft:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.TopLeft:SetTexCoord(self.cHorizTexCoord0, self.cHorizTexCoord1, self.cVertTexCoord0, self.cVertTexCoord1)
	self.TopLeft:SetWidth(self.cLeftWidth)
	self.TopLeft:SetHeight(self.cTopHeight)
	self.TopLeft:SetPoint("TOPLEFT", self, "TOPLEFT")
	
	self.BottomLeft = self:CreateTexture(nil, "BACKGROUND")
	self.BottomLeft:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.BottomLeft:SetTexCoord(self.cHorizTexCoord0, self.cHorizTexCoord1, self.cVertTexCoord2, self.cVertTexCoord3)
	self.BottomLeft:SetWidth(self.cLeftWidth)
	self.BottomLeft:SetHeight(self.cBottomHeight)
	self.BottomLeft:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
	
	self.Left = self:CreateTexture(nil, "BACKGROUND")
	self.Left:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.Left:SetTexCoord(self.cHorizTexCoord0, self.cHorizTexCoord1, self.cVertTexCoord1, self.cVertTexCoord2)
	self.Left:SetWidth(self.cLeftWidth)
	self.Left:SetPoint("TOPLEFT", self.TopLeft, "BOTTOMLEFT")
	self.Left:SetPoint("BOTTOMLEFT", self.BottomLeft, "TOPLEFT")
	
	self.TopRight = self:CreateTexture(nil, "BACKGROUND")
	self.TopRight:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.TopRight:SetTexCoord(self.cHorizTexCoord2, self.cHorizTexCoord3, self.cVertTexCoord0, self.cVertTexCoord1)
	self.TopRight:SetWidth(self.cRightWidth)
	self.TopRight:SetHeight(self.cTopHeight)
	self.TopRight:SetPoint("TOPRIGHT", self, "TOPRIGHT")
	
	self.BottomRight = self:CreateTexture(nil, "BACKGROUND")
	self.BottomRight:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.BottomRight:SetTexCoord(self.cHorizTexCoord2, self.cHorizTexCoord3, self.cVertTexCoord2, self.cVertTexCoord3)
	self.BottomRight:SetWidth(self.cRightWidth)
	self.BottomRight:SetHeight(self.cBottomHeight)
	self.BottomRight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
	
	self.Right = self:CreateTexture(nil, "BACKGROUND")
	self.Right:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.Right:SetTexCoord(self.cHorizTexCoord2, self.cHorizTexCoord3, self.cVertTexCoord1, self.cVertTexCoord2)
	self.Right:SetWidth(self.cRightWidth)
	self.Right:SetPoint("TOPRIGHT", self.TopRight, "BOTTOMRIGHT")
	self.Right:SetPoint("BOTTOMRIGHT", self.BottomRight, "TOPRIGHT")

	self.Top = self:CreateTexture(nil, "BACKGROUND")
	self.Top:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.Top:SetTexCoord(self.cHorizTexCoord1, self.cHorizTexCoord2, self.cVertTexCoord0, self.cVertTexCoord1)
	self.Top:SetHeight(self.cTopHeight)
	self.Top:SetPoint("TOPLEFT", self.TopLeft, "TOPRIGHT")
	self.Top:SetPoint("TOPRIGHT", self.TopRight, "TOPLEFT")

	self.Bottom = self:CreateTexture(nil, "BACKGROUND")
	self.Bottom:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.Bottom:SetTexCoord(self.cHorizTexCoord1, self.cHorizTexCoord2, self.cVertTexCoord2, self.cVertTexCoord3)
	self.Bottom:SetHeight(self.cBottomHeight)
	self.Bottom:SetPoint("BOTTOMLEFT", self.BottomLeft, "BOTTOMRIGHT")
	self.Bottom:SetPoint("BOTTOMRIGHT", self.BottomRight, "BOTTOMLEFT")
	
	self.Middle = self:CreateTexture(nil, "BACKGROUND")
	self.Middle:SetTexture("Interface\\Addons\\Forge\\Textures\\RoleBackground")
	self.Middle:SetTexCoord(self.cHorizTexCoord1, self.cHorizTexCoord2, self.cVertTexCoord1, self.cVertTexCoord2)
	self.Middle:SetPoint("TOPLEFT", self.TopLeft, "BOTTOMRIGHT")
	self.Middle:SetPoint("TOPRIGHT", self.TopRight, "BOTTOMLEFT")
	self.Middle:SetPoint("BOTTOMLEFT", self.BottomLeft, "TOPRIGHT")
	self.Middle:SetPoint("BOTTOMRIGHT", self.BottomRight, "TOPLEFT")
end
]]
----------------------------------------
-- DecodeItemLink
----------------------------------------

Forge.cItemLinkFormat = "|Hitem:(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+):(-?%d+)|h%[([^%]]*)%]|h"

function Forge:DecodeItemLink(pItemLink)
	if not pItemLink then
		return nil
	end
	
	local vStartIndex, vEndIndex,
	      vLinkColor,
	      vItemCode,
	      vItemEnchantCode,
	      vItemJewelCode1, vItemJewelCode2, vItemJewelCode3, vItemJewelCode4,
	      vItemSubCode,
	      vUnknownCode5,
	      vItemName = strfind(pItemLink, Forge.cItemLinkFormat)
	
	if not vStartIndex then
		return nil
	end
	
	local vLinkInfo =
	{
		Link = pItemLink,
		Name = vItemName,
		
		Code = tonumber(vItemCode),
		SubCode = tonumber(vItemSubCode),
		
		EnchantCode = tonumber(vItemEnchantCode),
		
		JewelCode1 = tonumber(vItemJewelCode1),
		JewelCode2 = tonumber(vItemJewelCode2),
		JewelCode3 = tonumber(vItemJewelCode3),
		JewelCode4 = tonumber(vItemJewelCode4),		
	}
	
	return vLinkInfo
end

Forge.cDeformat =
{
	s = "(.-)",
	d = "(-?[%d]+)",
	f = "(-?[%d%.]+)",
	g = "(-?[%d%.]+)",
	["%"] = "%%",
}

function Forge:ConvertFormatStringToSearchPattern(pFormat)
	local vEscapedFormat = pFormat:gsub(
			"[%[%]%.]",
			function (pChar) return "%"..pChar end)
	
	return vEscapedFormat:gsub(
			"%%[%-%d%.]-([sdgf%%])",
			self.cDeformat)
end

----------------------------------------
-- Slash commands
----------------------------------------

Forge.SlashCommands = {}
Forge.OrderedSlashCommands = {}

function Forge:ExecuteCommand(pCommandString)
	local vStartIndex, vEndIndex, vCommand, vParameter = string.find(pCommandString, "([^%s]+) ?(.*)")
	
	if not vStartIndex then
		self:ShowAllHelp()
		return
	end
	
	local vCommandInfo = self.SlashCommands[string.lower(vCommand)]
	
	if not vCommandInfo then
		self:ShowAllHelp()
		return
	end
	
	vCommandInfo.Func(vCommandInfo.Param, vCommand, vParameter)
end

function Forge:AddSlashCommand(pCommand, pFunction, pParam, pHelpParameters, pHelpDescription)
	local vSlashCommand =
	{
		Command = string.lower(pCommand),
		Func = pFunction,
		Param = pParam,
		HelpParams = pHelpParameters,
		HelpDesc = pHelpDescription,
	}
	
	table.insert(self.OrderedSlashCommands, vSlashCommand)
	self.SlashCommands[vSlashCommand.Command] = vSlashCommand
end

function Forge:ShowAllHelp(pCommand, pParameter)
	for _, vSlashCommand in ipairs(self.OrderedSlashCommands) do
		self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/forge %s %s"..NORMAL_FONT_COLOR_CODE..": %s", vSlashCommand.Command, vSlashCommand.HelpParams or "", vSlashCommand.HelpDesc or "No description available")
	end
end

function Forge:ShowCommandHelp(pCommand)
	local vSlashCommand = self.SlashCommands[pCommand]
	
	if not vSlashCommand then
		return
	end
	
	self:NoteMessage(HIGHLIGHT_FONT_COLOR_CODE.."/forge %s %s"..NORMAL_FONT_COLOR_CODE..": %s", pCommand, vSlashCommand.HelpParams or "", vSlashCommand.HelpDesc or "No description available")
	return
end

function Forge:GetUnitDistanceRange(pUnitID)
	if UnitIsUnit(pUnitID, "player") then
		return 0, 0
	end
	
	if not UnitIsVisible(pUnitID) then
		return 100, nil
	elseif CheckInteractDistance(pUnitID, 3) then
		return 0, 10
	elseif CheckInteractDistance(pUnitID, 2) then
		return 10, 11.11
	elseif CheckInteractDistance(pUnitID, 4) then
		return 11.11, 28
	else
		return 28, 100
	end
end

function Forge:GetFrameMaxLevel(pFrame, pUseDepth, pFrameLevel)
	local vLevel = pFrameLevel or pFrame:GetFrameLevel()
	local vChildren = {pFrame:GetChildren()}
	
	for _, vChildFrame in pairs(vChildren) do
		local vChildLevel
		
		if pUseDepth then
			vChildLevel = vLevel + 1
		end
		
		vChildLevel = self:GetFrameMaxLevel(vChildFrame, pUseDepth, vChildLevel)
		
		if vChildLevel > vLevel then
			vLevel = vChildLevel
		end
	end
	
	return vLevel
end

function Forge:IdentifyFramesUnderCursor()
	local	vCursorX, vCursorY = GetCursorPosition()
	
	self:IdentifyChildrenUnderPoint(UIParent, vCursorX, vCursorY)
end

function Forge:IdentifyChildrenUnderPoint(pFrame, pX, pY, pPrefix)
	local	vEffectiveScale = pFrame:GetEffectiveScale()
	if not pPrefix then pPrefix = "" end
	
	for _, vRegion in pairs({pFrame:GetRegions()}) do
		if self:PointInRegion(vRegion, pX, pY, vEffectiveScale) then
			local	vRegionName = pPrefix.."Region: "..(vRegion:GetName() or "<unnamed>")
			DEFAULT_CHAT_FRAME:AddMessage(vRegionName)
		end
	end
	
	for _, vFrame in pairs({pFrame:GetChildren()}) do
		if not vFrame:IsForbidden() then
			if self:PointInFrame(vFrame, pX, pY) then
				local	vFrameName = pPrefix.."Frame: "..(vFrame:GetName() or "<unnamed>").." level "..tostring(vFrame:GetFrameLevel())
				DEFAULT_CHAT_FRAME:AddMessage(vFrameName)
			end
		
			self:IdentifyChildrenUnderPoint(vFrame, pX, pY, pPrefix.."    ")
		end
	end
end

function Forge:PointInFrame(pFrame, pPointX, pPointY)
	return self:PointInRegion(pFrame, pPointX, pPointY, pFrame:GetEffectiveScale())
end

function Forge:PointInRegion(pFrame, pPointX, pPointY, pScale)
	return pFrame:IsVisible()
	   and pFrame:GetLeft() ~= nil
	   and pPointX >= (pFrame:GetLeft() * pScale)
	   and pPointX < (pFrame:GetRight() * pScale)
	   and pPointY <= (pFrame:GetTop() * pScale)
	   and pPointY > (pFrame:GetBottom() * pScale)
end

----------------------------------------
-- Object-oriented
----------------------------------------

function Forge:New(pMethodTable, ...)
	local vObject
	
	if pMethodTable.New then
		vObject = pMethodTable:New(...)
	else
		vObject = {}
	end
	
	return Forge:Construct(vObject, pMethodTable, ...)
end

function Forge:Construct(pObject, pMethodTable, ...)
	if not pMethodTable then
		self:ErrorMessage("ConstructObject called with nil method table")
		self:DebugStack()
		return
	end
	
	for vIndex, vValue in pairs(pMethodTable) do
		pObject[vIndex] = vValue
	end
	
	if pMethodTable.Construct then
		return pObject, pMethodTable.Construct(pObject, ...)
	else
		return pObject
	end
end

----------------------------------------
----------------------------------------

Forge.EventLib:RegisterEvent("PLAYER_ENTERING_WORLD", Forge.Initialize, Forge)
