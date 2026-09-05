-- 伪装帽 / 隐蔽帽 / 隐身帽
-- 装备时减少敌对生物探测范围，高阶完全中立
-- 资源（按阶）：1阶已出货（vex_hat_camouflage），2-3阶暂用 tophat 占位
-- 命名：zip名 = bank = build 名，动画名与 vanilla 帽子一致为 "anim"

-- { bank=build 名, 动画名, 是否为 mod 自带 zip }
-- 注意：原版动画（tophat 占位）不能声明 Asset("ANIM")，mod 的 Asset 只解析 mod 自身文件
local TIER_ANIMS = {
    { "vex_hat_camouflage", "anim", true },
    { "vex_hat_conceal",    "anim", true },
    { "vex_hat_invisible",  "anim", true },
}

-- UI 图标（imagename 不带 .tex 后缀，显示时游戏自动补）
local TIER_ICONS = {
    "vex_hat_camouflage",
    "vex_hat_conceal",
    "vex_hat_invisible",
}

local function make_assets(level)
    local anim = TIER_ANIMS[level]
    local icon = TIER_ICONS[level]
    local assets = {
        Asset("ATLAS", "images/inventoryimages/" .. icon .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. icon .. ".tex"),
    }
    if anim[3] then
        table.insert(assets, 1, Asset("ANIM", "anim/" .. anim[1] .. ".zip"))
    end
    return assets
end

local function onequip(inst, owner)
    if not owner or not owner:HasTag("vex") then return end
    owner._vex_hat_level = inst.hat_level
    owner._vex_hat_range_mult = inst.hat_range_mult

    -- 穿戴显示：把角色的头部符号换成帽子的 build（build 内符号名须为 swap_hat）
    -- （原版 hats.lua / 格温 gw_maozi_zhandou 的做法；equippable 不会自动渲染）
    owner.AnimState:OverrideSymbol("swap_hat", inst.AnimState:GetBuild(), "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAT_HAIR")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAIR")

    -- 特定生物中立标签
    if inst.hat_tags then
        for _, tag in ipairs(inst.hat_tags) do
            owner:AddTag(tag)
        end
    end
    owner:AddTag("vex_hat_worn")
end

local function onunequip(inst, owner)
    if not owner then return end
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAT_HAIR")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")
    owner._vex_hat_level = 0
    owner._vex_hat_range_mult = 1
    owner:RemoveTag("vex_hat_worn")

    if inst.hat_tags then
        for _, tag in ipairs(inst.hat_tags) do
            owner:RemoveTag(tag)
        end
    end
end

local function make_hat(level, name, range_mult, tags)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        local anim = TIER_ANIMS[level]
        inst.AnimState:SetBank(anim[1])
        inst.AnimState:SetBuild(anim[1])
        inst.AnimState:PlayAnimation(anim[2])

        inst:AddTag("vex_hat")
        inst:AddTag("hat")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.hat_level = level
        inst.hat_range_mult = range_mult
        inst.hat_tags = tags

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. TIER_ICONS[level] .. ".xml"
        inst.components.inventoryitem.imagename = TIER_ICONS[level]

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)

        inst:AddComponent("inspectable")

        return inst
    end
end

-- Lv1 伪装帽: 对发情牛/杀人蜂/秃鹫中立, 探测范围 ×0.7
-- Lv2 隐蔽帽: +蜘蛛/鱼人中立, 探测范围 ×0.5
-- Lv3 隐身帽: 一切中立, 探测范围 ×0

return Prefab("vex_hat_camouflage", make_hat(1, "vex_hat_camouflage", 0.7,
        {"beefalo_neutral", "insect", "buzzard_neutral"}), make_assets(1)),
    Prefab("vex_hat_conceal",    make_hat(2, "vex_hat_conceal", 0.5,
        {"beefalo_neutral", "insect", "buzzard_neutral",
         "spiderdisguise", "merm"}), make_assets(2)),
    Prefab("vex_hat_invisible",  make_hat(3, "vex_hat_invisible", 0,
        {"beefalo_neutral", "insect", "buzzard_neutral",
         "spiderdisguise", "merm"}), make_assets(3))