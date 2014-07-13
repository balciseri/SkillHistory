SkillHistory = LibStub("AceAddon-3.0"):NewAddon("SkillHistory", "AceConsole-3.0",  "AceEvent-3.0")

local skillHistoryFramePlayer
local skillHistoryFrameParty1
local skillHistoryFrameParty2

local position = {
	["EDGE_BOTTOM"] = {"TOP","BOTTOM"},
	["EDGE_TOP"] = {"BOTTOM","TOP"},
	["EDGE_LEFT"] = {"RIGHT","LEFT"},
	["EDGE_RIGHT"] = {"LEFT","RIGHT"},
	["EDGE_TOP_RIGHT"] = {"TOPLEFT","TOPRIGHT"},
	["EDGE_TOP_LEFT"] = {"TOPRIGHT","TOPLEFT"},
	["EDGE_BOTTOM_RIGHT"] = {"BOTTOMLEFT","BOTTOMRIGHT"},
	["EDGE_BOTTOM_LEFT"] = {"BOTTOMRIGHT","BOTTOMLEFT"},
	["CORNER_BOTTOM_RIGHT"] = {"TOPLEFT","BOTTOMRIGHT"},
	["CORNER_BOTTOM_LEFT"] = {"TOPRIGHT","BOTTOMLEFT"},
	["CORNER_TOP_RIGHT"] = {"BOTTOMLEFT","TOPRIGHT"},
	["CORNER_TOP_LEFT"] = {"BOTTOMRIGHT","TOPLEFT"},
	["UNDER_BOTTOM_RIGHT"] = {"TOPRIGHT","BOTTOMRIGHT"},
	["UNDER_BOTTOM_LEFT"] = {"TOPLEFT","BOTTOMLEFT"},
	["ABOVE_TOP_RIGHT"] = {"BOTTOMRIGHT","TOPRIGHT"},
	["ABOVE_TOP_LEFT"] = {"BOTTOMLEFT","TOPLEFT"},
}
function SkillHistory:OnInitialize()
	local defaults = {
		profile = {
			scale = 1.3,
			maxIcons = 3,
			xOffset = 1,
			yOffset = 1,
			iconDuration = 4,
			iconDirection = "RIGHT",
			iconPosition = "EDGE_BOTTOM_RIGHT",
		},
	}
 	self.db = LibStub("AceDB-3.0"):New("SkillHistoryDB", defaults, "Default")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	
	local options = {
		name = "Skill History",
		handler = SkillHistory,
		type = "group",
		childGroups = "tab",
		args = {
			scale = {
				type = "range",
				name = "Scale",
				min	= 0.1,
				max = 10,
				softMin = 0.1,
				softMax = 10,
				desc = "The scale for the icons",
				step = 0.1,
				bigStep = 0.1,
				set = "SetOptionScale",
				get = "GetOptionScale",
			},
			maxIcons = {
				type = "range",
				name = "Max icons",
				min	= 1,
				max = 30,
				softMin = 1,
				softMax = 30,
				desc = "The number of icons per frame",
				step = 1,
				bigStep = 1,
				set = "SetOptionMaxIcon",
				get = "GetOptionMaxIcon",
			},
			xOffset = {
				type = "range",
				name = "X offset",
				min	= 0,
				max = 100,
				softMin = 0,
				softMax = 100,
				desc = "The horizontal offset between the icons",
				step = 1,
				bigStep = 1,
				set = "SetOptionXOffset",
				get = "GetOptionXOffset",
			},
			yOffset = {
				type = "range",
				name = "Y offset",
				min	= 0,
				max = 100,
				softMin = 0,
				softMax = 100,
				desc = "The vertical offset between the icons",
				step = 1,
				bigStep = 1,
				set = "SetOptionYOffset",
				get = "GetOptionYOffset",
			},
			iconDuration = {
				type = "range",
				name = "Icon duration (s)",
				min	= 0,
				max = 20,
				softMin = 0,
				softMax = 20,
				desc = "The icon duration in seconds",
				step = 0.5,
				bigStep = 0.5,
				set = "SetOptionIconDuration",
				get = "GetOptionIconDuration",
			},
			iconDirection = {
				type = "select",
				values = {["RIGHT"]="Right",["LEFT"]="Left",["UP"]="Up",["DOWN"]="Down",},
				name = "Direction",
				desc = "The direction of the slide",
				set = "SetOptionIconDirection",
				get = "GetOptionIconDirection",
			},
			iconPosition = {
				type = "select",
				values = {["EDGE_TOP_RIGHT"]="Edge, Top-right",["EDGE_TOP_LEFT"]="Edge, Top-left", ["EDGE_BOTTOM_RIGHT"]="Edge, Bottom-right",["EDGE_BOTTOM_LEFT"]="Edge, Bottom-left",["CORNER_BOTTOM_RIGHT"]="Corner, Bottom-right",["CORNER_BOTTOM_LEFT"]="Corner, Bottom-left",["CORNER_TOP_RIGHT"]="Corner, Top-right",["CORNER_TOP_LEFT"]="Corner, Top-left",["EDGE_RIGHT"]="Edge, Right",["EDGE_LEFT"]="Edge, Left",["EDGE_TOP"]="Edge, Top",["EDGE_BOTTOM"]="Edge, Bottom",["UNDER_BOTTOM_RIGHT"]="Under, Bottom-right",["UNDER_BOTTOM_LEFT"]="Under, Bottom-left",["ABOVE_TOP_RIGHT"]="Above, Top-right",["ABOVE_TOP_LEFT"]="Above, Top-left" },
				name = "Position",
				desc = "The anchor point relative to the blizzard's raid frame",
				set = "SetOptionIconPosition",
				get = "GetOptionIconPosition",
			},
		},
	}
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("SkillHistoryOptions", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SkillHistoryOptions", "Skill History")
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("SkillHistoryProfile", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SkillHistoryProfile", "Profiles", "Skill History")
		
    self:RegisterChatCommand("sh", "ChatCommandSh")
		
	SkillHistory:CreateBar()
	
	ChatFrame1:AddMessage("SkillHistory loaded. Type /sh to open the options panel.",2,0,0)
		
	-- Set basic values for the skillHistory.
	SkillHistory:SetBasicSkillHistoryFrameValues(skillHistoryFramePlayer,"player")
	SkillHistory:SetBasicSkillHistoryFrameValues(skillHistoryFrameParty1,"party1")
	SkillHistory:SetBasicSkillHistoryFrameValues(skillHistoryFrameParty2,"party2")
	
	CompactRaidFrameContainer:HookScript("OnEvent", SkillHistory.OnRosterUpdate)
	CompactRaidFrameContainer:HookScript("OnHide", SkillHistory.OnRosterHide)
	CompactRaidFrameContainer:HookScript("OnShow", SkillHistory.OnRosterUpdate)
	
end
function SkillHistory:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
end

function SkillHistory:RefreshConfig()
	SkillHistory:UpdateBar()
	skillHistoryFramePlayer:Reset()
	skillHistoryFrameParty1:Reset()
	skillHistoryFrameParty2:Reset()
	self:Print("Settings refreshed")
end
function SkillHistory:ChatCommandSh(input)
	if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("sh", "SkillHistory", input)
    end
end

function SkillHistory:GetOptionScale(info)
    return self.db.profile.scale
end
function SkillHistory:SetOptionScale(info, newValue)
    self.db.profile.scale = newValue
	SkillHistory:UpdateBar()
end
function SkillHistory:GetOptionMaxIcon(info)
    return self.db.profile.maxIcons
end
function SkillHistory:SetOptionMaxIcon(info, newValue)
    self.db.profile.maxIcons = newValue
end
function SkillHistory:GetOptionXOffset(info)
    return self.db.profile.xOffset
end
function SkillHistory:SetOptionXOffset(info, newValue)
    self.db.profile.xOffset = newValue
end
function SkillHistory:GetOptionYOffset(info)
    return self.db.profile.yOffset
end
function SkillHistory:SetOptionYOffset(info, newValue)
    self.db.profile.yOffset = newValue
end
function SkillHistory:GetOptionIconDuration(info)
    return self.db.profile.iconDuration
end
function SkillHistory:SetOptionIconDuration(info, newValue)
    self.db.profile.iconDuration = newValue
end
function SkillHistory:GetOptionIconDirection(info)
    return self.db.profile.iconDirection
end
function SkillHistory:SetOptionIconDirection(info, newValue)
    self.db.profile.iconDirection = newValue
end
function SkillHistory:GetOptionIconPosition(info)
    return self.db.profile.iconPosition
end
function SkillHistory:SetOptionIconPosition(info, newValue)
    self.db.profile.iconPosition = newValue
	skillHistoryFramePlayer:ClearAllPoints();
	skillHistoryFrameParty1:ClearAllPoints();
	skillHistoryFrameParty2:ClearAllPoints();
	self:OnRosterUpdate()
end

function SkillHistory:GetDB()
	return self.db
end


local testega = 0
local ICON_SIZE = 35

-- *** FRAME FUNCTIONS ***
local function Enable (self)
	self.enabled = true
	self:SetScript("OnUpdate", self.OnUpdate)
	self:Show()
end

local function Disable (self)
	self.enabled = nil
	self:SetScript("OnUpdate", nil)
	self:Hide()
end

local function Update (self)	
	if ( not self.enabled ) then
		return
	end

	self:Reset()
end

local function OnUpdate(self, elapsed)
	if ( not self.enabled ) then
		return
	end

	if ( self.numIcons > 0 ) then
		self.elapsed = self.elapsed + elapsed
		
		-- Throttle the OnUpdate function for the cast history.
		if ( self.elapsed > 0.3 ) then
			self.elapsed = 0
			
			for i = 1, self.numIcons do
				local icon = self["icon"..i]
				
				if ( icon and icon.active and icon.expires and icon.expires <= GetTime() ) then
					icon.fadeOutAnimation:Play()
					icon.fading = true
				end
			end
		end
	end

end

local function Rotate (self, event, spellID, lineID)
	if ( not self.enabled ) then
		return
	end
	
	local name, _, texture, _, _, _, castingTime, _, _ = GetSpellInfo(spellID)
	local iconFound
	local icon
	local unit = self.unit
	local dontMove = true
	local direction = SkillHistory:GetDB().profile.iconDirection
	local size = ICON_SIZE

	-- This is the first spell the cast history gets. We need to create an icon now.
	if ( self.numIcons == 0 ) then
		SkillHistory:CreateIcon(self)
	end
	
	--[[ It is possible that there is no visible frame on the initial position due to the fadeout of failed casts.
	If this is the case, we don't need to move anything, because we already have enough space to show the new icon. ]]--
	for i = 1, self.numIcons do
		icon = self["icon"..i]
		
		if ( icon.timesMoved == 0 and icon.active ) then
			dontMove = nil
			break
		end	
	end
	
	icon = nil
	
	for i = 1, self.numIcons do
		icon = self["icon"..i]
		
		if ( not icon.active ) then
			-- This is an icon we can use for the new spell, just check if we've found one already.
			if ( not iconFound ) then
				
				icon.spellID = spellID
				
				-- PvP-Trinekt spell has a different icon than the trinkets. So I replace it here with the according one.
				if ( spellID == 59752 or spellID == 42292 ) then
					local _, faction = UnitFactionGroup(unit)
					
					if ( faction == "Alliance" ) then
						texture = ("Interface\\ICONS\\INV_Jewelry_TrinketPVP_01")
					else
						texture = ("Interface\\ICONS\\INV_Jewelry_TrinketPVP_02")
					end
				end
					
				icon.texture:SetTexture(texture)
				icon:SetAlpha(0)
					
				-- Update icon Size etc.
				SkillHistory:UpdateIcon(icon, size, direction)
					
				if ( event == "UNIT_SPELLCAST_START" ) then
					icon.casting = true
					icon.lineID = lineID
					self.castingIcon = icon
					icon.castingAnimation:Play()
				elseif ( event == "UNIT_SPELLCAST_CHANNEL_START" ) then
					icon.casting = nil
					icon.channeling = true
					self.channelIcon = icon
					icon.castingAnimation:Play()
				elseif ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
					icon.fadeInAnimation:Play()
				end

				icon.active = true
				iconFound = true
				icon:Show()
				--[[ Mark the icon in our castbar as the newest icon. This way it is possible to alter its appearance via combat log functions,
					 because these always fire after the UNIT_SPELLCAST events. ]]--
				self.newestIcon = icon
			end
		else
			-- Already active icon. So this one might has to be moved.
			if (not dontMove ) then

				icon.timesMoved = icon.timesMoved + 1

				if ( icon.moveAnimation:IsPlaying() ) then
					-- If the icon is already moving we just add the default offset to the current transitionway
					local xOffset, yOffset = icon.translationAnimation:GetOffset()
					
					if ( direction == "LEFT" ) then
						xOffset = xOffset - size
					elseif ( direction == "RIGHT" ) then
						xOffset = xOffset + size
					elseif ( direction == "UP" ) then
						yOffset = yOffset + size
					elseif ( direction == "DOWN" ) then
						yOffset = yOffset - size
					end
					
					icon.translationAnimation:SetOffset(xOffset, yOffset)
				else
					icon.moveAnimation:Play()
				end
				
				if (not icon.fading and icon.timesMoved >= SkillHistory:GetDB().profile.maxIcons ) then
					icon.fadeOutAnimation:Play()
				end
			
			end			
		
		end
	end
	
	-- Create a new icon, if no inactive icon was found.
	if ( not iconFound ) then
		icon = SkillHistory:CreateIcon(self)
		
		icon.spellID = spellID
				
		-- PvP-Trinekt spell has a different icon than the trinkets. So I replace it here with the according one.
		if ( spellID == 59752 or spellID == 42292 ) then
			local _, faction = UnitFactionGroup(unit)
					
			if ( faction == "Alliance" ) then
				texture = ("Interface\\ICONS\\INV_Jewelry_TrinketPVP_01")
			else
				texture = ("Interface\\ICONS\\INV_Jewelry_TrinketPVP_02")
			end
		end	
		
		icon.texture:SetTexture(texture)
		icon:SetAlpha(0)
					
		-- Update icon Size etc.
		SkillHistory:UpdateIcon(icon, size, direction)
					
		if ( event == "UNIT_SPELLCAST_START" ) then
			icon.casting = true
			icon.lineID = lineID
			self.castingIcon = icon
			icon.castingAnimation:Play()
		elseif ( event == "UNIT_SPELLCAST_CHANNEL_START" ) then
			icon.channeling = true
			self.channelIcon = icon
			icon.castingAnimation:Play()
		elseif ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
			icon.fadeInAnimation:Play()
		end
		
		icon.active = true
		iconFound = true
		icon:Show()
		
		--[[ Mark the icon in our castbar as the newest icon. This way it is possible to alter its appearance via combat log functions,
			 because these always fire after the UNIT_SPELLCAST events. ]]--
		self.newestIcon = icon
	end
	
end
local function Reset (self)
	if ( self.numIcons > 0 ) then
		for i = 1, self.numIcons do
			local icon = self["icon"..i]
			SkillHistory:ResetIcon(icon)
		end
	end

end

-- *** ANIMATION SCRIPT FUNCTIONS ***
local function FadeInOnFinished(animation, requested)
	local icon = animation:GetParent()
	
	icon:SetAlpha(1)
	icon.expires = GetTime() + SkillHistory:GetDB().profile.iconDuration	

end

local function FadeOutOnFinished(animation, requested)
	local icon = animation:GetParent()
	local skillHistory = icon:GetParent()
	
	icon:Hide()
	icon:SetAlpha(0)
		
	if ( icon.active ) then
		SkillHistory:ResetIcon(icon)
	end	

end

local function MoveOnFinished(animation, requested)
	local icon = animation:GetParent()
	local skillHistory = icon:GetParent()
	local size = ICON_SIZE
	local direction = SkillHistory:GetDB().profile.iconDirection
	
	-- Reset animation's xOffset to default
	local point, relativeTo, relativePoint, xOffset, yOffset = icon:GetPoint()

	if ( direction == "LEFT" ) then
		xOffset = (-size - SkillHistory:GetDB().profile.xOffset) * icon.timesMoved 
		yOffset = 0
		icon.translationAnimation:SetOffset(-size, 0)
	elseif ( direction == "RIGHT" ) then
		xOffset = ( size + SkillHistory:GetDB().profile.xOffset ) * icon.timesMoved 
		yOffset = 0
		icon.translationAnimation:SetOffset(size, 0)
	elseif ( direction == "UP" ) then
		yOffset = (size + SkillHistory:GetDB().profile.yOffset) * icon.timesMoved
		xOffset = 0
		icon.translationAnimation:SetOffset(0, size)
	elseif ( direction == "DOWN" ) then
		yOffset = (-size - SkillHistory:GetDB().profile.yOffset) * icon.timesMoved
		xOffset = 0
		icon.translationAnimation:SetOffset(0, -size)
	end	

	icon:ClearAllPoints()
	icon:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)	

end

local function CastingOnFinished(animation, requested)
	local icon = animation:GetParent()
	local skillHistory = icon:GetParent()
	
	if ( not icon.abandoned ) then
		
		icon.fadeInAnimation:Play()
	else
		SkillHistory:ResetIcon(icon)
	end	

end

function SkillHistory:CreateIcon(skillHistory)

	local size = ICON_SIZE
	local direction = self.db.profile.iconDirection
	local numIcons = skillHistory.numIcons + 1
	local iconTemplate = "SkillHistoryIconTemplate"
	local prefix = skillHistory.unit.."SkillHistory"
	local iconName = prefix.."Icon"..numIcons
	local iconReference = "icon"..numIcons
	
	local icon = CreateFrame("Button", iconName, skillHistory, iconTemplate)
	
	if ( icon ) then
		skillHistory[iconReference] = icon
		
		icon.texture = _G[iconName.."Texture"]
		icon.border = _G[iconName.."Border"]
		icon.lockOutTexture = _G[iconName.."LockOutTexture"]
		icon.castingAnimation = _G[iconName.."Casting"]
		icon.moveAnimation = _G[iconName.."Move"]
		icon.translationAnimation = _G[iconName.."MoveTranslation"]
		icon.fadeInAnimation = _G[iconName.."FadeIn"]
		icon.fadeOutAnimation = _G[iconName.."FadeOut"]
		
		-- Set the anchor of icon according to the move direction.
		SkillHistory:UpdateIcon(icon, size, direction)
		
		icon.timesMoved = 0
		
		skillHistory.numIcons = numIcons
		
		-- Set scripts for the animations.
		icon.fadeInAnimation:SetScript("OnFinished", FadeInOnFinished)
		icon.fadeOutAnimation:SetScript("OnFinished", FadeOutOnFinished)
		icon.castingAnimation:SetScript("OnFinished", CastingOnFinished)
		icon.moveAnimation:SetScript("OnFinished", MoveOnFinished)
		
		return skillHistory[iconReference]
	end

end

function SkillHistory:UpdateIcon(icon, size, direction)
		icon:ClearAllPoints()
		
		if ( direction == "LEFT" ) then
			icon:SetPoint("RIGHT")
			icon.translationAnimation:SetOffset(-size, 0)
		elseif ( direction == "RIGHT" ) then
			icon:SetPoint("LEFT")
			icon.translationAnimation:SetOffset(size, 0)
		elseif ( direction == "UP" ) then
			icon:SetPoint("BOTTOM")
			icon.translationAnimation:SetOffset(0, size)
		elseif ( direction == "DOWN" ) then
			icon:SetPoint("TOP")
			icon.translationAnimation:SetOffset(0, -size)
		end
		
		icon:SetSize(size, size)
		icon.border:SetSize(size+1, size+1)		
end

function SkillHistory:ResetIcon (icon)	
	icon:Hide()
	icon.texture:SetTexture()
	icon.border:SetVertexColor(1, 1, 1, 1)
	icon.border:Hide()
	icon.lockOutTexture:Hide()
	
	-- Stop all animations that are running.
	icon.moveAnimation:Stop()
	icon.fadeInAnimation:Stop()
	icon.fadeOutAnimation:Stop()
	icon.castingAnimation:Stop()
	
	-- Reset the offset for the translation animation.
	icon.translationAnimation:SetOffset(0, 0)
	
	-- Clear all points and set the alpha to 1.
	icon:SetAlpha(1)
	icon:ClearAllPoints()
	
	-- Reset all control variables to their initial state.
	icon.active = nil
	icon.timesMoved = 0
	icon.expires = nil
	icon.fading = nil
	icon.abandoned = nil
	icon.casting = nil
	icon.lineID = nil
	icon.channeling = nil
	icon.spellID = nil

end

function SkillHistory:StartCast(skillHistory, event, ...)
	local lineID = select(4, ...)
	local spellID = select(5, ...)
	skillHistory.casting = true
	skillHistory.lineID = lineID
	skillHistory:Rotate(event, spellID, lineID)
end

function SkillHistory:StopCast(skillHistory, ...)
	local lineID = select(4, ...)
	local spellID = select(5, ...)
	local name = GetSpellInfo(spellID)
	
	skillHistory.casting = nil
	skillHistory.lineID = nil
	
	local icon = skillHistory.castingIcon

	if ( icon and lineID == icon.lineID ) then
		-- Reset the history icon that was registered for this casted spell.
		--FadeOutOnFinished(icon.fadeOutAnimation,nil)
		icon.casting = nil
		icon.lineID = nil
		icon.abandoned = true
		icon.castingAnimation:Finish()
		skillHistory.stoppedIcon = skillHistory.castingIcon
		skillHistory.castingIcon = nil
	end
end

function SkillHistory:StartChannel(skillHistory, event, ...)
	local spellID = select(5, ...)	
	skillHistory.channeling = true
	skillHistory:Rotate(event, spellID, nil)
end

function SkillHistory:StopChannel(skillHistory, ...)
		skillHistory.channeling = nil
		local icon = skillHistory.channelIcon
		
		if ( icon ) then
			icon.channeling = nil
			icon.abandoned = nil
			icon.castingAnimation:Finish()
			icon.stoppedIcon = skillHistory.channelIcon
			icon.channelIcon = nil
		end
end

function SkillHistory:SuccessfulCast (skillHistory, event, ...)
	local icon = skillHistory.castingIcon
	local lineID = select(4, ...)
	local spellID = select(5, ...)		
	local name = GetSpellInfo(spellID)
		
	if ( not skillHistory.casting and not skillHistory.channeling  ) then
		-- This one is an instant cast spell. "UNIT_SPELLCAST_SUCCEEDED" also fires for every tick of a channeled spell, so we checked channeling also.
		skillHistory:Rotate(event, spellID, lineID)
	elseif ( skillHistory.casting and lineID == skillHistory.lineID ) then
		skillHistory.isCasting = nil
		skillHistory.lineID = nil
		
		if ( icon and icon.casting ) then
			icon.casting = nil
			icon.lineID = nil
			icon.abandoned = nil
			icon.castingAnimation:Finish()
			skillHistory.castingIcon = nil
		end
	end
end

function SkillHistory:SetIconBorderColour(skillHistory, ...)
	local spellID = select(12, ...)
	local destGUID = select(8, ...)
	local icon = skillHistory.newestIcon
	local _, class
	
	if ( icon and not icon.casting and not icon.channeling and icon.spellID and icon.spellID == spellID ) then
		if ( destGUID ~= "0x0000000000000000" and destGUID ~= "" and destGUID ) then
			_, class = GetPlayerInfoByGUID(destGUID)
		end			
	
		if ( class ) then
			icon.border:Show()
			icon.border:SetVertexColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b, 1)
		else
			icon.border:Hide()
		end
		
		skillHistory.newestIcon = nil
	end
end

function SkillHistory:LockOutCast(skillHistory, ...)
	local extraSpellID = select(15, ...)
		
	icon = skillHistory.stoppedIcon
	
	if ( icon and icon.abandoned and icon.spellID and extraSpellID == icon.spellID ) then
		icon.abandoned = nil
		icon.border:Show()
		icon.border:SetVertexColor(1, 0, 0, 1)
		icon.lockOutTexture:Show()
		skillHistory.stoppedIcon = nil		
	end

end

function SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	local affectedFrame
	if (skillHistoryFramePlayer and unit == "player") then
		affectedFrame = skillHistoryFramePlayer
	elseif (skillHistoryFrameParty1 and unit == "party1") then
		affectedFrame = skillHistoryFrameParty1
	elseif (skillHistoryFrameParty2 and unit == "party2") then
		affectedFrame = skillHistoryFrameParty2
	else
		affectedFrame = nil
	end
	
	return affectedFrame
end
function SkillHistory:GetAffectedSkillHistoryFrameByName(name)
	if name == nil then
		return nil
	end
	local affectedFrame
	if (skillHistoryFramePlayer and UnitIsUnit(name,"player")) then
		affectedFrame = skillHistoryFramePlayer
	elseif (skillHistoryFrameParty1 and UnitIsUnit(name,"party1")) then
		affectedFrame = skillHistoryFrameParty1
	elseif (skillHistoryFrameParty2 and UnitIsUnit(name,"party2")) then
		affectedFrame = skillHistoryFrameParty2
	else
		affectedFrame = nil
	end
	
	return affectedFrame
end

function SkillHistory:UNIT_SPELLCAST_SUCCEEDED(eventName,...)
	if select(5,...) == 146739 then return end  --we don't like double corruption
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:SuccessfulCast(skillHistoryFrame, "UNIT_SPELLCAST_SUCCEEDED", ...)
	end
end
function SkillHistory:UNIT_SPELLCAST_START(eventName,...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StartCast(skillHistoryFrame, "UNIT_SPELLCAST_START", ...)
	end
end
function SkillHistory:UNIT_SPELLCAST_STOP(eventName,...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StopCast(skillHistoryFrame, ...)
	end
end
function SkillHistory:UNIT_SPELLCAST_CHANNEL_START(eventName,...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StartChannel(skillHistoryFrame,"UNIT_SPELLCAST_CHANNEL_START",...)
	end
end
function SkillHistory:UNIT_SPELLCAST_CHANNEL_STOP(eventName,...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StopChannel(skillHistoryFrame, ...)
	end
end
function SkillHistory:UNIT_SPELLCAST_CHANNEL_UPDATE(eventName,...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StopChannel(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED_SPELL_DAMAGE(eventName,...)
	local sourceName = select(5, ...)
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByName(sourceName)
	if skillHistoryFrame ~= nil then
		SkillHistory:SetIconBorderColour(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED_SPELL_HEAL(eventName,...)
	local sourceName = select(5, ...)
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByName(sourceName)
	if skillHistoryFrame ~= nil then
		SkillHistory:SetIconBorderColour(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_SUCCESS(eventName,...)
	local sourceName = select(5, ...)
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByName(sourceName)
	if skillHistoryFrame ~= nil then
		SkillHistory:SetIconBorderColour(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED_SPELL_INTERRUPT(eventName,...)
	local destName = select(9, ...)
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByName(destName)
	if skillHistoryFrame ~= nil then
		SkillHistory:LockOutCast(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED(eventName,...)
	local event2 = select(2, ...)
	eventName = eventName.."_"..event2
	
	if eventName == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_DAMAGE" then
		self:COMBAT_LOG_EVENT_UNFILTERED_SPELL_DAMAGE(seventName,...)
	elseif eventName == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_HEAL" then
		self:COMBAT_LOG_EVENT_UNFILTERED_SPELL_HEAL(seventName,...)
	elseif eventName == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_SUCCESS" then
		self:COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_SUCCESS(seventName,...)
	elseif eventName == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_INTERRUPT" then
		self:COMBAT_LOG_EVENT_UNFILTERED_SPELL_INTERRUPT(seventName,...)
	end
end
function SkillHistory:UpdateBar()
	skillHistoryFramePlayer:SetScale(self.db.profile.scale)
	skillHistoryFrameParty1:SetScale(self.db.profile.scale)
	skillHistoryFrameParty2:SetScale(self.db.profile.scale)
end
function SkillHistory:CreateSkillHistoryFrame()
	local frame
	frame = CreateFrame("Frame", nil, UIParent)
	frame:SetWidth(ICON_SIZE)
	frame:SetHeight(ICON_SIZE)
	
	return frame
end
function SkillHistory:CreateBar()
	skillHistoryFramePlayer = SkillHistory:CreateSkillHistoryFrame()
	skillHistoryFrameParty1 = SkillHistory:CreateSkillHistoryFrame()	
	skillHistoryFrameParty2 = SkillHistory:CreateSkillHistoryFrame()
	
	self:UpdateBar()
end                                       

function SkillHistory:Test()
	print("Not yet implemented")
	--[[if testega == 0 then
		testega = 10
	else	
		testega = 0
	end]]
end

function SkillHistory:SetBasicSkillHistoryFrameValues(skillHistory,unit)
	skillHistory.numIcons = 0
	skillHistory.elapsed = 0
	skillHistory.iconTemplate = iconTemplate
	skillHistory.unit = unit
	skillHistory.OnUpdate = OnUpdate
	skillHistory.Update = Update
	skillHistory.Rotate = Rotate
	skillHistory.Reset = Reset
	skillHistory.Enable = Enable
	skillHistory.Disable = Disable
	skillHistory:SetScript("OnUpdate", skillHistory.OnUpdate)
	
	local n = GetNumGroupMembers()
	if n > 0 then
		enabled = true
	else
		enabled = false
	end
	
	if ( enabled ) then
		skillHistory:Enable()
	else
		skillHistory:Disable()
	end	
end

function SkillHistory:OnRosterHide()
	if CompactRaidFrameContainer:IsVisible() then
		return 
	end
	
	skillHistoryFramePlayer:Disable()
	skillHistoryFrameParty1:Disable()
	skillHistoryFrameParty2:Disable()
end
function SkillHistory:OnRosterUpdate()
	if not CompactRaidFrameContainer:IsVisible() then
		if(skillHistoryFramePlayer.enabled) then
			skillHistoryFramePlayer:Disable()
		end
		if(skillHistoryFrameParty1.enabled) then
			skillHistoryFrameParty1:Disable()
		end
		if(skillHistoryFrameParty2.enabled) then
			skillHistoryFrameParty2:Disable()
		end
		return 
	end
	if( not skillHistoryFramePlayer.enabled) then
		skillHistoryFramePlayer:Enable()
	end
	if( not skillHistoryFrameParty1.enabled) then
		skillHistoryFrameParty1:Enable()
	end
	if( not skillHistoryFrameParty2.enabled) then
		skillHistoryFrameParty2:Enable()
	end

	local n = GetNumGroupMembers()
	if n > 0 then
		if CompactRaidFrameManager.container.groupMode == "flush" then
			for i = 1,40 do 
				local f = _G["CompactRaidFrame"..i]
				if(f and f.displayedUnit and UnitIsUnit("player", f.displayedUnit)) then
					skillHistoryFramePlayer:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
				elseif(f and f.displayedUnit and UnitIsUnit("party1", f.displayedUnit)) then
					skillHistoryFrameParty1:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
				elseif(f and f.displayedUnit and UnitIsUnit("party2", f.displayedUnit)) then
					skillHistoryFrameParty2:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
				end
			end
		elseif CompactRaidFrameManager.container.groupMode == "discrete" then
			local test = _G["CompactPartyFrameMember1"]
			if ( test ) then
				for i = 1,5 do
					local f = _G["CompactPartyFrameMember"..i]
					if (f and f.displayedUnit and UnitIsUnit("player", f.displayedUnit)) then
						skillHistoryFramePlayer:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
					elseif(f and f.displayedUnit and UnitIsUnit("party1", f.displayedUnit)) then
						skillHistoryFrameParty1:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
					elseif(f and f.displayedUnit and UnitIsUnit("party2", f.displayedUnit)) then
						skillHistoryFrameParty2:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
					end
				end
			else 
				for i = 1,8 do
					for j = 1,5 do
						local f = _G["CompactRaidGroup"..i.."Member"..j]
						if (f and f.displayedUnit and UnitIsUnit("player", f.displayedUnit)) then
							skillHistoryFramePlayer:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
						elseif(f and f.displayedUnit and UnitIsUnit("party1", f.displayedUnit)) then
							skillHistoryFrameParty1:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
						elseif(f and f.displayedUnit and UnitIsUnit("party2", f.displayedUnit)) then
							skillHistoryFrameParty2:SetPoint(position[SkillHistory:GetDB().profile.iconPosition][1], f, position[SkillHistory:GetDB().profile.iconPosition][2],1,3)
						end
					end
				end
			end
		end
	end
end
