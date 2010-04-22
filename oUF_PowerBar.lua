--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

--some settings have been omved to here, for easier changing
local minalpha = 0
local maxalpha = 1
local castbaroffset = 80
local castbarheight = 16
local castbarbuttonsize = 21
local playertargetheight = 27
local playertargetwidth = 180
local petheight = 27
local petwidth = 130
local focustargettargetheight = 20
local focustargettargetwidth = playertargetwidth * .80
local debuffsize = 10
local hideparty=true
local showenergybar=true
local pbn="oUF_Cynyr_power"



local max = math.max
local floor = math.floor

local minimalist = [=[Interface\AddOns\oUF_Cynyr\media\minimalist]=]
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local colors = setmetatable({
	power = setmetatable({
		MANA = {0, 144/255, 1}
	}, {__index = oUF.colors.power}),
	reaction = setmetatable({
		[2] = {1, 0, 0},
		[4] = {1, 1, 0},
		[5] = {0, 1, 0}
	}, {__index = oUF.colors.reaction}),
	runes = setmetatable({
		[1] = {0.8, 0, 0},
		[3] = {0, 0.4, 0.7},
		[4] = {0.8, 0.8, 0.8}
	}, {__index = oUF.colors.runes})
}, {__index = oUF.colors})

local buffFilter = {
	[GetSpellInfo(62600)] = true,
	[GetSpellInfo(61336)] = true,
	[GetSpellInfo(52610)] = true,
	[GetSpellInfo(22842)] = true,
	[GetSpellInfo(22812)] = true,
	[GetSpellInfo(16870)] = true
}

local function menu(self)
	local drop = _G[string.gsub(self.unit, '(.)', string.upper, 1) .. 'FrameDropDown']
	if(drop) then
		ToggleDropDownMenu(1, nil, drop, 'cursor')
	end
end

local function updateCombo(self, event, unit)
	if(unit == PlayerFrame.unit and unit ~= self.CPoints.unit) then
		self.CPoints.unit = unit
	end
end

local function updatePower(self, event, unit, bar, minVal, maxVal)
	if(unit ~= 'target') then 
        return
    end

	if(maxVal ~= 0) then
		self.Health:SetHeight(22)
		bar:Show()
	else
		self.Health:SetHeight(27)
		bar:Hide()
	end
end

local function castIcon(self, event, unit)
	local castbar = self.Castbar
	if(castbar.interrupt) then
		castbar.Button:SetBackdropColor(0, 0.9, 1)
	else
		castbar.Button:SetBackdropColor(0, 0, 0)
	end
end

local function castTime(self, duration)
	if(self.channeling) then
		self.Time:SetFormattedText('%.1f ', duration)
	elseif(self.casting) then
		self.Time:SetFormattedText('%.1f ', self.max - duration)
	end
end

local function updateTime(self, elapsed)
	self.remaining = max(self.remaining - elapsed, 0)
	self.time:SetText(self.remaining < 90 and floor(self.remaining) or '')
end

local function updateBuff(self, icons, unit, icon, index)
	local _, _, _, _, _, duration, expiration = UnitAura(unit, index, icon.filter)

	if(duration > 0 and expiration) then
		icon.remaining = expiration - GetTime()
		icon:SetScript('OnUpdate', updateTime)
	else
		icon:SetScript('OnUpdate', nil)
		icon.time:SetText()
	end
end

local function updateDebuff(self, icons, unit, icon, index)
	local _, _, _, _, dtype = UnitAura(unit, index, icon.filter)

	if(icon.debuff) then
		if(not UnitIsFriend('player', unit) and icon.owner ~= 'player' and icon.owner ~= 'vehicle') then
			icon:SetBackdropColor(0, 0, 0)
			icon.icon:SetDesaturated(true)
		else
			local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
			icon:SetBackdropColor(color.r * 0.6, color.g * 0.6, color.b * 0.6)
			icon.icon:SetDesaturated(false)
		end
	end
end

local function createAura(self, button, icons)
	icons.showDebuffType = true

	button.cd:SetReverse()
	button:SetBackdrop(backdrop)
	button:SetBackdropColor(0, 0, 0)
	button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	button.icon:SetDrawLayer('ARTWORK')
	button.overlay:SetTexture()

	if(self.unit == 'player') then
		icons.disableCooldown = true

		button.time = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
		button.time:SetPoint('TOPLEFT', button)
	end
end

local function customFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, expiration, caster)
	if(buffFilter[name] and caster == 'player') then
		return true
	end
end

local function style(self, unit)
	self.colors = colors
	self.menu = menu

	self:RegisterForClicks('AnyUp')
	self:SetAttribute('type2', 'menu')

	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)
    self.Health = CreateFrame('StatusBar', nil, self)
    self.Health:SetPoint('TOPRIGHT')
    self.Health:SetPoint('TOPLEFT')
    self.Health:SetStatusBarTexture(minimalist)
    self.Health:SetStatusBarColor(0.25, 0.25, 0.35)
    --self.Health:SetHeight((unit == 'focus' or unit == 'targettarget') and 20 or 22)
    self.Health:SetHeight(22)
    self.Health.frequentUpdates = true

    self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
    self.Health.bg:SetAllPoints(self.Health)
    self.Health.bg:SetTexture(0.3, 0.3, 0.3)
	
	self.Power = CreateFrame('StatusBar', nil, self)
	self.Power:SetPoint('BOTTOMRIGHT')
	self.Power:SetPoint('BOTTOMLEFT')
	self.Power:SetPoint('TOP', self.Health, 'BOTTOM', 0, -1)
	self.Power:SetStatusBarTexture(minimalist)
	self.Power.frequentUpdates = true

	--self.Power.colorClass = true
	--self.Power.colorTapping = true
	--self.Power.colorDisconnected = true
	--self.Power.colorReaction = unit ~= 'pet'
	--self.Power.colorHappiness = unit == 'pet'
	--self.Power.colorPower = unit == 'pet'

	self.Power.bg = self.Power:CreateTexture(nil, 'BORDER')
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
	self.Power.bg.multiplier = 0.3

	local power = self.Health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
	power:SetPoint('LEFT', self.Health, 2, -1)
	power.frequentUpdates = 0.1
	self:Tag(power, '[ppower][( )druidpower]')

	self.PostUpdatePower = updatePower
    if(unit=="player" and IsAddOnLoaded("oUF_BarFader")) then
        self.BarFade = true
        self.BarFaderMinAlpha = minalpha
        self.BarFaderMaxAlpha = maxalpha
    end
	--self.DebuffHighlightBackdrop = true
	--self.DebuffHighlightFilter = true
    self.MoveableFrames = true
end

oUF:RegisterStyle('Cynyr', style)
oUF:SetActiveStyle('Cynyr')

oUF:Spawn('player', "oUF_Cynyr_player"):SetPoint('CENTER', UIParent, -220, -250)

