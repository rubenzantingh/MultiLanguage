local addonName, addonTable = ...
local translationsFrame = CreateFrame("Frame")

local function addonLoaded(self, event, addonLoadedName)
    if addonLoadedName == addonName then
        addonTable.translations = {}

        addonTable.translations["en"] = {
            description = "Description",
            objectives = "Quest objectives"
        }

        addonTable.translations["es"] = {
            description = "Descripción",
            objectives = "Objetivos de la misión"
        }
    end
end

translationsFrame:RegisterEvent("ADDON_LOADED")
translationsFrame:SetScript("OnEvent", addonLoaded)