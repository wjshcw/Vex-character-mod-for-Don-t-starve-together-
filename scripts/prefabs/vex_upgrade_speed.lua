-- UI 图标 jiasu_1-4 + 地面动画 jiasu_1-4.zip
-- （zip名=bank=build=动画名，imagename 不带 .tex 后缀，显示时游戏自动补）
local TIER_NAMES = {
    "jiasu_1",
    "jiasu_2",
    "jiasu_3",
    "jiasu_4",
}

local function make_assets(level)
    local name = TIER_NAMES[level]
    return {
        Asset("ANIM", "anim/" .. name .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/" .. name .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. name .. ".tex"),
    }
end

-- 通用构造函数：config = { speed = 倍率, flight = 是否飞行 }
local function make_speed_upgrade(level, config)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        inst:AddTag("vex_upgrade")
        inst:AddTag("vex_upgrade_speed")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetBank(TIER_NAMES[level])
        inst.AnimState:SetBuild(TIER_NAMES[level])
        inst.AnimState:PlayAnimation(TIER_NAMES[level])

        inst.speed_bonus = config.speed
        inst.flight = config.flight  -- Lv4 飞行

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. TIER_NAMES[level] .. ".xml"
        inst.components.inventoryitem.imagename = TIER_NAMES[level]

        inst:AddComponent("inspectable")

        return inst
    end
end

return Prefab("vex_upgrade_speed_1", make_speed_upgrade(1, { speed = 1.15 }), make_assets(1)),
       Prefab("vex_upgrade_speed_2", make_speed_upgrade(2, { speed = 1.25 }), make_assets(2)),
       Prefab("vex_upgrade_speed_3", make_speed_upgrade(3, { speed = 1.50 }), make_assets(3)),
       Prefab("vex_upgrade_speed_4", make_speed_upgrade(4, { speed = 2.00, flight = true }), make_assets(4))