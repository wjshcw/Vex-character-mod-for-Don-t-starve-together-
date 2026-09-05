-- 愁煞技能核心逻辑
-- 按住键瞄准 → 松开释放波 → 命中标记 → 再次按键冲刺 → 落地伤害 → 6秒内击杀刷新CD
-- 参考：格温mod的按键+RPC模式 + 贝蕾娅mod的debuff+冲刺状态机

GLOBAL["setmetatable"](env, {
    __index = function(t, k)
        return GLOBAL["rawget"](GLOBAL, k)
    end
})

local TheInput = GLOBAL.TheInput
local ThePlayer = GLOBAL.ThePlayer
local DEGREES = GLOBAL.DEGREES
local FRAMES = GLOBAL.FRAMES

--------------------------------------------------------------------------------
-- 配置
--------------------------------------------------------------------------------
local VEX_SORROW_KEY = GetModConfigData("Vex_Sorrow_Key") or 114  -- KEY_R = 114
local SORROW_CD = 60       -- 冷却秒数

--------------------------------------------------------------------------------
-- 客户端：RPC 回调（服务端通知客户端状态变更）
--------------------------------------------------------------------------------
AddClientModRPCHandler("vex", "sorrow_marked", function(target_guid)
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    player.vex_sorrow_mark_active = true
    player.vex_sorrow_mark_target = tonumber(target_guid)
    player.vex_sorrow_mark_end = GLOBAL.GetTime() + 4
    print(">>> Sorrow: mark active, target = " .. tostring(target_guid))

    -- 4秒冲刺窗口倒计时
    if player._vex_mark_task then player._vex_mark_task:Cancel() end
    player._vex_mark_task = player:DoPeriodicTask(1, function()
        if not player:IsValid() then return end
        local remain = player.vex_sorrow_mark_end and math.ceil(player.vex_sorrow_mark_end - GLOBAL.GetTime()) or 0
        if remain > 0 and player.vex_sorrow_mark_active then
            if player.components.talker then
                player.components.talker:Say("冲刺窗口: " .. remain .. "s", 1)
            end
        else
            if player._vex_mark_task then
                player._vex_mark_task:Cancel()
                player._vex_mark_task = nil
            end
        end
    end)

    if player.components.talker then
        player.components.talker:Say("再按R冲刺！(4秒)", 2.5)
    end
end)

AddClientModRPCHandler("vex", "sorrow_unmarked", function()
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    player.vex_sorrow_mark_active = false
    player.vex_sorrow_mark_target = nil
    if player._vex_mark_task then
        player._vex_mark_task:Cancel()
        player._vex_mark_task = nil
    end
    print(">>> Sorrow: mark expired")
end)

AddClientModRPCHandler("vex", "sorrow_cd_reset", function()
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    player.vex_sorrow_cd_end = nil
    -- 清除死亡窗口倒计时
    if player._vex_window_task then
        player._vex_window_task:Cancel()
        player._vex_window_task = nil
    end
    player.vex_sorrow_window_end = nil
    print(">>> Sorrow: CD refreshed!")
    if player.components.talker then
        player.components.talker:Say("愁煞已就绪", 2)
    end
end)

-- 恐惧CD同步 + 就绪提醒
AddClientModRPCHandler("vex", "fear_triggered", function()
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    player._vex_fear_cd_end = GLOBAL.GetTime() + 40

    -- 启动就绪检测
    if player._vex_fear_ready_check then return end
    player._vex_fear_ready_check = player:DoPeriodicTask(2, function()
        if not player:IsValid() then return end
        if player._vex_fear_cd_end and GLOBAL.GetTime() >= player._vex_fear_cd_end then
            player._vex_fear_cd_end = nil
            if player._vex_fear_ready_check then
                player._vex_fear_ready_check:Cancel()
                player._vex_fear_ready_check = nil
            end
            if player.components.talker then
                player.components.talker:Say("恐惧已就绪", 2.5)
            end
            print(">>> Fear: ready!")
        end
    end)
end)

-- 服务端通知客户端：落地开始，启动6秒死亡窗口倒计时
AddClientModRPCHandler("vex", "sorrow_landed", function()
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    player.vex_sorrow_window_end = GLOBAL.GetTime() + 6

    -- 每秒播报一次倒计时
    if player._vex_window_task then
        player._vex_window_task:Cancel()
    end
    player._vex_window_task = player:DoPeriodicTask(1, function()
        if not player:IsValid() then return end
        local remain = player.vex_sorrow_window_end and math.ceil(player.vex_sorrow_window_end - GLOBAL.GetTime()) or 0
        if remain > 0 then
            if player.components.talker then
                player.components.talker:Say("击杀窗口: " .. remain .. "s", 1)
            end
        else
            if player._vex_window_task then
                player._vex_window_task:Cancel()
                player._vex_window_task = nil
            end
        end
    end)

    if player.components.talker then
        player.components.talker:Say("6秒内击杀目标可刷新CD", 2.5)
    end
end)

--------------------------------------------------------------------------------
-- 客户端：瞄准指示器——单个方向箭头（位于角色前方固定距离，随鼠标旋转）
--------------------------------------------------------------------------------

-- 指示器参数
local ARROW_DIST = 4    -- 箭头与角色的距离
local ARROW_SCALE = 1.2 -- 箭头大小

local function MakeArrow()
    local m = GLOBAL.CreateEntity()
    if not m then return nil end
    m.entity:SetCanSleep(false)
    m.persists = false
    m:AddTag("FX")
    m:AddTag("NOCLICK")
    m.entity:AddTransform()
    m.entity:AddAnimState()
    m.AnimState:SetBank("reticuleline")
    m.AnimState:SetBuild("reticuleline")
    m.AnimState:PlayAnimation("idle")
    m.AnimState:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround)
    m.AnimState:SetLayer(GLOBAL.LAYER_WORLD_BACKGROUND)
    m.AnimState:SetSortOrder(3)
    m.AnimState:SetScale(ARROW_SCALE, ARROW_SCALE, 1)
    m.AnimState:SetMultColour(0.5, 0.1, 0.9, 0.75)
    return m
end

local function CreateReticule(player)
    player._vex_reticule = MakeArrow()
end

local function DestroyReticule(player)
    local d = player._vex_reticule
    if d and d:IsValid() then d:Remove() end
    player._vex_reticule = nil
end

local function UpdateReticule(player)
    local m = player._vex_reticule
    if not m or not m:IsValid() then return end

    local pp = player:GetPosition()
    local mp = TheInput:GetWorldPosition()
    local dv = mp - pp
    local md = math.sqrt(dv.x * dv.x + dv.z * dv.z)

    if md < 0.01 then
        local f = player.Transform:GetRotation() * DEGREES
        dv.x, dv.z = math.cos(f), -math.sin(f)
    else
        dv.x, dv.z = dv.x / md, dv.z / md
    end

    -- 箭头位于角色前方固定距离
    m.Transform:SetPosition(pp.x + dv.x * ARROW_DIST, 0, pp.z + dv.z * ARROW_DIST)
    -- 箭头旋转指向瞄准方向（与波的旋转公式一致）
    m.Transform:SetRotation(math.atan2(-dv.z, dv.x) / DEGREES)
end

local function StartAiming(player)
    if player._vex_aiming then return end
    player._vex_aiming = true

    CreateReticule(player)

    player._vex_move_handler = TheInput:AddMoveHandler(function()
        if player._vex_aiming and player._vex_reticule then
            UpdateReticule(player)
        end
    end)

    UpdateReticule(player)
    print(">>> Sorrow: aiming started")
end

local function IsMouseOverUI()
    local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
    if screen and screen.name ~= "HUD" then
        return true
    end
    return false
end

local function StopAimingAndFire(player)
    if not player._vex_aiming then return end
    player._vex_aiming = false

    DestroyReticule(player)

    -- DST没有RemoveMoveHandler API，只需清引用；回调内会检查_vex_aiming为false自动跳过
    player._vex_move_handler = nil

    if IsMouseOverUI() then
        print(">>> Sorrow: cancelled (mouse over UI)")
        return
    end

    local playerpos = player:GetPosition()
    local mousepos = TheInput:GetWorldPosition()
    local dir = mousepos - playerpos
    local dist = math.sqrt(dir.x * dir.x + dir.z * dir.z)

    if dist < 0.01 then
        local facing = player.Transform:GetRotation() * DEGREES
        dir.x = math.cos(facing)
        dir.z = -math.sin(facing)
    else
        dir.x = dir.x / dist
        dir.z = dir.z / dist
    end

    SendModRPCToServer(GetModRPC("vex", "sorrow_wave"), dir.x, dir.z)
    player.vex_sorrow_cd_end = GLOBAL.GetTime() + SORROW_CD
    print(">>> Sorrow: wave fired! dir=" .. string.format("%.2f, %.2f", dir.x, dir.z))
end

--------------------------------------------------------------------------------
-- 客户端：按键处理
--------------------------------------------------------------------------------
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst ~= GLOBAL.ThePlayer then return end
        if inst.prefab ~= "vex" then return end

        inst.vex_sorrow_mark_active = false
        inst.vex_sorrow_mark_target = nil
        inst.vex_sorrow_cd_end = nil
        inst._vex_aiming = false
        inst._vex_reticule = nil
        inst._vex_move_handler = nil

        print(">>> Sorrow: client initialized for " .. inst.prefab)
    end)
end)

-- 按键（仅客户端：专用服务器无 TheInput）
if GLOBAL.TheNet:GetIsClient() then
GLOBAL.TheInput:AddKeyHandler(function(key, down)
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end
    if key ~= VEX_SORROW_KEY then return end
    if GLOBAL.TheFrontEnd:GetActiveScreen().name ~= "HUD" then return end

    if down then
        -- 情况A：有活跃标记 → 冲刺
        if player.vex_sorrow_mark_active and player.vex_sorrow_mark_target then
            SendModRPCToServer(GetModRPC("vex", "sorrow_dash"), player.vex_sorrow_mark_target)
            player.vex_sorrow_mark_active = false
            player.vex_sorrow_mark_target = nil
            -- 清理冲刺窗口倒计时
            if player._vex_mark_task then
                player._vex_mark_task:Cancel()
                player._vex_mark_task = nil
            end
            print(">>> Sorrow: dash!")
            return
        end

        -- 情况B：CD中
        if player.vex_sorrow_cd_end and GLOBAL.GetTime() < player.vex_sorrow_cd_end then
            local remaining = math.ceil(player.vex_sorrow_cd_end - GLOBAL.GetTime())
            if player.components.talker and remaining > 0 then
                player.components.talker:Say("愁煞冷却中 (" .. remaining .. "s)", 1.5)
            end
            return
        end

        -- 情况C：开始瞄准
        StartAiming(player)

    else
        -- 松开按键 → 发射波
        if player._vex_aiming then
            StopAimingAndFire(player)
        end
    end
end)
end

-- 作弊键：按 J 瞬间刷新愁煞冷却（测试用）
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst ~= GLOBAL.ThePlayer then return end
        if inst.prefab ~= "vex" then return end
        GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_J, function()
            inst.vex_sorrow_cd_end = nil
            inst.vex_coldwave_cd_end = nil
            inst.vex_aoe_cd_end = nil
            inst.vex_mistzone_cd_end = nil
            -- 同时刷新服务端冷却（P2 服务端校验后客户端 CD 无效）
            SendModRPCToServer(GetModRPC("vex", "debug_reset_cds"))
            if inst.components.talker then
                inst.components.talker:Say("全技能CD已刷新", 2)
            end
            print(">>> Cheat: all skill CDs reset")
        end)
    end)
end)

-- 兜底清理
AddPlayerPostInit(function(inst)
    inst:ListenForEvent("onremove", function()
        DestroyReticule(inst)
        inst._vex_move_handler = nil
        inst._vex_aiming = false
    end)
end)

--------------------------------------------------------------------------------
-- 服务端：RPC 处理
--------------------------------------------------------------------------------
AddModRPCHandler("vex", "sorrow_wave", function(player, dir_x, dir_z)
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end

    -- 服务端冷却校验（不信任客户端本地 CD）
    if player.vex_sorrow_cd_srv and GLOBAL.GetTime() < player.vex_sorrow_cd_srv then
        print(">>> Sorrow: rejected (server CD)")
        return
    end
    local cfg = player._vex_skill_config
    player.vex_sorrow_cd_srv = GLOBAL.GetTime() + SORROW_CD * (cfg and cfg.all_cd_mult or 1)

    -- TODO: gloom 消耗
    local px, py, pz = player.Transform:GetWorldPosition()
    local wave = GLOBAL.SpawnPrefab("vex_sorrow_wave")
    if not wave then return end

    -- 离地1单位：OnGround 平铺贴图在 y=0 会被地面遮挡
    wave.Transform:SetPosition(px, 1, pz)
    local angle = math.atan2(-dir_z, dir_x) / DEGREES  -- 与指示器同公式
    wave.Transform:SetRotation(angle)
    wave.sorrow_caster = player

    print(">>> Sorrow: wave spawned at " .. string.format("%.1f, %.1f dir=%.1f°", px, pz, angle))
end)

AddModRPCHandler("vex", "sorrow_dash", function(player, target_guid)
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end

    target_guid = tonumber(target_guid)
    if not target_guid then return end

    if not player._sorrow_mark_target or player._sorrow_mark_target ~= target_guid then
        print(">>> Sorrow: dash rejected - wrong target")
        return
    end

    local target = GLOBAL.Ents[target_guid]
    if not target or not target:IsValid() then
        print(">>> Sorrow: dash rejected - target invalid")
        return
    end

    if not player._sorrow_mark_time or GLOBAL.GetTime() - player._sorrow_mark_time > 4.5 then
        print(">>> Sorrow: dash rejected - mark expired")
        player._sorrow_mark_target = nil
        player._sorrow_mark_time = nil
        return
    end

    player._sorrow_mark_target = nil
    player._sorrow_mark_time = nil

    -- 清理标记定时器和特效
    if player._sorrow_mark_expire then
        player._sorrow_mark_expire:Cancel()
        player._sorrow_mark_expire = nil
    end
    if player._sorrow_mark_fx and player._sorrow_mark_fx:IsValid() then
        player._sorrow_mark_fx:Remove()
        player._sorrow_mark_fx = nil
    end

    local userid = player.userid
    if userid then
        SendModRPCToClient(GetClientModRPC("vex", "sorrow_unmarked"), userid)
    end

    local target_pos = target:GetPosition()
    player.sg:GoToState("vex_sorrow_dash", { target_pos = target_pos, target = target })

    print(">>> Sorrow: dashing to target at " .. string.format("%.1f, %.1f", target_pos.x, target_pos.z))
end)

-- 调试 RPC：刷新服务端技能冷却（配合客户端 J 键）
AddModRPCHandler("vex", "debug_reset_cds", function(player)
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    player.vex_aoe_cd_srv = nil
    player.vex_coldwave_cd_srv = nil
    player.vex_mistzone_cd_srv = nil
    player.vex_sorrow_cd_srv = nil
    print(">>> Cheat: server skill CDs reset")
end)

--------------------------------------------------------------------------------
-- 服务端：状态机 — 冲刺 + 落地
--------------------------------------------------------------------------------
local sorrow_dash_state = State({
    name = "vex_sorrow_dash",
    tags = { "busy", "nomorph", "noattack" },

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("atk_leap_lag")

        local target_pos = data and data.target_pos
        if target_pos then
            inst:ForceFacePoint(target_pos)
        end

        inst.components.health:SetInvincible(true)
        inst._sorrow_dash_data = data
        inst._sorrow_dash_start = inst:GetPosition()
        inst._sorrow_dash_speed = 40
        inst.sg:SetTimeout(1.5)

        print(">>> Sorrow: dash state entered")
    end,

    onupdate = function(inst, dt)
        local dd = inst._sorrow_dash_data
        if not dd or not dd.target_pos then return end

        local cur = inst:GetPosition()
        local tgt = dd.target_pos
        local dx, dz = tgt.x - cur.x, tgt.z - cur.z
        local dist = math.sqrt(dx*dx + dz*dz)

        if dist <= 2 then
            inst.Transform:SetPosition(tgt.x, 0, tgt.z)
            inst.sg:GoToState("vex_sorrow_land")
            return
        end

        local step = inst._sorrow_dash_speed * dt
        if step >= dist then
            inst.Transform:SetPosition(tgt.x, 0, tgt.z)
        else
            inst.Transform:SetPosition(cur.x + dx/dist * step, 0, cur.z + dz/dist * step)
        end
    end,

    ontimeout = function(inst)
        inst.sg:GoToState("vex_sorrow_land")
    end,

    onexit = function(inst)
        inst.components.health:SetInvincible(false)
        inst._sorrow_dash_speed = nil
        inst._sorrow_dash_start = nil
    end,
})

local sorrow_land_state = State({
    name = "vex_sorrow_land",
    tags = { "busy", "nomorph" },

    onenter = function(inst)
        inst.components.health:SetInvincible(false)
        inst.AnimState:PlayAnimation("superjump_land")

        local land_fx = SpawnPrefab("vex_sorrow_land")
        if land_fx then
            local x, y, z = inst.Transform:GetWorldPosition()
            land_fx.Transform:SetPosition(x, 0, z)
            land_fx.owner = inst
        end

        local target = inst._sorrow_dash_data and inst._sorrow_dash_data.target
        inst._sorrow_land_time = GetTime()
        inst._sorrow_land_target = target
        inst._sorrow_dash_data = nil

        inst.sg:SetTimeout(0.4)

        -- RPC 通知客户端启动6秒倒计时
        local uid = inst.userid
        if uid then
            SendModRPCToClient(GetClientModRPC("vex", "sorrow_landed"), uid)
        end

        print(">>> Sorrow: land! death window started")
    end,

    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },

    ontimeout = function(inst)
        inst.sg:GoToState("idle")
    end,

    onexit = function(inst)
        inst._sorrow_dash_data = nil
    end,
})

-- 客户端镜像：只播动画
local sorrow_dash_client = State({
    name = "vex_sorrow_dash",
    tags = { "busy", "nomorph", "noattack" },
    onenter = function(inst)
        inst.AnimState:PlayAnimation("atk_leap_lag")
        inst.sg:SetTimeout(1.5)
    end,
    ontimeout = function(inst)
        inst.sg:GoToState("idle")
    end,
})

local sorrow_land_client = State({
    name = "vex_sorrow_land",
    tags = { "busy", "nomorph" },
    onenter = function(inst)
        inst.AnimState:PlayAnimation("superjump_land")
        inst.sg:SetTimeout(0.4)
    end,
    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },
    ontimeout = function(inst)
        inst.sg:GoToState("idle")
    end,
})

-- 注册到wilson状态机
AddStategraphState("wilson", sorrow_dash_state)
AddStategraphState("wilson", sorrow_land_state)
AddStategraphState("wilson_client", sorrow_dash_client)
AddStategraphState("wilson_client", sorrow_land_client)

print(">>> Sorrow skill system loaded")
