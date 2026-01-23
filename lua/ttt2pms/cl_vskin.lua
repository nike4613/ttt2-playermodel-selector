local utilGetChangedColor
local vskinGetBackgroundColor

local drawRoundedBox
local drawRoundedBoxEx

local function GetBoxColor()
    return utilGetChangedColor(vskinGetBackgroundColor(), 20)
end

local function PaintPlyModelRow(skin, pnl, w, h)
    drawRoundedBox(4, 0, 0, w, h, GetBoxColor())
end

local function PaintPlyModelDropCell(skin, pnl, w, h)
    local colorBox = GetBoxColor()
    drawRoundedBox(4, 0, 0, w, h, colorBox)
    drawRoundedBox(2, 2, 2, w - 4, h - 4, vskinGetBackgroundColor())
end

local function UpdateDefaultSkin()
    print("TTT2PMS: Updating TTT default skin...")

    local skin = derma.GetNamedSkin("ttt2_default")

    local function SetFunc(name, func)
        skin[name] = func -- TODO: find a way to not override if something else (?) has overridden it itself
    end

    SetFunc("PaintPlyModelRow_TTT2PMS", PaintPlyModelRow)
    SetFunc("PaintPlyModelDropCell_TTT2PMS", PaintPlyModelDropCell)

    utilGetChangedColor = util.GetChangedColor
    vskinGetBackgroundColor = vskin.GetBackgroundColor

    drawRoundedBox = draw.RoundedBox
    drawRoundedBoxEx = draw.RoundedBoxEx
end

hook.Add("Initialize", "TTT2PMS_UpdateDefaultSkin", UpdateDefaultSkin)
hook.Add("OnReloaded", "TTT2PMS_UpdateDefaultSkin", UpdateDefaultSkin)

ttt2pms = ttt2pms or {}
ttt2pms.cl = ttt2pms.cl or {}

-- Clientside constants
ttt2pms.cl.plyModelRowHeight = 64
ttt2pms.cl.plyModelRowVPadding = 4
