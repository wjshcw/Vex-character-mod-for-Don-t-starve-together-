-- 终焉暮气 被动系统
-- 统一三维检测（每0.2秒）：
--   1. 持续性：GetTimeMoving ≥ 2秒 + 基速 ≥ 8
--   2. 突变性：Physics速度 ≥ 12（飞扑/冲撞）
--   3. 传送性：位置跳跃 ≥ 5单位（瞬移）
-- 暮气：绿色色相 + tag + 6秒自动消除

local MIST_SPEED_THRESHOLD = 8    -- 基速阈值（火鸡=8）
local MIST_MOVE_TIME = 2          -- 持续移动时间
local MIST_DURATION = 6           -- 暮气持续
local MIST_REAPPLY_CD = 1         -- 暮气消除后的重新施加冷却（秒）
local MIST_CHECK_INTERVAL = 0.2   -- 统一检测间隔（5Hz）
local MIST_NOTIFY_RANGE = 30      -- 播报范围
local LEAP_VEL_THRESHOLD = 12     -- 速度尖峰（墨荒=13.5）
local TELEPORT_DIST = 5           -- 位置跳跃（瞬移检测）
local EPIC_VEL_THRESHOLD = 10      -- Boss降阈（天体英雄等大范围攻击速度较低）

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

--------------------------------------------------------------------------------
-- 暮气定时清除任务
--------------------------------------------------------------------------------
local function ScheduleMistExpire(target)
    if target._vex_mist_expire then
        target._vex_mist_expire:Cancel()
    end
    target._vex_mist_expire = target:DoTaskInTime(MIST_DURATION, function()
        if target:IsValid() then
            RemoveMist(target)
        end
    end)
end

--------------------------------------------------------------------------------
-- 暮气清除
--------------------------------------------------------------------------------
function RemoveMist(target)
    if not target:IsValid() then return end
    target:RemoveTag("vex_gloom_mist")
    -- 重新施加冷却：防止持续快速移动的生物（蜘蛛/发条战车等）
    -- 被消除后 0.2 秒内又被检测器立即刷回
    target._vex_mist_cd_end = GLOBAL.GetTime() + MIST_REAPPLY_CD
    if target._vex_mist_fx then
        if target._vex_mist_fx:IsValid() then
            target._vex_mist_fx:Remove()
        end
        target._vex_mist_fx = nil
    end
    if target._vex_mist_expire then
        target._vex_mist_expire:Cancel()
        target._vex_mist_expire = nil
    end
    target._vex_mist_time = nil
end

--------------------------------------------------------------------------------
-- 暮气应用（覆盖全身贴图，不再变色）
--------------------------------------------------------------------------------
function ApplyMist(target)
    if target:HasTag("vex_gloom_mist") then
        target._vex_mist_time = GLOBAL.GetTime()
        ScheduleMistExpire(target)
        return
    end

    target:AddTag("vex_gloom_mist")
    target._vex_mist_time = GLOBAL.GetTime()

    -- 挂载暮气贴图（网络化FX实体，所有客户端可见）
    local fx = SpawnPrefab("vex_mist_fx")
    if fx then
        fx.entity:SetParent(target.entity)
        if fx.AttachTo then
            fx:AttachTo(target)
        end
        target._vex_mist_fx = fx
    end

    ScheduleMistExpire(target)

    print(">>> Mist: applied to " .. (target.prefab or "?"))
end

--------------------------------------------------------------------------------
-- 无视不新鲜食物惩罚（不新鲜=新鲜值，变质仍有效）
--------------------------------------------------------------------------------
AddComponentPostInit("edible", function(self)
    local _GetHunger = self.GetHunger
    local _GetSanity  = self.GetSanity
    local _GetHealth  = self.GetHealth

    function self:GetHunger(eater, ...)
        if eater and eater.prefab == "vex" and self.inst.components.perishable
            and self.inst.components.perishable:IsStale() then
            return self.hungervalue
        end
        return _GetHunger(self, eater, ...)
    end
    function self:GetSanity(eater, ...)
        if eater and eater.prefab == "vex" and self.inst.components.perishable
            and self.inst.components.perishable:IsStale() then
            return self.sanityvalue or 0
        end
        return _GetSanity(self, eater, ...)
    end
    function self:GetHealth(eater, ...)
        if eater and eater.prefab == "vex" and self.inst.components.perishable
            and self.inst.components.perishable:IsStale() then
            return self.healthvalue or 0
        end
        return _GetHealth(self, eater, ...)
    end
end)

--------------------------------------------------------------------------------
-- 暗影瘴气免疫：无伤害、1.2倍速、无视野遮蔽
--------------------------------------------------------------------------------
AddPlayerPostInit(function(inst)
    if inst.prefab ~= "vex" then return end

    -- 1. 免疫瘴气伤害（截获 health:DoDelta 中 cause="miasma" 的伤害）

    -- 2. 1.2倍速替代减速 + 拦截 player_common 的慢速覆盖
    if inst.components.miasmawatcher then
        local mw = inst.components.miasmawatcher
        mw.miasmaspeedmult = 1.2
        local _SetMiasmaSpeed = mw.SetMiasmaSpeedMultiplier
        function mw:SetMiasmaSpeedMultiplier(mult)
            _SetMiasmaSpeed(self, 1.2)  -- 永远1.2
        end
        function mw:UpdateMiasmaWalkSpeed()
            if self.hasmiasmasource:Get() and
                not self.inst.components.playervision:HasGoggleVision() and
                not self.inst.components.playervision:HasGhostVision() and
                not self.inst.components.rider:IsRiding() then
                self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "miasma", 1.2)
            else
                self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "miasma")
            end
        end
    end

    -- 3. 免疫视野遮蔽
    inst.IsInMiasma = function() return false end
end)

-- 导出供其他文件调用
GLOBAL.ApplyMist = ApplyMist
GLOBAL.RemoveMist = RemoveMist

--------------------------------------------------------------------------------
-- 猴子诅咒免疫（来源：格温mod gwen_hook.lua:546-571，格温抄自奇幻降临mod）
--------------------------------------------------------------------------------
AddComponentPostInit("cursable", function(self)
    local oldIsCursable = self.IsCursable
    function self:IsCursable(item)
        if item and item.components.curseditem and item.components.curseditem.curse == "MONKEY"
            and self.inst:HasTag("player") and self.inst.prefab == "vex" then
            return false
        end
        return oldIsCursable(self, item)
    end
    local oldApplyCurse = self.ApplyCurse
    function self:ApplyCurse(item)
        if item and item.components.curseditem and item.components.curseditem.curse == "MONKEY"
            and self.inst:HasTag("player") and self.inst.prefab == "vex" then
            item:RemoveTag("applied_curse")
            item.components.curseditem.cursed_target = nil
            return
        end
        return oldApplyCurse(self, item)
    end
    local oldForceOntoOwner = self.ForceOntoOwner
    function self:ForceOntoOwner(item)
        if item and item.components.curseditem and item.components.curseditem.curse == "MONKEY"
            and self.inst:HasTag("player") and self.inst.prefab == "vex" then
            return
        end
        return oldForceOntoOwner(self, item)
    end
end)

--------------------------------------------------------------------------------
-- 阵营克制：暗影减伤20% / 月亮增伤20% / 月亮受伤×1.2
--------------------------------------------------------------------------------
AddPlayerPostInit(function(inst)
    if inst.prefab ~= "vex" then return end

    -- 月亮阵营增伤20%
    local combat = inst.components.combat
    if combat then
        local _CalcDamage = combat.CalcDamage
        function combat:CalcDamage(target, weapon, multiplier, ...)
            local dmg = _CalcDamage(self, target, weapon, multiplier, ...)
            if target and target:HasTag("lunar_aligned") then
                dmg = dmg * 1.2
            end
            return dmg
        end
    end

    -- 暗影减伤20% + 月亮受伤×1.2 + 瘴气免疫
    local health = inst.components.health
    if health then
        local _DoDelta = health.DoDelta
        function health:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
            if amount < 0 then
                print(string.format(">>> HealthDelta: amount=%.1f cause=%s afflicter=%s",
                    amount, tostring(cause), afflicter and afflicter.prefab or "nil"))
            end
            if cause == "miasma" then
                print(">>> Miasma dmg blocked: " .. tostring(amount))
                return
            end
            if amount < 0 and afflicter and afflicter:IsValid() then
                if afflicter:HasTag("shadow_aligned") then
                    amount = amount * 0.8
                elseif afflicter:HasTag("lunar_aligned") then
                    amount = amount * 1.2
                end
            end
            return _DoDelta(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
        end
    end
end)

--------------------------------------------------------------------------------
-- 统一三维检测：持续移动 / 速度尖峰 / 位置跳跃
--------------------------------------------------------------------------------
local function StartUnifiedMonitor(target)
    target._vex_mist_last_pos = target:GetPosition()
    target._vex_mist_monitor = target:DoPeriodicTask(MIST_CHECK_INTERVAL, function()
        if not target:IsValid() then return end
        if target.components.health and target.components.health:IsDead() then return end
        if target:HasTag("vex_gloom_mist") then return end

        -- 重新施加冷却：期间继续追踪位置，
        -- 防止冷却结束后把冷却期间的位移误判为"瞬移跳跃"
        if target._vex_mist_cd_end and GLOBAL.GetTime() < target._vex_mist_cd_end then
            target._vex_mist_last_pos = target:GetPosition()
            return
        end

        local loco = target.components.locomotor
        local now_pos = target:GetPosition()

        -- 维度1：持续快速移动（基速+GetTimeMoving）
        if loco and (loco.runspeed or 0) >= MIST_SPEED_THRESHOLD then
            local tm = loco:GetTimeMoving()
            if tm and tm >= MIST_MOVE_TIME then
                ApplyMist(target)
                print(">>> Mist: " .. (target.prefab or "?") .. " running " .. string.format("%.1fs", tm))
                return
            end
        end

        -- 维度2：物理速度尖峰（飞扑/冲撞）—— epic Boss 降阈
        if target.Physics then
            local vx, vy, vz = target.Physics:GetVelocity()
            local speed = math.sqrt(vx*vx + vy*vy + vz*vz)
            local vel_thresh = target:HasTag("epic") and EPIC_VEL_THRESHOLD or LEAP_VEL_THRESHOLD
            if speed >= vel_thresh then
                ApplyMist(target)
                print(">>> Mist: " .. (target.prefab or "?") .. " vel=" .. string.format("%.0f", speed)
                    .. (target:HasTag("epic") and " (epic)" or ""))
                return
            end
        end

        -- 维度3：位置跳跃（瞬移/冲撞位移）—— epic Boss 降阈
        local dx = now_pos.x - target._vex_mist_last_pos.x
        local dz = now_pos.z - target._vex_mist_last_pos.z
        local jump = math.sqrt(dx*dx + dz*dz)
        local jump_thresh = target:HasTag("epic") and 3 or TELEPORT_DIST
        if jump >= jump_thresh then
            ApplyMist(target)
            print(">>> Mist: " .. (target.prefab or "?") .. " jump=" .. string.format("%.0f", jump)
                .. (target:HasTag("epic") and " (epic)" or ""))
        end

        target._vex_mist_last_pos = now_pos
    end)
end

--------------------------------------------------------------------------------
-- Daywalker 专属：飞扑速度仅11（<通用阈值12），监听 pounce 状态标签
--------------------------------------------------------------------------------
AddPrefabPostInit("daywalker", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    inst:DoTaskInTime(0.3, function()
        if not inst:IsValid() then return end
        inst:ListenForEvent("newstate", function(inst, data)
            if not data or not data.state or not data.state.tags then return end
            for _, tag in ipairs(data.state.tags) do
                if tag == "pounce" or tag == "pounce_recovery" then
                    ApplyMist(inst)
                    print(">>> Mist: daywalker pounce (tag=" .. tag .. ")")
                    return
                end
            end
        end)
    end)
end)

AddPrefabPostInit("daywalker2", function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    inst:DoTaskInTime(0.3, function()
        if not inst:IsValid() then return end
        inst:ListenForEvent("newstate", function(inst, data)
            if not data or not data.state or not data.state.tags then return end
            for _, tag in ipairs(data.state.tags) do
                if tag == "pounce" or tag == "pounce_recovery" or tag == "tackle" then
                    ApplyMist(inst)
                    print(">>> Mist: daywalker2 pounce/tackle (tag=" .. tag .. ")")
                    return
                end
            end
        end)
    end)
end)

--------------------------------------------------------------------------------
-- 天体英雄专属：翻滚/冲撞 SG 标签检测（SetMotorVelOverride(10) 可能不触发 GetVelocity）
--------------------------------------------------------------------------------
local function HookAlterguardian(prefab)
    AddPrefabPostInit(prefab, function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end
        inst:DoTaskInTime(0.5, function()
            if not inst:IsValid() then return end
            inst:ListenForEvent("newstate", function(inst, data)
                if not data or not data.state or not data.state.tags then return end
                for _, tag in ipairs(data.state.tags) do
                    if tag == "charge" then
                        ApplyMist(inst)
                        print(">>> Mist: alterguardian charge (tag=" .. tag .. ")")
                        return
                    end
                end
            end)
        end)
    end)
end
HookAlterguardian("alterguardian_phase1")
HookAlterguardian("alterguardian_phase2")
HookAlterguardian("alterguardian_phase3")
HookAlterguardian("alterguardian_phase4_lunarrift")

--------------------------------------------------------------------------------
-- 全局：为所有战斗生物挂统一监测
--------------------------------------------------------------------------------
AddPrefabPostInitAny(function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    if inst:HasTag("player") then return end
    if inst:HasTag("wall") then return end
    if inst:HasTag("veggie") then return end
    if inst:HasTag("FX") then return end
    if inst:HasTag("NOCLICK") then return end
    if inst:HasTag("DECOR") then return end
    if not inst.components.combat then return end
    if not inst.Physics then return end

    inst:DoTaskInTime(0.3, function()
        if not inst:IsValid() then return end
        StartUnifiedMonitor(inst)
    end)
end)

-- 清理：移除/死亡时清除暮气贴图和标签（仅服务端、仅有战斗组件的实体）
AddPrefabPostInitAny(function(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    if not inst.components.combat and not inst:HasTag("player") then return end
    local function cleanup()
        if inst._vex_mist_fx then
            if inst._vex_mist_fx:IsValid() then
                inst._vex_mist_fx:Remove()
            end
            inst._vex_mist_fx = nil
        end
        if inst._vex_mist_expire then
            inst._vex_mist_expire:Cancel()
            inst._vex_mist_expire = nil
        end
        inst:RemoveTag("vex_gloom_mist")
    end
    inst:ListenForEvent("onremove", cleanup)
    inst:ListenForEvent("death", cleanup)
end)

--------------------------------------------------------------------------------
-- 玩家端：暮气计数播报
--------------------------------------------------------------------------------
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(1, function()
        if inst.prefab ~= "vex" then return end
        -- 仅客户端本地玩家播报，服务端不重复
        if inst ~= GLOBAL.ThePlayer then return end

        inst._mist_last_count = 0

        inst._mist_notify_task = inst:DoPeriodicTask(1, function()
            if not inst:IsValid() then return end
            if inst:HasTag("playerghost") then return end

            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = GLOBAL.TheSim:FindEntities(x, y, z, MIST_NOTIFY_RANGE,
                { "vex_gloom_mist" }, { "player", "playerghost", "INLIMBO" })

            local count = #ents
            local last = inst._mist_last_count

            if count ~= last then
                inst._mist_last_count = count
                if count > 0 then
                    if inst.components.talker then
                        inst.components.talker:Say("周围暮气: " .. count, 2)
                    end
                    print(">>> Mist nearby: " .. count)
                else
                    if inst.components.talker then
                        inst.components.talker:Say("暮气消散", 2)
                    end
                    print(">>> Mist nearby: cleared")
                end
            end
        end)
    end)
end)

--------------------------------------------------------------------------------
-- 暮气远程攻击：服务端扩展 Vex 对暮气目标的攻击/命中距离
--------------------------------------------------------------------------------
local MIST_ATTACK_RANGE = 8
local MIST_HIT_RANGE = 9

AddComponentPostInit("combat", function(self)
    if not self.inst:HasTag("vex") then return end

    local _CalcAttackRangeSq = self.CalcAttackRangeSq
    function self:CalcAttackRangeSq(target)
        if target and target:HasTag("vex_gloom_mist") then
            local r = target:GetPhysicsRadius(0) + MIST_ATTACK_RANGE
            return r * r
        end
        return _CalcAttackRangeSq(self, target)
    end

    local _CalcHitRangeSq = self.CalcHitRangeSq
    function self:CalcHitRangeSq(target)
        if target and target:HasTag("vex_gloom_mist") then
            local r = target:GetPhysicsRadius(0) + MIST_HIT_RANGE
            return r * r
        end
        return _CalcHitRangeSq(self, target)
    end
end)

--------------------------------------------------------------------------------
-- 伪装/隐蔽/隐身帽：敌对生物探测范围缩减
--------------------------------------------------------------------------------
AddComponentPostInit("combat", function(self)
    local _ShouldAggro = self.ShouldAggro
    function self:ShouldAggro(target, ...)
        if target and target:HasTag("vex_hat_worn") then
            -- 攻击后3秒内破隐（即使隐身帽也正常反击）
            if target._vex_hat_revealed and GetTime() < target._vex_hat_revealed then
                return _ShouldAggro(self, target, ...)
            end
            local mult = target._vex_hat_range_mult
            if mult == 0 then
                return false  -- 隐身帽：完全中立
            end
            if mult and mult < 1 then
                local hat_range = self.attackrange * 2 * mult
                local distsq = self.inst:GetDistanceSqToInst(target)
                if distsq > hat_range * hat_range then
                    return false
                end
            end
        end
        return _ShouldAggro(self, target, ...)
    end
end)

-- 隐身帽攻击破隐：攻击后3秒内生物可正常反击
AddPlayerPostInit(function(inst)
    if inst.prefab ~= "vex" then return end
    inst:ListenForEvent("onhitother", function()
        inst._vex_hat_revealed = GLOBAL.GetTime() + 3
    end)
end)

print(">>> Gloom Mist passive system loaded")
