---@meta

---@class net_ty

---Initiates a stream message. The data will be converted to an encoded string and sent to the
---peer, which must be listening for the stream at [messageId].
---@realm shared
---
---@param messageId string The message ID the stream will be sent as. Does NOT need to be a network string.
---@param data table The data to send to the peer.
---@param plys? table<Player>|Player @realm server The player(s) to send the stream to. This only has an effect on the server.
function net.SendStream(messageId, data, plys) end

---Receive a stream message sent by [net.SendStream].
---@realm shared
---
---@param messageId string The message ID to listen on.
---@param callback fun(tbl: table, ply?: Player) The function to call when a stream is received. `ply` is only provided when receiving on the server.
function net.ReceiveStream(messageId, callback) end
