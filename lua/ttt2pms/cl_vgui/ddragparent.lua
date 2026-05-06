ttt2pms = ttt2pms or {}
ttt2pms.cl = ttt2pms.cl or {}

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
---@field private originX number
---@field private originY number
local DDragParent_TTT2PMS = {}

AccessorFunc(DDragParent_TTT2PMS, "bDebugShow", "DebugShow", FORCE_BOOL)
AccessorFunc(DDragParent_TTT2PMS, "nTrashHeight", "TrashHeight", FORCE_NUMBER)
AccessorFunc(DDragParent_TTT2PMS, "nScrollUpZone", "ScrollUpZone", FORCE_NUMBER)
AccessorFunc(DDragParent_TTT2PMS, "nScrollDownZone", "ScrollDownZone", FORCE_NUMBER)

---The number of seconds it takes to show or hide the trash area.
local C_TrashShowTime = 0.5
---The number of seconds it takes to grow or shrink the dragged panel when hovering the trash area.
local C_GrowShrinkTime = 0.25
---The factor by which elements shrink when held over the trash area.
local C_ShrinkFactor = 0.6

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
    self.originX = 0
    self.originY = 0

    -- we want an element for the trash zone too. it'll be hidden if we don't have a trash callback
    -- though it won't actually be visible unless TrashCallback is set
    ---@type DPanel
    local trash = self:Add("DPanelTTT2")
    self.pnlTrash = trash
    trash:SetPaintBackground(false)
    trash:SetPaintBackgroundEnabled(false)
    trash:SetVisible(false)
    trash:SetTall(0)
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
---@field screenX number panel X in screen coords
---@field screenY number panel Y in screen coords
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
---@field finish fun(self,pos:DDragParent_Position,doneAnimating:fun()):boolean? Called when the dragged panel is
---                                                 dropped. If this does not reparent pnl, pnl
---                                                 will be removed. The Dock state of the panel
---                                                 is reset at start, so must be re-Docked if needed.
---                                                 If this returns TRUE, the reparent of pnl is
---                                                 suppressed, and the DDragParent remains above
---                                                 everything else until doneAnimating is called,
---                                                 at which point the reparent/remove check is repeated.
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
        self.pnlTrash:SetWide(self:GetWide())
        self.pnlTrash:SetPos(0, self.originY - self.nTrashHeight)
        self.pnlTrash:SetAnimationEnabled(true)
        self.pnlTrash:MoveTo(0, self.originY, C_TrashShowTime, 0, 0.5)
    end
end

---
---@param anim AnimationData
---@param panel Panel
---@param t number
local function MoveThinkBasic(anim, panel, t)
    if not anim.StartPos then
        anim.StartPos = Vector(panel:GetX(), panel:GetY(), 0)
    end
    local pos = LerpVector(t, anim.StartPos, anim.Pos)
    panel:SetPos(pos.x, pos.y)
end

---@package
---@class RelTargetAnimData : AnimationData
---@field RelOffs? Vector
---@field TargetAnim? AnimationData
---@field RelPanel? Panel should be set only when this anim is done and the panel's position needs
---to be updated directly

---
---@param anim RelTargetAnimData
---@param panel Panel
---@param t number
local function MoveThinkRelTarget(anim, panel, t)
    if not anim.StartPos then
        anim.StartPos = Vector(panel:GetX(), panel:GetY(), 0)
    end
    local pos = LerpVector(t, anim.StartPos, anim.Pos)
    panel:SetPos(pos.x, pos.y)

    if anim.RelOffs then
        local relPos = pos + anim.RelOffs
        if anim.TargetAnim then
            anim.TargetAnim.Pos = relPos
        end
        if anim.RelPanel then
            anim.RelPanel:SetPos(relPos.x, relPos.y)
        end
    end
end

---
---@param rta RelTargetAnimData
---@param anim AnimationData
local function DelayAnimEndByRelTargetAnim(rta, anim)
    local animOnEnd = anim.OnEnd
    local rtaOnEnd = rta.OnEnd
    local endCounter = 0
    local animPanel, rtaPanel

    local function MaybeInvokeAnimEnded()
        endCounter = endCounter + 1
        if endCounter == 2 then
            animOnEnd(anim, animPanel)
            rtaOnEnd(rta, rtaPanel)
        end
    end

    anim.OnEnd = function(_, panel)
        rta.RelPanel = panel
        animPanel = panel
        MaybeInvokeAnimEnded()
    end

    rta.OnEnd = function(_, panel)
        rtaPanel = panel
        MaybeInvokeAnimEnded()
    end

    rta.TargetAnim = anim
end

function DDragParent_TTT2PMS:EndDrag()
    if not self.draggable or not self.dragState.dragging then
        return
    end

    self.dragState.dragging = false

    local requiredDecrs = 1
    local function DecrAndFinishDrag()
        requiredDecrs = requiredDecrs - 1
        if requiredDecrs == 0 then
            self:SetZPos(-32768)
            self.draggable = nil
            self.dragState = nil
        end
    end

    if self.dragState.trashHovered then
        -- the drag finished while the trash was hovered
        self.draggable:trash()
    else
        -- the drag finished while the trash was NOT hovered
        local px, py = self.draggable.panel:GetPos()
        local mx, my = self.dragState.mouseX, self.dragState.mouseY
        local sx, sy = self:LocalToScreen(px, py)
        local nx, ny = mx + self.dragState.offsX, my + self.dragState.offsY

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

        local panel = self.draggable.panel

        local function AnimateDone()
            -- if the finish function didn't reparent, hide and destroy the panel ourselves
            if panel and panel:GetParent() == self then
                panel:SetVisible(false)
                panel:Remove()
            end

            DecrAndFinishDrag()
        end
        requiredDecrs = requiredDecrs + 1

        local waitForAnimate = self.draggable:finish(pos, AnimateDone)
        if not waitForAnimate then
            AnimateDone()
        end
    end

    -- hide the trash panel
    if self.draggable.trash then
        ---@type RelTargetAnimData
        local tranim = self.pnlTrash:NewAnimation(C_TrashShowTime, 0, 2, function(_, pnl)
            pnl:SetVisible(false)
            pnl:SetTall(0)

            DecrAndFinishDrag()
        end)
        requiredDecrs = requiredDecrs + 1
        tranim.Pos = Vector(0, self.originY - self.nTrashHeight)
        tranim.Think = MoveThinkRelTarget

        if self.dragState.trashHovered then
            -- need to animate the dragged panel too
            local x, y = self.draggable.panel:GetPos()
            local w, h = self.draggable.panel:GetSize()
            local W, H = self.pnlTrash:GetSize()

            -- this panel will be moved to a position relative to the trash. It will be maintained
            -- by the MoveThinkRelTarget animation above. Thus, we need the actual position delta.
            -- We want to place this panel in the center of the trash, so that's what we actually
            -- want to compute.
            local visw = w * C_ShrinkFactor
            local visx = (W - visw) / 2
            local adjOffsX = (1 - C_ShrinkFactor) * self.trashAnim.offsX

            local vish = h * C_ShrinkFactor
            local visy = (H - vish) / 2

            -- if the dragged panel is actually taller than the trash panel, (visually) then we'll
            -- push it way above the trash panel so that it is off-screen when needed
            if visy < ttt2pms.cl.plyModelRowVPadding then
                visy = -(vish - H + ttt2pms.cl.plyModelRowVPadding)
            end

            local adjOffsY = (1 - C_ShrinkFactor) * self.trashAnim.offsY

            local tx = visx + adjOffsX
            local ty = visy + adjOffsY

            tranim.RelOffs = Vector(tx, ty)

            local pnlAnim = self.draggable.panel:NewAnimation(
                3 * C_TrashShowTime / 4,
                0,
                -1,
                function(_, pnl)
                    -- destroy the animation state if its still present
                    if self.trashAnim and self.trashAnim.panel == pnl then
                        self.trashAnim = nil
                    end
                    -- and destroy the panel itself
                    pnl:Remove()
                end
            )
            pnlAnim.Think = MoveThinkBasic
            pnlAnim.StartPos = Vector(x, y)
            pnlAnim.Pos = Vector(x, y) -- default target vector to current pos; it'll be fixed by the first think on tranim

            -- this actually wires up the anims to be linked
            DelayAnimEndByRelTargetAnim(tranim, pnlAnim)
        else
            self.trashAnim = nil
        end
    end

    DecrAndFinishDrag()
end

function DDragParent_TTT2PMS:CancelDrag()
    if not self.draggable or not self.dragState.dragging then
        return
    end

    ErrorNoHaltWithStack("Drag was canceled!")

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

    local thinkTime = RealTime()

    -- if we're currently dragging, we need to update the dragged panel positioning
    local isx, isy = input.GetCursorPos()
    local mx, my = self:ScreenToLocal(isx, isy)

    if mx ~= self.dragState.mouseX or my ~= self.dragState.mouseY then
        -- the mouse moved since the last time we noticed, do a move update
        local nx, ny = mx + self.dragState.offsX, my + self.dragState.offsY

        local sx, sy = self:LocalToScreen(self.dragState.pnlX, self.dragState.pnlY)

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

    -- check for trash hovered, and set up shrink animation as appropriate
    if self.draggable.trash then
        local bx, by, bw, bh = self.pnlTrash:GetBounds()

        local animStartTime = thinkTime
        if self.trashAnim then
            local t = math.min((thinkTime - self.trashAnim.startTime) / C_GrowShrinkTime, 1)
            t = 1 - t
            animStartTime = thinkTime - (t * C_GrowShrinkTime)
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

    -- check if the mouse is in a position where we want to do a scroll
    if
        not self.dragState.trashHovered
        and mx >= 0
        and mx <= self:GetWide()
        and my >= 0
        and my <= self:GetTall()
    then
        local upper = GetZoneOrDefault(self, self:GetScrollUpZone())
        local lower = GetZoneOrDefault(self, self:GetScrollDownZone())

        local function DoScroll(dir)
            -- if this is set, then the drag started in a scroll region and hasn't left it yet
            if self.dragState.blockScroll then
                return
            end

            local parent = self:GetParent()
            if parent:GetName() == "DScrollPanelTTT2" then
                ---@cast parent DScrollPanelTTT2
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

    self.lastThinkTime = thinkTime
end

ttt2pms.cl.pow2RenderTargets = ttt2pms.cl.pow2RenderTargets or {}
local pow2RenderTargets = ttt2pms.cl.pow2RenderTargets

---
---@param n number
---@return number
local function NextPow2(n)
    n = math.ceil(n) -- float -> integer (round up)
    if n <= 0 then
        return 1
    end

    n = n - 1
    n = bit.bor(n, bit.rshift(n, 1))
    n = bit.bor(n, bit.rshift(n, 2))
    n = bit.bor(n, bit.rshift(n, 4))
    n = bit.bor(n, bit.rshift(n, 8))
    n = bit.bor(n, bit.rshift(n, 16))
    return n + 1
end

---Gets a render target for a given size (rounding up, ofc)
---@param w number
---@param h number
---@return ITexture renderTarget a rendertarget capable of holding a frame that's wxh
---@return IMaterial material an IMaterial referencing the RT
local function GetFrameRenderTarget(w, h)
    w = NextPow2(w)
    h = NextPow2(h)

    local hdict = pow2RenderTargets[w] or {}
    pow2RenderTargets[w] = hdict

    local d = hdict[h] or {}
    hdict[h] = d

    if not d.rt then
        d.rt = GetRenderTargetEx(
            "TTT2PMS_DDragParent_PanelRT_" .. w .. "x" .. h,
            w,
            h,
            RT_SIZE_DEFAULT,
            MATERIAL_RT_DEPTH_SEPARATE,
            ---@diagnostic disable-next-line
            40976,
            CREATERENDERTARGETFLAGS_AUTOMIPMAP,
            IMAGE_FORMAT_RGBA8888
        )
        d.mat = CreateMaterial(d.rt:GetName() .. "_Mat", "UnlitGeneric", {
            ["$basetexture"] = d.rt:GetName(),
            ["$ignorez"] = 1,
            ["$translucent"] = 1,
            ["$smooth"] = 0,
        })
    end
    return d.rt, d.mat
end

function DDragParent_TTT2PMS:PaintOver(w, h)
    if not self.trashAnim then
        return
    end

    local anim = self.trashAnim

    local tAbs = RealTime() - anim.startTime
    local t = math.min(tAbs / C_GrowShrinkTime, 1) -- t = relative time since animation start (capped)

    -- compute the correct scale
    local scaleStart, scaleEnd
    if anim.shrink then
        -- we've started hovering (or have been hovering), so do the ease-in (forward)
        scaleStart = 1
        scaleEnd = C_ShrinkFactor
    else
        -- we're NOT hovering anymore, do the ease-out (backward)
        scaleStart = C_ShrinkFactor
        scaleEnd = 1
    end

    local et = math.ease.InOutSine(t)
    local scale = Lerp(et, scaleStart, scaleEnd)

    local pps = surface.GetPanelPaintState()

    -- trash is hovered, and we need to manually render the element
    -- we'll render it to an RT of appropriate size, then draw that RT back to the screen.
    -- Trying to render directly is plagued by issues with some elements not properly respecting the
    -- view transform, and the engine being really weird about clipping and scissoring.

    local x, y = anim.panel:GetPos()
    local pw, ph = anim.panel:GetSize()
    local rt, mat = GetFrameRenderTarget(pw, ph)

    render.PushRenderTarget(rt, 0, 0, pw, ph)
    render.Clear(0, 0, 0, 0, true, true)
    cam.Start2D()

    local tmat = Matrix()
    tmat:SetTranslation(Vector(-pps.translate_x - x, -pps.translate_y - y, 0))
    cam.PushModelMatrix(tmat, true)

    local oldClipping = DisableClipping(true)
    anim.panel:PaintManual(true)
    DisableClipping(oldClipping)

    cam.PopModelMatrix()
    cam.End2D()
    render.PopRenderTarget()

    local tr = Vector(pps.translate_x + x - anim.offsX, pps.translate_y + y - anim.offsY, 0)
    tr = tr - (tr * scale)

    local mtx = Matrix()
    mtx:Scale(Vector(scale, scale, 1))
    mtx:SetTranslation(tr)

    -- actually draw the matrix using the computed matrix
    cam.PushModelMatrix(mtx, true)

    -- manually enable clipping for our scaled setup
    render.SetScissorRect(
        pps.scissor_left,
        pps.scissor_top,
        pps.scissor_right,
        pps.scissor_bottom,
        true
        --false
    )

    if self:GetDebugShow() then
        local prev = DisableClipping(true)
        draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(255, 255, 255, 63))
        DisableClipping(prev)
    end

    surface.SetMaterial(mat)
    oldClipping = DisableClipping(true)
    surface.DrawTexturedRectUV(
        x,
        y,
        pw,
        ph,
        0,
        0,
        pw / rt:GetMappingWidth(),
        ph / rt:GetMappingHeight()
    )
    DisableClipping(oldClipping)

    -- remove the scissor rect again
    render.SetScissorRect(
        pps.scissor_left,
        pps.scissor_top,
        pps.scissor_right,
        pps.scissor_bottom,
        false
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
    local w, h = self:GetParent():GetSize()
    local w2 = w -- / C_ShrinkFactor
    local h2 = h -- / C_ShrinkFactor

    local x = (w - w2) / 2
    local y = (h - h2) / 2

    self:SetPos(x, y)
    self:SetSize(w2, h2)

    self.originX = -x
    self.originY = -y
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

---Find the containing DScrollPanelTTT2 of pnl.
---@param pnl Panel the panel to find a scrolling parent of
---@return DScrollPanelTTT2? scrollPanel the parent DScrollPanelTTT2
---@return Panel lastChecked the last found parent panel checked
function ttt2pms.cl.FindParentScrollPanel(pnl)
    local lastChecked = pnl
    while pnl and pnl:GetName() ~= "DScrollPanelTTT2" do
        lastChecked = pnl
        pnl = pnl:GetParent()
        ---@cast pnl +?
    end

    ---@cast pnl DScrollPanelTTT2
    ---@cast pnl +?
    return pnl, lastChecked
end

---Finds a DDragParent_TTT2PMS which is a child of `pnl`.
---@param pnl Panel the panel whose children will be searched
---@return DDragParent_TTT2PMS? dragParent the located drag parent
function ttt2pms.cl.FindDragParentIn(pnl)
    local children = pnl:GetChildren()
    for i = 1, #children do
        local child = children[i]

        if child and child:GetName() == "DDragParent_TTT2PMS" then
            return child
        end
    end

    return nil
end

---Gets or creates a DDragParent_TTT2PMS parented (directly) to `parent`.
---@param parent Panel the parent panel of the drag parent
---@return DDragParent_TTT2PMS panel the found or created drag parent
function ttt2pms.cl.GetOrCreateDragParent(parent)
    -- first, search children
    local dragParent = ttt2pms.cl.FindDragParentIn(parent)
    if dragParent then
        return dragParent
    end

    -- no drag parent was found
    local parentIsScrollPanel = parent:GetName() == "DScrollPanelTTT2"

    -- if we're parenting to a scroll panel, we want the drag parent to be *directly* under the
    -- scroll panel itself, and *not* in its content panel. Thus, this rigamarole.
    local scrollPanelOnChildAdded
    if parentIsScrollPanel then
        ---@cast parent DScrollPanelTTT2
        scrollPanelOnChildAdded = parent.OnChildAdded
        parent.OnChildAdded = function() end
    end

    dragParent = vgui.Create("DDragParent_TTT2PMS", parent)

    if parentIsScrollPanel then
        parent.OnChildAdded = scrollPanelOnChildAdded
    end

    return dragParent
end

---Locates the nearest DDragParent_TTT2PMS in `pnl`'s heirarchy
---@param pnl Panel the panel to locate the drag parent for
---@return DDragParent_TTT2PMS? panel the located drag parent, if any
function ttt2pms.cl.FindNearestDragParent(pnl)
    while pnl do
        local res = ttt2pms.cl.FindDragParentIn(pnl)
        if res then
            return res
        end

        pnl = pnl:GetParent()
    end
end

---Gets or creates the best drag parent for the target panel.
---This is the nearest one (where it is a child of some ancestor of pnl), or if one doesn't exist,
---one is created in the nearest ancestor scroll panel, and if no ancestor scroll panel exists, one
---is created in the root.
---@param pnl Panel the panel to get a drag parent for
---@return DDragParent_TTT2PMS dragParent the located drag parent
function ttt2pms.cl.GetBestDragParent(pnl)
    -- first, search for a drag parent up the heirarchy
    local dragParent = ttt2pms.cl.FindNearestDragParent(pnl)
    if dragParent then
        return dragParent
    end

    -- if none were found, lets try to create one. We'll try to put it in the nearest containing
    -- scroll panel, if present; otherwise, the outermost panel found.
    local scroll, last = ttt2pms.cl.FindParentScrollPanel(pnl)
    local chosenParent = scroll or last

    return ttt2pms.cl.GetOrCreateDragParent(chosenParent)
end
