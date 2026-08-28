local lastQuestFrameEvent = nil
local macroSpellID = nil
local translationFrame = CreateFrame("Frame")
local activeItemSpellOrUnitLines = {}
local activeItemSpellOrUnitId = nil
local hotkeyButtonPressed = false
local questFrameBeingHovered = false
local translationTooltipFrameWidth = 200
local translationTooltipFrameHeight = 50

local lastTooltipSourceFrame = nil
local lastTooltipSourceType = nil

hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
    if ContainerFrameUtil_GetItemButtonAndContainer then
        local containerFrame = ContainerFrameUtil_GetItemButtonAndContainer(bag, slot)
        if containerFrame then
            lastTooltipSourceFrame = containerFrame
            lastTooltipSourceType = "bag"
            return
        end
    end

    for i = 1, NUM_CONTAINER_FRAMES or 13 do
        local frameName = "ContainerFrame" .. i
        local frame = _G[frameName]
        if frame and frame:IsShown() and frame:GetID() == bag then
            local buttonName = frameName .. "Item" .. slot
            local button = _G[buttonName]
            if button then
                lastTooltipSourceFrame = button
                lastTooltipSourceType = "bag"
                return
            end
        end
    end
end)

local inventorySlotFrames = {
    [1] = "CharacterHeadSlot",
    [2] = "CharacterNeckSlot",
    [3] = "CharacterShoulderSlot",
    [4] = "CharacterShirtSlot",
    [5] = "CharacterChestSlot",
    [6] = "CharacterWaistSlot",
    [7] = "CharacterLegsSlot",
    [8] = "CharacterFeetSlot",
    [9] = "CharacterWristSlot",
    [10] = "CharacterHandsSlot",
    [11] = "CharacterFinger0Slot",
    [12] = "CharacterFinger1Slot",
    [13] = "CharacterTrinket0Slot",
    [14] = "CharacterTrinket1Slot",
    [15] = "CharacterBackSlot",
    [16] = "CharacterMainHandSlot",
    [17] = "CharacterSecondaryHandSlot",
}

hooksecurefunc(GameTooltip, "SetInventoryItem", function(self, unit, slot)
    if unit == "player" and inventorySlotFrames[slot] then
        local button = _G[inventorySlotFrames[slot]]
        if button then
            lastTooltipSourceFrame = button
            lastTooltipSourceType = "inventory"
        end
    end
end)

hooksecurefunc(GameTooltip, "SetAction", function(self, actionSlot)
    local actionType = GetActionInfo(actionSlot)
    if actionType == "item" then
        local owner = self:GetOwner()
        if owner then
            lastTooltipSourceFrame = owner
            lastTooltipSourceType = "actionitem"
        end
    end
end)

GameTooltip:HookScript("OnHide", function()
    lastTooltipSourceFrame = nil
    lastTooltipSourceType = nil
end)

local function SafeSetFrameSize(frame, width, height)
    if width then
        pcall(function() frame:SetWidth(width) end)
    end
    if height then
        pcall(function() frame:SetHeight(height) end)
    end
end
local textColorCodes = {
    ["[q]"] = "|cFFFFD100",
    ["[q0]"] = "|cFF9D9D9D",
    ["[q2]"] = "|cFF00FF00",
    ["[q3]"] = "|cFF0070DD",
    ["[q4]"] = "|cFFA335EE",
    ["[q5]"] = "|cFFFF8000",
    ["[q6]"] = "|cFFE5CC80",
    ["[q7]"] = "|cFF00CCFF",
    ["[q8]"] = "|cFF00CCFF"
}

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
        macroSpellID = nil

        if tooltip ~= GameTooltip then return end
        if not data or not data.type then return end

        local spellTranslationsEnabled = MultiLanguageOptions["SPELL_TRANSLATIONS"]
        if not spellTranslationsEnabled then return end

        if data.type == Enum.TooltipDataType.Spell then
            macroSpellID = data.id
        elseif data.type == Enum.TooltipDataType.Macro then
            if tooltip.GetPrimaryTooltipData then
                local primaryData = tooltip:GetPrimaryTooltipData()

                if primaryData and primaryData.lines then
                    if primaryData.lines[1] then
                        macroSpellID = primaryData.lines[1].tooltipID
                    end
                end
            end
        end
    end)
end

local function elementWillBeAboveTop(element, parent)
    local elementHeight = element:GetHeight()
    local elementTop = parent:GetTop()

    if not canaccessvalue(elementHeight) or not canaccessvalue(elementTop) then
        return false
    end

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

    if QuestModelScene:IsShown() then
        xOffset = xOffset + QuestModelScene:GetWidth()
    end

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

function UpdateQuestTranslationFrame()
    local isAlways = MultiLanguageOptions and MultiLanguageOptions.SELECTED_INTERACTION == "always"
    if QuestMapDetailsScrollFrame:IsShown() and (isAlways or QuestMapDetailsScrollFrame:IsMouseOver()) then
        local questID = C_QuestLog.GetSelectedQuest()

        if not questID then
            return
        end

        questData = GetDataByID(MultiLanguageQuestData, questID)

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
    end

    if QuestFrame:IsShown() and (isAlways or QuestFrame:IsMouseOver()) then
        local questID = GetQuestID()

        if not questID then
            return
        end

        questData = GetDataByID(MultiLanguageQuestData, questID)

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
        if not (MultiLanguageOptions and MultiLanguageOptions.SELECTED_INTERACTION == "always") then
            QuestTranslationFrame:Hide()
        end
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

local cachedTooltipLeft = nil
local cachedTooltipTop = nil
local cachedTooltipBottom = nil
local cachedTooltipRight = nil

GameTooltip:HookScript("OnUpdate", function(self)
    local left = self:GetLeft()
    local top = self:GetTop()
    local bottom = self:GetBottom()
    local right = self:GetRight()

    if canaccessvalue(left) and canaccessvalue(top) and canaccessvalue(bottom) and canaccessvalue(right) then
        cachedTooltipLeft = left
        cachedTooltipTop = top
        cachedTooltipBottom = bottom
        cachedTooltipRight = right
    end
end)

GameTooltip:HookScript("OnHide", function()
    cachedTooltipLeft = nil
    cachedTooltipTop = nil
    cachedTooltipBottom = nil
    cachedTooltipRight = nil
end)

local function GetFramePosition(frame)
    if not frame then return nil, nil, nil end

    local left = frame:GetLeft()
    local top = frame:GetTop()
    local bottom = frame:GetBottom()

    if canaccessvalue(left) and canaccessvalue(top) and canaccessvalue(bottom) then
        return left, top, bottom
    end
    return nil, nil, nil
end

local function SetTranslationFrameHeightAndPosition(height, gameToolTipHeight)
    translationTooltipFrameHeight = height
    SafeSetFrameSize(TranslationTooltipFrame, nil, height)
    TranslationTooltipFrame:ClearAllPoints()

    local left, top, bottom

    if lastTooltipSourceType == "inventory" and lastTooltipSourceFrame then
        local srcLeft, srcTop, srcBottom = GetFramePosition(lastTooltipSourceFrame)
        if srcLeft then
            local srcWidth = lastTooltipSourceFrame:GetWidth()
            if not canaccessvalue(srcWidth) then
                srcWidth = 40
            end
            TranslationTooltipFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", srcLeft + srcWidth, srcTop)
            return
        end
    elseif lastTooltipSourceType == "bag" and lastTooltipSourceFrame then
        local srcLeft, srcTop, srcBottom = GetFramePosition(lastTooltipSourceFrame)
        if srcLeft then
            TranslationTooltipFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", srcLeft, srcTop)
            return
        end
    elseif lastTooltipSourceType == "actionitem" then
        local screenWidth = GetScreenWidth()
        TranslationTooltipFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", screenWidth - 10, gameToolTipHeight + height + 15)
        return
    end

    left, top, bottom = GetFramePosition(GameTooltip)

    if not left and cachedTooltipLeft and cachedTooltipTop and cachedTooltipBottom then
        left = cachedTooltipLeft
        top = cachedTooltipTop
        bottom = cachedTooltipBottom
    end

    if not left then
        local owner = GameTooltip:GetOwner()
        if owner then
            local ownerLeft, ownerTop, ownerBottom = GetFramePosition(owner)
            if ownerLeft then
                left = ownerLeft + (owner:GetWidth() or 0) + 5
                top = ownerTop
                bottom = ownerTop - gameToolTipHeight
            end
        end
    end

    if not left and lastTooltipSourceFrame then
        local srcLeft, srcTop, srcBottom = GetFramePosition(lastTooltipSourceFrame)
        if srcLeft then
            local srcWidth = lastTooltipSourceFrame:GetWidth()
            if not canaccessvalue(srcWidth) then
                srcWidth = 40
            end
            left = srcLeft + srcWidth + 5
            top = srcTop
            bottom = srcTop - gameToolTipHeight
        end
    end

    if not left then
        local scale = UIParent:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        cursorX = cursorX / scale
        cursorY = cursorY / scale

        left = cursorX + 20
        top = cursorY - 10
        bottom = top - gameToolTipHeight
    end

    local screenHeight = GetScreenHeight()
    local screenWidth = GetScreenWidth()

    if left + translationTooltipFrameWidth > screenWidth then
        left = screenWidth - translationTooltipFrameWidth - 5
    end

    if top + height + 5 > screenHeight then
        TranslationTooltipFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, bottom - 5)
    else
        TranslationTooltipFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, top + 5)
    end
end

local function UpdateTranslationTooltipFrame(itemHeader, itemText, id, type)
    local gameToolTipWidth = GameTooltip:GetWidth()
    local gameToolTipHeight = GameTooltip:GetHeight()
    local tooltipValuesAccessible = canaccessvalue(gameToolTipWidth) and canaccessvalue(gameToolTipHeight)

    if not tooltipValuesAccessible then
        gameToolTipWidth = 300
        gameToolTipHeight = 100
    end

    translationTooltipFrameWidth = gameToolTipWidth
    SafeSetFrameSize(TranslationTooltipFrame, translationTooltipFrameWidth, nil)

    TranslationTooltipFrameHeader:SetWidth(translationTooltipFrameWidth - 17.5)
    TranslationTooltipFrameHeader:Show()
    TranslationTooltipFrameHeader:SetPoint("TOPLEFT", 10, -10)

    local r, g, b = GameTooltipTextLeft1:GetTextColor()

    if type == "npc" then
        TranslationTooltipFrameHeader:SetText(itemHeader)
        TranslationTooltipFrameHeader:SetTextColor(r,g,b)
    else
        TranslationTooltipFrameHeader:SetText(SetColorForLine(itemHeader))
    end

    if MultiLanguageOptions.SELECTED_INTERACTION == "hover-hotkey" then
        if hotkeyButtonPressed then
            TranslationTooltipFrame:Show()
        else
            TranslationTooltipFrame:Hide()
        end
    else
        TranslationTooltipFrame:Show()
    end

    local existingLines = #activeItemSpellOrUnitLines
    local headerHeight = TranslationTooltipFrameHeader:GetHeight()
    local totalFrameHeight = canaccessvalue(headerHeight) and headerHeight or 14
    local newLines = 0
    local frameAdditionalHeight = 0

    if ShowOnlyTitleTranslation(type) then
        SetTranslationFrameHeightAndPosition(totalFrameHeight + 20, gameToolTipHeight)

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
        local parent = TranslationTooltipFrameHeader
        local spellColorLinePassed = false

        if itemText then
            for line in itemText:gmatch("[^\r\n]+") do
                local lineFontString
                local lineFontStringHeight

                if newLines < existingLines then
                    lineFontString = activeItemSpellOrUnitLines[newLines + 1]
                else
                    lineFontString = TranslationTooltipFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
                    table.insert(activeItemSpellOrUnitLines, lineFontString)
                end

                local firstWord, secondWord = line:match("{(.-)}%s-{(.-)}")

                if firstWord and secondWord then
                    local secondFontString

                    if newLines + 1 < existingLines then
                        secondFontString = activeItemSpellOrUnitLines[newLines + 2]
                    else
                        secondFontString = TranslationTooltipFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
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
                    lineFontString:SetWidth(translationTooltipFrameWidth / 2 - 10)
                    lineFontString:SetJustifyH("LEFT")
                    lineFontString:Show()

                    secondFontString:SetPoint(
                        "TOPLEFT",
                        parent,
                        "BOTTOMLEFT",
                        translationTooltipFrameWidth / 2 - 7.5,
                        -2.5 - frameAdditionalHeight
                    )
                    secondFontString:SetText(SetColorForLine(secondWord, spellColorLinePassed))
                    secondFontString:SetWidth(translationTooltipFrameWidth / 2 - 10)
                    secondFontString:SetJustifyH("RIGHT")
                    secondFontString:Show()

                    local heightOne = lineFontString:GetHeight()
                    local heightTwo = secondFontString:GetHeight()
                    heightOne = canaccessvalue(heightOne) and heightOne or 12
                    heightTwo = canaccessvalue(heightTwo) and heightTwo or 12

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
                    lineFontString:SetWidth(translationTooltipFrameWidth - 17.5)
                    lineFontString:SetNonSpaceWrap(true)
                    lineFontString:SetJustifyH("LEFT")
                    lineFontString:Show()

                    local lfHeight = lineFontString:GetHeight()
                    lineFontStringHeight = canaccessvalue(lfHeight) and lfHeight or 12
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

        local singleWidth = translationTooltipFrameWidth - 17.5
        local doubleWidth = (translationTooltipFrameWidth / 2) - 10

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
                heightOne = canaccessvalue(heightOne) and heightOne or 12
                heightTwo = canaccessvalue(heightTwo) and heightTwo or 12

                lineFontString:SetWidth(doubleWidth)
                secondFontString:SetWidth(doubleWidth)

                newLines = newLines + 1
                lineFontStringHeight = math.max(heightOne, heightTwo)
            else
                lineFontString:SetWidth(singleWidth)
                local lfh = lineFontString:GetHeight()
                lineFontStringHeight = canaccessvalue(lfh) and lfh or 12
            end

            totalFrameHeight = totalFrameHeight + lineFontStringHeight + 2.5
        end
    end

    SetTranslationFrameHeightAndPosition(totalFrameHeight + 20, gameToolTipHeight)
end

-- General functions
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

local function OnTooltipSetData(self)
    self:Show()

    local _, itemLink = self:GetItem()
    local _, spellID = self:GetSpell()
    local owner = self:GetOwner()

    if owner == nil then
        return
    end

    local questID = owner.questID
    local unitGUID = UnitGUID("mouseover")

    if issecretvalue(UnitGUID("mouseover")) then
        unitGUID = nil
    end

    if questID then
        return
    end

    local itemTranslationsEnabled = MultiLanguageOptions["ITEM_TRANSLATIONS"]
    local spellTranslationsEnabled = MultiLanguageOptions["SPELL_TRANSLATIONS"]
    local npcTranslationsEnabled = MultiLanguageOptions["NPC_TRANSLATIONS"]
    local questTranslationsEnabled = MultiLanguageOptions["QUEST_TRANSLATIONS"]

    if itemLink and itemTranslationsEnabled then
        local itemID = GetItemIDFromLink(itemLink)

        if not itemID then
            return
        end

        local item = GetDataByID(MultiLanguageItemData, itemID)

        if item then
            UpdateTranslationTooltipFrame(item.name, item.additional_info, itemID, "item")
        else
            TranslationTooltipFrame:Hide()
        end
    elseif (spellID and spellTranslationsEnabled) or (macroSpellID and spellTranslationsEnabled) then
        local spell = nil

        if spellID then
            spell = GetDataByID(MultiLanguageSpellData, spellID)
        elseif macroSpellID then
            spell = GetDataByID(MultiLanguageSpellData, macroSpellID)
        end

        if spell then
            UpdateTranslationTooltipFrame(spell.name, spell.additional_info, spellID, "spell")
        else
            TranslationTooltipFrame:Hide()
        end
    elseif unitGUID and npcTranslationsEnabled then
        local unitType, _, _, _, _, npcID = strsplit("-", unitGUID)

        if unitType == "Creature" then
            if not npcID then
                return
            end

            local npc = GetDataByID(MultiLanguageNpcData, npcID)

            if npc then
                UpdateTranslationTooltipFrame(npc.name, npc.subname, npcID, "npc")
            else
                TranslationTooltipFrame:Hide()
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

SetQuestHoverScripts(QuestFrameDetailPanel, true)
SetQuestHoverScripts(QuestMapDetailsScrollFrame, false)
SetQuestHoverScripts(QuestFrame, false)

-- "Always show" interaction mode: auto-update quest translations
local alwaysModeFrame = CreateFrame("Frame")
alwaysModeFrame:RegisterEvent("QUEST_LOG_UPDATE")
alwaysModeFrame:SetScript("OnEvent", function()
    if MultiLanguageOptions and MultiLanguageOptions.SELECTED_INTERACTION == "always"
       and MultiLanguageOptions.QUEST_TRANSLATIONS
       and QuestMapDetailsScrollFrame and QuestMapDetailsScrollFrame:IsShown() then
        UpdateQuestTranslationFrame()
    end
end)

QuestMapDetailsScrollFrame:HookScript("OnShow", function()
    if MultiLanguageOptions and MultiLanguageOptions.SELECTED_INTERACTION == "always"
       and MultiLanguageOptions.QUEST_TRANSLATIONS then
        C_Timer.After(0.1, function()
            UpdateQuestTranslationFrame()
        end)
    end
end)

QuestMapDetailsScrollFrame:HookScript("OnHide", function()
    if MultiLanguageOptions and MultiLanguageOptions.SELECTED_INTERACTION == "always" then
        QuestTranslationFrame:Hide()
    end
end)
