local fcvars
if CLIENT then
    fcvars = { FCVAR_REPLICATED }
end
if SERVER then
    fcvars = { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }
end

---@realm shared
ttt2pms = ttt2pms or {}
ttt2pms.cv = table.Merge(ttt2pms.cv or {}, {
    ---@realm shared
    allowUserColors = CreateConVar(
        "ttt2_pms_allow_user_colors",
        "0",
        fcvars,
        "Whether to allow users to select their playermodel color. When 0, the playermodel color will "
            .. "be determined according to the normal TTT2 rules.",
        0,
        1
    ),
    overrideColor = {
        ---@realm shared
        r = CreateConVar(
            "ttt2_pms_override_color_r",
            "255",
            fcvars,
            "The red channel of the global override color. Only used when ttt_playercolor_mode is 0.",
            0,
            255
        ),
        ---@realm shared
        g = CreateConVar(
            "ttt2_pms_override_color_g",
            "255",
            fcvars,
            "The green channel of the global override color. Only used when ttt_playercolor_mode is 0.",
            0,
            255
        ),
        ---@realm shared
        b = CreateConVar(
            "ttt2_pms_override_color_b",
            "255",
            fcvars,
            "The blue channel of the global override color. Only used when ttt_playercolor_mode is 0.",
            0,
            255
        ),
    },
    ---@realm shared
    allowModelPerRound = CreateConVar(
        "ttt2_pms_allow_round_models",
        "1",
        fcvars,
        "Whether to allow players to get a new playermodel each round. "
            .. "If this is disabled, playermodels will only be changeable in a map's first round preparation phase. ",
        0,
        1
    ),
    ---@realm shared
    requireUniqueModels = CreateConVar(
        "ttt2_pms_require_unique_models",
        "1",
        fcvars,
        "Whether to require each player to have a unique playermodel.",
        0,
        1
    ),
})

local cv = ttt2pms.cv

ttt2pms.__ServerOpts_getters = table.Merge(ttt2pms.__ServerOpts_getters, {
    allowUserColors = function(_)
        return cv.allowUserColors:GetBool()
    end,
    overrideColor = function(_)
        return Color(
            cv.overrideColor.r:GetInt(),
            cv.overrideColor.g:GetInt(),
            cv.overrideColor.b:GetInt()
        )
    end,
    allowModelPerRound = function(_)
        return cv.allowModelPerRound:GetBool()
    end,
    requireUniqueModels = function(_)
        return cv.requireUniqueModels:GetBool()
    end,
})

if SERVER then
    -- We add the setters too, on the server, so we have a convenient way to change these convars
    ttt2pms.__ServerOpts_setters = table.Merge(ttt2pms.__ServerOpts_setters, {
        ---@param v boolean
        allowUserColors = function(_, v)
            cv.allowUserColors:SetBool(v)
        end,
        ---@param v Color
        overrrideColor = function(_, v)
            cv.overrideColor.r:SetInt(v.r)
            cv.overrideColor.g:SetInt(v.g)
            cv.overrideColor.b:SetInt(v.b)
        end,
        ---@param v boolean
        allowModelPerRound = function(_, v)
            cv.allowModelPerRound:SetBool(v)
        end,
        ---@param v boolean
        requireUniqueModels = function(_, v)
            cv.requireUniqueModels:SetBool(v)
        end,
    })
end
