GLOBAL.setmetatable(env, {__index = function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

-- 修理动作（完全参考格温mod gw_tasui 的实现模式）
VEX_REPAIR = AddAction("VEX_REPAIR", "修理", function(act)
	if act.target ~= nil and act.target.vex_repair ~= nil then
		return act.target:vex_repair(act.invobject, act.doer, act.target)
	end
end)
VEX_REPAIR.priority = 99
VEX_REPAIR.mount_valid = true

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.VEX_REPAIR, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.VEX_REPAIR, "doshortaction"))

-- 手持噩梦燃料，右键 vex_multitool_2 / vex_gloom_weapon 时显示修复选项
-- 参数顺序：inst(手持物), doer(玩家), target(右键目标), actions, right
AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
	if target
	and (target.prefab == "vex_multitool_2" or target.prefab == "vex_gloom_weapon")
	and inst.prefab == "nightmarefuel"
	and doer and doer.prefab == "vex" then
		table.insert(actions, ACTIONS.VEX_REPAIR)
	end
end)
