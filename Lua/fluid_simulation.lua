local fluidSimulation = {}

local mathUtils = dofile("Mods/FluidMod/Lua/math_utils.lua")

local gasDistributionSpeedConstant = 0.01
local temperatureSpeedConstant = 5

local gas
fluidSimulation.SetGasses = function (gasses)
    gas = gasses
end

local function GetCharactersInHull(hull)
    local chars = Player.GetAllCharacters()

    for key, value in pairs(chars) do
        if value.CurrentHull ~= hull then table.remove(chars, key) end
    end

    return chars
end

local function GetCharactersInHullFast(hull1, hull2)
    local chars = Character.CharacterList
    local hulls = {}

    hulls[hull1] = {}
    hulls[hull2] = {}

    for key, value in pairs(chars) do
        if value.CurrentHull == hull1 or value.CurrentHull == hull2 then
            table.insert(hulls[value.CurrentHull], value)
        end
    end

    return hulls
end

local function ApplyPressure(chars, pressure, gap, mult)
    local stun = math.abs(pressure/813)

    if tostring(stun) == "NaN" then
        SafePrint("STUN VALUE WAS NIL! PRESSURE: " .. pressure)
        stun = 1
    end

    local speedlimit = 15
    for key, value in pairs(chars) do
        if value.AnimController ~= nil then
            value.CharacterHealth.Stun = stun
            for _, limb in pairs(value.AnimController.Limbs) do
                local force = Vector2.Normalize(gap.WorldPosition - value.WorldPosition) * pressure

                local nextvelocity = limb.body.LinearVelocity + (force/limb.body.Mass)
                if nextvelocity.Length() < speedlimit then
                    limb.body.ApplyForce(force * mult)
                else
                    limb.body.LinearVelocity = Vector2.Normalize(nextvelocity * mult) * speedlimit
                end
            end
        end
    end
end

fluidSimulation.Simulate = function (gap, hull1, hull2)
    local hullsTotalGas = {}
    for _, gasName in pairs(gas.listGasses) do
        local totalGas = gas.GetGas(hull1, gasName) + gas.GetGas(hull2, gasName)

        hullsTotalGas[hull1] = (hullsTotalGas[hull1] or 1) + gas.GetGas(hull2, gasName)
        hullsTotalGas[hull2] = (hullsTotalGas[hull2] or 1) + gas.GetGas(hull2, gasName)

        local totalVolume = (hull1.Volume + hull2.Volume)
        local deltaGas = (totalGas * hull1.Volume / totalVolume) - gas.GetGas(hull1, gasName)

        deltaGas = mathUtils.clamp(deltaGas, -gap.Size * gasDistributionSpeedConstant, gap.Size * gasDistributionSpeedConstant)

        local pressure1 = (gas.GetGas(hull1, gasName) * 813 * gas.GetTemperature(hull1))/hull1.Volume
        local pressure2 = (gas.GetGas(hull2, gasName) * 813 * gas.GetTemperature(hull2))/hull2.Volume
        local pressure = pressure1 - pressure2
        local stun = math.abs(pressure/813)

        if stun > 1 then
            local chars = GetCharactersInHullFast(hull1, hull2)

            ApplyPressure(chars[hull1], pressure, gap, 1)
            ApplyPressure(chars[hull2], pressure, gap, -1)
        end

        if math.abs(deltaGas) > 0 then
            gas.AddGas(hull1, gasName, deltaGas)        
            gas.AddGas(hull2, gasName, -deltaGas)
        end
    end

    local temperatureDifference = gas.GetTemperature(hull1) - gas.GetTemperature(hull2)
    if math.abs(temperatureDifference) > 0 then
        local deltaTemperature = mathUtils.clamp(temperatureDifference, -gap.Size * temperatureSpeedConstant, gap.Size * temperatureSpeedConstant)
        deltaTemperature = math.min(deltaTemperature, math.min(gas.GetTemperature(hull1), gas.GetTemperature(hull2)))

        local dtemp1 = deltaTemperature / hullsTotalGas[hull1]
        local dtemp2 = deltaTemperature / hullsTotalGas[hull2]

        gas.AddTemperature(hull1, -dtemp1)
        gas.AddTemperature(hull2, dtemp2)
    end
end


return fluidSimulation