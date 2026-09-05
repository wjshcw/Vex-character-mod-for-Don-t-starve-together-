-- 寒心波云·波投射物
-- 穿透所有目标，前5慢(宽3)后5快(宽2.5)，总长10，飞行时长与40帧动画严格对齐
-- 视觉架构（参考：游戏原版 groundpoundringfx.lua 代理+本地FX模式）：
--   服务端代理实体负责移动与伤害（Transform:SetPosition 移动）
--   每个客户端本地生成非网络动画实体，自行模拟移动（起点/朝向/速度
--   均为确定值，本地模拟不依赖网络位置同步）

-- 三要素对齐：动画视觉时长 = 实体存活时间 = 伤害判定窗口
-- Q_bo 动画 40帧@30fps = 1.333秒；飞行时长 = 5/5 + 5/15 = 1.0 + 0.333 = 1.333秒 ✓
-- 技能强化的距离/速度倍率同乘（range_mult = speed_mult），时长不变，对齐不被破坏
local PHASE1_LEN = 5        -- 第一阶段长度
local PHASE2_LEN = 5        -- 第二阶段长度
local TOTAL_LEN = 10         -- 总长度（与 vex_coldwave.lua 指示器 GetReticleLen 保持一致）
local PHASE1_SPEED = 5       -- 第一阶段速度（慢，5/5=1.0秒）
local PHASE2_SPEED = 15      -- 第二阶段速度（快，5/15=0.333秒）
local PHASE1_WIDTH = 3       -- 第一阶段命中半径
local PHASE2_WIDTH = 2.5     -- 第二阶段命中半径（宽1太窄，远距离易空）
local WAVE_DAMAGE = 50       -- 伤害

-- 波视觉贴图：动画覆盖实际命中范围（含箭头指示器走廊）
-- 缩放 = 命中半径 × 此系数（贴图266px≈2.66单位宽）
local FX_SCALE_MULT = 1.7

local assets = {
    Asset("ANIM", "anim/Q_bo.zip"),
}

local COMBAT_MUST_TAGS = { "_combat", "_health" }
local COMBAT_CANT_TAGS = {
    "INLIMBO", "FX", "NOCLICK", "DECOR",
    "playerghost", "companion", "wall", "abigail",
    "invisible", "notarget", "player",
}

-- 客户端本地视觉实体：自行模拟波的位置/阶段/缩放
local function PlayWaveAnim(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    -- 初始位置和朝向从代理读取（生成时网络位置已同步）
    local start_x, _, start_z = proxy.Transform:GetWorldPosition()
    local rot = proxy.Transform:GetRotation() * DEGREES
    inst.Transform:SetPosition(start_x, 1, start_z)
    inst.Transform:SetRotation(proxy.Transform:GetRotation())

    inst.AnimState:SetFinalOffset(2)
    inst.AnimState:SetBank("Q_bo")
    inst.AnimState:SetBuild("Q_bo")
    inst.AnimState:PlayAnimation("Q_bo")
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    -- 本地模拟：位置 = 起点 + 朝向 × 已飞距离（阶段速度变化与缩放同步）
    -- 动画播完立即销毁（创建时就挂监听，杜绝迟到导致末帧滞留）
    inst:ListenForEvent("animover", inst.Remove)
    local travelled = 0
    local cur_speed = PHASE1_SPEED
    inst._vex_anim_task = inst:DoPeriodicTask(FRAMES, function()
        if not proxy:IsValid() then
            -- 代理消失：停止移动；动画已播完则立即销毁（否则等上面的 animover）
            print(">>> QAnimDBG: follower removed at travelled=" .. string.format("%.1f", travelled))
            if inst._vex_anim_task then
                inst._vex_anim_task:Cancel()
                inst._vex_anim_task = nil
            end
            if inst.AnimState:AnimDone() then
                inst:Remove()
            end
            return
        end
        local speed_mult = proxy._vex_speed_mult and proxy._vex_speed_mult:value() or 1
        if travelled >= PHASE1_LEN and cur_speed ~= PHASE2_SPEED then
            cur_speed = PHASE2_SPEED
        end
        travelled = travelled + cur_speed * speed_mult * FRAMES
        inst.Transform:SetPosition(
            start_x + math.cos(rot) * travelled,
            1,
            start_z - math.sin(rot) * travelled)
        local width = travelled < PHASE1_LEN and PHASE1_WIDTH or PHASE2_WIDTH
        local s = width * FX_SCALE_MULT
        inst.AnimState:SetScale(s, s, 1)
    end)

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    -- 无AnimState：纯逻辑代理实体（移动+伤害）
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    -- 技能强化速度倍率（供客户端本地模拟读取）
    inst._vex_speed_mult = net_float(inst.GUID, "vex_coldwave.speedmult", "vex_speed_mult_dirty")

    -- 每个客户端本地生成跟随动画（专用服务器无需视觉）
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, PlayWaveAnim)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.hittargets = {}

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(WAVE_DAMAGE)
    inst.components.combat.playerdamagepercent = 0

    -- 延迟一帧记录起始位置
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() then return end
        local sx, sy, sz = inst.Transform:GetWorldPosition()
        inst._start_x = sx
        inst._start_z = sz

        -- 同步技能强化倍率给客户端
        local cfg = (inst._cold_caster and inst._cold_caster._vex_skill_config) or {}
        inst._vex_speed_mult:set(cfg.coldwave_speed_mult or 1)

        inst._update_task = inst:DoPeriodicTask(FRAMES, function()
            if not inst:IsValid() then return end

            -- 计算当前位置和阶段
            local x, y, z = inst.Transform:GetWorldPosition()
            local dx = x - inst._start_x
            local dz = z - inst._start_z
            local travelled = math.sqrt(dx*dx + dz*dz)

            -- 超出自毁（考虑技能强化距/速加成）
            local cfg = (inst._cold_caster and inst._cold_caster._vex_skill_config) or {}
            local range_mult = cfg.coldwave_range_mult or 1
            if travelled >= TOTAL_LEN * range_mult then
                print(">>> QWaveDBG: server wave removed at travelled=" .. string.format("%.1f", travelled))
                inst:Remove()
                return
            end

            -- 确定当前阶段参数
            local speed, width
            if travelled < PHASE1_LEN then
                speed = PHASE1_SPEED
                width = PHASE1_WIDTH
            else
                speed = PHASE2_SPEED
                width = PHASE2_WIDTH
            end

            -- 向前移动（保持离地1单位，避免贴图被地面遮挡）
            local rot = inst.Transform:GetRotation() * DEGREES
            local speed_mult = cfg.coldwave_speed_mult or 1
            local step = speed * speed_mult * FRAMES
            inst.Transform:SetPosition(x + math.cos(rot) * step, 1, z - math.sin(rot) * step)

            -- 扫描伤害（穿透，不停止）
            local nx, ny, nz = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(nx, ny, nz, width, COMBAT_MUST_TAGS, COMBAT_CANT_TAGS)
            local owner = inst._cold_caster
            for _, v in ipairs(ents) do
                if v:IsValid() and v.components.health and not v.components.health:IsDead()
                    and v.components.combat and not inst.hittargets[v] then
                    inst.hittargets[v] = true
                    print(">>> QWaveDBG: hit " .. (v.prefab or "?") .. " at travelled=" .. string.format("%.1f", travelled) .. " width=" .. tostring(width))
                    local caster = inst._cold_caster
                    local cfg = caster and caster._vex_skill_config
                    local dmg = WAVE_DAMAGE * (cfg and cfg.damage_bonus or 1)
                    -- 暮气目标双倍伤害 + 去除暮气 + 回复gloom
                    local was_mist = v:HasTag("vex_gloom_mist")
                    if was_mist then
                        dmg = dmg * 2
                        if RemoveMist then RemoveMist(v) end
                    end
                    v.components.combat:GetAttacked(owner or inst, dmg)
                    if was_mist and caster and caster.components.gloom then
                        caster.components.gloom:DoDelta(dmg / 2)
                    end

                    -- 恐惧（40s CD）+ 暮气目标 -10s CD
                    if caster and caster:IsValid() and caster.prefab == "vex" then
                        if not caster._vex_fear_cd_end or GetTime() >= caster._vex_fear_cd_end then
                            if v.components.hauntable and v.components.hauntable.panicable then
                                v.components.hauntable:Panic(3)
                                caster._vex_fear_cd_end = GetTime() + 40
                                if caster.userid and SendModRPCToClient then
                                    SendModRPCToClient(GetClientModRPC("vex", "fear_triggered"), caster.userid)
                                end
                                print(">>> Fear: triggered on " .. (v.prefab or "?"))
                            end
                        end
                        if v:HasTag("vex_gloom_mist") and caster._vex_fear_cd_end then
                            caster._vex_fear_cd_end = caster._vex_fear_cd_end - 10
                            print(">>> Fear: CD reduced 10s (mist)")
                        end
                    end
                end
            end
        end)

        print(">>> ColdWave: started from " .. string.format("%.1f, %.1f", sx, sz))
    end)

    -- 超时兜底
    inst:DoTaskInTime(3, function()
        if inst:IsValid() then inst:Remove() end
    end)

    return inst
end

return Prefab("vex_cold_wave", fn, assets)
