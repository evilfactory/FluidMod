local gas = dofile("Mods/FluidMod/Lua/gasses.lua")
local fluidSimulation = dofile("Mods/FluidMod/Lua/fluid_simulation.lua")

gas.DefineGas("oxygen")
gas.DefineGas("weldingFuel")

fluidSimulation.SetGasses(gas)

local oxygenUpdateTimer = 0
Hook.Add("think", "fluidmod", function()
    if Timer.GetTime() > oxygenUpdateTimer then

        for k, v in pairs(Gap.GapList) do
            if v.open > 0 then
                local linkedHulls = v.linkedTo
                if linkedHulls[1] ~= nil and linkedHulls[2] ~= nil and linkedHulls[1] ~= linkedHulls[2] then
                    fluidSimulation.Simulate(v, linkedHulls[1], linkedHulls[2])
                end
            end
        end

--[[         for k, char in pairs(Character.CharacterList) do
            if char.CurrentHull then
                local temp = GetTemperature(char.CurrentHull)
                if temp > 320 then
                    local damage = (temp - 310)/2000
                    for k, limb in pairs(char.AnimController.Limbs) do
                        char.CharacterHealth.ApplyAffliction(limb, burnPrefab.Instantiate(damage))
                    end
                elseif temp < 283 then
                    local funny = "joebiden"
                end
            end 
        end ]]

        oxygenUpdateTimer = Timer.GetTime() + 0.1 -- updates run at 10 times a second
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

    if msg == "!hot" then
        gas.AddTemperature(client.Character.CurrentHull, 50)
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
