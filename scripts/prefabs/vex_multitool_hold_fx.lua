-- 多用工具·手持显示
-- 替代方案：swap包的UV数据损坏（转换工具bug），改用跟随实体挂载
-- 架构（参考：格温mod gw_hundeng.lua Follower:FollowSymbol + wx78影子FX的代理模式）：
--   服务端生成网络代理实体并SetParent到玩家
--   每个客户端本地生成非网络动画实体，Follower跟随玩家的 swap_object 符号（手部锚点）

local assets = {
    Asset("ANIM", "anim/held_vex_multitool.zip"),
}

-- 挂载偏移（swap_object符号空间的像素偏移，100px=1单位）
local HOLD_OFFSET_X = 0
local HOLD_OFFSET_Y = -30

local function PlayHoldFx(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst.AnimState:SetBank("held_vex_multitool")
    inst.AnimState:SetBuild("held_vex_multitool")
    inst.AnimState:PlayAnimation("held_vex_multitool", true)

    -- 跟随玩家手部符号（位置）
    local owner = proxy.entity:GetParent()
    if owner and owner:IsValid() then
        inst.Follower:FollowSymbol(owner.GUID, "swap_object", HOLD_OFFSET_X, HOLD_OFFSET_Y, 0)
    end

    -- 朝向角度（FACING_LEFT=1 镜像, UP=2, RIGHT=3, DOWN=4）
    local FACING_ANGLES = { [1] = 180, [2] = 90, [3] = 0, [4] = 270 }

    -- 每帧：同步朝向旋转/镜像 + 代理销毁时移除
    inst._hold_task = inst:DoPeriodicTask(FRAMES, function()
        if not proxy:IsValid() then
            inst:Remove()
            return
        end
        local owner = proxy.entity:GetParent()
        if owner and owner:IsValid() and owner.AnimState then
            local facing = owner.AnimState:GetCurrentFacing()
            inst.Transform:SetRotation(FACING_ANGLES[facing] or 0)
            if facing == 1 then
                inst.AnimState:SetScale(-1, 1, 1)
            else
                inst.AnimState:SetScale(1, 1, 1)
            end
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

    -- 每个客户端本地生成跟随动画
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, PlayHoldFx)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("vex_multitool_hold_fx", fn, assets)
