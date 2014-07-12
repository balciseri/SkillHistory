SkillHistory = {}
SkillHistory.frame = CreateFrame("Frame")

local testega = 0
local MAXICONS 
local ICON_SIZE = 35
local DEFAULT_X_MOD 
local DEFAULT_Y_MOD 
local ICON_DURATION 
local ICON_DIRECTION

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
	local direction = ICON_DIRECTION
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
				
				if (not icon.fading and icon.timesMoved >= MAXICONS ) then
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
	icon.expires = GetTime() + ICON_DURATION	

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
	local direction = ICON_DIRECTION
	
	-- Reset animation's xOffset to default
	local point, relativeTo, relativePoint, xOffset, yOffset = icon:GetPoint()

	if ( direction == "LEFT" ) then
		xOffset = (-size - DEFAULT_X_MOD) * icon.timesMoved 
		yOffset = 0
		icon.translationAnimation:SetOffset(-size, 0)
	elseif ( direction == "RIGHT" ) then
		xOffset = ( size + DEFAULT_X_MOD ) * icon.timesMoved 
		yOffset = 0
		icon.translationAnimation:SetOffset(size, 0)
	elseif ( direction == "UP" ) then
		yOffset = (size + DEFAULT_Y_MOD) * icon.timesMoved
		xOffset = 0
		icon.translationAnimation:SetOffset(0, size)
	elseif ( direction == "DOWN" ) then
		yOffset = (-size - DEFAULT_Y_MOD) * icon.timesMoved
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
	local direction = ICON_DIRECTION
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

function SkillHistory:UNIT_SPELLCAST_SUCCEEDED(...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:SuccessfulCast(skillHistoryFrame, "UNIT_SPELLCAST_SUCCEEDED", ...)
	end
end
function SkillHistory:UNIT_SPELLCAST_START(...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StartCast(skillHistoryFrame, "UNIT_SPELLCAST_START", ...)
	end
end
function SkillHistory:UNIT_SPELLCAST_STOP(...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StopCast(skillHistoryFrame, ...)
	end
end
function SkillHistory:UNIT_SPELLCAST_CHANNEL_START(...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StartChannel(skillHistoryFrame,"UNIT_SPELLCAST_CHANNEL_START",...)
	end
end
function SkillHistory:UNIT_SPELLCAST_CHANNEL_STOP(...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StopChannel(skillHistoryFrame, ...)
	end
end
function SkillHistory:UNIT_SPELLCAST_CHANNEL_UPDATE(...)
	local unit = ...
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByUnit(unit)
	if skillHistoryFrame ~= nil then
		SkillHistory:StopChannel(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED_SPELL_DAMAGE(...)
	local sourceName = select(5, ...)
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByName(sourceName)
	if skillHistoryFrame ~= nil then
		SkillHistory:SetIconBorderColour(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED_SPELL_HEAL(...)
	local sourceName = select(5, ...)
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByName(sourceName)
	if skillHistoryFrame ~= nil then
		SkillHistory:SetIconBorderColour(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_SUCCESS(...)
	local sourceName = select(5, ...)
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByName(sourceName)
	if skillHistoryFrame ~= nil then
		SkillHistory:SetIconBorderColour(skillHistoryFrame, ...)
	end
end
function SkillHistory:COMBAT_LOG_EVENT_UNFILTERED_SPELL_INTERRUPT(...)
	local destName = select(9, ...)
	local skillHistoryFrame = SkillHistory:GetAffectedSkillHistoryFrameByName(destName)
	if skillHistoryFrame ~= nil then
		SkillHistory:LockOutCast(skillHistoryFrame, ...)
	end
end
function SkillHistory:UpdateBar()
	skillHistoryFramePlayer:SetScale(SkillHistoryDb.scale)
	skillHistoryFrameParty1:SetScale(SkillHistoryDb.scale)
	skillHistoryFrameParty2:SetScale(SkillHistoryDb.scale)
	MAXICONS = SkillHistoryDb.maxIcons
	DEFAULT_X_MOD = SkillHistoryDb.x_mod
	DEFAULT_Y_MOD = SkillHistoryDb.y_mod
	ICON_DURATION = SkillHistoryDb.icon_duration
	ICON_DIRECTION = SkillHistoryDb.icon_direction
	
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

local cmdfuncs = {
	scale = function(v) SkillHistoryDb.scale = tonumber(v) SkillHistory:UpdateBar() end,
	max = function(v) SkillHistoryDb.maxIcons = tonumber(v) SkillHistory:UpdateBar() end,
	x = function(v) SkillHistoryDb.x_mod = tonumber(v) SkillHistory:UpdateBar() end,
	y = function(v) SkillHistoryDb.y_mod = tonumber(v) SkillHistory:UpdateBar() end,
	duration = function(v) SkillHistoryDb.icon_duration = tonumber(v) SkillHistory:UpdateBar() end,
	direction = function(v) SkillHistoryDb.icon_direction = string.upper(v) SkillHistory:UpdateBar() end,
	test = function() SkillHistory:Test() end,
}
local cmdtbl = {}

function SkillHistory:SkillHistory_Command(cmd)
	for k in ipairs(cmdtbl) do
		cmdtbl[k] = nil
	end
	for v in gmatch(cmd, "[^ ]+") do
  	tinsert(cmdtbl, v)
  end
  local cb = cmdfuncs[cmdtbl[1]] 
  if cb then
  	local s = cmdtbl[2]
  	cb(s)
  else
  	ChatFrame1:AddMessage("Skill History Options | /mg <option>",2,0,0)  	
  	ChatFrame1:AddMessage("/sh scale <number> | actual value: " .. SkillHistoryDb.scale,2,1,0)
	ChatFrame1:AddMessage("/sh max <number> | actual value: " .. SkillHistoryDb.maxIcons,2,1,0)
	ChatFrame1:AddMessage("/sh x <number> | actual value: " .. SkillHistoryDb.x_mod,2,1,0)
	ChatFrame1:AddMessage("/sh y <number> | actual value: " .. SkillHistoryDb.y_mod,2,1,0)
	ChatFrame1:AddMessage("/sh duration <number> | actual value: " .. SkillHistoryDb.icon_duration,2,1,0)
	ChatFrame1:AddMessage("/sh direction <right,left,up,down> | actual value: " .. string.lower(SkillHistoryDb.icon_direction),2,1,0)
	ChatFrame1:AddMessage("/sh test (execute)",2,1,0)
  end
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
function SkillHistory:VARIABLES_LOADED(...)
	SkillHistoryDb = SkillHistoryDb or { scale = 1, maxIcons = 3, x_mod = 1, y_mod = 1, icon_duration = 3, icon_direction = "RIGHT", }
	MAXICONS = SkillHistoryDb.maxIcons
	DEFAULT_X_MOD = SkillHistoryDb.x_mod
	DEFAULT_Y_MOD = SkillHistoryDb.y_mod
	ICON_DURATION = SkillHistoryDb.icon_duration
	ICON_DIRECTION = SkillHistoryDb.icon_direction
	SkillHistory:CreateBar()
	
	SlashCmdList["SkillHistory"] = function (cmd) SkillHistory:SkillHistory_Command(cmd) end
	SLASH_SkillHistory1 = "/sh"
	ChatFrame1:AddMessage("SkillHistory loaded. Type /sh for options.",2,0,0)
	
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	-- Set basic values for the skillHistory.
	SkillHistory:SetBasicSkillHistoryFrameValues(skillHistoryFramePlayer,"player")
	SkillHistory:SetBasicSkillHistoryFrameValues(skillHistoryFrameParty1,"party1")
	SkillHistory:SetBasicSkillHistoryFrameValues(skillHistoryFrameParty2,"party2")
	
	CompactRaidFrameContainer:HookScript("OnEvent", SkillHistory.OnRosterUpdate)
	CompactRaidFrameContainer:HookScript("OnHide", SkillHistory.OnRosterHide)
	CompactRaidFrameContainer:HookScript("OnShow", SkillHistory.OnRosterUpdate)
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
					skillHistoryFramePlayer:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
				elseif(f and f.displayedUnit and UnitIsUnit("party1", f.displayedUnit)) then
					skillHistoryFrameParty1:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
				elseif(f and f.displayedUnit and UnitIsUnit("party2", f.displayedUnit)) then
					skillHistoryFrameParty2:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
				end
			end
		elseif CompactRaidFrameManager.container.groupMode == "discrete" then
			local test = _G["CompactPartyFrameMember1"]
			if ( test ) then
				for i = 1,5 do
					local f = _G["CompactPartyFrameMember"..i]
					if (f and f.displayedUnit and UnitIsUnit("player", f.displayedUnit)) then
						skillHistoryFramePlayer:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
					elseif(f and f.displayedUnit and UnitIsUnit("party1", f.displayedUnit)) then
						skillHistoryFrameParty1:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
					elseif(f and f.displayedUnit and UnitIsUnit("party2", f.displayedUnit)) then
						skillHistoryFrameParty2:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
					end
				end
			else 
				for i = 1,8 do
					for j = 1,5 do
						local f = _G["CompactRaidGroup"..i.."Member"..j]
						if (f and f.displayedUnit and UnitIsUnit("player", f.displayedUnit)) then
							skillHistoryFramePlayer:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
						elseif(f and f.displayedUnit and UnitIsUnit("party1", f.displayedUnit)) then
							skillHistoryFrameParty1:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
						elseif(f and f.displayedUnit and UnitIsUnit("party2", f.displayedUnit)) then
							skillHistoryFrameParty2:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT",1,3)
						end
					end
				end
			end
		end
	end
end

SkillHistory.frame:SetScript("OnEvent", function(self, event, ...)
	if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
		local event2 = select(2, ...)
		event = event.."_"..event2
	end

	if type(SkillHistory[event]) == "function" then
		SkillHistory[event](self, ...) -- call one of the functions above
	end
end)

for k, v in pairs(SkillHistory) do
	SkillHistory.frame:RegisterEvent(k) -- Register all events for which handlers have been defined
end