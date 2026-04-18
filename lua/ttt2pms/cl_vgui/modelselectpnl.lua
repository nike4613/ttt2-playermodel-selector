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
local ModelSelectorPanel_TTT2PMS = {}

function ModelSelectorPanel_TTT2PMS:Init()
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

    local bodygroupsContent = upper:Add("DContentPanelTTT2")
    bodygroupsContent:Dock(FILL)
    local bodygroupsScroll = bodygroupsContent:Add("DScrollPanelTTT2")
    self.pnlFormContainer = bodygroupsScroll
    bodygroupsScroll:Dock(FILL) -- fill remaining space in container

    local colorForm = vgui.CreateTTT2Form(bodygroupsScroll, "ttt2pms_select_model_color_header")
    self.pnlFormColor = colorForm
    colorForm:Dock(TOP)

    ---@type DComboBoxTTT2
    self.pnlCmbColorMode = vgui.Create("DComboBoxTTT2", self)
    self.pnlCmbColorMode:SetTall(32)
    self.pnlCmbColorMode:Dock(TOP)
    self.pnlCmbColorMode:AddChoice("ttt2pms_select_model_color_mode_opt_default", -1)
    self.pnlCmbColorMode:AddChoice(
        "ttt2pms_select_model_color_mode_opt_server",
        PLAYERMODEL_COLOR_MODE.SERVER
    )
    self.pnlCmbColorMode:AddChoice(
        "ttt2pms_select_model_color_mode_opt_user",
        PLAYERMODEL_COLOR_MODE.USER_GLOBAL
    )
    self.pnlCmbColorMode:AddChoice(
        "ttt2pms_select_model_color_mode_opt_model",
        PLAYERMODEL_COLOR_MODE.MODEL
    )
    self.pnlCmbColorMode:AddChoice(
        "ttt2pms_select_model_color_mode_opt_random",
        PLAYERMODEL_COLOR_MODE.RANDOM
    )
    self.pnlCmbColorMode:SetDefaultValue(-1)
    self.pnlCmbColorMode.OnSelect = function(_, _, value, _)
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

        self.modelDirty = true
        self:InvalidateLayout(false)
        self.pnlColorSelector:GetParent():InvalidateLayout(false)

        if self.OnChanged then
            self.OnChanged(table.Copy(self.plymodel))
        end
    end

    colorForm:AddItem(self.pnlCmbColorMode)

    self.pnlColorSelector = vgui.Create("DColorMixer", self)
    self.pnlColorSelector:SetPalette(true)
    self.pnlColorSelector:SetAlphaBar(false)
    self.pnlColorSelector:SetWangs(true)
    ---@diagnostic disable-next-line
    self.pnlColorSelector.ValueChanged = function(_, color)
        self.plymodel.color = color
        self.modelDirty = true
        self:InvalidateLayout(false)
    end

    colorForm:AddItem(self.pnlColorSelector)

    local bodygroupsForm =
        vgui.CreateTTT2Form(bodygroupsScroll, "ttt2pms_select_model_bodygroups_header")
    self.pnlFormBodygroups = bodygroupsForm
    bodygroupsForm:Dock(TOP)

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

function ModelSelectorPanel_TTT2PMS:PerformLayout()
    if self.modelDirty then
        print("selector panel modelDirty")
        PrintTable({ self.plymodel })
        self.pnlModel:SetPlayermodel(self.plymodel)
        self.pnlCmbColorMode:ChooseOptionValue(self.plymodel.colorMode or -1)
        self.pnlColorSelector:SetColor(self.plymodel.color)
    end
    self.modelDirty = false

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
