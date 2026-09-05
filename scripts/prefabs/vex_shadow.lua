local assets = {
    --Asset("ANIM", "anim/vex_shadow.zip"),  -- TODO: 地面动画待画师
    Asset("ATLAS", "images/inventoryimages/vex_shadow.xml"),
    Asset("IMAGE", "images/inventoryimages/vex_shadow.tex"),
}

local ARMOR_ABSORB = 0.2
local SPEED_MULT   = 1.1

-- 升级槽槽位编号（容器内最后3格）
local UPGRADE_SLOT_1 = 1
local UPGRADE_SLOT_2 = 2
local UPGRADE_SLOT_3 = 3

local function GetOwner(inst)
    return inst.components.inventoryitem and inst.components.inventoryitem.owner
end

-- 护目镜状态变更后的重装备刷新（刷新客户端视觉：运行时标签不会同步到已存在的装备 replica，
-- 必须重装备让客户端重建带 goggles 标签的 replica）：
-- 必须延迟到本轮 ApplyUpgrades 完成后执行 —— 同步重装备的 Unequip 会清掉本轮已加的全部效果，
-- 且其 ApplyUpgrades 被 _applying_upgrades 递归锁拦截，效果永远回不来。
-- 用一次性抑制标记防循环：刷新自身触发的重新应用不再调度下一次刷新。
local function ScheduleGoggleRefresh(inst, owner)
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() then return end
        local o = GetOwner(inst)
        if o and o.components.inventory then
            local equipped = o.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            if equipped == inst then
                o._vex_goggle_refresh_suppress = true
                o.components.inventory:Unequip(EQUIPSLOTS.BODY)
                o.components.inventory:Equip(inst)
                o._vex_goggle_refresh_suppress = nil
            end
        end
    end)
end

-- 清除所有升级效果
local function ClearUpgrades(inst)


    print(">>> ClearUpgrades called on", inst)
    -- 关闭存储饰品容器
    if inst._open_storage and inst._open_storage.components.container then
        local owner = GetOwner(inst)
        if owner then
            inst._open_storage.components.container:Close(owner)
        end
        inst._open_storage = nil
    end
    -- 清除技能强化
    local owner = GetOwner(inst)
    if owner then
        owner._vex_skill_level = 0
        owner._vex_skill_config = nil
    end
    TUNING.VEX_SKILL_DAMAGE_BONUS = 1
    TUNING.VEX_SKILL_CD_MULT = 1
    TUNING.VEX_MISTZONE_RADIUS_MULT = 1
    TUNING.VEX_MISTZONE_CD_MULT = 1
    TUNING.VEX_COLDWAVE_RANGE_MULT = 1
    TUNING.VEX_COLDWAVE_SPEED_MULT = 1

    -- 同步重置玩家 net 变量
    if owner and owner.vex_skill_cd_mult then
        owner.vex_skill_cd_mult:set(1)
        owner.vex_mistzone_radius_mult:set(1)
        owner.vex_mistzone_cd_mult:set(1)
    end

    inst:RemoveTag("goggles")
    inst:RemoveTag("waterproofer")
    if inst.components.waterproofer then
        inst:RemoveComponent("waterproofer")
    end


    local owner = GetOwner(inst)
    if inst.components.preserver then
        inst:RemoveComponent("preserver")
    end
    -- 清除飞行效果
    -- 参考：格温mod gwen.lua gw_land()（已取得制作者同意）
    if inst._vex_flight_active and owner then
        -- 飞行保护：海面/虚空上不可降落（参考：格温mod modmain.lua gw_fly RPC）
        local x, _, z = owner.Transform:GetWorldPosition()
        local can_land = TheWorld.Map:IsPassableAtPoint(x, 0, z)
        if not can_land then
            if owner.components.talker then
                owner.components.talker:Say("我可不想掉进海里喂鱼！")
            end
        else
            owner:RemoveTag("amphibious")
            owner:RemoveTag("vex_flying")
            if owner.Physics then
                -- 恢复碰撞掩码即可：飞行期间人物始终贴地（掩码仅地面），
                -- 之前的 -4*32 向下速度会把角色砸进地面再弹起，造成跑动时瞬间上移下移
                ChangeToCharacterPhysics(owner)
            end
            if owner.components.drownable then
                owner.components.drownable.enabled = true
            end
            inst._vex_flight_active = false
        end
    end
    -- 清除存储饰品上的 preserver
    if inst._open_storage and inst._open_storage:IsValid() and inst._open_storage.components.preserver then
        inst._open_storage:RemoveComponent("preserver")
    end
    -- 清除隐藏中转箱上的 preserver
    if owner and owner._vex_stash and owner._vex_stash:IsValid() and owner._vex_stash.components.preserver then
        owner._vex_stash:RemoveComponent("preserver")
    end
    if owner and owner.components.locomotor then
        owner.components.locomotor:RemoveExternalSpeedMultiplier(inst, "vex_shadow_upgrade_speed")
    end
    if inst.gloom_upgrade_task then
        inst.gloom_upgrade_task:Cancel()
        inst.gloom_upgrade_task = nil
    end

     -- 清除生存升级效果
    if owner then
        owner:RemoveTag("goggles")
        if owner.components.locomotor then
            owner.components.locomotor:RemoveExternalSpeedMultiplier(inst, "vex_shadow_upgrade_speed")
        end
        if owner.components.hunger then
            owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
        end
    end
    if inst.components.equippable then
        inst.components.equippable.insulated = false
    end
    -- 清除隔热保暖
    if inst._vex_insulation_watch then
        inst:StopWatchingWorldState("issummer", inst._vex_insulation_fn)
        inst._vex_insulation_watch = nil
        inst._vex_insulation_fn = nil
    end
    if inst.components.insulator then
        inst:RemoveComponent("insulator")
    end
    if inst._fix_temp_task then
        inst._fix_temp_task:Cancel()
        inst._fix_temp_task = nil
    end
    -- 清除护目镜和防水
    inst:RemoveTag("goggles")
    -- 护目镜失效需重装备刷新（卸下黑影时跳过：原版 Unequip 时序里槽位尚未清空，
    -- 此处 Equip 会把黑影重新穿回去并重新触发 ApplyUpgrades，导致模块效果卸下后仍然生效）
    if inst._vex_had_goggles and not inst._unequipping then
        local owner = GetOwner(inst)
        if owner then
            ScheduleGoggleRefresh(inst, owner)
        end
    end
    inst._vex_had_goggles = nil
    inst:RemoveTag("waterproofer")
    if inst.components.waterproofer then
        inst:RemoveComponent("waterproofer")
    end

    print(">>> After ClearUpgrades, goggles tag:", inst:HasTag("goggles"))

    -- 清除防御升级
    inst.components.armor:InitCondition(99999, ARMOR_ABSORB)  -- 重置为黑影基础减伤
    if inst.components.planardefense then
        inst:RemoveComponent("planardefense")
    end
    inst:RemoveTag("fireimmune")
    inst:RemoveTag("freezeimmune")
    if owner then
        if owner.components.health then
            owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
        end
        owner:RemoveTag("freezeimmune")
        owner:RemoveTag("vex_knockbackimmune")
        if inst._orig_addcoldness and owner.components.freezable then
            owner.components.freezable.AddColdness = inst._orig_addcoldness
            inst._orig_addcoldness = nil
        end
        owner:RemoveTag("napsackimmune")
        if inst._defense_onhit then
            owner:RemoveEventCallback("attacked", inst._defense_onhit)
            inst._defense_onhit = nil
        end
    end
    if inst._knockouttest_set and owner and owner.components.grogginess then
        owner.components.grogginess:SetKnockOutTest(nil)
        inst._knockouttest_set = false
    end
end

-- 根据升级槽内容应用效果
local function ApplyUpgrades(inst, override_owner)
    -- 防止递归：ClearUpgrades 关闭容器可能触发 itemlose → ApplyUpgrades → 死循环
    if inst._applying_upgrades then return end
    inst._applying_upgrades = true

    print(">>> ApplyUpgrades called on", inst)
    ClearUpgrades(inst)
    local owner = override_owner or GetOwner(inst)
    print(">>> owner:", owner)
    -- 保鲜类升级：扫描所有升级槽，取最佳保鲜率
    local best_rate = 1
    local best_gloom_per_sec = 0
    for _, slot in ipairs({UPGRADE_SLOT_1, UPGRADE_SLOT_2, UPGRADE_SLOT_3}) do
        local item = inst.components.container:GetItemInSlot(slot)
        print(">>> slot", slot, "item:", item and item.prefab or "nil")
        if item and item:HasTag("vex_upgrade_preserve") then
            local rate = item.preserve_rate
            if rate < best_rate then
                best_rate = rate
            end
        end
    end

    local has_flight = false
    local has_hunger = false
    for _, slot in ipairs({UPGRADE_SLOT_1, UPGRADE_SLOT_2, UPGRADE_SLOT_3}) do
        local item = inst.components.container:GetItemInSlot(slot)
        if item then
            -- 加速类升级
            if item:HasTag("vex_upgrade_speed") and owner then
                local bonus = item.speed_bonus or 1.1
                owner.components.locomotor:SetExternalSpeedMultiplier(
                    inst, "vex_shadow_upgrade_speed", bonus)
                if item.flight then
                    has_flight = true
                end
            end
            if item:HasTag("vex_upgrade_gloom") then
                if (item.gloom_per_sec or 0) > best_gloom_per_sec then
                    best_gloom_per_sec = item.gloom_per_sec or 0
                end
            end

            -- 生存升级
            if item:HasTag("vex_upgrade_survival") and owner then
                print(">>> found survival upgrade:", item.prefab)
                local cfg = item.survival_config
                print(">>> cfg:", cfg)
                if cfg then
                    print(">>> cfg.goggles:", cfg.goggles)
                    if cfg.hunger then
                        has_hunger = true
                    end
        -- 护目镜：给黑影本身加 tag
                    if cfg.goggles and owner then
                        print(">>> Adding goggles tag to shadow")
                        inst:AddTag("goggles")
                        inst._vex_had_goggles = true
                        if owner._vex_goggle_refresh_suppress then
                            -- 刷新循环内部的重新应用：不再调度，防止无限循环
                            owner._vex_goggle_refresh_suppress = nil
                        else
                            ScheduleGoggleRefresh(inst, owner)
                        end
                        print(">>> After AddTag, goggles tag:", inst:HasTag("goggles"))
                    end
        -- 防水：给黑影本身加 tag 和 component
                    if cfg.waterproof and cfg.waterproof > 0 then
                        inst:AddTag("waterproofer")
                        if not inst.components.waterproofer then
                            inst:AddComponent("waterproofer")
                        end
                        inst.components.waterproofer:SetEffectiveness(cfg.waterproof)
                    end
        -- 避雷：原版机制是 equippable.insulated 字段（不是标签！）
        -- Inventory:IsInsulated → Equippable:IsInsulated 返回 self.insulated
        -- （参考原版 raincoat.lua:62 inst.components.equippable.insulated = true）
                    if cfg.insulated and inst.components.equippable then
                        inst.components.equippable.insulated = true
                    end
        -- 隔热保暖：给黑影加 insulator，按季节动态切换（夏季隔热/冬季保暖）
        -- 原版机制：temperature:GetInsulation() 只统计已装备物品的 insulator 组件
                    if not cfg.fixtemp and (cfg.heat or cfg.cold) then
                        if not inst.components.insulator then
                            inst:AddComponent("insulator")
                        end
                        -- 每次应用都重建监听（模块可能更换，cfg 会变）
                        if inst._vex_insulation_watch then
                            inst:StopWatchingWorldState("issummer", inst._vex_insulation_fn)
                        end
                        inst._vex_insulation_fn = function()
                            if not inst:IsValid() then return end
                            local is_summer = TheWorld.state.issummer
                            if is_summer and cfg.heat and cfg.heat > 0 then
                                inst.components.insulator:SetInsulation(cfg.heat)
                                inst.components.insulator:SetSummer()
                            elseif not is_summer and cfg.cold and cfg.cold > 0 then
                                inst.components.insulator:SetInsulation(cfg.cold)
                                inst.components.insulator:SetWinter()
                            end
                        end
                        inst._vex_insulation_fn()
                        inst._vex_insulation_watch = inst:WatchWorldState("issummer", inst._vex_insulation_fn)
                    end
                    if cfg.fixtemp then
                        inst._fix_temp_task = inst:DoPeriodicTask(1, function()
                            if owner and owner:IsValid() and owner.components.temperature then
                                owner.components.temperature:SetTemperature(30)
                            end
                        end)
                    end
                end
            end

            if has_hunger and owner and owner.components.hunger then
                owner.components.hunger.burnratemodifiers:SetModifier(inst, 0.75)
            end

            -- 防御类升级
            if item:HasTag("vex_upgrade_defense") and owner then
                local cfg = item.defense_config
                if cfg then
                    -- 覆盖护甲减伤
                    if cfg.absorb then
                        inst.components.armor:InitCondition(99999, cfg.absorb)
                    end

                    -- 位面防御
                    if cfg.planar and cfg.planar > 0 then
                        if not inst.components.planardefense then
                            inst:AddComponent("planardefense")
                        end
                        inst.components.planardefense:SetBaseDefense(cfg.planar)
                    end

                    -- 免疫着火：让火焰伤害乘以0
                    if cfg.fireimmune then
                        inst:AddTag("fireimmune")
                        if owner.components.health then
                            owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 0)
                        end
                    end

                    -- 免疫冰冻：给黑影和玩家都加tag
                    if cfg.freezeimmune then
                        inst:AddTag("freezeimmune")
                        owner:AddTag("freezeimmune")
                        if owner.components.freezable then
                            inst._orig_addcoldness = owner.components.freezable.AddColdness
                            owner.components.freezable.AddColdness = function() end
                        end
                    end

                    -- 免疫击飞：标签由 SGwilson 击飞状态检查（modmain 补丁）
                    if cfg.knockbackimmune then
                        owner:AddTag("vex_knockbackimmune")
                    end

                    -- 免疫催眠
                    if cfg.sleepimmune then
                        owner:AddTag("napsackimmune")
                        -- grogginess component 的 knockouttest 也要处理
                        if owner.components.grogginess then
                            owner.components.grogginess:SetKnockOutTest(function() return false end)
                            inst._knockouttest_set = true
                        end
                    end

                    -- 伤害50%转gloom
                    if cfg.gloom_split then
                        inst._defense_onhit = function(owner, data)
                            if data and data.damage and data.damage > 0 then
                                local convert = data.damage * 0.5
                                -- 还回一半血
                                if owner.components.health then
                                    owner.components.health:DoDelta(convert, true, "gloom_split")
                                end
                                -- 扣 gloom
                                if owner.components.gloom then
                                    owner.components.gloom:DoDelta(-convert)
                                end
                            end
                        end
                        owner:ListenForEvent("attacked", inst._defense_onhit)  
                    end
                end
            end
        end
    end

    -- 存储饰品：取最高等级，自动开/关容器
    if owner then
        local best_storage = nil
        for _, slot in ipairs({UPGRADE_SLOT_1, UPGRADE_SLOT_2, UPGRADE_SLOT_3}) do
            local item = inst.components.container:GetItemInSlot(slot)
            if item and item:HasTag("vex_upgrade_storage") and item.components.container then
                if not best_storage or (item.storage_level or 0) > (best_storage.storage_level or 0) then
                    best_storage = item
                end
            end
        end

        -- 切换存储饰品时关闭旧容器
        if inst._open_storage and inst._open_storage ~= best_storage then
            if inst._open_storage.components.container and inst._open_storage.components.container:IsOpen() then
                inst._open_storage.components.container:Close(owner)
            end
            inst._open_storage = nil
        end

        -- 存储饰品容器打开
        if best_storage and best_storage ~= inst._open_storage then
            local container = best_storage.components.container
            print(string.format(">>> Storage: open %s slots=%d canopen=%s isopen=%s",
                best_storage.prefab or "?",
                best_storage.storage_slots or 0,
                tostring(container.canbeopened),
                tostring(container:IsOpen())))
            container.canbeopened = true
            container:Open(owner)
            -- 从隐藏中转容器恢复物品
            local stash = owner and owner._vex_stash
            if stash and stash.components.container then
                local src = stash.components.container
                for slot = 1, src:GetNumSlots() do
                    local sit = src:GetItemInSlot(slot)
                    if sit then
                        src:RemoveItemBySlot(slot)
                        if not container:IsFull() then
                            container:GiveItem(sit)
                        else
                            -- 新存储也满了，回退到中转
                            src:GiveItem(sit)
                            break
                        end
                    end
                end
            end
            inst._open_storage = best_storage
        end
    end

    -- 保鲜效果统一应用：黑影自身 + 存储饰品容器 + 隐藏中转箱
    if best_rate < 1 then
        -- 黑影自身容器（升级槽）
        if not inst.components.preserver then
            inst:AddComponent("preserver")
        end
        inst.components.preserver:SetPerishRateMultiplier(best_rate)

        -- 当前打开的存储饰品容器
        if inst._open_storage and inst._open_storage:IsValid() then
            if not inst._open_storage.components.preserver then
                inst._open_storage:AddComponent("preserver")
            end
            inst._open_storage.components.preserver:SetPerishRateMultiplier(best_rate)
        end

        -- 隐藏中转箱（切换存储饰品时物品暂存处）
        local stash = owner and owner._vex_stash
        if stash and stash:IsValid() then
            if not stash.components.preserver then
                stash:AddComponent("preserver")
            end
            stash.components.preserver:SetPerishRateMultiplier(best_rate)
        end
    end

    -- gloom 恢复任务：取最高值，只创建一个定时任务
    if best_gloom_per_sec > 0 and owner and owner.components.gloom then
        inst.gloom_upgrade_task = inst:DoPeriodicTask(1, function()
            if owner and owner:IsValid() and owner.components.gloom then
                owner.components.gloom:DoDelta(best_gloom_per_sec)
            end
        end)
    end

    -- 飞行效果：Lv4 加速模块（水面行走 + 无视障碍物）
    -- 参考：格温mod gwen_hook.lua / gwen_sg.lua（已取得制作者同意）
    if has_flight and owner then
        owner:AddTag("amphibious")
        owner:AddTag("vex_flying")
        if owner.Physics then
            RemovePhysicsColliders(owner)
        end
        if owner.components.drownable then
            owner.components.drownable.enabled = false
        end
        inst._vex_flight_active = true
    end

    -- 技能强化挂件：取最高等级生效
    local best_skill_level = 0
    local best_skill_config = nil
    for _, slot in ipairs({UPGRADE_SLOT_1, UPGRADE_SLOT_2, UPGRADE_SLOT_3}) do
        local item = inst.components.container:GetItemInSlot(slot)
        if item and item:HasTag("vex_skill_upgrade") and item.skill_level and item.skill_level > best_skill_level then
            best_skill_level = item.skill_level
            best_skill_config = item.skill_config
        end
    end
    if owner then
        owner._vex_skill_level = best_skill_level
        owner._vex_skill_config = best_skill_config
    end
    -- 同步到 TUNING 供本进程读取（服务端结算与房主客户端同进程可见）
    local cfg = (owner and best_skill_config) or {}
    TUNING.VEX_SKILL_DAMAGE_BONUS = cfg.damage_bonus or 1
    TUNING.VEX_SKILL_CD_MULT = cfg.all_cd_mult or 1
    TUNING.VEX_MISTZONE_RADIUS_MULT = cfg.mistzone_radius_mult or 1
    TUNING.VEX_MISTZONE_CD_MULT = cfg.mistzone_cd_mult or 1
    TUNING.VEX_COLDWAVE_RANGE_MULT = cfg.coldwave_range_mult or 1
    TUNING.VEX_COLDWAVE_SPEED_MULT = cfg.coldwave_speed_mult or 1

    -- 同步到玩家 net 变量：客机客户端收不到 TUNING 写入，需经网络同步
    if owner and owner.vex_skill_cd_mult then
        owner.vex_skill_cd_mult:set(cfg.all_cd_mult or 1)
        owner.vex_mistzone_radius_mult:set(cfg.mistzone_radius_mult or 1)
        owner.vex_mistzone_cd_mult:set(cfg.mistzone_cd_mult or 1)
    end

    inst._applying_upgrades = false

    -- 飞行保护：海面/虚空上加速模块被非法取下时自动从背包找回并装回
    -- 参考：格温mod modmain.lua gw_fly RPC（已取得制作者同意）
    -- 延迟到 _applying_upgrades 释放后执行，避免 GiveItem 触发 itemget → ApplyUpgrades 递归被阻断
    if inst._vex_flight_active and not has_flight and owner and owner:IsValid() then
        inst:DoTaskInTime(0, function()
            if not inst:IsValid() or not inst._vex_flight_active then return end
            local cur_owner = GetOwner(inst)
            if not cur_owner or not cur_owner:IsValid() then return end
            local x, _, z = cur_owner.Transform:GetWorldPosition()
            if not TheWorld.Map:IsPassableAtPoint(x, 0, z) then
                -- 重新扫描确认加速模块确实不在槽中
                local found = false
                for _, s in ipairs({UPGRADE_SLOT_1, UPGRADE_SLOT_2, UPGRADE_SLOT_3}) do
                    local it = inst.components.container:GetItemInSlot(s)
                    if it and it.flight and it:HasTag("vex_upgrade_speed") then
                        found = true
                        break
                    end
                end
                if not found then
                    local inv = cur_owner.components.inventory
                    if inv then
                        local speed_item = inv:FindItem(function(it)
                            return it and it.flight and it:HasTag("vex_upgrade_speed")
                        end)
                        if speed_item then
                            if cur_owner.components.talker then
                                cur_owner.components.talker:Say("我可不想掉进海里喂鱼！")
                            end
                            inv:RemoveItem(speed_item)
                            inst.components.container:GiveItem(speed_item)
                        end
                    end
                end
            end
        end)
    end
end

-- 升级槽只允许放入特定标签的物品
local function OnClose(inst, doer)
    for _, slot in ipairs({UPGRADE_SLOT_1, UPGRADE_SLOT_2, UPGRADE_SLOT_3}) do
        local item = inst.components.container:GetItemInSlot(slot)
        if item and not item:HasTag("vex_upgrade") then
            inst:DoTaskInTime(0, function()
                local current = inst.components.container:GetItemInSlot(slot)
                if current and not current:HasTag("vex_upgrade") then
                    inst.components.container:DropItemBySlot(slot)
                end
            end)
        end
    end
end

local function onitemget(inst, data)
    local item = data and data.item
    print(">>> itemget:", item and item.prefab or "nil")
    if item and item:HasTag("vex_upgrade_survival") then
        print(">>> survival upgrade detected")
        print(">>> cfg:", item.survival_config and "exists" or "nil")
        if item.survival_config then
            print(">>> goggles cfg:", item.survival_config.goggles)
        end
    end
    ApplyUpgrades(inst)
    print(">>> shadow has goggles tag:", inst:HasTag("goggles"))
end

local function onitemlose(inst, data)
    print(">>> onitemlose fired")
    local item = data and data.item
    local owner = GetOwner(inst)

    -- 飞行保护：海面/虚空上禁止取下加速模块（参考：格温mod modmain.lua gw_fly RPC）
    if item and item.flight and owner and owner:HasTag("vex_flying") then
        local x, _, z = owner.Transform:GetWorldPosition()
        if not TheWorld.Map:IsPassableAtPoint(x, 0, z) then
            if owner.components.talker then
                owner.components.talker:Say("我可不想掉进海里喂鱼！")
            end
            -- 重新装回升级槽
            inst.components.container:GiveItem(item)
            return
        end
    end

    -- hand_inv 类型容器移除物品时 data.item 可能为 nil
    -- 回退：检查当前打开的存储饰品是否已不在升级槽中
    if not item and inst._open_storage and inst._open_storage:IsValid() then
        local still_in_slot = false
        for _, slot in ipairs({UPGRADE_SLOT_1, UPGRADE_SLOT_2, UPGRADE_SLOT_3}) do
            if inst.components.container:GetItemInSlot(slot) == inst._open_storage then
                still_in_slot = true
                break
            end
        end
        if not still_in_slot then
            item = inst._open_storage
            print(">>> onitemlose fallback: using _open_storage " .. (item.prefab or "?"))
        end
    end

    print(string.format(">>> onitemlose data: item=%s hasTag=%s hasContainer=%s",
        item and item.prefab or "nil",
        tostring(item and item:HasTag("vex_upgrade_storage")),
        tostring(item and item.components and item.components.container ~= nil)))
    if item and item:HasTag("vex_upgrade_storage") and item.components.container then
        owner = GetOwner(inst)
        local stash = owner and owner._vex_stash
        -- 离开升级槽后恢复为仅可装备时打开（ApplyUpgrades 装备时会重新置 true）
        item.components.container.canbeopened = false
        print(string.format(">>> StashTransfer: item=%s owner=%s stash=%s slots=%d",
            item.prefab or "?",
            tostring(owner ~= nil),
            tostring(stash ~= nil),
            stash and stash.components.container and stash.components.container:GetNumSlots() or 0))
        if stash and stash.components.container then
            local src = item.components.container
            local dst = stash.components.container
            local count = 0
            for slot = src:GetNumSlots(), 1, -1 do
                local sit = src:GetItemInSlot(slot)
                if sit then
                    src:RemoveItemBySlot(slot)
                    if dst:IsFull() then
                        local x, y, z = owner.Transform:GetWorldPosition()
                        sit.Transform:SetPosition(x, 0, z)
                    else
                        dst:GiveItem(sit)
                        count = count + 1
                    end
                end
            end
            print(">>> StashTransfer: moved " .. count .. " items to stash")
        end
    end
    inst:DoTaskInTime(0, function()
        ApplyUpgrades(inst)
    end)
end

-- 掉落时自动吸回主人背包
local function OnDropped(inst)
    -- 关闭存储饰品容器
    if inst._open_storage and inst._open_storage.components.container then
        inst._open_storage.components.container:Close()
        inst._open_storage = nil
    end

    if inst.rerolling then
        if inst.components.container then
            inst.components.container:DropEverything()
            inst:Remove()
        end
        inst.rerolling = false
        return
    end

    if inst.vex_owner and inst.vex_owner:IsValid() then
        local owner = inst.vex_owner
        if owner.components.inventory then
            if owner.components.inventory:IsFull() then
                -- 背包满时腾出一格
                local slot1 = owner.components.inventory:GetItemInSlot(1)
                if slot1 then
                    owner.components.inventory:DropItem(slot1)
                end
            end
            owner.components.inventory:GiveItem(inst)
        end
    end
end

-- 进入背包时记录主人
local function OnPutInInventory(inst, owner)
    if owner and owner:HasTag("vex") then
        inst.vex_owner = owner
        inst:ListenForEvent("ms_playerreroll",
            function() inst.rerolling = true end, owner)
    end
end

-- 非 vex 角色拾取时立刻丢出
local function OnPickup(inst, picker)
    if not picker then return end
    if not picker:HasTag("vex") then
        inst:DoTaskInTime(0, function()
            if picker.components.inventory then
                picker.components.inventory:DropItem(inst)
            end
        end)
    end
end

local function onequip(inst, owner)
    -- 护甲减伤由 armor component 自动处理
    -- 加速
    owner.components.locomotor:SetExternalSpeedMultiplier(
        inst, "vex_shadow_speed", SPEED_MULT)

    -- TODO: 装备动画，等美术资源到位
    -- owner.AnimState:OverrideSymbol("swap_body", "vex_shadow", "swap_body")

    -- 打开容器
    if inst.components.container then
        inst.components.container:Open(owner)
    end
    ApplyUpgrades(inst, owner)
end

local function onunequip(inst, owner)
    -- 防止 ClearUpgrades 里的护目镜 re-equip 再次触发 Unequip → 死循环
    if inst._unequipping then return end
    inst._unequipping = true

    -- 关闭存储饰品容器（触发 stash 转移）
    if inst._open_storage and inst._open_storage.components.container then
        inst._open_storage.components.container:Close(owner)
        inst._open_storage = nil
    end

    -- 清除所有升级效果
    ClearUpgrades(inst)

    -- 清除基础黑影加速
    if owner and owner.components.locomotor then
        owner.components.locomotor:RemoveExternalSpeedMultiplier(inst, "vex_shadow_speed")
    end

    inst._unequipping = false

    if inst.components.container then
        inst.components.container:Close(owner)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    MakeInventoryPhysics(inst)

    -- TODO: 替换为自定义动画
    --inst.AnimState:SetBank("need_to_draw")
    --inst.AnimState:SetBuild("need_to_draw")
    --inst.AnimState:PlayAnimation("idle", true)

    -- 地图图标，TODO: 替换为 vex_shadow.tex
    inst.MiniMapEntity:SetIcon("backpack.png")

    inst:AddTag("shadow_bag")
    inst:AddTag("vex_shadow")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -- 背包物品
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/vex_shadow.xml"
    inst.components.inventoryitem.imagename = "vex_shadow"
    inst.components.inventoryitem.canonlygoinpocket = true
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPickupFn(OnPickup)

    -- 护甲 20% 减伤，耐久极大
    inst:AddComponent("armor")
    inst.components.armor:InitCondition(99999, ARMOR_ABSORB)

    -- 装备到护甲槽（body）
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -- 容器：3格存储 + 3格升级槽 = 共6格
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("vex_shadow")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.onclosefn = OnClose

    inst:ListenForEvent("itemget",  onitemget)
    inst:ListenForEvent("itemlose", onitemlose)

    inst:AddComponent("inspectable")

    -- 实体被移除时清理所有效果和容器
    inst:ListenForEvent("onremove", function()
        ClearUpgrades(inst)
        if inst.components.container then
            inst.components.container:Close()
            inst.components.container:DropEverything()
        end
    end)

    -- 存档加载（洞穴穿梭/服务器重启）后重新应用升级效果
    inst.OnLoad = function(inst, data)
        if data then
            inst:DoTaskInTime(0, function()
                if not inst:IsValid() then return end
                local owner = GetOwner(inst)
                if owner and owner:IsValid() then
                    ApplyUpgrades(inst, owner)
                end
            end)
        end
    end

    return inst
end

return Prefab("vex_shadow", fn, assets)