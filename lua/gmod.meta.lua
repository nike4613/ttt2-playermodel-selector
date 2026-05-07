---@meta

---@generic K, V
---Flips key-value pairs of each element within a table, so that each value becomes the key, and each key becomes the value.
---@param input table<K, V>
---@return table<V, K> output
function table.Flip(input) end

---@generic V
---Flips key-value pairs of each element within a table, so that each value becomes the key, and each key becomes the value.
---@param input table<V>
---@return table<V, number> output
function table.Flip(input) end
