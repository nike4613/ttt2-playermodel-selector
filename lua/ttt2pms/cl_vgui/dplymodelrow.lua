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
    self.timerTime = 0

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
---@return number|BodygroupSettings skinId
---@return table<number,number|BodygroupSettings> bodygroups
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
---@param skin number|BodygroupSettings
---@param bodygroups table<number,number|BodygroupSettings>
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

---@param bgrp number|BodygroupSettings
---@return number
local function GetBodygroupImmediateVal(bgrp, max)
    if type(bgrp) == "number" then
        return bgrp
    end

    if not bgrp.random then
        return bgrp.value
    end

    return math.random(0, max)
end

local function UpdateBodygroups(self)
    if not self.mdlSkin or not self.mdlBodygroups then
        return
    end

    self.pnlModel.Entity:SetSkin(
        GetBodygroupImmediateVal(self.mdlSkin, self.pnlModel.Entity:SkinCount())
    )
    for i = 0, self.pnlModel.Entity:GetNumBodyGroups() - 1 do
        local bgrp = self.mdlBodygroups[i]
        if not bgrp then
            self.pnlModel.Entity:SetBodygroup(i, 0)
        else
            self.pnlModel.Entity:SetBodygroup(
                i,
                GetBodygroupImmediateVal(bgrp, self.pnlModel.Entity:GetBodygroupCount(i))
            )
        end
    end
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

    UpdateBodygroups(self)

    local bodygroupStr = GetBodygroupStr(self.mdlSkin)
    for i = 0, self.pnlModel.Entity:GetNumBodyGroups() - 1 do
        if self.pnlModel.Entity:GetBodygroupCount(i) <= 1 then
            -- don't show any bodygroups with only one variant
            continue
        end

        local bgrp = self.mdlBodygroups[i]
        bodygroupStr = bodygroupStr .. "/" .. GetBodygroupStr(bgrp)
    end

    self.pnlBodygroups:SetText(bodygroupStr)

    self:SizeToChildren(false, true)
end

function DPlyModelRow_TTT2PMS:Paint(w, h)
    derma.SkinHook("Paint", "PlyModelRow_TTT2PMS", self, w, h)

    if UnPredictedCurTime() - self.timerTime >= 0.5 then
        self.timerTime = UnPredictedCurTime()
        UpdateBodygroups(self)
    end
end

derma.DefineControl(
    "DPlyModelRow_TTT2PMS",
    "a playermodel row entry",
    DPlyModelRow_TTT2PMS,
    "DPanelTTT2"
)
