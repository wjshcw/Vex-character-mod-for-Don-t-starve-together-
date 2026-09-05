-- UI 图标 shencun_1-4 + 地面动画 shencun_1-4.zip
-- （zip名=bank=build=动画名，imagename 不带 .tex 后缀，显示时游戏自动补）
local TIER_NAMES = {
    "shencun_1",
    "shencun_2",
    "shencun_3",
    "shencun_4",
}

local function make_assets(level)
    local name = TIER_NAMES[level]
    return {
        Asset("ANIM", "anim/" .. name .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/" .. name .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. name .. ".tex"),
    }
end

local function make_survival_upgrade(level, config)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", 0.07, 0.71)

        inst:AddTag("vex_upgrade")
        inst:AddTag("vex_upgrade_survival")

        -- 防水 tag 必须在 SetPristine 之前加
        if config.waterproof and config.waterproof > 0 then
            inst:AddTag("waterproofer")
        end

        -- 护目镜 tag 必须在 SetPristine 之前加
        if config.goggles then
            inst:AddTag("goggles")
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetBank(TIER_NAMES[level])
        inst.AnimState:SetBuild(TIER_NAMES[level])
        inst.AnimState:PlayAnimation(TIER_NAMES[level])

        inst.survival_config = config

        -- 防水 component 加在饰品本身
        if config.waterproof and config.waterproof > 0 then
            inst:AddComponent("waterproofer")
            inst.components.waterproofer:SetEffectiveness(config.waterproof)
        end

        -- 隔热保暖：根据当前季节动态切换
        if not config.fixtemp and (config.heat or config.cold) then
            inst:AddComponent("insulator")

            local function UpdateInsulation()
                if not inst:IsValid() then return end
                local is_summer = TheWorld.state.issummer
                if is_summer and config.heat and config.heat > 0 then
                    inst.components.insulator:SetInsulation(config.heat)
                    inst.components.insulator:SetSummer()
                elseif not is_summer and config.cold and config.cold > 0 then
                    inst.components.insulator:SetInsulation(config.cold)
                    inst.components.insulator:SetWinter()
                end
            end

            UpdateInsulation()

            -- 季节变化时重新切换
            inst:WatchWorldState("issummer", UpdateInsulation)
            inst:ListenForEvent("onremove", function()
                inst:StopWatchingWorldState("issummer", UpdateInsulation)
            end)
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. TIER_NAMES[level] .. ".xml"
        inst.components.inventoryitem.imagename = TIER_NAMES[level]

        inst:AddComponent("inspectable")

        return inst
    end
end

return Prefab("vex_upgrade_survival_1", make_survival_upgrade(1, {
        heat       = 60,
        cold       = 60,
        waterproof = 0.20,
        insulated  = false,
        hunger     = false,
        goggles    = false,
        fixtemp    = false,
    }), make_assets(1)),

    Prefab("vex_upgrade_survival_2", make_survival_upgrade(2, {
        heat       = 120,
        cold       = 120,
        waterproof = 0.60,
        insulated  = true,
        hunger     = false,
        goggles    = false,
        fixtemp    = false,
    }), make_assets(2)),

    Prefab("vex_upgrade_survival_3", make_survival_upgrade(3, {
        heat       = 240,
        cold       = 240,
        waterproof = 1.0,
        insulated  = true,
        hunger     = true,
        goggles    = true,
        fixtemp    = false,
    }), make_assets(3)),

    Prefab("vex_upgrade_survival_4", make_survival_upgrade(4, {
        heat       = 0,
        cold       = 0,
        waterproof = 1.0,
        insulated  = true,
        hunger     = true,
        goggles    = true,
        fixtemp    = true,
    }), make_assets(4))