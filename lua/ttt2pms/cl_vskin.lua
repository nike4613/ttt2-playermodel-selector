local utilGetChangedColor
local vskinGetBackgroundColor

local drawRoundedBox
local drawRoundedBoxEx

local function PaintPlyModelRow(skin, pnl, w, h)
    local colorBox = utilGetChangedColor(vskinGetBackgroundColor(), 20)

    drawRoundedBoxEx(4, 0, 0, w, h, colorBox)
    --    drawRoundedBox(4, 1, 1, w - 2, h - 2, colorBox)
end

local function UpdateDefaultSkin()
    print("TTT2PMS: Updating TTT default skin...")

    local skin = derma.GetNamedSkin("ttt2_default")

    local function SetFunc(name, func)
        skin[name] = func -- TODO: find a way to not override if something else (?) has overridden it itself
    end

    SetFunc("PaintPlyModelRow_TTT2PMS", PaintPlyModelRow)

    utilGetChangedColor = util.GetChangedColor
    vskinGetBackgroundColor = vskin.GetBackgroundColor

    drawRoundedBox = draw.RoundedBox
    drawRoundedBoxEx = draw.RoundedBoxEx
end

hook.Add("Initialize", "TTT2PMS_UpdateDefaultSkin", UpdateDefaultSkin)
hook.Add("OnReloaded", "TTT2PMS_UpdateDefaultSkin", UpdateDefaultSkin)
