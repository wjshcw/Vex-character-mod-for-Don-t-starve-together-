-- 生人勿近·爆发特效
-- 一次性播放boom动画（20帧），播完自毁
-- 附带暗影爆炸环：复用原版麦斯威尔暗影陷阱的蘑菇弹冲击波动画
-- （参考：原版 shadow_trap.lua OnShockwave，未改动原版参数逻辑）

local assets = {
    Asset("ANIM", "anim/boom.zip"),
}

-- 冲击波环缩放：原版暗影陷阱 1.9 对应命中半径6，W命中半径3.5 → 1.9*3.5/6≈1.1
local SHOCKWAVE_SCALE = 1.1

local function PlayShockwave(inst)
    local fx = CreateEntity()

    fx:AddTag("FX")
    fx.persists = false

    fx.entity:AddTransform()
    fx.entity:AddAnimState()

    local x, _, z = inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, 0, z)

    fx.AnimState:SetBank("mushroombomb_base")
    fx.AnimState:SetBuild("mushroombomb_base")
    fx.AnimState:PlayAnimation("idle")
    fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    fx.AnimState:SetLayer(LAYER_BACKGROUND)
    fx.AnimState:SetSortOrder(3)
    fx.AnimState:SetFinalOffset(3)
    fx.AnimState:SetScale(SHOCKWAVE_SCALE, SHOCKWAVE_SCALE, 1)
    fx.AnimState:SetMultColour(0, 0, 0, .5)

    fx:ListenForEvent("animover", fx.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.AnimState:SetBank("boom")
    inst.AnimState:SetBuild("boom")
    inst.AnimState:PlayAnimation("boom")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetScale(9, 9, 9)

    -- 每个客户端本地生成暗影爆炸环（专用服务器无需视觉）
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, PlayShockwave)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst:ListenForEvent("animover", inst.Remove)
        return inst
    end

    inst.persists = false

    -- 动画播完自毁 + 2秒兜底
    inst:ListenForEvent("animover", inst.Remove)
    inst:DoTaskInTime(2, function()
        if inst:IsValid() then inst:Remove() end
    end)

    return inst
end

return Prefab("vex_boom_fx", fn, assets)
