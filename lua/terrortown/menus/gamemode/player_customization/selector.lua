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

        local skin = LocalPlayer():GetSkin()
        local bodygroups = {}
        for i = 0, LocalPlayer():GetNumBodyGroups() - 1 do
            bodygroups[i] = LocalPlayer():GetBodygroup(i)
        end
        row:SetBodygroups(skin, bodygroups)
    end
end
