---@realm server

---@generic T: ORMObject
---@class ORM<T>
---@field All function():table<T>|nil
---@field Find function(name:string):T|nil
---@field New function(tbl:table):T
---@field Where function(filters:table):table<T>|nil

---@class ORMObject
---@field Delete function():boolean
---@field Refresh function():boolean
---@field Save function():boolean
---@field name string the name of the model

local ponEmptyTbl = "[}"

local modelBodygroupOptionsTblName = "ttt2pms_sv_model_distinct_bodygroups"
---@type ORM<ModelBodygroupOptionsMdl>
local modelBodygroupOptionsOrm
---@class ModelBodygroupOptionsMdl: ORMObject
---@field bodygroups_pon string the @{pon} encoded bodygroups configuration

local playerSettingsTblName = "ttt2pms_cl_settings"
---@type ORM<PlayerSettingsOrm>
local playerSettingsOrm
hook.Add("Initialize", "TTT2PMS_Database", function()
    sql.CreateSqlTable(modelBodygroupOptionsTblName, {
        bodygroups_pon = { typ = "string", default = ponEmptyTbl },
    })
    modelBodygroupOptionsOrm = orm.Make(modelBodygroupOptionsTblName)

    sql.CreateSqlTable(playerSettingsTblName, {
        globalColor = { typ = "color" },
        defaultColorMode = { typ = "number", default = 0 },

        usePrimaryModel = { typ = "boolean", default = false },
        usePriorityModels = { typ = "boolean", default = false },
        useRandomModels = { typ = "boolean", default = false },

        primaryModel_pon = { typ = "string", default = ponEmptyTbl },
        priorityModels_pon = { typ = "string", default = ponEmptyTbl },
        randomModels_pon = { typ = "string", default = ponEmptyTbl },
    })
    playerSettingsOrm = orm.Make(playerSettingsTblName)
end)

---@class PlayerSettingsOrm: ORMObject
---@field name string the SteamID64 of the player this is for
---@field globalColor Color
---@field defaultColorMode PLAYERMODEL_COLOR_MODE
---@field usePrimaryModel boolean
---@field usePriorityModels boolean
---@field useRandomModels boolean
---@field primaryModel_pon string
---@field priorityModels_pon string
---@field randomModels_pon string

ttt2pms = ttt2pms or {}
ttt2pms.db = ttt2pms.db or {}

---@param orm ModelBodygroupOptionsMdl
---@return PlayermodelServer
local function DecodeBodygroupsOrm(orm)
    return {
        model = orm.name,
        bodygroups = pon.decode(orm.bodygroups_pon),
    }
end

---@param opts PlayermodelServer
---@return ModelBodygroupOptionsMdl
local function EncodeBodygroupsOrm(opts)
    return {
        name = opts.model,
        bodygroups_pon = pon.encode(opts.bodygroups),
    }
end

local bodygroupDistinctModelsTbl

---@return table<string, PlayermodelServer>
function ttt2pms.db.GetBodygroupDistinctModels()
    if not bodygroupDistinctModelsTbl then
        ---@type table<ModelBodygroupOptionsMdl>
        local models = modelBodygroupOptionsOrm:All()

        local result = {}
        for i = 1, #models do
            local orm = models[i]
            result[orm.name] = DecodeBodygroupsOrm(orm)
        end

        bodygroupDistinctModelsTbl = result
    end

    return bodygroupDistinctModelsTbl
end

---@param opts PlayermodelServer
function ttt2pms.db.SetModelDistinctOptions(opts)
    local orm = modelBodygroupOptionsOrm:Find(opts.model)
    if not orm then
        orm = modelBodygroupOptionsOrm:New(EncodeBodygroupsOrm(opts))
    else
        table.Merge(orm, EncodeBodygroupsOrm(opts))
    end
    orm:Save()

    if bodygroupDistinctModelsTbl then
        bodygroupDistinctModelsTbl[opts.model] = table.Copy(opts)
    end
end

---@param model string
---@return boolean
function ttt2pms.db.DeleteModelDistinctOptions(model)
    local orm = modelBodygroupOptionsOrm:Find(model)
    local success = false
    if orm then
        success = orm:Delete()
    end

    if bodygroupDistinctModelsTbl then
        bodygroupDistinctModelsTbl[model] = nil
    end

    return success
end

function ttt2pms.db.SaveModelDistinctOptions()
    -- we want to save ALL changes in the distinct table.
    if not bodygroupDistinctModelsTbl then
        -- if this hasn't been set, then noone called GetBodygroupDistinctModels(), and thus
        -- couldn't have changed it. So, nothing to be done.
        return
    end

    -- otherwise, we want to 1. get a list of all of the DB models, then 2. sync those
    -- appropriately.

    local ormTbl = {}
    for _, v in ipairs(modelBodygroupOptionsOrm:All()) do
        ormTbl[v.name] = v
    end

    -- before syncing, we want to make sure the keys and values of the distinct table are synced
    local tbl = table.Copy(bodygroupDistinctModelsTbl)
    for k, v in pairs(tbl) do
        if k ~= v.model then
            bodygroupDistinctModelsTbl[v.model] =
                table.Merge(bodygroupDistinctModelsTbl[v.model] or {}, v)
            bodygroupDistinctModelsTbl[k] = nil
        end
    end
    tbl = bodygroupDistinctModelsTbl

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
            modelBodygroupOptionsOrm:New(EncodeBodygroupsOrm(v)):Save()
        end
    end

    -- anything remaining in ormTbl needs to be deleted
    for _, v in pairs(ormTbl) do
        v:Delete()
    end
end

function ttt2pms.db.ClearModelDistinctOptions()
    sql.Query("DELETE FROM " .. sql.SQLStr(modelBodygroupOptionsTblName) .. ";")
    bodygroupDistinctModelsTbl = {}
end

ttt2pms.__ServerOpts_getters = table.Merge(ttt2pms.__ServerOpts_getters, {
    modelsWithAllowedDistinctBodygroups = function(_)
        return ttt2pms.db.GetBodygroupDistinctModels()
    end,
})

ttt2pms.__ServerOpts_setters = table.Merge(ttt2pms.__ServerOpts_setters, {
    modelsWithAllowedDistinctBodygroups = function()
        error("not allowed to set modelsWithAllowedDistinctBodygroups", 5)
    end,
})

concommand.Add("ttt2_pms_distinct_bodygroups_clear", function(ply, cmd, args)
    -- execute
    if not ply:IsSuperAdmin() then
        return
    end

    if #args > 0 then
        -- a list of models were specified
        for _, v in ipairs(args) do
            if ttt2pms.db.DeleteModelDistinctOptions(v) then
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
        ttt2pms.db.ClearModelDistinctOptions()
    end
end, function(cmd, argStr, args)
    -- autocomplete
    local models = ttt2pms.db.GetBodygroupDistinctModels()

    local passed = {}
    for _, v in ipairs(args) do
        passed[v] = true
    end

    local options = {}
    if #args == 0 then
        options[#options + 1] = cmd
    end

    for k, _ in pairs(models) do
        if passed[k] then
            -- don't print any options that are already passed
            continue
        end

        options[#options + 1] = argStr .. " \"" .. k .. "\""
    end

    return options
end, "Clears the configured \"distinct\" bodygroups options (optionally for a specific model).", {})

concommand.Add(
    "ttt2_pms_distinct_bodygroups_set",
    function(ply, cmd, args)
        -- execute
        if not ply:IsSuperAdmin() then
            return
        end

        if #args < 1 then
            error(cmd .. " usage: <mdl> (<bodygroup> <mode> <comma separated values>)+")
        end

        local model = args[1]
        ---@type table<number,BodygroupServer>
        local bodygroupSettings = {}
        ---@type nil|BodygroupServer
        local skinSettings

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
            ---@type table<number>
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

        ---@type PlayermodelServer
        local pm = { model = model, bodygroups = bodygroupSettings }

        if skinSettings then
            pm.skin = skinSettings
        end

        pm = table.Merge(ttt2pms.db.GetBodygroupDistinctModels()[pm.model] or {}, pm)
        ttt2pms.db.SetModelDistinctOptions(pm)
    end,
    --[[ ya fuck doing autocomplete for this lmao ]]
    nil,
    "Sets distinct bodygroup settings for a model.",
    {}
)

local function ponDecodeMaybeNil(str)
    local res = pon.decode(str)
    if type(res) == "table" and #table == 0 then
        return nil
    else
        return res
    end
end

---@param orm PlayerSettingsOrm
---@return PlayermodelSettings
local function DecodePlayerOrm(orm)
    return {
        globalColor = orm.globalColor,
        defaultColorMode = orm.defaultColorMode,
        usePrimaryModel = orm.usePrimaryModel,
        usePriorityModels = orm.usePriorityModels,
        useRandomModels = orm.useRandomModels,
        primaryModel = ponDecodeMaybeNil(orm.primaryModel_pon),
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
        usePrimaryModel = opts.usePrimaryModel,
        usePriorityModels = opts.usePriorityModels,
        useRandomModels = opts.useRandomModels,
        primaryModel_pon = pon.encode(opts.primaryModel or {}),
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

    ---@type PlayerSettingsOrm
    local opts = playerSettingsOrm:Find(sid)
    ---@type PlayermodelSettings
    local resultModel
    if not opts then
        -- player does not have any recorded options, populate a default
        resultModel = {
            globalColor = COLOR_WHITE,
            defaultColorMode = PLAYERMODEL_COLOR_MODE.SERVER,
            usePrimaryModel = false,
            primaryModel = nil,
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
