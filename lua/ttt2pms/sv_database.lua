---@realm server

---@class ORM<T>
---@field All fun(self):table<T>
---@field Find fun(self,name:string):T|nil
---@field New fun(self,tbl:table):T
---@field Where fun(self,filters:table):table<T>|nil

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
        bodygroupModelsTbl[opts.model] = table.Copy(opts)
    end
end

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
    end

    return success
end

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
        local values = {}
        for _, v in ipairs(valuesList) do
            local num = tonumber(v)
            if num == nil then
                error("value '" .. v .. "' must be a number")
            end
            values[#values + 1] = num
        end

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

local function BodygroupSetAutocomplete(cmd, argStr, args)
    local count = #args
    if count == 0 then
        local models = ttt2pms.db.GetModels()
        local options = {}
        for k, _ in pairs(models) do
            options[#options + 1] = argStr .. " \"" .. k .. "\""
        end
        return options
    end

    local rem = count % 3
    if rem == 1 then
        return { argStr .. " \"skin\"" }
    elseif rem == 2 then
        return { argStr .. " \"pos\"", argStr .. " \"neg\"" }
    end
    return {}
end

local function ClearModelAutocomplete(cmd, argStr, args)
    local models = ttt2pms.db.GetModels()
    local passed = {}

    for _, v in ipairs(args) do
        passed[v] = true
    end

    local options = {}
    if #args == 0 then
        options[#options + 1] = cmd
    end

    for k, _ in pairs(models) do
        if not passed[k] then
            options[#options + 1] = argStr .. " \"" .. k .. "\""
        end
    end

    return options
end

concommand.Add(
    "ttt2_pms_distinct_bodygroups_clear",
    function(ply, cmd, args)
        -- execute
        -- don't nered permission check; this is server-only
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
        -- don't nered permission check; this is server-only
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
    -- don't nered permission check; this is server-only
    if #args < 1 then
        error(cmd .. " usage: <mdl> (<bodygroup> <mode> <comma separated values>)+")
    end

    local bg, skin = ParseBodygroupSetCmdArgs(args)
    UpdateModelSettingsForCmd(args[1], bg, skin, "distinct")
end, BodygroupSetAutocomplete, "Sets distinct bodygroup settings for a model.", {})

concommand.Add("ttt2_pms_allowed_bodygroups_set", function(ply, cmd, args)
    -- execure
    -- don't nered permission check; this is server-only
    if #args < 1 then
        error(cmd .. " usage: <mdl> (<bodygroup> <mode> <comma separated values>)+")
    end

    local bg, skin = ParseBodygroupSetCmdArgs(args)
    UpdateModelSettingsForCmd(args[1], bg, skin, "allowed")
end, BodygroupSetAutocomplete, "Sets allowed bodygroup settings for a model.", {})

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

---@param opts PlayermodelSettings
---@return PlayerSettingsOrm
local function EncodePlayerOrm(opts)
    return {
        globalColor = opts.globalColor,
        defaultColorMode = opts.defaultColorMode,
        usePriorityModels = opts.usePriorityModels,
        useRandomModels = opts.useRandomModels,
        priorityModels_pon = pon.encode(opts.priorityModels),
        randomModels_pon = pon.encode(opts.randomModels),
    }
end

local plyOptionsCache = {}

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
        opts = playerSettingsOrm:New(EncodePlayerOrm(resultModel))
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

    orm = table.Merge(orm, EncodePlayerOrm(opts))
    orm:Save()
end
