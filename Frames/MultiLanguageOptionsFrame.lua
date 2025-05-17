local addonName = ...
local optionsFrame = CreateFrame("Frame")
local gameLocale = GetLocale()
local gameLanguage = string.sub(gameLocale, 1, 2)
local defaultOptions = nil
local optionsTranslations = nil

-- General functions
local function CreateOptionDropdown(parent, relativeFrame, offsetX, offsetY, label, defaultValueLabel, optionKey, selectedKey, translationKey)
    local dropdownLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropdownLabel:SetText(label)
    dropdownLabel:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", offsetX, offsetY - 10)

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -20, -4)

    local selectedOptionLabel = defaultValueLabel

    local function InitializeDropdownOptions()
        local info = UIDropDownMenu_CreateInfo()

        local function OnDropdownValueChanged(self, arg1, arg2, checked)
            MultiLanguageOptions[selectedKey] = arg1
            UIDropDownMenu_SetText(dropdown, arg2)
        end

        for index, value in ipairs(MultiLanguageOptions[optionKey]) do
            info.text = optionsTranslations[translationKey][value.value]
            info.value = value.value
            info.arg1 = info.value
            info.arg2 = info.text
            info.checked = MultiLanguageOptions[selectedKey] == value.value
            info.func = OnDropdownValueChanged
            info.minWidth = 150

            if info.checked then
                selectedOptionLabel = optionsTranslations[translationKey][value.value]
            end

            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(dropdown, InitializeDropdownOptions)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, selectedOptionLabel)
    UIDropDownMenu_SetAnchor(dropdown, 0, 0, "TOPLEFT", dropdown)

    return {
        frame = dropdown,
        reinitialize = function()
            UIDropDownMenu_Initialize(dropdown, InitializeDropdownOptions)
        end
    }
end

local function CreateCheckBox(parent, text, optionKey, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox.Text:SetText(text)

    if gameLanguage == "ru" then
        checkbox.Text:SetFont("Fonts\\Arial__.TTF", 12, "OUTLINE")
    elseif gameLanguage == "cn" then
        checkbox.Text:SetFont("Fonts\\ARKai_T.TTF", 12, "OUTLINE")
    elseif gameLanguage == "ko" then
        checkbox.Text:SetFont("Fonts\\2002.TTF", 12, "OUTLINE")
    else
        checkbox.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    end

    checkbox.Text:SetPoint("LEFT", 30, 0)
    checkbox:SetScript("OnClick", onClick)
    checkbox:SetChecked(MultiLanguageOptions[optionKey])
    return checkbox
end

local function CreateTextInput(parent, relativeFrame, offsetX, offsetY, label, defaultValue, maxLetters, optionKey)
    local inputLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    inputLabel:SetText(label)
    inputLabel:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", offsetX, offsetY)

    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", inputLabel, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetSize(300, 80)

    local bg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(scrollFrame)
    bg:SetColorTexture(0, 0, 0, 0.5)

    local border = CreateFrame("Frame", nil, scrollFrame, BackdropTemplateMixin and "BackdropTemplate")
    border:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -5, 5)
    border:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 5, -5)
    border:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
    })
    border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetText(MultiLanguageOptions[optionKey] or defaultValue)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    editBox:SetTextInsets(5, 5, 5, 5)
    editBox:SetCursorPosition(0)
    editBox:SetSize(300, 200)
    editBox:SetPoint("TOPLEFT")
    editBox:SetPoint("TOPRIGHT")
    editBox:SetHeight(80)
    editBox:SetMaxLetters(maxLetters)

    scrollFrame:SetScrollChild(editBox)
    scrollFrame:SetVerticalScroll(0)
    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function(self)
        editBox:SetFocus()
    end)

    editBox:SetScript("OnTextChanged", function(self)
        MultiLanguageOptions[optionKey] = self:GetText()
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        self:Insert("\n")
    end)

    return scrollFrame
end

local function getDefaultOptions(optionsTranslations)
    return {
        QUEST_TRANSLATIONS = true,
        ITEM_TRANSLATIONS = true,
        ITEM_TRANSLATIONS_ONLY_DISPLAY_NAME = false,
        SPELL_TRANSLATIONS = true,
        SPELL_TRANSLATIONS_ONLY_DISPLAY_NAME = false,
        NPC_TRANSLATIONS = true,
        NPC_TRANSLATIONS_ONLY_DISPLAY_NAME = false,
        SELECTED_LANGUAGE = 'en',
        AVAILABLE_LANGUAGES = {
            {value = 'en', text = optionsTranslations["languages"]["en"]},
        },
        SELECTED_INTERACTION = 'hover',
        AVAILABLE_INTERACTIONS = {
           {value = 'hover', text = optionsTranslations["interactionModes"]["hover"]},
           {value = 'hover-hotkey', optionsTranslations["interactionModes"]["hoverHotkey"]}
        },
        SELECTED_HOTKEY = nil
   }
end

local function InitializeOptions()
    local optionsPanel = CreateFrame("Frame", "MultiLanguageOptionsPanel", UIParent)
    optionsPanel.name = "MultiLanguage"

    -- Vars
    local titleOffsetY = -22
    local subTitleOffsetY = -30
    local fieldOffsetX = 25
    local fieldOffsetY = -10

    -- Options panel title
    local panelTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    panelTitle:SetPoint("TOPLEFT", optionsPanel, 6, titleOffsetY)
    panelTitle:SetText("MultiLanguage")
    panelTitle:SetTextColor(1, 1, 1)
    panelTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)

    local panelTitleUnderline = optionsPanel:CreateTexture(nil, "ARTWORK")
    panelTitleUnderline:SetColorTexture(1, 1, 1, 0.3)
    panelTitleUnderline:SetPoint("TOPLEFT", panelTitle, "BOTTOMLEFT", 0, -9)
    panelTitleUnderline:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -16, -31)

    -- Scrollable frame
    local optionsContainerScrollFrame = CreateFrame("ScrollFrame", nil, optionsPanel, "UIPanelScrollFrameTemplate")
    optionsContainerScrollFrame:SetPoint("TOPLEFT", panelTitleUnderline, 0, -10)
    optionsContainerScrollFrame:SetPoint("BOTTOMRIGHT", -38, 30)

    local scrollSpeed = 50

    optionsContainerScrollFrame:EnableMouseWheel(true)
    optionsContainerScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local newOffset = self:GetVerticalScroll() - (delta * scrollSpeed)
        newOffset = math.max(0, math.min(newOffset, self:GetVerticalScrollRange()))
        self:SetVerticalScroll(newOffset)
    end)

    local optionsContainer = CreateFrame("Frame")
    optionsContainerScrollFrame:SetScrollChild(optionsContainer)
    optionsContainer:SetWidth(UIParent:GetWidth())
    optionsContainer:SetHeight(1)

    -- Quest options
    local generalOptionsTitle = optionsContainer:CreateFontString("ARTWORK", nil, "GameFontHighlightLarge")
    generalOptionsTitle:SetPoint("TOPLEFT", 8, titleOffsetY)
    generalOptionsTitle:SetText(optionsTranslations["generalOptionsTitle"])
    generalOptionsTitle:SetTextColor(1, 1, 1)

    -- General options
    local languageDropdown = CreateOptionDropdown(
        optionsContainer,
        generalOptionsTitle,
        fieldOffsetX,
        subTitleOffsetY,
        optionsTranslations["languageDropdownLabel"],
        optionsTranslations["languages"]["en"],
        "AVAILABLE_LANGUAGES",
        "SELECTED_LANGUAGE",
        "languages"
    )

    function AddLanguageDropdownOption()
        languageDropdown.reinitialize()
    end

    local interactionDropdown = CreateOptionDropdown(
        optionsContainer,
        languageDropdown.frame,
        fieldOffsetX - 5,
        subTitleOffsetY,
        optionsTranslations["interactionDropdownLabel"],
        optionsTranslations["interactionModes"]["hover"],
        "AVAILABLE_INTERACTIONS",
        "SELECTED_INTERACTION",
        "interactionModes"
    )

    -- General options: Hotkey
    local hotkeyDescription = optionsContainer:CreateFontString(nil, "ARTWORK", "GameFontnormalSmall")
    hotkeyDescription:SetPoint("TOPLEFT", interactionDropdown.frame, "BOTTOMLEFT", 16, fieldOffsetY)
    hotkeyDescription:SetText(optionsTranslations["registerHotkeyDescriptionText"])

    local registerHotkeyButton = CreateFrame("Button", "MultiLanguageRegisterHotkeyButton", optionsContainer, "UIPanelButtonTemplate")
    registerHotkeyButton:SetWidth(120)
    registerHotkeyButton:SetHeight(25)
    registerHotkeyButton:SetPoint("TOPLEFT", hotkeyDescription, "TOPLEFT", 0, -12)

    if MultiLanguageOptions.SELECTED_HOTKEY then
        registerHotkeyButton:SetText(MultiLanguageOptions.SELECTED_HOTKEY)
    else
        registerHotkeyButton:SetText(optionsTranslations["registerHotkeyNotBoundText"])
    end

    local waitingForKey = false

    registerHotkeyButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if not waitingForKey then
                waitingForKey = true
                registerHotkeyButton:SetText(optionsTranslations["registerHotkeyPressButtonText"])
            end
        elseif button == "RightButton" then
            waitingForKey = false
            registerHotkeyButton:SetText(optionsTranslations["registerHotkeyNotBoundText"])
            MultiLanguageOptions.SELECTED_HOTKEY = nil
        end
    end)

    local function SetHotkeyButton(self, key)
        if waitingForKey then
            MultiLanguageOptions.SELECTED_HOTKEY = key
            registerHotkeyButton:SetText(MultiLanguageOptions.SELECTED_HOTKEY)
            waitingForKey = false
        end
    end

    registerHotkeyButton:SetScript("OnKeyDown", SetHotkeyButton)
    registerHotkeyButton:SetPropagateKeyboardInput(true)

    -- Quest options
    local questOptionsTitle = optionsContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    questOptionsTitle:SetPoint("TOPLEFT", registerHotkeyButton, -fieldOffsetX + 5, -registerHotkeyButton:GetHeight() + subTitleOffsetY)
    questOptionsTitle:SetText(optionsTranslations["questOptionsTitle"])
    questOptionsTitle:SetTextColor(1, 1, 1)

    local questTranslationsEnabledCheckbox = CreateCheckBox(optionsContainer, optionsTranslations["enableText"], "QUEST_TRANSLATIONS", function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions["QUEST_TRANSLATIONS"] = checked
    end)
    questTranslationsEnabledCheckbox:SetPoint("TOPLEFT", questOptionsTitle, fieldOffsetX - 5, subTitleOffsetY + fieldOffsetY)

    -- Item options
    local itemOptionsTitle = optionsContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    itemOptionsTitle:SetPoint("TOPLEFT", questTranslationsEnabledCheckbox, -fieldOffsetX + 5, -questTranslationsEnabledCheckbox:GetHeight() + subTitleOffsetY - fieldOffsetY)
    itemOptionsTitle:SetText(optionsTranslations["itemOptionsTitle"])
    itemOptionsTitle:SetTextColor(1, 1, 1)

    local itemTranslationsEnabledCheckbox = CreateCheckBox(optionsContainer, optionsTranslations["enableText"], "ITEM_TRANSLATIONS", function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions["ITEM_TRANSLATIONS"] = checked
    end)
    itemTranslationsEnabledCheckbox:SetPoint("TOPLEFT", itemOptionsTitle, fieldOffsetX - 5, subTitleOffsetY + fieldOffsetY)

    local itemTranslationsDisplayOnlyNameCheckbox = CreateCheckBox(optionsContainer, optionsTranslations["onlyDisplayNameText"], "ITEM_TRANSLATIONS_ONLY_DISPLAY_NAME", function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions["ITEM_TRANSLATIONS_ONLY_DISPLAY_NAME"] = checked
    end)
    itemTranslationsDisplayOnlyNameCheckbox:SetPoint("TOPLEFT", itemTranslationsEnabledCheckbox, 0, subTitleOffsetY + fieldOffsetY)

    -- Spell options
    local spellOptionsTitle = optionsContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    spellOptionsTitle:SetPoint("TOPLEFT", itemTranslationsDisplayOnlyNameCheckbox, -fieldOffsetX + 5, -itemTranslationsDisplayOnlyNameCheckbox:GetHeight() + subTitleOffsetY - fieldOffsetY)
    spellOptionsTitle:SetText(optionsTranslations["spellOptionsTitle"])
    spellOptionsTitle:SetTextColor(1, 1, 1)

    local spellTranslationsEnabledCheckbox = CreateCheckBox(optionsContainer, optionsTranslations["enableText"], "SPELL_TRANSLATIONS", function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions["SPELL_TRANSLATIONS"] = checked
    end)
    spellTranslationsEnabledCheckbox:SetPoint("TOPLEFT", spellOptionsTitle, fieldOffsetX - 5, subTitleOffsetY + fieldOffsetY)

    local spellTranslationsDisplayOnlyNameCheckbox = CreateCheckBox(optionsContainer, optionsTranslations["onlyDisplayNameText"], "SPELL_TRANSLATIONS_ONLY_DISPLAY_NAME", function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions["SPELL_TRANSLATIONS_ONLY_DISPLAY_NAME"] = checked
    end)
    spellTranslationsDisplayOnlyNameCheckbox:SetPoint("TOPLEFT", spellTranslationsEnabledCheckbox, 0, subTitleOffsetY + fieldOffsetY)

    -- Npc options
    local npcOptionsTitle = optionsContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    npcOptionsTitle:SetPoint("TOPLEFT", spellTranslationsDisplayOnlyNameCheckbox, -fieldOffsetX + 5, -spellTranslationsEnabledCheckbox:GetHeight() + subTitleOffsetY - fieldOffsetY)
    npcOptionsTitle:SetText(optionsTranslations["npcOptionsTitle"])
    npcOptionsTitle:SetTextColor(1, 1, 1)

    local npcTranslationsEnabledCheckbox = CreateCheckBox(optionsContainer, optionsTranslations["enableText"], "NPC_TRANSLATIONS", function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions["NPC_TRANSLATIONS"] = checked
    end)
    npcTranslationsEnabledCheckbox:SetPoint("TOPLEFT", npcOptionsTitle, fieldOffsetX - 5, subTitleOffsetY + fieldOffsetY)

    local npcTranslationsDisplayOnlyNameCheckbox = CreateCheckBox(optionsContainer, optionsTranslations["onlyDisplayNameText"], "NPC_TRANSLATIONS_ONLY_DISPLAY_NAME", function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions["NPC_TRANSLATIONS_ONLY_DISPLAY_NAME"] = checked
    end)
    npcTranslationsDisplayOnlyNameCheckbox:SetPoint("TOPLEFT", npcTranslationsEnabledCheckbox, 0, subTitleOffsetY + fieldOffsetY)

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(optionsPanel)
    else
        local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name);
        Settings.RegisterAddOnCategory(category);
    end
end

local function addonLoaded(self, event, addonLoadedName)
    if addonLoadedName == addonName then
        optionsTranslations = (_G["MultiLanguageTranslations"][gameLanguage] or _G["MultiLanguageTranslations"]["en"])["options"]

        defaultOptions = getDefaultOptions(optionsTranslations)
        MultiLanguageOptions = MultiLanguageOptions or defaultOptions

        for key, value in pairs(defaultOptions) do
            if MultiLanguageOptions[key] == nil then
                MultiLanguageOptions[key] = value
            elseif type(value) == "table" and key == "AVAILABLE_LANGUAGES" then
                MultiLanguageOptions[key] = value
            end
        end

        InitializeOptions()
    end
end

optionsFrame:RegisterEvent("ADDON_LOADED")
optionsFrame:SetScript("OnEvent", addonLoaded)
