local defaultOptions = {
    QUEST_TRANSLATIONS = true,
    ITEM_TRANSLATIONS = true,
    SPELL_TRANSLATIONS = true,
    NPC_TRANSLATIONS = true
}

local addonName = ...
local optionsFrame = CreateFrame("Frame")

local function CreateCheckBox(parent, optionsPanel, text, onClick)
    local checkbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate");
    checkbox.Text:SetText(text);
    checkbox:SetScript("OnClick", onClick);

    return checkbox;
end

local function createOptionCheckbox(parent, optionsPanel, text, optionKey)
    local checkbox = CreateCheckBox(parent, optionsPanel, text, function(self)
        local checked = self:GetChecked()
        MultiLanguageOptions[optionKey] = checked
    end)

    checkbox:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -8);
    checkbox:SetChecked(MultiLanguageOptions[optionKey])
    return checkbox
end

local function InitializeOptions()
    local optionsPanel = CreateFrame("Frame", "MultiLanguageOptionsPanel", UIParent);
    optionsPanel.name = "MultiLanguage";

    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    title:SetPoint("TOPLEFT", 16, -16);
    title:SetText("MultiLanguage");
    local enableQuestTranslationCheckbox = createOptionCheckbox(title, optionsPanel,"Enable quest translations", "QUEST_TRANSLATIONS");
    local enableItemTranslationCheckbox = createOptionCheckbox(enableQuestTranslationCheckbox, optionsPanel, "Enable item translations", "ITEM_TRANSLATIONS");
    local enableSpellTranslationCheckbox = createOptionCheckbox(enableItemTranslationCheckbox, optionsPanel, "Enable spell translations", "SPELL_TRANSLATIONS");
    local enableNpcTranslationCheckbox = createOptionCheckbox(enableSpellTranslationCheckbox, optionsPanel, "Enable npc translations", "NPC_TRANSLATIONS");

    InterfaceOptions_AddCategory(optionsPanel);
end

local function addonLoaded(self, event, addonLoadedName)
    if addonLoadedName == addonName then
        MultiLanguageOptions = MultiLanguageOptions or defaultOptions
        InitializeOptions()
    end
end

optionsFrame:RegisterEvent("ADDON_LOADED")
optionsFrame:SetScript("OnEvent", addonLoaded)