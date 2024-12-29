local addonName, addonTable = ...
local translationsFrame = CreateFrame("Frame")

local function addonLoaded(self, event, addonLoadedName)
    if addonLoadedName == addonName then
        addonTable.translations = {}

        addonTable.translations["en"] = {
            description = "Description",
            objectives = "Quest Objectives"
        }

        addonTable.translations["es"] = {
            description = "Descripción",
            objectives = "Objetivos de la misión"
        }

        addonTable.translations["de"] = {
            description = "Beschreibung",
            objectives = "Questziele"
        }
        
        addonTable.translations["fr"] = {
            description = "Description",
            objectives = "Objectifs"
        }

        addonTable.translations["pt"] = {
            description = "Descrição",
            objectives = "Objetivos"
        }

        addonTable.translations["ru"] = {
            description = "Описание",
            objectives = "Цели"
        }

        addonTable.translations["cn"] = {
            description = "描述",
            objectives = "目标"
        }

        addonTable.translations["ko"] = {
            description = "서술",
            objectives = "목표"
        }
    end
end

translationsFrame:RegisterEvent("ADDON_LOADED")
translationsFrame:SetScript("OnEvent", addonLoaded)