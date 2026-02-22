-- NakedBars — Blizzard-style settings panel
-- Loaded after NakedBars.lua; uses the shared NB addon table.

local addonName, NB = ...

------------------------------------------------------------------------
-- Checkbox factory (Blizzard-standard textures)
------------------------------------------------------------------------
local function CreateNBCheckbox(parent, x, y, label, tooltipText, checked, onClickFunc)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", x, y)

    cb:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]])
    cb:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]])
    cb:SetHighlightTexture([[Interface\Buttons\UI-CheckBox-Highlight]])
    cb:GetHighlightTexture():SetBlendMode("ADD")
    cb:SetCheckedTexture([[Interface\Buttons\UI-CheckBox-Check]])
    cb:SetDisabledCheckedTexture([[Interface\Buttons\UI-CheckBox-Check-Disabled]])

    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    cb.label:SetText(label)

    -- Extend click-region to cover the label text
    cb:SetHitRectInsets(0, -(cb.label:GetStringWidth() + 6), 0, 0)
    cb:SetChecked(checked)

    cb:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        PlaySound(isChecked and 856 or 857)
        if onClickFunc then onClickFunc(self, isChecked) end
    end)

    if tooltipText then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", GameTooltip_Hide)
    end

    return cb
end

------------------------------------------------------------------------
-- Section header with separator line
------------------------------------------------------------------------
local function CreateSectionHeader(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 16, y)
    fs:SetTextColor(1, 0.82, 0) -- Blizzard gold
    fs:SetText(text)

    local lineY = y - fs:GetStringHeight() - 2
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 16, lineY)
    line:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    return lineY - 10 -- next y position
end

------------------------------------------------------------------------
-- Build the panel
------------------------------------------------------------------------
local function BuildPanel()
    local canvas = CreateFrame("Frame", "NakedBarsOptionsPanel")
    canvas:SetAllPoints()
    canvas:Hide()

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, canvas, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -22, 4)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(560)
    scrollFrame:SetScrollChild(content)

    local refreshCallbacks = {}
    local y = -16

    ----------------------------------------------------------------
    -- Title
    ----------------------------------------------------------------
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, y)
    title:SetText("NakedBars")
    y = y - 24

    -- Description
    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 16, y)
    desc:SetPoint("RIGHT", content, "RIGHT", -16, 0)
    desc:SetJustifyH("LEFT")
    desc:SetText(
        "Toggle UI elements with |cff00ff00/bars|r or a keybind. "
        .. "Open this panel with |cff00ff00/bars config|r. "
        .. "Check the elements you want included in the toggle."
    )
    y = y - (desc:GetStringHeight() or 14) - 10

    -- Keybind info
    local keybindText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keybindText:SetPoint("TOPLEFT", 16, y)

    table.insert(refreshCallbacks, function()
        local key = GetBindingKey("NAKEDBARS_TOGGLE")
        if key then
            keybindText:SetText("Keybind:  |cff00ff00" .. key .. "|r")
        else
            keybindText:SetText(
                "Keybind:  |cffff6060Not Set|r   "
                .. "|cff888888(Key Bindings \226\128\186 Other)|r"
            )
        end
    end)
    y = y - 24

    -- Divider
    local topDiv = content:CreateTexture(nil, "ARTWORK")
    topDiv:SetHeight(1)
    topDiv:SetPoint("TOPLEFT", 16, y)
    topDiv:SetPoint("RIGHT", content, "RIGHT", -16, 0)
    topDiv:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    y = y - 14

    ----------------------------------------------------------------
    -- Column offsets
    ----------------------------------------------------------------
    local col1X, col2X = 24, 280

    ----------------------------------------------------------------
    -- Action Bars
    ----------------------------------------------------------------
    y = CreateSectionHeader(content, "Action Bars", y)

    local barDefs = {}
    for _, def in ipairs(NB.ELEMENT_DEFS) do
        if def.category == "Action Bars" then
            table.insert(barDefs, def)
        end
    end

    for i, def in ipairs(barDefs) do
        local x = ((i - 1) % 2 == 0) and col1X or col2X
        local cb = CreateNBCheckbox(content, x, y, def.label, def.tooltip,
            NakedBarsDB.elements[def.key],
            function(_, checked)
                NakedBarsDB.elements[def.key] = checked
                NB:ApplyState()
            end)
        table.insert(refreshCallbacks, function()
            cb:SetChecked(NakedBarsDB.elements[def.key])
        end)
        if (i % 2 == 0) or i == #barDefs then
            y = y - 30
        end
    end
    y = y - 6

    ----------------------------------------------------------------
    -- UI Elements
    ----------------------------------------------------------------
    y = CreateSectionHeader(content, "UI Elements", y)

    local uiDefs = {}
    for _, def in ipairs(NB.ELEMENT_DEFS) do
        if def.category == "UI Elements" then
            table.insert(uiDefs, def)
        end
    end

    for i, def in ipairs(uiDefs) do
        local x = ((i - 1) % 2 == 0) and col1X or col2X
        local cb = CreateNBCheckbox(content, x, y, def.label, def.tooltip,
            NakedBarsDB.elements[def.key],
            function(_, checked)
                NakedBarsDB.elements[def.key] = checked
                NB:ApplyState()
            end)
        table.insert(refreshCallbacks, function()
            cb:SetChecked(NakedBarsDB.elements[def.key])
        end)
        if (i % 2 == 0) or i == #uiDefs then
            y = y - 30
        end
    end
    y = y - 6

    ----------------------------------------------------------------
    -- Cooldown Manager
    ----------------------------------------------------------------
    y = CreateSectionHeader(content, "Cooldown Manager", y)

    -- Explanatory text
    local cdmDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cdmDesc:SetPoint("TOPLEFT", 24, y)
    cdmDesc:SetPoint("RIGHT", content, "RIGHT", -24, 0)
    cdmDesc:SetJustifyH("LEFT")
    cdmDesc:SetText(
        "When bars are hidden, cooldown trackers can appear in their place "
        .. "so you can monitor abilities without cluttering your screen. "
        .. "Select which trackers to display."
    )
    y = y - (cdmDesc:GetStringHeight() or 28) - 12

    -- Master toggle
    local cdmSubCheckboxes = {}

    local function SetCDMSubsEnabled(enabled)
        for _, sub in ipairs(cdmSubCheckboxes) do
            if enabled then
                sub:Enable()
                sub.label:SetTextColor(1, 1, 1)
            else
                sub:Disable()
                sub.label:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end

    local cdmMaster = CreateNBCheckbox(content, col1X, y,
        "Enable Cooldown Overlay",
        "Master toggle — show selected cooldown trackers when bars are hidden.",
        NakedBarsDB.cdm.enabled,
        function(_, checked)
            NakedBarsDB.cdm.enabled = checked
            SetCDMSubsEnabled(checked)
            NB:ApplyState()
        end)

    table.insert(refreshCallbacks, function()
        cdmMaster:SetChecked(NakedBarsDB.cdm.enabled)
    end)
    y = y - 34

    -- Sub-divider
    local cdmDiv = content:CreateTexture(nil, "ARTWORK")
    cdmDiv:SetHeight(1)
    cdmDiv:SetPoint("TOPLEFT", 36, y)
    cdmDiv:SetPoint("RIGHT", content, "RIGHT", -36, 0)
    cdmDiv:SetColorTexture(0.4, 0.4, 0.4, 0.3)
    y = y - 10

    -- Individual CDM checkboxes
    for i, def in ipairs(NB.CDM_DEFS) do
        local x = ((i - 1) % 2 == 0) and (col1X + 12) or col2X
        local cb = CreateNBCheckbox(content, x, y, def.label, def.tooltip,
            NakedBarsDB.cdm[def.key],
            function(_, checked)
                NakedBarsDB.cdm[def.key] = checked
                NB:ApplyState()
            end)
        table.insert(cdmSubCheckboxes, cb)
        table.insert(refreshCallbacks, function()
            cb:SetChecked(NakedBarsDB.cdm[def.key])
            if NakedBarsDB.cdm.enabled then
                cb:Enable()
                cb.label:SetTextColor(1, 1, 1)
            else
                cb:Disable()
                cb.label:SetTextColor(0.5, 0.5, 0.5)
            end
        end)
        if (i % 2 == 0) or i == #NB.CDM_DEFS then
            y = y - 30
        end
    end

    -- Apply initial disabled state
    if not NakedBarsDB.cdm.enabled then
        SetCDMSubsEnabled(false)
    end

    ----------------------------------------------------------------
    -- Set scroll-child height
    ----------------------------------------------------------------
    content:SetHeight(math.abs(y) + 20)

    ----------------------------------------------------------------
    -- Refresh all widgets when the panel is shown
    ----------------------------------------------------------------
    canvas:SetScript("OnShow", function()
        for _, fn in ipairs(refreshCallbacks) do fn() end
    end)

    return canvas
end

------------------------------------------------------------------------
-- Register with Blizzard Settings
------------------------------------------------------------------------
local function RegisterSettings()
    local canvas = BuildPanel()
    local category = Settings.RegisterCanvasLayoutCategory(canvas, "NakedBars")
    Settings.RegisterAddOnCategory(category)
    NB.settingsCategoryID = category:GetID()
end

------------------------------------------------------------------------
-- Open settings panel (called from /bars config)
------------------------------------------------------------------------
function NB:OpenSettings()
    if self.settingsCategoryID then
        Settings.OpenToCategory(self.settingsCategoryID)
    end
end

------------------------------------------------------------------------
-- Callback — invoked by NakedBars.lua after DB is ready
------------------------------------------------------------------------
NB.RegisterOptions = RegisterSettings
