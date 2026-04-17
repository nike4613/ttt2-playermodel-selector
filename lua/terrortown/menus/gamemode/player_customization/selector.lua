--- @ignore

CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.priority = 99
CLGAMEMODESUBMENU.title = "submenu_customization_selector"

---@class _P_ListItem
---@field model string
---@field color? Color
---@field skin number|BodygroupSettings
---@field bodygroups table<number, number|BodygroupSettings>

function CLGAMEMODESUBMENU:Populate(parent)
    local form = vgui.CreateTTT2Form(parent, "header_customization_selector_form1")

    local scrollParent = ttt2pms.cl.FindParentScrollPanel(parent)
    if not scrollParent then
        error("could not find containing scroll parent")
    end
    local dragParent = ttt2pms.cl.GetOrCreateDragParent(scrollParent)

    ---@type DDragList_TTT2PMS
    local dragList = vgui.Create("DDragList_TTT2PMS", form)
    dragList:SetFitWidth(false)
    dragList:SetDragParent(dragParent)
    dragList:SetCallbacks({
        itemFactory = function(p, hnd, item)
            ---@type _P_ListItem
            item = item

            local slot = vgui.Create("DPlyModelDropCell_TTT2PMS", p)
            print("CB <- p.wide=" .. p:GetWide())
            slot:Dock(TOP)
            slot:SetZPos(-1024)

            local row = vgui.Create("DPlyModelRow_TTT2PMS", slot)
            row:Dock(FILL)

            row:SetModel(item.model)
            row:SetPlayerColor(item.color)
            row:SetDisplayColor(item.color)
            row:SetBodygroups(item.skin, item.bodygroups)
            row:SetZPos(1024)

            row:InvalidateLayout(true)
            slot:SetTall(row:GetTall())

            --- @diagnostic disable-next-line
            function row:OnMousePressed(keyCode)
                if keyCode ~= MOUSE_LEFT then
                    return
                end
                dragList:StartDrag(hnd, keyCode, true)
            end

            return slot, row
        end,

        ParentItemToSlot = function(_, slot, pnl)
            pnl:SetParent(slot)
            pnl:Dock(FILL)
        end,

        changed = function(list)
            print("drag list changed (by user). now:")
            for i, it in list:IIter() do
                PrintTable({ i, it })
            end
        end,
    })
    dragList:Dock(TOP)
    dragList:SetPadding(ttt2pms.cl.plyModelRowVPadding)

    local plyColor = ttt2pms.util.Vec2Col(LocalPlayer():GetPlayerColor())

    local pmodels = player_manager.AllValidModels()
    local testent

    local k = 1
    for _, mdl in pairs(pmodels) do
        if k > 5 then
            break
        end
        k = k + 1

        if not testent then
            testent = ClientsideModel(mdl, RENDERGROUP_OTHER)
        end
        if not testent then
            error("Could not create clientside entity to get bodygroups")
        end
        testent:SetModel(mdl)

        local skin = { random = true }
        local bodygroups = {}
        for i = 1, testent:GetNumBodyGroups() do
            bodygroups[i] = { random = true }
        end

        dragList:AddItem({
            model = mdl,
            color = plyColor,
            skin = skin,
            bodygroups = bodygroups,
        })
    end

    if testent then
        testent:Remove()
    end

    --[[
    for i = 1, 5 do
        local plyColor = ttt2pms.util.Vec2Col(LocalPlayer():GetPlayerColor())
        local skin = LocalPlayer():GetSkin()
        local bodygroups = ttt2pms.util.GetBodygroupTbl(LocalPlayer())

        local skin2 = { random = math.random() < 0.5, value = skin }
        local bodygroups2 = {}
        for k, v in pairs(bodygroups) do
            bodygroups2[k] = { random = math.random() < 0.5, value = v }
        end

        ---@type _P_ListItem
        local it = {
            model = LocalPlayer():GetModel(),
            color = plyColor,
            skin = skin2,
            bodygroups = bodygroups2,
        }

        dragList:AddItem(it)
    end
    --]]

    dragList:PerformLayout()
end
