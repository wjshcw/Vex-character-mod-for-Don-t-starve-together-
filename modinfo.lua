name = "愁云使者-薇古斯Vex"
description = "基于LOL(英雄联盟)中角色薇古斯开发的饥荒联机版角色mod，详情请见创意工坊介绍页面。"
author = "冷冽谷的芙宁娜"
version = "0.1"
forumthread = ""
icon_atlas = "modicon.xml"
icon = "modicon.tex"
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true
api_version = 10
-- 按键配置表（兼容格温mod的完整键位：F1-F12 + A-Z + Num + 鼠标）
local alpha = {"F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"}
local alpha2 = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
                "Q","R","S","T","U","V","W","X","Y","Z","无"}
local alpha3 = {"Num 0","Num 1","Num 2","Num 3","Num 4","Num 5","Num 6","Num 7",
                "Num 8","Num 9","Num .","Num /","Num *","Num -","Num +"}
local offsets = {281, 96, 255}
local alphas = {alpha, alpha2, alpha3}
local vex_Key_data = {}

for index = 1, #alphas do
    local alphaSet = alphas[index]
    for i = 1, #alphaSet do
        local key = alphaSet[i]
        vex_Key_data[#vex_Key_data + 1] = {description = key, data = i + offsets[index]}
    end
end

local mouseButtons = {
    {description = "鼠标中键", data = 1002},
    {description = "鼠标侧键4", data = 1005},
    {description = "鼠标侧键5", data = 1006},
}
for i = 1, #mouseButtons do
    vex_Key_data[#vex_Key_data + 1] = mouseButtons[i]
end

configuration_options = {
    {name = "Vex_Sorrow_Key",
     label = "愁煞 R",
     hover = "愁煞技能快捷键",
     options = vex_Key_data,
     default = 114,  -- KEY_R = 114
    },
    {name = "Vex_ColdWave_Key",
     label = "寒心波云 C",
     hover = "寒心波云技能快捷键",
     options = vex_Key_data,
     default = 120,  -- KEY_X = 120
    },
    {name = "Vex_AOE_Key",
     label = "生人勿近 Z",
     hover = "生人勿近技能快捷键",
     options = vex_Key_data,
     default = 122,  -- KEY_Z = 122
    },
    {name = "Vex_MistZone_Key",
     label = "溟濛渐染 V",
     hover = "溟濛渐染技能快捷键",
     options = vex_Key_data,
     default = 118,  -- KEY_V = 118
    },
}
server_filter_tags = {
"character",
}