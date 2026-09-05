local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}

-- Your character's stats
TUNING.VEX_HEALTH = 150
TUNING.VEX_HUNGER = 150
TUNING.VEX_SANITY = 200

-- Custom starting inventory
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.VEX = {
	"vex_shadow",
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.VEX
end
local prefabs = FlattenTree(start_inv, true)

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when not a ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "vex_speed_mod", 1)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
   inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "vex_speed_mod")
end

-- When loading or spawning the character
local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
end


-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "vex.tex" )
	inst.gloom_current = net_float(inst.GUID, "vex.gloom_current", "gloom_update")
	-- 技能强化参数经网络同步给客机客户端（服务端 ApplyUpgrades 写入，客户端只读）
	inst.vex_skill_cd_mult = net_float(inst.GUID, "vex.skill_cd_mult")
	inst.vex_mistzone_radius_mult = net_float(inst.GUID, "vex.mistzone_radius_mult")
	inst.vex_mistzone_cd_mult = net_float(inst.GUID, "vex.mistzone_cd_mult")
	if TheWorld.ismastersim then
	    inst.gloom_current:set(100)
	    inst.vex_skill_cd_mult:set(1)
	    inst.vex_mistzone_radius_mult:set(1)
	    inst.vex_mistzone_cd_mult:set(1)
	end

	inst:AddTag("vex")

end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
	-- Set starting inventory
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default
	
	-- choose which sounds this character will play
	inst.soundsname = "willow"
	
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    --inst.talker_path_override = "dontstarve_DLC001/characters/"
	
	-- Stats	
	inst.components.health:SetMaxHealth(TUNING.VEX_HEALTH)
	inst.components.hunger:SetMax(TUNING.VEX_HUNGER)
	inst.components.sanity:SetMax(TUNING.VEX_SANITY)
	
	-- Damage multiplier (optional)
    inst.components.combat.damagemultiplier = 1
	
	-- Hunger rate (optional)
	inst.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE
	inst:AddComponent("gloom")

		-- 存储饰品中转容器（隐藏14格）
		local stash = SpawnPrefab("treasurechest")
		if stash then
			stash.entity:Hide()
			stash:AddTag("CLASSIFIED")
			stash.persists = false
			stash.components.container:WidgetSetup("vex_storage_14")
			-- 弹性空间：单格可无限容纳同种物品，
			-- 防止切换存储模块时超过单格上限的物品掉落
			stash.components.container:EnableInfiniteStackSize(true)
			inst._vex_stash = stash
		end


		-- 复活/出生时回收旧黑影：把旧黑影中的饰品转入新黑影，删除旧黑影及内部残留
		local function SalvageOldShadows(inst, new_shadow)
			local salvaged = 0
			for _, v in pairs(Ents) do
				if v ~= new_shadow
					and v.prefab == "vex_shadow"
					and v.vex_owner == inst
					and v.components.container then
					-- 转移槽内饰品（存储饰品的内部物品随模块实体一起走，不丢失）
					for slot = 1, v.components.container:GetNumSlots() do
						local item = v.components.container:GetItemInSlot(slot)
						if item then
							v.components.container:RemoveItemBySlot(slot)
							if new_shadow.components.container:IsFull() then
								local x, y, z = inst.Transform:GetWorldPosition()
								item.Transform:SetPosition(x, 0, z)
							else
								new_shadow.components.container:GiveItem(item)
								salvaged = salvaged + 1
							end
						end
					end
					-- 删除旧黑影（连同其内部残留物品）
					v:Remove()
				end
			end
			if salvaged > 0 then
				print(">>> Shadow salvage: transferred " .. salvaged .. " modules")
			end
		end

		-- 出生自带黑影：首次出生由起始物品表提供；
		-- 此处为复活等场景补发（延迟检查避免与起始物品重复发放）+ 回收旧黑影饰品
		inst.OnNewSpawn = function(inst)
	    	onload(inst)
	    	inst:DoTaskInTime(0.5, function()
	    		if not inst:IsValid() or not inst.components.inventory then return end
	    		local shadow = inst.components.inventory:FindItem(function(item)
	    			return item.prefab == "vex_shadow"
	    		end)
	    		if not shadow then
	    			shadow = SpawnPrefab("vex_shadow")
	    			if shadow then
	    				inst.components.inventory:GiveItem(shadow)
	    			end
	    		end
	    		if shadow then
	    			SalvageOldShadows(inst, shadow)
	    		end
	    	end)
		end

	-- 复活时获得满阴暗值
	inst:ListenForEvent("ms_respawnedfromghost", function(inst)
    	inst.components.gloom:SetPercent(1)
    	print(">>> Gloom: respawned, set to max")
	end)
	
	--击杀Boss增加gloom
	inst:ListenForEvent("killed", function(inst, data)
    	if data and data.victim then
        	local victim = data.victim
        	if victim:HasTag("epic") then
            	local max_health = victim.components.health and victim.components.health.maxhealth or 0
            	local gain = max_health * 0.005  -- 0.5%
            	inst.components.gloom:DoDelta(gain)
        	end
    	end
	end)

	-- 淘气值同比增加 gloom（每1点淘气值+2点gloom）
	inst:ListenForEvent("killed", function(inst, data)
    	if data ~= nil and data.victim ~= nil and data.victim.prefab ~= nil then
        	local naughtiness = NAUGHTY_VALUE[data.victim.prefab]
        	if naughtiness ~= nil then
            -- 排除和 kramped.lua 一样的特殊情况
            	local victim = data.victim
            	if not (victim.prefab == "pigman" and
                    	victim.components.werebeast ~= nil and
                    	victim.components.werebeast:IsInWereState())
                	and not victim:HasTag("shadowthrall_parasite_hosted")
                	and not victim.was_shadowthrall_parasited then

                	local naughty_val = FunctionOrValue(naughtiness, inst, data)
                	local gloom_gain = naughty_val * (data.stackmult or 1) * 2
                	inst.components.gloom:DoDelta(gloom_gain)
                	print(string.format(">>> Gloom: killed %s, naughty=%.1f, gloom +%.1f",
                    	victim.prefab, naughty_val, gloom_gain))
            	end
        	end
    	end
	end)


	-- 愁煞CD刷新：被标记目标在落地/波击后6秒内死亡（smallcreature除外）
		inst:ListenForEvent("killed", function(inst, data)
			if not data or not data.victim then return end
			if not inst._sorrow_land_time then return end
			if not inst._sorrow_land_target then return end

			local victim = data.victim

			-- 击杀 smallcreature 不刷新 CD
			if victim:HasTag("smallcreature") then
				inst._sorrow_land_time = nil
				inst._sorrow_land_target = nil
				return
			end

			local target = inst._sorrow_land_target

			local match = false
			if type(target) == "table" and target:IsValid() then
				match = (victim == target)
			elseif type(target) == "number" then
				match = (victim.GUID == target)
			end

			if not match then return end

			if GetTime() - inst._sorrow_land_time <= 6 then
				print(">>> Sorrow: target died within 6s, CD refreshed!")
				-- 同时清除服务端冷却（P2 服务端校验）
				inst.vex_sorrow_cd_srv = nil
				if inst.userid then
					SendModRPCToClient(GetClientModRPC("vex", "sorrow_cd_reset"), inst.userid)
				end
			end

			inst._sorrow_land_time = nil
			inst._sorrow_land_target = nil
		end)

	inst.OnLoad = onload

	
end



return MakePlayerCharacter("vex", prefabs, assets, common_postinit, master_postinit, prefabs)
