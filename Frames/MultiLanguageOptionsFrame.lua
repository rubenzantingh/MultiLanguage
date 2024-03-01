local defaultOptions = {
    QUEST_TRANSLATIONS = true,
    ITEM_TRANSLATIONS = true,
    SPELL_TRANSLATIONS = true,
    NPC_TRANSLATIONS = true,
    SELECTED_LANGUAGE = 'en',
    SELECTED_INTERACTION = 'hover',
    SELECTED_HOTKEY = nil
}

local addonName = ...
local optionsFrame = CreateFrame("Frame")

local function CreateCheckBox(parent, optionsPanel, text, onClick)
    local checkbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    checkbox.Text:SetText(text)
    checkbox:SetScript("OnClick", onClick)

    return checkbox
end

local function createOptionCheckbox(parent, optionsPanel, text, optionKey)
    local checkbox = CreateCheckBox(parent, optionsPanel, text, function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions[optionKey] = checked
    end)

    checkbox:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -8)
    checkbox:SetChecked(MultiLanguageOptions[optionKey])
    return checkbox
end

local function InitializeOptions()
    local optionsPanel = CreateFrame("Frame", "MultiLanguageOptionsPanel", UIParent)
    optionsPanel.name = "MultiLanguage"

    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("MultiLanguage")

    local languageDropdownDescription = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontnormalSmall")
    languageDropdownDescription:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    languageDropdownDescription:SetText("Select language:")

    local languageDropdown = CreateFrame("Frame", "MultiLanguageLanguageDropdown", optionsPanel, "UIDropDownMenuTemplate")
    languageDropdown:SetPoint("TOPLEFT", languageDropdownDescription, "BOTTOMLEFT", -16, -4)

    local function OnLanguageDropdownValueChanged(self, arg1, arg2, checked)
        MultiLanguageOptions.SELECTED_LANGUAGE = arg1
        UIDropDownMenu_SetText(languageDropdown, arg2)
    end

    local function SetSelectedLanguageText(languageText, selectedLanguageText, checked)
        if checked then
            return selectedLanguageText
        end

        return languageText
    end

    local function InitializeLanguageDropdown()
        local info = UIDropDownMenu_CreateInfo()
        local languageText = "English"

        info.text = "English"
        info.value = "en"
        info.arg1 = info.value
        info.arg2 = info.text
        info.checked = MultiLanguageOptions.SELECTED_LANGUAGE == "en"
        info.func = OnLanguageDropdownValueChanged
        info.minWidth = 145
        languageText = SetSelectedLanguageText(languageText, info.text, info.checked)
        UIDropDownMenu_AddButton(info)

        info.text = "Spanish"
        info.value = "es"
        info.arg1 = info.value
        info.arg2 = info.text
        info.checked = MultiLanguageOptions.SELECTED_LANGUAGE == "es"
        info.func = OnLanguageDropdownValueChanged
        languageText = SetSelectedLanguageText(languageText, info.text, info.checked)
        UIDropDownMenu_AddButton(info)

        info.text = "German"
        info.value = "de"
        info.arg1 = info.value
        info.arg2 = info.text
        info.checked = MultiLanguageOptions.SELECTED_LANGUAGE == "de"
        info.func = OnLanguageDropdownValueChanged
        languageText = SetSelectedLanguageText(languageText, info.text, info.checked)
        UIDropDownMenu_AddButton(info)

        info.text = "French"
        info.value = "fr"
        info.arg1 = info.value
        info.arg2 = info.text
        info.checked = MultiLanguageOptions.SELECTED_LANGUAGE == "fr"
        info.func = OnLanguageDropdownValueChanged
        languageText = SetSelectedLanguageText(languageText, info.text, info.checked)
        UIDropDownMenu_AddButton(info)

        UIDropDownMenu_SetText(languageDropdown, languageText)
        UIDropDownMenu_SetAnchor(languageDropdown, 16, 4, "TOPLEFT", languageDropdown, "BOTTOMLEFT")
    end

    local enableQuestTranslationCheckbox = createOptionCheckbox(languageDropdown, optionsPanel,"Enable quest translations", "QUEST_TRANSLATIONS")
    enableQuestTranslationCheckbox:SetPoint("TOPLEFT", languageDropdown, "BOTTOMLEFT", 16, -8)
    local enableItemTranslationCheckbox = createOptionCheckbox(enableQuestTranslationCheckbox, optionsPanel, "Enable item translations", "ITEM_TRANSLATIONS")
    local enableSpellTranslationCheckbox = createOptionCheckbox(enableItemTranslationCheckbox, optionsPanel, "Enable spell translations", "SPELL_TRANSLATIONS")
    local enableNpcTranslationCheckbox = createOptionCheckbox(enableSpellTranslationCheckbox, optionsPanel, "Enable npc translations", "NPC_TRANSLATIONS")

    UIDropDownMenu_SetWidth(languageDropdown, 150)
    UIDropDownMenu_Initialize(languageDropdown, InitializeLanguageDropdown)

    local interactionDropdownDescription = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontnormalSmall")
    interactionDropdownDescription:SetPoint("TOPLEFT", enableNpcTranslationCheckbox, "BOTTOMLEFT", 0, -8)
    interactionDropdownDescription:SetText("Select interaction:")

    local interactionDropdown = CreateFrame("Frame", "MultiLanguageInteractionDropdown", optionsPanel, "UIDropDownMenuTemplate")
    interactionDropdown:SetPoint("TOPLEFT", interactionDropdownDescription, "BOTTOMLEFT", -16, -4)

    local function SetSelectedInteractionText(interactionText, selectedInteractionText, checked)
        if checked then
            return selectedInteractionText
        end

        return interactionText
    end

    local function OnInteractionDropdownValueChanged(self, arg1, arg2, checked)
        MultiLanguageOptions.SELECTED_INTERACTION = arg1
        UIDropDownMenu_SetText(interactionDropdown, arg2)
    end

    local function InitializeInteractionDropdown()
        local info = UIDropDownMenu_CreateInfo()
        local interactionText = "Hover"

        info.text = "Hover"
        info.value = "hover"
        info.arg1 = info.value
        info.arg2 = info.text
        info.checked = MultiLanguageOptions.SELECTED_INTERACTION == "hover"
        info.func = OnInteractionDropdownValueChanged
        info.minWidth = 145
        interactionText = SetSelectedInteractionText(interactionText, info.text, info.checked)
        UIDropDownMenu_AddButton(info)

        info.text = "Hover + hotkey"
        info.value = "hover-hotkey"
        info.arg1 = info.value
        info.arg2 = info.text
        info.checked = MultiLanguageOptions.SELECTED_INTERACTION == "hover-hotkey"
        info.func = OnInteractionDropdownValueChanged
        info.minWidth = 145
        interactionText = SetSelectedInteractionText(interactionText, info.text, info.checked)
        UIDropDownMenu_AddButton(info)

        UIDropDownMenu_SetText(interactionDropdown, interactionText)
        UIDropDownMenu_SetAnchor(interactionDropdown, 16, 4, "TOPLEFT", interactionDropdown, "BOTTOMLEFT")
    end

    UIDropDownMenu_SetWidth(interactionDropdown, 150)
    UIDropDownMenu_Initialize(interactionDropdown, InitializeInteractionDropdown)

    local hotkeyDescription = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontnormalSmall")
    hotkeyDescription:SetPoint("TOPLEFT", interactionDropdown, "BOTTOMLEFT", 16, -8)
    hotkeyDescription:SetText("Register Hotkey (right-click to unbind):")

    local registerHotkeyButton = CreateFrame("Button", "MultiLanguageRegisterHotkeyButton", optionsPanel, "UIPanelButtonTemplate")
    registerHotkeyButton:SetWidth(120)
    registerHotkeyButton:SetHeight(25)
    registerHotkeyButton:SetPoint("TOPLEFT", hotkeyDescription, "TOPLEFT", 0, -12)

    if MultiLanguageOptions.SELECTED_HOTKEY then
        registerHotkeyButton:SetText(MultiLanguageOptions.SELECTED_HOTKEY)
    else
        registerHotkeyButton:SetText("Not Bound")
    end

    local waitingForKey = false

    registerHotkeyButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if not waitingForKey then
                waitingForKey = true
                registerHotkeyButton:SetText("Press button..")
            end
        elseif button == "RightButton" then
            waitingForKey = false
            registerHotkeyButton:SetText("Not Bound")
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

    InterfaceOptions_AddCategory(optionsPanel)
end

local function addonLoaded(self, event, addonLoadedName)
    if addonLoadedName == addonName then
        MultiLanguageOptions = MultiLanguageOptions or defaultOptions
        
        for key, value in pairs(defaultOptions) do
            if MultiLanguageOptions[key] == nil then
                MultiLanguageOptions[key] = value
            end
        end

        InitializeOptions()
    end
end

optionsFrame:RegisterEvent("ADDON_LOADED")
optionsFrame:SetScript("OnEvent", addonLoaded)