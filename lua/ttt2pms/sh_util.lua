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
