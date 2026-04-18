---@class DModelPanel_TTT2PMS : DModelPanel
---@field private Entity Entity
---@field private aLookAngle Angle
---@field private vLookatPos Vector
---@field private vCamPos Vector
---@field private fFOV number
---@field private FarZ number
---@field private colAmbientLight Color
---@field private colColor Color
---@field private DirectionalLight table<Color>
---@field private LayoutEntity fun(self:DModelPanel_TTT2PMS, ent:Entity)
local DModelPanel_TTT2PMS = {}

function DModelPanel_TTT2PMS:Init()
    local DModelPanel = vgui.GetControlTable("DModelPanel")
    DModelPanel.Init(self)
end

function DModelPanel_TTT2PMS:DrawModel()
    --[[
	-- Get the panel's scissor rect, and apply it to model render
	if ( surface.GetScissorRect ) then
		local enabled, leftx, topy, rightx, bottomy = surface.GetScissorRect()
		render.ClearDepth( false )
		render.SetScissorRect( leftx, topy, rightx, bottomy, enabled )
	else
        ---@type PanelPaintState
        local pps = surface.GetPanelPaintState()
		render.ClearDepth( false )
		render.SetScissorRect(pps.scissor_left, pps.scissor_top, pps.scissor_right, pps.scissor_bottom, pps.scissor_enabled )
	end
    --]]

    local ret = self:PreDrawModel(self.Entity)
    if ret ~= false then
        self.Entity:DrawModel()

        self:PostDrawModel(self.Entity)
    end

    --render.SetScissorRect(0, 0, 0, 0, false)
end

---
---Called before the view entity is drawn to test if it should be.
---In the 3D rendering context.
---@param ent Entity the entity about to be drawn
---@return boolean `false` to suppress rendering of the entity; any other value to allow it
function DModelPanel_TTT2PMS:PreDrawModel(ent)
    return true
end

---
---Called after an entity has been drawn, while in the 3D rendering context
---@param ent Entity the entity that was just drawn
function DModelPanel_TTT2PMS:PostDrawModel(ent) end

---
---@param w number
---@param h number
function DModelPanel_TTT2PMS:Paint(w, h)
    if not IsValid(self.Entity) then
        return
    end

    local x, y = self:LocalToScreen(0, 0)

    self:LayoutEntity(self.Entity)

    local ang = self.aLookAngle
    if not ang then
        ang = (self.vLookatPos - self.vCamPos):Angle()
    end

    -- copy the current render transform from the 2D context into the 3D context
    local matrix = cam.GetModelMatrix()

    local x1 = Vector(x, y)
    local x2 = x1 + Vector(w, h)
    x1 = matrix * x1
    x2 = matrix * x2
    x2 = x2 - x1

    local enabled, leftx, topy, rightx, bottomy = surface.GetScissorRect()
    render.ClearDepth(true)
    local a1 = matrix * Vector(leftx, topy)
    local a2 = matrix * Vector(rightx, bottomy)

    render.SetScissorRect(a1.x, a1.y, a2.x, a2.y, true)

    cam.Start3D(self.vCamPos, ang, self.fFOV, x1.x, x1.y, x2.x, x2.y, 5, self.FarZ)
    --render.SetScissorRect(a1.x, a1.y, a2.x, a2.y, true)

    render.SuppressEngineLighting(true)
    render.SetLightingOrigin(self.Entity:GetPos())
    render.ResetModelLighting(
        self.colAmbientLight.r / 255,
        self.colAmbientLight.g / 255,
        self.colAmbientLight.b / 255
    )
    render.SetColorModulation(self.colColor.r / 255, self.colColor.g / 255, self.colColor.b / 255)
    --render.SetBlend((self:GetAlpha() / 255) * (self.colColor.a / 255)) -- * surface.GetAlphaMultiplier()

    for i = 0, 6 do
        local col = self.DirectionalLight[i]
        if col then
            render.SetModelLighting(i, col.r / 255, col.g / 255, col.b / 255)
        end
    end

    render.SetStencilEnable(true)
    render.SetStencilTestMask(255)
    render.SetStencilWriteMask(255)
    render.SetStencilReferenceValue(255)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)

    -- draw with stencil enabled and alpha written. we'll use the stencil in a mo to reset alpha properly
    self:DrawModel()

    render.SetStencilEnable(false)

    render.SuppressEngineLighting(false)

    cam.End3D()

    -- now we use the stencil to reset the alpha of the drawn model
    render.SetStencilEnable(true)
    render.SetStencilTestMask(255)
    render.SetStencilWriteMask(255)
    render.SetStencilReferenceValue(255)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)

    render.OverrideBlend(
        true,
        BLEND_ZERO,
        BLEND_ONE,
        BLENDFUNC_ADD,
        BLEND_ONE,
        BLEND_ZERO,
        BLENDFUNC_ADD
    )

    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

    render.OverrideBlend(false)

    render.SetStencilEnable(false)

    self.LastPaint = RealTime()
end

derma.DefineControl(
    "DModelPanel_TTT2PMS",
    "a DModelPanel that is better behaved in advanced rendering scenarios",
    DModelPanel_TTT2PMS,
    "DModelPanel"
)
