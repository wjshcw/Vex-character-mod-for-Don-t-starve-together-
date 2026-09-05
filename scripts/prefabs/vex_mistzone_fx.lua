-- 溟濛渐染·落地特效
-- 视觉架构（参考：游戏原版 groundpoundringfx.lua 代理+本地FX模式）：
--   服务端在目标位置生成网络代理实体
--   每个客户端本地生成非网络动画实体，播放E动画（20帧@20fps=1秒）
--   与服务端1秒延迟伤害同步，动画播完自毁

local assets = {
    Asset("ANIM", "anim/E.zip"),
}

-- 缩放 = 命中半径 × 系数（贴图266px≈2.66单位宽，系数1.8让视觉范围大于伤害直径）
local FX_SCALE_MULT = 3.6

-- 动画帧内置偏移（anim.bin 帧数据：x=+33px, y=-11px，1单位=100px）
-- 用于补偿贴图绘制中心与实体位置的错位（偏移随缩放同步放大）
local OFFSET_X_PX = 33
local OFFSET_Y_PX = -11

local function PlayFxAnim(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    local x, _, z = proxy.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, 0, z)

    inst.AnimState:SetBank("E")
    inst.AnimState:SetBuild("E")
    -- 一次性播放（完整动画，不循环），结束时刻由代理销毁控制
    inst.AnimState:PlayAnimation("E")
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    -- 覆盖实际命中范围（内圈半径2.5 × 技能强化倍率）
    local radius = 2.5 * (TUNING.VEX_MISTZONE_RADIUS_MULT or 1)
    local s = radius * FX_SCALE_MULT
    inst.AnimState:SetScale(s, s, 1)

    -- 补偿贴图内置偏移，使视觉中心对齐实体位置
    local ox = OFFSET_X_PX / 100 * s
    local oy = OFFSET_Y_PX / 100 * s
    inst.Transform:SetPosition(x - ox, 0, z - oy)

    -- 代理销毁时同步自毁（伤害落地瞬间）
    inst._vex_fx_task = inst:DoPeriodicTask(FRAMES, function()
        if not proxy:IsValid() then
            inst:Remove()
        end
    end)

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    -- 每个客户端本地生成动画（专用服务器无需视觉）
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, PlayFxAnim)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    -- 代理存活 0.667 秒：RPC 中延后 0.333 秒生成，
    -- 使动画（约0.667秒@30fps播放）结束时刻 = 伤害落地时刻（RPC后1.0秒）
    inst:DoTaskInTime(0.667, function()
        if inst:IsValid() then inst:Remove() end
    end)

    return inst
end

return Prefab("vex_mistzone_fx", fn, assets)
