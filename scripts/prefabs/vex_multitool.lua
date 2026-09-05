-- 三等级的资源名（zip内部bank/build/动画名与文件名一致）
local TIER_NAMES = {
    "vex_multitool",
    "vex_multitool_2",
    "vex_multitool_3",
}

local assets = {
    Asset("ANIM", "anim/vex_multitool.zip"),
    Asset("ANIM", "anim/vex_multitool_2.zip"),
    Asset("ANIM", "anim/vex_multitool_3.zip"),
    Asset("ANIM", "anim/swap_vex_multitool.zip"),
    Asset("ANIM", "anim/swap_vex_multitool_2.zip"),
    Asset("ANIM", "anim/swap_vex_multitool_3.zip"),
    Asset("ATLAS", "images/inventoryimages/vex_multitool.xml"),
    Asset("IMAGE", "images/inventoryimages/vex_multitool.tex"),
    Asset("ATLAS", "images/inventoryimages/vex_multitool_2.xml"),
    Asset("IMAGE", "images/inventoryimages/vex_multitool_2.tex"),
    Asset("ATLAS", "images/inventoryimages/vex_multitool_3.xml"),
    Asset("IMAGE", "images/inventoryimages/vex_multitool_3.tex"),
}

-- 手持显示：标准swap模式（参考：格温mod gw_tasui.lua）
local function onequip(inst, owner)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    local swap_name = inst._swap_name
    owner.AnimState:OverrideSymbol("swap_object", swap_name, swap_name)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local SKILL_RANGE = 5
local SKILL_USES  = 30
local E_EXCLUDE   = {"FX", "NOCLICK", "DECOR", "INLIMBO", "player"}

local function CanDestroy(v)
    return v ~= nil
        and v.components.workable ~= nil
        and not v:HasTag("farm_plant")
        and (
            v:HasTag("plant") or v:HasTag("tree") or v:HasTag("stump") or
            v:HasTag("heavy") or v:HasTag("boulder") or v:HasTag("frozen") or
            v:HasTag("gargoyle") or v:HasTag("seastack") or v:HasTag("cavedweller") or
            v:HasTag("statue") or v:HasTag("rocky") or
            v.prefab == "saltstack" or v.prefab == "rock_avocado_fruit"
        )
end

local function DoSkill(inst, owner, cd)
    inst.components.rechargeable:Discharge(cd)
    if inst.components.finiteuses then
        inst.components.finiteuses:Use(SKILL_USES)
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    -- 第一波：摧毁范围内可拆除物
    -- 注意：Lua 5.1 的 for 循环变量在闭包间共享，必须用局部变量固定捕获
    local ents = TheSim:FindEntities(x, y, z, SKILL_RANGE, nil, E_EXCLUDE)
    for _, v in pairs(ents) do
        if CanDestroy(v) then
            local target = v
            inst:DoTaskInTime(0, function()
                if target ~= nil and target:IsValid() and target.components.workable ~= nil then
                    target.components.workable:Destroy(owner)
                end
            end)
        end
    end

    -- 第二波：刨掉第一波伐木后留下的树根
    -- （树被 Destroy 后同一实体延迟转成 stump，第一次 FindEntities 时还不存在）
    -- 参考：格温mod gw_tasui 的双波延迟设计
    inst:DoTaskInTime(0.9, function()
        if not inst:IsValid() then return end
        local ents2 = TheSim:FindEntities(x, y, z, SKILL_RANGE, nil, E_EXCLUDE)
        for _, v in pairs(ents2) do
            if v:HasTag("stump") then
                local stump = v
                inst:DoTaskInTime(0, function()
                    if stump:IsValid() and stump.components.workable ~= nil then
                        stump.components.workable:Destroy(owner)
                    end
                end)
            end
        end
    end)

    -- 特效（同样固定捕获循环变量）
    for i = 1, 3 do
        local wave = i
        inst:DoTaskInTime(wave * 0.14, function()
            local pt = Vector3(x, y, z)
            for k = 0, 8 do
                local rad = wave * 1.2
                local angle = k * 2 * PI / 9
                local fxpos = pt + Vector3(rad * math.cos(angle), 0, rad * math.sin(angle))
                local fx = SpawnPrefab("groundpound_fx")
                fx.Transform:SetPosition(fxpos:Get())
                fx.Transform:SetScale(0.66, 0.66, 0.66)
            end
        end)
    end
end

local function MakeUseItemFn(cd, cost_uses)
    return function(inst)
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        inst.components.useableitem:StopUsingItem()
        if owner == nil then return false end
        if inst.components.rechargeable:GetTimeToCharge() > 0 then return false end
        if cost_uses and inst.components.finiteuses and
           inst.components.finiteuses:GetUses() < SKILL_USES then
            return false
        end
        DoSkill(inst, owner, cd)
        return false
    end
end

local function canrepairwith(inst, item)
    return item.prefab == "nightmarefuel"
end

local function make_multitool(tier)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        local name = TIER_NAMES[tier]
        inst._swap_name = "swap_" .. name

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation(name)

        inst:AddTag("sharp")
        inst:AddTag("tool")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        local chop_eff  = tier == 3 and 2 or (tier == 2 and 1.5 or 1)
        local mine_eff  = tier == 3 and 2 or (tier == 2 and 1.5 or 1)
        local dig_eff   = tier == 3 and 2 or (tier == 2 and 1.5 or 1)
        local hamm_eff  = tier == 3 and 2 or (tier == 2 and 1.5 or 1)



        -- 基础工具功能（三个等级都有）
        inst:AddComponent("tool")
        inst.components.tool:SetAction(ACTIONS.CHOP, chop_eff)
        inst.components.tool:SetAction(ACTIONS.MINE, mine_eff)
        inst.components.tool:SetAction(ACTIONS.DIG,  dig_eff)
        inst.components.tool:SetAction(ACTIONS.HAMMER, hamm_eff)

        inst:AddInherentAction(ACTIONS.TILL)
        inst:AddComponent("farmtiller")

        -- tier1/2 有耐久，tier3 无限
        if tier <= 2 then
            inst:AddComponent("finiteuses")
            inst.components.finiteuses:SetMaxUses(400)
            inst.components.finiteuses:SetUses(400)
    -- tier2 耐久耗尽不消失
            if tier == 2 then
                inst.components.finiteuses:SetOnFinished(function(i)
            -- 什么都不做，不消失
                end)
            else
                inst.components.finiteuses:SetOnFinished(function(i) i:Remove() end)
            end
            local consumption = tier == 2 and 0.5 or 1 
            inst.components.finiteuses:SetConsumption(ACTIONS.CHOP,   consumption)
            inst.components.finiteuses:SetConsumption(ACTIONS.MINE,   consumption)
            inst.components.finiteuses:SetConsumption(ACTIONS.DIG,    consumption)
            inst.components.finiteuses:SetConsumption(ACTIONS.TILL,   consumption)
            inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, consumption)
        end


        -- tier2 可用噩梦燃料修复

        if tier == 2 then
            inst.vex_repair = function(inst, item, doer)
                if item == nil or item.prefab ~= "nightmarefuel" then
                    return false
                end
                if inst.components.finiteuses:GetPercent() >= 1 then
                    return true
                end
                local itemnum = item.components.stackable
                    and item.components.stackable.stacksize or 1
                inst.components.finiteuses:Use(-80)
                if inst.components.finiteuses:GetPercent() >= 1 then
                    inst.components.finiteuses:SetPercent(1)
                end
                if itemnum > 1 then
                    item.components.stackable:Get(1)
                else
                    item:Remove()
                end
                return true
            end
        end

        -- tier2/3 有右键技能和冷却
        if tier >= 2 then
            inst:AddTag("rechargeable")
            inst:AddComponent("rechargeable")
            inst:AddComponent("useableitem")
            if tier == 2 then
                -- 消耗30耐久，冷却30秒
                inst.components.useableitem:SetOnUseFn(MakeUseItemFn(30, true))
            elseif tier == 3 then
                -- 不消耗耐久，冷却10秒
                inst.components.useableitem:SetOnUseFn(MakeUseItemFn(10, false))
            end
        end

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. name .. ".xml"
        inst.components.inventoryitem.imagename = name

        inst:AddComponent("inspectable")

        return inst
    end
end

return Prefab("vex_multitool",   make_multitool(1), assets),
       Prefab("vex_multitool_2", make_multitool(2), assets),
       Prefab("vex_multitool_3", make_multitool(3), assets)