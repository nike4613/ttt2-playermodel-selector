---@realm shared
---@enum PLAYERMODEL_COLOR_MODE
PLAYERMODEL_COLOR_MODE = {
    ---
    -- Use the server's global color for the player model
    SERVER = 0,

    ---
    -- Use the user's specified global color for the player model
    USER_GLOBAL = 1,

    ---
    -- Use the color specified for this model
    MODEL = 2,

    ---
    -- Use a random color for this model
    RANDOM = 3,
}

---@realm shared
---@class PlayermodelSettings
---@field globalColor           Color                   The user global player color
---@field defaultColorMode      PLAYERMODEL_COLOR_MODE  The default playermodel color mode
---
---@field playermodel?          Playermodel?            The playermodel to use when unique playermodels are disabled.
---
---@field usePriorityModels     boolean                 Whether to use priority models
---@field priorityModels        table<Playermodel>      The priority playermodels.
---
---@field useRandomModels       boolean                 Whether to use the random model pool
---@field randomModels          table<Playermodel>      The random models

---@realm shared
---@class Playermodel
---@field model         string                              The name of the model.
---@field color         Color                               The model-specific color. Only meaningful with @{PLAYERMODEL_COLOR_MODE.MODEL}.
---@field colorMode?    PLAYERMODEL_COLOR_MODE              The color mode to use for this model.
---@field skin          BodygroupSettings                   The model skin to use
---@field bodygroups    table<number,BodygroupSettings>     The bodygroup settings for the playermodel.

---@realm shared
---@class BodygroupSettings
---@field value         number                      The bodygroup value
---@field random        boolean                     Whether the bodygroup's value should be random.

---@realm shared
---@class PlayermodelServerSettings
---@field allowUserColors       boolean     Whether to allow users to use their own colors.
---         When false, all players will use the server-assigned color settings.
---         `ttt2_pms_allow_user_colors` `ttt2pms.cv.allowUserColors`
---@field overrideColor         Color       The server-assigned color to force. This will override
---         TTT2's default COLOR_WHITE with `ttt_playercolor_mode 0`.
---         `ttt2_pms_override_color_r` `ttt2pms.cv.overrideColor.r``
---         `ttt2_pms_override_color_g` `ttt2pms.cv.overrideColor.g`
---         `ttt2_pms_override_color_b` `ttt2pms.cv.overrideColor.b`
---@field allowUserModels       boolean     Whether to allow users to select their own models.
---         When false, the playermodel selector will be unavailable and playermodels will be
---         selected according to default TTT2 logic.
---         `ttt2_pms_allow_user_models` `ttt2pms.cv.allowUserModels`
---@field allowModelPerRound    boolean     Whether to allow players to select new models each
---         round. When false, playermodels will only be reselected during preparation period of the
---         first round on the map.
---         `ttt2_pms_allow_round_models` `ttt2pms.cv.allowModelPerRound`
---@field requireUniqueModels   boolean     Whether to enforce unique playermodels among all
---         players. This being set is the only case where most of the player's options do anything.
---         `ttt2_pms_require_unique_models` `ttt2pms.cv.requireUniqueModels`
---@field allowDistinctBodygroups boolean   Whether to allow treating the same playermodels with
---         different bodygroup values as distinct, subject to the server's per-model settings.
---         `ttt2_pms_allow_distinct_bodygroups` `ttt2pms.cv.allowDistinctBodygroups`

---A mapping of some value for each playermodel
---@class PerPlayermodel<T> : { [string]: T? }

---@realm server
---@class PlayermodelServer
---The name of the model.
---@field model                 string
---The set of skin values allowed.
---@field skinAllowed           BodygroupServer?
---The set of skin values considered to be distinct.
---@field skinDistinct          BodygroupServer?
---The allowed values for each bodygroup. If a bodygroup is not specified, aall values are
---permitted.
---@field bodygroupsAllowed     table<number,BodygroupServer>
---The values for each bodygroup considered to be distinct. If a bodygroup is not specified,
---all values are considered to be distinct.
---@field bodygroupsDistinct    table<number,BodygroupServer>

---@realm server
---@note When this is used to list distinct values, the following behavior applies:
--- - When `mode` is "pos", the values in `values` are treated as distinct from each other, and
---   all values not listed are treated as a final group, distinct from the values in `values`,
---   but equivalent to each other.
--- - When `mode` is "neg", the values in `values` are treated as equivalent to each other, and
---   all values not listed are treated as being distinct from each other and those listed in
---   `values`.
---@class BodygroupServer
---The mode of this bodygroup. If "pos", then this lists the positive values, and logically this instance
---represents exactly the values in `values`. If "neg", then this lists the negative values, and logically
---this instance represents all values EXCEPT those listed in `values`.
---@field mode          "pos"|"neg"
---The values associated with this configured bodygroup.
---@field values        table<number>

ttt2pms = ttt2pms or {}

---@type PlayermodelServerSettings
---@diagnostic disable-next-line
ttt2pms.ServerOpts = {}

---@type table<string,function>
ttt2pms.__ServerOpts_getters = table.Merge(ttt2pms.__ServerOpts_getters or {}, {})
---@type table<string,function>
ttt2pms.__ServerOpts_setters = table.Merge(ttt2pms.__ServerOpts_setters or {}, {})

setmetatable(ttt2pms.ServerOpts, {
    __index = function(tbl, name)
        local get = ttt2pms.__ServerOpts_getters[name]
        return get and get(tbl)
    end,
    __newindex = function(tbl, name, value)
        local set = ttt2pms.__ServerOpts_setters[name]
        if set then
            set(tbl, value)
        end
    end,
})
