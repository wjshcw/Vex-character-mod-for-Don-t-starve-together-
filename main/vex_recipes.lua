GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})


-- 暗影法杖 + 符文法杖（测试配方）
AddRecipe2("vex_shadow_staff",
    {
        Ingredient("ruins_bat", 1),
        Ingredient("minotaurhorn", 1),
        Ingredient("shieldofterror", 1),
        Ingredient("vex_gloom_weapon", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/wuqi_2.xml", image = "wuqi_2.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_rune_staff",
    {
        Ingredient("coolant", 1),
        Ingredient("butter", 3),
        Ingredient("vex_shadow_staff", 1),
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/wuqi_3.xml", image = "wuqi_3.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)

-- 暗影武器：暗影剑 + 紫宝石
AddRecipe2("vex_gloom_weapon",
    {
        Ingredient("nightsword", 1),
        Ingredient("purplegem", 1),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/wuqi_1.xml",
        image = "wuqi_1.tex",
        builder_tag = "vex",
    },
    {"CHARACTER"}
)

AddRecipe2("vex_multitool",
    {
        Ingredient("goldenshovel",   1),
        Ingredient("goldenaxe",      1),
        Ingredient("goldenpickaxe",  1),
        Ingredient("golden_farm_hoe",1),
        Ingredient("hammer",         1)
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/vex_multitool.xml",
        image = "vex_multitool.tex",
        builder_tag = "vex",
    },
    {"CHARACTER"}
)

AddRecipe2("vex_multitool_2",
    {
        Ingredient("vex_multitool", 1),
        Ingredient("multitool_axe_pickaxe", 1),  -- TODO 替换
        Ingredient("staff_tornado", 1),
        Ingredient("moonglassaxe", 1)
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/vex_multitool_2.xml",
        image = "vex_multitool_2.tex",
        builder_tag = "vex",
    },
    {"CHARACTER"}
)

AddRecipe2("vex_multitool_3",
    {
        Ingredient("vex_multitool_2", 1),
        Ingredient("voidcloth_scythe", 1),  -- TODO 替换
        Ingredient("shadow_battleaxe", 1),
        Ingredient("shovel_lunarplant", 1),
        Ingredient("pickaxe_lunarplant", 1)
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/vex_multitool_3.xml",
        image = "vex_multitool_3.tex",
        builder_tag = "vex",
    },
    {"CHARACTER"}
)

-- 存储饰品（测试配方）
AddRecipe2("vex_storage_1",
    {
        Ingredient("cutgrass", 2),
        Ingredient("twigs", 2),
        Ingredient("nightmarefuel", 1),
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/cunchu_1.xml", image = "cunchu_1.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_storage_2",
    {
        Ingredient("pigskin", 2),
        Ingredient("silk", 3),
        Ingredient("nightmarefuel", 4),
        Ingredient("vex_storage_1", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/cunchu_2.xml", image = "cunchu_2.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_storage_3",
    {
        Ingredient("bundlewrap", 1),
        Ingredient("dragon_scales", 1),
        Ingredient("shadowheart", 1),
        Ingredient("horrorfuel", 3),
        Ingredient("vex_storage_2", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/cunchu_3.xml", image = "cunchu_3.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_storage_4",
    {
        Ingredient("chestupgrade_stacksize", 1),
        Ingredient("horrorfuel", 20),
        Ingredient("vex_storage_3", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/cunchu_4.xml", image = "cunchu_4.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)

-- 伪装/隐蔽/隐身帽（测试配方）
AddRecipe2("vex_hat_camouflage",
    {
        Ingredient("beefalohat", 1),
        Ingredient("beehat", 1),
        Ingredient("bushhat", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/vex_hat_camouflage.xml", image = "vex_hat_camouflage.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_hat_conceal",
    {
        Ingredient("featherhat", 1),
        Ingredient("hivehat", 1),
        Ingredient("spiderhat", 1),
        Ingredient("vex_hat_camouflage", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/vex_hat_conceal.xml", image = "vex_hat_conceal.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_hat_invisible",
    {
        Ingredient("coolant", 1),
        Ingredient("flowerhat", 1),
        Ingredient("vex_hat_conceal", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/vex_hat_invisible.xml", image = "vex_hat_invisible.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)

-- 技能强化（测试配方）
AddRecipe2("vex_skill_upgrade_1",
    {
        Ingredient("nightmarefuel", 3),
        Ingredient("purplegem", 3)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/jineng_1.xml", image = "jineng_1.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_skill_upgrade_2",
    {
        Ingredient("yellowgem", 1),
        Ingredient("orangegem", 1),
        Ingredient("greengem", 1),
        Ingredient("nightmarefuel", 10),
        Ingredient("vex_skill_upgrade_1", 2)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/jineng_2.xml", image = "jineng_2.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_skill_upgrade_3",
    {
        Ingredient("townportaltalisman", 6),
        Ingredient("nightmarefuel", 20),
        Ingredient("vex_skill_upgrade_2", 3),
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/jineng_3.xml", image = "jineng_3.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)
AddRecipe2("vex_skill_upgrade_4",
    {
        Ingredient("lunarplant_husk", 3),
        Ingredient("dreadstone",3),
        Ingredient("coolant", 1),
        Ingredient("vex_skill_upgrade_3", 1),
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/jineng_4.xml", image = "jineng_4.tex", builder_tag = "vex", nounlock = true },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_speed_1",
    {
        Ingredient("feather_crow", 4),
        Ingredient("batwing", 2),
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/jiasu_1.xml",
        image = "jiasu_1.tex",
        builder_tag = "vex",
        nounlock = true,
    },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_speed_2",
    {
        Ingredient("feather_canary", 4),
        Ingredient("lightninggoathorn", 2),
        Ingredient("vex_upgrade_speed_1", 1)
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/jiasu_2.xml",
        image = "jiasu_2.tex",
        builder_tag = "vex",
        nounlock = true,
    },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_speed_3",
    {
        Ingredient("goose_feather", 4),
        Ingredient("cane", 1),
        Ingredient("vex_upgrade_speed_2", 1)
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/jiasu_3.xml",
        image = "jiasu_3.tex",
        builder_tag = "vex",
        nounlock = true,
    },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_speed_4",
    {
        Ingredient("malbatross_feather", 4),
        Ingredient("voidcloth", 2),
        Ingredient("vex_upgrade_speed_3", 1)
    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/jiasu_4.xml",
        image = "jiasu_4.tex",
        builder_tag = "vex",
        nounlock = true,
    },
    {"CHARACTER"}
)
AddRecipe2("vex_upgrade_gloom_1",
    {
        Ingredient("nightmarefuel", 4),
        Ingredient("spoiled_food", 10)

    },  -- TODO: 替换材料
    TECH.NONE,
    {
        atlas = "images/inventoryimages/yinying_1.xml",
        image = "yinying_1.tex",
        builder_tag = "vex",
    },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_gloom_2",
    {
        Ingredient("purplegem", 2),
        Ingredient("livinglog", 4),
        Ingredient("vex_upgrade_gloom_1", 1)

    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/yinying_2.xml",
        image = "yinying_2.tex",
        builder_tag = "vex",
    },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_gloom_3",
    {
        Ingredient("tentaclespots", 2),
        Ingredient("dreadstone", 2),
        Ingredient("vex_upgrade_gloom_2", 1)

    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/yinying_3.xml",
        image = "yinying_3.tex",
        builder_tag = "vex",
    },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_gloom_4",
    {
        Ingredient("dreadstone", 4),
        Ingredient("voidcloth", 6),
        Ingredient("horrorfuel", 10),
        Ingredient("vex_upgrade_gloom_3", 1)

    },
    TECH.NONE,
    {
        atlas = "images/inventoryimages/yinying_4.xml",
        image = "yinying_4.tex",
        builder_tag = "vex",
    },
    {"CHARACTER"}
)


AddRecipe2("vex_upgrade_preserve_1",
    {
        Ingredient("gears", 1),
        Ingredient("wagpunk_bits", 2),
    },  -- TODO
    TECH.NONE,
    { atlas = "images/inventoryimages/baoxian_1.xml", image = "baoxian_1.tex", builder_tag = "vex" },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_preserve_2",
    {
        Ingredient("bluegem", 2),
        Ingredient("trinket_6", 4),
        Ingredient("vex_upgrade_preserve_1", 1)
    },  -- TODO
    TECH.NONE,
    { atlas = "images/inventoryimages/baoxian_2.xml", image = "baoxian_2.tex", builder_tag = "vex" },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_preserve_3",
    {
        Ingredient("deerclops_eyeball", 1),
        Ingredient("saltrock", 10),
        Ingredient("vex_upgrade_preserve_2", 1)
    },  -- TODO
    TECH.NONE,
    { atlas = "images/inventoryimages/baoxian_3.xml", image = "baoxian_3.tex", builder_tag = "vex" },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_preserve_4",
    {
        Ingredient("beargerfur_sack", 1),
        Ingredient("gelblob_storage_kit",1),
        Ingredient("vex_upgrade_preserve_3",1)

    },  -- TODO
    TECH.NONE,
    { atlas = "images/inventoryimages/baoxian_4.xml", image = "baoxian_4.tex", builder_tag = "vex" },
    {"CHARACTER"}
)


AddRecipe2("vex_upgrade_survival_1",
    {
        Ingredient("beefalowool", 6),
        Ingredient("silk", 4),
        Ingredient("pigskin", 2)
    },  -- TODO
    TECH.NONE,
    { atlas = "images/inventoryimages/shencun_1.xml", image = "shencun_1.tex", builder_tag = "vex" },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_survival_2",
    {
        Ingredient("heatrock", 2),
        Ingredient("ice", 20),
        Ingredient("tentaclespots", 2),
        Ingredient("walrushat", 1),
        Ingredient("vex_upgrade_survival_1", 1)
    },  -- TODO
    TECH.NONE,
    { atlas = "images/inventoryimages/shencun_2.xml", image = "shencun_2.tex", builder_tag = "vex" },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_survival_3",
    {
        Ingredient("bearger_fur", 1),
        Ingredient("deserthat", 1),
        Ingredient("deerclops_eyeball", 1),
        Ingredient("vex_upgrade_survival_2", 1),
    },  -- TODO
    TECH.NONE,
    { atlas = "images/inventoryimages/shencun_3.xml", image = "shencun_3.tex", builder_tag = "vex" },
    {"CHARACTER"}
)

AddRecipe2("vex_upgrade_survival_4",
    {
        Ingredient("trunk_winter", 1),
        Ingredient("cactus_flower", 1),
        Ingredient("gelblob_storage_kit", 1),
        Ingredient("deerclopseyeball_sentryward_kit", 1),
        Ingredient("vex_upgrade_survival_3", 1),
    },  -- TODO
    TECH.NONE,
    { atlas = "images/inventoryimages/shencun_4.xml", image = "shencun_4.tex", builder_tag = "vex" },
    {"CHARACTER"}
)



AddRecipe2("vex_upgrade_defense_1",
    {
        Ingredient("armorwood", 1),
        Ingredient("pigskin", 2),
        Ingredient("silk", 4)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/fangyu_1.xml", image = "fangyu_1.tex", builder_tag = "vex" },
    {"CHARACTER"}
)
AddRecipe2("vex_upgrade_defense_2",
    {
        Ingredient("armor_sanity", 1),
        Ingredient("armormarble", 1),
        Ingredient("deerclops_eyeball", 1),
        Ingredient("vex_upgrade_defense_1", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/fangyu_2.xml", image = "fangyu_2.tex", builder_tag = "vex" },
    {"CHARACTER"}
)
AddRecipe2("vex_upgrade_defense_3",
    {
        Ingredient("armorruins", 1),
        Ingredient("armordreadstone", 1),
        Ingredient("dragon_scales", 1),
        Ingredient("vex_upgrade_defense_2", 1)
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/fangyu_3.xml", image = "fangyu_3.tex", builder_tag = "vex" },
    {"CHARACTER"}
)
AddRecipe2("vex_upgrade_defense_4",
    {
        Ingredient("armor_voidcloth", 1),
        Ingredient("armor_lunarplant", 1),
        Ingredient("shroom_skin", 1),
        Ingredient("vex_upgrade_defense_3", 1),
    },
    TECH.NONE,
    { atlas = "images/inventoryimages/fangyu_4.xml", image = "fangyu_4.tex", builder_tag = "vex" },
    {"CHARACTER"}
)
