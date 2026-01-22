--- @ignore

CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.priority = 99
CLGAMEMODESUBMENU.title = "submenu_customization_selector"

function CLGAMEMODESUBMENU:Populate(parent)
    local form = vgui.CreateTTT2Form(parent, "header_customization_selector_form1")

    for i = 1, 5 do
        ---@type DPlyModelRow_TTT2PMS
        local row = vgui.Create("DPlyModelRow_TTT2PMS", form)
        form:AddItem(row)
        row:SetModel(LocalPlayer():GetModel())
        local plyColor = ttt2pms.util.Vec2Col(LocalPlayer():GetPlayerColor())
        row:SetPlayerColor(plyColor)
        if i == 2 then
            row:SetDisplayColor(nil)
        else
            row:SetDisplayColor(plyColor)
        end

        local skin = LocalPlayer():GetSkin()
        local bodygroups = ttt2pms.util.GetBodygroupTbl(LocalPlayer())

        local skin2 = { random = math.random() < 0.5, value = skin }
        local bodygroups2 = {}
        for k, v in pairs(bodygroups) do
            bodygroups2[k] = { random = math.random() < 0.5, value = v }
        end

        row:SetBodygroups(skin2, bodygroups2)
    end
end
