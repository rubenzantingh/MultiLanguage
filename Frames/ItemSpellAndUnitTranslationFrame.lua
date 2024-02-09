local itemSpellAndUnitTranslationFrame = CreateFrame("Frame", "ItemSpellAndUnitTranslationFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
itemSpellAndUnitTranslationFrame:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
});
itemSpellAndUnitTranslationFrame:SetBackdropColor(0, 0, 0, 0.9);
itemSpellAndUnitTranslationFrame:SetParent(GameTooltip)
itemSpellAndUnitTranslationFrame:SetWidth(200)

local itemSpellAndUnitTranslationFrameHeader = itemSpellAndUnitTranslationFrame:CreateFontString("ItemSpellAndUnitTranslationFrameHeader", "OVERLAY", "GameFontHighlight")
itemSpellAndUnitTranslationFrameHeader:SetTextScale(1.175)
itemSpellAndUnitTranslationFrameHeader:SetJustifyH("LEFT")

local itemSpellAndUnitTranslationFrameText = itemSpellAndUnitTranslationFrame:CreateFontString("ItemSpellAndUnitTranslationFrameText", "OVERLAY", "GameFontHighlight")
itemSpellAndUnitTranslationFrameText:SetJustifyH("LEFT")