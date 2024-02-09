local defaultOptions = {
    QUEST_TRANSLATIONS = true,
    ITEM_TRANSLATIONS = true,
    SPELL_TRANSLATIONS = true,
    NPC_TRANSLATIONS = true,
    SELECTED_LANGUAGE = 'en'
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
    languageDropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -26)

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