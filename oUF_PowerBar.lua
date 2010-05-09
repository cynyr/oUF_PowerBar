--[[

  Cynyr's Modification of the below authors mod

--]]

--[[

  Adrian L Lange grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.

--]]

--some settings have been moved to here, for easier changing
local minalpha = 0          --Minimum alpha to show the power bar at(OOC)
local maxalpha = 1          --Maximum alpha to show the power bar at(combat)
local pbn="oUF_PowerBar"    --Nice place for the name of the bar
local height=8              --Height of the power bar
local width=150             --Width of the power bar

--The texture for the bar.
local minimalist = [=[Interface\AddOns\oUF_PowerBar\media\minimalist]=]
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

--Function left in in case i decide to add the menu to that bar again.
local function menu(self)
	local drop = _G[string.gsub(self.unit, '(.)', string.upper, 1) .. 'FrameDropDown']
	if(drop) then
		ToggleDropDownMenu(1, nil, drop, 'cursor')
	end
end

local function oncombat(self)
    self:Show()
    self.Power:Show()
    self:SetBackdropColor(0, 0, 0, 1)
    DEFAULT_CHAT_FRAME:AddMessage("SHOW!")
end

local function onnocombat(self)
    self:Hide()
    self.Power:Hide()
    self:SetBackdropColor(0, 0, 0, 0)
    DEFAULT_CHAT_FRAME:AddMessage("HIDE!")
end

local function style(self, unit)
    if((select(2, UnitClass('player')) == 'ROGUE') or 
       (select(2, UnitClass('player')) == 'DRUID')
       ) then
	    self.colors = colors
	    --self.menu = menu
        
        --not having the below should make it clickthough-able.
	    --self:RegisterForClicks('AnyUp')
        
        --set the size of the frame.
        self:SetAttribute('initial-height', height)
	    self:SetAttribute('initial-width', width)
        
        --set the backdrop
	    self:SetBackdrop(backdrop)
	    self:SetBackdropColor(0, 0, 0, 1)
	    
        --create the a bar
	    self.Power = CreateFrame('StatusBar', nil, self)
        self.Power:SetAllPoints()
	    self.Power:SetStatusBarTexture(minimalist)
	    self.Power.frequentUpdates = true
        
        --color the bar, not all of these are needed i'm sure, but ohh well.
	    self.Power.colorClass = true
	    --self.Power.colorTapping = true
	    --self.Power.colorDisconnected = true
	    --self.Power.colorReaction = unit ~= 'pet'
	    --self.Power.colorHappiness = unit == 'pet'
	    --self.Power.colorPower = unit == 'pet'
        
        --get a font string and set it to the amount of power.
	    local power = self.Power:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
	    power:SetPoint('CENTER', self.Power, 'CENTER')
	    power.frequentUpdates = 0.1
	    self:Tag(power, '[ppower][( )druidpower]')
        
        --Use oUF_BarFader to fade the bar.
        if(unit=="player" and IsAddOnLoaded("oUF_BarFader")) then
            self.BarFade = true
            self.BarFaderMinAlpha = minalpha
            self.BarFaderMaxAlpha = maxalpha
        end
        --enable /omf for moving the frame.
        --actully /omf doesn't need addon support, but the otherone does.
    end
    self.Power:Hide()
    self:Hide()
    self:SetBackdropColor(0, 0, 0, 0)
    if (select(2, UnitClass('player')) == 'ROGUE') then 
        statestr = '[combat] bar; nobar'
    elseif (select(2, UnitClass('player')) == 'DRUID') then
        statestr = '[stance:3,combat] bar; nobar'
    end
    statestr = '[combat] bar; nobar'
    RegisterStateDriver(self, 'bar', statestr)
    self:SetAttribute('_onstate-bar', [[
    if(newstate == 'bar') then
			self:Show()
	else
			self:Hide()
	end
    ]])
    self:RegisterEvent('PLAYER_REGEN_DISABLED', oncombat)
    self:RegisterEvent('PLAYER_REGEN_ENABLED', onnocombat)
    --self.Power:Execute([[ POWER_FRAMES = newtable() ]])
    --self.Power:SetFrameRef("powerFrame", self)
    --self.Power:Execute([[
		--local frame = self:GetFrameRef("powerFrame")
		--table.insert(POWER_FRAMES, frame)
    --]])


end

--make sure oUF knows about us and uses us.
oUF:RegisterStyle('PowerBar', style)
oUF:SetActiveStyle('PowerBar')

--spawn the frame, needs to be tied to player.
--no support for other units is present
oUF:Spawn('player', pbn):SetPoint('CENTER', UIParent, 'CENTER')

if(select(2, UnitClass('player')) == 'DRUID') then
    local _STATE = CreateFrame("Frame", nil, UIParent, 'SecureHandlerStateTemplate')
    RegisterStateDriver(_STATE, 'kitty', '[stance:3,combat] cat; nocat')
 
    _STATE:SetAttribute('_onstate-kitty', [[
    if(newstate == 'cat') then
        for k, frame in pairs(CAT_FRAMES) do
            frame:SetAttribute('unit', frame:GetAttribute('oldUnit'))
            frame:SetAttribute('oldUnit', nil)
        end
    else
        for k, frame in pairs(CAT_FRAMES) do
            frame:SetAttribute('oldUnit', frame:GetAttribute('unit'))
            frame:SetAttribute('unit', nil)
        end
    end
    ]])
    _STATE:Execute[[
    CAT_FRAMES = newtable()
    ]]
 
    -- The frames in question.
    for _, frame in pairs{
        player,
        --target,
    } do
        _STATE:SetFrameRef('frame', frame)
        _STATE:Execute[[table.insert(CAT_FRAMES, self:GetFrameRef'frame')]]
    end
end
