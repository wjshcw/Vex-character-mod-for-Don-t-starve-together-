GLOBAL.setmetatable(env, {__index = function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local containers = require("containers")
local params = containers.params

-- 黑影：3格升级徽章（hand_inv 类型，装备时自动弹出小徽章）
params.vex_shadow = {
    widget = {
        slotpos = {},
        animbank  = "ui_chest_2x3",
        animbuild = "ui_chest_2x3",
        pos = Vector3(120, 40, 0),
        slotbg = {},
    },
    type = "hand_inv",
    acceptsstacks = true,
    openlimit = 1,
}
for i = 0, 2 do
    table.insert(params.vex_shadow.widget.slotpos, Vector3(-75 + i * 75, 0, 0))
    params.vex_shadow.widget.slotbg[i+1] = { image = nil, atlas = nil }
end
function params.vex_shadow.itemtestfn(container, item, slot)
    if slot == nil then return true end
    return item:HasTag("vex_upgrade")
end

-- 存储饰品容器（使用游戏原版槽位坐标对齐背景图）
local function DefStorage(name, anim, pos, slotfn)
    local w = { slotpos = {}, animbank = anim, animbuild = anim, pos = pos, slotbg = {}, vex_storage = name }
    slotfn(w)
    for i = 1, #w.slotpos do w.slotbg[i] = { image = nil, atlas = nil } end
    params[name] = { widget = w, type = "chest", acceptsstacks = true, openlimit = 1 }
end

-- Lv1 3格（1行×3列，胡子同款坐标）
DefStorage("vex_storage_3", "ui_beard_3x1", Vector3(0, 80, 0), function(w)
    for x = 0, 2 do table.insert(w.slotpos, Vector3(-75 + x * 75, 0, 0)) end
end)

-- Lv2 9格（3行×3列，原版木箱坐标）
DefStorage("vex_storage_9", "ui_chest_3x3", Vector3(0, 80, 0), function(w)
    for y = 2, 0, -1 do
        for x = 0, 2 do
            table.insert(w.slotpos, Vector3(80*x - 80*2 + 80, 80*y - 80*2 + 80, 0))
        end
    end
end)

-- Lv3 12格（4行×3列，远古守护者华丽箱子坐标）
DefStorage("vex_storage_12", "ui_chester_shadow_3x4", Vector3(0, 80, 0), function(w)
    for y = 2.5, -0.5, -1 do
        for x = 0, 2 do
            table.insert(w.slotpos, Vector3(75*x - 150 + 75, 75*y - 150 + 75, 0))
        end
    end
end)

-- Lv4 14格（7行×2列，坎普斯背包坐标）
DefStorage("vex_storage_14", "ui_krampusbag_2x8", Vector3(0, -10, 0), function(w)
    for y = 0, 6 do
        table.insert(w.slotpos, Vector3(-162, -75*y + 240, 0))
        table.insert(w.slotpos, Vector3(-162 + 75, -75*y + 240, 0))
    end
end)

-- 存储容器拖拽（来自格温mod gwen_containers.lua）
local vex_dragpos = {}
local function load_dragpos()
    TheSim:GetPersistentString("vex_storage_drag", function(ok, data)
        if ok and data then
            local s, allpos = RunInSandbox(data)
            if s and allpos then
                for k, v in pairs(allpos) do
                    if vex_dragpos[k] == nil then
                        vex_dragpos[k] = Vector3(v.x or 0, v.y or 0, v.z or 0)
                    end
                end
            end
        end
    end)
end
local function save_dragpos()
    if next(vex_dragpos) then
        TheSim:SetPersistentString("vex_storage_drag", DataDumper(vex_dragpos, nil, true), false)
    end
end
local function get_dragpos(key)
    if vex_dragpos[key] == nil then load_dragpos() end
    return vex_dragpos[key]
end

AddClassPostConstruct("widgets/containerwidget", function(self)
    local _Open = self.Open
    self.Open = function(_, container, doer)
        _Open(_, container, doer)
        if not container or not container.replica.container then return end
        local widget = container.replica.container:GetWidget()
        if not widget or not widget.vex_storage then return end

        local tag = widget.vex_storage
        if not _.candrag then
            _.candrag = true
            -- 整个面板右键拖拽
            function _:StartDrag()
                if self._drag_h then return end
                local spos = TheInput:GetScreenPosition()
                local ppos = self:GetPosition()
                self._drag_h = TheInput:AddMoveHandler(function(x, y)
                    -- 容器可能已被销毁（如右键装备导致容器关闭），
                    -- 当前版本无 Widget:IsValid 方法，需检查底层实体有效性
                    if not self.inst or not self.inst:IsValid() then
                        if self._drag_h then
                            self._drag_h:Remove()
                            self._drag_h = nil
                        end
                        return
                    end
                    local off = 0.6
                    local scl = self:GetScale()
                    self:SetPosition(
                        ppos.x + (x - spos.x) / (scl.x / off),
                        ppos.y + (y - spos.y) / (scl.y / off), 0)
                    if not Input:IsMouseDown(MOUSEBUTTON_RIGHT) then self:EndDrag() end
                end)
            end
            function _:EndDrag()
                if self._drag_h then self._drag_h:Remove() end
                self._drag_h = nil
                -- 容器销毁时跳过位置保存（GetPosition 会访问已移除的实体）
                if self.inst and self.inst:IsValid() then
                    vex_dragpos[tag] = self:GetPosition()
                    save_dragpos()
                end
            end
            -- 右键按下/松开
            local oldCtrl = _.OnControl
            _.OnControl = function(me, ctrl, down)
                if ctrl == CONTROL_SECONDARY then
                    -- 先让子控件（物品格）处理右键，如装备/使用；
                    -- 未被消费（点在面板空白处）才进入面板拖拽
                    if oldCtrl and oldCtrl(me, ctrl, down) then
                        return true
                    end
                    if down then me:StartDrag() else me:EndDrag() end
                    return true
                end
                return oldCtrl and oldCtrl(me, ctrl, down)
            end
            -- 中键重置
            local oldMouse = _.OnMouseButton
            _.OnMouseButton = function(me, btn, down, ...)
                if btn == MOUSEBUTTON_MIDDLE and down then
                    vex_dragpos[tag] = nil
                    save_dragpos()
                end
                return oldMouse and oldMouse(me, btn, down, ...)
            end
        end
        -- 恢复保存的位置
        local saved = get_dragpos(tag)
        if saved then _:SetPosition(saved) end
    end
end)
