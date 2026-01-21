if engine.ActiveGamemode() ~= "terrortown" then
    error("engine.ActiveGamemode() =" .. engine.ActiveGamemode())
    return
end

local function include_cl(filename)
    if CLIENT then
        include(filename)
    else
        AddCSLuaFile(filename)
    end
end

local function include_sh(filename)
    if SERVER then
        AddCSLuaFile(filename)
    end
    include(filename)
end

local function include_sv(filename)
    if SERVER then
        include(filename)
    end
end

if SERVER then
    AddCSLuaFile()
end

include_sh("ttt2pms/types.lua")
include_sh("ttt2pms/sh_convars.lua")
include_sh("ttt2pms/sh_util.lua")
include_sv("ttt2pms/sv_database.lua")
include_sh("ttt2pms/sh_plysettings.lua")

include_cl("ttt2pms/cl_vskin.lua")

local function LoadVgui()
    print("TTT2PMS: Reloading VGUI")
    include_cl("ttt2pms/cl_vgui/dplymodelrow.lua")
end
LoadVgui()
hook.Add("OnReloaded", "TTT2PMS_Vgui", LoadVgui)
