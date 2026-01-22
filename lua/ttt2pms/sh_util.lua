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
