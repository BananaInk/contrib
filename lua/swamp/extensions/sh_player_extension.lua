﻿-- This file is subject to copyright - contact swampservers@gmail.com for more information.
--- Faster than writing `IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass()==class`
function Player:UsingWeapon(class)
    local c = self:GetActiveWeapon()

    return IsValid(c) and c:GetClass() == class
end

-- Use the player color as the weapon color
function Player:GetWeaponColor()
    return self:GetPlayerColor()
end

--- IsPlayer and not IsBot
function Entity:IsHuman()
    return self:IsPlayer() and not self:IsBot()
end

function Player:IsHuman()
    return not self:IsBot()
end
