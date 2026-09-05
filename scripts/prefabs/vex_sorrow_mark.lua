-- 愁煞·标记 Buff
-- 附加到被波命中的目标上，持续4秒

local MARK_DURATION = 4

local function CreateMarkFx(target)
    local fx = CreateEntity()
    fx.entity:AddTransform()
    fx.entity:AddAnimState()
    fx.entity:SetCanSleep(false)
    fx.persists = false
    fx:AddTag("FX")
    fx:AddTag("NOCLICK")

    fx.AnimState:SetBank("groundpoundring_fx")
    fx.AnimState:SetBuild("groundpoundring_fx")
    fx.AnimState:PlayAnimation("loop")
    fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    fx.AnimState:SetMultColour(0.6, 0.1, 0.9, 0.7)
    fx.AnimState:SetScale(0.6, 0.6, 0.6)

    local x, y, z = target.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, 0, z)

    return fx
end

local function OnAttached(inst, target)
    inst.components.debuff:Stop()

    inst._mark_fx = CreateMarkFx(target)

    inst.components.debuff:Start(MARK_DURATION)
end

local function OnDetached(inst, target)
    if inst._mark_fx and inst._mark_fx:IsValid() then
        inst._mark_fx:Remove()
        inst._mark_fx = nil
    end

    if inst.casters then
        for _, caster in ipairs(inst.casters) do
            if caster and caster:IsValid() and caster.userid then
                SendModRPCToClient(
                    GetClientModRPC("vex", "sorrow_unmarked"),
                    caster.userid
                )
                caster._sorrow_mark_target = nil
                caster._sorrow_mark_time = nil
            end
        end
    end

    inst.components.debuff:Stop()
end

local function OnExtended(inst, target)
    inst.components.debuff:Start(MARK_DURATION)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    return inst
end

return Prefab("vex_sorrow_mark", fn)
