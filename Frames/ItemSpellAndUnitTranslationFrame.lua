local translationTooltipFrame = CreateFrame("Frame", "TranslationTooltipFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
translationTooltipFrame:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
});
translationTooltipFrame:SetBackdropColor(0, 0, 0, 0.9);
translationTooltipFrame:SetParent(GameTooltip)
translationTooltipFrame:SetWidth(200)

local translationTooltipFrameHeader = translationTooltipFrame:CreateFontString("TranslationTooltipFrameHeader", "OVERLAY", "GameTooltipHeaderText")
translationTooltipFrameHeader:SetJustifyH("LEFT")