local gas = dofile("Mods/FluidMod/Lua/gasses.lua")
local fluidSimulation = dofile("Mods/FluidMod/Lua/fluid_simulation.lua")
local mathUtils = dofile("Mods/FluidMod/Lua/math_utils.lua")

gas.DefineGas("oxygen")
gas.DefineGas("weldingFuel")

fluidSimulation.SetGasses(gas)

local burnPrefab
local pressureDeathPrefab
local highPressurePrefab
local hypothermiaPrefab

for k, v in pairs(AfflictionPrefab.ListArray) do
    if v.name == "Burn" then
       burnPrefab = v
    end

    if v.name == "High Pressure" then
        highPressurePrefab = v
    end

    if v.name == "Barotrauma" then
        pressureDeathPrefab = v
    end

    if v.name == "Hypothermia" then
        hypothermiaPrefab = v
    end
end

local count = 0
local time = 0


local oxygenUpdateTimer = 0
local afflictionUpdateTimer = 0
Hook.Add("think", "fluidmod", function()
    count = count + 1

    if Timer.GetTime() > time then
        print(count)

        time = Timer.GetTime() + 1
        count = 0
    end

    if Timer.GetTime() > oxygenUpdateTimer then

        for k, v in pairs(Gap.GapList) do
            if v.open > 0 then
                local linkedHulls = v.linkedTo
                if linkedHulls[1] ~= nil and linkedHulls[2] ~= nil and linkedHulls[1] ~= linkedHulls[2] then
                    fluidSimulation.Simulate(v, linkedHulls[1], linkedHulls[2])
                end
            end
        end

        oxygenUpdateTimer = Timer.GetTime() + 0.1 -- updates run at 10 times a second
    end

    if Timer.GetTime() > afflictionUpdateTimer then
        for k, char in pairs(Character.CharacterList) do
            if char.CurrentHull and char.CharacterHealth then
                local temp = gas.GetTemperature(char.CurrentHull)

                local amountHypothermia = char.CharacterHealth.GetAffliction("hypothermia")
                if amountHypothermia ~= nil then amountHypothermia = amountHypothermia.Strength 
                else amountHypothermia = 0 end

                if temp > gas.maxNormalTemperature then
                    local damage = (temp - (gas.maxNormalTemperature)) / 2000
                    for k, limb in pairs(char.AnimController.Limbs) do
                        char.CharacterHealth.ApplyAffliction(limb, burnPrefab.Instantiate(damage))
                    end
                    char.CharacterHealth.ApplyAffliction(char.AnimController.MainLimb, hypothermiaPrefab.Instantiate(-1))
                elseif temp < gas.minNormalTemperature then
                    char.CharacterHealth.ApplyAffliction(char.AnimController.MainLimb, hypothermiaPrefab.Instantiate(0.25))
                elseif amountHypothermia > 0 then
                    char.CharacterHealth.ApplyAffliction(char.AnimController.MainLimb, hypothermiaPrefab.Instantiate(-0.25))
                end

                local pressure = mathUtils.calculateTotalPressure(char.CurrentHull, gas)
                local amountPressure = char.CharacterHealth.GetAffliction("highpressure")

                if amountPressure ~= nil then amountPressure = amountPressure.Strength 
                else amountPressure = 0 end

                if pressure > math.abs(char.PressureProtection) + 1000 then
                    char.CharacterHealth.ApplyAffliction(char.AnimController.MainLimb, highPressurePrefab.Instantiate(1))
                    
                    if amountPressure > 95 then 
                        char.CharacterHealth.ApplyAffliction(char.AnimController.MainLimb, pressureDeathPrefab.Instantiate(1))
                    end
                elseif amountPressure > 0 then
                    char.CharacterHealth.ApplyAffliction(char.AnimController.MainLimb, highPressurePrefab.Instantiate(-1))
                end
            end 
        end 

        afflictionUpdateTimer = Timer.GetTime() + 0.25
    end
end)

Game.DisableSpamFilter(true)
Hook.Add("chatMessage", "chatMessageDebug", function (msg, client)
    if msg == "!info" then
        local mess = ""

        mess = mess .. "Volume: " .. client.Character.CurrentHull.Volume
        mess = mess .. "\nTemperature: " .. gas.GetTemperature(client.Character.CurrentHull) .. "K"

        for _, gasName in pairs(gas.listGasses) do
            mess = mess .. "\n" .. gasName .. ": " .. gas.GetGas(client.Character.CurrentHull, gasName)
        end
        Game.SendMessage(mess, 1)
    end

    if msg == "!add" then
        gas.AddGas(client.Character.CurrentHull, "weldingFuel", 2000)
    end

    if msg == "!ad" then
        gas.AddGas(client.Character.CurrentHull, "weldingFuel", 50)
    end

    if msg == "!hot" then
        gas.AddTemperature(client.Character.CurrentHull, 50)
    end

    if msg == "!cold" then
        gas.AddTemperature(client.Character.CurrentHull, -50)
    end

    if msg == "!pressure" then
        client.Character.CurrentHull.LethalPressure = 1000000
    end

    if msg == "!pressure1" then
        Game.SendMessage(client.Character.CurrentHull.LethalPressure, 1)
    end

    if msg == "!removeoxygen" then
        client.Character.CurrentHull.Oxygen = 0
    end
end)

Hook.Add("changeFallDamage", "testFallDamage", function (amount, character, impactpos, velocity)
    local damage = velocity.Length() * 15
    return damage
end)
