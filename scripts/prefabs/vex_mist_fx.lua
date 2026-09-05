-- 暮气贴图 FX
-- 覆盖生物全身的贴片实体：网络化（所有客户端可见），
-- 由 ApplyMist 生成并 SetParent 挂到目标生物上，随生物移动/旋转

local assets = {
    Asset("ANIM", "anim/vex_mist_fx.zip"),
}

-- ========== 体型适配参数（按需微调）==========
local Y_MULT = 1        -- 贴图中心高度 = 生物物理半径 × 此系数
local SCALE_BASE = 1.25 -- 参照体型（半径≈0.5，如蜘蛛）的贴图缩放
local SCALE_POWER = 0.7 -- 缩放随体型的增长指数（1=线性；<1=大型生物增幅递减）
local MIN_SCALE = 0.6   -- 最小缩放（防止小型生物贴图过小）
local ALPHA = 0.5       -- 贴图透明度（1=完全不透明，0.5=半透明）
-- ============================================

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.AnimState:SetBank("vex_mist_fx")
    inst.AnimState:SetBuild("vex_mist_fx")
    inst.AnimState:PlayAnimation("vex_mist_fx", true)
    -- 半透明（RGBA 贴图的 alpha 通道参与混合）
    inst.AnimState:SetMultColour(1, 1, 1, ALPHA)
    -- 始终面向镜头（贴片效果）
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.BillBoard)
    -- 渲染层级抬升，盖在生物之上
    inst.AnimState:SetFinalOffset(2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    -- 根据目标体型适配位置和缩放（由 ApplyMist 挂载后调用）
    -- 生物原点通常在脚下：抬高到身体中心高度
    -- 缩放用次线性曲线：小型生物保持参照缩放，大型生物增幅递减
    inst.AttachTo = function(_, target)
        local r = target.Physics and target.Physics:GetRadius() or 0.5
        inst.Transform:SetPosition(0, r * Y_MULT, 0)
        local scale = math.max(MIN_SCALE, SCALE_BASE * math.pow(r / 0.5, SCALE_POWER))
        inst.AnimState:SetScale(scale, scale, 1)
    end

    return inst
end

return Prefab("vex_mist_fx", fn, assets)
