-- 寒心波云 技能逻辑
-- 按住键瞄准 → 松开发射穿透波（前10慢宽3，后10快宽1）

GLOBAL["setmetatable"](env, {
    __index = function(t, k)
        return GLOBAL["rawget"](GLOBAL, k)
    end
})

local TheInput = GLOBAL.TheInput
local DEGREES = GLOBAL.DEGREES

local VEX_COLDWAVE_KEY = GetModConfigData("Vex_ColdWave_Key") or 120  -- KEY_X = 120
local COLDWAVE_CD = 30

-- 指示器参数：单个方向箭头（位于角色前方固定距离，随鼠标旋转）
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
    m.AnimState:SetMultColour(0.3, 0.6, 0.9, 0.75)
    return m
end

local function CreateReticule(player)
    player._vex_cold_reticle = MakeArrow()
end

local function DestroyReticule(player)
    local d = player._vex_cold_reticle
    if d and d:IsValid() then d:Remove() end
    player._vex_cold_reticle = nil
end

local function UpdateReticule(player)
    local m = player._vex_cold_reticle
    if not m or not m:IsValid() then return end

    local pp = player:GetPosition()
    local mp = TheInput:GetWorldPosition()
    local dv = mp - pp
    local md = math.sqrt(dv.x*dv.x + dv.z*dv.z)
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
    if player._vex_cold_aiming then return end
    player._vex_cold_aiming = true
    CreateReticule(player)
    player._vex_cold_move = TheInput:AddMoveHandler(function()
        if player._vex_cold_aiming and player._vex_cold_reticle then
            UpdateReticule(player)
        end
    end)
    UpdateReticule(player)
end

local function IsMouseOverUI()
    local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
    return screen and screen.name ~= "HUD"
end

local function StopAimingAndFire(player)
    if not player._vex_cold_aiming then return end
    player._vex_cold_aiming = false
    DestroyReticule(player)
    player._vex_cold_move = nil

    if IsMouseOverUI() then return end

    local pp = player:GetPosition()
    local mp = TheInput:GetWorldPosition()
    local dv = mp - pp
    local md = math.sqrt(dv.x*dv.x + dv.z*dv.z)
    if md < 0.01 then
        local f = player.Transform:GetRotation() * DEGREES
        dv.x, dv.z = math.cos(f), -math.sin(f)
    else
        dv.x, dv.z = dv.x / md, dv.z / md
    end

    SendModRPCToServer(GetModRPC("vex", "cold_wave"), dv.x, dv.z)
    local sv = player.vex_skill_cd_mult and player.vex_skill_cd_mult:value() or 0
    local cd_mult = sv > 0 and sv or 1
    player.vex_coldwave_cd_end = GLOBAL.GetTime() + COLDWAVE_CD * cd_mult
end

-- 客户端初始化
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst ~= GLOBAL.ThePlayer then return end
        if inst.prefab ~= "vex" then return end
        inst._vex_cold_aiming = false
        inst._vex_cold_reticle = nil
        inst._vex_cold_move = nil
        inst.vex_coldwave_cd_end = nil
    end)
end)

-- 按键处理（仅客户端：专用服务器无 TheInput）
if GLOBAL.TheNet:GetIsClient() then
GLOBAL.TheInput:AddKeyHandler(function(key, down)
    local player = GLOBAL.ThePlayer
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end
    if key ~= VEX_COLDWAVE_KEY then return end
    if GLOBAL.TheFrontEnd:GetActiveScreen().name ~= "HUD" then return end

    if down then
        if player.vex_coldwave_cd_end and GLOBAL.GetTime() < player.vex_coldwave_cd_end then
            local rem = math.ceil(player.vex_coldwave_cd_end - GLOBAL.GetTime())
            if player.components.talker and rem > 0 then
                player.components.talker:Say("寒心波云冷却中 (" .. rem .. "s)", 1.5)
            end
            return
        end
        StartAiming(player)
    else
        if player._vex_cold_aiming then
            StopAimingAndFire(player)
        end
    end
end)
end

-- 兜底清理
AddPlayerPostInit(function(inst)
    inst:ListenForEvent("onremove", function()
        DestroyReticule(inst)
        inst._vex_cold_move = nil
        inst._vex_cold_aiming = false
    end)
end)

-- 服务端 RPC：发射波
AddModRPCHandler("vex", "cold_wave", function(player, dir_x, dir_z)
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player:HasTag("playerghost") then return end

    -- 服务端冷却校验（不信任客户端本地 CD）
    if player.vex_coldwave_cd_srv and GLOBAL.GetTime() < player.vex_coldwave_cd_srv then
        print(">>> ColdWave: rejected (server CD)")
        return
    end
    local cfg = player._vex_skill_config
    player.vex_coldwave_cd_srv = GLOBAL.GetTime() + COLDWAVE_CD * (cfg and cfg.all_cd_mult or 1)

    local px, py, pz = player.Transform:GetWorldPosition()
    local wave = GLOBAL.SpawnPrefab("vex_cold_wave")
    if not wave then return end

    -- 离地1单位：OnGround 平铺贴图在 y=0 会被地面遮挡
    wave.Transform:SetPosition(px, 1, pz)
    wave.Transform:SetRotation(math.atan2(-dir_z, dir_x) / DEGREES)
    wave._cold_caster = player
end)

print(">>> ColdWave skill system loaded")
