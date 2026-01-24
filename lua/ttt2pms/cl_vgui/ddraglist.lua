---@alias DDragList_ItemFactory fun(parent: Panel, itemHandle: any): Panel, Panel pnlSlot, pnlItem
---@alias DDragList_ListChangedCallback fun(list: DDragList_TTT2PMS)

---@class DDragList_Callbacks
---@field itemFactory DDragList_ItemFactory
---@field changed? DDragList_ListChangedCallback

---@class DDragList_P_Item
---@field private id number
---@field private item any
---@field private pnlParent Panel
---@field private pnlSlot Panel
---@field private pnlItem Panel

---@class DDragList_TTT2PMS : DPanelTTT2
---@field private pnlDragParent? DDragParent_TTT2PMS
---@field private callbacks? DDragList_Callbacks
---
---@field private idMap table<number, DDragList_P_Item>
---@field private itemOrder table<number>
---@field private itemToId table<any, number>
local DDragList_TTT2PMS = {}

function DDragList_TTT2PMS:Init()
    self.pnlDragParent = nil
    self.callbacks = nil

    self.idMap = {}
    self.itemOrder = {}
    self.itemToId = {}
end

---
---@param callbacks DDragList_Callbacks
function DDragList_TTT2PMS:SetCallbacks(callbacks)
    self.callbacks = callbacks
end

---
---@param pnl DDragParent_TTT2PMS
function DDragList_TTT2PMS:SetDDragParent(pnl)
    self.pnlDragParent = pnl
end

local function Check(self)
    if not self.callbacks then
        error("list callbacks not configured")
    end

    if not self.pnlDragParent or not IsValid(self.pnlDragParent) then
        error("drag parent not set or not valid")
    end
end

function DDragList_TTT2PMS:PerformLayout()
    Check(self)
    --self:SizeToChildren(false, true)
end

function DDragList_TTT2PMS:Paint(w, h)
    derma.SkinHook("Paint", "DragList_TTT2PMS", self, w, h)
end

derma.DefineControl(
    "DDragList_TTT2PMS",
    "a vertical list of drag-reorderable items",
    DDragList_TTT2PMS,
    "DPanelTTT2"
)
