local questTranslationFrame = CreateFrame("Frame", "QuestTranslationFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
questTranslationFrame:SetWidth(QuestLogFrame:GetWidth())
questTranslationFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
questTranslationFrame:SetBackdropColor(0, 0, 0, 1)

local questTranslationFramePrimaryHeader = questTranslationFrame:CreateFontString("QuestTranslationFramePrimaryHeader", "OVERLAY", "GameFontHighlight")
questTranslationFramePrimaryHeader:SetTextScale(1.3)
questTranslationFramePrimaryHeader:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFramePrimaryHeader:SetJustifyH("LEFT")

local questTranslationFrameSecondaryHeader = questTranslationFrame:CreateFontString("QuestTranslationFrameSecondaryHeader", "OVERLAY", "GameFontHighlight")
questTranslationFrameSecondaryHeader:SetTextScale(1.3)
questTranslationFrameSecondaryHeader:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFrameSecondaryHeader:SetJustifyH("LEFT")

local questTranslationFramePrimaryText = questTranslationFrame:CreateFontString("QuestTranslationFramePrimaryText", "OVERLAY", "GameFontHighlight")
questTranslationFramePrimaryText:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFramePrimaryText:SetJustifyH("LEFT")

local questTranslationFrameSecondaryText = questTranslationFrame:CreateFontString("QuestTranslationFrameSecondaryText", "OVERLAY", "GameFontHighlight")
questTranslationFrameSecondaryText:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFrameSecondaryText:SetJustifyH("LEFT")

QuestTranslationFrame:RegisterEvent("QUEST_PROGRESS")
QuestTranslationFrame:RegisterEvent("QUEST_COMPLETE")
QuestTranslationFrame:RegisterEvent("QUEST_FINISHED")
QuestTranslationFrame:RegisterEvent("QUEST_DETAIL")
