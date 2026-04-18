local Col2Vec = ttt2pms.util.Col2Vec

---
---@class DPlyModelRow_TTT2PMS : DPanel, Panel
local DPlyModelRow_TTT2PMS = {}

function DPlyModelRow_TTT2PMS:Init()
    self.plymodel = nil
    self.mdlDispColor = nil
    self.timerTime = 0

    local padding = ttt2pms.cl.plyModelRowVPadding
    self:DockPadding(padding, padding, padding, padding)

    ---@class DPanelTTT2 : DPanel, Panel

    ---@type DPanelTTT2
    local pnlBody = self:Add("DPanelTTT2")
    pnlBody:Dock(FILL)
    pnlBody:DockPadding(padding, 0, 0, 0)

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

    local pnlModel = self:Add("DModelPanel_TTT2PMS")
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
---@return Playermodel?
function DPlyModelRow_TTT2PMS:GetPlayerModel()
    return self.plymodel
end

---
---@param mdl Playermodel The model to display
function DPlyModelRow_TTT2PMS:SetPlayerModel(mdl)
    self.plymodel = mdl
    self.pnlModel:SetPlayermodel(mdl)

    if mdl.colorMode == PLAYERMODEL_COLOR_MODE.MODEL then
        self:SetDisplayColor(mdl.color)
    end

    self:InvalidateLayout()
end

---
---@param color Color
function DPlyModelRow_TTT2PMS:SetPlayerColor(color)
    self.pnlModel:SetPlayerColor(color)
end

---
---@param color Color|nil
function DPlyModelRow_TTT2PMS:SetDisplayColor(color)
    self.mdlDispColor = color
    self:InvalidateLayout()
end

function DPlyModelRow_TTT2PMS:PerformLayout()
    local height = ttt2pms.cl.plyModelRowHeight
    self.pnlModel:SetWide(height)
    self.pnlModel:SetTall(height)

    self.pnlColorDisplayArea:SetWide(height / 2)
    self.pnlColorDisplayArea:SetTall(height)

    self.pnlName:SetText(self.plymodel.model)
    self.pnlPath:SetText(player_manager.TranslatePlayerModel(self.plymodel.model))

    self.pnlModel.Entity:SetPos(Vector(-100, 0, -61))

    if self.mdlDispColor then
        self.pnlColorDisplayInner:SetVisible(true)
        self.pnlColorDisplayInner:Dock(FILL)
        self.pnlColorDisplayInner:SetColor(self.mdlDispColor, true)
        self.pnlColorDisplayInner:SetTooltip(nil)
    else
        self.pnlColorDisplayInner:SetSize(0, 0)
        self.pnlColorDisplayInner:SetVisible(false)
    end

    ---@param bgrp number|BodygroupSettings
    ---@return string
    local function GetBodygroupStr(bgrp)
        if type(bgrp) == "table" then
            if bgrp.random then
                return "?"
            else
                return tostring(bgrp.value)
            end
        else
            return tostring(bgrp)
        end
    end

    local bodygroupStr = GetBodygroupStr(self.plymodel.skin)
    for i = 0, self.pnlModel.Entity:GetNumBodyGroups() - 1 do
        if self.pnlModel.Entity:GetBodygroupCount(i) <= 1 then
            -- don't show any bodygroups with only one variant
            continue
        end

        local bgrp = self.plymodel.bodygroups[i]
        bodygroupStr = bodygroupStr .. "/" .. GetBodygroupStr(bgrp or 0)
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
