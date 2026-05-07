local Col2Vec = ttt2pms.util.Col2Vec

---
---@class DPlyModelRow_TTT2PMS : DPanelTTT2, DPanel, Panel
---@field package dragList? DDragList_TTT2PMS
---@field package dragListId? any
local DPlyModelRow_TTT2PMS = {}

function DPlyModelRow_TTT2PMS:Init()
    self.plymodel = nil
    self.userSettings = nil
    self.mdlDispColor = nil
    self.timerTime = 0

    local padding = ttt2pms.cl.plyModelRowVPadding
    self:DockPadding(padding, padding, padding, padding)

    ---@type DPanelTTT2
    local pnlBody = self:Add("DPanelTTT2")
    pnlBody:Dock(FILL)
    pnlBody:DockPadding(padding, 0, 0, 0)

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
    pnlModel:SetFOV(24)
    pnlModel:SetCamPos(Vector(0, 0, 0))
    pnlModel:SetDirectionalLight(BOX_RIGHT, Color(255, 160, 80, 255))
    pnlModel:SetDirectionalLight(BOX_LEFT, Color(80, 160, 255, 255))
    pnlModel:SetAmbientLight(Vector(-64, -64, -64))
    pnlModel:SetAnimated(true)
    pnlModel:SetLookAt(Vector(-100, 0, -11))

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

    local pnlDragArea = self:Add("DPanelTTT2")
    self.pnlDragArea = pnlDragArea
    pnlDragArea:Dock(RIGHT)
    pnlDragArea:SetZPos(0)
    pnlDragArea:SetVisible(false)
    function pnlDragArea:PerformLayout()
        self:SetWide(self:GetTall() * 2 / 3)
    end

    ---@param mouseCode MOUSE
    function pnlDragArea.OnMousePressed(_, mouseCode)
        if mouseCode ~= MOUSE_LEFT then
            return
        end
        if not self.dragList then
            return
        end
        -- mouse press on this region drags the item
        self.dragList:StartDrag(self.dragListId, mouseCode, true)
    end

    ---@param w number
    ---@param h number
    function pnlDragArea:Paint(w, h)
        -- TODO: better display for this
        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 127))
    end

    local pnlBtnArea = self:Add("DPanelTTT2")
    self.pnlBtnArea = pnlBtnArea
    pnlBtnArea:Dock(RIGHT)
    pnlBtnArea:SetZPos(1)
    pnlBtnArea:SetVisible(false)
    function pnlBtnArea:PerformLayout()
        local wide = self:GetTall() / 3
        self:SetWide(wide)

        local children = self:GetChildren()
        for i = 1, #children do
            local child = children[i]

            child:SetSize(wide, wide)
        end
    end

    -- TODO: these buttons currently look like ass. replace their paint with one that just draws an
    -- icon corresponding to the action
    local btnUp = pnlBtnArea:Add("DButtonTTT2")
    btnUp:Dock(TOP)
    btnUp:SetText("up")
    function btnUp.DoClick()
        if not self.dragList then
            return
        end
        self.dragList:MoveItemIdRelative(self.dragListId, -1)
    end
    local btnDn = pnlBtnArea:Add("DButtonTTT2")
    btnDn:Dock(BOTTOM)
    btnDn:SetText("down")
    function btnDn.DoClick()
        if not self.dragList then
            return
        end
        self.dragList:MoveItemIdRelative(self.dragListId, 1)
    end
    local btnDup = pnlBtnArea:Add("DButtonTTT2")
    btnDup:Dock(FILL)
    btnDup:SetText("dupe")
    function btnDup.DoClick()
        if not self.dragList then
            return
        end

        -- inject new item after self
        local newIdx = self.dragList:IndexOfId(self.dragListId)
        self.dragList:InsertItem(self:CreateDuplicateListValue(), newIdx + 1)
    end
end

---
---@param list DDragList_TTT2PMS?
---@param id any?
function DPlyModelRow_TTT2PMS:SetDragList(list, id)
    self.dragList = list
    if list == nil then
        id = nil
    end
    self.dragListId = id

    self.pnlDragArea:SetVisible(list ~= nil)
    self.pnlBtnArea:SetVisible(list ~= nil)
end

function DPlyModelRow_TTT2PMS:CreateDuplicateListValue()
    return table.Copy(self.plymodel)
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
---@param settings PlayermodelSettings
---@param serverColor? Color
function DPlyModelRow_TTT2PMS:SetUserSettings(settings, serverColor)
    self.userSettings = settings
    self.pnlModel:SetGlobalSettings(
        settings.defaultColorMode,
        settings.globalColor,
        serverColor or COLOR_WHITE
    )
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
