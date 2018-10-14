Forge.WarningMessage = {}

Forge.WarningMessage.cWarningFontSize = 20
Forge.WarningMessage.cSubTextFontSize = 15

function Forge.WarningMessage:Initialize()
	self.WarningFrame = CreateFrame("Frame", "ForgeWarningFrame", UIParent)
	self.WarningFrame:Hide()
	self.WarningFrame:SetWidth(256)
	self.WarningFrame:SetHeight(32)
	self.WarningFrame:SetPoint("CENTER", RaidWarningFrame, "CENTER")
	
	self.WarningText = self.WarningFrame:CreateFontString(nil, "ARTWORK", "ZoneTextFont")
	self.WarningText:SetPoint("CENTER", self.WarningFrame, "CENTER")
	
	self.WarningSubText = self.WarningFrame:CreateFontString(nil, "ARTWORK", "SubZoneTextFont")
	self.WarningSubText:SetPoint("TOP", self.WarningText, "BOTTOM")
end

Forge.WarningMessage.cAlertAnimation =
{
	Action = "Sequence",
	Actions =
	{
		{Action = "FlashFrame", HoldShownTime = 4, FadeOutTime = 2, Asynch = true},
		{Action = "Sequence", Repeat = 12, Actions =
			{
				{Action = "SetScale", Value = 1, AbsoluteScale = true, Duration = 0},
				{Action = "Delay", Duration = 0.08},
				{Action = "SetScale", Value = 0.8, AbsoluteScale = true, Duration = 0},
				{Action = "Delay", Duration = 0.08},
			},
		},
		{Action = "SetScale", Value = 1, AbsoluteScale = true, Duration = 0},
	},
}

Forge.WarningMessage.cGameOverAnimation =
{
	Action = "Sequence",
	Actions =
	{
		{Action = "FlashFrame", FadeInTime = 0.5, HoldShownTime = 10, FadeOutTime = 1, Asynch = true},
		{Action = "SetScale", Value = 1, AbsoluteScale = true, Duration = 0},
	},
}

Forge.WarningMessage.cGameOverSubTextAnimation =
{
	Action = "Sequence",
	Actions =
	{
		{Action = "FlashFrame", FadeInTime = 0.1, HoldShownTime = 0.75, FadeOutTime = 0.1, HoldHiddenTime = 0.25, RepeatCount = 10},
	},
}

Forge.WarningMessage.cFadeAnimation =
{
	Action = "Sequence",
	Actions =
	{
		{Action = "FlashFrame", FadeInTime = 1, HoldShownTime = 2, FadeOutTime = 2, Asynch = true},
		{Action = "SetScale", Value = 1, AbsoluteScale = true, Duration = 0},
	},
}

Forge.WarningMessage.cNoteAnimation =
{
	Action = "Sequence",
	Actions =
	{
		{Action = "FlashFrame", HoldShownTime = 4, FadeOutTime = 2, Asynch = true},
		{Action = "SetScale", Value = 1, AbsoluteScale = true, Duration = 0},
	},
}

function Forge.WarningMessage:ShowMessage(pMessage, pColor, pStyle, pSubText)
	self.WarningText:SetText(pMessage)
	
	if not pSubText then
		pSubText = ""
	end
	
	self.WarningSubText:SetText(pSubText)
	
	if pColor then
		self.WarningText:SetTextColor(pColor.r, pColor.g, pColor.b)
		self.WarningSubText:SetTextColor(pColor.r, pColor.g, pColor.b)
	else
		self.WarningText:SetTextColor(1, 0.85, 0)
		self.WarningSubText:SetTextColor(1, 0.85, 0)
	end
	
	self.WarningText:SetFont(STANDARD_TEXT_FONT, self.cWarningFontSize, "THICKOUTLINE")
	self.WarningText:SetAlpha(1)
	self.WarningText:Show()
	
	self.WarningSubText:SetFont(STANDARD_TEXT_FONT, self.cSubTextFontSize, "OUTLINE")
	self.WarningSubText:SetAlpha(1)
	self.WarningSubText:Show()
	
	self.WarningFrame:SetScale(1)
	
	Forge.AnimationLib:StopFrameAnimations(self.WarningFrame)
	
	if pStyle == "FLASH" then
		Forge.AnimationLib:StartAnimation(self.WarningFrame, self.cAlertAnimation)
	elseif pStyle == "GAMEOVER" then
		Forge.AnimationLib:StartAnimation(self.WarningFrame, self.cGameOverAnimation)
		Forge.AnimationLib:StartAnimation(self.WarningSubText, self.cGameOverSubTextAnimation)
	elseif pStyle == "FADE" then
		Forge.AnimationLib:StartAnimation(self.WarningFrame, self.cFadeAnimation)
	else
		Forge.AnimationLib:StartAnimation(self.WarningFrame, self.cNoteAnimation)
	end
	
	self.WarningFrame:Show()
end

Forge.EventLib:RegisterEvent("FORGE_INIT", Forge.WarningMessage.Initialize, Forge.WarningMessage)