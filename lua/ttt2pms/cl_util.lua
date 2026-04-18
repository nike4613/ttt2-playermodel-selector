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

---Gets a concrete bodygroup value given some BodygroupSettings, and a maximum bodygroup value.
---@param bgrp number|BodygroupSettings the bodygroup setting to use
---@param max number the maximum value of the bodygroup
---@return number value the concrete bodygroup value
function ttt2pms.cl.GetBodygroupValue(bgrp, max)
    if type(bgrp) == "number" then
        return bgrp
    end

    if not bgrp.random then
        return bgrp.value
    end

    return math.random(0, max)
end
