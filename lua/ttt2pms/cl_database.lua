ttt2pms = ttt2pms or {}
ttt2pms.db = ttt2pms.db or {}

---@type PerPlayermodel<PlayermodelServer>
local modelOptions = {}
---@type PerPlayermodel<table<fun(opts: PlayermodelServer?)>>
local modelPendingCallbacks = {}

---Asynchronously gets the server's playermodel options for a specified model.
---@realm client
---
---@param model string The model to get the options for.
---@param callback fun(opts: PlayermodelServer?) The function to call once the options are available.
function ttt2pms.db.GetModelOptions(model, callback)
    local cached = modelOptions[model]
    if cached then
        callback(cached)
        return
    end

    -- not cached, need to send a request to the server and register a callback
    if callback then
        local callbacks = modelPendingCallbacks[model] or {}
        callbacks[#callbacks + 1] = callback
        modelPendingCallbacks[model] = callbacks
    end

    net.SendStream(
        "TTT2PMS_Get_PlayermodelOptions",
        ---@type TTT2PMS_Get_PlayermodelOptions_Req
        {
            model = model,
        }
    )
end

net.ReceiveStream("TTT2PMS_Broadcast_PlayermodelOptions", function(data)
    ---@cast data TTT2PMS_Get_PlayermodelOptions_Resp

    -- a broadcast could happen either because the server changed settings (and so it's sending us
    -- the new version) or because we previously requested it, in which case we have pending
    -- callbacks for that model. whatever the case, we need to 1. update our cache, and 2. call
    -- callbacks.
    modelOptions[data.model] = data.opts

    local callbacks = modelPendingCallbacks[data.model]
    if callbacks then
        for i = 1, #callbacks do
            ProtectedCall(callbacks[i], data.opts)
        end
    end

    modelPendingCallbacks[data.model] = nil
end)
