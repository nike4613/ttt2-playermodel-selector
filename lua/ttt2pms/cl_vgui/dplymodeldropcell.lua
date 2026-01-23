---@class DPlyModelDropCell_TTT2PMS : DPanelTTT2
local DPlyModelDropCell_TTT2PMS = {}

function DPlyModelDropCell_TTT2PMS:Init() end

function DPlyModelDropCell_TTT2PMS:PerformLayout()
    --self:SizeToChildren(false, true)

    local height = ttt2pms.cl.plyModelRowHeight + ttt2pms.cl.plyModelRowVPadding * 2
    self:SetTall(height)
end

function DPlyModelDropCell_TTT2PMS:Paint(w, h)
    derma.SkinHook("Paint", "PlyModelDropCell_TTT2PMS", self, w, h)
end

derma.DefineControl(
    "DPlyModelDropCell_TTT2PMS",
    "a plymodelrow drop cell (the outline)",
    DPlyModelDropCell_TTT2PMS,
    "DPanelTTT2"
)
