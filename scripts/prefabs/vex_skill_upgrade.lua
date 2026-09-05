-- 技能强化挂件 1-4 阶
-- 放入黑影升级槽生效，高阶继承低阶全部效果
-- UI 图标 jineng_1-4 + 地面动画 jineng_1-4.zip
-- （zip名=bank=build=动画名，imagename 不带 .tex 后缀，显示时游戏自动补）

local TIER_NAMES = {
    "jineng_1",
    "jineng_2",
    "jineng_3",
    "jineng_4",
}

local function make_assets(level)
    local name = TIER_NAMES[level]
    return {
        Asset("ANIM", "anim/" .. name .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/" .. name .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. name .. ".tex"),
    }
end

local function make_skill_upgrade(level, config)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        inst:AddTag("vex_upgrade")
        inst:AddTag("vex_skill_upgrade")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetBank(TIER_NAMES[level])
        inst.AnimState:SetBuild(TIER_NAMES[level])
        inst.AnimState:PlayAnimation(TIER_NAMES[level])

        inst.skill_config = config
        inst.skill_level = level

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. TIER_NAMES[level] .. ".xml"
        inst.components.inventoryitem.imagename = TIER_NAMES[level]

        inst:AddComponent("inspectable")

        return inst
    end
end

-- Lv1: +10% 伤害, 寒心波云距/速各 +50%
-- Lv2: +25% 伤害, 生人勿近 → 3s 无敌
-- Lv3: +75% 伤害, 溟濛渐染范围 +50%, CD -25%
-- Lv4: +100% 伤害, 全技能 CD 减半

return Prefab("vex_skill_upgrade_1", make_skill_upgrade(1, {
    damage_bonus = 1.10,
    coldwave_range_mult = 1.5,
    coldwave_speed_mult = 1.5,
}), make_assets(1)),
    Prefab("vex_skill_upgrade_2", make_skill_upgrade(2, {
        damage_bonus = 1.25,
        coldwave_range_mult = 1.5,
        coldwave_speed_mult = 1.5,
        aoe_invincible = 3,     -- 生人勿近3秒无敌
    }), make_assets(2)),
    Prefab("vex_skill_upgrade_3", make_skill_upgrade(3, {
        damage_bonus = 1.75,
        coldwave_range_mult = 1.5,
        coldwave_speed_mult = 1.5,
        aoe_invincible = 3,
        mistzone_radius_mult = 1.5,
        mistzone_cd_mult = 0.75,
    }), make_assets(3)),
    Prefab("vex_skill_upgrade_4", make_skill_upgrade(4, {
        damage_bonus = 2.0,
        coldwave_range_mult = 1.5,
        coldwave_speed_mult = 1.5,
        aoe_invincible = 3,
        mistzone_radius_mult = 1.5,
        mistzone_cd_mult = 0.75,
        all_cd_mult = 0.5,      -- 全技能CD减半
    }), make_assets(4))
