-- The /uis window: a tab per module down the left, a slider and a
-- percentage box on the right. Changes apply live.

local ADDON, ns = ...

local ROW_H, SIDEBAR_W = 22, 170
local panel, tabs, selected = nil, {}, nil
local slider, input, header, status
local updating = false

local function pct(v) return math.floor(v * 100 + 0.5) end

local function refresh()
    for _, tab in ipairs(tabs) do
        local on = tab.module.key == selected.key
        tab.label:SetText(tab.module.name)
        tab.value:SetText(pct(ns.GetScale(tab.module.key)) .. "%")
        tab.bg:SetShown(on)
        tab.label:SetFontObject(on and "GameFontHighlight" or "GameFontNormal")
    end

    local scale = ns.GetScale(selected.key)
    updating = true
    slider:SetValue(pct(scale))
    updating = false
    input:SetText(pct(scale))
    header:SetText(selected.name)

    if #ns.LoadedFrames(selected.key) > 0 then
        status:SetText("|cff80ff80Loaded.|r Changes show immediately.")
    else
        status:SetText("|cffffd100Not loaded yet.|r Open this window once in\n"
            .. "game and your scale will be applied to it.")
    end
end

local function setScale(percent)
    if not percent then return end
    ns.SetScale(selected.key, percent / 100)
    refresh()
end

local function makeButton(parent, text, width)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    return b
end

local function build()
    panel = CreateFrame("Frame", "UIScalerFrame", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(560, #ns.MODULES * ROW_H + 80)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide()
    tinsert(UISpecialFrames, "UIScalerFrame") -- Escape closes it

    local title = panel.TitleText
    if not title then
        title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -5)
    end
    title:SetText("UI Scaler")

    -- Sidebar: one tab per module.
    for i, m in ipairs(ns.MODULES) do
        local tab = CreateFrame("Button", nil, panel)
        tab:SetSize(SIDEBAR_W, ROW_H)
        tab:SetPoint("TOPLEFT", 12, -30 - (i - 1) * ROW_H)
        tab.module = m

        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints()
        tab.bg:SetColorTexture(1, 0.82, 0, 0.18)

        local hl = tab:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)

        tab.label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.label:SetPoint("LEFT", 6, 0)
        tab.value = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tab.value:SetPoint("RIGHT", -6, 0)

        tab:SetScript("OnClick", function()
            selected = m
            refresh()
        end)
        tabs[i] = tab
    end

    -- Right-hand pane.
    local left = SIDEBAR_W + 40

    header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", left, -40)

    status = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", left, -70)
    status:SetJustifyH("LEFT")

    -- Built by hand rather than from OptionsSliderTemplate, which has been
    -- renamed or removed across client versions.
    slider = CreateFrame("Slider", nil, panel, "BackdropTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(260, 17)
    slider:SetPoint("TOPLEFT", left, -130)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetMinMaxValues(pct(ns.MIN), pct(ns.MAX))
    slider:SetValueStep(5)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouseWheel(true)
    slider:SetScript("OnValueChanged", function(_, value)
        if not updating then setScale(value) end
    end)
    slider:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta * 5)
    end)

    local low = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    low:SetText(pct(ns.MIN) .. "%")
    local high = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    high:SetText(pct(ns.MAX) .. "%")

    -- Type an exact percentage.
    input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    input:SetSize(44, 20)
    input:SetPoint("LEFT", slider, "RIGHT", 16, 0)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(3)
    input:SetScript("OnEnterPressed", function(self)
        setScale(tonumber(self:GetText()))
        self:ClearFocus()
    end)
    input:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        refresh()
    end)
    local sign = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sign:SetPoint("LEFT", input, "RIGHT", 4, 0)
    sign:SetText("%")

    -- Presets.
    local prev
    for _, p in ipairs({ 75, 90, 110, 125, 150 }) do
        local b = makeButton(panel, p .. "%", 52)
        if prev then
            b:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        else
            b:SetPoint("TOPLEFT", left, -180)
        end
        b:SetScript("OnClick", function() setScale(p) end)
        prev = b
    end

    local reset = makeButton(panel, "Reset to 100%", 130)
    reset:SetPoint("TOPLEFT", left, -216)
    reset:SetScript("OnClick", function()
        ns.Reset(selected.key)
        refresh()
    end)

    local resetAll = makeButton(panel, "Reset all", 100)
    resetAll:SetPoint("BOTTOMRIGHT", -16, 14)
    resetAll:SetScript("OnClick", function()
        ns.ResetAll()
        refresh()
    end)

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", left, 20)
    hint:SetText("Tip: scroll the mouse wheel over the slider.")

    panel:SetScript("OnShow", refresh)
    selected = ns.MODULES[1]
end

function ns.Toggle()
    if not panel then build() end
    panel:SetShown(not panel:IsShown())
end

SLASH_UISCALER1 = "/uis"
SLASH_UISCALER2 = "/uiscaler"
SlashCmdList.UISCALER = ns.Toggle

-- A stub page in the game's own AddOns settings that opens the real window.
local stub = CreateFrame("Frame")
stub.name = "UI Scaler"
local open = makeButton(stub, "Open UI Scaler", 160)
open:SetPoint("TOPLEFT", 16, -16)
open:SetScript("OnClick", function()
    if SettingsPanel then HideUIPanel(SettingsPanel) end
    if InterfaceOptionsFrame then HideUIPanel(InterfaceOptionsFrame) end
    if not (panel and panel:IsShown()) then ns.Toggle() end
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(stub, stub.name)
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(stub)
end
