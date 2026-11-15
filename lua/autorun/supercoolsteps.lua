AddCSLuaFile( "stepconfig/steps.lua" )

local config = include("stepconfig/steps.lua")
-- PrintTable(config)
local surfacefootstepssprinting = config.surfacefootstepssprinting
local surfacefootsteps = config.surfacefootsteps
local surfacefootsteps_indoor = config.surfacefootsteps_indoor
local surfacefootstepssprinting_indoor = config.surfacefootstepssprinting_indoor
local surfacefootstepsland_indoor = config.surfacefootstepsland_indoor
local surfacefootstepsland = config.surfacefootstepsland
local weaponcategories = config.weaponcategories

local function getSurfacePropName(surfacePropID)
    local name = util.GetSurfacePropName(surfacePropID)
    return name ~= "" and string.lower(name) or "default"
end

glassZones = glassZones or {}

hook.Add("Think", "TrackBrokenGlass", function()
    for _, glass in ipairs(ents.FindByClass("func_breakable_surf")) do
        if not glass._WasBroken and glass:GetInternalVariable("m_bIsBroken") then
            glass._WasBroken = true

            local pos = glass:LocalToWorld(glass:OBBCenter())
            table.insert(glassZones, {
                pos = pos,
                radius = 125, -- how big is the damn area
                expire = CurTime() + 15 -- how long does this goddamn zone exist
            })

            debugoverlay.Sphere(pos, 100, 3, Color(0,255,255), true)
        end
    end

    -- clean this shit dwag
    for i = #glassZones, 1, -1 do
        if glassZones[i].expire < CurTime() then
            table.remove(glassZones, i)
        end
    end
end)

hook.Add("PlayerFootstep", "CustomFootstep", function(ply, pos, foot, sound, volume, rf)
    local weapon = ply:GetActiveWeapon()
    local armorvalue = ply:Armor()
    local waterlevel = ply:WaterLevel()

    local rain = ents.FindByClass("func_precipitation") [1]
    local breakableglass = ents.FindByClass("func_breakable_surf") [1]
    -- print( rain:GetInternalVariable( "preciptype" ) ) 
    local preciptype = 99
    if IsValid(rain) then
        preciptype = rain:GetInternalVariable( "preciptype" )
    end
    local israining = preciptype == 0 or preciptype == 4

    -- print(weapon.SubCategory)
    -- print(weaponcategories[weapon.SubCategory])
    local sprinting = ply:KeyDown(IN_SPEED) and surfacefootstepssprinting or surfacefootsteps
    local sprinting_indoor = ply:KeyDown(IN_SPEED) and surfacefootstepssprinting_indoor or surfacefootsteps_indoor
    local tr = util.TraceLine({
        start = ply:GetPos(),
        endpos = ply:GetPos() + Vector(0, 0, -10),
        filter = ply
    })
    local materialtype = getSurfacePropName(tr.SurfaceProps or 30)
    print(tr.SurfaceProps, "[" .. materialtype .. "]", surfacefootsteps[materialtype], surfacefootstepssprinting[materialtype])
    -- PrintTable(tr)

    if (sprinting[materialtype]) then -- lets play the sounds lol
        
       ply:EmitSound(sprinting[materialtype])
        ply:EmitSound(ply:KeyDown(IN_SPEED) and "generic_cloth.sprint" or "generic_cloth.walk")
        -- ply:EmitSound("generic_cloth.walk")

        if waterlevel == 1 then
            ply:EmitSound("water_ankle.sprint")
        elseif waterlevel == 2 then
            ply:EmitSound("water_knee.sprint")
        elseif waterlevel == 3 then
            ply:EmitSound("water_waist.sprint")
        end

        if ply.WaterExitTime != nil and CurTime() < ply.WaterExitTime + 7 then
            -- ply:EmitSound(ply:KeyDown(IN_SPEED) and "wet.sprint" or "wet.walk")
            ply:EmitSound("wet_lyr")
        end

        if IndoorCheck(ply) then
                -- ply:EmitSound(sprinting[materialtype], 75, 100, 1, CHAN_BODY, 0, 3)
                ply:EmitSound(sprinting_indoor[materialtype])
                ply:EmitSound("clothes", 75, 100, 1, CHAN_GEARLAYER, 0, 3)
        else
            if israining then
                -- ply:EmitSound(ply:KeyDown(IN_SPEED) and "wet.sprint" or "wet.walk")
                ply:EmitSound("wet_lyr")
            end
        end
    end


    --Armor values :steamhappy:
    if armorvalue >= 120 then
        if IndoorCheck(ply) then
            ply:EmitSound("superheavy",75, 100, 1, CHAN_GEARLAYER, 0, 3)
        else
            ply:EmitSound("superheavy")
        end
        -- ply:EmitSound("bass")
    elseif armorvalue >= 60 then
        if IndoorCheck(ply) then
            ply:EmitSound(ply:KeyDown(IN_SPEED) and "milhvygr.sprint" or "milhvygr.walk",75, 100, 1, CHAN_GEARLAYER, 0, 3)
        else
            ply:EmitSound(ply:KeyDown(IN_SPEED) and "milhvygr.sprint" or "milhvygr.walk")
        end
    elseif armorvalue >= 30 then
        if IndoorCheck(ply) then
            ply:EmitSound(ply:KeyDown(IN_SPEED) and "western_med.sprint" or "western_med.walk",75, 100, 1, CHAN_GEARLAYER, 0, 3)
        else
            ply:EmitSound(ply:KeyDown(IN_SPEED) and "western_med.sprint" or "western_med.walk")
        end
    elseif armorvalue >= 1 then
        if IndoorCheck(ply) then
            ply:EmitSound(ply:KeyDown(IN_SPEED) and "western_light.sprint" or "western_light.walk",75, 100, 1, CHAN_GEARLAYER, 0, 3)
        else
            ply:EmitSound(ply:KeyDown(IN_SPEED) and "western_light.sprint" or "western_light.walk")
        end
    end

    --Weapon rattle sound code
    if (weaponcategories[weapon.SubCategory]) and ply:KeyDown(IN_SPEED) then 
        if (ply.RattleTime or 0) < CurTime() then
            if  IndoorCheck(ply) then
            ply:EmitSound(weaponcategories[weapon.SubCategory],75, 100, 1, CHAN_RATTLELAYER, 0, 3)
            ply.RattleTime = CurTime() + 0.5
            else
            ply:EmitSound(weaponcategories[weapon.SubCategory])    
        end
    end
    end

    --Wood creak sound code
    if (materialtype == "wood" or materialtype == "wood_plank") then
        if (ply.WoodCreakTime or 0) < CurTime() then
            ply:EmitSound("wood.creak")
            ply.WoodCreakTime = CurTime() + 4
        end
    end

     if glassZones then
        for _, zone in ipairs(glassZones) do
            if pos:DistToSqr(zone.pos) <= (zone.radius ^ 2) then
                ply:EmitSound("glass_broken.run")
            end
        end
end



    return true
end)

local maxDifference = 45
local currentAngle = Angle()
local lastSnap = Angle()
function OnSnap(ply)
            local tr = util.TraceLine({
        start = ply:GetPos(),
        endpos = ply:GetPos() + Vector(0, 0, -10),
        filter = ply
    })
    local turn = surfacefootsteps
    local materialtype = getSurfacePropName(tr.SurfaceProps or 30)
     if (ply.StepTime or 0) < CurTime() then
            ply:EmitSound(turn[materialtype])
            ply.StepTime = CurTime() + 0.3
     end
end
hook.Add( "SetupMove", "tata", function( ply, mv, cmd )
    currentAngle:Set(mv:GetAngles())
    if mv:GetVelocity():Length() > 0 then
        lastSnap:Set(mv:GetAngles())
    end

    local newAngle = math.abs(math.AngleDifference(lastSnap.y, currentAngle.y))
    --print(newAngle)
    if newAngle > maxDifference then
        lastSnap:Set(mv:GetAngles())
        OnSnap(ply)
    end
end )

-- hook.Add( "Think", "ILoveThinkingAboutBrokenGlass", function()

--     for _, glass in ipairs( ents.FindByClass( "func_breakable_surf" ) ) do
--     	if glass:GetInternalVariable("m_bIsBroken") then
--             -- print("deez nuts")
--             debugoverlay.Sphere(glass:OBBCenter(),10,0.1)
--         end
--     end

-- end )


hook.Add("OnPlayerHitGround", "LandSound", function(ply)
        local tr = util.TraceLine({
        start = ply:GetPos(),
        endpos = ply:GetPos() + Vector(0, 0, -10),
        filter = ply
    })
    local land = surfacefootstepsland
    local land_indoor = surfacefootstepsland_indoor
    local materialtype = getSurfacePropName(tr.SurfaceProps or 30)
    if IndoorCheck(ply) then
        ply:EmitSound(land_indoor[materialtype])
    else
        ply:EmitSound(land[materialtype])
    end
end)

hook.Add("OnPlayerJump", "JumpSound", function(ply)
    local tr = util.TraceLine({
        start = ply:GetPos(),
        endpos = ply:GetPos() + Vector(0, 0, -10),
        filter = ply
    })

    local materialtype = getSurfacePropName(tr.SurfaceProps or 30)
    local jumping = config.surfacefootsteps_jump
    local jumpsound = jumping[materialtype]

    if jumpsound then
        ply:EmitSound(jumpsound)
    end
end)

function IndoorCheck(ply)
    local tr = util.TraceLine({
        start = ply:GetPos(),
        endpos = ply:GetPos() + Vector(0, 0, 1000),
        filter = ply
    })
    -- print("its a roof lol")
    return tr.Hit and not tr.HitSky
end

hook.Add("PlayerTick", "PlayerBreathing", function(ply)
    local wasinwater = ply:WaterLevel()

    if CLIENT then
        return
    end

    -- if ply:KeyDown(IN_SPEED) and ply:IsOnGround() and ply:GetVelocity():Length() > 100 then
    --     if ply.BreathingStartTime == nil then
    --         ply.BreathingStartTime = CurTime()
    --     end
    --     -- print(ply.BreathingStartTime)
    --     if CurTime() > ply.BreathingStartTime + 10 then
    --         if ply.BreathingPlayed == nil then
    --             ply:EmitSound("breath.loop")
    --             ply.BreathingPlayed = true
    --         end
    --     end
    -- else
    --     ply.BreathingStartTime = nil
    --     if ply.BreathingPlayed == true then
    --         ply:EmitSound("breath.end")
    --     end
    --     ply.BreathingPlayed = nil
    -- end

    if ply:KeyDown(IN_DUCK) and ply:IsOnGround() then
        if ply.PlayerCrouched == nil then
            ply.PlayerCrouched = true
            ply:EmitSound("stand.to.crouch")
        end
    else
        if ply.PlayerCrouched == true then
            ply:EmitSound("crouch.to.stand")
            ply.PlayerCrouched = nil
        end
    end

    if wasinwater > 0 then
        ply.IsInWater = true
        ply.WaterExitTime = nil
    else
        if ply.IsInWater == true then
            ply.WaterExitTime = CurTime()
            ply.IsInWater = false
        end
    end
end)