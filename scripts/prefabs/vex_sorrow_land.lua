-- 愁煞·落地特效
-- 冲刺到达目标时在落点生成，执行300范围伤害 + 视觉特效
-- 附带暗影爆炸环：复用原版麦斯威尔暗影陷阱的蘑菇弹冲击波动画
-- （参考：原版 shadow_trap.lua OnShockwave，未改动原版参数逻辑）

local assets = {
    Asset("ANIM", "anim/boom.zip"),
}

-- 冲击波环缩放：原版暗影陷阱 1.9 对应命中半径6，R落地半径4 → 1.9*4/6≈1.3
local SHOCKWAVE_SCALE = 1.3

local function PlayShockwave(inst)
    local fx = CreateEntity()

    fx:AddTag("FX")
    fx.persists = false

    fx.entity:AddTransform()
    fx.entity:AddAnimState()

    local x, _, z = inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, 0, z)

    fx.AnimState:SetBank("mushroombomb_base")
    fx.AnimState:SetBuild("mushroombomb_base")
    fx.AnimState:PlayAnimation("idle")
    fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    fx.AnimState:SetLayer(LAYER_BACKGROUND)
    fx.AnimState:SetSortOrder(3)
    fx.AnimState:SetFinalOffset(3)
    fx.AnimState:SetScale(SHOCKWAVE_SCALE, SHOCKWAVE_SCALE, 1)
    fx.AnimState:SetMultColour(0, 0, 0, .5)

    fx:ListenForEvent("animover", fx.Remove)
end

local DAMAGE_RADIUS = 4
local LAND_DAMAGE = 300

local COMBAT_MUST_TAGS = { "_combat", "_health" }
local COMBAT_CANT_TAGS = {
    "INLIMBO", "FX", "NOCLICK", "DECOR",
    "playerghost", "companion", "wall", "abigail",
    "invisible", "notarget",
}

if not TheNet:GetPVPEnabled() then
    table.insert(COMBAT_CANT_TAGS, "player")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("boom")
    inst.AnimState:SetBuild("boom")
    inst.AnimState:PlayAnimation("boom")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetScale(7, 7, 7)
    inst.AnimState:SetMultColour(1, 1, 1, 1)

    inst.SoundEmitter:PlaySound("dontstarve/common/shadow_heart/activate")

    -- 每个客户端本地生成暗影爆炸环（专用服务器无需视觉）
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, PlayShockwave)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst:ListenForEvent("animover", inst.Remove)
        return inst
    end

    inst.persists = false

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(LAND_DAMAGE)
    inst.components.combat.playerdamagepercent = 0

    inst:DoTaskInTime(0, function()
        local doer = inst.owner
        if not doer or not doer:IsValid() then
            inst:Remove()
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()

        -- 范围伤害
        local ents = TheSim:FindEntities(x, y, z, DAMAGE_RADIUS, COMBAT_MUST_TAGS, COMBAT_CANT_TAGS)
        for _, v in ipairs(ents) do
            if v:IsValid()
                and v.components.health
                and not v.components.health:IsDead()
                and v.components.combat then

                local is_follower = v.components.follower
                    and v.components.follower:GetLeader()
                    and v.components.follower:GetLeader():HasTag("player")
                local is_domesticatable = v:HasTag("domesticatable")
                local obedience = is_domesticatable
                    and v.components.domesticatable
                    and v.components.domesticatable:GetObedience() or 0
                local domestication = is_domesticatable
                    and v.components.domesticatable
                    and v.components.domesticatable:GetDomestication() or 0

                if not is_follower
                    and v ~= doer
                    and not (is_domesticatable and (obedience > 0 or domestication > 0)) then

                    v.components.combat:GetAttacked(doer, LAND_DAMAGE)
                end
            end
        end

        -- 特效
        local puff = SpawnPrefab("groundpoundring_fx")
        if puff then
            puff.Transform:SetPosition(x, y, z)
        end
    end)

    inst:ListenForEvent("animover", inst.Remove)
    -- 兜底：2秒后自毁
    inst:DoTaskInTime(2, function()
        if inst:IsValid() then
            inst:Remove()
        end
    end)

    return inst
end

return Prefab("vex_sorrow_land", fn, assets)
