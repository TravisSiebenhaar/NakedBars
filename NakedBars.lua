-- NakedBars — Hide your action bars with a single toggle
-- /bars  or  keybind  to toggle
-- Interface: 120001

local addonName = ...

------------------------------------------------------------------------
-- Keybind label (shows under "Other" in Key Bindings UI)
------------------------------------------------------------------------
BINDING_NAME_NAKEDBARS_TOGGLE = "NakedBars: Toggle Bar Visibility"

------------------------------------------------------------------------
-- Hidden-parent frame — children become invisible & non-interactive
------------------------------------------------------------------------
local hider = CreateFrame("Frame", "NakedBarsHider", UIParent)
hider:Hide()

------------------------------------------------------------------------
-- Action bar frames to hide (alpha + mouse-disable approach)
-- MainMenuBar does not exist in 12.x; bar 1 handled via ActionButton1-12
------------------------------------------------------------------------
local BAR_FRAMES = {
    "MultiBarBottomLeft",       -- Bar 2
    "MultiBarBottomRight",      -- Bar 3
    "MultiBarRight",            -- Bar 4
    "PetActionBar",
    "MicroMenuContainer",
    "BagsBar",
    "StatusTrackingBarManager",
}

------------------------------------------------------------------------
-- Cooldown Viewer frames — toggled INVERSELY to bars
-- (visible when bars hidden, hidden when bars visible)
------------------------------------------------------------------------
local CDM_FRAMES = {
    "EssentialCooldownViewer",  -- Blizzard Essential Cooldowns
    "UtilityCooldownViewer",    -- Blizzard Utility Cooldowns
    "BuffIconCooldownViewer",   -- Blizzard buff icon cooldown viewer
    "BuffBarCooldownViewer",    -- Blizzard buff bar cooldown viewer
    "CMCTracker1",              -- CMC addon tracker
    "CMCTracker2",              -- CMC addon tracker
}

------------------------------------------------------------------------
-- Helpers: hide / show a frame via alpha + mouse
------------------------------------------------------------------------
local function HideFrame(frame)
    frame:SetAlpha(0)
    if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.EnableKeyboard then frame:EnableKeyboard(false) end
end

local function ShowFrame(frame)
    frame:SetAlpha(1)
    if frame.EnableMouse then frame:EnableMouse(true) end
    if frame.EnableKeyboard then frame:EnableKeyboard(true) end
end

------------------------------------------------------------------------
-- Core: hide / show bars
------------------------------------------------------------------------
local function HideBars()
    -- Bar frames
    for _, name in ipairs(BAR_FRAMES) do
        local f = _G[name]
        if f then HideFrame(f) end
    end
    -- Bar 1 buttons (individually, since MainMenuBar is gone in 12.x)
    for i = 1, 12 do
        local btn = _G["ActionButton" .. i]
        if btn then HideFrame(btn) end
    end
end

local function ShowBars()
    for _, name in ipairs(BAR_FRAMES) do
        local f = _G[name]
        if f then ShowFrame(f) end
    end
    for i = 1, 12 do
        local btn = _G["ActionButton" .. i]
        if btn then ShowFrame(btn) end
    end
end

------------------------------------------------------------------------
-- Core: hide / show cooldown viewers (reparent into hider)
------------------------------------------------------------------------
local cdmOrigParents = {}

local function HideCDM()
    for _, name in ipairs(CDM_FRAMES) do
        local f = _G[name]
        if f then
            if not cdmOrigParents[name] then
                cdmOrigParents[name] = f:GetParent() or UIParent
            end
            f:SetParent(hider)
            f:SetAlpha(0)
        end
    end
end

local function ShowCDM()
    for _, name in ipairs(CDM_FRAMES) do
        local f = _G[name]
        if f then
            f:SetParent(cdmOrigParents[name] or UIParent)
            f:SetAlpha(1)
            f:Show()
        end
    end
end

------------------------------------------------------------------------
-- Apply current state
------------------------------------------------------------------------
local function ApplyState()
    if InCombatLockdown() then return end
    if NakedBarsDB.hidden then
        HideBars()
        ShowCDM()
    else
        ShowBars()
        HideCDM()
    end
end

------------------------------------------------------------------------
-- Toggle
------------------------------------------------------------------------
local pendingToggle = false

local function DoToggle()
    NakedBarsDB.hidden = not NakedBarsDB.hidden
    ApplyState()
    if NakedBarsDB.hidden then
        print("|cffff6060YOU'RE NAKED!!!|r")
    else
        print("|cff60ff60Bars restored. You're decent again.|r")
    end
end

function NakedBars_Toggle()
    if InCombatLockdown() then
        if not pendingToggle then
            pendingToggle = true
            print("|cffffcc00Can't toggle in combat — will toggle when combat ends.|r")
        end
        return
    end
    DoToggle()
end

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
SLASH_NAKEDBARS1 = "/bars"
SLASH_NAKEDBARS2 = "/nakedbars"
SlashCmdList["NAKEDBARS"] = function()
    NakedBars_Toggle()
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if NakedBarsDB == nil then
            NakedBarsDB = { hidden = false }
        end
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_ENTERING_WORLD" then
        ApplyState()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingToggle then
            pendingToggle = false
            DoToggle()
        else
            ApplyState()
        end
    end
end)
