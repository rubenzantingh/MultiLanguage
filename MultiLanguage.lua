local lastQuestFrameEvent = nil
local addonName, addonTable = ...
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

local gameLocale = GetLocale()
local gameLanguage = string.sub(gameLocale, 1, 2)

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

local function GetDataByID(dataType, dataId)
    if not addonTable[dataType] then
        return nil
    end

    languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

    if not addonTable[dataType][languageCode] then
        return nil
    end

    local convertedId = tonumber(dataId)

    if addonTable[dataType][languageCode][convertedId] then
        return addonTable[dataType][languageCode][convertedId]
    end

    return nil
end

-- Quests functions
local function SetQuestTranslationDetails(headerText, objectiveText, descriptionHeader, descriptionText, isQuestFrame)
    if MultiLanguageOptions["SELECTED_QUEST_DISPLAY_MODE"] ~= 'replace' then
        return
    end

    if isQuestFrame then
        QuestProgressTitleText:SetText(headerText)
        QuestProgressText:SetText(objectiveText)

        QuestInfoTitleHeader:SetText(headerText)
        QuestInfoRewardText:SetText(objectiveText)

        QuestInfoObjectivesHeader:SetText(descriptionHeader)
        QuestInfoObjectivesText:SetText(descriptionText)
        QuestInfoDescriptionText:SetText(objectiveText)
    else
        QuestLogQuestTitle:SetText(headerText);
        QuestLogObjectivesText:SetText(objectiveText);
        QuestLogDescriptionTitle:SetText(descriptionHeader)
        QuestLogQuestDescription:SetText(descriptionText)
    end
end

local function DisplayQuestTranslationFrame()
   if MultiLanguageOptions["SELECTED_QUEST_DISPLAY_MODE"] == 'tooltip' then
       QuestTranslationFrame:Show()
   end
end

local function SetQuestFrameDetails(isQuestFrame)
    SetQuestTranslationDetails(
        QuestTranslationFramePrimaryHeader:GetText(),
        QuestTranslationFramePrimaryText:GetText(),
        QuestTranslationFrameSecondaryHeader:GetText(),
        QuestTranslationFrameSecondaryText:GetText(),
        isQuestFrame
    )
end

local function ResetQuestFrameDetails(questFrame)
    if questFrame then
        local headerText = GetTitleText()
        local objectiveText = ''
        local descriptionHeader = ''
        local descriptionText = ''

        if lastQuestFrameEvent == "QUEST_PROGRESS" then
            objectiveText = GetProgressText()
        elseif lastQuestFrameEvent == "QUEST_COMPLETE" then
            objectiveText = GetRewardText()
        elseif lastQuestFrameEvent == "QUEST_DETAIL" then
            objectiveText = GetQuestText()
            descriptionText = GetObjectiveText()
            descriptionHeader = _G["MultiLanguageTranslations"][gameLanguage]["objectives"]
        end

        SetQuestTranslationDetails(
            headerText,
            objectiveText,
            descriptionHeader,
            descriptionText,
            true
        )
    else
        local selectedQuestIndex = GetQuestLogSelection()
        local description, objectives = GetQuestLogQuestText()
        local title = GetQuestLogTitle(selectedQuestIndex)

        SetQuestTranslationDetails(
            title,
            objectives,
            _G["MultiLanguageTranslations"][gameLanguage]["description"],
            description,
            false
        )
    end
end

local function SetTranslationFrameQuestDetails(headerText, objectiveText, descriptionHeader, descriptionText, parentFrame, yOffset, isQuestFrame)
    QuestTranslationFramePrimaryHeader:SetText(headerText)
    QuestTranslationFramePrimaryText:SetText(objectiveText)
    QuestTranslationFrameSecondaryHeader:SetText(descriptionHeader)
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

    -- Quest log frame
    if QuestLogFrame:IsShown() and QuestLogFrame:IsMouseOver() then
        selectedQuestIndex = GetQuestLogSelection()

        if selectedQuestIndex <= 0 then
            return
        end

        questId = select(8, GetQuestLogTitle(selectedQuestIndex))
        questData = GetDataByID("questData", questId)

        if not questData then
            QuestTranslationFrame:Hide()
            return
        end

        local languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

        if MultiLanguageOptions["SELECTED_INTERACTION"] == "hover-hotkey" then
            if hotkeyButtonPressed then
                SetQuestFrameDetails(false)
                DisplayQuestTranslationFrame()
            end
        else
            SetQuestFrameDetails(false)
            DisplayQuestTranslationFrame()
        end

        SetTranslationFrameQuestDetails(
            questData.title,
            questData.objective,
            _G["MultiLanguageTranslations"][languageCode]["description"],
            questData.description,
            QuestLogFrame,
            -QuestLogListScrollFrame:GetHeight() - (QuestLogFrame:GetTop() - QuestLogListScrollFrame:GetTop()) - 5, false
        )
    end

    -- Quest frame
    if QuestFrame:IsShown() and QuestFrame:IsMouseOver() then
        questId = GetQuestID()

        if not questId then
            return
        end

        questData = GetDataByID("questData", questId)

        if not questData then
            QuestTranslationFrame:Hide()
            return
        end

        if MultiLanguageOptions["SELECTED_INTERACTION"] == "hover-hotkey" then
            if hotkeyButtonPressed then
                SetQuestFrameDetails(true)
                DisplayQuestTranslationFrame()
            end
        else
            SetQuestFrameDetails(true)
            DisplayQuestTranslationFrame()
        end

        languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]

        if lastQuestFrameEvent == "QUEST_PROGRESS" then
            SetTranslationFrameQuestDetails(
                questData.title,
                questData.progress,
                "",
                "",
                QuestFrame,
                -80,
                true
            )
        elseif lastQuestFrameEvent == "QUEST_COMPLETE" then
            SetTranslationFrameQuestDetails(
                questData.title,
                questData.completion,
                "",
                "",
                QuestFrame,
                -80,
                true
            )
        elseif lastQuestFrameEvent == "QUEST_DETAIL" then
            SetTranslationFrameQuestDetails(
                questData.title,
                questData.description,
                _G["MultiLanguageTranslations"][languageCode]["objectives"],
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

        if MultiLanguageOptions["SELECTED_INTERACTION"] == "hover" then
            ResetQuestFrameDetails(true)
            ResetQuestFrameDetails(false)
        end
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

    if MultiLanguageOptions["SELECTED_INTERACTION"] == "hover-hotkey" then
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

                    lineFontStringHeight = lineFontString:GetHeight()
                    frameAdditionalHeight = 0
                    newLines = newLines + 1
                end

                lineFontString:SetJustifyH("LEFT")
                lineFontString:Show()

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

        if not questFrameBeingHovered then
            return
        end

        ResetQuestFrameDetails(true)
        ResetQuestFrameDetails(false)

        QuestTranslationFrame:Hide()
    else
        hotkeyButtonPressed = true

        if not questFrameBeingHovered then
            return
        end

        SetQuestFrameDetails(true)
        SetQuestFrameDetails(false)

        DisplayQuestTranslationFrame()
    end
end

local function OnTooltipSetData(self)
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

        local item = GetDataByID("itemData", itemID)

        if item then
            UpdateItemSpellAndUnitTranslationFrame(item.name, item.additional_info, itemID, "item")
        else
            ItemSpellAndUnitTranslationFrame:Hide()
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
            if not npcID then
                return
            end
        
            local npc = GetDataByID("npcData", npcID)

            if npc then
                local reaction = UnitReaction("player", "mouseover")
                local level = UnitLevel("mouseover")
                local languageCode = MultiLanguageOptions["SELECTED_LANGUAGE"]
                local levelText = _G["MultiLanguageTranslations"][languageCode]["level"]
                local combinedSubname = npc.subname or ""
                local additionalInfo = ""

                if level and level > 0 then
                    additionalInfo = levelText .. " " .. level
                    
                    if reaction and (reaction == 4 or reaction == 2) then
                        local creatureType = UnitCreatureType("mouseover")

                        if not creatureType then
                            return
                        end

                        local translatedType = _G["MultiLanguageTranslations"][languageCode]["creatureTypes"][creatureType]

                        if translatedType then
                            additionalInfo = additionalInfo .. " " .. translatedType
                        else
                            additionalInfo = additionalInfo .. " " .. creatureType
                        end
                    end
                end
                
                if additionalInfo ~= "" then
                    if combinedSubname ~= "" then
                        combinedSubname = combinedSubname .. "\n" .. additionalInfo
                    else
                        combinedSubname = additionalInfo
                    end
                end
                
                UpdateItemSpellAndUnitTranslationFrame(npc.name, combinedSubname, npcID, "npc")
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

local function HookQuestLogTitleButtons()
    for i = 1, QUESTS_DISPLAYED do
        local questLogTitle = _G["QuestLogTitle"..i]

        if questLogTitle and not questLogTitle.isHooked then
            questLogTitle:HookScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    if MultiLanguageOptions["QUEST_TRANSLATIONS"] and MultiLanguageOptions["SELECTED_INTERACTION"] == "hover-hotkey" and hotkeyButtonPressed then
                        UpdateQuestTranslationFrame()
                        SetQuestFrameDetails(false)
                    end
                end
            end)
            questLogTitle.isHooked = true
        end
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

QuestFrame:HookScript("OnShow", function()
    UpdateQuestTranslationFrame()

    if MultiLanguageOptions["SELECTED_INTERACTION"] == "hover-hotkey" then
        if hotkeyButtonPressed then
            SetQuestFrameDetails(true)
        end
    end
end)

QuestLogFrame:HookScript("OnShow", function()
    UpdateQuestTranslationFrame()

    if MultiLanguageOptions["SELECTED_INTERACTION"] == "hover-hotkey" then
        if hotkeyButtonPressed then
            SetQuestFrameDetails(false)
        end
    end
end)

translationFrame:SetScript("OnKeyDown", function(self, key) SetHotkeyButtonPressed(self, key, "OnKeyDown") end)
translationFrame:SetPropagateKeyboardInput(true)

hooksecurefunc("QuestLog_Update", HookQuestLogTitleButtons)

SetQuestHoverScripts(QuestLogFrame, true)
SetQuestHoverScripts(QuestFrame, false)

SetQuestHoverScripts(QuestProgressScrollFrame, true)
SetQuestHoverScripts(QuestDetailScrollFrame, true)
SetQuestHoverScripts(QuestRewardScrollFrame, true)

SetQuestHoverScripts(QuestFrameCompleteButton, true)
SetQuestHoverScripts(QuestFrameCompleteQuestButton, true)
SetQuestHoverScripts(QuestFrameGoodbyeButton, true)
SetQuestHoverScripts(QuestFrameCancelButton, true)
