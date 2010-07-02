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

local function style(self, unit)
    if((select(2, UnitClass('player')) == 'ROGUE') or 
       (select(2, UnitClass('player')) == 'DRUID')
       ) then
	    self.colors = colors
        
        --not having the below should make it clickthough-able.
	    --self:RegisterForClicks('AnyUp')
        
        --set the size of the frame.
        self:SetAttribute('initial-height', height)
	    self:SetAttribute('initial-width', width)
        
        --set the backdrop
	    self:SetBackdrop(backdrop)
	    self:SetBackdropColor(0, 0, 0, 0.5)
	    
        --create the a bar
	    self.Power = CreateFrame('StatusBar', nil, self)
        self.Power:SetAllPoints()
	    self.Power:SetStatusBarTexture(minimalist)
	    self.Power.frequentUpdates = true
        
        --color the bar, not all of these are needed i'm sure, but ohh well.
	    self.Power.colorClass = true
	    self.Power.colorTapping = true
	    self.Power.colorDisconnected = true
	    self.Power.colorReaction = unit ~= 'pet'
	    self.Power.colorHappiness = unit == 'pet'
	    self.Power.colorPower = unit == 'pet'
        
        --get a font string and set it to the amount of power.
	    local power = self.Power:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
	    power:SetPoint('CENTER', self.Power, 'CENTER')
	    power.frequentUpdates = 0.1
	    self:Tag(power, '[ppower][druidpower]')
        
        --Use oUF_BarFader to fade the bar.
        if(unit=="player" and IsAddOnLoaded("oUF_BarFader")) then
            self.BarFade = true
            self.BarFaderMinAlpha = minalpha
            self.BarFaderMaxAlpha = maxalpha
        end
        --enable /omf for moving the frame.
        --actully /omf doesn't need addon support, but the otherone does.
    end
end

--make sure oUF knows about us and uses us.
oUF:RegisterStyle('PowerBar', style)
oUF:SetActiveStyle('PowerBar')

--spawn the frame, needs to be tied to player.
--no support for other units is present
local player = oUF:Spawn('player', pbn)
player:SetPoint('CENTER', UIParent, 'CENTER')
--Set the oldUnit to 'player' so that the frame will show correctly.
player:SetAttribute('oldUnit', 'player')
--set unit to nil to hide the frame by default
player:SetAttribute('unit', nil)

driverstr=''
if(select(2, UnitClass('player')) == 'DRUID') then
    driverstr = '[stance:3,combat] show; hide'
elseif(select(2, UnitClass('player')) == 'ROGUE') then
    driverstr = '[combat] show; [stance:1] show; hide'
end

if(driverstr ~= '') then
    --create a secure frame to run code fo us in combat.
    --it must be a inherant SecureHandlerStateTemplate to work
    local _STATE = CreateFrame("Frame", nil, UIParent,
                               'SecureHandlerStateTemplate')
    --Register for a "macro" state. any valid macro conditional works here
    RegisterStateDriver(_STATE, 'kitty', driverstr)
    --self, stateid, newstate will be set for you inside the [[foo]]
    --Setting attr 'unit' to nil, makes the frame go away, setting it to
    -- to 'player', 'target', etc. 
    _STATE:SetAttribute('_onstate-kitty', [[
    if(newstate == 'show') then
        local frame = self:GetFrameRef('powerbar')
        frame:SetAttribute('unit', frame:GetAttribute('oldUnit'))
        frame:SetAttribute('oldUnit', nil)
    else
        local frame = self:GetFrameRef('powerbar')
        frame:SetAttribute('oldUnit', frame:GetAttribute('unit'))
        frame:SetAttribute('unit', nil)
    end
    ]])
    --with a single frame this seems to be a better idea.
    --This lets us set a referance to a frame.
    --SetFrameRef('NAME', frameobject)
    _STATE:SetFrameRef('powerbar', player)

    --The below would be for doing a large number of frames at once.
    --You need to iterate over the table in the _onstate-foo code to get
    -- the frames you so you can show/hide them by changing the unit to nil
    -- this will cause the frame to dissapear.
    --
    --Create a table in the secure frame to hold a list of frame objects.
    --_STATE:Execute[[
    --CAT_FRAMES = newtable()
    --]]
 
    ---- The frame objects in question.
    --for _, frame in pairs{
        --player,
        ----target,
    --} do
        --Set a referance inside of _STATE to the frame.
        --_STATE:SetFrameRef('frame', frame) 
        --add the referance to the CAT_FRAMES table.
        --_STATE:Execute([[table.insert(CAT_FRAMES, self:GetFrameRef('frame'))]])
    --end
end
