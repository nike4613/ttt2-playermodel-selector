---@class DDragParent_TTT2PMS : DPanelTTT2
---
---@field private bDebugShow boolean
---@field GetDebugShow fun(self):boolean
---@field SetDebugShow fun(self, v: boolean)
---
---@field private nTrashHeight number
---@field GetTrashHeight fun(self):number
---@field SetTrashHeight fun(self, v:number)
---
---@field private nScrollUpZone number?
---@field GetScrollUpZone fun(self):number?
---@field SetScrollUpZone fun(self, v?:number)
---
---@field private nScrollDownZone number?
---@field GetScrollDownZone fun(self):number?
---@field SetScrollDownZone fun(self, v?:number)
---
---@field private draggable? DDragParent_Draggable
local DDragParent_TTT2PMS = {}

AccessorFunc(DDragParent_TTT2PMS, "bDebugShow", "DebugShow", FORCE_BOOL)
AccessorFunc(DDragParent_TTT2PMS, "nTrashHeight", "TrashHeight", FORCE_NUMBER)
AccessorFunc(DDragParent_TTT2PMS, "nScrollUpZone", "ScrollUpZone", FORCE_NUMBER)
AccessorFunc(DDragParent_TTT2PMS, "nScrollDownZone", "ScrollDownZone", FORCE_NUMBER)

function DDragParent_TTT2PMS:Init()
    self:SetDebugShow(false)
    self:SetPaintBackground(false)
    self:SetPaintBackgroundEnabled(false)
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)
    self:SetZPos(-32768)

    self:SetTrashHeight(ttt2pms.cl.plyModelRowHeight)
    self:SetScrollUpZone(nil)
    self:SetScrollDownZone(nil)

    self.dragState = nil
    self.trashAnim = nil

    -- we want an element for the trash zone too. it'll be hidden if we don't have a trash callback
    -- though it won't actually be visible unless TrashCallback is set
    ---@type DPanel
    local trash = self:Add("DPanelTTT2")
    self.pnlTrash = trash
    trash:SetPaintBackground(false)
    trash:SetPaintBackgroundEnabled(false)
    trash:SetVisible(false)
    trash:SetTall(0)
    ---@diagnostic disable-next-line
    function trash:Paint(w, h)
        derma.SkinHook("Paint", "DragParentTrashZone_TTT2PMS", self, w, h)
    end

    self:InvalidateLayout()
end

---@class DDragParent_Position
---@field parentW number drag container width
---@field parentH number drag container height
---@field oldLocalX number old panel X in local coords
---@field oldLocalY number old panel Y in local coords
---@field localX number new panel X in local coords
---@field localY number new panel Y in local coords
---@field screenX number mouse X in screen coords
---@field screenY number mouse Y in screen coords
---@field mouseX number mouse X in local coords
---@field mouseY number mouse Y in local coords

---@class DDragParent_Draggable
---@field btn MOUSE
---@field panel Panel
---@field move? fun(self,pos:DDragParent_Position) Called when the dragged panel is moved.
---                                                 If the local coordinates are modified, the
---                                                 dragged panel is moved there.
---@field trash? fun(self) Called when the panel is dragged over the trash. Trash does
---                                                 not appear if not specified. The panel must be
---                                                 left INTACT by this method; it will still be
---                                                 used for some animation.
---@field finish fun(self,pos:DDragParent_Position) Called when the dragged panel is
---                                                 dropped. If this does not reparent pnl, pnl
---                                                 will be removed. The Dock state of the panel
---                                                 is reset at start, so must be re-Docked if needed.
---@field cancel fun(self) Called if the drag is cancelled for some reason

function DDragParent_TTT2PMS:CanBeginDrag()
    return self.draggable == nil
end

local function GetZoneOrDefault(self, zone)
    return zone or (0.25 * self:GetTall())
end

---
---@param draggable DDragParent_Draggable
function DDragParent_TTT2PMS:BeginDrag(draggable)
    if self.draggable then
        error("cannot start a new drag operation while a previous one is not yet complete")
    end

    self.draggable = draggable
    self:InvalidateLayout()

    local panel = draggable.panel

    -- first, get the panel's bounds BEFORE changing Dock
    local x, y, w, h = panel:GetBounds()
    if panel:GetParent() then
        x, y = panel:GetParent():LocalToScreen(x, y)
    end
    x, y = self:ScreenToLocal(x, y)

    -- then, reparent
    panel:SetParent(self)
    -- then, configure its initial positioning and size
    panel:Dock(NODOCK)
    panel:SetSize(w, h)
    panel:SetPos(x, y)

    -- capture the mouse for the duration of the drag
    self:SetMouseInputEnabled(true)
    self:MouseCapture(true)
    self:SetZPos(32767)

    local mx, my = input.GetCursorPos()
    mx, my = self:ScreenToLocal(mx, my)

    -- store the offset from the panel pos to the mouse pos so we can keep the panel correct
    self.dragState = {
        dragging = true,
        blockScroll = true,
        mouseX = mx,
        mouseY = my,
        offsX = x - mx,
        offsY = y - my,
        pnlX = x,
        pnlY = y,
        trashHovered = false,
    }

    -- show the trash if necessary
    if draggable.trash then
        self.pnlTrash:SetVisible(true)
        self.pnlTrash:SetTall(self.nTrashHeight)
        self.pnlTrash:Dock(TOP)
        self.pnlTrash:SetPos(0, -self.nTrashHeight)
        self.pnlTrash:SetAnimationEnabled(true)
        self.pnlTrash:MoveTo(0, 0, 0.5, 0, 0.5)
    end
end

function DDragParent_TTT2PMS:EndDrag()
    if not self.draggable or not self.dragState.dragging then
        return
    end

    self.dragState.dragging = false

    if self.dragState.trashHovered then
        -- the drag finished while the trash was hovered
        self.draggable:trash()
    else
        -- the drag finished while the trash was NOT hovered
        local px, py = self.draggable.panel:GetPos()
        local sx, sy = self:LocalToScreen(px, py)
        ---@type DDragParent_Position
        local pos = {
            parentW = self:GetWide(),
            parentH = self:GetTall(),
            oldLocalX = px,
            oldLocalY = py,
            localX = px,
            localY = py,
            screenX = sx,
            screenY = sy,
            mouseX = self.dragState.mouseX,
            mouseY = self.dragState.mouseY,
        }
        self.draggable:finish(pos)

        -- if the finish function didn't reparent, hide and destroy the panel ourselves
        if self.draggable.panel and self.draggable.panel:GetParent() == self then
            self.draggable.panel:SetVisible(false)
            self.draggable.panel:Remove()
        end
    end

    -- hide the trash panel
    if self.draggable.trash then
        self.pnlTrash:MoveTo(0, -self.nTrashHeight, 0.5, 0, 1, function(_, pnl)
            pnl:SetVisible(false)
            pnl:SetTall(0)
            self:SetZPos(-32768)
        end)
        if self.dragState.trashHovered then
            -- need to animate the dragged panel too
            local x, y = self.draggable.panel:GetPos()
            self.draggable.panel:MoveTo(
                x,
                y - self:GetTall(),
                0.5 * (self:GetTall() / self.nTrashHeight), -- this dance makes sure that this anim moves at the same rate as the above trash anim
                0,
                1,
                function(_, pnl)
                    -- destroy the animation state if its still present
                    if self.trashAnim and self.trashAnim.panel == pnl then
                        self.trashAnim = nil
                    end
                    -- and destroy the panel itself
                    pnl:Remove()
                end
            )
        else
            self.trashAnim = nil
        end
    else
        self:SetZPos(-32768)
    end

    self.draggable = nil
    self.dragState = nil
    self.trashAnim = nil
end

function DDragParent_TTT2PMS:CancelDrag()
    if not self.draggable or not self.dragState.dragging then
        return
    end

    self.dragState.dragging = false
    self.draggable:cancel()
    self.pnlTrash:SetVisible(false)
    self.pnlTrash:SetTall(0)
    self:SetZPos(-32768)
    self.draggable = nil
    self.dragState = nil
    self.trashAnim = nil
end

---
---@param btn MOUSE
function DDragParent_TTT2PMS:OnMouseReleased(btn)
    if not self.draggable or not self.dragState.dragging then
        return false
    end

    if btn ~= self.draggable.btn then
        return false
    end

    -- the user has released the mouse button they were dragging with. finish the drag
    self:EndDrag()

    return true
end

function DDragParent_TTT2PMS:Think()
    if not self.draggable or not self.dragState or not self.dragState.dragging then
        return
    end

    local thinkTime = UnPredictedCurTime()

    -- if we're currently dragging, we need to update the dragged panel positioning
    --
    local sx, sy = input.GetCursorPos()
    local mx, my = self:ScreenToLocal(sx, sy)

    if mx ~= self.dragState.mouseX or my ~= self.dragState.mouseY then
        -- the mouse moved since the last time we noticed, do a move update
        local nx, ny = mx + self.dragState.offsX, my + self.dragState.offsY

        if self.draggable.move then
            ---@type DDragParent_Position
            local pos = {
                parentW = self:GetWide(),
                parentH = self:GetTall(),
                oldLocalX = self.dragState.pnlX,
                oldLocalY = self.dragState.pnlY,
                mouseX = mx,
                mouseY = my,
                screenX = sx,
                screenY = sy,
                localX = nx,
                localY = ny,
            }
            self.draggable:move(pos)
            nx, ny = pos.localX, pos.localY
        end

        -- we've finalized the new position, set it
        self.draggable.panel:SetPos(nx, ny)
        self.dragState.pnlX = nx
        self.dragState.pnlY = ny
        -- update stored mouse pos
        self.dragState.mouseX = mx
        self.dragState.mouseY = my
    end

    -- check if the mouse is in a position where we want to do a scroll
    if mx >= 0 and mx <= self:GetWide() and my >= 0 and my <= self:GetTall() then
        local upper = GetZoneOrDefault(self, self:GetScrollUpZone())
        local lower = GetZoneOrDefault(self, self:GetScrollDownZone())

        local function DoScroll(dir)
            -- if this is set, then the drag started in a scroll region and hasn't left it yet
            if self.dragState.blockScroll then
                return
            end

            local parent = self:GetParent()
            if parent:GetName() == "DScrollPanelTTT2" then
                -- we're in a scroll panel, we can actually do our work
                parent:GetVBar():AddScroll((thinkTime - self.lastThinkTime) * 30 * dir)
            end
        end

        if my <= upper then
            -- need to scroll up in the containing scroll panel
            DoScroll(-1)
        elseif my >= self:GetTall() - lower then
            -- need to scroll up in the containing scroll panel
            DoScroll(1)
        else
            -- cursor is in bounds of the drag region, but not in a scroll region. Unblock
            -- scrolling.
            self.dragState.blockScroll = false
        end
    end

    -- check for trash hovered, and set up shrink animation as appropriate
    if self.draggable.trash then
        local bx, by, bw, bh = self.pnlTrash:GetBounds()

        local animStartTime = thinkTime
        if self.trashAnim then
            local t = math.min((thinkTime - self.trashAnim.startTime) / 0.5, 1)
            t = 1 - t
            animStartTime = thinkTime - (t * 0.5)
        end

        if my > 0 and mx > bx and my > by and mx - bx < bw and my - by < bh then
            if not self.dragState.trashHovered then
                -- in this case, we will be manually painting the panel so we can scale it wihout
                -- resizing
                self.draggable.panel:SetPaintedManually(true)
                self.trashAnim = {
                    startTime = animStartTime,
                    panel = self.draggable.panel,
                    shrink = true,
                    destroyAfter = false,
                    offsX = self.dragState.offsX,
                    offsY = self.dragState.offsY,
                }
            end
            -- mouse is over the visible portion of the trash panel
            self.dragState.trashHovered = true
        else
            -- mouse is NOT over the visible portion of the trash panel
            if self.dragState.trashHovered then
                -- do NOT unset PaintedManually immediately so we can animate it
                self.trashAnim = {
                    startTime = animStartTime,
                    panel = self.draggable.panel,
                    shrink = false,
                    destroyAfter = false,
                    offsX = self.dragState.offsX,
                    offsY = self.dragState.offsY,
                }
            end
            self.dragState.trashHovered = false
        end
    end

    self.lastThinkTime = thinkTime
end

function DDragParent_TTT2PMS:PaintOver(w, h)
    if not self.trashAnim then
        return
    end

    local anim = self.trashAnim

    local tAbs = UnPredictedCurTime() - anim.startTime
    local t = math.min(tAbs / 0.5, 1) -- t = relative time since animation start (capped)

    -- compute the correct scale
    local scaleStart, scaleEnd
    if anim.shrink then
        -- we've started hovering (or have been hovering), so do the ease-in (forward)
        scaleStart = 1
        scaleEnd = 0.6
    else
        -- we're NOT hovering anymore, do the ease-out (backward)
        scaleStart = 0.6
        scaleEnd = 1
    end

    local et = math.ease.InOutSine(t)
    local scale = Lerp(et, scaleStart, scaleEnd)

    -- trash is hovered, and we need to manually render the element
    local mtx = Matrix()
    -- NOTE: All of the matrix modification method POSTMULTIPLY, so the last "operation" happens
    -- FIRST

    local pps = surface.GetPanelPaintState()

    local x, y = anim.panel:GetPos()

    local tr = Vector(pps.translate_x + x - anim.offsX, pps.translate_y + y - anim.offsY, 0)
    tr = tr - (tr * scale)

    mtx:Scale(Vector(scale, scale, 1))
    mtx:SetTranslation(tr)

    PrintTable({ pps, scale, tr })

    -- change the scissor rect to be correct for the projected space
    render.SetScissorRect(
        (pps.scissor_left - tr.x) / scale,
        (pps.scissor_top - tr.y) / scale,
        (pps.scissor_right - tr.x) / scale,
        (pps.scissor_bottom - tr.y) / scale,
        true
    )

    PrintTable(surface.GetPanelPaintState())

    -- actually draw the matrix using the computed matrix
    cam.PushModelMatrix(mtx, true)

    if self:GetDebugShow() then
        local prev = DisableClipping(true)
        draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(255, 255, 255, 63))
        DisableClipping(prev)
    end

    anim.panel:PaintManual(false)

    -- fix scissor rect
    render.SetScissorRect(
        pps.scissor_left,
        pps.scissor_top,
        pps.scissor_right,
        pps.scissor_bottom,
        true
    )

    cam.PopModelMatrix()

    if not anim.shrink and et == 1 then
        -- we've reached the end of the unhover animation, clear SetPaintedManually and
        -- trashHoverTime so we aren't running this logic anymore
        anim.panel:SetPaintedManually(false)
        self.trashAnim = nil
    end

    if anim.destroyAfter and et == 1 then
        anim.panel:Remove()
    end
end

function DDragParent_TTT2PMS:PerformLayout()
    -- this panel's parent is the scroll view which contains the draggable area
    local area = self:GetParent()

    self:SetPos(0, 0)
    self:SetWide(area:GetWide())
    self:SetTall(area:GetTall())
end

function DDragParent_TTT2PMS:Paint(w, h)
    if self:GetDebugShow() then
        draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 63))
    end
end

derma.DefineControl(
    "DDragParent_TTT2PMS",
    "a drag-n-drop parent helper",
    DDragParent_TTT2PMS,
    "DPanelTTT2"
)
