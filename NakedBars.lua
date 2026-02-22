-- NakedBars — Hide your action bars with a single toggle
-- /bars  or  keybind  to toggle  |  /bars config  to open settings
-- Interface: 120001

local addonName, NB = ...

------------------------------------------------------------------------
-- Keybind label (shows in Key Bindings UI under "Other")
------------------------------------------------------------------------
BINDING_NAME_NAKEDBARS_TOGGLE = "NakedBars: Toggle Bar Visibility"

------------------------------------------------------------------------
-- Hidden-parent frame — CDM frames are reparented here to vanish
------------------------------------------------------------------------
local hider = CreateFrame("Frame", "NakedBarsHider", UIParent)
hider:Hide()
NB.hider = hider

------------------------------------------------------------------------
-- Default saved-variable values
------------------------------------------------------------------------
NB.DEFAULTS = {
    hidden = false,
    elements = {
        actionBar1 = true,
        actionBar2 = true,
        actionBar3 = true,
        actionBar4 = true,
        actionBar5 = false,
        actionBar6 = false,
        actionBar7 = false,
        actionBar8 = false,
        petBar     = true,
        microMenu  = true,
        bagsBar    = true,
        xpBar      = true,
        chat       = false,
        objectives = false,
        minimap    = false,
    },
    cdm = {
        enabled            = true,
        essentialCooldowns = true,
        utilityCooldowns   = true,
        buffIconCooldowns  = true,
        buffBarCooldowns   = true,
        cmcTracker1        = true,
        cmcTracker2        = true,
    },
}

------------------------------------------------------------------------
-- Element registry — config key → frame name(s)
-- Uses alpha + mouse-disable approach
-- (actionBar1 is handled separately via ActionButton1-12)
------------------------------------------------------------------------
NB.ELEMENT_MAP = {
    actionBar2  = { "MultiBarBottomLeft" },
    actionBar3  = { "MultiBarBottomRight" },
    actionBar4  = { "MultiBarRight" },
    actionBar5  = { "MultiBarLeft" },
    actionBar6  = { "MultiBar5" },
    actionBar7  = { "MultiBar6" },
    actionBar8  = { "MultiBar7" },
    petBar      = { "PetActionBar" },
    microMenu   = { "MicroMenuContainer" },
    bagsBar     = { "BagsBar" },
    xpBar       = { "StatusTrackingBarManager" },
    chat        = { "ChatFrame1" },
    objectives  = { "ObjectiveTrackerFrame" },
    minimap     = { "MinimapCluster" },
}

------------------------------------------------------------------------
-- CDM registry — config key → frame name
-- Reparented into hider (inverse toggle: shown when bars hidden)
------------------------------------------------------------------------
NB.CDM_MAP = {
    essentialCooldowns = "EssentialCooldownViewer",
    utilityCooldowns   = "UtilityCooldownViewer",
    buffIconCooldowns  = "BuffIconCooldownViewer",
    buffBarCooldowns   = "BuffBarCooldownViewer",
    cmcTracker1        = "CMCTracker1",
    cmcTracker2        = "CMCTracker2",
}

------------------------------------------------------------------------
-- Ordered definitions for the options UI
------------------------------------------------------------------------
NB.ELEMENT_DEFS = {
    -- Action Bars
    { key = "actionBar1", label = "Action Bar 1", category = "Action Bars",
      tooltip = "The primary action bar (buttons 1-12)." },
    { key = "actionBar2", label = "Action Bar 2", category = "Action Bars",
      tooltip = "Bottom-left multi-bar." },
    { key = "actionBar3", label = "Action Bar 3", category = "Action Bars",
      tooltip = "Bottom-right multi-bar." },
    { key = "actionBar4", label = "Action Bar 4", category = "Action Bars",
      tooltip = "Right-side multi-bar." },
    { key = "actionBar5", label = "Action Bar 5", category = "Action Bars",
      tooltip = "Left-side multi-bar." },
    { key = "actionBar6", label = "Action Bar 6", category = "Action Bars",
      tooltip = "Additional action bar 6." },
    { key = "actionBar7", label = "Action Bar 7", category = "Action Bars",
      tooltip = "Additional action bar 7." },
    { key = "actionBar8", label = "Action Bar 8", category = "Action Bars",
      tooltip = "Additional action bar 8." },
    -- UI Elements
    { key = "petBar",     label = "Pet Action Bar",    category = "UI Elements",
      tooltip = "The pet action bar." },
    { key = "microMenu",  label = "Micro Menu",        category = "UI Elements",
      tooltip = "Character, Spellbook, Talents, etc." },
    { key = "bagsBar",    label = "Bags Bar",           category = "UI Elements",
      tooltip = "The bag-slot buttons." },
    { key = "xpBar",      label = "XP / Rep Bar",      category = "UI Elements",
      tooltip = "Experience and reputation tracking bar." },
    { key = "chat",       label = "Chat",               category = "UI Elements",
      tooltip = "The chat window. You can still type by pressing Enter." },
    { key = "objectives", label = "Objectives Tracker", category = "UI Elements",
      tooltip = "Quest and achievement tracker." },
    { key = "minimap",    label = "Minimap",            category = "UI Elements",
      tooltip = "The minimap and surrounding buttons." },
}

NB.CDM_DEFS = {
    { key = "essentialCooldowns", label = "Essential Cooldowns",
      tooltip = "Blizzard essential-cooldown viewer (major abilities)." },
    { key = "utilityCooldowns",   label = "Utility Cooldowns",
      tooltip = "Blizzard utility-cooldown viewer (defensives, interrupts, etc.)." },
    { key = "buffIconCooldowns",  label = "Buff Icon Cooldowns",
      tooltip = "Blizzard buff-icon cooldown viewer." },
    { key = "buffBarCooldowns",   label = "Buff Bar Cooldowns",
      tooltip = "Blizzard buff-bar cooldown viewer." },
    { key = "cmcTracker1",        label = "CMC Tracker 1",
      tooltip = "Cooldown Manager Companion tracker 1 (third-party addon)." },
    { key = "cmcTracker2",        label = "CMC Tracker 2",
      tooltip = "Cooldown Manager Companion tracker 2 (third-party addon)." },
}

------------------------------------------------------------------------
-- Internal tracking — we only restore frames we have actually hidden
------------------------------------------------------------------------
local modifiedFrames = {}

local function HideFrame(frame)
    frame:SetAlpha(0)
    if frame.EnableMouse    then frame:EnableMouse(false) end
    if frame.EnableKeyboard then frame:EnableKeyboard(false) end
    modifiedFrames[frame] = true
end

local function ShowFrame(frame)
    if not modifiedFrames[frame] then return end
    frame:SetAlpha(1)
    if frame.EnableMouse    then frame:EnableMouse(true) end
    if frame.EnableKeyboard then frame:EnableKeyboard(true) end
    modifiedFrames[frame] = nil
end

------------------------------------------------------------------------
-- CDM parent cache
------------------------------------------------------------------------
local cdmOrigParents = {}

------------------------------------------------------------------------
-- Apply state — reconciles every element against saved settings
------------------------------------------------------------------------
function NB:ApplyState()
    if InCombatLockdown() then return end

    local db     = NakedBarsDB
    local hidden = db.hidden

    -- Bar 1 — individual buttons (MainMenuBar absent in 12.x)
    for i = 1, 12 do
        local btn = _G["ActionButton" .. i]
        if btn then
            if hidden and db.elements.actionBar1 then
                HideFrame(btn)
            else
                ShowFrame(btn)
            end
        end
    end

    -- All other alpha-based elements
    for key, frameNames in pairs(self.ELEMENT_MAP) do
        for _, name in ipairs(frameNames) do
            local f = _G[name]
            if f then
                if hidden and db.elements[key] then
                    HideFrame(f)
                else
                    ShowFrame(f)
                end
            end
        end
    end

    -- CDM (inverse: show when bars hidden, hide when bars visible)
    for key, frameName in pairs(self.CDM_MAP) do
        local f = _G[frameName]
        if f then
            if hidden and db.cdm.enabled and db.cdm[key] then
                -- Restore CDM frame to original parent
                local orig = cdmOrigParents[frameName]
                if orig then f:SetParent(orig) end
                f:SetAlpha(1)
                f:Show()
            else
                -- Park CDM frame in hider
                if not cdmOrigParents[frameName] then
                    cdmOrigParents[frameName] = f:GetParent() or UIParent
                end
                f:SetParent(hider)
                f:SetAlpha(0)
            end
        end
    end
end

------------------------------------------------------------------------
-- Toggle
------------------------------------------------------------------------
local pendingToggle = false

local function DoToggle()
    NakedBarsDB.hidden = not NakedBarsDB.hidden
    NB:ApplyState()
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

SlashCmdList["NAKEDBARS"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "config" or msg == "options" or msg == "settings" then
        if NB.OpenSettings then
            NB:OpenSettings()
        end
    else
        NakedBars_Toggle()
    end
end

------------------------------------------------------------------------
-- Database initialisation — deep-merge defaults into saved variables
------------------------------------------------------------------------
local function InitDB()
    if not NakedBarsDB then NakedBarsDB = {} end
    for k, v in pairs(NB.DEFAULTS) do
        if type(v) == "table" then
            if type(NakedBarsDB[k]) ~= "table" then
                NakedBarsDB[k] = {}
            end
            for kk, vv in pairs(v) do
                if NakedBarsDB[k][kk] == nil then
                    NakedBarsDB[k][kk] = vv
                end
            end
        else
            if NakedBarsDB[k] == nil then
                NakedBarsDB[k] = v
            end
        end
    end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        -- Let options panel build now that DB is ready
        if NB.RegisterOptions then NB.RegisterOptions() end
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_ENTERING_WORLD" then
        NB:ApplyState()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingToggle then
            pendingToggle = false
            DoToggle()
        else
            NB:ApplyState()
        end
    end
end)
