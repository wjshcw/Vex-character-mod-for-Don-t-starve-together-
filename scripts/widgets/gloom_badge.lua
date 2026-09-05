local Badge = require "widgets/badge"

local GloomBadge = Class(Badge, function(self, owner)
    local purple_tint = { 0.6, 0.1, 0.9, 1 }
    local bonus_tint  = { 0.8, 0.3, 1.0, 1 }

    Badge._ctor(
        self,
        nil,          -- anim
        owner,
        purple_tint,
        nil,          -- iconbuild
        false,        -- circular_meter: 改为 false，走标准竖向液体样式
        false,        -- use_clear_bg
        false,        -- dont_update_while_paused
        bonus_tint
    )

    self.owner = owner
    self:StartUpdating()
end)

function GloomBadge:OnGainFocus()
    GloomBadge._base.OnGainFocus(self)
    self.num:Show()
end

function GloomBadge:OnLoseFocus()
    GloomBadge._base.OnLoseFocus(self)
    self.num:Hide()
end

function GloomBadge:SetPercent(val, max)
    Badge.SetPercent(self, val, max)
end

function GloomBadge:OnUpdate(dt)
    if self.owner and self.owner.gloom_current then
        local current = self.owner.gloom_current:value()
        local max = 200
        self:SetPercent(current / max, max)
    end
end

return GloomBadge