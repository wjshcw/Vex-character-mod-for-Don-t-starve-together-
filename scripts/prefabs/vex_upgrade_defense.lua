-- UI 图标 fangyu_1-4 + 地面动画 fangyu_1-4.zip
-- （zip名=bank=build=动画名，imagename 不带 .tex 后缀，显示时游戏自动补）
local TIER_NAMES = {
    "fangyu_1",
    "fangyu_2",
    "fangyu_3",
    "fangyu_4",
}

local function make_assets(level)
    local name = TIER_NAMES[level]
    return {
        Asset("ANIM", "anim/" .. name .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/" .. name .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. name .. ".tex"),
    }
end

local function make_defense_upgrade(level, config)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        inst:AddTag("vex_upgrade")
        inst:AddTag("vex_upgrade_defense")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetBank(TIER_NAMES[level])
        inst.AnimState:SetBuild(TIER_NAMES[level])
        inst.AnimState:PlayAnimation(TIER_NAMES[level])

        inst.defense_config = config

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. TIER_NAMES[level] .. ".xml"
        inst.components.inventoryitem.imagename = TIER_NAMES[level]

        inst:AddComponent("inspectable")

        return inst
    end
end

return Prefab("vex_upgrade_defense_1", make_defense_upgrade(1, {
        absorb        = 0.85,
        planar        = 0,
        fireimmune    = false,
        freezeimmune  = false,
        knockbackimmune = false,
        sleepimmune   = false,
        gloom_split   = false,
    }), make_assets(1)),

    Prefab("vex_upgrade_defense_2", make_defense_upgrade(2, {
        absorb        = 0.95,
        planar        = 0,
        fireimmune    = false,
        freezeimmune  = false,
        knockbackimmune = false,
        sleepimmune   = false,
        gloom_split   = false,
    }), make_assets(2)),

    Prefab("vex_upgrade_defense_3", make_defense_upgrade(3, {
        absorb        = 0.95,
        planar        = 10,
        fireimmune    = true,
        freezeimmune  = true,
        knockbackimmune = true,
        sleepimmune   = false,
        gloom_split   = false,
    }), make_assets(3)),

    Prefab("vex_upgrade_defense_4", make_defense_upgrade(4, {
        absorb        = 0.95,
        planar        = 15,
        fireimmune    = true,
        freezeimmune  = true,
        knockbackimmune = true,
        sleepimmune   = true,
        gloom_split   = true,
    }), make_assets(4))