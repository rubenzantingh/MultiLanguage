local itemSpellAndUnitTranslationFrame = CreateFrame("Frame", "ItemSpellAndUnitTranslationFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
itemSpellAndUnitTranslationFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
itemSpellAndUnitTranslationFrame:SetBackdropColor(0, 0, 0, 1)
itemSpellAndUnitTranslationFrame:SetParent(GameTooltip)
itemSpellAndUnitTranslationFrame:SetWidth(200)

local itemSpellAndUnitTranslationFrameHeader = itemSpellAndUnitTranslationFrame:CreateFontString("ItemSpellAndUnitTranslationFrameHeader", "OVERLAY", "GameFontHighlight")
itemSpellAndUnitTranslationFrameHeader:SetTextScale(1.15)
itemSpellAndUnitTranslationFrameHeader:SetJustifyH("LEFT")

local itemSpellAndUnitTranslationFrameText = itemSpellAndUnitTranslationFrame:CreateFontString("ItemSpellAndUnitTranslationFrameText", "OVERLAY", "GameFontHighlight")
itemSpellAndUnitTranslationFrameText:SetWidth(itemSpellAndUnitTranslationFrame:GetWidth() - 20)
itemSpellAndUnitTranslationFrameText:SetJustifyH("LEFT")