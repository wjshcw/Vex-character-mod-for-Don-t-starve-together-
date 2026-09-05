-- 存储饰品 1-4 阶（3/9/12/18 格）
-- 放入黑影升级槽自动打开，取出自动关闭

-- UI 图标 + 地面动画均为 cunchu_1-4
-- （zip名=bank=build=动画名，imagename 不带 .tex 后缀，显示时游戏自动补）
local TIER_NAMES = {
    "cunchu_1",
    "cunchu_2",
    "cunchu_3",
    "cunchu_4",
}

local function make_assets(level)
    local name = TIER_NAMES[level]
    return {
        Asset("ANIM", "anim/" .. name .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/" .. name .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. name .. ".tex"),
    }
end

local WIDGET_NAMES = { "vex_storage_3", "vex_storage_9", "vex_storage_12", "vex_storage_14" }

local function make_storage(level, slots)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        inst:AddTag("vex_upgrade")
        inst:AddTag("vex_upgrade_storage")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetBank(TIER_NAMES[level])
        inst.AnimState:SetBuild(TIER_NAMES[level])
        inst.AnimState:PlayAnimation(TIER_NAMES[level])

        inst.storage_level = level
        inst.storage_slots = slots
        inst.storage_widget = WIDGET_NAMES[level] or "vex_storage_3"

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. TIER_NAMES[level] .. ".xml"
        inst.components.inventoryitem.imagename = TIER_NAMES[level]

        -- 饰品自带容器
        inst:AddComponent("container")
        inst.components.container:WidgetSetup(inst.storage_widget)
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true
        -- 仅可被装备时打开（黑影 ApplyUpgrades 会置 true 并 Open），禁止背包/地面右键打开
        inst.components.container.canbeopened = false

        -- Lv4：弹性空间，单格可无限容纳同种物品
        if level == 4 then
            inst.components.container:EnableInfiniteStackSize(true)
        end

        inst:AddComponent("inspectable")

        return inst
    end
end

return Prefab("vex_storage_1", make_storage(1, 3),  make_assets(1)),
       Prefab("vex_storage_2", make_storage(2, 9),  make_assets(2)),
       Prefab("vex_storage_3", make_storage(3, 12), make_assets(3)),
       Prefab("vex_storage_4", make_storage(4, 14), make_assets(4))
