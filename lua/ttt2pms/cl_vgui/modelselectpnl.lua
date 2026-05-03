ttt2pms = ttt2pms or {}
ttt2pms.cl = ttt2pms.cl or {}

---@class ModelSelectorPanel_TTT2PMS : DPanelTTT2, DPanel
---
---@field private pnlModel DModelPanel_TTT2PMS
---@field private pnlFormContainer DScrollPanelTTT2
---@field private pnlFormColor DFormTTT2
---@field private pnlCmbColorMode DComboBoxTTT2
---@field private pnlFormBodygroups DFormTTT2
---@field private pnlIconLayout DIconLayout
---
---@field OnChanged? fun(plymodel: Playermodel)
---
---@field private modelDirty boolean
---@field private plymodel Playermodel
---@field private plymodelSettings PlayermodelSettings
---@field private serverColor Color
---
---@field private bodygroupsFormItems table
---
local ModelSelectorPanel_TTT2PMS = {}

local materialReset = Material("vgui/ttt/vskin/icon_reset")

function ModelSelectorPanel_TTT2PMS:Init()
    local TryT = LANG.TryTranslation

    self.serverColor = COLOR_WHITE
    self.modelDirty = false

    local padding = ttt2pms.cl.plyModelRowVPadding

    -- upper panel
    local upper = self:Add("DPanelTTT2")
    upper:Dock(TOP)
    upper:SetTall(512)

    ---@type DModelPanel_TTT2PMS
    local modelDisplay = upper:Add("DModelPanel_TTT2PMS")
    self.pnlModel = modelDisplay
    modelDisplay:SetWide(512 * 2 / 3)
    modelDisplay:Dock(LEFT)
    modelDisplay:SetAnimated(true)
    modelDisplay:SetCamPos(Vector(0, 0, 0))
    modelDisplay:SetFOV(36)
    modelDisplay:SetAmbientLight(Vector(-64, -64, -64))
    modelDisplay:SetLookAt(Vector(-100, 0, -22))
    modelDisplay:SetDirectionalLight(BOX_RIGHT, Color(255, 160, 80, 255))
    modelDisplay:SetDirectionalLight(BOX_LEFT, Color(255, 160, 80, 255))

    local mdlDrag = {
        DefaultPos = function(slf)
            slf.Angles = Angle(0, 0, 0)
            slf.Pos = Vector(-100, 0, -61)
        end,
    }
    mdlDrag:DefaultPos()

    function modelDisplay:DragMousePress(btn)
        mdlDrag.px, mdlDrag.py = input.GetCursorPos()
        mdlDrag.pressed = btn
    end
    function modelDisplay:DragMouseRelease(btn)
        mdlDrag.pressed = false
    end
    function modelDisplay:OnMouseWheeled(delta)
        mdlDrag.wheel = delta * -10
        mdlDrag.wheeled = true
    end

    function modelDisplay:LayoutEntity(ent)
        -- this logic is in the base LayoutEntity
        if self.bAnimated then
            self:RunAnimation()
        end

        if mdlDrag.pressed == MOUSE_LEFT then
            local mx, my = input.GetCursorPos()
            mdlDrag.Angles = mdlDrag.Angles - Angle(0, (mdlDrag.px or mx) - mx, 0)
            mdlDrag.px, mdlDrag.py = input.GetCursorPos()
        end
        if mdlDrag.pressed == MOUSE_RIGHT then
            local mx, my = input.GetCursorPos()
            mdlDrag.Angles = mdlDrag.Angles
                - Angle(
                    (mdlDrag.py * 0.5 or my * 0.5) - my * 0.5,
                    0,
                    (mdlDrag.px * -0.5 or mx * -0.5) - mx * -0.5
                )

            mdlDrag.px, mdlDrag.py = input.GetCursorPos()
        end

        if mdlDrag.pressed == MOUSE_MIDDLE then
            local mx, my = input.GetCursorPos()
            mdlDrag.Pos = mdlDrag.Pos
                - Vector(
                    0,
                    (mdlDrag.px * 0.5 or mx * 0.5) - mx * 0.5,
                    (mdlDrag.py * -0.5 or my * -0.5) - my * -0.5
                )

            mdlDrag.px, mdlDrag.py = input.GetCursorPos()
        end

        if mdlDrag.wheeled then
            mdlDrag.wheeled = false
            mdlDrag.Pos = mdlDrag.Pos - Vector(mdlDrag.wheel, 0, 0)
        end

        ent:SetAngles(mdlDrag.Angles)
        ent:SetPos(mdlDrag.Pos)
    end

    -- add a reset button over the model panel in the bottom right
    local btnResetMdlPos = vgui.Create("DButtonTTT2", upper)
    btnResetMdlPos:SetText("ttt2pms_select_model_reset_model")
    btnResetMdlPos:SetIcon(materialReset, true, 16)
    btnResetMdlPos:SetSize(96, 32)
    btnResetMdlPos.DoClick = function()
        mdlDrag:DefaultPos()
    end
    self.btnResetMdlPos = btnResetMdlPos

    local bodygroupsContent = upper:Add("DContentPanelTTT2")
    bodygroupsContent:Dock(FILL)
    local bodygroupsScroll = bodygroupsContent:Add("DScrollPanelTTT2")
    self.pnlFormContainer = bodygroupsScroll
    bodygroupsScroll:Dock(FILL) -- fill remaining space in container

    local colorForm = vgui.CreateTTT2Form(bodygroupsScroll, "ttt2pms_select_model_color_header")
    colorForm:SetLabelWidth(150)
    self.pnlFormColor = colorForm
    colorForm:Dock(TOP)

    self.pnlCmbColorMode = colorForm:MakeComboBox({
        label = "ttt2pms_select_model_color_mode_label",
        default = -1,
        choices = {
            {
                title = TryT("ttt2pms_select_model_color_mode_opt_default"),
                value = -1,
            },
            {
                title = TryT("ttt2pms_select_model_color_mode_opt_server"),
                value = PLAYERMODEL_COLOR_MODE.SERVER,
            },
            {
                title = TryT("ttt2pms_select_model_color_mode_opt_user"),
                value = PLAYERMODEL_COLOR_MODE.USER_GLOBAL,
            },
            {
                title = TryT("ttt2pms_select_model_color_mode_opt_model"),
                value = PLAYERMODEL_COLOR_MODE.MODEL,
            },
            {
                title = TryT("ttt2pms_select_model_color_mode_opt_random"),
                value = PLAYERMODEL_COLOR_MODE.RANDOM,
            },
        },
        OnChange = function(value)
            local isNil = value == -1
            if not isNil then
                self.plymodel.colorMode = tonumber(value)
            else
                self.plymodel.colorMode = nil
            end

            self.pnlColorSelector:SetVisible(
                (
                    self.plymodel.colorMode
                    or (self.plymodelSettings and self.plymodelSettings.defaultColorMode)
                ) == PLAYERMODEL_COLOR_MODE.MODEL
            )

            self.pnlModel:UpdateBodygroups()
            self.pnlColorSelector:GetParent():InvalidateLayout(false)

            if self.OnChanged then
                self.OnChanged(table.Copy(self.plymodel))
            end
        end,
    })

    self.pnlColorSelector = vgui.Create("DColorMixer", self)
    self.pnlColorSelector:SetPalette(true)
    self.pnlColorSelector:SetAlphaBar(false)
    self.pnlColorSelector:SetWangs(true)
    ---@diagnostic disable-next-line
    self.pnlColorSelector.ValueChanged = function(_, color)
        self.plymodel.color = color
        self.pnlModel:UpdateBodygroups()
    end

    colorForm:AddItem(self.pnlColorSelector)

    local bodygroupsForm =
        vgui.CreateTTT2Form(bodygroupsScroll, "ttt2pms_select_model_bodygroups_header")
    bodygroupsForm:SetLabelWidth(150)
    self.pnlFormBodygroups = bodygroupsForm
    bodygroupsForm:Dock(TOP)

    self.bodygroupsFormItems = {
        ---@type table<DNumberWangTTT2>
        bodygroups = {},
    }

    -- first, the skin item. this will always be present.
    local skinWang = self:_MakeWangForBodygroup(
        bodygroupsForm,
        { random = false, value = 0 },
        "ttt2pms_select_model_bodygroup_skin_label"
    )
    self.bodygroupsFormItems.skin = skinWang
    skinWang:GetParent():SetVisible(false)

    -- lower panel
    local lower = self:Add("DPanelTTT2")
    lower:Dock(TOP) -- fill remaining space in container

    local searchBar = lower:Add("DTextEntryTTT2")
    self.pnlSearchBar = searchBar
    searchBar:Dock(TOP)
    searchBar:SetDefaultValue(LANG.GetTranslation("ttt2pms_select_model_search"))

    ---@type DIconLayout
    local modelsIconLayout = lower:Add("DIconLayout")
    self.pnlIconLayout = modelsIconLayout
    modelsIconLayout:Dock(FILL)
    modelsIconLayout:SetSpaceX(padding)
    modelsIconLayout:SetSpaceY(padding)
    modelsIconLayout:SetStretchHeight(true)
    modelsIconLayout:SetStretchWidth(false)
    modelsIconLayout:SetLayoutDir(LEFT)
end

---@class DTextEntryTTT2 : DTextEntry, DPanelTTT2
---@class DNumberWangTTT2 : DNumberWang, DTextEntryTTT2

---@param form DFormTTT2
---@param bgrp BodygroupSettings
---@param label string
---@return DNumberWangTTT2
function ModelSelectorPanel_TTT2PMS:_MakeWangForBodygroup(form, bgrp, label)
    ---@type DNumberWangTTT2
    local wang
    wang = form:MakeNumberWang({
        label = label,
        default = 0,
        OnChange = function(_, value)
            wang.bgrp.value = value
            self.pnlModel:UpdateBodygroups()
        end,
        initial = bgrp.value,
        enableToggle = true,
        -- TODO: toggleIconMaterial = { materialNotRandom, materialRandom }
        toggleInitialState = bgrp.random and 2 or 1,
        OnClickToggle = function(_, state)
            local rand = state == 2
            wang:SetEnabled(not rand)
            wang:InvalidateLayout(false)
            wang.bgrp.random = rand
            self.pnlModel:UpdateBodygroups()
        end,
    })
    wang.bgrp = bgrp
    wang:SetEnabled(not bgrp.random)

    return wang
end

function ModelSelectorPanel_TTT2PMS:PerformLayout()
    if self.modelDirty then
        print("selector panel modelDirty")
        PrintTable({ self.plymodel })
        self.pnlModel:SetPlayermodel(self.plymodel)
        self.pnlCmbColorMode:ChooseOptionValue(self.plymodel.colorMode or -1)
        self.pnlColorSelector:SetColor(self.plymodel.color)

        local visibleRowCt = 0

        local skins = self.pnlModel.Entity:SkinCount()
        if skins > 1 then
            visibleRowCt = 1
            self.bodygroupsFormItems.skin:GetParent():SetVisible(true)
            self.bodygroupsFormItems.skin.bgrp = self.plymodel.skin
            self.bodygroupsFormItems.skin.toggleBtn.state = self.plymodel.skin.random and 2 or 1
            self.bodygroupsFormItems.skin:SetMinMax(0, skins - 1)
            self.bodygroupsFormItems.skin:SetValue(self.plymodel.skin.value)
            self.bodygroupsFormItems.skin:SetEnabled(not self.plymodel.skin.random)
        else
            self.bodygroupsFormItems.skin:GetParent():SetVisible(false)
            self.bodygroupsFormItems.skin.bgrp = { random = false, value = 0 }
        end

        -- clear the existing bodygroups
        for i = 1, #self.bodygroupsFormItems.bodygroups do
            self.bodygroupsFormItems.bodygroups[i]:GetParent():Remove()
        end

        -- initialize the new ones
        local bgrpTbl = {}
        self.bodygroupsFormItems.bodygroups = bgrpTbl

        for i = 0, self.pnlModel.Entity:GetNumBodyGroups() - 1 do
            local ct = self.pnlModel.Entity:GetBodygroupCount(i)

            if ct > 1 then
                visibleRowCt = visibleRowCt + 1

                local bgrp = self.plymodel.bodygroups[i] or { random = false, value = 0 }
                self.plymodel.bodygroups[i] = bgrp
                bgrp.random = tobool(bgrp or false)
                bgrp.value = tonumber(bgrp.value) or 0

                local wang = self:_MakeWangForBodygroup(
                    self.pnlFormBodygroups,
                    bgrp,
                    self.pnlModel.Entity:GetBodygroupName(i)
                )
                wang:SetMinMax(0, ct - 1)

                bgrpTbl[#bgrpTbl + 1] = wang
            end
        end

        self.pnlFormBodygroups:InvalidateLayout(true)
        self.pnlFormBodygroups:SetVisible(visibleRowCt ~= 0)
    end
    self.modelDirty = false

    self.btnResetMdlPos:SetPos(
        self.pnlModel:GetWide() - self.btnResetMdlPos:GetWide(),
        self.pnlModel:GetTall() - self.btnResetMdlPos:GetTall()
    )
    self:SizeToChildren(false, true)
end

---comment
---@param userSettings  PlayermodelSettings
function ModelSelectorPanel_TTT2PMS:SetUserSettings(userSettings)
    self.plymodelSettings = userSettings
    self.pnlModel:SetGlobalSettings(
        self.plymodelSettings.defaultColorMode,
        self.plymodelSettings.globalColor,
        self.serverColor
    )
    self:InvalidateLayout(false)
end

---comment
---@param col Color
function ModelSelectorPanel_TTT2PMS:SetServerColor(col)
    self.serverColor = col
    self:InvalidateLayout(false)
end

---comment
---@param model Playermodel
function ModelSelectorPanel_TTT2PMS:SetPlayerModel(model)
    self.plymodel = table.Copy(model)
    self.plymodel.skin.random = tobool(self.plymodel.skin.random or false)
    self.plymodel.skin.value = tonumber(self.plymodel.skin.value) or 0
    self.modelDirty = true
    self:InvalidateLayout(false)
end

---comment
---@return Playermodel
function ModelSelectorPanel_TTT2PMS:GetPlayerModel()
    return table.Copy(self.plymodel)
end

derma.DefineControl(
    "ModelSelectorPanel_TTT2PMS",
    "a playermodel selection panel",
    ModelSelectorPanel_TTT2PMS,
    "DPanelTTT2"
)

---@class ModelSelectorPanelOptions
---@field initialModel Playermodel
---@field userSettings PlayermodelSettings
---@field serverColor Color

---@class DFrameTTT2 : DFrame

---
---@param options ModelSelectorPanelOptions
---@return DFrameTTT2
function ttt2pms.cl.ShowModelSelectPopup(options)
    ---@type DFrameTTT2
    local frame = vguihandler.GenerateFrame(512 * 4 / 3, 900, "ttt2pms_select_model_title")

    local padding = ttt2pms.cl.plyModelRowVPadding

    frame:SetPadding(padding, padding, padding, padding)

    frame:SetDraggable(true)
    frame:SetScreenLock(true)
    frame:SetDeleteOnClose(true)
    frame:SetPaintShadow(true)

    frame:SetSizable(true)
    frame:SetMinWidth(512)
    frame:SetMinHeight(512)

    frame:ShowCloseButton(true)
    frame:ShowBackButton(false)

    frame:Center()
    frame:MakePopup()

    local scroll = frame:Add("DScrollPanelTTT2")
    scroll:Dock(FILL) -- fill remaining space in container

    ---@type ModelSelectorPanel_TTT2PMS
    local selectorPanel = scroll:Add("ModelSelectorPanel_TTT2PMS")
    selectorPanel:Dock(TOP)

    selectorPanel:SetUserSettings(options.userSettings)
    selectorPanel:SetServerColor(options.serverColor)
    selectorPanel:SetPlayerModel(table.Copy(options.initialModel))

    return frame
end
