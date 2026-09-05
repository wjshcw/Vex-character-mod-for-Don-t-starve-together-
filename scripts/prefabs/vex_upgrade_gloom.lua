-- UI 图标 yinying_1-4 + 地面动画 yinying_1-4.zip
-- （zip名=bank=build=动画名，imagename 不带 .tex 后缀，显示时游戏自动补）
local TIER_NAMES = {
    "yinying_1",
    "yinying_2",
    "yinying_3",
    "yinying_4",
}

local function make_assets(level)
    local name = TIER_NAMES[level]
    return {
        Asset("ANIM", "anim/" .. name .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/" .. name .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. name .. ".tex"),
    }
end

-- 每分钟转换为每秒
local function make_gloom_upgrade(level, gloom_per_min, gloom_per_sec_override)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        inst:AddTag("vex_upgrade")
        inst:AddTag("vex_upgrade_gloom")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetBank(TIER_NAMES[level])
        inst.AnimState:SetBuild(TIER_NAMES[level])
        inst.AnimState:PlayAnimation(TIER_NAMES[level])

        -- 每秒增加量，tier4 直接用 override 值
        if gloom_per_sec_override then
            inst.gloom_per_sec = gloom_per_sec_override
        else
            inst.gloom_per_sec = gloom_per_min / 60
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. TIER_NAMES[level] .. ".xml"
        inst.components.inventoryitem.imagename = TIER_NAMES[level]

        inst:AddComponent("inspectable")

        return inst
    end
end

return Prefab("vex_upgrade_gloom_1", make_gloom_upgrade(1, 3),    make_assets(1)),
       Prefab("vex_upgrade_gloom_2", make_gloom_upgrade(2, 5),    make_assets(2)),
       Prefab("vex_upgrade_gloom_3", make_gloom_upgrade(3, 10),   make_assets(3)),
       Prefab("vex_upgrade_gloom_4", make_gloom_upgrade(4, 6000), make_assets(4))