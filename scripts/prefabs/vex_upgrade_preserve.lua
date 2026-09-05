-- 保鲜升级模块 1-4 阶
-- 资源：UI 图标 baoxian_1-4（64x64 图集）+ 地面动画 baoxian_1-4.zip
-- （zip名=bank=build=动画名，imagename 不带 .tex 后缀，显示时游戏自动补）

local TIER_NAMES = {
    "baoxian_1",
    "baoxian_2",
    "baoxian_3",
    "baoxian_4",
}

local function make_assets(level)
    local name = TIER_NAMES[level]
    return {
        Asset("ANIM", "anim/" .. name .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/" .. name .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. name .. ".tex"),
    }
end

-- rate: 腐烂速率倍率，0 = 永久保鲜，0.5 = 减缓50%
local function make_preserve_upgrade(level, rate)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        inst:AddTag("vex_upgrade")
        inst:AddTag("vex_upgrade_preserve")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetBank(TIER_NAMES[level])
        inst.AnimState:SetBuild(TIER_NAMES[level])
        inst.AnimState:PlayAnimation(TIER_NAMES[level])

        inst.preserve_rate = rate  -- ApplyUpgrades 里读取

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. TIER_NAMES[level] .. ".xml"
        inst.components.inventoryitem.imagename = TIER_NAMES[level]

        inst:AddComponent("inspectable")

        return inst
    end
end

return Prefab("vex_upgrade_preserve_1", make_preserve_upgrade(1, 0.75), make_assets(1)),  -- 减缓25%
       Prefab("vex_upgrade_preserve_2", make_preserve_upgrade(2, 0.50), make_assets(2)),  -- 减缓50%
       Prefab("vex_upgrade_preserve_3", make_preserve_upgrade(3, 0.25), make_assets(3)),  -- 减缓75%
       Prefab("vex_upgrade_preserve_4", make_preserve_upgrade(4, 0),    make_assets(4))   -- 永久保鲜
