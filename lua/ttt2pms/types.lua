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
---@field usePrimaryModel       boolean                 Whether to use the configured primary model
---@field primaryModel          Playermodel|nil         The primary model.
---
---@field usePriorityModels     boolean                 Whether to use priority models
---@field priorityModels        table<Playermodel>      The priority playermodels.
---
---@field useRandomModels       boolean                 Whether to use the random model pool
---@field randomModels          table<Playermodel>      The random models

---@realm shared
---@class Playermodel
---@field model         string                      The name of the model.
---@field color         Color                       The model-specific color. Only meaningful with @{PLAYERMODEL_COLOR_MODE.MODEL}.
---@field colorMode     PLAYERMODEL_COLOR_MODE|nil  The color mode to use for this model.
---@field bodygroups    table<number,BodygroupSettings>    The bodygroup settings for the playermodel.

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
---         `ttt2_pms_require_unique_models `ttt2pms.cv.requireUniqueModels`
---@realm server
---@field modelsWithAllowedDistinctBodygroups   table<PlayermodelServer> A set of
---         playermodels (and their bodygroups) for which instances are considered to be unique if
---         the bodygroups are different. This being significant enough to be reasonable is rare
---         enough that there is no method to enable this across all playermodels, as there would be
---         no point.
---         `ttt2_pms_distinct_bodygroups_clear [<mdl>]`
---         `ttt2_pms_distinct_bodygroups_set <mdl> (<bodygroup> <mode> <comma separated values>)+`
---         (note: `ttt2_pms_set_distinct_bodygroups` is ADDITIVE; it does not replace)

---@realm server
---@class PlayermodelServer
---@field model         string                          The model name
---@field bodygroups    table<number,BodygroupServer>   The set of bodygroups which have options
---         configured. Any bodygroups which are unconfigured are not considered to be distinct.

---@realm server
---@class BodygroupServer
---@field mode          "pos"|"neg"     The mode of this bodygroup option. If "pos", then this lists
---         the values which are considered to be distinct. If "neg", then this lists the values which are
---         considered to be NOT distinct (and the remaining values are considered to be distinct).
---         The distinct groupings are: [all values not considered distinct],distinct1,distinct2,etc...
---         Thus, if values 3, 4, and 5 are considered distinct, then the groups are [0,1,2],[3],[4],[5].
---@field values        table<number>   The values associated with this configured bodygroup.

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
