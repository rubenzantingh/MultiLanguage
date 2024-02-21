local lastQuestFrameEvent = nil
local addonName, addonTable = ...
local translationFrame = CreateFrame("Frame")
local activeItemSpellOrUnitLines = {}
local activeItemSpellOrUnitId = nil
local textColorCodes = {
    ["[q]"] = "|cFFFFD100",
    ["[q0]"] = "|cFF9D9D9D",
    ["[q2]"] = "|cFF00FF00",
    ["[q3]"] = "|cFF0070DD",
    ["[q4]"] = "|cFFA335EE",
    ["[q5]"] = "|cFFFF8000"
}

local function GetDataByID(dataType, dataId)
    if addonTable[dataType] then
        languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

        if addonTable[dataType][languageCode] then
            local convertedId = tonumber(dataId)
            if addonTable[dataType][languageCode][convertedId] then
                return addonTable[dataType][languageCode][convertedId]
            end
        end
    end

    return nil
end

local function SetQuestDetails(headerText, objectiveText, descriptionHeader, descriptionText, parentFrame, yOffset, isQuestFrame)
    QuestTranslationFramePrimaryHeader:SetText(headerText:upper())
    QuestTranslationFramePrimaryText:SetText(objectiveText)
    QuestTranslationFrameSecondaryHeader:SetText(descriptionHeader:upper())
    QuestTranslationFrameSecondaryText:SetText(descriptionText)

    textTopMargin = -QuestTranslationFramePrimaryHeader:GetHeight() - 15
    descriptionHeaderTopMargin = textTopMargin - QuestTranslationFramePrimaryText:GetHeight() - 10
    descriptionTextTopMargin = descriptionHeaderTopMargin - QuestTranslationFrameSecondaryHeader:GetHeight() - 5

    local heightPadding = 10

    local addPadding = function(text, value)
        if text ~= "" then
            heightPadding = heightPadding + value
        end
    end

    addPadding(headerText, 10)
    addPadding(objectiveText, 5)
    addPadding(descriptionHeader, 10)
    addPadding(descriptionText, 5)

    QuestTranslationFramePrimaryHeader:SetPoint("TOPLEFT", 10, -10)
    QuestTranslationFramePrimaryText:SetPoint("TOPLEFT", 10, textTopMargin)
    QuestTranslationFrameSecondaryHeader:SetPoint("TOPLEFT", 10, descriptionHeaderTopMargin)
    QuestTranslationFrameSecondaryText:SetPoint("TOPLEFT", 10, descriptionTextTopMargin)
    QuestTranslationFrame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", -15, yOffset)

    QuestTranslationFrame:SetParent(parentFrame)
    QuestTranslationFrame:SetHeight(
        QuestTranslationFramePrimaryHeader:GetHeight() +
        QuestTranslationFramePrimaryText:GetHeight() +
        QuestTranslationFrameSecondaryHeader:GetHeight() +
        QuestTranslationFrameSecondaryText:GetHeight() +
        heightPadding
    )
end

local function UpdateQuestTranslationFrame()
    local selectedQuestIndex, questId, questData

    if QuestLogFrame:IsShown() and QuestLogFrame:IsMouseOver() then
        selectedQuestIndex = GetQuestLogSelection()

        if selectedQuestIndex > 0 then
            questId = select(8, GetQuestLogTitle(selectedQuestIndex))
            questData = GetDataByID("questData", questId)

            if questData then
                QuestTranslationFrame:Show()
                languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]
            
                SetQuestDetails(
                    questData.title,
                    questData.objective,
                    addonTable.translations[languageCode]["description"],
                    questData.description,
                    QuestLogFrame,
                    -QuestLogListScrollFrame:GetHeight() - (QuestLogFrame:GetTop() - QuestLogListScrollFrame:GetTop()) - 5, false
                )
            else
                QuestTranslationFrame:Hide()
            end
        end
    end

    if QuestFrame:IsShown() and QuestFrame:IsMouseOver() then
        questId = GetQuestID()

        if questId then
            questData = GetDataByID("questData", questId)
            if questData then
                QuestTranslationFrame:Show()
                languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

                if lastQuestFrameEvent == "QUEST_PROGRESS" then
                    QuestTranslationFrame:Show()
                    SetQuestDetails(
                            questData.title,
                            questData.progress,
                            "",
                            "",
                            QuestFrame,
                            -80,
                            true
                    )
                elseif lastQuestFrameEvent == "QUEST_COMPLETE" then
                    SetQuestDetails(
                            questData.title,
                            questData.completion,
                            "",
                            "",
                            QuestFrame,
                            -80,
                            true
                    )
                elseif lastQuestFrameEvent == "QUEST_DETAIL" then
                    SetQuestDetails(
                            questData.title,
                            questData.description,
                            addonTable.translations[languageCode]["objectives"],
                            questData.objective,
                            QuestFrame,
                            -80,
                            true
                    )
                elseif lastQuestFrameEvent == "QUEST_FINISHED" then
                    QuestTranslationFrame:Hide()
                end
            else
                QuestTranslationFrame:Hide()
            end
        end
    end
end

local function SetQuestHoverScripts(frame, children)
    local frameName = frame:GetName()

    if frameName ~= "QuestLogListScrollFrame" and not string.find(frameName, "QuestLogItem") and not string.find(frameName, "QuestProgressItem") then
        frame:SetScript("OnEnter", function()
            local questTranslationsEnabled = MultiLanguageOptions["QUEST_TRANSLATIONS"]

            if questTranslationsEnabled then
                UpdateQuestTranslationFrame()
            else
                QuestTranslationFrame:Hide()
            end
        end)

        frame:SetScript("OnLeave", function()
            QuestTranslationFrame:Hide()
        end)

        if children then
            for i = 1, frame:GetNumChildren() do
                local child = select(i, frame:GetChildren())
                SetQuestHoverScripts(child, true)
            end
        end
    end
end

local function elementWillBeAboveTop(element, parent)
    local elementHeight = element:GetHeight()
    local elementTop = parent:GetTop()
    local screenHeight = GetScreenHeight()
    local topPosition = elementTop + elementHeight + 5

    return topPosition > screenHeight
end

local function escapeMagic(s)
    return s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

local function SetColorForLine(line, spellColorLinePassed)
    if spellColorLinePassed then
        return "|cFFFFD100" .. line .. "|r"
    end

    for pattern, colorCode in pairs(textColorCodes) do
        local escapedPattern = escapeMagic(pattern)
        local _, count = string.gsub(line, escapedPattern, "")

        if count > 0 then
            line = line:gsub(escapedPattern, "")
            return colorCode .. line .. "|r"
        end
    end

    return "|cFFFFFFFF" .. line .. "|r"
end

local function UpdateItemSpellAndUnitTranslationFrame(itemHeader, itemText, id, type)
    local gameToolTipWidth = GameTooltip:GetWidth()
    local gameToolTipHeight = GameTooltip:GetHeight()

    ItemSpellAndUnitTranslationFrame:SetWidth(gameToolTipWidth)
    ItemSpellAndUnitTranslationFrame:Show()

    ItemSpellAndUnitTranslationFrameHeader:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() - 17.5)
    ItemSpellAndUnitTranslationFrameHeader:Show()
    ItemSpellAndUnitTranslationFrameHeader:SetText(SetColorForLine(itemHeader))
    ItemSpellAndUnitTranslationFrameHeader:SetPoint("TOPLEFT", 10, -10)

    if id ~= activeItemSpellOrUnitId then
        local parent = ItemSpellAndUnitTranslationFrameHeader
        local existingLines = #activeItemSpellOrUnitLines
        local newLines = 0
        local spellColorLinePassed = false
        local totalFrameHeight = ItemSpellAndUnitTranslationFrameHeader:GetHeight()

        if itemText then
            for line in itemText:gmatch("[^\r\n]+") do
                local lineFontString

                if newLines < existingLines then
                    lineFontString = activeItemSpellOrUnitLines[newLines + 1]
                else
                    lineFontString = ItemSpellAndUnitTranslationFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                    table.insert(activeItemSpellOrUnitLines, lineFontString)
                end

                lineFontString:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -2.5)
                lineFontString:SetText(SetColorForLine(line, spellColorLinePassed))
                lineFontString:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() - 17.5)
                lineFontString:SetJustifyH("LEFT")

                parent = lineFontString

                if type == "spell" then
                    if string.find(line, "%[q%]") then
                        spellColorLinePassed = true
                    end
                end

                lineFontString:Show()
                totalFrameHeight = totalFrameHeight + lineFontString:GetHeight() + 2.5
                newLines = newLines + 1
            end

            for i = newLines + 1, #activeItemSpellOrUnitLines do
                activeItemSpellOrUnitLines[i]:Hide()
            end
        else
            if existingLines > 0 then
                for _, frame in ipairs(activeItemSpellOrUnitLines) do
                    frame:Hide()
                end
                activeItemSpellOrUnitLines = {}
            end
        end

        ItemSpellAndUnitTranslationFrame:SetHeight(totalFrameHeight + 20)
        ItemSpellAndUnitTranslationFrame:SetPoint("TOPLEFT", 0, elementWillBeAboveTop(ItemSpellAndUnitTranslationFrame, GameTooltip) and -gameToolTipHeight - 5 or ItemSpellAndUnitTranslationFrame:GetHeight() + 5)
        activeItemSpellOrUnitId = id
    else
        local totalFrameHeight = ItemSpellAndUnitTranslationFrameHeader:GetHeight()
        local existingLines = #activeItemSpellOrUnitLines
        local newLines = 0

        if itemText then
            for line in itemText:gmatch("[^\r\n]+") do
                local lineFontString

                if newLines < existingLines then
                    lineFontString = activeItemSpellOrUnitLines[newLines + 1]
                    lineFontString:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() - 17.5)
                    totalFrameHeight = totalFrameHeight + lineFontString:GetHeight() + 2.5
                end

                newLines = newLines + 1
            end

            ItemSpellAndUnitTranslationFrame:SetHeight(totalFrameHeight + 20)
            ItemSpellAndUnitTranslationFrame:SetPoint("TOPLEFT", 0, elementWillBeAboveTop(ItemSpellAndUnitTranslationFrame, GameTooltip) and -gameToolTipHeight - 5 or ItemSpellAndUnitTranslationFrame:GetHeight() + 5)
        end
    end
end

local function GetItemIDFromLink(itemLink)
    local _, _, itemID = string.find(itemLink, "item:(%d+):")
    return tonumber(itemID)
end

local function OnTooltipSetData(self)
    self:Show()

    local _, itemLink = self:GetItem()
    local _, spellID = self:GetSpell()
    local unitGUID = UnitGUID("mouseover")

    local itemTranslationsEnabled = MultiLanguageOptions["ITEM_TRANSLATIONS"]
    local spellTranslationsEnabled = MultiLanguageOptions["SPELL_TRANSLATIONS"]
    local npcTranslationsEnabled = MultiLanguageOptions["NPC_TRANSLATIONS"]

    if itemLink and itemTranslationsEnabled then
        local itemID = GetItemIDFromLink(itemLink)

        if itemID then
            local item = GetDataByID("itemData", itemID)

            if item then
                UpdateItemSpellAndUnitTranslationFrame(item.name, item.additional_info, itemID, "item")
            else
                ItemSpellAndUnitTranslationFrame:Hide()
            end
        end
    elseif spellID and spellTranslationsEnabled then
        local spell = GetDataByID("spellData", spellID)

        if spell then
            UpdateItemSpellAndUnitTranslationFrame(spell.name, spell.additional_info, spellID, "spell")
        else
            ItemSpellAndUnitTranslationFrame:Hide()
        end
    elseif unitGUID and npcTranslationsEnabled then
        local unitType, _, _, _, _, npcID = strsplit("-", unitGUID)

        if unitType == "Creature" then
            if npcID then
                local npc = GetDataByID("npcData", npcID)

                if npc then
                    UpdateItemSpellAndUnitTranslationFrame(npc.name, npc.subname, npcID, "npc")
                else
                    ItemSpellAndUnitTranslationFrame:Hide()
                end
            end
        else
            ItemSpellAndUnitTranslationFrame:Hide()
        end
    else
        ItemSpellAndUnitTranslationFrame:Hide()
    end
end

GameTooltip:HookScript("OnUpdate", OnTooltipSetData)

QuestTranslationFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "QUEST_FINISHED" or event == "QUEST_DETAIL" then
        local questTranslationsEnabled = MultiLanguageOptions["QUEST_TRANSLATIONS"]

        if questTranslationsEnabled then
            lastQuestFrameEvent = event
            UpdateQuestTranslationFrame()
        else
            QuestTranslationFrame:Hide()
        end
    end
end)

SetQuestHoverScripts(QuestLogFrame, true)
SetQuestHoverScripts(QuestFrame, false)

SetQuestHoverScripts(QuestProgressScrollFrame, true)
SetQuestHoverScripts(QuestDetailScrollFrame, true)
SetQuestHoverScripts(QuestRewardScrollFrame, true)

SetQuestHoverScripts(QuestFrameCompleteButton, true)
SetQuestHoverScripts(QuestFrameCompleteQuestButton, true)
SetQuestHoverScripts(QuestFrameGoodbyeButton, true)
SetQuestHoverScripts(QuestFrameCancelButton, true)