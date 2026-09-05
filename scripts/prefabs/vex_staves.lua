-- 暗影法杖 + 符文法杖
-- 资源：暗影法杖 wuqi_2 / 符文法杖 wuqi_3（地面动画 + 手持swap + UI图标）

local assets = {
    Asset("ANIM", "anim/wuqi_2.zip"),
    Asset("ANIM", "anim/swap_wuqi_2.zip"),
    Asset("ATLAS", "images/inventoryimages/wuqi_2.xml"),
    Asset("IMAGE", "images/inventoryimages/wuqi_2.tex"),
    Asset("ANIM", "anim/wuqi_3.zip"),
    Asset("ANIM", "anim/swap_wuqi_3.zip"),
    Asset("ATLAS", "images/inventoryimages/wuqi_3.xml"),
    Asset("IMAGE", "images/inventoryimages/wuqi_3.tex"),
}

-- 手持显示：标准swap模式（参考：格温mod gw_tasui.lua）
local function make_equip_handlers(swap_name)
    local function onequip(inst, owner)
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
        owner.AnimState:OverrideSymbol("swap_object", swap_name, swap_name)
    end

    local function onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_object")
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
    end

    return onequip, onunequip
end

local staff_equip, staff_unequip = make_equip_handlers("swap_wuqi_2")
local rune_equip, rune_unequip = make_equip_handlers("swap_wuqi_3")

-- 暗影法杖：远程 50 伤害，无耐久
local function shadow_staff_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wuqi_2")
    inst.AnimState:SetBuild("wuqi_2")
    inst.AnimState:PlayAnimation("wuqi_2")

    inst:AddTag("rangedweapon")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(50)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetProjectile("fire_projectile")
    -- 子弹染紫：原版火焰子弹为橙黄色，乘紫色调成暗紫色（薇古斯主题色）
    inst.components.weapon.onprojectilelaunched = function(inst, attacker, target, projectile)
        if projectile ~= nil and projectile.AnimState ~= nil then
            projectile.AnimState:SetMultColour(0.6, 0.1, 0.9, 1)
        end
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/wuqi_2.xml"
    inst.components.inventoryitem.imagename = "wuqi_2"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip(staff_equip)
    inst.components.equippable:SetOnUnequip(staff_unequip)

    inst:AddComponent("inspectable")

    return inst
end

-- 符文法杖：远程 50 + 位面50 = 100真伤，1.5倍攻速，无耐久
local function rune_staff_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wuqi_3")
    inst.AnimState:SetBuild("wuqi_3")
    inst.AnimState:PlayAnimation("wuqi_3")

    inst:AddTag("rangedweapon")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(50)
    inst.components.weapon:SetRange(8, 10)
    -- 弹射子弹：复用亮茄法杖的 brilliance_projectile_fx（命中后自动弹射到附近目标，最多5次）
    inst.components.weapon:SetProjectile("brilliance_projectile_fx")
    -- 子弹染紫 + 真实伤害：
    -- 投射物命中的 weapon 参数是子弹实体，武器上的 planardamage 不会随子弹生效，
    -- 因此真实伤害必须挂在子弹的 onhit 上（包一层保留原版弹射逻辑）
    inst.components.weapon.onprojectilelaunched = function(inst, attacker, target, projectile)
        if projectile ~= nil and projectile.AnimState ~= nil then
            projectile.AnimState:SetMultColour(0.6, 0.1, 0.9, 1)
        end
        if projectile ~= nil and projectile.components.projectile ~= nil then
            local old_onhit = projectile.components.projectile.onhit
            projectile.components.projectile.onhit = function(pinst, atker, tgt)
                if old_onhit ~= nil then
                    old_onhit(pinst, atker, tgt)
                end
                -- 真实伤害50：不经过 combat:CalcDamage，无视护甲/位面防御/一切减伤buff
                if tgt ~= nil and tgt:IsValid() and tgt.components.health ~= nil then
                    tgt.components.health:DoDelta(-50, false, "vex_rune_staff", false, atker, true)
                end
            end
        end
    end
    -- 1.5倍攻速（默认 attackperiod=1 → WILSON_ATTACK_PERIOD×1=0.4s；0.667→0.267s）
    inst.components.weapon.attackperiod = 0.667

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/wuqi_3.xml"
    inst.components.inventoryitem.imagename = "wuqi_3"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip(rune_equip)
    inst.components.equippable:SetOnUnequip(rune_unequip)

    inst:AddComponent("inspectable")

    return inst
end

return Prefab("vex_shadow_staff", shadow_staff_fn, assets),
       Prefab("vex_rune_staff",   rune_staff_fn, assets)
