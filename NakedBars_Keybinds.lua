-- NakedBars — keybind labels on Blizzard Cooldown Manager icons
-- Loaded after NakedBars.lua; uses the shared NB addon table.
--
-- Each CDM icon's spell is matched against the spell (or macro spell) on
-- every action button; the first button with a binding supplies the key.
-- Buttons are read even while NakedBars has them faded out.

local addonName, NB = ...

------------------------------------------------------------------------
-- Viewers that get labels (the buff viewers track auras, not casts)
------------------------------------------------------------------------
local VIEWERS = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

------------------------------------------------------------------------
-- Action bar buttons → binding command prefix, in lookup priority order
------------------------------------------------------------------------
local BUTTON_BARS = {
    { button = "ActionButton",             command = "ACTIONBUTTON" },
    { button = "MultiBarBottomLeftButton",  command = "MULTIACTIONBAR1BUTTON" },
    { button = "MultiBarBottomRightButton", command = "MULTIACTIONBAR2BUTTON" },
    { button = "MultiBarRightButton",       command = "MULTIACTIONBAR3BUTTON" },
    { button = "MultiBarLeftButton",        command = "MULTIACTIONBAR4BUTTON" },
    { button = "MultiBar5Button",           command = "MULTIACTIONBAR5BUTTON" },
    { button = "MultiBar6Button",           command = "MULTIACTIONBAR6BUTTON" },
    { button = "MultiBar7Button",           command = "MULTIACTIONBAR7BUTTON" },
}

------------------------------------------------------------------------
-- Key abbreviation — order matters (NUMPADPLUS before NUMPAD, etc.)
------------------------------------------------------------------------
local KEY_ABBREVIATIONS = {
    { "SHIFT%-",        "S" },
    { "CTRL%-",         "C" },
    { "ALT%-",          "A" },
    { "META%-",         "M" },
    { "MOUSEWHEELUP",   "WU" },
    { "MOUSEWHEELDOWN", "WD" },
    { "MIDDLEMOUSE",    "M3" },
    { "BUTTON(%d+)",    "M%1" },
    { "NUMPADPLUS",     "N+" },
    { "NUMPADMINUS",    "N-" },
    { "NUMPADMULTIPLY", "N*" },
    { "NUMPADDIVIDE",   "N/" },
    { "NUMPADDECIMAL",  "N." },
    { "NUMPAD",         "N" },
    { "PAGEUP",         "PU" },
    { "PAGEDOWN",       "PD" },
    { "SPACE",          "Sp" },
    { "INSERT",         "Ins" },
    { "DELETE",         "Del" },
    { "HOME",           "Hm" },
    { "BACKSPACE",      "BS" },
    { "CAPSLOCK",       "Cap" },
}

local function AbbreviateKey(key)
    for _, rule in ipairs(KEY_ABBREVIATIONS) do
        key = key:gsub(rule[1], rule[2])
    end
    return key
end

-- Midnight can hand addons opaque "secret" values in combat; those can't
-- be compared or used as table keys, so treat them as unknown.
local function IsUsable(value)
    if value == nil then return false end
    if issecretvalue and issecretvalue(value) then return false end
    return true
end

------------------------------------------------------------------------
-- Spell → key map, rebuilt on every full refresh
------------------------------------------------------------------------
local spellKeys = {}

local function GetButtonKey(button, command)
    local key = GetBindingKey(command)
        or GetBindingKey("CLICK " .. button:GetName() .. ":LeftButton")
    return key and AbbreviateKey(key)
end

local function GetSlotSpell(slot)
    local actionType, id, subType = GetActionInfo(slot)
    if not IsUsable(id) then return nil end
    if actionType == "spell" then
        return id
    elseif actionType == "macro" then
        -- Newer clients report the macro's spell directly
        if subType == "spell" then return id end
        return GetMacroSpell(id)
    end
end

local function AddSpellKey(spellID, key)
    if not IsUsable(spellID) or spellKeys[spellID] then return end
    spellKeys[spellID] = key
    -- Bars hold the base spell; CDM may report an override (and vice versa)
    local base = FindBaseSpellByID and FindBaseSpellByID(spellID)
    if IsUsable(base) and not spellKeys[base] then
        spellKeys[base] = key
    end
end

local function BuildSpellKeys()
    wipe(spellKeys)
    for _, bar in ipairs(BUTTON_BARS) do
        for i = 1, 12 do
            local button = _G[bar.button .. i]
            -- button.action already reflects stance/form paging
            local slot = button and button.action
            if IsUsable(slot) and HasAction(slot) then
                local key = GetButtonKey(button, bar.command .. i)
                if key then
                    AddSpellKey(GetSlotSpell(slot), key)
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- CDM icon helpers
------------------------------------------------------------------------
local function GetItemSpellIDs(item)
    local info = item.cooldownInfo
    if not info and item.GetCooldownID and C_CooldownViewer then
        local cooldownID = item:GetCooldownID()
        if IsUsable(cooldownID) then
            info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
        end
    end
    if not info then return end
    return info.overrideSpellID, info.spellID, info.linkedSpellIDs
end

local function FindItemKey(item)
    local overrideID, spellID, linked = GetItemSpellIDs(item)
    if IsUsable(overrideID) and spellKeys[overrideID] then
        return spellKeys[overrideID]
    end
    if IsUsable(spellID) and spellKeys[spellID] then
        return spellKeys[spellID]
    end
    if type(linked) == "table" then
        for _, id in ipairs(linked) do
            if IsUsable(id) and spellKeys[id] then return spellKeys[id] end
        end
    end
end

-- Label lives on its own frame so it draws above the cooldown swipe
local function GetLabel(item)
    if item.NakedBarsKeybind then return item.NakedBarsKeybind end
    -- Our frame anchors to the icon; skip protected icons until combat ends
    if InCombatLockdown() and item:IsProtected() then return nil end

    local holder = CreateFrame("Frame", nil, item)
    holder:SetAllPoints()
    holder:SetFrameLevel(item:GetFrameLevel() + 10)

    local label = holder:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPRIGHT", -1, -2)
    label:SetJustifyH("RIGHT")
    item.NakedBarsKeybind = label
    return label
end

local function UpdateItem(item)
    local enabled = NakedBarsDB and NakedBarsDB.cdm.showKeybinds
    local label = item.NakedBarsKeybind
    if not enabled then
        if label then label:SetText("") end
        return
    end

    label = GetLabel(item)
    if not label then return end

    -- Scale with icon size; the essential viewer's icons are larger
    local size = math.max(10, math.floor((item:GetWidth() or 36) * 0.32))
    if label.nbSize ~= size then
        local fontFile = NumberFontNormal:GetFont()
        label:SetFont(fontFile, size, "OUTLINE")
        label.nbSize = size
    end
    label:SetText(FindItemKey(item) or "")
end

------------------------------------------------------------------------
-- Full refresh — coalesced to one pass per frame
------------------------------------------------------------------------
local hookedItems   = {}
local hookedViewers = {}
local refreshQueued = false

local function RefreshViewer(viewer)
    for _, item in ipairs({ viewer:GetChildren() }) do
        -- Only cooldown icons; skip any other child frames
        if item.GetCooldownID or item.cooldownInfo then
            if not hookedItems[item] and item.OnCooldownIDSet then
                hooksecurefunc(item, "OnCooldownIDSet", UpdateItem)
                hookedItems[item] = true
            end
            UpdateItem(item)
        end
    end
end

local function RefreshAll()
    refreshQueued = false
    if not NakedBarsDB then return end
    BuildSpellKeys()
    for _, name in ipairs(VIEWERS) do
        local viewer = _G[name]
        if viewer then
            if not hookedViewers[viewer] and viewer.RefreshLayout then
                hooksecurefunc(viewer, "RefreshLayout", NB.RefreshKeybinds)
                hookedViewers[viewer] = true
            end
            RefreshViewer(viewer)
        end
    end
end

-- Deferred a frame so Blizzard's own handlers (e.g. button.action paging)
-- have run first
function NB.RefreshKeybinds()
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(0, RefreshAll)
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
for _, event in ipairs({
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED",        -- create labels deferred during combat
    "UPDATE_BINDINGS",
    "ACTIONBAR_SLOT_CHANGED",
    "ACTIONBAR_PAGE_CHANGED",
    "UPDATE_BONUS_ACTIONBAR",
    "UPDATE_SHAPESHIFT_FORM",
    "PLAYER_SPECIALIZATION_CHANGED",
    "SPELLS_CHANGED",
}) do
    -- Some events don't exist on every client
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end
eventFrame:SetScript("OnEvent", NB.RefreshKeybinds)
