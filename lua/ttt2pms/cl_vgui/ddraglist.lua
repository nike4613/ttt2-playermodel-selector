---@alias DDragList_ItemFactory<T> fun(parent: Panel, itemHandle: any, item: T): Panel, Panel pnlSlot, pnlItem
---@alias DDragList_ListChangedCallback<T> fun(list: DDragList_TTT2PMS<T>)

---@class DDragList_Callbacks<T>
---@field itemFactory DDragList_ItemFactory<T>
---@field changed? DDragList_ListChangedCallback<T>
---if nil, it's treated as 0, 0
---@field GetItemPositionInSlot? fun(item: T, slot: Panel, itemPanel: Panel): number, number
---if nil, SetParent() then SetPos(0, 0)
---@field ParentItemToSlot? fun(item: T, slot: Panel, itemPanel: Panel)

---@package
---@class DDragList_P_Item<T>
---@field id number
---@field item T
---@field pnlParent? Panel
---@field pnlSlot? Panel
---@field pnlItem? Panel
---@field isDragging boolean
---@field isNew boolean

---@class DDragList_TTT2PMS<T> : DPanelTTT2
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
---@field package pnlDragParent? DDragParent_TTT2PMS
---@field package callbacks? DDragList_Callbacks<T>
---
---@field private dirty boolean
---
---@field private anyIsDragging boolean
---@field private nextId number
---@field package idMap table<number, DDragList_P_Item<T>>
---@field private itemOrder table<number>
---@field private itemDraggedOrder? table<number>
---@field private itemToId table<T, number>
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

    self.dirty = true
end

---
---@param callbacks DDragList_Callbacks<T>
function DDragList_TTT2PMS:SetCallbacks(callbacks)
    self.callbacks = callbacks
end

---
---@param pnl DDragParent_TTT2PMS
function DDragList_TTT2PMS:SetDragParent(pnl)
    self.pnlDragParent = pnl
end

local function Check(self, throw)
    if not self.callbacks then
        if throw then
            error("list callbacks not configured")
        else
            ErrorNoHaltWithStack("DDragList callbacks check failed")
            return false
        end
    end

    if not self.pnlDragParent or not IsValid(self.pnlDragParent) then
        if throw then
            error("list callbacks not configured")
        else
            ErrorNoHaltWithStack("DDragList pnlDragParent check failed")
            return false
        end
    end

    return true
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

---Inserts an item into the drag list.
---@param item T
---@param idx number
function DDragList_TTT2PMS:InsertItem(item, idx)
    local newId = self.nextId
    self.nextId = newId + 1

    self.itemToId[item] = newId
    table.insert(self.itemOrder, idx, newId)
    self.idMap[newId] = {
        id = newId,
        item = item,
        isDragging = false,
        isNew = true,
    }

    self:InvalidateLayout(false)
    self.dirty = true
end

---Adds an item to the drag list.
---@param item T
function DDragList_TTT2PMS:AddItem(item)
    self:InsertItem(item, #self.itemOrder + 1)
end

---Adds a list of items to the drag list, in order.
---@param items table<T>
function DDragList_TTT2PMS:AddItems(items)
    for i = 1, #items + 1 do
        self:AddItem(items[i])
    end
end

---@generic T
---@param tbl table<T>
---@param value T
---@return integer
local function IndexOf(tbl, value)
    for i = 1, #tbl + 1 do
        if tbl[i] == value then
            return i
        end
    end
    return -1
end

---
---@param item T
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

    self.dirty = true
end

---Get the number of items in this list.
---@return integer count the number of items in the list
function DDragList_TTT2PMS:Count()
    return #self.itemOrder
end

---Get the item at position i in the list.
---@param i integer
---@return T
function DDragList_TTT2PMS:Item(i)
    return self.idMap[self.itemOrder[i]].item
end

---Gets the ID of the item at index [i].
---@param i integer
---@return any id
function DDragList_TTT2PMS:ItemId(i)
    return self.itemOrder[i]
end

---Gets an iterator over the items in this list.
---@return fun(): T?
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
---@return fun(): number?, T?
function DDragList_TTT2PMS:IIter()
    local i = 0
    return function()
        i = i + 1
        if i <= #self.itemOrder then
            return i, self:Item(i)
        end
    end
end

---@generic T
---@param list DDragList_TTT2PMS
---@param callbacks DDragList_Callbacks<T>
---@param it DDragList_P_Item<T>
local function LazyInitItem(list, callbacks, it)
    if not it.pnlParent or not it.pnlSlot or not it.pnlItem then
        local parent = vgui.Create("DPanelTTT2", list)

        local slot, item = callbacks.itemFactory(parent, it.id, it.item)
        local _ = (callbacks.ParentItemToSlot or DefaultParentToSlot)(it.item, slot, item)

        parent:InvalidateLayout(true)
        parent:SizeToChildren(false, true)

        it.pnlParent = parent
        it.pnlSlot = slot
        it.pnlItem = item
    end
end

function DDragList_TTT2PMS:PerformLayout()
    if not Check(self) then
        return
    end

    local sw = self:GetWide()

    if not self.dirty and self.lastWidth == sw then
        return
    end

    self.lastWidth = sw
    self.dirty = false

    --print("DDragList::PerformLayout wide=" .. sw)

    local snapTime = self:GetMoveSnapTime()
    local padding = self:GetPadding()

    local x = padding
    local y = padding

    local maxw = 0

    local order = self.itemDraggedOrder or self.itemOrder

    for i = 1, #order do
        local j = order[i]
        local it = self.idMap[j]

        --print("[" .. i .. "] j=" .. (j or "(nil)") .. " y=" .. (y or "(nil)") .. " maxw=" .. maxw)

        LazyInitItem(self, self.callbacks, it)

        local w, h = it.pnlParent:GetSize()
        --print("w=" .. w .. " h=" .. h)

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
        self:SetSize(maxw + 2 * padding, y - padding)
    else
        self:SetTall(y - padding)
    end

    -- once we've ended up with a width, resize all of the item parents to fit
    sw = self:GetWide()

    for i = 1, #order do
        local j = order[i]
        local it = self.idMap[j]

        it.pnlParent:SetWide(sw - 2 * padding)
        it.pnlParent:InvalidateLayout(true)
        it.pnlParent:SizeToChildren(false, true)
    end
end

---@generic T
---@param self DDragList_TTT2PMS<T>
---@param order table<number>
---@param item DDragList_P_Item<T>
---@param x number
---@param y number
---@return number index the index that the given item should be inserted at in the CURRENT list.
local function FindTargetIndexGivenPosition(self, order, item, x, y)
    -- note: for the moment, we only care about the Y position, and ignore the X.

    if y < 0 then
        return 1
    end

    local _, sloth = item.pnlParent:GetSize()
    local _, itemh = item.pnlItem:GetSize()

    -- offset the Y by 1/2 item height so that we're testing against the "center" of the item
    y = y + itemh / 2

    local padding = self:GetPadding()
    local cy = 0

    for i = 1, #order do
        local id = order[i]

        -- consider: IF we put `itemId` here, would the current mouse position be (vertically) in that space?
        if cy < y and y <= cy + sloth + 2 * padding then
            -- it would; this is the position we should be putting the itemi.
            return i
        end

        -- if the item we're currently considering is the one we want to insert, we DON'T want to
        -- add it to our consideration.
        if id ~= item.id then
            -- otherwise, advance to next item vertically
            ---@diagnostic disable-next-line
            cy = cy + 2 * padding + self.idMap[id].pnlParent:GetTall()
        end
    end

    -- if we reached the end of the list, we want to put it at the end
    return #order + 1
end

---@generic T
---@param tbl table<T>
---@param oldIndex number
---@param newIndex number new index as it would be in the CURRENT list, not the FINAL list.
---@param id T
---@return number newIndex
local function MoveItemInList(tbl, oldIndex, newIndex, id)
    if oldIndex <= 0 or oldIndex > #tbl then
        error("invalid oldIndex " .. oldIndex)
    end
    if newIndex <= 0 or newIndex > #tbl + 1 then
        error("invalid newIndex " .. newIndex)
    end

    if oldIndex == newIndex then
        tbl[newIndex] = id
        return newIndex
    end

    table.remove(tbl, oldIndex)
    if oldIndex < newIndex then
        -- we just changed the list before the new index; need to adjust
        newIndex = newIndex - 1
    end
    table.insert(tbl, newIndex, id)

    return newIndex
end

---@package
---@class DDragList_P_Draggable<T> : DDragParent_Draggable
---@field it DDragList_P_Item<T>
---@field list DDragList_TTT2PMS<T>
---@field curIdxInOrder number
---@field order table<number>

---@generic T
---@param self DDragList_P_Draggable<T>
---@param pos DDragParent_Position
local function Draggable_Move(self, pos)
    -- convert position coordinates
    local x, y = self.list:ScreenToLocal(pos.screenX, pos.screenY)

    -- figure out where in the list it should go
    local targetIndex = FindTargetIndexGivenPosition(self.list, self.order, self.it, x, y)
    -- move it, and tell the list to relayout
    targetIndex = MoveItemInList(self.order, self.curIdxInOrder, targetIndex, self.it.id)
    if targetIndex ~= self.curIdxInOrder then
        self.list:InvalidateLayout(false)
        self.curIdxInOrder = targetIndex
        ---@diagnostic disable-next-line
        self.list.dirty = true
    end

    -- lock x position of dragged item
    pos.localX = pos.oldLocalX
end

---@package
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

---@generic T
---@param self DDragList_P_Draggable<T>
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
        self.list.itemOrder = self.order
        self.list.itemDraggedOrder = nil
        self.list.anyIsDragging = false
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

    ---@diagnostic disable
    ---@diagnostic enable

    return true
end

---@generic T
---@param self DDragList_P_Draggable<T>
local function Draggable_Trash(self)
    -- the item is REMOVED. Terminate appropriately.
    table.remove(self.order, self.curIdxInOrder)
    self.it.pnlParent:Remove()

    ---@diagnostic disable
    self.list.idMap[self.it.id] = nil
    self.list.itemToId[self.it.item] = nil
    self.list.dirty = true
    ---@diagnostic enable

    self.it.isDragging = false
    ---@diagnostic disable
    self.list.anyIsDragging = false
    self.list.itemOrder = self.order
    self.list.itemDraggedOrder = nil
    ---@diagnostic enable

    ---@diagnostic disable-next-line
    local changedCb = self.list.callbacks.changed
    if changedCb then
        changedCb(self.list)
    end
end

---@generic T
---@param self DDragList_P_Draggable<T>
local function Draggable_Cancel(self)
    -- as far as it goes, cancel is really very simple. we just need to fully restore state to what
    -- it was before the drag.
    self.it.isDragging = false
    ---@diagnostic disable
    self.list.anyIsDragging = false
    self.list.itemDraggedOrder = nil
    self.list.dirty = true
    ---@diagnostic enable

    ---@diagnostic disable-next-line
    (self.list.callbacks.ParentItemToSlot or DefaultParentToSlot)(
        self.it.item,
        self.it.pnlSlot,
        self.it.pnlItem
    )
end

local function CheckId(self, id)
    if type(id) ~= "number" or not self.idMap[id] then
        error("invalid item id")
    end
end

---Begin the drag of the item with ID `itemId`
---@param itemId any
---@param btn MOUSE
---@param allowTrash? boolean
function DDragList_TTT2PMS:StartDrag(itemId, btn, allowTrash)
    CheckId(self, itemId)
    ---@cast itemId integer

    if self.anyIsDragging then
        error("an item is already being dragged")
    end

    local it = self.idMap[itemId]

    LazyInitItem(self, self.callbacks, it)

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
    self.dirty = true
end

---Gets the index of the item referred to by [id]
---@param id any
---@return integer index The index of the item with ID [id], or `-1` if the item does not exist.
function DDragList_TTT2PMS:IndexOfId(id)
    CheckId(self, id)
    ---@cast id integer

    return IndexOf(self.itemOrder, id)
end

---Moves the item with ID [id] to [idx].
---@param id any
---@param idx integer The index to move the item with ID [id] to. This will be the index the item ends up at in the final list.
function DDragList_TTT2PMS:MoveItemIdTo(id, idx)
    CheckId(self, id)
    ---@cast id integer

    local oldIndex = IndexOf(self.itemOrder, id)
    local newIndex = idx
    if newIndex > oldIndex then
        -- MoveItemInList expects the position to *insert* the item in the current list, as if the
        -- old position hadn't been removed. (It does this because this is the useful behavior for
        -- the other uses.)
        newIndex = newIndex + 1
    end

    local finalIndex = MoveItemInList(self.itemOrder, oldIndex, newIndex, id)

    if finalIndex ~= oldIndex then
        self.dirty = true
        self:InvalidateLayout(false)
    end
end

---Moves the item at index [from] to index [to].
---@note Equivalent to `MoveItemIdTo(ItemId(from), to)`
---@param from integer
---@param to integer
function DDragList_TTT2PMS:ShuffleItem(from, to)
    if to > from then
        to = to - 1
    end

    local finalIndex = MoveItemInList(self.itemOrder, from, to, self.itemOrder[from])

    if finalIndex ~= from then
        self.dirty = true
        self:InvalidateLayout(false)
    end
end

---Moves the item with ID [id] relative to its current position, clamping to table boundaries.
---@param id any
---@param rel integer The relative offset index to move the item to.
function DDragList_TTT2PMS:MoveItemIdRelative(id, rel)
    CheckId(self, id)
    ---@cast id integer

    local oldIndex = IndexOf(self.itemOrder, id)
    local newIndex = oldIndex + rel
    if newIndex < 1 then
        newIndex = 1
    elseif newIndex > #self.itemOrder then
        newIndex = #self.itemOrder + 1 -- integrates below adjustment
    elseif newIndex > oldIndex then
        newIndex = newIndex + 1
    end
    local finalIndex = MoveItemInList(self.itemOrder, oldIndex, newIndex, id)

    if finalIndex ~= oldIndex then
        self.dirty = true
        self:InvalidateLayout(false)
    end
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
