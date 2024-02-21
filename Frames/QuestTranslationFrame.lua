local questTranslationFrame = CreateFrame("Frame", "QuestTranslationFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
questTranslationFrame:SetWidth(QuestLogFrame:GetWidth())
questTranslationFrame:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
questTranslationFrame:SetBackdropColor(0, 0, 0, 0.9)

local questTranslationFramePrimaryHeader = questTranslationFrame:CreateFontString("QuestTranslationFramePrimaryHeader", "OVERLAY", "QuestTitleFont")
questTranslationFramePrimaryHeader:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFramePrimaryHeader:SetJustifyH("LEFT")
questTranslationFramePrimaryHeader:SetTextColor(1, 1, 1, 1)

local questTranslationFrameSecondaryHeader = questTranslationFrame:CreateFontString("QuestTranslationFrameSecondaryHeader", "OVERLAY", "QuestTitleFont")
questTranslationFrameSecondaryHeader:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFrameSecondaryHeader:SetJustifyH("LEFT")
questTranslationFrameSecondaryHeader:SetTextColor(1, 1, 1, 1)

local questTranslationFramePrimaryText = questTranslationFrame:CreateFontString("QuestTranslationFramePrimaryText", "OVERLAY", "QuestFont")
questTranslationFramePrimaryText:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFramePrimaryText:SetJustifyH("LEFT")
questTranslationFramePrimaryText:SetTextColor(1, 1, 1, 1)

local questTranslationFrameSecondaryText = questTranslationFrame:CreateFontString("QuestTranslationFrameSecondaryText", "OVERLAY", "QuestFont")
questTranslationFrameSecondaryText:SetWidth(questTranslationFrame:GetWidth() - 20)
questTranslationFrameSecondaryText:SetJustifyH("LEFT")
questTranslationFrameSecondaryText:SetTextColor(1, 1, 1, 1)

QuestTranslationFrame:RegisterEvent("QUEST_PROGRESS")
QuestTranslationFrame:RegisterEvent("QUEST_COMPLETE")
QuestTranslationFrame:RegisterEvent("QUEST_FINISHED")
QuestTranslationFrame:RegisterEvent("QUEST_DETAIL")
