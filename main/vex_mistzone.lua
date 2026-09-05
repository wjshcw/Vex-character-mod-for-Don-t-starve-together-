-- 溟濛渐染 技能逻辑
-- 按住 V → 大圈(角色为中心) + 小圈(鼠标位置,限制在大圈内) → 松开 → 1秒延迟 → 35伤害+3秒40%减速

GLOBAL["setmetatable"](env, {
    __index = function(t, k)
        return GLOBAL["rawget"](GLOBAL, k)
    end
})

local VEX_MISTZONE_KEY = GetModConfigData("Vex_MistZone_Key") or 118  -- KEY_V = 118
local MISTZONE_CD = 20
local OUTER_RADIUS = 8     -- 大圈(选取范围)
local function GetInnerRadius(player)
    -- 客户端读 net 变量（客机同步），服务端读施法者配置（多薇古斯互不干扰）
    if player and player.vex_mistzone_radius_mult then
        local v = player.vex_mistzone_radius_mult:value()
        if v > 0 then return 2.5 * v end
    end
    local cfg = player and player._vex_skill_config
    return 2.5 * (cfg and cfg.mistzone_radius_mult or 1)
end
local MISTZONE_DAMAGE = 35
local SLOW_DURATION = 3
local SLOW_MULT = 0.4      -- 减速到40%

local COMBAT_MUST_TAGS = { "_combat", "_health" }
local COMBAT_CANT_TAGS = {
    "INLIMBO", "FX", "NOCLICK", "DECOR",
    "playerghost", "companion", "wall", "abigail",
    "invisible", "notarget",
}
if not GLOBAL.TheNet:GetPVPEnabled() then
    table.insert(COMBAT_CANT_TAGS, "player")
end

-- 客户端：双圈指示器
local function MakeReticule()
    local m = GLOBAL.CreateEntity()
    if not m then return nil end
    m.entity:SetCanSleep(false)
    m.persists = false
    m:AddTag("FX")
    m:AddTag("NOCLICK")
    m.entity:AddTransform()
    m.entity:AddAnimState()
    m.AnimState:SetBank("reticuleaoe")
    m.AnimState:SetBuild("reticuleaoe")
    m.AnimState:PlayAnimation("idle")
    m.AnimState:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround)
    m.AnimState:SetLayer(GLOBAL.LAYER_WORLD_BACKGROUND)
    m.AnimState:SetSortOrder(3)
    return m
end

local function CreateReticule(player)
    -- 大圈（选取范围，蓝色）
    local outer = MakeReticule()
    if outer then
        outer.AnimState:SetMultColour(0.3, 0.5, 0.9, 0.5)
        outer.AnimState:SetScale(OUTER_RADIUS / 2, OUTER_RADIUS / 2, OUTER_RADIUS / 2)
    end
    -- 小圈（伤害范围，橙红色）
    local inner = MakeReticule()
    if inner then
        inner.AnimState:SetMultColour(0.9, 0.3, 0.1, 0.7)
        inner.AnimState:SetScale(GetInnerRadius(player) / 2, GetInnerRadius(player) / 2, GetInnerRadius(player) / 2)
    end
    player._vex_mistzone_outer = outer
    player._vex_mistzone_inner = inner
end

local function UpdateReticule(player)
    local outer = player._vex_mistzone_outer
    local inner = player._vex_mistzone_inner
    if not outer and not inner then return end

    local pp = player:GetPosition()
    local mp = GLOBAL.TheInput:GetWorldPosition()

    -- 大圈固定在角色位置
    if outer and outer:IsValid() then
        outer.Transform:SetPosition(pp.x, 0, pp.z)
    end

    -- 小圈跟随鼠标，限制在大圈内
    if inner and inner:IsValid() then
        local dx, dz = mp.x - pp.x, mp.z - pp.z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist > OUTER_RADIUS then
            dx, dz = dx / dist * OUTER_RADIUS, dz / dist * OUTER_RADIUS
        end
        inner.Transform:SetPosition(pp.x + dx, 0, pp.z + dz)
    end
end

local function DestroyReticule(player)
    for _, key in ipairs({"_vex_mistzone_outer", "_vex_mistzone_inner"}) do
        local m = player[key]
        if m and m:IsValid() then m:Remove() end
        player[key] = nil
    end
end

-- 服务端 RPC
AddModRPCHandler("vex", "mistzone", function(player, tx, tz)
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end

    -- 服务端冷却校验（不信任客户端本地 CD）
    if player.vex_mistzone_cd_srv and GLOBAL.GetTime() < player.vex_mistzone_cd_srv then
        print(">>> MistZone: rejected (server CD)")
        return
    end
    local cfg = player._vex_skill_config
    player.vex_mistzone_cd_srv = GLOBAL.GetTime()
        + MISTZONE_CD * (cfg and cfg.all_cd_mult or 1) * (cfg and cfg.mistzone_cd_mult or 1)

    -- 落地特效：E动画延后0.333秒生成（动画时长约0.667秒），
    -- 结束时刻与1秒延迟伤害落地对齐
    player:DoTaskInTime(0.333, function()
        if not player:IsValid() then return end
        local land_fx = GLOBAL.SpawnPrefab("vex_mistzone_fx")
        if land_fx then
            land_fx.Transform:SetPosition(tx, 0, tz)
        end
    end)

    -- 1秒延迟后伤害+减速
    player:DoTaskInTime(1, function()
        if not player:IsValid() then return end

        local ents = GLOBAL.TheSim:FindEntities(tx, 0, tz, GetInnerRadius(player), COMBAT_MUST_TAGS, COMBAT_CANT_TAGS)
        for _, v in ipairs(ents) do
            if v:IsValid() and v.components.health and not v.components.health:IsDead()
                and v.components.combat and v ~= player then
                local is_follower = v.components.follower and v.components.follower:GetLeader()
                    and v.components.follower:GetLeader():HasTag("player")
                if not is_follower then
                    local cfg = player._vex_skill_config
                    v.components.combat:GetAttacked(player, MISTZONE_DAMAGE * (cfg and cfg.damage_bonus or 1))

                    -- 恐惧（40s CD）
                    if not player._vex_fear_cd_end or GLOBAL.GetTime() >= player._vex_fear_cd_end then
                        if v.components.hauntable and v.components.hauntable.panicable then
                            v.components.hauntable:Panic(3)
                            player._vex_fear_cd_end = GLOBAL.GetTime() + 40
                            local uid = player.userid
                            if uid then
                                SendModRPCToClient(GetClientModRPC("vex", "fear_triggered"), uid)
                            end
                            print(">>> Fear: triggered on " .. (v.prefab or "?"))
                        end
                    end

                    -- 击杀 -10s 恐惧CD
                    if v.components.health:IsDead() and player._vex_fear_cd_end then
                        player._vex_fear_cd_end = player._vex_fear_cd_end - 10
                        print(">>> Fear: CD reduced 10s (kill)")
                    end

                    -- 施加暮气buff
                    if GLOBAL.ApplyMist then
                        GLOBAL.ApplyMist(v)
                    end

                    -- 减速效果：3秒40%移速
                    if v.components.locomotor then
                        v.components.locomotor:SetExternalSpeedMultiplier(
                            player, "vex_mistzone_slow", SLOW_MULT)
                        v:DoTaskInTime(SLOW_DURATION, function()
                            if v:IsValid() and v.components.locomotor then
                                v.components.locomotor:RemoveExternalSpeedMultiplier(
                                    player, "vex_mistzone_slow")
                            end
                        end)
                    end
                end
            end
        end

    end)

    print(">>> MistZone: target at " .. string.format("%.1f, %.1f", tx, tz))
end)

-- 客户端初始化
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst ~= GLOBAL.ThePlayer then return end
        if inst.prefab ~= "vex" then return end
        inst.vex_mistzone_cd_end = nil
        inst._vex_mistzone_aiming = false
    end)
end)

-- 按键：按住 → 双圈，松开 → 释放（仅客户端：专用服务器无 TheInput）
if GLOBAL.TheNet:GetIsClient() then
GLOBAL.TheInput:AddKeyHandler(function(key, down)
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end
    if key ~= VEX_MISTZONE_KEY then return end
    if GLOBAL.TheFrontEnd:GetActiveScreen().name ~= "HUD" then return end

    if down then
        -- CD 检查
        if player.vex_mistzone_cd_end and GLOBAL.GetTime() < player.vex_mistzone_cd_end then
            local rem = math.ceil(player.vex_mistzone_cd_end - GLOBAL.GetTime())
            if player.components.talker and rem > 0 then
                player.components.talker:Say("溟濛渐染冷却中 (" .. rem .. "s)", 1.5)
            end
            return
        end
        if player._vex_mistzone_aiming then return end
        player._vex_mistzone_aiming = true
        CreateReticule(player)
        player._vex_mz_move = GLOBAL.TheInput:AddMoveHandler(function()
            if player._vex_mistzone_aiming then UpdateReticule(player) end
        end)
        UpdateReticule(player)
    else
        if not player._vex_mistzone_aiming then return end
        player._vex_mistzone_aiming = false
        player._vex_mz_move = nil

        -- 计算目标位置
        local pp = player:GetPosition()
        local mp = GLOBAL.TheInput:GetWorldPosition()
        local dx, dz = mp.x - pp.x, mp.z - pp.z
        local dist = math.sqrt(dx*dx + dz*dz)
        if dist > OUTER_RADIUS then
            dx, dz = dx / dist * OUTER_RADIUS, dz / dist * OUTER_RADIUS
        elseif dist < 0.01 then
            local f = player.Transform:GetRotation() * GLOBAL.DEGREES
            dx, dz = math.cos(f) * 2, -math.sin(f) * 2
        end
        local tx, tz = pp.x + dx, pp.z + dz

        DestroyReticule(player)
        SendModRPCToServer(GetModRPC("vex", "mistzone"), tx, tz)
        local sv = player.vex_skill_cd_mult and player.vex_skill_cd_mult:value() or 0
        local mv = player.vex_mistzone_cd_mult and player.vex_mistzone_cd_mult:value() or 0
        local cd_mult = (sv > 0 and sv or 1) * (mv > 0 and mv or 1)
        player.vex_mistzone_cd_end = GLOBAL.GetTime() + MISTZONE_CD * cd_mult
    end
end)
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("onremove", function()
        DestroyReticule(inst)
        inst._vex_mz_move = nil
        inst._vex_mistzone_aiming = false
    end)
end)

print(">>> MistZone skill loaded")
