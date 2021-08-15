Game.DisableSpamFilter(true)

local function clamp(value, min, max)
    return math.min(math.max(value, min), max);
end

local gasses = {}

local temperatures = {}

local listOfGasses = {}

listOfGasses.weldingFuel = {}
listOfGasses.weldingFuel.heatTransfer = 0.5

listOfGasses.oxygen = {}
listOfGasses.oxygen.heatTransfer = 0.5

local gasDistributionSpeed = 0.1
local normalTemperature = 310

local function GetGas(hull, type)
    if type == "oxygen" then return hull.Oxygen / 5000 end
    
    if gasses[hull] == nil then
        gasses[hull] = {}
    end

    if gasses[hull][type] == nil then
        gasses[hull][type] = 0
    end

    return gasses[hull][type]
end

local function AddGas(hull, type, amount)
    if type == "oxygen" then 
        hull.Oxygen = hull.Oxygen + amount * 5000
        return
    end

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

local speedLimit = 10

Hook.Add("gapOxygenUpdate", "gapOxygenUpdateTest", function (gap, hull1, hull2)
    for k, v in pairs(listOfGasses) do
        local totalGas = GetGas(hull1, k) + GetGas(hull2, k)
        local totalVolume = (hull1.Volume + hull2.Volume)
    
        local deltaGas = (totalGas * hull1.Volume / totalVolume) - GetGas(hull1, k)
        deltaGas = clamp(deltaGas, -gap.Size * gasDistributionSpeed, gap.Size * gasDistributionSpeed)

        if math.abs(deltaGas) > 0.01 then
            local chars1 = GetCharactersInHull(hull1)
            for key, value in pairs(chars1) do
                if value.AnimController ~= nil then
                    value.CharacterHealth.Stun = deltaGas * 15

                    for _, limb in pairs(value.AnimController.Limbs) do
                        limb.body.ApplyForce(-(gap.WorldPosition - value.WorldPosition) * deltaGas * 2, speedLimit)
                    end
                end
            end

            local chars2 = GetCharactersInHull(hull2)
            for key, value in pairs(chars2) do
                if value.AnimController ~= nil then
                    value.CharacterHealth.Stun = deltaGas * 15

                    for _, limb in pairs(value.AnimController.Limbs) do
                        limb.body.ApplyForce((gap.WorldPosition - value.WorldPosition) * deltaGas * 2, speedLimit)
                    end
                end
            end
        end


        AddGas(hull1, k, deltaGas)
        AddGas(hull2, k, -deltaGas)
    end

    return true

    --local temperatureDifference = GetTemperature(hull1) - GetTemperature(hull2)
    --local deltaTemperature = coeffient * gap.Size * temperatureDifference

    --deltaTemperature = clamp(deltaTemperature, -temperatureDistributionSpeed, temperatureDistributionSpeed)

    --AddTemperature(hull1, deltaTemperature)
    --AddTemperature(hull2, -deltaTemperature)
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
        AddGas(client.Character.CurrentHull, "weldingFuel", 50)
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