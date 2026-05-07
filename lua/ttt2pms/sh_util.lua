ttt2pms = ttt2pms or {}
ttt2pms.util = ttt2pms.util or {}

---
---@param ent Entity
---@return table<number,number>
---@realm shared
function ttt2pms.util.GetBodygroupTbl(ent)
    local bodygroups = {}
    for i = 0, ent:GetNumBodyGroups() - 1 do
        bodygroups[i] = ent:GetBodygroup(i)
    end
    return bodygroups
end

---
---@param ent Entity
---@param bodygroups table<number,number>
function ttt2pms.util.SetBodygroupTbl(ent, bodygroups)
    for k, v in pairs(bodygroups) do
        ent:SetBodygroup(k, v)
    end
end
---
---@param ent Entity
---@param bodygroups table<number,number>
function ttt2pms.util.ReplaceBodygroupTbl(ent, bodygroups)
    for i = 0, ent:GetNumBodyGroups() - 1 do
        ent:SetBodygroup(i, bodygroups[i] or 0)
    end
end

---
---@param vec Vector
---@return Color
function ttt2pms.util.Vec2Col(vec)
    return Color(vec.x * 255.0, vec.y * 255.0, vec.z * 255.0)
end

---
---@param col Color
---@return Vector
function ttt2pms.util.Col2Vec(col)
    return Vector(col.r / 255.0, col.g / 255.0, col.b / 255.0)
end

---Creates a helper function which returns `true` if the string passed to it matches [filter].
---@param filter string?
---@return fun(str: string): boolean
function ttt2pms.util.FilterMatcher(filter)
    local filterParts = string.Split(filter or "", " ")

    local function InFilter(name)
        if not filter or filter == "" then
            return true
        end

        for _, sstr in pairs(filterParts) do
            if not string.match(name:lower(), string.PatternSafe(sstr:lower())) then
                return false
            end
        end

        return true
    end

    return InFilter
end

---Gets the actual logical set represented by a [BodygroupServer].
---@param bgrp BodygroupServer The bodygroup being considered
---@param max number The maximum value of the corresponding bodygroup
---@return table<number> values
function ttt2pms.util.GetBodygroupSet(bgrp, max)
    if bgrp.mode == "pos" then
        -- in positive mode, the values are the set directly
        local values = bgrp.values
        local newValues
        -- we'll just filter to be strictly in-range
        for i = 1, #values do
            local value = values[i]

            if value < 0 or value >= max then
                -- item needs to be removed; if we haven't created newValues yet, do so and copy in
                if not newValues then
                    newValues = {}
                    for j = 1, i - 1 do
                        newValues[j] = values[j]
                    end
                end
            else
                -- item is good; copy into newValues if appropriate
                if newValues then
                    newValues[#newValues + 1] = value
                end
            end
        end

        return newValues or values
    else
        -- in negative mode, values represents the values *not* present
        local lut = table.Flip(bgrp.values)

        local values = {}
        for i = 0, max - 1 do
            if lut[i] == nil then
                values[#values + 1] = i
            end
        end

        return values
    end
end

---Gets a concrete bodygroup value given some BodygroupSettings, and a maximum bodygroup value.
---@param bgrp number|BodygroupSettings the bodygroup setting to use
---@param max number the maximum value of the bodygroup
---@param allowedValues? table<number> the possible values this bodygroup is permitted to take
---@return number value the concrete bodygroup value
function ttt2pms.util.GetBodygroupValue(bgrp, max, allowedValues)
    local value

    if type(bgrp) == "number" then
        value = bgrp
    elseif not bgrp.random then
        value = bgrp.value
    end

    if value == nil then
        -- value must be randomly selected
        if allowedValues then
            -- the randomly selected allowed value will be the final value
            return allowedValues[math.random(#allowedValues)]
        else
            -- the randomly selected is necesarily in range, so will be the final value
            return math.random(0, max)
        end
    else
        -- [value] must be sanitized to ensure it is in-range/allowed
        if allowedValues then
            if not table.HasValue(allowedValues, value) then
                -- default to 0 here
                return 0
            end
        else
            if value < 0 or value >= max then
                return 0
            end
        end

        -- value was ok, return it
        return value
    end
end

local plymodelsPending = {}

---Gets the serverside list of all selected models, playermodels.GetSelectedModels().
---On @realm client, this is asynchronous and coalesced (i.e. only request to the server is
---in-flight at a time).
---On @realm server, this is synchronous, and immediately calls the callback with the result.
---@param callback fun(result: table<string>)
function ttt2pms.util.GetSelectablePlayermodels(callback)
    if SERVER then
        local models = playermodels.GetSelectedModels()
        callback(models)
    end
    if CLIENT then
        local alreadyRequested = #plymodelsPending > 0

        plymodelsPending[#plymodelsPending + 1] = callback

        if not alreadyRequested then
            net.Start("ttt2pms_util_GetSelectablePlayermodels")
            net.SendToServer()
        end
    end
end

if SERVER then
    util.AddNetworkString("ttt2pms_util_GetSelectablePlayermodels")
    util.AddNetworkString("ttt2pms_util_GetSelectablePlayermodels_reply")

    net.Receive("ttt2pms_util_GetSelectablePlayermodels", function(_, ply)
        ttt2pms.util.GetSelectablePlayermodels(function(values)
            net.SendStream("ttt2pms_util_GetSelectablePlayermodels_reply", values, ply)
        end)
    end)
end

if CLIENT then
    net.ReceiveStream("ttt2pms_util_GetSelectablePlayermodels_reply", function(tbl)
        for i = 1, #plymodelsPending do
            ProtectedCall(plymodelsPending[i], tbl)
        end
        plymodelsPending = {}
    end)
end
