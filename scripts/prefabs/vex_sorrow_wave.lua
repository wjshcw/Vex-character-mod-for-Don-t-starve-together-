-- 愁煞·波投射物
-- 手动计算位置移动，逐帧扫描伤害
-- smallcreature 标签的生物直接穿过，首个非smallcreature生物停止并标记
-- 视觉架构（参考：游戏原版 groundpoundringfx.lua 代理+本地FX模式）：
--   服务端代理实体负责移动与伤害（Transform:SetPosition 移动）
--   每个客户端本地生成非网络动画实体，自行模拟移动（起点/朝向/速度
--   均为确定值，本地模拟不依赖网络位置同步）

-- 从 TUNING 读取（由 modmain.lua 统一管理，修改一处全局生效）
local WAVE_SPEED   = TUNING.VEX_SORROW_WAVE_SPEED or 15
local HIT_RADIUS   = TUNING.VEX_SORROW_HIT_RADIUS or 15
local MAX_DISTANCE = TUNING.VEX_SORROW_MAX_DIST or 500
local WAVE_DAMAGE  = TUNING.VEX_SORROW_WAVE_DAMAGE or 100

-- 波视觉贴图：动画覆盖实际命中范围（含箭头指示器走廊）
-- 缩放 = 命中半径 × 此系数（贴图266px≈2.66单位宽）
local FX_SCALE_MULT = 1.7

local assets = {
    Asset("ANIM", "anim/R_chousha_skill.zip"),
}

local COMBAT_MUST_TAGS = { "_combat", "_health" }
local COMBAT_CANT_TAGS = {
    "INLIMBO", "FX", "NOCLICK", "DECOR",
    "playerghost", "companion", "wall", "abigail",
    "invisible", "notarget", "player",
}

-- 客户端本地视觉实体：自行模拟波的位置
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
    inst.AnimState:SetBank("R_chousha_skill")
    inst.AnimState:SetBuild("R_chousha_skill")
    inst.AnimState:PlayAnimation("R_chousha_skill")
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    local s = HIT_RADIUS * FX_SCALE_MULT
    inst.AnimState:SetScale(s, s, 1)

    -- 本地模拟：位置 = 起点 + 朝向 × 已飞距离
    local travelled = 0
    inst._vex_anim_task = inst:DoPeriodicTask(FRAMES, function()
        if not proxy:IsValid() then
            inst:Remove()
            return
        end
        travelled = travelled + WAVE_SPEED * FRAMES
        inst.Transform:SetPosition(
            start_x + math.cos(rot) * travelled,
            1,
            start_z - math.sin(rot) * travelled)
    end)

    return inst
end

local function ScanAndHit(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local owner = inst.sorrow_caster

    -- 检查是否超出最大射程
    local dx = x - inst._start_x
    local dz = z - inst._start_z
    if dx * dx + dz * dz >= MAX_DISTANCE * MAX_DISTANCE then
        inst:Remove()
        return
    end

    local ents = TheSim:FindEntities(x, y, z, HIT_RADIUS, COMBAT_MUST_TAGS, COMBAT_CANT_TAGS)
    if #ents > 0 then
        print(">>> Sorrow wave: found " .. #ents .. " entities in range")
    end

    for _, v in ipairs(ents) do
        if v:IsValid()
            and v.components.health
            and not v.components.health:IsDead()
            and v.components.combat
            and not inst.hittargets[v] then

            inst.hittargets[v] = true
            local attacker = owner or inst

            print(">>> Sorrow wave: hit " .. (v.prefab or "?") .. " smallcreature=" .. tostring(v:HasTag("smallcreature")))

            -- 跳过 smallcreature，不停止波
            if v:HasTag("smallcreature") then
                v.components.combat:GetAttacked(attacker, WAVE_DAMAGE)
                -- 继续移动
            else
                -- 命中非小动物
                local caster = inst.sorrow_caster

                -- 先设 _sorrow_land_target，因为 GetAttacked 内部同步触发 killed 事件
                if caster and caster:IsValid() and caster.prefab == "vex" then
                    caster._sorrow_land_time = GetTime()
                    caster._sorrow_land_target = v
                end

                -- 造成伤害
                v.components.combat:GetAttacked(attacker, WAVE_DAMAGE)

                if caster and caster:IsValid() and caster.prefab == "vex" then
                    if v.components.health:IsDead() then
                        -- 波直接击杀 → CD 已在 killed 事件中刷新
                        print(">>> Sorrow wave: target killed by wave!")
                    else
                        -- 未击杀 → 清除 land 标记，走正常标记流程
                        caster._sorrow_land_time = nil
                        caster._sorrow_land_target = nil

                        -- 清理旧标记
                        if caster._sorrow_mark_expire then
                            caster._sorrow_mark_expire:Cancel()
                        end
                        if caster._sorrow_mark_fx and caster._sorrow_mark_fx:IsValid() then
                            caster._sorrow_mark_fx:Remove()
                        end

                        -- 新标记
                        caster._sorrow_mark_target = v.GUID
                        caster._sorrow_mark_time = GetTime()

                        -- 目标脚下生成标记光环
                        local mx, my, mz = v.Transform:GetWorldPosition()
                        local fx = SpawnPrefab("groundpoundring_fx")
                        if fx then
                            fx.Transform:SetPosition(mx, 0, mz)
                            if fx.AnimState then
                                fx.AnimState:SetMultColour(0.6, 0.1, 0.9, 0.7)
                                fx.AnimState:SetScale(0.6, 0.6, 0.6)
                            end
                            caster._sorrow_mark_fx = fx
                        end

                        -- 4秒后自动过期
                        caster._sorrow_mark_expire = caster:DoTaskInTime(4, function()
                            caster._sorrow_mark_target = nil
                            caster._sorrow_mark_time = nil
                            if caster._sorrow_mark_fx and caster._sorrow_mark_fx:IsValid() then
                                caster._sorrow_mark_fx:Remove()
                            end
                            caster._sorrow_mark_fx = nil
                            caster._sorrow_mark_expire = nil
                            local uid = caster.userid
                            if uid then
                                SendModRPCToClient(GetClientModRPC("vex", "sorrow_unmarked"), uid)
                            end
                            print(">>> Sorrow: mark expired (4s)")
                        end)

                        -- RPC 通知客户端标记已激活
                        local uid = caster.userid
                        if uid then
                            SendModRPCToClient(GetClientModRPC("vex", "sorrow_marked"), uid, v.GUID)
                        end
                        print(">>> Sorrow wave: target marked, GUID=" .. tostring(v.GUID))
                    end
                end

                -- 波停止
                inst:Remove()
                return
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    -- 无AnimState：纯逻辑代理实体（移动+伤害）
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

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

    -- 延迟一帧获取起始位置（此时 SetPosition 已由 RPC handler 调用完毕）
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() then return end
        local sx, sy, sz = inst.Transform:GetWorldPosition()
        inst._start_x = sx
        inst._start_z = sz

        -- 每帧扫描 + 移动（保持离地1单位，避免贴图被地面遮挡）
        inst._update_task = inst:DoPeriodicTask(FRAMES, function()
            if not inst:IsValid() then return end
            local rot = inst.Transform:GetRotation() * DEGREES
            local speed = WAVE_SPEED * FRAMES
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x + math.cos(rot) * speed, 1, z - math.sin(rot) * speed)
            ScanAndHit(inst)
        end)
        print(">>> Sorrow wave: started from " .. string.format("%.1f, %.1f", sx, sz))
    end)

    -- 兜底：超时自毁
    inst:DoTaskInTime(3, function()
        if inst:IsValid() then
            print(">>> Sorrow wave: timeout, self-removing")
            inst:Remove()
        end
    end)

    return inst
end

return Prefab("vex_sorrow_wave", fn, assets)
