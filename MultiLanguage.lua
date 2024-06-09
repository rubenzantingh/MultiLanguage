local lastQuestFrameEvent = nil
local translationFrame = CreateFrame("Frame")
local activeItemSpellOrUnitLines = {}
local activeItemSpellOrUnitId = nil
local hotkeyButtonPressed = false
local questFrameBeingHovered = false
local textColorCodes = {
    ["[q]"] = "|cFFFFD100",
    ["[q0]"] = "|cFF9D9D9D",
    ["[q2]"] = "|cFF00FF00",
    ["[q3]"] = "|cFF0070DD",
    ["[q4]"] = "|cFFA335EE",
    ["[q5]"] = "|cFFFF8000"
}

local function SetHotkeyButtonPressed(self, key, eventType)
    if MultiLanguageOptions.SELECTED_INTERACTION == "hover-hotkey" and MultiLanguageOptions.SELECTED_HOTKEY then
        if eventType == "OnKeyDown" and key == MultiLanguageOptions.SELECTED_HOTKEY then
            if hotkeyButtonPressed then
                hotkeyButtonPressed = false

                if questFrameBeingHovered then
                    QuestTranslationFrame:Hide()
                end
            else
                hotkeyButtonPressed = true

                if questFrameBeingHovered then
                    QuestTranslationFrame:Show()
                end
            end
        end
    end
end

translationFrame:SetScript("OnKeyDown", function(self, key) SetHotkeyButtonPressed(self, key, "OnKeyDown") end)
translationFrame:SetPropagateKeyboardInput(true)

local function GetDataByID(dataVariable, dataId)
    if dataVariable then
        languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

        if dataVariable[languageCode] then
            local convertedId = tonumber(dataId)
            if dataVariable[languageCode][convertedId] then
                return dataVariable[languageCode][convertedId]
            end
        end
    end

    return nil
end

local function SetQuestDetails(headerText, objectiveText, descriptionHeader, descriptionText, parentFrame, xOffset, yOffset, isQuestFrame)
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
    QuestTranslationFrame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", xOffset, yOffset)

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
    if QuestMapDetailsScrollFrame:IsShown() and QuestMapDetailsScrollFrame:IsMouseOver() then
        local questID = C_QuestLog.GetSelectedQuest()

        if questID then
            questData = GetDataByID(MultiLanguageQuestData, questID)
            if questData then
                if MultiLanguageOptions.SELECTED_INTERACTION == "hover-hotkey" then
                    if hotkeyButtonPressed then
                        QuestTranslationFrame:Show()
                    end
                else
                    QuestTranslationFrame:Show()
                end

                SetQuestDetails(
                    questData.title,
                    questData.objective,
                    MultiLanguageTranslations[languageCode]["description"],
                    questData.description,
                    QuestMapDetailsScrollFrame,
                    30,
                    0,
                    false
                )
            else
                QuestTranslationFrame:Hide()
            end
        end
    end

    if QuestFrame:IsShown() and QuestFrame:IsMouseOver() then
        local questID = GetQuestID()

        if questID then
            questData = GetDataByID(MultiLanguageQuestData, questID)
            if questData then
                if MultiLanguageOptions.SELECTED_INTERACTION == "hover-hotkey" then
                    if hotkeyButtonPressed then
                        QuestTranslationFrame:Show()
                    end
                else
                    QuestTranslationFrame:Show()
                end

                languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

                if lastQuestFrameEvent == "QUEST_PROGRESS" then
                    SetQuestDetails(
                            questData.title,
                            questData.progress,
                            "",
                            "",
                            QuestFrame,
                            0,
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
                            0,
                            -80,
                            true
                    )
                elseif lastQuestFrameEvent == "QUEST_DETAIL" then
                    SetQuestDetails(
                            questData.title,
                            questData.description,
                            MultiLanguageTranslations[languageCode]["objectives"],
                            questData.objective,
                            QuestFrame,
                            0,
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
    frame:SetScript("OnEnter", function()
        local questTranslationsEnabled = MultiLanguageOptions["QUEST_TRANSLATIONS"]

        if questTranslationsEnabled then
            UpdateQuestTranslationFrame()
            questFrameBeingHovered = true
        else
            QuestTranslationFrame:Hide()
            questFrameBeingHovered = false
        end
    end)

    frame:SetScript("OnLeave", function()
        QuestTranslationFrame:Hide()
        questFrameBeingHovered = false
    end)

    if children then
        for i = 1, frame:GetNumChildren() do
            local child = select(i, frame:GetChildren())
            SetQuestHoverScripts(child, true)
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

local function UpdateTranslationTooltipFrame(itemHeader, itemText, id, type)
    local gameToolTipWidth = GameTooltip:GetWidth()
    local gameToolTipHeight = GameTooltip:GetHeight()

    TranslationTooltipFrame:SetWidth(gameToolTipWidth)

    TranslationTooltipFrameHeader:SetWidth(TranslationTooltipFrame:GetWidth() - 17.5)
    TranslationTooltipFrameHeader:Show()
    TranslationTooltipFrameHeader:SetText(SetColorForLine(itemHeader))
    TranslationTooltipFrameHeader:SetPoint("TOPLEFT", 10, -10)

    if MultiLanguageOptions.SELECTED_INTERACTION == "hover-hotkey" then
        if hotkeyButtonPressed then
            TranslationTooltipFrame:Show()
        else
            TranslationTooltipFrame:Hide()
        end
    else
        TranslationTooltipFrame:Show()
    end

    if id ~= activeItemSpellOrUnitId then
        local parent = TranslationTooltipFrameHeader
        local existingLines = #activeItemSpellOrUnitLines
        local newLines = 0
        local spellColorLinePassed = false
        local totalFrameHeight = TranslationTooltipFrameHeader:GetHeight()

        if itemText then
            for line in itemText:gmatch("[^\r\n]+") do
                local lineFontString

                if newLines < existingLines then
                    lineFontString = activeItemSpellOrUnitLines[newLines + 1]
                else
                    lineFontString = TranslationTooltipFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                    table.insert(activeItemSpellOrUnitLines, lineFontString)
                end

                lineFontString:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -2.5)
                lineFontString:SetText(SetColorForLine(line, spellColorLinePassed))
                lineFontString:SetWidth(TranslationTooltipFrame:GetWidth() - 17.5)
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

        TranslationTooltipFrame:SetHeight(totalFrameHeight + 20)
        TranslationTooltipFrame:SetPoint("TOPLEFT", 0, elementWillBeAboveTop(TranslationTooltipFrame, GameTooltip) and -gameToolTipHeight - 5 or TranslationTooltipFrame:GetHeight() + 5)
        activeItemSpellOrUnitId = id
    else
        local totalFrameHeight = TranslationTooltipFrameHeader:GetHeight()
        local existingLines = #activeItemSpellOrUnitLines
        local newLines = 0

        if itemText then
            for line in itemText:gmatch("[^\r\n]+") do
                local lineFontString

                if newLines < existingLines then
                    lineFontString = activeItemSpellOrUnitLines[newLines + 1]
                    lineFontString:SetWidth(TranslationTooltipFrame:GetWidth() - 17.5)
                    totalFrameHeight = totalFrameHeight + lineFontString:GetHeight() + 2.5
                end

                newLines = newLines + 1
            end

            TranslationTooltipFrame:SetHeight(totalFrameHeight + 20)
            TranslationTooltipFrame:SetPoint("TOPLEFT", 0, elementWillBeAboveTop(TranslationTooltipFrame, GameTooltip) and -gameToolTipHeight - 5 or TranslationTooltipFrame:GetHeight() + 5)
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
    local owner = self:GetOwner()
    local questID = owner.questID
    local unitGUID = UnitGUID("mouseover")

    local itemTranslationsEnabled = MultiLanguageOptions["ITEM_TRANSLATIONS"]
    local spellTranslationsEnabled = MultiLanguageOptions["SPELL_TRANSLATIONS"]
    local npcTranslationsEnabled = MultiLanguageOptions["NPC_TRANSLATIONS"]
    local questTranslationsEnabled = MultiLanguageOptions["QUEST_TRANSLATIONS"]

    if itemLink and itemTranslationsEnabled then
        local itemID = GetItemIDFromLink(itemLink)

        if itemID then
            local item = GetDataByID(MultiLanguageItemData, itemID)

            if item then
                UpdateTranslationTooltipFrame(item.name, item.additional_info, itemID, "item")
            else
                TranslationTooltipFrame:Hide()
            end
        end
    elseif spellID and spellTranslationsEnabled then
        local spell = GetDataByID(MultiLanguageSpellData, spellID)

        if spell then
            UpdateTranslationTooltipFrame(spell.name, spell.additional_info, spellID, "spell")
        else
            TranslationTooltipFrame:Hide()
        end
    elseif unitGUID and npcTranslationsEnabled then
        local unitType, _, _, _, _, npcID = strsplit("-", unitGUID)

        if unitType == "Creature" then
            if npcID then
                local npc = GetDataByID(MultiLanguageNpcData, npcID)

                if npc then
                    UpdateTranslationTooltipFrame(npc.name, npc.subname, npcID, "npc")
                else
                    TranslationTooltipFrame:Hide()
                end
            end
        else
            TranslationTooltipFrame:Hide()
        end
    elseif  questID and questTranslationsEnabled and QuestMapDetailsScrollFrame:IsMouseOver() then
        local quest = GetDataByID(MultiLanguageQuestData, questID)

        if quest then
            UpdateTranslationTooltipFrame(quest.title, quest.objective, questID, "quest")
        else
            TranslationTooltipFrame:Hide()
        end
    else
        TranslationTooltipFrame:Hide()
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

SetQuestHoverScripts(QuestFrameDetailPanel, true)
SetQuestHoverScripts(QuestMapDetailsScrollFrame, false)
SetQuestHoverScripts(QuestFrame, false)