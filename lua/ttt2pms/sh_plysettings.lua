ttt2pms = ttt2pms or {}

if SERVER then
    ---
    ---@param ply Player
    ---@return PlayermodelSettings
    ---@realm server
    function ttt2pms.GetPlayerSettings(ply)
        if not IsValid(ply) or type(ply) ~= "Player" then
            error("ttt2pms.GetPlayerSettings() must take a player")
        end

        return ttt2pms.db.GetOptionsForPlayer(ply)
    end

    ---
    ---@param ply Player|nil
    ---@realm server
    function ttt2pms.SyncPlayerSettings(ply)
        if not ply then
            -- if no player specified, explcit sync to all
            Dev(1, "TTT2PMS: Explicit player settings sync-to-all triggered")
            local plys = player.GetAll()
            for i = 1, #plys do
                ttt2pms.SyncPlayerSettings(plys[i])
            end
            return
        end

        net.SendStream("TTT2PMS_SyncPlayerSettings", ttt2pms.GetPlayerSettings(ply), ply)
    end

    hook.Add("PlayerInitialSpawn", "TTT2PMS_PlayerInitialSpawn", function(ply)
        -- Player is spawning in, sync that player's settings to them
        ttt2pms.SyncPlayerSettings(ply)
    end)

    hook.Remove("Initialize", "TTT2PMS_PlySync")
    hook.Add("Initialize", "TTT2PMS_PlySync", function()
        net.ReceiveStream("TTT2PMS_SyncPlayerSettings", function(plySettings, ply)
            -- client has sent us updated settings for them, store that
            ttt2pms.db.SaveOptionsForPlayer(ply, plySettings)
        end)
    end)
end

if CLIENT then
    ---@type PlayermodelSettings
    local playerSettings

    ---
    ---@return PlayermodelSettings
    ---@realm client
    function ttt2pms.GetPlayerSettings()
        return playerSettings
    end

    ---@realm client
    function ttt2pms.SyncPlayerSettings()
        if not playerSettings then
            return -- do nothing if we haven't received any settings from the server, nor set any ourselves
        end

        net.SendStream("TTT2PMS_SyncPlayerSettings", playerSettings)
    end

    ---
    ---@param settings PlayermodelSettings
    ---@realm client
    function ttt2pms.SetPlayerSettings(settings)
        playerSettings = settings
        ttt2pms.SyncPlayerSettings()
    end

    hook.Remove("Initialize", "TTT2PMS_PlySync")
    hook.Add("Initialize", "TTT2PMS_PlySync", function()
        net.ReceiveStream("TTT2PMS_SyncPlayerSettings", function(plySettings)
            playerSettings = plySettings
        end)
    end)
end
