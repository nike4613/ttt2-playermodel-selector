---
---@class DPlyModelRow_TTT2PMS : DPanel, Panel
local DPlyModelRow_TTT2PMS = {}

function DPlyModelRow_TTT2PMS:Init()
    self.mdlPath = nil
    self.mdlName = nil
    self.mdlSkin = nil
    self.mdlBodygroups = nil
    self.mdlPlyColor = COLOR_WHITE

    self:DockPadding(4, 4, 4, 4)

    local pnlBody = self:Add("DPanelTTT2")
    pnlBody:Dock(FILL)
    pnlBody:DockPadding(4, 0, 0, 0)

    local modelName = pnlBody:Add("DLabelTTT2")
    self.pnlName = modelName
    modelName:Dock(TOP)
    modelName:SetZPos(0)
    modelName:SetFont("DermaTTT2Title")

    local modelPath = pnlBody:Add("DLabelTTT2")
    self.pnlPath = modelPath
    modelPath:Dock(TOP)
    modelPath:SetZPos(1)

    -- TODO: display bodygroups here?

    ---@class DModelPanel
    ---@field Entity Entity
    local pnlModel = self:Add("DModelPanel")
    self.pnlModel = pnlModel
    pnlModel:Dock(LEFT)
    pnlModel:SetWide(64)
    pnlModel:SetTall(64)
    pnlModel:SetFOV(36)
    pnlModel:SetCamPos(Vector(0, 0, 0))
    pnlModel:SetDirectionalLight(BOX_RIGHT, Color(255, 160, 80, 255))
    pnlModel:SetDirectionalLight(BOX_LEFT, Color(80, 160, 255, 255))
    pnlModel:SetAmbientLight(Vector(-64, -64, -64))
    pnlModel:SetAnimated(true)
    pnlModel:SetLookAt(Vector(-100, 0, -22))

    --pnlModel.Angles = Angle(0, 0, 0)
    --pnlModel.Pos = Vector(-100, 0, -61)
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

function DPlyModelRow_TTT2PMS:PerformLayout()
    self:SetTall(64)

    self.pnlName:SetText(self.mdlName)
    self.pnlPath:SetText(self.mdlPath)

    self.pnlModel:SetModel(self.mdlPath)
    self.pnlModel.Entity:SetPos(Vector(-100, 0, -61))
    ---@diagnostic disable-next-line
    self.pnlModel.Entity.GetPlayerColor = function()
        return self.mdlPlyColor
    end

    self.pnlModel.Entity:SetSkin(self.mdlSkin)
    for i = 0, self.pnlModel.Entity:GetNumBodyGroups() - 1 do
        self.pnlModel.Entity:SetBodygroup(i, self.mdlBodygroups[i] or 0)
    end
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
