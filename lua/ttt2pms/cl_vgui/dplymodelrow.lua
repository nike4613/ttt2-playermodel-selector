local Col2Vec = ttt2pms.util.Col2Vec

---
---@class DPlyModelRow_TTT2PMS : DPanel, Panel
local DPlyModelRow_TTT2PMS = {}

function DPlyModelRow_TTT2PMS:Init()
    self.mdlPath = nil
    self.mdlName = nil
    self.mdlSkin = nil
    self.mdlBodygroups = nil
    self.mdlPlyColor = COLOR_WHITE
    self.mdlDispColor = color_transparent

    self:DockPadding(4, 4, 4, 4)

    ---@class DPanelTTT2 : DPanel, Panel

    ---@type DPanelTTT2
    local pnlBody = self:Add("DPanelTTT2")
    pnlBody:Dock(FILL)
    pnlBody:DockPadding(4, 0, 0, 0)

    ---@class DLabelTTT2 : DLabel
    local modelName = pnlBody:Add("DLabelTTT2")
    self.pnlName = modelName
    modelName:Dock(TOP)
    modelName:SetZPos(0)
    modelName:SetFont("DermaTTT2Title")

    local modelPath = pnlBody:Add("DLabelTTT2")
    self.pnlPath = modelPath
    modelPath:Dock(TOP)
    modelPath:SetZPos(1)

    local modelBodygroups = pnlBody:Add("DLabelTTT2")
    self.pnlBodygroups = modelBodygroups
    modelBodygroups:Dock(TOP)
    modelBodygroups:SetZPos(2)

    ---@class DModelPanel
    ---@field Entity Entity
    local pnlModel = self:Add("DModelPanel")
    self.pnlModel = pnlModel
    pnlModel:Dock(LEFT)
    pnlModel:SetZPos(0)
    pnlModel:SetFOV(36)
    pnlModel:SetCamPos(Vector(0, 0, 0))
    pnlModel:SetDirectionalLight(BOX_RIGHT, Color(255, 160, 80, 255))
    pnlModel:SetDirectionalLight(BOX_LEFT, Color(80, 160, 255, 255))
    pnlModel:SetAmbientLight(Vector(-64, -64, -64))
    pnlModel:SetAnimated(true)
    pnlModel:SetLookAt(Vector(-100, 0, -22))

    --pnlModel.Angles = Angle(0, 0, 0)
    --pnlModel.Pos = Vector(-100, 0, -61)

    ---@type DPanelTTT2
    local pnlColorDispArea = self:Add("DPanelTTT2")
    self.pnlColorDisplayArea = pnlColorDispArea
    pnlColorDispArea:Dock(LEFT)
    pnlColorDispArea:SetZPos(1)

    local pnlColDisp = vgui.Create("DColorButton", pnlColorDispArea)
    self.pnlColorDisplayInner = pnlColDisp
    pnlColDisp:SetPos(-100000, -100000)
    pnlColDisp:SetSize(0, 0)
end

---
---@return string|nil
function DPlyModelRow_TTT2PMS:GetModel()
    return self.mdlPath
end

---
---@return number skinId
---@return table<number,number> bodygroups
function DPlyModelRow_TTT2PMS:GetBodygroups()
    return self.mdlSkin, self.mdlBodygroups
end

---
---@param mdl string The model path to display
function DPlyModelRow_TTT2PMS:SetModel(mdl)
    self.mdlPath = mdl
    self.mdlName = player_manager.TranslateToPlayerModelName(mdl)
    self.mdlSkin = 0
    self.mdlBodygroups = {}
    self:InvalidateLayout()
end

---
---@param skin number
---@param bodygroups table<number,number>
function DPlyModelRow_TTT2PMS:SetBodygroups(skin, bodygroups)
    self.mdlSkin = skin
    self.mdlBodygroups = table.Copy(bodygroups)
    self:InvalidateLayout()
end

---
---@param color Color
function DPlyModelRow_TTT2PMS:SetPlayerColor(color)
    self.mdlPlyColor = color
    self:InvalidateLayout()
end

---
---@param color Color|nil
function DPlyModelRow_TTT2PMS:SetDisplayColor(color)
    self.mdlDispColor = color
    self:InvalidateLayout()
end

function DPlyModelRow_TTT2PMS:PerformLayout()
    --self:SetTall(64)
    self.pnlModel:SetWide(ttt2pms.cl.plyModelRowHeight)
    self.pnlModel:SetTall(ttt2pms.cl.plyModelRowHeight)

    self.pnlColorDisplayArea:SetWide(ttt2pms.cl.plyModelRowHeight / 2)
    self.pnlColorDisplayArea:SetTall(ttt2pms.cl.plyModelRowHeight)

    self.pnlName:SetText(self.mdlName)
    self.pnlPath:SetText(self.mdlPath)

    self.pnlModel:SetModel(self.mdlPath)
    self.pnlModel.Entity:SetPos(Vector(-100, 0, -61))
    ---@diagnostic disable-next-line
    self.pnlModel.Entity.GetPlayerColor = function()
        return Col2Vec(self.mdlPlyColor)
    end

    if self.mdlDispColor then
        --       self.pnlColorDisplayInner:SetParent(self.pnlColorDisplayArea)
        self.pnlColorDisplayInner:Dock(FILL)
        self.pnlColorDisplayInner:SetColor(self.mdlDispColor, true)
        self.pnlColorDisplayInner:SetTooltip(nil)
    else
        --        self.pnlColorDisplayInner:SetParent(nil)
        self.pnlColorDisplayInner:SetSize(0, 0)
        self.pnlColorDisplayInner:SetPos(-100000, -100000)
    end

    self.pnlModel.Entity:SetSkin(self.mdlSkin)
    ttt2pms.util.ReplaceBodygroupTbl(self.pnlModel.Entity, self.mdlBodygroups)

    local bodygroupStr = tostring(self.mdlSkin)
    for i = 0, self.pnlModel.Entity:GetNumBodyGroups() - 1 do
        if self.pnlModel.Entity:GetBodygroupCount(i) <= 1 then
            -- don't show any bodygroups with only one variant
            continue
        end
        bodygroupStr = bodygroupStr .. "/" .. tostring(self.pnlModel.Entity:GetBodygroup(i))
    end

    self.pnlBodygroups:SetText(bodygroupStr)

    self:SizeToChildren(false, true)
end

function DPlyModelRow_TTT2PMS:Paint(w, h)
    derma.SkinHook("Paint", "PlyModelRow_TTT2PMS", self, w, h)
end

derma.DefineControl(
    "DPlyModelRow_TTT2PMS",
    "a playermodel row entry",
    DPlyModelRow_TTT2PMS,
    "DPanelTTT2"
)
