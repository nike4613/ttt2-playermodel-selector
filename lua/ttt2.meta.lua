---@meta

---Initiates a stream message. The data will be converted to an encoded string and sent to the
---peer, which must be listening for the stream at [messageId].
---@realm shared
---
---@param messageId string The message ID the stream will be sent as. Does NOT need to be a network string.
---@param data table The data to send to the peer.
---@param plys? table<Player>|Player @realm server The player(s) to send the stream to. This only has an effect on the server.
function net.SendStream(messageId, data, plys) end

---Receive a stream message sent by [net.SendStream].
---@realm shared
---
---@param messageId string The message ID to listen on.
---@param callback fun(tbl: table, ply?: Player) The function to call when a stream is received. `ply` is only provided when receiving on the server.
function net.ReceiveStream(messageId, callback) end

---@realm shared
---Returns the translated string with name [name], or [name] itself if no such key was found.
---@param name string
---@return string translated The translated string
function LANG.TryTranslation(name) end

---@realm client
---@class DPanelTTT2 : DPanel, Panel

---@realm client
---@class DLabelTTT2 : DPanelTTT2, DLabel

---@realm client
---@class DScrollPanelTTT2 : DPanelTTT2, DScrollPanel

---@realm client
---@class DContentPanelTTT2 : DPanelTTT2

---@realm client
---@class DButtonTTT2 : DLabelTTT2, DButton
local DButtonTTT2 = {}
---Gets the icon material associated with this button.
---@realm client
---@return IMaterial? icon The icon material.
function DButtonTTT2:GetIcon() end
---Sets the icon rendered on the button.
---@realm client
---@param icon IMaterial? The icon material to render.
---@param is_shadowed? boolean Default `false`. Whether to render a shadow under the icon.
---@param size? number Default `32`. The size to render the [icon] at.
function DButtonTTT2:SetIcon(icon, is_shadowed, size) end

---@realm client
---@class DFrameTTT2 : DPanelTTT2, DFrame
local DFrameTTT2 = {}
---Sets the padding around this frame.
---@param left number
---@param top number
---@param right number
---@param bottom number
function DFrameTTT2:SetPadding(left, top, right, bottom) end
---
---@param bShow boolean
function DFrameTTT2:ShowBackButton(bShow) end

---@realm client
---@class DFormTTT2 : DPanelTTT2, DForm
local DFormTTT2 = {}
---Gets the label width for this form.
---@realm client
---@return number width
function DFormTTT2:GetLabelWidth() end
---Sets the label width for this form.
---@realm client
---@param width number
function DFormTTT2:SetLabelWidth(width) end

---@realm client
---@package
---@class _DFormTTT2_MakeObjectData<TPanel>
---@field label string
---
---@field enableToggle? boolean
---@field toggleInitialState? number
---@field toggleIconMaterial? table<IMaterial>
---@field toggleColorBackground? table<Color>
---@field OnClickToggle? fun(pnl: TPanel, state: number)
---
---@field enableRun? boolean
---@field runIconMaterial? IMaterial
---@field runColorBackground? Color
---@field OnClickRun? fun(btn: DButtonTTT2)

---@realm client
---@package
---@class _DFormTTT2_MakeButtonData
---@field label string
---@field buttonLabel string
---@field OnClick? fun(btn: DButtonTTT2)

---Create a new [DButtonTTT2] in the form, using the specified options.
---@param data _DFormTTT2_MakeButtonData
---@return DButtonTTT2 btn The created button
---@return DLabelTTT2 label The label created on the same row
function DFormTTT2:MakeButton(data) end

---@realm client
---@package
---@class _DFormTTT2_MakeComboBoxData<TExtra> : _DFormTTT2_MakeObjectData<DComboBoxTTT2>
---@field default? string|number
---@field choices? table<_DFormTTT2_MakeComboBoxData_Choice<TExtra>>>
---@field selectId? number
---@field selectName? string
---@field selectValue? string|number
---@field OnChange? fun(value: string|number, additionalData: TExtra, pnl: DComboBoxTTT2)
---@package
---@class _DFormTTT2_MakeComboBoxData_Choice<TExtra>
---@field title string
---@field value? string|number
---@field select? boolean
---@field icon? string
---@field data? TExtra

---@generic TExtra
---Create a new [DComboBoxTTT2] in the form, using the specified options.
---@param data _DFormTTT2_MakeComboBoxData<TExtra>
---@return DComboBoxTTT2 comboBox The created combo box
---@return DLabelTTT2 label The created label associated with the combo box
function DFormTTT2:MakeComboBox(data) end

---@package
---@class _DFormTTT2_MakeNumberWangData : _DFormTTT2_MakeObjectData<DNumberWangTTT2>
---@field default? number
---@field OnChange? fun(wang: DNumberWangTTT2, value: number)

---Create a new [DNumberWangTTT2] in the form, using the specified options.
---@param data _DFormTTT2_MakeObjectData
---@return DNumberWangTTT2 numberWang The created number wang
---@return DLabelTTT2 label The created label associated with the combo box
function DFormTTT2:MakeNumberWang(data) end

---@realm client
---@class DComboBoxTTT2 : DPanelTTT2
local DComboBoxTTT2 = {}
---Chose the value of the combo box programmatically, by value.
---@param value string|number must be a value currently present in the comboBox
---@param ignoreConVar? boolean `true` is passed here when setting ConVars to avoid loops.
function DComboBoxTTT2:ChooseOptionValue(value, ignoreConVar) end

---@realm client
---@class DTextEntryTTT2 : DPanelTTT2
local DTextEntryTTT2 = {}
---Sets the default value for the [DTextEntryTTT2].
---@param value string?
function DTextEntryTTT2:SetDefaultValue(value) end

---@realm client
---@class DNumberWangTTT2 : DTextEntryTTT2, DNumberWang
local DNumberWangTTT2 = {}

---Gets the list of permitted values currently set.
---@return table<number>|nil
function DNumberWangTTT2:GetPermittedValues() end

---Sets the list of permitted values that this number wang can take.
---If a value is currently set, this will change the value to the one in the permitted value table
---nearest to the currently set value.
---@param tbl table<number>?
function DNumberWangTTT2:SetPermittedValues(tbl) end

---@class CLGAMEMODEMENU
---@field priority integer
---@field icon IMaterial?
---@field title string
---@field description string
---@field searchBarPlaceholderText string?
---
---@type CLGAMEMODEMENU
CLGAMEMODEMENU = {} ---@diagnostic disable-line

---@class CLGAMEMODESUBMENU
---@field priority integer
---@field title string
---@field searchable boolean
---
---@type CLGAMEMODESUBMENU
CLGAMEMODESUBMENU = {} ---@diagnostic disable-line

---This function is used to populate the submenu on open/refresh.
---@note This function should be overwritten but not called.
---@realm client
---@hook
---@param parent Panel
function CLGAMEMODESUBMENU:Populate(parent) end

---This function is used to populate the button panel of a submenu on open/refresh.
---@note This function should be overwritten but not called.
---@note [CLGAMEMODESUBMENU:HasButtonPanel] must return `true` to display a button panel.
---@realm client
---@hook
---@param parent Panel
function CLGAMEMODESUBMENU:PopulateButtonPanel(parent) end

---Gets whether this menu should have a button panel.
---@note This function should be overridden but not called.
---@realm client
---@hook
---@return boolean HasButtonPanel Whether this submenu has a button panel
function CLGAMEMODESUBMENU:HasButtonPanel() end

---Called after the class is initialized and has finished inheriting.
---@note This function should be overridden but not called.
---@realm client
---@hook
function CLGAMEMODESUBMENU:Initialize() end

---Gets whether this submenu should be shown.
---@note This function should be overridden but not called.
---@realm client
---@hook
---@return boolean ShouldSow Whether this submenu should be visible
function CLGAMEMODESUBMENU:ShouldShow() end
