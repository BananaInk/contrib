﻿-- This file is subject to copyright - contact swampservers@gmail.com for more information.
-- makes material a table that caches things
Material = setmetatable(isfunction(Material) and {
    [0] = Material
} or Material, {
    __call = function(tab, mn, png) return tab[0](mn, png) end,
    __index = function(tab, k)
        local v = tab[0](k)
        tab[k] = v

        return v
    end
})

-- local t=type(r)
-- if t=="number" then
--     sdc(r,g,b,a)
-- elseif t=="table" then
--     sdc(r.r,r.g,r.b,r.a)
-- else
--     sdc(255,255,255)
-- end
function render.BlendAdd()
    render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
end

function render.BlendSubtract()
    render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_REVERSE_SUBTRACT)
end

function render.BlendMultiply()
    render.OverrideBlend(true, BLEND_DST_COLOR, BLEND_ZERO, BLENDFUNC_ADD)
end

function render.BlendReset()
    render.OverrideBlend(false)
end

--- Bool if we are currently drawing to the screen.
function render.DrawingScreen()
    local t = render.GetRenderTarget()

    return t == nil or tostring(t) == "[NULL Texture]"
end

render.BaseSetColorModulation = render.BaseSetColorModulation or render.SetColorModulation
-- render.SetColorModulation = function() print("WARNING: USE render.PushColorModulation") end
render.ColorModulationStack = render.ColorModulationStack or {}

function render.PushColorModulation(col)
    if #render.ColorModulationStack > 0 then
        col = col * render.ColorModulationStack[#render.ColorModulationStack]
    end

    table.insert(render.ColorModulationStack, col)
    render.BaseSetColorModulation(col.x, col.y, col.z)
end

function render.PopColorModulation()
    table.remove(render.ColorModulationStack)
    local col = #render.ColorModulationStack > 0 and render.ColorModulationStack[#render.ColorModulationStack] or Vector(1, 1, 1)
    render.BaseSetColorModulation(col.x, col.y, col.z)
end

--- Sets the color modulation, calls your callback, then sets it back to what it was before.
function render.WithColorModulation(r, g, b, callback)
    local lr, lg, lb = render.GetColorModulation()
    render.SetColorModulation(r, g, b)
    callback()
    render.SetColorModulation(lr, lg, lb)
end

function cam.StartCulled3D2D(pos, ang, scale)
    if (EyePos() - pos):Dot(ang:Up()) > 0 then
        cam.Start3D2D(pos, ang, scale)

        return true
    end
end

--- Runs `cam.Start3D2D(pos, ang, scale) callback() cam.End3D2D()` but only if the user is in front of the "screen" so they can see it.
function cam.Culled3D2D(pos, ang, scale, callback)
    if cam.StartCulled3D2D(pos, ang, scale) then
        callback()
        cam.End3D2D()
    end
end

-- in SHARED (NOT CLIENT), return bone name, LOCAL pos, LOCAL ang, for example:
-- local pos, ang = Vector(1,2,3), Angle(0,0,0)
-- function SWEP:GetWorldModelPosition(ply)
--     -- if CLIENT then self:RemoveEffects(EF_BONEMERGE) end
--     return "ValveBiped.Bip01_R_Hand", pos, ang
-- end
hook.Add("PreRegisterSWEP", "VeryFastRendering", function(swep, class)
    if class == "weapon_base" then
        swep.DrawWorldModel = Entity.DrawModel
        swep.DrawWorldModelTranslucent = Entity.DrawModel
        hook.Remove("PreRegisterSWEP", "VeryFastRendering")
    end
end)

hook.Add("PreRegisterSENT", "VeryFastRendering", function(ent, class)
    if class == "base_anim" then
        print("WEDIDTI2")
        ent.Draw = Entity.DrawModel
        -- swep.DrawTranslucent = Entity.DrawModel incorrect because we might override draw and want drawtranslucent to do it
        hook.Remove("PreRegisterSENT", "VeryFastRendering")
    end
end)

hook.Add("OnEntityCreated", "GetWorldModelPosition", function(wep)
    -- "NetworkEntityCreated" "NotifyShouldTransmit"
    if wep:IsWeapon() then
        -- have to delay a little for initialization
        hook.Add("PreRender", wep, function()
            hook.Remove("PreRender", wep)

            if wep.GetWorldModelPosition then
                -- works but cant use another renderoverride
                function wep:RenderOverride(mode)
                    local ply = self.Owner

                    if IsValid(ply) then
                        local bone, pos, ang = self:GetWorldModelPosition(ply)
                        bone = ply:LookupBone(bone)

                        if bone then
                            local mat = ply:GetBoneMatrix(bone)

                            if mat then
                                pos, ang = LocalToWorld(pos, ang, mat:GetTranslation(), mat:GetAngles())
                                self:SetRenderOrigin(pos)
                                self:SetRenderAngles(ang)
                                self:DrawModel()

                                return
                            end
                        end
                    end

                    self:SetRenderOrigin()
                    self:SetRenderAngles()
                    self:DrawModel()
                end
                -- works but 1 frame delayed
                -- if wep.WMPCallback then wep:RemoveCallback("BuildBonePositions",wep.WMPCallback) end
                -- wep.WMPCallback = wep:AddCallback("BuildBonePositions", function(wep, nbones)
                --     local ply = wep.Owner
                --     if IsValid(ply) then
                --         local bone,pos,ang = wep:GetWorldModelPosition(ply)
                --         bone = ply:LookupBone(bone)
                --         if bone then
                --         local mat = ply:GetBoneMatrix(bone)
                --         if mat then 
                --             pos,ang= LocalToWorld(pos,ang,mat:GetTranslation(),mat:GetAngles())
                --             wep:SetRenderOrigin(pos)
                --             wep:SetRenderAngles(ang)
                --         end
                --     end
                -- else
                --     wep:SetRenderOrigin()
                --     wep:SetRenderAngles()
                --     end
                -- end)
                -- works on localplayer, laggy on other players
                -- function wep:CalcAbsolutePosition( opos, oang)
                --     local ply = self.Owner
                --     if IsValid(ply) then
                --         local bone,pos,ang = self:GetWorldModelPosition(ply)
                --         bone = ply:LookupBone(bone)
                --         if bone then
                --         local mat = ply:GetBoneMatrix(bone)
                --         if mat then 
                --             return LocalToWorld(pos,ang,mat:GetTranslation(),mat:GetAngles())
                --         end
                --     end
                --     return opos, oang
                --     end
                -- end
            end
        end)
    end
end)
