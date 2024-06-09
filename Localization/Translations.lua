local addonName = ...
local translationsFrame = CreateFrame("Frame")

local function addonLoaded(self, event, addonLoadedName)
    if addonLoadedName == addonName then
        MultiLanguageTranslations = {}

        MultiLanguageTranslations["en"] = {
            description = "Description",
            objectives = "Quest objectives"
        }
    end
end

translationsFrame:RegisterEvent("ADDON_LOADED")
translationsFrame:SetScript("OnEvent", addonLoaded)