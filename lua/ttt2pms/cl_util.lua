ttt2pms = ttt2pms or {}
ttt2pms.cl = ttt2pms.cl or {}

---
---@param parent Panel
---@return DSizeToContents
function ttt2pms.cl.MakePaddedSizeToContents(parent)
    local panel = vgui.Create("DSizeToContents", parent)

    panel:SetSizeX(false)
    panel:Dock(TOP)
    panel:DockPadding(10, 10, 10, 0)
    panel:InvalidateLayout()

    return panel
end
