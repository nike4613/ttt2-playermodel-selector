if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("ttt2pms/types.lua")
    AddCSLuaFile("ttt2pms/sh_convars.lua")
    AddCSLuaFile("ttt2pms/sh_plysettings.lua")
end

include("ttt2pms/types.lua")
include("ttt2pms/sh_convars.lua")
include("ttt2pms/sh_plysettings.lua")

if SERVER then
    include("ttt2pms/sv_database.lua")
end

if CLIENT then
end
