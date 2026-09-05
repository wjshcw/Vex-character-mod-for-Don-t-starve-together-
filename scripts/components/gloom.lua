local easing = require("easing")

local Gloom = Class(function(self, inst)
    self.inst = inst
    self.current = 100
    self.max = 200
    self.min = 0

    self.inst:StartUpdatingComponent(self)  -- 启动 OnUpdate
end)

function Gloom:GetPercent()
    return self.current / self.max
end

function Gloom:SetPercent(val)
    self.current = math.clamp(val * self.max, 0, self.max)
end

function Gloom:DoDelta(amount)  -- 原来叫 Delta，改为 DoDelta 与原版风格一致
    self.current = math.clamp(self.current + amount, 0, self.max)
    if self.inst.gloom_current then
        self.inst.gloom_current:set(self.current)
    end
end

function Gloom:OnUpdate(dt)
    if not TheWorld.ismastersim then return end

    -- 睡眠时跳过光照计算（和原版 sanity 一致）
    if self.inst.sg and self.inst.sg:HasStateTag("sleeping") then
        return
    end

    -- ========== 光照对阴暗度的影响 ==========
    local light_delta = 0
    local phase = TheWorld.state.phase

    if TheWorld:HasTag("cave") then
        light_delta = 5 / 60        -- 洞穴全天当夜晚 +5/min
    elseif phase == "day" then
        light_delta = -5 / 60       -- 白天 -5/min
    elseif phase == "dusk" then
        light_delta = 3 / 60        -- 黄昏 +3/min
    elseif phase == "night" then
        light_delta = 5 / 60        -- 夜晚 +5/min
    end

    -- ========== 潮湿度对阴暗度的影响 ==========
    if self.inst.components.moisture then
        local m = self.inst.components.moisture:GetMoisture()
        local mmax = self.inst.components.moisture:GetMaxMoisture()
    -- 取绝对值，因为 MOISTURE_SANITY_PENALTY_MAX 是负数
        local moisture_delta = math.abs(easing.inSine(m, 0, TUNING.MOISTURE_SANITY_PENALTY_MAX, mmax))
        self:DoDelta(moisture_delta * dt)
    end

    self:DoDelta(light_delta * dt)

    -- ========== 队友影响（全局计数，同原版鬼魂扣理智逻辑）==========
    -- 参考：components/sanity.lua:457-464 RecalcGhostDrain
    local shard = TheWorld.shard
    if shard and shard.components.shard_players then
        local num_ghosts = shard.components.shard_players:GetNumGhosts()
        local num_alive = shard.components.shard_players:GetNumAlive() - 1  -- 排除自己
        if num_alive < 0 then num_alive = 0 end
        local delta = (num_ghosts - num_alive) * 3.3 / 60  -- 每秒变化
        self:DoDelta(delta * dt)
    end

    -- ========== 阴暗度 > 195 对影怪中立 ==========
    if self.current > 195 then
        if not self.inst:HasTag("shadowdominance") then
            self.inst:AddTag("shadowdominance")
        end
    else
        if self.inst:HasTag("shadowdominance") then
            self.inst:RemoveTag("shadowdominance")
        end
    end

    -- ========== 阴暗度对 San 值的影响 ==========
    if self.inst.components.sanity then
        local san_delta = 0
        if self.current > 150 then
            san_delta = 30 / 60
        elseif self.current < 50 then
            san_delta = -30 / 60
        end
        if san_delta ~= 0 then
            self.inst.components.sanity:DoDelta(san_delta * dt, true)
        end
    end
end

function Gloom:OnSave()
    return { current = self.current, max = self.max }
end

function Gloom:OnLoad(data)
    if data then
        self.current = data.current or self.max
        self.max = data.max or self.max
    end
end

return Gloom