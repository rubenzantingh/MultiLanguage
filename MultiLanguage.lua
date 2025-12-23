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

-- Helper functions
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

local function GetItemIDFromLink(itemLink)
    local _, _, itemID = string.find(itemLink, "item:(%d+):")
    return tonumber(itemID)
end

local function GetDataByID(dataVariable, dataId)
    if not dataVariable then
        return
    end

    languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

    if not dataVariable[languageCode] then
        return
    end

    local convertedId = tonumber(dataId)

    if dataVariable[languageCode][convertedId] then
        return dataVariable[languageCode][convertedId]
    end

    return nil
end

-- Quests functions
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
    QuestTranslationFrame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 5, yOffset)
    QuestTranslationFrame:SetParent(parentFrame)
    QuestTranslationFrame:SetFrameStrata("HIGH")
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

        if selectedQuestIndex <= 0 then
            return
        end

        questId = select(8, GetQuestLogTitle(selectedQuestIndex))
        questData = GetDataByID(MultiLanguageQuestData, questId)

        if not questData then
            QuestTranslationFrame:Hide()
            return
        end

        if MultiLanguageOptions.SELECTED_INTERACTION == "hover-hotkey" then
            if hotkeyButtonPressed then
                QuestTranslationFrame:Show()
            end
        else
            QuestTranslationFrame:Show()
        end

        languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

        SetQuestDetails(
            questData.title,
            questData.objective,
            MultiLanguageTranslations[languageCode]["description"],
            questData.description,
            QuestLogFrame,
            - (QuestLogFrame:GetTop() - QuestLogListScrollFrame:GetTop()) + 2.5, false
        )
    end

    if QuestFrame:IsShown() and QuestFrame:IsMouseOver() then
        questId = GetQuestID()

        if not questId then
            return
        end

        questData = GetDataByID(MultiLanguageQuestData, questId)

        if not questData then
            QuestTranslationFrame:Hide()
            return
        end

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
                MultiLanguageTranslations[languageCode]["objectives"],
                questData.objective,
                QuestFrame,
                -80,
                true
            )
        elseif lastQuestFrameEvent == "QUEST_FINISHED" then
            QuestTranslationFrame:Hide()
        end
    end
end

local function SetQuestHoverScripts(frame, children)
    local frameName = frame:GetName()

    if frameName == "QuestLogListScrollFrame" or string.find(frameName, "QuestLogItem") or string.find(frameName, "QuestProgressItem") then
        return
    end

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

-- Item, spell and unit functions
local function ShowOnlyTitleTranslation(type)
    return MultiLanguageOptions[type:upper() .. "_TRANSLATIONS_ONLY_DISPLAY_NAME"]
end

local function SetItemSpellAndUnitTranslationFrameHeightAndPosition(height, gameToolTipHeight)
    ItemSpellAndUnitTranslationFrame:SetHeight(height)
    ItemSpellAndUnitTranslationFrame:SetPoint("TOPLEFT", 0, elementWillBeAboveTop(ItemSpellAndUnitTranslationFrame, GameTooltip) and -gameToolTipHeight - 5 or ItemSpellAndUnitTranslationFrame:GetHeight() + 5)
end

local function UpdateItemSpellAndUnitTranslationFrame(itemHeader, itemText, id, type)
    local gameToolTipWidth = GameTooltip:GetWidth()
    local gameToolTipHeight = GameTooltip:GetHeight()

    ItemSpellAndUnitTranslationFrame:SetWidth(gameToolTipWidth)

    ItemSpellAndUnitTranslationFrameHeader:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() - 17.5)
    ItemSpellAndUnitTranslationFrameHeader:Show()
    ItemSpellAndUnitTranslationFrameHeader:SetPoint("TOPLEFT", 10, -10)

    if type == "npc" then
        local r, g, b = GameTooltipTextLeft1:GetTextColor()
        ItemSpellAndUnitTranslationFrameHeader:SetText(itemHeader)
        ItemSpellAndUnitTranslationFrameHeader:SetTextColor(r,g,b)

        local npcTitleTranslationWidth = ItemSpellAndUnitTranslationFrameHeader:GetStringWidth()
        local gameTooltipWidth = GameTooltip:GetWidth()

        if npcTitleTranslationWidth + 20 > gameTooltipWidth then
            ItemSpellAndUnitTranslationFrame:SetWidth(npcTitleTranslationWidth + 20)
            ItemSpellAndUnitTranslationFrameHeader:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth())

            if ItemSpellAndUnitTranslationFrameHeader:IsVisible() then
                GameTooltip:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth())
            end
        end
    else
        ItemSpellAndUnitTranslationFrameHeader:SetText(SetColorForLine(itemHeader))
    end

    if MultiLanguageOptions.SELECTED_INTERACTION == "hover-hotkey" then
        if hotkeyButtonPressed then
            ItemSpellAndUnitTranslationFrame:Show()
        else
            ItemSpellAndUnitTranslationFrame:Hide()
        end
    else
        ItemSpellAndUnitTranslationFrame:Show()
    end

    local existingLines = #activeItemSpellOrUnitLines
    local totalFrameHeight = ItemSpellAndUnitTranslationFrameHeader:GetHeight()
    local newLines = 0
    local frameAdditionalHeight = 0

    if ShowOnlyTitleTranslation(type) then
        SetItemSpellAndUnitTranslationFrameHeightAndPosition(totalFrameHeight + 20, gameToolTipHeight)

        if existingLines > 0 then
            for _, frame in ipairs(activeItemSpellOrUnitLines) do
                frame:Hide()
            end
            activeItemSpellOrUnitLines = {}
        end

        activeItemSpellOrUnitId = id

        return
    end

    if id ~= activeItemSpellOrUnitId then
        -- A new entity is hovered
        local parent = ItemSpellAndUnitTranslationFrameHeader
        local spellColorLinePassed = false

        if itemText then
            for line in itemText:gmatch("[^\r\n]+") do
                local lineFontString
                local lineFontStringHeight

                if newLines < existingLines then
                    lineFontString = activeItemSpellOrUnitLines[newLines + 1]
                else
                    lineFontString = ItemSpellAndUnitTranslationFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                    table.insert(activeItemSpellOrUnitLines, lineFontString)
                end

                local firstWord, secondWord = line:match("{(.-)}%s-{(.-)}")

                if firstWord and secondWord then
                    local secondFontString

                    if newLines + 1 < existingLines then
                        secondFontString = activeItemSpellOrUnitLines[newLines + 2]
                    else
                        secondFontString = ItemSpellAndUnitTranslationFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                        table.insert(activeItemSpellOrUnitLines, secondFontString)
                    end

                    lineFontString:SetPoint(
                        "TOPLEFT",
                        parent,
                        "BOTTOMLEFT",
                        0,
                        -2.5 - frameAdditionalHeight
                    )
                    lineFontString:SetText(SetColorForLine(firstWord, spellColorLinePassed))
                    lineFontString:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() / 2 - 10)
                    lineFontString:SetJustifyH("LEFT")
                    lineFontString:Show()

                    secondFontString:SetPoint(
                        "TOPLEFT",
                        parent,
                        "BOTTOMLEFT",
                        ItemSpellAndUnitTranslationFrame:GetWidth() / 2 - 7.5,
                        -2.5 - frameAdditionalHeight
                    )
                    secondFontString:SetText(SetColorForLine(secondWord, spellColorLinePassed))
                    secondFontString:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() / 2 - 10)
                    secondFontString:SetJustifyH("RIGHT")
                    secondFontString:Show()

                    local heightOne = lineFontString:GetHeight()
                    local heightTwo = secondFontString:GetHeight()

                    lineFontStringHeight = math.max(heightOne, heightTwo)
                    newLines = newLines + 2

                    if heightTwo > heightOne then
                        frameAdditionalHeight = heightTwo - heightOne
                    else
                        frameAdditionalHeight = 0
                    end
                else
                    lineFontString:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -2.5 - frameAdditionalHeight)
                    lineFontString:SetText(SetColorForLine(line, spellColorLinePassed))
                    lineFontString:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() - 17.5)
                    lineFontString:SetNonSpaceWrap(true)
                    lineFontString:SetJustifyH("LEFT")
                    lineFontString:Show()

                    lineFontStringHeight = lineFontString:GetHeight()
                    frameAdditionalHeight = 0
                    newLines = newLines + 1
                end

                if type == "spell" then
                    if string.find(line, "%[q%]") then
                        spellColorLinePassed = true
                    end
                end

                parent = lineFontString
                totalFrameHeight = totalFrameHeight + lineFontStringHeight + 2.5
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

        activeItemSpellOrUnitId = id
    else
        -- The same entity is hovered
        if not itemText then
            return
        end

        local frameWidth = ItemSpellAndUnitTranslationFrame:GetWidth()
        local singleWidth = frameWidth - 17.5
        local doubleWidth = (frameWidth / 2) - 10

        for line in itemText:gmatch("[^\r\n]+") do
            if newLines >= existingLines then break end

            local lineFontString = activeItemSpellOrUnitLines[newLines + 1]
            newLines = newLines + 1

            local firstWord, secondWord = line:match("{(.-)} {(.-)}")
            local lineFontStringHeight

            if firstWord and secondWord then
                if newLines >= existingLines then break end

                local secondFontString = activeItemSpellOrUnitLines[newLines + 1]

                local heightOne = lineFontString:GetHeight()
                local heightTwo = secondFontString:GetHeight()

                lineFontString:SetWidth(doubleWidth)
                secondFontString:SetWidth(doubleWidth)

                newLines = newLines + 1
                lineFontStringHeight = math.max(heightOne, heightTwo)
            else
                lineFontString:SetWidth(singleWidth)
                lineFontStringHeight = lineFontString:GetHeight()
            end

            totalFrameHeight = totalFrameHeight + lineFontStringHeight + 2.5
        end
    end

    SetItemSpellAndUnitTranslationFrameHeightAndPosition(totalFrameHeight + 20, gameToolTipHeight)
end

-- General functions
local function SetHotkeyButtonPressed(self, key, eventType)
    if not MultiLanguageOptions["QUEST_TRANSLATIONS"] or MultiLanguageOptions["SELECTED_INTERACTION"] ~= "hover-hotkey" or not MultiLanguageOptions["SELECTED_HOTKEY"] then
        return
    end

    if eventType ~= "OnKeyDown" or key ~= MultiLanguageOptions["SELECTED_HOTKEY"] then
        return
    end

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

        if not itemID then
            return
        end

        local item = GetDataByID(MultiLanguageItemData, itemID)

        if item then
            UpdateItemSpellAndUnitTranslationFrame(item.name, item.additional_info, itemID, "item")
        else
            ItemSpellAndUnitTranslationFrame:Hide()
        end
    elseif spellID and spellTranslationsEnabled then
        local spell = GetDataByID(MultiLanguageSpellData, spellID)

        if spell then
            UpdateItemSpellAndUnitTranslationFrame(spell.name, spell.additional_info, spellID, "spell")
        else
            ItemSpellAndUnitTranslationFrame:Hide()
        end
    elseif unitGUID and npcTranslationsEnabled then
        local unitType, _, _, _, _, npcID = strsplit("-", unitGUID)

        if unitType == "Creature" then
            if not npcID then
                return
            end

            local npc = GetDataByID(MultiLanguageNpcData, npcID)

            if npc then
                UpdateItemSpellAndUnitTranslationFrame(npc.name, npc.subname, npcID, "npc")
            else
                ItemSpellAndUnitTranslationFrame:Hide()
            end
        else
            ItemSpellAndUnitTranslationFrame:Hide()
        end
    else
        ItemSpellAndUnitTranslationFrame:Hide()
    end
end

-- Register scripts to frames
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

translationFrame:SetScript("OnKeyDown", function(self, key) SetHotkeyButtonPressed(self, key, "OnKeyDown") end)
translationFrame:SetPropagateKeyboardInput(true)

SetQuestHoverScripts(QuestLogFrame, true)
SetQuestHoverScripts(QuestFrame, false)

SetQuestHoverScripts(QuestProgressScrollFrame, true)
SetQuestHoverScripts(QuestDetailScrollFrame, true)
SetQuestHoverScripts(QuestRewardScrollFrame, true)

SetQuestHoverScripts(QuestFrameCompleteButton, true)
SetQuestHoverScripts(QuestFrameCompleteQuestButton, true)
SetQuestHoverScripts(QuestFrameGoodbyeButton, true)
SetQuestHoverScripts(QuestFrameCancelButton, true)
