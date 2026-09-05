GLOBAL["setmetatable"](env, {
    __index = function(t, k)
        return GLOBAL["rawget"](GLOBAL, k)
    end
})

PrefabFiles = {
    "vex",
    "vex_none",
    "vex_gloom_weapon",
    "vex_staves",
    "vex_multitool",
    "vex_shadow",
    "vex_upgrade_speed",
    "vex_upgrade_gloom",
    "vex_upgrade_preserve",
    "vex_upgrade_survival",
    "vex_upgrade_defense",
    "vex_sorrow_wave",
    "vex_sorrow_mark",
    "vex_sorrow_land",
    "vex_hats",
    "vex_storage_upgrade",
    "vex_skill_upgrade",
    "vex_cold_wave",
    "vex_mist_fx",
    "vex_mistzone_fx",
    "vex_boom_fx",
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/vex.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/vex.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/vex.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/vex.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/vex_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/vex_silho.xml" ),

    Asset( "IMAGE", "bigportraits/vex.tex" ),
    Asset( "ATLAS", "bigportraits/vex.xml" ),

    Asset( "IMAGE", "images/map_icons/vex.tex" ),
    Asset( "ATLAS", "images/map_icons/vex.xml" ),

    Asset( "IMAGE", "images/avatars/avatar_vex.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_vex.xml" ),

    Asset( "IMAGE", "images/avatars/avatar_ghost_vex.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_vex.xml" ),

    Asset( "IMAGE", "images/avatars/self_inspect_vex.tex" ),
    Asset( "ATLAS", "images/avatars/self_inspect_vex.xml" ),

    Asset( "IMAGE", "images/names_vex.tex" ),
    Asset( "ATLAS", "images/names_vex.xml" ),

    Asset( "IMAGE", "images/names_gold_vex.tex" ),
    Asset( "ATLAS", "images/names_gold_vex.xml" ),
}

AddMinimapAtlas("images/map_icons/vex.xml")

local STRINGS = GLOBAL.STRINGS

STRINGS.CHARACTER_TITLES.vex = "愁云使者"
STRINGS.CHARACTER_NAMES.vex = "薇古斯"
STRINGS.CHARACTER_DESCRIPTIONS.vex = "*喜欢独处\n*不开兴才高兴\n*有黑影相伴\n"
STRINGS.CHARACTER_QUOTES.vex = "\"行，随你的便\""
STRINGS.CHARACTER_SURVIVABILITY.vex = "easy"

STRINGS.CHARACTERS.VEX = require "speech_vex"

STRINGS.NAMES.VEX = "薇古斯"
STRINGS.SKIN_NAMES.vex_none = "Esc"

local skin_modes = {
    {
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle",
        scale = 0.75,
        offset = { 0, -25 }
    },
}


STRINGS.NAMES.VEX_MULTITOOL   = "多用工具套件"
STRINGS.NAMES.VEX_MULTITOOL_2 = "懒人工具套件"
STRINGS.NAMES.VEX_MULTITOOL_3 = "双手解放者"

STRINGS.NAMES.VEX_GLOOM_WEAPON = "抓挠黑影"
STRINGS.NAMES.VEX_SHADOW_STAFF = "黑影法杖"
STRINGS.NAMES.VEX_RUNE_STAFF   = "阴郁之拥"
STRINGS.NAMES.VEX_SHADOW       = "黑影"

STRINGS.NAMES.VEX_SKILL_UPGRADE_1 = "技能模块·一阶"
STRINGS.NAMES.VEX_SKILL_UPGRADE_2 = "技能模块·二阶"
STRINGS.NAMES.VEX_SKILL_UPGRADE_3 = "技能模块·三阶"
STRINGS.NAMES.VEX_SKILL_UPGRADE_4 = "技能模块·四阶"

STRINGS.NAMES.VEX_UPGRADE_SPEED_1    = "加速模块·一阶"
STRINGS.NAMES.VEX_UPGRADE_SPEED_2    = "加速模块·二阶"
STRINGS.NAMES.VEX_UPGRADE_SPEED_3    = "加速模块·三阶"
STRINGS.NAMES.VEX_UPGRADE_SPEED_4    = "加速模块·四阶"

STRINGS.NAMES.VEX_UPGRADE_GLOOM_1    = "阴影模块·一阶"
STRINGS.NAMES.VEX_UPGRADE_GLOOM_2    = "阴影模块·二阶"
STRINGS.NAMES.VEX_UPGRADE_GLOOM_3    = "阴影模块·三阶"
STRINGS.NAMES.VEX_UPGRADE_GLOOM_4    = "阴影模块·四阶"

STRINGS.NAMES.VEX_UPGRADE_PRESERVE_1 = "保鲜模块·一阶"
STRINGS.NAMES.VEX_UPGRADE_PRESERVE_2 = "保鲜模块·二阶"
STRINGS.NAMES.VEX_UPGRADE_PRESERVE_3 = "保鲜模块·三阶"
STRINGS.NAMES.VEX_UPGRADE_PRESERVE_4 = "保鲜模块·四阶"

STRINGS.NAMES.VEX_UPGRADE_SURVIVAL_1 = "生存模块·一阶"
STRINGS.NAMES.VEX_UPGRADE_SURVIVAL_2 = "生存模块·二阶"
STRINGS.NAMES.VEX_UPGRADE_SURVIVAL_3 = "生存模块·三阶"
STRINGS.NAMES.VEX_UPGRADE_SURVIVAL_4 = "生存模块·四阶"

STRINGS.NAMES.VEX_UPGRADE_DEFENSE_1  = "防御模块·一阶"
STRINGS.NAMES.VEX_UPGRADE_DEFENSE_2  = "防御模块·二阶"
STRINGS.NAMES.VEX_UPGRADE_DEFENSE_3  = "防御模块·三阶"
STRINGS.NAMES.VEX_UPGRADE_DEFENSE_4  = "防御模块·四阶"

STRINGS.NAMES.VEX_STORAGE_1 = "存储模块·一阶"
STRINGS.NAMES.VEX_STORAGE_2 = "存储模块·二阶"
STRINGS.NAMES.VEX_STORAGE_3 = "存储模块·三阶"
STRINGS.NAMES.VEX_STORAGE_4 = "存储模块·四阶"

STRINGS.NAMES.VEX_HAT_CAMOUFLAGE = "伪装帽"
STRINGS.NAMES.VEX_HAT_CONCEAL    = "隐蔽帽"
STRINGS.NAMES.VEX_HAT_INVISIBLE  = " "

-- 配方描述：制作栏详情面板 + 配方弹窗显示（2行截断，建议40-60字）
STRINGS.RECIPE_DESC.VEX_MULTITOOL = "黑影可以变形成任何工具。"
STRINGS.RECIPE_DESC.VEX_MULTITOOL_2 = "更轻松写意的摧毁一切。"
STRINGS.RECIPE_DESC.VEX_MULTITOOL_3 = "砍断！切开！剁碎！……所有树和石头。"

STRINGS.RECIPE_DESC.VEX_GLOOM_WEAPON = "握握手。"
STRINGS.RECIPE_DESC.VEX_SHADOW_STAFF = "远程总比近战优雅。"
STRINGS.RECIPE_DESC.VEX_RUNE_STAFF = "冥火之拥，但是黑影版。"

STRINGS.RECIPE_DESC.VEX_STORAGE_1 = "让黑影帮你背两件东西。"
STRINGS.RECIPE_DESC.VEX_STORAGE_2 = "增加黑影能容纳的物品数量。"
STRINGS.RECIPE_DESC.VEX_STORAGE_3 = "进一步增加黑影存储量。"
STRINGS.RECIPE_DESC.VEX_STORAGE_4 = "让黑影能容纳一切。"

STRINGS.RECIPE_DESC.VEX_UPGRADE_DEFENSE_1 = "让黑影代替你承受部分伤害。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_DEFENSE_2 = "黑影更为致密，能够抵御更多伤害。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_DEFENSE_3 = "融入黑雾后，黑影可防御更多类型的伤害。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_DEFENSE_4 = "黑影隔绝异常，融化兵刃。"

STRINGS.RECIPE_DESC.VEX_UPGRADE_SURVIVAL_1 = "为你遮风挡雨。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_SURVIVAL_2 = "为你偏折雷暴。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_SURVIVAL_3 = "为你清扫雾霭。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_SURVIVAL_4 = "保你衣食无忧。"

STRINGS.RECIPE_DESC.VEX_UPGRADE_PRESERVE_1 = "阴冷的黑暗，减缓物品的腐坏。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_PRESERVE_2 = "寒冷的黑暗，减缓物品的腐坏。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_PRESERVE_3 = "冰冷的黑暗，减缓物品的腐坏。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_PRESERVE_4 = "极致的黑暗，凝固物品的时间。"

STRINGS.RECIPE_DESC.VEX_SKILL_UPGRADE_1 = "面包与黄油。"
STRINGS.RECIPE_DESC.VEX_SKILL_UPGRADE_2 = "面包与果酱。"
STRINGS.RECIPE_DESC.VEX_SKILL_UPGRADE_3 = "面包与奶酪。"
STRINGS.RECIPE_DESC.VEX_SKILL_UPGRADE_4 = "面包三明治。"

STRINGS.RECIPE_DESC.VEX_UPGRADE_GLOOM_1 = "开局我只是一片小小影子……"
STRINGS.RECIPE_DESC.VEX_UPGRADE_GLOOM_2 = "暗影终将占据上风……"
STRINGS.RECIPE_DESC.VEX_UPGRADE_GLOOM_3 = "黑雾必将遍布大地……"
STRINGS.RECIPE_DESC.VEX_UPGRADE_GLOOM_4 = "谁才是暗影之王？"

STRINGS.RECIPE_DESC.VEX_UPGRADE_SPEED_1 = "影子会推着你走。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_SPEED_2 = "黑影代步。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_SPEED_3 = "光线追不上黑暗扩散的速度。"
STRINGS.RECIPE_DESC.VEX_UPGRADE_SPEED_4 = "融入黑影，无不可往。"

STRINGS.RECIPE_DESC.VEX_HAT_CAMOUFLAGE = "避免引人注目。"
STRINGS.RECIPE_DESC.VEX_HAT_CONCEAL = "让你悄然无声。"
STRINGS.RECIPE_DESC.VEX_HAT_INVISIBLE = " "
-- 其余物品照此格式补充：
-- STRINGS.RECIPE_DESC.VEX_UPGRADE_SPEED_1 = "..."

-- 通用物品描述：物品栏悬停显示
STRINGS.CHARACTERS.GENERIC.DESCRIBE.VEX_STORAGE_1 = "薇古斯的随身储物饰品。"
-- 其余物品照此格式补充：
-- STRINGS.CHARACTERS.GENERIC.DESCRIBE.VEX_UPGRADE_SPEED_1 = "..."



AddModCharacter("vex", "FEMALE", skin_modes)

-- 注册物品图标图集：配方材料/物品栏图标解析需要（GetInventoryItemAtlas 查询此表）
RegisterInventoryItemAtlas("images/inventoryimages/vex_multitool.xml",   "vex_multitool.tex")
RegisterInventoryItemAtlas("images/inventoryimages/vex_multitool_2.xml", "vex_multitool_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/vex_multitool_3.xml", "vex_multitool_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/cunchu_1.xml", "cunchu_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/cunchu_2.xml", "cunchu_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/cunchu_3.xml", "cunchu_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/cunchu_4.xml", "cunchu_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/baoxian_1.xml", "baoxian_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/baoxian_2.xml", "baoxian_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/baoxian_3.xml", "baoxian_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/baoxian_4.xml", "baoxian_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jiasu_1.xml", "jiasu_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jiasu_2.xml", "jiasu_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jiasu_3.xml", "jiasu_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jiasu_4.xml", "jiasu_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/fangyu_1.xml", "fangyu_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/fangyu_2.xml", "fangyu_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/fangyu_3.xml", "fangyu_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/fangyu_4.xml", "fangyu_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/shencun_1.xml", "shencun_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/shencun_2.xml", "shencun_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/shencun_3.xml", "shencun_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/shencun_4.xml", "shencun_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/yinying_1.xml", "yinying_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/yinying_2.xml", "yinying_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/yinying_3.xml", "yinying_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/yinying_4.xml", "yinying_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jineng_1.xml", "jineng_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jineng_2.xml", "jineng_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jineng_3.xml", "jineng_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jineng_4.xml", "jineng_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/wuqi_1.xml", "wuqi_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/wuqi_2.xml", "wuqi_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/wuqi_3.xml", "wuqi_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/vex_hat_camouflage.xml", "vex_hat_camouflage.tex")
RegisterInventoryItemAtlas("images/inventoryimages/vex_hat_conceal.xml", "vex_hat_conceal.tex")
RegisterInventoryItemAtlas("images/inventoryimages/vex_hat_invisible.xml", "vex_hat_invisible.tex")
RegisterInventoryItemAtlas("images/inventoryimages/vex_shadow.xml", "vex_shadow.tex")

-- 配方材料图标：按 prefab 名（小写.tex）查找，图集内已添加同名元素
RegisterInventoryItemAtlas("images/inventoryimages/cunchu_1.xml", "vex_storage_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/cunchu_2.xml", "vex_storage_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/cunchu_3.xml", "vex_storage_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/cunchu_4.xml", "vex_storage_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/baoxian_1.xml", "vex_upgrade_preserve_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/baoxian_2.xml", "vex_upgrade_preserve_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/baoxian_3.xml", "vex_upgrade_preserve_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/baoxian_4.xml", "vex_upgrade_preserve_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jiasu_1.xml", "vex_upgrade_speed_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jiasu_2.xml", "vex_upgrade_speed_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jiasu_3.xml", "vex_upgrade_speed_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jiasu_4.xml", "vex_upgrade_speed_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/fangyu_1.xml", "vex_upgrade_defense_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/fangyu_2.xml", "vex_upgrade_defense_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/fangyu_3.xml", "vex_upgrade_defense_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/fangyu_4.xml", "vex_upgrade_defense_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/shencun_1.xml", "vex_upgrade_survival_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/shencun_2.xml", "vex_upgrade_survival_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/shencun_3.xml", "vex_upgrade_survival_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/shencun_4.xml", "vex_upgrade_survival_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/yinying_1.xml", "vex_upgrade_gloom_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/yinying_2.xml", "vex_upgrade_gloom_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/yinying_3.xml", "vex_upgrade_gloom_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/yinying_4.xml", "vex_upgrade_gloom_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jineng_1.xml", "vex_skill_upgrade_1.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jineng_2.xml", "vex_skill_upgrade_2.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jineng_3.xml", "vex_skill_upgrade_3.tex")
RegisterInventoryItemAtlas("images/inventoryimages/jineng_4.xml", "vex_skill_upgrade_4.tex")
RegisterInventoryItemAtlas("images/inventoryimages/wuqi_1.xml", "vex_gloom_weapon.tex")
RegisterInventoryItemAtlas("images/inventoryimages/wuqi_2.xml", "vex_shadow_staff.tex")
RegisterInventoryItemAtlas("images/inventoryimages/wuqi_3.xml", "vex_rune_staff.tex")


-- 愁煞共享参数（波文件和指示器统一从此读取）
TUNING.VEX_SORROW_HIT_RADIUS = 4
TUNING.VEX_SORROW_MAX_DIST = 30
TUNING.VEX_SORROW_WAVE_SPEED = 20
TUNING.VEX_SORROW_WAVE_DAMAGE = 100

-- ========== 飞行系统（加速模块Lv4）==========
-- 参考：格温mod gwen_hook.lua（已取得制作者同意）
-- 不提升视觉高度，脚底阴影由 vex_shadow.lua ApplyUpgrades/ClearUpgrades 管理

-- 飞行时免疫地面减速（蜘蛛网、道路等）
AddComponentPostInit("locomotor", function(self)
    local _SetExternalSpeedMultiplier = self.SetExternalSpeedMultiplier
    function self:SetExternalSpeedMultiplier(source, key, m, ...)
        if m ~= nil and m < 1 and self.inst:HasTag("vex_flying") then
            return
        end
        return _SetExternalSpeedMultiplier(self, source, key, m, ...)
    end
end)
-- =========================================

modimport("main/vex_recipes.lua")
modimport("main/vex_actions.lua")
modimport("main/vex_containers.lua")
modimport("main/vex_sorrow.lua")
modimport("main/vex_coldwave.lua")
modimport("main/vex_aoe.lua")
modimport("main/vex_mistzone.lua")
modimport("main/vex_gloom_passive.lua")

AddPrefabPostInit("vex_shadow", function(inst)
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            if inst.replica and inst.replica.container then
                inst.replica.container:WidgetSetup("vex_shadow")
            end
        end
    end
end)

-- 存储饰品客户端容器初始化（widget名硬编码，客户端拿不到 storage_widget）
local STORAGE_WIDGETS = {
    vex_storage_1 = "vex_storage_3",
    vex_storage_2 = "vex_storage_9",
    vex_storage_3 = "vex_storage_12",
    vex_storage_4 = "vex_storage_14",
}
for prefab, widget_name in pairs(STORAGE_WIDGETS) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = function(inst)
                if inst.replica and inst.replica.container then
                    inst.replica.container:WidgetSetup(widget_name)
                end
            end
        end
    end)
end

-- 噩梦燃料修复统一由 main/vex_actions.lua 的 VEX_REPAIR 动作处理（参考格温mod gw_tasui）

-- 物品栏满时拾取自动转存存储模块（仅薇古斯）
-- 优先级：正常格子→堆叠→背包溢出→存储模块→光标持有→掉回地面
-- 在原版 GiveItem 执行前拦截：仅当主物品栏无可用格（含堆叠）且背包溢出也不可用时
AddComponentPostInit("inventory", function(self)
    local old_GiveItem = self.GiveItem
    function self:GiveItem(inst, slot, src_pos, ...)
        if slot == nil and inst ~= nil and inst:IsValid()
            and inst.components.inventoryitem ~= nil
            and self.inst:HasTag("vex")
            and self:GetNextAvailableSlot(inst) == nil then
            local overflow = self:GetOverflowContainer()
            if overflow == nil or overflow:IsFull() then
                local body = self:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
                if body ~= nil and body.prefab == "vex_shadow" then
                    local storage = body._open_storage
                    if storage ~= nil and storage:IsValid()
                        and storage.components.container ~= nil
                        and not storage.components.container:IsFull() then
                        storage.components.container:GiveItem(inst)
                        return true
                    end
                end
            end
        end
        return old_GiveItem(self, inst, slot, src_pos, ...)
    end
end)

-- 防御模块击飞免疫：原版击飞状态无免疫标签机制，补丁检查标签后直接回 hit
-- （防御模块3阶+给玩家加 vex_knockbackimmune 标签；需双端补丁保证客户端预测一致）
for _, sgname in ipairs({ "wilson", "wilson_client" }) do
    AddStategraphPostInit(sgname, function(sg)
        for _, statename in ipairs({ "knockback", "knockbacklanded" }) do
            local state = sg.states[statename]
            if state ~= nil then
                local old_onenter = state.onenter
                state.onenter = function(inst, data)
                    if inst:HasTag("vex_knockbackimmune") then
                        inst.sg:GoToState("hit")
                        return
                    end
                    return old_onenter(inst, data)
                end
            end
        end
    end)
end

-- 移除黑影护目镜的屏幕边框滤镜（参考：格温mod gwen_hook.lua 蘸豆头2的处理）
-- 护目镜防护保留（服务器端沙暴免疫），只隐藏 goggle_over 视觉边框
AddClassPostConstruct("widgets/gogglesover", function(widget)
    local oldToggleGoggles = widget.ToggleGoggles
    widget.ToggleGoggles = function(s, show, ...)
        local forceHide = false
        local owner = s.owner
        if owner and owner.replica and owner.replica.inventory then
            local body = owner.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
            if body and body:HasTag("goggles") and body:HasTag("vex_shadow") then
                forceHide = true
            end
        end
        if forceHide then
            oldToggleGoggles(s, false, ...)
        else
            oldToggleGoggles(s, show, ...)
        end
    end
end)

-- 专用服务器无 widgets 环境，守卫加载（挂载回调内有 ThePlayer 守卫，专服不会执行）
local Gloom_badge = nil
if not GLOBAL.TheNet:IsDedicated() then
    Gloom_badge = require("widgets/gloom_badge")
end

local FLOWER_PREFABS = { "flower", "flower_rose", "flower_cave", "moonflower" }

for _, prefab in ipairs(FLOWER_PREFABS) do
    AddPrefabPostInit(prefab, function(inst)
        inst:ListenForEvent("picked", function(inst, data)
            local picker = data and data.picker
            if picker and picker.prefab == "vex" and picker.components.gloom then
                picker.components.gloom:DoDelta(-5)
                print(">>> Gloom: picked", prefab, "delta -5")
            end
        end)
    end)
end

AddPrefabPostInitAny(function(inst)
    -- 只处理有 edible component 且是 GOODIES 类型的食物
    if inst.components and inst.components.edible then
        if inst.components.edible.foodtype == FOODTYPE.GOODIES then
            inst:ListenForEvent("oneaten", function(inst, data)
                local eater = data and data.eater
                if eater and eater.prefab == "vex" and eater.components.gloom then
                    local san_gain = inst.components.edible:GetSanity(eater)
                    if san_gain and san_gain > 0 then
                        local gloom_loss = san_gain * 5
                        eater.components.gloom:DoDelta(-gloom_loss)
                        print(string.format(">>> Gloom: ate %s, san=%.1f, gloom -%.1f",
                            inst.prefab, san_gain, gloom_loss))
                    end
                end
            end)
        end
    end
end)

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst == GLOBAL.ThePlayer and inst.prefab == "vex" then
            if inst.HUD and inst.HUD.controls and inst.HUD.controls.status then
                local status = inst.HUD.controls.status
                print(">>> GloomBadge: creating for", inst.prefab)
                status.gloom_badge = status:AddChild(Gloom_badge(inst))
                status.gloom_badge:Show()
                status.gloom_badge:SetPosition(-240, 20, 0)
                status.gloom_badge:SetClickable(true)
            end
        end
    end)
end)


-- Gloom 调试面板（仅客户端，只初始化一次）
if not rawget(GLOBAL, "_VEX_DEBUG_INIT") and GLOBAL.TheNet:GetIsClient() then
    rawset(GLOBAL, "_VEX_DEBUG_INIT", true)

    local DEBUG_KEY = KEY_G
    local DEBUG_KEY_H = KEY_H

    -- G：切换面板显示
    GLOBAL.TheInput:AddKeyDownHandler(DEBUG_KEY, function()
        local player = GLOBAL.ThePlayer
        if not player or not player:IsValid() or player.prefab ~= "vex" then return end
        if not player.HUD or not player.HUD.controls or not player.HUD.controls.status then return end
        local panel = player.HUD.controls.status.gloom_debug_panel
        if panel then
            if panel.shown then panel:Hide() else panel:Show() end
        end
    end)

    -- H：通过 RPC 设置 gloom 最大值（测试用）
    GLOBAL.TheInput:AddKeyDownHandler(DEBUG_KEY_H, function()
        local player = GLOBAL.ThePlayer
        if not player or not player:IsValid() or player.prefab ~= "vex" then return end
        SendModRPCToServer(GetModRPC("vex", "debug_set_gloom"))
    end)
end

-- 服务端：debug gloom RPC
AddModRPCHandler("vex", "debug_set_gloom", function(player)
    if not player or not player:IsValid() then return end
    if player.prefab ~= "vex" then return end
    if player.components.gloom then
        player.components.gloom:DoDelta(200)
        print(">>> GloomDebug: set to max")
    end
end)

-- Gloom 调试面板 HUD 创建（仅客户端本地玩家）
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst ~= GLOBAL.ThePlayer then return end
        if inst.prefab ~= "vex" then return end
        if not inst.HUD then return end

        local Text = require("widgets/text")
        local Widget = require("widgets/widget")

        local panel = inst.HUD:AddChild(Widget("GloomDebugPanel"))
        panel:SetPosition(600, 300, 0)

        local bg = panel:AddChild(require("widgets/image")("images/global.xml", "square.tex"))
        bg:SetSize(220, 160)
        bg:SetTint(0, 0, 0, 0.5)
        bg:SetPosition(0, 0, 0)

        local title = panel:AddChild(Text(BODYTEXTFONT, 22))
        title:SetPosition(0, 60, 0)
        title:SetColour(0.8, 0.3, 1.0, 1)
        title:SetString("[ Gloom Debug ]")

        local val_text = panel:AddChild(Text(BODYTEXTFONT, 20))
        val_text:SetPosition(0, 30, 0)
        val_text:SetColour(1, 1, 1, 1)

        local rate_text = panel:AddChild(Text(BODYTEXTFONT, 20))
        rate_text:SetPosition(0, 5, 0)
        rate_text:SetColour(1, 1, 1, 1)

        local phase_text = panel:AddChild(Text(BODYTEXTFONT, 20))
        phase_text:SetPosition(0, -20, 0)
        phase_text:SetColour(1, 1, 1, 1)

        local san_text = panel:AddChild(Text(BODYTEXTFONT, 20))
        san_text:SetPosition(0, -45, 0)
        san_text:SetColour(1, 1, 1, 1)

        panel:Hide()
        -- 注册到 status 供 G 键访问
        if inst.HUD.controls.status then
            inst.HUD.controls.status.gloom_debug_panel = panel
        end

        local last_val = nil
        local rate_smooth = 0

        local update_task = inst:DoPeriodicTask(0.1, function()
            if not panel or not panel.shown then return end
            if not inst.gloom_current then return end

            local current = inst.gloom_current:value()
            local max = 200

            if last_val then
                local raw_rate = (current - last_val) / 0.1
                rate_smooth = rate_smooth * 0.7 + raw_rate * 0.3
            end
            last_val = current

            local rate_color = {1, 1, 1, 1}
            if rate_smooth > 0.05 then
                rate_color = {0.8, 0.3, 1.0, 1}
            elseif rate_smooth < -0.05 then
                rate_color = {0.5, 0.8, 1.0, 1}
            else
                rate_color = {0.5, 0.5, 0.5, 1}
            end

            val_text:SetString(string.format("Gloom: %.1f / %d (%.0f%%)", current, max, current/max*100))
            rate_text:SetColour(unpack(rate_color))
            rate_text:SetString(string.format("Rate: %+.2f/s", rate_smooth))

            local phase = GLOBAL.TheWorld and GLOBAL.TheWorld.state and GLOBAL.TheWorld.state.phase or "?"
            phase_text:SetString("Phase: " .. tostring(phase))

            local san_delta = 0
            if current > 150 then
                san_delta = 10
            elseif current < 50 then
                san_delta = -10
            end

            local san_str
            if san_delta > 0 then
                san_str = string.format("+%d San/min", san_delta)
            elseif san_delta < 0 then
                san_str = string.format("%d San/min", san_delta)
            else
                san_str = "San: neutral"
            end
            san_text:SetString(san_str)
        end)

        inst:ListenForEvent("onremove", function()
            if update_task then
                update_task:Cancel()
                update_task = nil
            end
            if panel then
                panel:Kill()
                panel = nil
            end
        end)
    end)
end)