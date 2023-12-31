local questTranslationFrame = CreateFrame("Frame", "QuestTranslationFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
questTranslationFrame:SetWidth(QuestLogFrame:GetWidth())
questTranslationFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
questTranslationFrame:SetBackdropColor(0, 0, 0, 1)

local questTranslationFramePrimaryHeader = questTranslationFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
questTranslationFramePrimaryHeader:SetTextScale(1.3)
questTranslationFramePrimaryHeader:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFramePrimaryHeader:SetWordWrap(true)
questTranslationFramePrimaryHeader:SetJustifyH("LEFT")

local questTranslationFrameSecondaryHeader = questTranslationFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
questTranslationFrameSecondaryHeader:SetTextScale(1.3)
questTranslationFrameSecondaryHeader:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFrameSecondaryHeader:SetWordWrap(true)
questTranslationFrameSecondaryHeader:SetJustifyH("LEFT")

local questTranslationFramePrimaryText = questTranslationFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
questTranslationFramePrimaryText:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFramePrimaryText:SetWordWrap(true)
questTranslationFramePrimaryText:SetJustifyH("LEFT")

local questTranslationFrameSecondaryText = questTranslationFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
questTranslationFrameSecondaryText:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFrameSecondaryText:SetWordWrap(true)
questTranslationFrameSecondaryText:SetJustifyH("LEFT")

local lastQuestFrameEvent = nil

local addonName, addonTable = ...

local function GetQuestDataByID(questId)
    if addonTable.questData then
        if addonTable.questData[questId] then
            return addonTable.questData[questId]
        end
    end

    return nil
end

local function SetQuestDetails(headerText, objectiveText, descriptionHeader, descriptionText, parentFrame, yOffset, isQuestFrame)
    questTranslationFramePrimaryHeader:SetText(headerText)
    questTranslationFramePrimaryText:SetText(objectiveText)
    questTranslationFrameSecondaryHeader:SetText(descriptionHeader)
    questTranslationFrameSecondaryText:SetText(descriptionText)

    textTopMargin = -questTranslationFramePrimaryHeader:GetHeight() - 15
    descriptionHeaderTopMargin = textTopMargin - questTranslationFramePrimaryText:GetHeight() - 10
    descriptionTextTopMargin = descriptionHeaderTopMargin - questTranslationFrameSecondaryHeader:GetHeight() - 5

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

    questTranslationFramePrimaryHeader:SetPoint("TOPLEFT", 10, -10)
    questTranslationFramePrimaryText:SetPoint("TOPLEFT", 10, textTopMargin)
    questTranslationFrameSecondaryHeader:SetPoint("TOPLEFT", 10, descriptionHeaderTopMargin)
    questTranslationFrameSecondaryText:SetPoint("TOPLEFT", 10, descriptionTextTopMargin)
    questTranslationFrame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", -15, yOffset)

    questTranslationFrame:SetParent(parentFrame)
    questTranslationFrame:SetHeight(
        questTranslationFramePrimaryHeader:GetHeight() +
        questTranslationFramePrimaryText:GetHeight() +
        questTranslationFrameSecondaryHeader:GetHeight() +
        questTranslationFrameSecondaryText:GetHeight() +
        heightPadding
    )
end

local function UpdateQuestTranslationFrame()
    local selectedQuestIndex, questId, questData

    if QuestLogFrame:IsShown() and QuestLogFrame:IsMouseOver() then
        selectedQuestIndex = GetQuestLogSelection()

        if selectedQuestIndex > 0 then
            questId = select(8, GetQuestLogTitle(selectedQuestIndex))
            questData = GetQuestDataByID(questId)

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
            questData = GetQuestDataByID(questId)

            if questData then
                if lastQuestFrameEvent == "QUEST_PROGRESS" then
                    questTranslationFrame:Show()
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
                    questTranslationFrame:Hide()
                end
            end
        end
    end
end

questTranslationFrame:RegisterEvent("QUEST_PROGRESS")
questTranslationFrame:RegisterEvent("QUEST_COMPLETE")
questTranslationFrame:RegisterEvent("QUEST_FINISHED")
questTranslationFrame:RegisterEvent("QUEST_DETAIL")

questTranslationFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "QUEST_FINISHED" or event == "QUEST_DETAIL" then
        lastQuestFrameEvent = event
        UpdateQuestTranslationFrame()
    end
end)

local function SetQuestHoverScripts(frame, children)
    local frameName = frame:GetName()

    if frameName ~= "QuestLogListScrollFrame" and not string.find(frameName, "QuestLogItem") and not string.find(frameName, "QuestProgressItem") then
        frame:SetScript("OnEnter", function()
            UpdateQuestTranslationFrame()
            questTranslationFrame:Show()
        end)

        frame:SetScript("OnLeave", function()
            questTranslationFrame:Hide()
        end)

        if children then
            for i = 1, frame:GetNumChildren() do
                local child = select(i, frame:GetChildren())
                SetQuestHoverScripts(child, true)
            end
        end
    end
end

SetQuestHoverScripts(QuestLogFrame, true)
SetQuestHoverScripts(QuestFrame, false)

SetQuestHoverScripts(QuestProgressScrollFrame, true)
SetQuestHoverScripts(QuestDetailScrollFrame, true)
SetQuestHoverScripts(QuestRewardScrollFrame, true)

SetQuestHoverScripts(QuestFrameCompleteButton, true)
SetQuestHoverScripts(QuestFrameCompleteQuestButton, true)
SetQuestHoverScripts(QuestFrameGoodbyeButton, true)
SetQuestHoverScripts(QuestFrameCancelButton, true)
