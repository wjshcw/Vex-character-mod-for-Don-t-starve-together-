-- 暗影剑：近战50伤害，噩梦燃料修理
-- 资源：地面动画 wuqi_1 + 手持swap swap_wuqi_1 + UI图标 wuqi_1

local assets = {
    Asset("ANIM", "anim/wuqi_1.zip"),
    Asset("ANIM", "anim/swap_wuqi_1.zip"),
    Asset("ATLAS", "images/inventoryimages/wuqi_1.xml"),
    Asset("IMAGE", "images/inventoryimages/wuqi_1.tex"),
}

-- 手持显示：标准swap模式（参考：格温mod gw_tasui.lua）
local function onequip(inst, owner)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    owner.AnimState:OverrideSymbol("swap_object", "swap_wuqi_1", "swap_wuqi_1")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onfinished(inst)
    -- 耐久归零不消失，但武器失效（伤害归零），修理后恢复
    if inst.components.weapon then
        inst.components.weapon:SetDamage(0)
    end
end

local function onusedforcombat(inst, attacker, target)
    if inst.components.finiteuses then
        inst.components.finiteuses:Use(1)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wuqi_1")
    inst.AnimState:SetBuild("wuqi_1")
    inst.AnimState:PlayAnimation("wuqi_1")

    inst:AddTag("sharp")
    inst:AddTag("weapon")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -- 近战武器
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(50)
    inst.components.weapon:SetOnAttack(onusedforcombat)

    -- 耐久200次
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(200)
    inst.components.finiteuses:SetUses(200)
    inst.components.finiteuses:SetOnFinished(onfinished)  -- 耐久归零不消失

    -- 读档时同步损坏状态（onfinished 只在归零瞬间触发一次）
    inst.OnLoad = function(inst)
        if inst.components.finiteuses:GetPercent() <= 0 and inst.components.weapon then
            inst.components.weapon:SetDamage(0)
        end
    end

    -- 噩梦燃料修理（参考：格温mod gw_tasui 的 gwxiufu，vex_actions.lua 右键触发）
    inst.vex_repair = function(inst, item, doer)
        if item == nil or item.prefab ~= "nightmarefuel" then
            return false
        end
        if inst.components.finiteuses:GetPercent() >= 1 then
            if doer and doer.components.talker then
                doer.components.talker:Say("武器无需修理")
            end
            return true
        end
        local itemnum = item.components.stackable
            and item.components.stackable.stacksize or 1
        inst.components.finiteuses:Use(-40)  -- 每个噩梦燃料恢复40耐久
        if inst.components.finiteuses:GetPercent() >= 1 then
            inst.components.finiteuses:SetPercent(1)
        end
        if itemnum > 1 then
            item.components.stackable:Get(1)
        else
            item:Remove()
        end
        -- 修复后恢复伤害
        if inst.components.weapon then
            inst.components.weapon:SetDamage(50)
        end
        if doer and doer.components.talker then
            doer.components.talker:Say("武器已修复")
        end
        return true
    end

    -- 背包物品
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "wuqi_1"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/wuqi_1.xml"

    -- 可检查
    inst:AddComponent("inspectable")

    -- 装备 component，让武器可以被装备到手上
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("vex_gloom_weapon", fn, assets)
