local utilGetChangedColor
local vskinGetBackgroundColor

local drawRoundedBox
local drawRoundedBoxEx

local surfaceSetMaterial = surface.SetMaterial
local surfaceSetDrawColor = surface.SetDrawColor
local surfaceDrawTexturedRect = surface.DrawTexturedRect
local mathMin = math.min

local matTrashIcon = Material("ttt2pms/trash-icon")

local function GetBoxColor()
    return utilGetChangedColor(vskinGetBackgroundColor(), 20)
end

local function PaintPlyModelRow(skin, pnl, w, h)
    drawRoundedBox(8, 0, 0, w, h, GetBoxColor())
end

local function PaintPlyModelDropCell(skin, pnl, w, h)
    local colorBox = GetBoxColor()
    drawRoundedBox(8, 0, 0, w, h, colorBox)
    drawRoundedBox(4, 4, 4, w - 8, h - 8, vskinGetBackgroundColor())
end

local function PaintDragParentTrashZone(skin, pnl, w, h)
    drawRoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 63))

    surfaceSetMaterial(matTrashIcon)
    surfaceSetDrawColor(GetBoxColor())

    -- compute correct sizing
    local minDim = mathMin(w, h)
    local targetSize = minDim - 2 * ttt2pms.cl.plyModelRowVPadding
    -- max size is texture size
    targetSize = mathMin(targetSize, matTrashIcon:GetTexture("$basetexture"):GetMappingHeight())

    local tx = (w - targetSize) / 2
    local ty = (h - targetSize) / 2

    surfaceDrawTexturedRect(tx, ty, targetSize, targetSize)
end

local function PaintDragList(skin, pnl, w, h) end

local function UpdateDefaultSkin()
    print("TTT2PMS: Updating TTT default skin...")

    local skin = derma.GetNamedSkin("ttt2_default")

    local function SetFunc(name, func)
        skin[name] = func -- TODO: find a way to not override if something else (?) has overridden it itself
    end

    SetFunc("PaintPlyModelRow_TTT2PMS", PaintPlyModelRow)
    SetFunc("PaintPlyModelDropCell_TTT2PMS", PaintPlyModelDropCell)
    SetFunc("PaintDragParentTrashZone_TTT2PMS", PaintDragParentTrashZone)
    SetFunc("PaintDragList_TTT2PMS", PaintDragList)

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
ttt2pms.cl.plyModelRowHeight = 96
ttt2pms.cl.plyModelRowVPadding = 8
