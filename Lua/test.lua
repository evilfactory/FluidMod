Game.DisableSpamFilter(true)

local function clamp(value, min, max)
    return math.min(math.max(value, min), max);
end

local lastoxy = {}

local gasses = {}

local temperatures = {}

local listOfGasses = {}

listOfGasses.weldingFuel = {}

listOfGasses.oxygen = {}

local gasDistributionSpeed = 0.1
local normalTemperature = 300

local safeTimer = 0
local function safePrint(txt, delay)
    if Timer.GetTime() < safeTimer then return end
    print(txt)
    safeTimer = Timer.GetTime() + (delay or 0.01)
end

local function GetGas(hull, type)
    if gasses[hull] == nil then
        gasses[hull] = {}
    end

    if gasses[hull][type] == nil then
        gasses[hull][type] = 0
    end

    return gasses[hull][type]
end

local function AddGas(hull, type, amount)
    if gasses[hull] == nil then
        gasses[hull] = {}
    end

    if gasses[hull][type] == nil then
        gasses[hull][type] = 0
    end

    gasses[hull][type] = clamp(gasses[hull][type] + amount, 0, hull.Volume)
end

local function GetTemperature(hull)
    if temperatures[hull] == nil then
        temperatures[hull] = normalTemperature
    end
    return temperatures[hull]
end

local function AddTemperature(hull, amount)
    if temperatures[hull] == nil then
        temperatures[hull] = normalTemperature
    end

    temperatures[hull] = temperatures[hull] + amount
end

local function GetCharactersInHull(hull)
    local chars = Player.GetAllCharacters()

    for key, value in pairs(chars) do
        if value.CurrentHull ~= hull then table.remove(chars, key) end
    end

    return chars
end

Hook.Add("changeFallDamage", "testFallDamage", function (amount, character, impactpos, velocity)
    local damage = velocity.Length() * 15
    --safePrint(tostring(damage))
    return damage
end)

local burnPrefab

for k, v in pairs(AfflictionPrefab.ListArray) do
    if v.name == "Burn" then
       burnPrefab = v
       break
    end
end

local function ApplyPressure(hull, pressure, gap, mult)
    local chars = GetCharactersInHull(hull)
    local stun = math.abs(pressure/813)
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


local function oxygenupdate(gap, hull1, hull2)
    local hullsTotalGas = {}
    for k, v in pairs(listOfGasses) do
        local totalGas = GetGas(hull1, k) + GetGas(hull2, k)

        hullsTotalGas[hull1] = (hullsTotalGas[hull1] or 0) + GetGas(hull2, k)
        hullsTotalGas[hull2] = (hullsTotalGas[hull2] or 0) + GetGas(hull2, k)

        local totalVolume = (hull1.Volume + hull2.Volume)
        local deltaGas = (totalGas * hull1.Volume / totalVolume) - GetGas(hull1, k)
        deltaGas = clamp(deltaGas, -gap.Size * gasDistributionSpeed, gap.Size * gasDistributionSpeed)

        local pressure1 = (GetGas(hull1, k) * 813 * GetTemperature(hull1))/hull1.Volume
        local pressure2 = (GetGas(hull2, k) * 813 * GetTemperature(hull2))/hull2.Volume
        local pressure = pressure1 - pressure2
        local stun = math.abs(pressure/813)

        if stun > 1 then
                --safePrint(tostring(pressure1).. "binga".. tostring(pressure2).. "chinga".. tostring(pressure))
            ApplyPressure(hull1, pressure, gap, 1)
            ApplyPressure(hull2, pressure, gap, -1)
        end

        if math.abs(deltaGas) > 0 then
            AddGas(hull1, k, deltaGas)        
            AddGas(hull2, k, -deltaGas)
        end
    end

    local temperatureDifference = GetTemperature(hull1) - GetTemperature(hull2)
    if math.abs(temperatureDifference) > 0 then
        local deltaTemperature = gap.Size * temperatureDifference
        deltaTemperature = math.min(deltaTemperature, math.min(GetTemperature(hull1), GetTemperature(hull2)))
        local dtemp1 = deltaTemperature/hullsTotalGas[hull1]/200
        local dtemp2 = deltaTemperature/hullsTotalGas[hull2]/200

        AddTemperature(hull1, -dtemp1)
        AddTemperature(hull2, dtemp2)
    end
end

local oxygenUpdateTimer = 0
local gapList = {}

for k, v in pairs(Gap.GapList) do
    local linkedHulls = v.linkedTo
    if linkedHulls[1] ~= nil and linkedHulls[2] ~= nil and linkedHulls[1] ~= linkedHulls[2] then
        table.insert(gapList, v)
    end
end

print(#gapList)

Hook.Add("think", "binga", function()
    if Timer.GetTime() > oxygenUpdateTimer then
        local startTime = os.clock()
        for k, v in pairs(gapList) do
            if v.open > 0 then
                local linkedHulls = v.linkedTo
                if linkedHulls[1] ~= nil and linkedHulls[2] ~= nil and linkedHulls[1] ~= linkedHulls[2] then
                    oxygenupdate(v, linkedHulls[1], linkedHulls[2])
                end
            end
        end

        local endTime = os.clock() - startTime
        --safePrint("Calculating took: " .. string.format("%.4f", endTime), 0.1)
        local startTime = os.clock()

        for k, char in pairs(Character.CharacterList) do
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
        end

        local endTime = os.clock() - startTime
        --safePrint("Calculating with characters took: " .. string.format("%.4f", endTime), 0.1)

        oxygenUpdateTimer = Timer.GetTime() + 0.1
    end

    --for k, hull in pairs(Hull.hullList) do 
        --local test = 1
        -- local oxy = GetGas(hull, "oxygen")
        -- if lastoxy[hull] ~= nil and hull.Oxygen ~= lastoxy[hull] then
        --     gasses[hull]["oxygen"] = oxy + (hull.oxygen - lastoxy[hull])
        -- end
        -- hull.Oxygen = oxy
        -- lastoxy[hull] = hull.Oxygen
    --end
end)

Hook.Add("chatMessage", "chatMessageDebug", function (msg, client)
    if msg == "!info" then
        local mess = ""

        mess = mess .. "Volume: " .. client.Character.CurrentHull.Volume
        mess = mess .. "\nTemperature: " .. GetTemperature(client.Character.CurrentHull) .. "K"
        mess = mess .. "\nWelding Fuel: " .. GetGas(client.Character.CurrentHull, "weldingFuel")
        mess = mess .. "\nOxygen: " .. GetGas(client.Character.CurrentHull, "oxygen")


        Game.SendMessage(mess, 1)
    end

    if msg == "!add" then
        AddGas(client.Character.CurrentHull, "weldingFuel", 2000)
    end

    if msg == "!hot" then
        AddTemperature(client.Character.CurrentHull, 50)
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