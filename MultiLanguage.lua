local lastQuestFrameEvent = nil
local addonName, addonTable = ...
local translationFrame = CreateFrame("Frame")

local function GetDataByID(dataType, dataId)
    if addonTable[dataType] then
        local convertedId = tonumber(dataId)
        if addonTable[dataType][convertedId] then
            return addonTable[dataType][convertedId]
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
                SetQuestDetails(
                    questData.title,
                    questData.objective,
                    "Description",
                    questData.description,
                    QuestLogFrame,
                    -QuestLogListScrollFrame:GetHeight() - (QuestLogFrame:GetTop() - QuestLogListScrollFrame:GetTop()) - 5, false
                )
            end
        end
    end

    if QuestFrame:IsShown() and QuestFrame:IsMouseOver() then
        questId = GetQuestID()

        if questId then
            questData = GetDataByID("questData", questId)
            if questData then
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
                            "Quest objectives",
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
    end
end

local function SetQuestHoverScripts(frame, children)
    local frameName = frame:GetName()

    if frameName ~= "QuestLogListScrollFrame" and not string.find(frameName, "QuestLogItem") and not string.find(frameName, "QuestProgressItem") then
        frame:SetScript("OnEnter", function()
            local questTranslationsEnabled = MultiLanguageOptions["QUEST_TRANSLATIONS"]

            if questTranslationsEnabled then
                UpdateQuestTranslationFrame()
                QuestTranslationFrame:Show()
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

local function elementIsBelowBottom(element)
    local elementY = element:GetBottom()

    if not elementY then
        return true
    end

    return elementY < 0
end

local function UpdateItemSpellAndUnitTranslationFrame(itemHeader, itemText)
    local gameToolTipWidth = GameTooltip:GetWidth()
    local gameToolTipHeight = GameTooltip:GetHeight()

    ItemSpellAndUnitTranslationFrame:SetWidth(gameToolTipWidth)
    ItemSpellAndUnitTranslationFrameHeader:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() - 20)
    ItemSpellAndUnitTranslationFrameText:SetWidth(ItemSpellAndUnitTranslationFrame:GetWidth() - 20)
    
    local elementIsBelowBottom = elementIsBelowBottom(ItemSpellAndUnitTranslationFrame)

    ItemSpellAndUnitTranslationFrame:Show()
    ItemSpellAndUnitTranslationFrameHeader:Show()
    ItemSpellAndUnitTranslationFrameText:Show()

    ItemSpellAndUnitTranslationFrameHeader:SetText(itemHeader)
    ItemSpellAndUnitTranslationFrameText:SetText(itemText)

    ItemSpellAndUnitTranslationFrame:SetHeight(ItemSpellAndUnitTranslationFrameHeader:GetHeight() + ItemSpellAndUnitTranslationFrameText:GetHeight() + 20)
    ItemSpellAndUnitTranslationFrameText:SetPoint("TOPLEFT", 10, - ItemSpellAndUnitTranslationFrameHeader:GetHeight() - 10)
    ItemSpellAndUnitTranslationFrameHeader:SetPoint("TOPLEFT", 10, -10)
    ItemSpellAndUnitTranslationFrame:SetPoint("TOPLEFT", 0, elementIsBelowBottom and gameToolTipHeight + 5 or -gameToolTipHeight - 5)
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
                UpdateItemSpellAndUnitTranslationFrame(item.name, item.additional_info)
            end
        end
    elseif spellID and spellTranslationsEnabled then
        local spell = GetDataByID("spellData", spellID)

        if spell then
            UpdateItemSpellAndUnitTranslationFrame(spell.name, spell.additional_info)
        end
    elseif unitGUID and npcTranslationsEnabled then
        local unitType, _, _, _, _, npcID = strsplit("-", unitGUID)

        if unitType == "Creature" then
            if npcID then
                local npc = GetDataByID("npcData", npcID)
                UpdateItemSpellAndUnitTranslationFrame(npc.name, npc.subname)
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

local function addonLoaded(self, event, addonLoadedName)
    if addonLoadedName == addonName then
        local questTranslationsEnabled = MultiLanguageOptions["QUEST_TRANSLATIONS"]

        if questTranslationsEnabled then

        end
    end
end