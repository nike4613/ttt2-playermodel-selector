--- @ignore

CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.priority = 99
CLGAMEMODESUBMENU.title = "submenu_customization_selector"

---@package
---@class _P_ListItem
---@field model Playermodel

function CLGAMEMODESUBMENU:Populate(parent)
    local form = vgui.CreateTTT2Form(parent, "header_customization_selector_form1")

    local scrollParent = ttt2pms.cl.FindParentScrollPanel(parent)
    if not scrollParent then
        error("could not find containing scroll parent")
    end
    local dragParent = ttt2pms.cl.GetOrCreateDragParent(scrollParent)

    ---@type DDragList_TTT2PMS<_P_ListItem>
    local dragList = vgui.Create("DDragList_TTT2PMS", form)
    dragList:SetFitWidth(false)
    dragList:SetDragParent(dragParent)
    dragList:SetCallbacks({
        itemFactory = function(p, hnd, item)
            local slot = vgui.Create("DPlyModelDropCell_TTT2PMS", p)
            slot:Dock(TOP)
            slot:SetZPos(-1024)

            local row = vgui.Create("DPlyModelRow_TTT2PMS", slot)
            row:Dock(FILL)

            row:SetPlayerModel(item.model)
            row:SetUserSettings({
                defaultColorMode = PLAYERMODEL_COLOR_MODE.SERVER,
                globalColor = COLOR_WHITE,

                usePriorityModels = false,
                priorityModels = {},
                useRandomModels = false,
                randomModels = {},
            }, COLOR_BLACK)
            row:SetZPos(1024)

            ---@return _P_ListItem
            function row:CreateDuplicateListValue()
                return {
                    model = table.Copy(self:GetPlayerModel() --[[@as Playermodel]]),
                }
            end
            row:SetDragList(dragList, hnd)

            row:InvalidateLayout(true)
            slot:SetTall(row:GetTall())

            --[[
            --- @diagnostic disable-next-line
            function row:OnMousePressed(keyCode)
                if keyCode ~= MOUSE_LEFT then
                    return
                end
                dragList:StartDrag(hnd, keyCode, true)
            end
            ]]

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
    for n, mdl in pairs(pmodels) do
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

        ---@type _P_ListItem
        local it = {
            model = {
                model = n,
                colorMode = PLAYERMODEL_COLOR_MODE.RANDOM,
                color = plyColor,
                skin = skin,
                bodygroups = bodygroups,
            },
        }

        dragList:AddItem(it)
    end

    local skin = { random = true }
    local bodygroups = {}
    for i = 1, LocalPlayer():GetNumBodyGroups() do
        bodygroups[i] = { random = true }
    end

    ---@type _P_ListItem
    local it = {
        model = {
            model = player_manager.TranslateToPlayerModelName(
                LocalPlayer():GetModel() --[[@as string]]
            ),
            colorMode = PLAYERMODEL_COLOR_MODE.RANDOM,
            color = plyColor,
            skin = skin,
            bodygroups = bodygroups,
        },
    }

    dragList:AddItem(it)

    if testent then
        testent:Remove()
    end

    form:MakeButton({
        label = "create model selection popup",
        buttonLabel = "Select Model",
        OnClick = function()
            ttt2pms.cl.ShowModelSelectPopup({
                initialModel = it.model,
                serverColor = COLOR_WHITE,
                userSettings = {
                    defaultColorMode = PLAYERMODEL_COLOR_MODE.SERVER,
                    globalColor = COLOR_BLACK,
                    usePriorityModels = false,
                    priorityModels = {},
                    useRandomModels = false,
                    randomModels = {},
                },
            })
        end,
    })
end
