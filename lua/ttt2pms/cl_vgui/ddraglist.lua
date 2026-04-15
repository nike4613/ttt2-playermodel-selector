---@alias DDragList_ItemFactory fun(parent: Panel, itemHandle: any, item: userdata): Panel, Panel pnlSlot, pnlItem
---@alias DDragList_ListChangedCallback fun(list: DDragList_TTT2PMS)

---@class DDragList_Callbacks
---@field itemFactory DDragList_ItemFactory
---@field changed? DDragList_ListChangedCallback
---if nil, it's treated as 0, 0
---@field GetItemPositionInSlot? fun(item: userdata, slot: Panel, itemPanel: Panel): number, number
---if nil, SetParent() then SetPos(0, 0)
---@field ParentItemToSlot? fun(item: userdata, slot: Panel, itemPanel: Panel)

---@class DDragList_P_Item
---@field id number
---@field item userdata
---@field pnlParent Panel
---@field pnlSlot Panel
---@field pnlItem Panel
---@field isDragging boolean
---@field isNew boolean

---@class DDragList_TTT2PMS : DPanelTTT2
---@field private fMoveSnapTime number
---@field GetMoveSnapTime fun(self: DDragList_TTT2PMS): number
---@field SetMoveSnapTime fun(self: DDragList_TTT2PMS, speed:number)
---
---@field private fPadding number
---@field GetPadding fun(self: DDragList_TTT2PMS): number
---@field SetPadding fun(self: DDragList_TTT2PMS, padding: number)
---
---@field private bFitWidth boolean
---@field GetFitWidth fun(self: DDragList_TTT2PMS): boolean
---@field SetFitWidth fun(self: DDragList_TTT2PMS, fitWidth: boolean)
---
---@field private pnlDragParent? DDragParent_TTT2PMS
---@field private callbacks? DDragList_Callbacks
---
---@field private anyIsDragging boolean
---@field private nextId number
---@field private idMap table<number, DDragList_P_Item>
---@field private itemOrder table<number>
---@field private itemDraggedOrder? table<number>
---@field private itemToId table<any, number>
local DDragList_TTT2PMS = {}

AccessorFunc(DDragList_TTT2PMS, "fMoveSnapTime", "MoveSnapTime", FORCE_NUMBER)
AccessorFunc(DDragList_TTT2PMS, "fPadding", "Padding", FORCE_NUMBER)
AccessorFunc(DDragList_TTT2PMS, "bFitWidth", "FitWidth", FORCE_BOOL)

function DDragList_TTT2PMS:Init()
    self.pnlDragParent = nil
    self.callbacks = nil

    self.nextId = 1
    self.idMap = {}
    self.itemOrder = {}
    self.itemToId = {}

    self:SetMoveSnapTime(0.1)
    self:SetPadding(0)
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

---
---@param self DPanel
local function InnerParentPerformLayout(self)
    self:SizeToChildren(true, true)
end

---Inserts an item into the drag list.
---@param item userdata
---@param idx number
function DDragList_TTT2PMS:InsertItem(item, idx)
    local newId = self.nextId
    self.nextId = newId + 1

    local container = vgui.Create("DPanel", self)
    ---@diagnostic disable-next-line
    container.PerformLayout = InnerParentPerformLayout

    local pnlSlot, pnlItem = self.callbacks.itemFactory(container, newId, item)

    self.itemToId[item] = newId
    table.insert(self.itemOrder, idx, newId)
    self.idMap[newId] = {
        id = newId,
        item = item,
        isDragging = false,
        isNew = true,
        pnlParent = container,
        pnlSlot = pnlSlot,
        pnlItem = pnlItem,
    }

    self:InvalidateLayout(false)
end

---Adds an item to the drag list.
---@param item userdata
function DDragList_TTT2PMS:AddItem(item)
    self:InsertItem(item, #self.itemOrder)
end

---Adds a list of items to the drag list, in order.
---@param items table<userdata>
function DDragList_TTT2PMS:AddItems(items)
    for i = 1, #items do
        self:AddItem(items[i])
    end
end

---@generic T
---@param tbl table<T>
---@param value T
---@return integer
local function IndexOf(tbl, value)
    for i = 1, #tbl do
        if tbl[i] == value then
            return i
        end
    end
    return -1
end

---
---@param item any
function DDragList_TTT2PMS:RemoveItem(item)
    local id = self.itemToId[item]
    if not id then
        error("item not in list")
    end

    local posInOrder = IndexOf(self.itemOrder, id)
    if posInOrder >= 0 then
        table.remove(self.itemOrder, posInOrder)
    end

    self.itemToId[item] = nil
    self.idMap[id] = nil
end

---Get the number of items in this list.
---@return number count the number of items in the list
function DDragList_TTT2PMS:Count()
    return #self.itemOrder
end

---Get the item at position i in the list.
---@param i number
---@return userdata
function DDragList_TTT2PMS:Item(i)
    return self.idMap[self.itemOrder[i]].item
end

---Gets an iterator over the items in this list.
---@return fun(): userdata?
function DDragList_TTT2PMS:Iter()
    local i = 0
    return function()
        i = i + 1
        if i <= #self.itemOrder then
            return self:Item(i)
        end
    end
end

---Gets an iterator over the items in this list, alongside their index.
---@return fun(): number?, userdata?
function DDragList_TTT2PMS:IIter()
    local i = 0
    return function()
        i = i + 1
        if i < #self.itemOrder then
            return i, self:Item(i)
        end
    end
end

function DDragList_TTT2PMS:PerformLayout()
    Check(self)

    local snapTime = self:GetMoveSnapTime()
    local padding = self:GetPadding()

    local x = 0
    local y = 0

    local maxw = 0

    local order = self.itemDraggedOrder or self.itemOrder

    for i = 1, #order do
        local j = order[i]
        local it = self.idMap[j]

        local w, h = it.pnlParent:GetSize()

        if it.isNew then
            it.pnlParent:SetPos(x, y)
        else
            it.pnlParent:MoveTo(x, y, snapTime, 0, -1)
        end

        it.isNew = false

        y = y + h + padding

        maxw = math.max(maxw, w)
    end

    if self.bFitWidth then
        self:SetSize(maxw, y - padding)
    else
        self:SetTall(y - padding)
    end
end

---
---@param self DDragList_TTT2PMS
---@param order table<number>
---@param itemId number
---@param x number
---@param y number
---@return number index the index that the given item should be inserted at in the CURRENT list.
local function FindTargetIndexGivenPosition(self, order, itemId, x, y)
    -- note: for the moment, we only care about the Y position, and ignore the X.

    if y < 0 then
        return 1
    end

    ---@diagnostic disable-next-line
    local slotw, sloth = self.idMap[itemId].pnlParent:GetSize()

    local padding = self:GetPadding()
    local cy = 0

    for i = 1, #order do
        local id = order[i]

        -- consider: IF we put `itemId` here, would the current mouse position be (vertically) in that space?
        if cy < y and y < cy + sloth then
            -- it would; this is the position we should be putting the item.
            return i
        end

        -- if the item we're currently considering is the one we want to insert, we DON'T want to
        -- add it to our consideration.
        if id ~= itemId then
            -- otherwise, advance to next item vertically
            ---@diagnostic disable-next-line
            cy = cy + padding + self.idMap[id].pnlParent:GetTall()
        end
    end

    -- if we reached the end of the list, we want to put it at the end
    return #order
end

---@generic T
---@param tbl table<T>
---@param oldIndex number
---@param newIndex number
---@param id T
---@return T oldId
local function MoveItemInList(tbl, oldIndex, newIndex, id)
    if oldIndex <= 0 or oldIndex >= #tbl then
        error("invalid oldIndex " .. oldIndex)
    end
    if newIndex <= 0 or newIndex > #tbl then
        error("invalid newIndex " .. newIndex)
    end

    if oldIndex == newIndex then
        local oldId = tbl[oldIndex]
        tbl[newIndex] = id
        return oldId
    end

    local oldId = table.remove(tbl, oldIndex)
    if oldIndex < newIndex then
        -- we just changed the list before the new index; need to adjust
        newIndex = newIndex - 1
    end
    table.insert(tbl, newIndex, id)

    return oldId
end

---@class DDragList_P_Draggable : DDragParent_Draggable
---@field it DDragList_P_Item
---@field list DDragList_TTT2PMS
---@field curIdxInOrder number
---@field order table<number>

---
---@param self DDragList_P_Draggable
---@param pos DDragParent_Position
local function Draggable_Move(self, pos)
    -- convert position coordinates
    local x, y = self.list:ScreenToLocal(pos.screenX, pos.screenY)

    -- figure out where in the list it should go
    local targetIndex = FindTargetIndexGivenPosition(self.list, self.order, self.it.id, x, y)
    -- move it, and tell the list to relayout
    MoveItemInList(self.order, self.curIdxInOrder, targetIndex, self.it.id)
    if targetIndex ~= self.curIdxInOrder then
        self.list:InvalidateLayout(false)
        self.curIdxInOrder = targetIndex
    end
end

local function DefaultGetOffsetInSlot()
    return 0, 0
end

---
---@param slot Panel
---@param item Panel
local function DefaultParentToSlot(_, slot, item)
    item:SetParent(slot)
    item:SetPos(0, 0)
end

---@class DDragList_P_MoveItemToSlotAnim : AnimationData
---@field rx number
---@field ry number
---@field slot Panel

---
---@param anim DDragList_P_MoveItemToSlotAnim
---@param pnlItem Panel
---@param t number
local function MoveItemToSlotAnim_Think(anim, pnlItem, t)
    if not anim.StartPos then
        anim.StartPos = Vector(pnlItem:GetX(), pnlItem:GetY())
    end

    local tx, ty = anim.slot:LocalToScreen(anim.rx, anim.ry)
    tx, ty = pnlItem:GetParent():ScreenToLocal(tx, ty)
    local p = LerpVector(t, anim.StartPos, Vector(tx, ty))

    pnlItem:SetPos(p.x, p.y)
end

---
---@param self DDragList_P_Draggable
---@param pos DDragParent_Position
---@param doneAnimating fun()
---@return true
local function Draggable_Finish(self, pos, doneAnimating)
    -- perform the usual Move logic before anything else
    Draggable_Move(self, pos)

    -- now, we want to take control of the panel while it's still on the drag parent, and animate it
    -- going towards its final position in its slot, then ONLY once that's done reparent it in
    ---@diagnostic disable-next-line
    local rx, ry = (self.list.callbacks.GetItemPositionInSlot or DefaultGetOffsetInSlot)(
        self.it.item,
        self.it.pnlSlot,
        self.it.pnlItem
    )

    ---@type DDragList_P_MoveItemToSlotAnim
    local anim = self.it.pnlItem:NewAnimation(self.list:GetMoveSnapTime(), 0, -1, function()
        -- animation complete; now we do our reparent, and generally commit the drag
        ---@diagnostic disable-next-line
        (self.list.callbacks.ParentItemToSlot or DefaultParentToSlot)(
            self.it.item,
            self.it.pnlSlot,
            self.it.pnlItem
        )

        doneAnimating()

        -- and here's where we commit the drag
        self.it.isDragging = false
        ---@diagnostic disable
        self.list.anyIsDragging = false
        self.list.itemOrder = self.order
        ---@diagnostic enable

        ---@diagnostic disable-next-line
        local changedCb = self.list.callbacks.changed
        if changedCb then
            changedCb(self.list)
        end
    end)
    anim.Think = MoveItemToSlotAnim_Think
    anim.rx = rx
    anim.ry = ry
    anim.slot = self.it.pnlSlot

    return true
end

---
---@param self DDragList_P_Draggable
local function Draggable_Trash(self)
    -- the item is REMOVED. Terminate appropriately.
    table.remove(self.order, self.curIdxInOrder)

    self.it.isDragging = false
    ---@diagnostic disable
    self.list.anyIsDragging = false
    self.list.itemOrder = self.order
    ---@diagnostic enable

    ---@diagnostic disable-next-line
    local changedCb = self.list.callbacks.changed
    if changedCb then
        changedCb(self.list)
    end
end

---
---@param self DDragList_P_Draggable
local function Draggable_Cancel(self)
    -- as far as it goes, cancel is really very simple. we just need to fully restore state to what
    -- it was before the drag.
    self.it.isDragging = false
    ---@diagnostic disable
    self.list.anyIsDragging = false
    self.list.itemDraggedOrder = nil
    ---@diagnostic enable

    ---@diagnostic disable-next-line
    (self.list.callbacks.ParentItemToSlot or DefaultParentToSlot)(
        self.it.item,
        self.it.pnlSlot,
        self.it.pnlItem
    )
end

---Begin the drag of the item with ID `itemId`
---@param itemId any
---@param btn MOUSE
---@param allowTrash? boolean
function DDragList_TTT2PMS:StartDrag(itemId, btn, allowTrash)
    if type(itemId) ~= "number" or not self.idMap[itemId] then
        error("invalid item id")
    end

    if self.anyIsDragging then
        error("an item is already being dragged")
    end

    local it = self.idMap[itemId]

    self.itemDraggedOrder = table.Copy(self.itemOrder)

    ---@type DDragList_P_Draggable
    local draggable = {
        it = it,
        list = self,
        order = self.itemDraggedOrder,
        curIdxInOrder = IndexOf(self.itemDraggedOrder, it.id),

        btn = btn,
        panel = it.pnlItem,

        move = Draggable_Move,
        finish = Draggable_Finish,
        cancel = Draggable_Cancel,
    }

    if allowTrash then
        draggable.trash = Draggable_Trash
    end

    it.isDragging = true
    self.anyIsDragging = true
    self.pnlDragParent:BeginDrag(draggable)
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
