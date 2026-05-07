---@realm server

-- TODO: move these typedefs over into the ttt2.meta file

---@package
---@class ORM<T>
---@field All fun(self):table<T>
---@field Find fun(self,name:string):T|nil
---@field New fun(self,tbl:table):T
---@field Where fun(self,filters:table):table<T>|nil

---@package
---@class ORMObject
---@field Delete fun(self):boolean
---@field Refresh fun(self):boolean
---@field Save fun(self):boolean
---@field name string the name of the model

local ponEmptyTbl = "[}"

local modelOptionsTblName = "ttt2pms_sv_model_options"
sql.CreateSqlTable(modelOptionsTblName, {
    skin_allowed_pon = { typ = "string", default = ponEmptyTbl },
    skin_distinct_pon = { typ = "string", default = ponEmptyTbl },
    bodygroups_allowed_pon = { typ = "string", default = ponEmptyTbl },
    bodygroups_distinct_pon = { typ = "string", default = ponEmptyTbl },
})
---@type ORM<ModelBodygroupOptionsMdl>
local modelOptionsOrm = orm.Make(modelOptionsTblName)
---@package
---@class ModelBodygroupOptionsMdl: ORMObject
---@field skin_allowed_pon string
---@field skin_distinct_pon string
---@field bodygroups_allowed_pon string
---@field bodygroups_distinct_pon string

local playerSettingsTblName = "ttt2pms_cl_settings"
sql.CreateSqlTable(playerSettingsTblName, {
    globalColor = { typ = "color" },
    defaultColorMode = { typ = "number", default = 0 },

    usePriorityModels = { typ = "boolean", default = false },
    useRandomModels = { typ = "boolean", default = false },

    priorityModels_pon = { typ = "string", default = ponEmptyTbl },
    randomModels_pon = { typ = "string", default = ponEmptyTbl },
})
---@type ORM<PlayerSettingsOrm>
local playerSettingsOrm = orm.Make(playerSettingsTblName)

---@package
---@class PlayerSettingsOrm: ORMObject
---@field name string the SteamID64 of the player this is for
---@field globalColor Color
---@field defaultColorMode PLAYERMODEL_COLOR_MODE
---@field usePriorityModels boolean
---@field useRandomModels boolean
---@field priorityModels_pon string
---@field randomModels_pon string

ttt2pms = ttt2pms or {}
ttt2pms.db = ttt2pms.db or {}

local function ponDecodeMaybeNil(str)
    local res = pon.decode(str)
    if type(res) == "table" and next(res) == nil then
        return nil
    else
        return res
    end
end

---@realm server
---@param orm ModelBodygroupOptionsMdl
---@return PlayermodelServer
local function DecodeBodygroupsOrm(orm)
    return {
        model = orm.name,
        skinAllowed = ponDecodeMaybeNil(orm.skin_allowed_pon),
        skinDistinct = ponDecodeMaybeNil(orm.skin_distinct_pon),
        bodygroupsAllowed = pon.decode(orm.bodygroups_allowed_pon),
        bodygroupsDistinct = pon.decode(orm.bodygroups_distinct_pon),
    }
end

---@realm server
---@param opts PlayermodelServer
---@return ModelBodygroupOptionsMdl
local function EncodeBodygroupsOrm(opts)
    return {
        name = opts.model,
        skin_allowed_pon = opts.skinAllowed and pon.encode(opts.skinAllowed) or ponEmptyTbl,
        skin_distinct_pon = opts.skinDistinct and pon.encode(opts.skinDistinct) or ponEmptyTbl,
        bodygroups_allowed_pon = opts.bodygroupsAllowed and pon.encode(opts.bodygroupsAllowed)
            or ponEmptyTbl,
        bodygroups_distinct_pon = opts.bodygroupsDistinct and pon.encode(opts.bodygroupsDistinct)
            or ponEmptyTbl,
    }
end

local bodygroupModelsTbl

---@realm server
---@return table<string, PlayermodelServer>
function ttt2pms.db.GetModels()
    if not bodygroupModelsTbl then
        ---@type table<ModelBodygroupOptionsMdl>
        local models = modelOptionsOrm:All()

        local result = {}
        for i = 1, #models do
            local orm = models[i]
            result[orm.name] = DecodeBodygroupsOrm(orm)
        end

        bodygroupModelsTbl = result
    end

    return bodygroupModelsTbl
end

---Broadcasts a change in playermodel to players so they can update their cache.
---@param model string
---@param opts PlayermodelServer?
local function BroadcastModelOptionsChange(model, opts)
    net.SendStream(
        "TTT2PMS_Broadcast_PlayermodelOptions",
        ---@type TTT2PMS_Get_PlayermodelOptions_Resp
        {
            model = model,
            opts = opts,
        }
    )
end

---@class TTT2PMS_Get_PlayermodelOptions_Req
---@field model string
---@class TTT2PMS_Get_PlayermodelOptions_Resp
---@field model string
---@field opts PlayermodelServer?

net.ReceiveStream("TTT2PMS_Get_PlayermodelOptions", function(tbl, ply)
    ---@cast tbl TTT2PMS_Get_PlayermodelOptions_Req

    local models = ttt2pms.db.GetModels()
    ---@type PlayermodelServer?
    local data = models[tbl.model]

    net.SendStream(
        "TTT2PMS_Broadcast_PlayermodelOptions",
        ---@type TTT2PMS_Get_PlayermodelOptions_Resp
        {
            model = data and data.model or tbl.model,
            opts = data,
        },
        ply
    )
end)

---@realm server
---@param opts PlayermodelServer
function ttt2pms.db.SetModelOptions(opts)
    local orm = modelOptionsOrm:Find(opts.model)
    if not orm then
        orm = modelOptionsOrm:New(EncodeBodygroupsOrm(opts))
    else
        table.Merge(orm, EncodeBodygroupsOrm(opts))
    end
    orm:Save()

    if bodygroupModelsTbl then
        local clone = table.Copy(opts)
        bodygroupModelsTbl[opts.model] = clone
        BroadcastModelOptionsChange(clone.model, clone)
    end
end

---@realm server
---@param model string
---@return boolean
function ttt2pms.db.DeleteModelOptions(model)
    local orm = modelOptionsOrm:Find(model)
    local success = false
    if orm then
        success = orm:Delete()
    end

    if bodygroupModelsTbl then
        bodygroupModelsTbl[model] = nil
        BroadcastModelOptionsChange(model, nil)
    end

    return success
end

---@realm server
function ttt2pms.db.SaveModelOptions()
    -- we want to save ALL changes in the distinct table.
    if not bodygroupModelsTbl then
        -- if this hasn't been set, then noone called GetBodygroupDistinctModels(), and thus
        -- couldn't have changed it. So, nothing to be done.
        return
    end

    -- otherwise, we want to 1. get a list of all of the DB models, then 2. sync those
    -- appropriately.

    local ormTbl = {}
    for _, v in ipairs(modelOptionsOrm:All()) do
        ormTbl[v.name] = v
    end

    -- before syncing, we want to make sure the keys and values of the distinct table are synced
    local tbl = table.Copy(bodygroupModelsTbl)
    for k, v in pairs(tbl) do
        if k ~= v.model then
            bodygroupModelsTbl[v.model] = table.Merge(bodygroupModelsTbl[v.model] or {}, v, true)
            bodygroupModelsTbl[k] = nil
        end
    end
    tbl = bodygroupModelsTbl

    -- now we're ready to actually sync
    for k, v in pairs(tbl) do
        if ormTbl[k] then
            -- we have an orm for this model
            table.Merge(ormTbl[k], EncodeBodygroupsOrm(v))
            ormTbl[k]:Save()
            -- delete the ORM from the table so we don't delete it later
            ormTbl[k] = nil
        else
            -- we do NOT have an orm for this model, create one
            modelOptionsOrm:New(EncodeBodygroupsOrm(v)):Save()
        end
    end

    -- anything remaining in ormTbl needs to be deleted
    for _, v in pairs(ormTbl) do
        v:Delete()
    end
end

---@realm server
---@param model string
---@param field "distinct"|"allowed"|nil
---@return boolean
function ttt2pms.db.ClearModelSettings(model, field)
    local existing = ttt2pms.db.GetModels()[model]
    if not existing then
        return false
    end

    local pm = table.Copy(existing)
    if field == "allowed" then
        pm.skinAllowed = nil
        pm.bodygroupsAllowed = {}
    elseif field == "distinct" then
        pm.skinDistinct = nil
        pm.bodygroupsDistinct = {}
    elseif field == nil then
        pm.skinAllowed = nil
        pm.bodygroupsAllowed = {}
        pm.skinDistinct = nil
        pm.bodygroupsDistinct = {}
    else
        error("invalid field " .. field)
    end

    ttt2pms.db.SetModelOptions(pm)
    return true
end

---@realm server
---@param field "distinct"|"allowed"|nil
function ttt2pms.db.ClearSettings(field)
    ErrorNoHaltWithStack("TTT2PMS: Deleting all model options " .. field)

    local skinCol, bgCol

    if field == nil then
        sql.Query(string.format("DELETE FROM %s", sql.SQLStr(modelOptionsTblName)))
    elseif field == "distinct" then
        skinCol, bgCol = "skin_distinct_pon", "bodygroups_distinct_pon"
    elseif field == "allowed" then
        skinCol, bgCol = "skin_allowed_pon", "bodygroups_allowed_pon"
    else
        error("invalid field " .. field)
    end

    if skinCol then
        sql.Query(
            string.format(
                "UPDATE %s SET %s = %s, %s = %s",
                sql.SQLStr(modelOptionsTblName),
                skinCol,
                sql.SQLStr(ponEmptyTbl),
                bgCol,
                sql.SQLStr(ponEmptyTbl)
            )
        )
    end

    bodygroupModelsTbl = nil
end

---
---@param args table<string>
---@return table<number, BodygroupServer>
---@return BodygroupServer|nil
local function ParseBodygroupSetCmdArgs(args)
    ---@type table<number,BodygroupServer>
    local bodygroupSettings = {}
    ---@type nil|BodygroupServer
    local skinSettings = nil

    local i = 2
    while i <= #args do
        local bodygroupStr = args[i]
        local bodygroup = tonumber(bodygroupStr)
        i = i + 1
        if bodygroup == nil and bodygroupStr ~= "skin" then
            error("bodygroup specifier '" .. bodygroupStr .. "' must be integer or 'skin'")
        end

        if i > #args then
            error("missing mode of bodygroup '" .. tostring(bodygroup) .. "'")
        end
        local mode = args[i]
        i = i + 1
        if mode ~= "pos" and mode ~= "neg" then
            error(
                "mode of bodygroup "
                    .. tostring(bodygroup)
                    .. " must be one of 'pos' or 'neg', not '"
                    .. mode
                    .. "'"
            )
        end

        if i > #args then
            error("missing values of bodygroup '" .. tostring(bodygroup) .. "'")
        end
        local valuesStr = args[i]
        i = i + 1

        local valuesList = string.Split(valuesStr, ",")
        local valuesInv = {}
        for _, v in ipairs(valuesList) do
            local num = tonumber(v)
            if num == nil then
                error("value '" .. v .. "' must be a number")
            end
            valuesInv[num] = true
        end

        local values = table.GetKeys(valuesInv)
        table.sort(values)

        if bodygroup then
            bodygroupSettings[bodygroup] = { mode = mode, values = values }
        else
            skinSettings = { mode = mode, values = values }
        end
    end
    return bodygroupSettings, skinSettings
end

---@param field "allowed"|"distinct"
local function UpdateModelSettingsForCmd(model, bodygroupSettings, skinSettings, field)
    local existing = ttt2pms.db.GetModels()[model]
    local pm = existing and table.Copy(existing)
        or {
            model = model,
            skinAllowed = nil,
            skinDistinct = nil,
            bodygroupsAllowed = {},
            bodygroupsDistinct = {},
        }

    if field == "allowed" then
        if existing then
            pm.bodygroupsAllowed = table.Copy(existing.bodygroupsAllowed)
        end
        table.Merge(pm.bodygroupsAllowed, bodygroupSettings, true)
        pm.skinAllowed = skinSettings
    else
        if existing then
            pm.bodygroupsDistinct = table.Copy(existing.bodygroupsDistinct)
        end
        table.Merge(pm.bodygroupsDistinct, bodygroupSettings, true)
        pm.skinDistinct = skinSettings
    end

    ttt2pms.db.SetModelOptions(pm)
end

local modelDataCache = {}
---@param model string
---@return {numBodygroups: integer, numSkins: integer, bgCounts: table<number, integer>}?
local function GetModelData(model)
    if not model then
        return nil
    end
    if modelDataCache[model] then
        return modelDataCache[model]
    end

    local mdlPath = player_manager.TranslatePlayerModel(model)
    local mdlInfo = util.GetModelInfo(mdlPath)

    local ent = ents.Create("prop_dynamic")
    if not ent then
        ErrorNoHalt(
            "[TTT2PMS] GetModelData: Failed to create prop_dynamic to get model data for "
                .. mdlPath
        )
        modelDataCache[model] = nil
        return nil
    end

    ent:SetModel(mdlPath)
    ent:Spawn()

    local bgs = ent:GetBodyGroups()
    local skins = mdlInfo.SkinCount

    local data = {
        numBodygroups = #bgs,
        numSkins = skins,
        bgCounts = {},
    }

    for _, bg in ipairs(bgs) do
        data.bgCounts[bg.id] = bg.num
    end

    ent:Remove()

    modelDataCache[model] = data
    return data
end

local function BodygroupSetAutocomplete(cmd, argStr, args)
    -- Determine which argument index we are currently completing.
    -- If the string ends in a space, we are starting a new argument.
    local n = #args
    if n == 0 or string.sub(argStr, -1) == " " then
        n = n + 1
    end

    local options = {}
    local filter = (n <= #args) and args[n] or ""
    local preStr = cmd .. string.sub(argStr, 1, #argStr - #filter)
    if string.sub(preStr, -1) == "\"" then
        preStr = string.sub(preStr, 1, -1)
    end

    -- Case 1: The user is typing the model name.
    if n == 1 then
        local pmodels = ttt2pms.db.GetModels()
        local models = table.GetKeys(pmodels)

        -- for the model name, we also want to add non-specified models (after the specified ones)
        local selected = playermodels.GetSelectedModels()
        for i = 1, #selected do
            local mdl = selected[i] --[[@as string]]
            if not pmodels[mdl] then
                models[#models + 1] = mdl
            end
        end

        local passed = {}
        for _, v in ipairs(args) do
            passed[v] = true
        end

        if filter == "" then
            for _, k in ipairs(models) do
                if not passed[k] then
                    options[#options + 1] = preStr .. "\"" .. k .. "\""
                end
            end
        else
            local InFilter = ttt2pms.util.FilterMatcher(filter)
            for _, k in ipairs(models) do
                if InFilter(k) and not passed[k] then
                    options[#options + 1] = preStr .. "\"" .. k .. "\""
                end
            end
        end
        return options
    -- Case 2: The user is typing a bodygroup ID or the keyword "skin".
    elseif n % 3 == 2 then
        local model = args[1]
        local data = GetModelData(model)
        local possible = { "skin" }
        if data then
            for i = 0, data.numBodygroups - 1 do
                possible[#possible + 1] = tostring(i)
            end
        end
        for _, v in ipairs(possible) do
            if string.StartsWith(v, filter) then
                options[#options + 1] = preStr .. v
            end
        end
        return options
    -- Case 3: The user is typing the mode ("pos" or "neg").
    elseif n % 3 == 0 then
        local possible = { "pos", "neg" }
        for _, v in ipairs(possible) do
            if string.StartsWith(v, filter) then
                options[#options + 1] = preStr .. v
            end
        end
        return options
    -- Case 4: The user is typing the comma-separated list of values.
    elseif n % 3 == 1 then
        local model = args[1]
        local bgSpec = args[n - 2]
        local data = GetModelData(model)

        if not data then
            return {}
        end

        local possible = {}
        if bgSpec == "skin" then
            for i = 0, data.numSkins - 1 do
                possible[#possible + 1] = tostring(i)
            end
        else
            local bgId = tonumber(bgSpec)
            if bgId then
                local valCount = data.bgCounts[bgId] or 0
                for i = 0, valCount - 1 do
                    possible[#possible + 1] = tostring(i)
                end
            end
        end

        if #possible > 0 then
            -- Handle comma-separated lists: we only autocomplete the last segment.
            local parts = string.Split(filter, ",")
            local currentPartial = parts[#parts]
            local entered = {}
            for i = 1, #parts - 1 do
                entered[tonumber(parts[i])] = true
            end

            -- Reconstruct the string up to the current partial match.
            local prefixInArg = ""
            for i = 1, #parts - 1 do
                prefixInArg = prefixInArg .. parts[i] .. ","
            end
            local fullPreStr = preStr .. prefixInArg

            for _, v in ipairs(possible) do
                if not entered[tonumber(v)] and string.StartsWith(v, currentPartial) then
                    options[#options + 1] = fullPreStr .. v
                end
            end
        end
        return options
    end

    -- unreachable
    return options
end

local function ClearModelAutocomplete(cmd, argStr, args)
    local models = ttt2pms.db.GetModels()
    local passed = {}

    for _, v in ipairs(args) do
        passed[v] = true
    end

    local options = {}
    if #args == 0 then
        options[#options + 1] = cmd .. argStr
    end

    if #args == 0 or args[#args] == "" then
        -- user hasn't written anything for this argument yet
        for k, _ in pairs(models) do
            if not passed[k] then
                options[#options + 1] = cmd .. argStr .. "\"" .. k .. "\""
            end
        end
    else
        -- user HAS written something for the argument, do the same as above but with an extra
        -- filter (and trim off what the user wrote, of course...)
        local filter = args[#args]
        local preStr = cmd .. string.sub(argStr, 1, #argStr - string.len(filter))
        if string.sub(preStr, -1) == "\"" then
            preStr = string.sub(preStr, 1, -1)
        end

        local InFilter = ttt2pms.util.FilterMatcher(filter)
        for k, _ in pairs(models) do
            if InFilter(k) and not passed[k] then
                options[#options + 1] = preStr .. "\"" .. k .. "\""
            end
        end
    end

    return options
end

concommand.Add(
    "ttt2_pms_distinct_bodygroups_clear",
    function(ply, cmd, args)
        -- execute
        if not ply:IsSuperAdmin() then
            error("must be admin")
        end
        if #args > 0 then
            -- a list of models were specified
            for _, v in ipairs(args) do
                if ttt2pms.db.ClearModelSettings(v, "distinct") then
                    print("Deleted model bodygroup options for '" .. v .. "'")
                else
                    print(
                        "No bodygroup options configured for model '"
                            .. v
                            .. "' (does the model exist?)"
                    )
                end
            end
        else
            -- nothing was specified, delete everything
            ttt2pms.db.ClearSettings("distinct")
        end
    end,
    ClearModelAutocomplete,
    "Clears the configured \"distinct\" bodygroups options (optionally for a specific model).",
    {}
)

concommand.Add(
    "ttt2_pms_allowed_bodygroups_clear",
    function(ply, cmd, args)
        -- execute
        if not ply:IsSuperAdmin() then
            error("must be admin")
        end
        if #args > 0 then
            for _, v in ipairs(args) do
                if ttt2pms.db.ClearModelSettings(v, "allowed") then
                    print("Cleared allowed bodygroup options for '" .. v .. "'")
                else
                    print("No allowed bodygroup options configured for model '" .. v .. "'")
                end
            end
        else
            ttt2pms.db.ClearSettings("allowed")
        end
    end,
    ClearModelAutocomplete,
    "Clears the configured \"allowed\" bodygroups options (optionally for a specific model).",
    {}
)

concommand.Add("ttt2_pms_distinct_bodygroups_set", function(ply, cmd, args)
    -- execute
    if not ply:IsSuperAdmin() then
        error("must be admin")
    end
    if #args < 1 then
        error(cmd .. " usage: <mdl> (<bodygroup> <mode> <comma separated values>)+")
    end

    local bg, skin = ParseBodygroupSetCmdArgs(args)
    UpdateModelSettingsForCmd(args[1], bg, skin, "distinct")
end, BodygroupSetAutocomplete, "Sets distinct bodygroup settings for a model.", {})

concommand.Add("ttt2_pms_allowed_bodygroups_set", function(ply, cmd, args)
    -- execute
    if not ply:IsSuperAdmin() then
        error("must be admin")
    end
    if #args < 1 then
        error(cmd .. " usage: <mdl> (<bodygroup> <mode> <comma separated values>)+")
    end

    local bg, skin = ParseBodygroupSetCmdArgs(args)
    UpdateModelSettingsForCmd(args[1], bg, skin, "allowed")
end, BodygroupSetAutocomplete, "Sets allowed bodygroup settings for a model.", {})

concommand.Add("ttt2_pms_print_bodygroup_settings", function()
    -- all players are allowed to do this; this isn't secret information

    -- first, print headers
    print("The following concommands will recreate the current bodygroup settings:")
    print(
        "--------------------------------------------------------------------------------------------"
    )
    local models = ttt2pms.db.GetModels()

    -- first, do the allowed set
    print("ttt2_pms_allowed_bodygroups_clear")

    ---
    ---@param type "allowed"|"distinct"
    ---@param mdl string
    ---@param groupName string
    ---@param bgroup BodygroupServer
    local function PrintBgroup(type, mdl, groupName, bgroup)
        print(
            "ttt2_pms_" .. type .. "_bodygroups_set",
            "\"" .. mdl .. "\"",
            groupName,
            bgroup.mode,
            table.concat(bgroup.values, ",")
        )
    end

    for mdl, opts in pairs(models) do
        if opts.skinAllowed then
            PrintBgroup("allowed", mdl, "skin", opts.skinAllowed)
        end
        for id, bgrp in pairs(opts.bodygroupsAllowed) do
            PrintBgroup("allowed", mdl, tostring(id), bgrp)
        end
    end

    -- then the distinct set
    print()
    print("ttt2_pms_distinct_bodygroups_clear")

    for mdl, opts in pairs(models) do
        if opts.skinDistinct then
            PrintBgroup("distinct", mdl, "skin", opts.skinDistinct)
        end
        for id, bgrp in pairs(opts.bodygroupsDistinct) do
            PrintBgroup("distinct", mdl, tostring(id), bgrp)
        end
    end

    print(
        "--------------------------------------------------------------------------------------------"
    )
end, nil, "Print the current bodygroup settings as a set of concommands to reproduce it.", {})

---@param orm PlayerSettingsOrm
---@return PlayermodelSettings
local function DecodePlayerOrm(orm)
    return {
        globalColor = orm.globalColor,
        defaultColorMode = orm.defaultColorMode,
        usePriorityModels = orm.usePriorityModels,
        useRandomModels = orm.useRandomModels,
        priorityModels = pon.decode(orm.priorityModels_pon),
        randomModels = pon.decode(orm.randomModels_pon),
    }
end

---@param sid string
---@param opts PlayermodelSettings
---@return PlayerSettingsOrm
local function EncodePlayerOrm(sid, opts)
    return {
        name = sid,
        globalColor = opts.globalColor,
        defaultColorMode = opts.defaultColorMode,
        usePriorityModels = opts.usePriorityModels,
        useRandomModels = opts.useRandomModels,
        priorityModels_pon = pon.encode(opts.priorityModels),
        randomModels_pon = pon.encode(opts.randomModels),
    }
end

local plyOptionsCache = {}

---@realm server
---
---@param ply Player
---@return PlayermodelSettings
---@realm server
function ttt2pms.db.GetOptionsForPlayer(ply)
    local cached = plyOptionsCache[ply]
    if cached then
        return cached.decoded
    end

    local sid = ply:SteamID64()

    ---@type PlayerSettingsOrm?
    local opts = playerSettingsOrm:Find(sid)
    ---@type PlayermodelSettings
    local resultModel
    if not opts then
        -- player does not have any recorded options, populate a default
        resultModel = {
            globalColor = COLOR_WHITE,
            defaultColorMode = PLAYERMODEL_COLOR_MODE.SERVER,
            usePriorityModels = false,
            priorityModels = {},
            useRandomModels = false,
            randomModels = {},
        }
        opts = playerSettingsOrm:New(EncodePlayerOrm(sid, resultModel))
        opts:Save()
    else
        resultModel = DecodePlayerOrm(opts)
    end

    plyOptionsCache[ply] = {
        orm = opts,
        decoded = resultModel,
    }

    return resultModel
end

---@realm server
---
---@param ply Player
---@param opts PlayermodelSettings
---@realm server
function ttt2pms.db.SaveOptionsForPlayer(ply, opts)
    local cached = plyOptionsCache[ply]
    local orm
    if cached then
        orm = cached.orm
        cached.decoded = table.Copy(opts)
    else
        orm = playerSettingsOrm:New({ name = ply:SteamID64() })
        cached = { orm = orm, decoded = table.Copy(opts) }
        plyOptionsCache[ply] = cached
    end

    orm = table.Merge(orm, EncodePlayerOrm(ply:SteamID64(), opts))
    orm:Save()
end
