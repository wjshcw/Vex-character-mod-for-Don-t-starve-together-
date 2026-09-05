-- 生人勿近 技能逻辑
-- 按 Z → 瞬间伤害 + 圆形范围提示停留1秒

GLOBAL["setmetatable"](env, {
    __index = function(t, k)
        return GLOBAL["rawget"](GLOBAL, k)
    end
})

local VEX_AOE_KEY = GetModConfigData("Vex_AOE_Key") or 122  -- KEY_Z = 122
local AOE_CD = 15
local AOE_RADIUS = 3.5     -- 实际伤害半径
local RETICLE_RADIUS = 3   -- 虚线圈显示半径
local AOE_DAMAGE = 75
local AOE_WINDUP = 1

local COMBAT_MUST_TAGS = { "_combat", "_health" }
local COMBAT_CANT_TAGS = {
    "INLIMBO", "FX", "NOCLICK", "DECOR",
    "playerghost", "companion", "wall", "abigail",
    "invisible", "notarget",
}
if not GLOBAL.TheNet:GetPVPEnabled() then
    table.insert(COMBAT_CANT_TAGS, "player")
end

-- 客户端：圆形 reticule
local function CreateReticule(player)
    local m = GLOBAL.CreateEntity()
    if not m then return end
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
    m.AnimState:SetMultColour(0.9, 0.3, 0.1, 0.7)
    local s = RETICLE_RADIUS / 2
    m.AnimState:SetScale(s, s, s)
    local px, py, pz = player.Transform:GetWorldPosition()
    m.Transform:SetPosition(px, 0, pz)
    player._vex_aoe_reticle = m
end

local function DestroyReticule(player)
    local m = player._vex_aoe_reticle
    if m and m:IsValid() then m:Remove() end
    player._vex_aoe_reticle = nil
end

-- 服务端 RPC
AddModRPCHandler("vex", "aoe_burst", function(player)
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end

    -- 服务端冷却校验（不信任客户端本地 CD）
    if player.vex_aoe_cd_srv and GLOBAL.GetTime() < player.vex_aoe_cd_srv then
        print(">>> AOE: rejected (server CD)")
        return
    end
    local cfg = player._vex_skill_config
    player.vex_aoe_cd_srv = GLOBAL.GetTime() + AOE_CD * (cfg and cfg.all_cd_mult or 1)

    local x, y, z = player.Transform:GetWorldPosition()
    local ents = GLOBAL.TheSim:FindEntities(x, y, z, AOE_RADIUS, COMBAT_MUST_TAGS, COMBAT_CANT_TAGS)
    for _, v in ipairs(ents) do
        if v:IsValid() and v.components.health and not v.components.health:IsDead()
            and v.components.combat and v ~= player then
            local is_follower = v.components.follower and v.components.follower:GetLeader()
                and v.components.follower:GetLeader():HasTag("player")
            if not is_follower then
                local cfg = player._vex_skill_config
                local dmg = AOE_DAMAGE * (cfg and cfg.damage_bonus or 1)
                local was_mist = v:HasTag("vex_gloom_mist")
                if was_mist then
                    dmg = dmg * 2
                    GLOBAL.RemoveMist(v)
                end
                v.components.combat:GetAttacked(player, dmg)
                -- 暮气目标：回复造成伤害一半的 gloom
                if was_mist and player.components.gloom then
                    player.components.gloom:DoDelta(dmg / 2)
                end

                -- 恐惧（40s CD）+ 暮气 -10s CD
                if not player._vex_fear_cd_end or GLOBAL.GetTime() >= player._vex_fear_cd_end then
                    if v.components.hauntable and v.components.hauntable.panicable then
                        v.components.hauntable:Panic(3)
                        player._vex_fear_cd_end = GLOBAL.GetTime() + 40
                        -- 同步到客户端
                        local uid = player.userid
                        if uid then
                            SendModRPCToClient(GetClientModRPC("vex", "fear_triggered"), uid)
                        end
                        print(">>> Fear: triggered on " .. (v.prefab or "?"))
                    end
                end
                if was_mist and player._vex_fear_cd_end then
                    player._vex_fear_cd_end = player._vex_fear_cd_end - 10
                    print(">>> Fear: CD reduced 10s (mist)")
                end
            end
        end
    end

    -- 升级2+：3秒无敌盾（铥矿头盔同款特效）
    local cfg = player._vex_skill_config
    if cfg and cfg.aoe_invincible then
        player.components.health:SetInvincible(true)
        local shield = GLOBAL.SpawnPrefab("forcefieldfx")
        if shield then
            shield.entity:SetParent(player.entity)
        end
        player:DoTaskInTime(cfg.aoe_invincible, function()
            if player:IsValid() then
                player.components.health:SetInvincible(false)
            end
            if shield and shield:IsValid() then
                shield:Remove()
            end
        end)
    end

    local fx = GLOBAL.SpawnPrefab("vex_boom_fx")
    if fx then fx.Transform:SetPosition(x, 0, z) end
    print(">>> AOE: burst at " .. string.format("%.1f, %.1f", x, z))
end)

-- 客户端初始化
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst ~= GLOBAL.ThePlayer then return end
        if inst.prefab ~= "vex" then return end
        inst.vex_aoe_cd_end = nil
        inst._vex_aoe_charging = false
    end)
end)

-- 按键（仅客户端：专用服务器无 TheInput）
if GLOBAL.TheNet:GetIsClient() then
GLOBAL.TheInput:AddKeyDownHandler(VEX_AOE_KEY, function()
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end
    if player._vex_aoe_charging then return end
    if GLOBAL.TheFrontEnd:GetActiveScreen().name ~= "HUD" then return end

    if player.vex_aoe_cd_end and GLOBAL.GetTime() < player.vex_aoe_cd_end then
        local rem = math.ceil(player.vex_aoe_cd_end - GLOBAL.GetTime())
        if player.components.talker and rem > 0 then
            player.components.talker:Say("生人勿近冷却中 (" .. rem .. "s)", 1.5)
        end
        return
    end

    SendModRPCToServer(GetModRPC("vex", "aoe_burst"))
    local sv = player.vex_skill_cd_mult and player.vex_skill_cd_mult:value() or 0
    local cd_mult = sv > 0 and sv or 1
    player.vex_aoe_cd_end = GLOBAL.GetTime() + AOE_CD * cd_mult

    player._vex_aoe_charging = true
    CreateReticule(player)
    player:DoTaskInTime(AOE_WINDUP, function()
        if not player:IsValid() then return end
        DestroyReticule(player)
        player._vex_aoe_charging = false
    end)
end)
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("onremove", function()
        DestroyReticule(inst)
        inst._vex_aoe_charging = false
    end)
end)

print(">>> AOE burst skill loaded")
