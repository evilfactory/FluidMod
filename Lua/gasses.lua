local gasses = {}

local normalTemperature = 300

gasses.listGasses = {}
gasses.gasHullStorage = {}
gasses.temperatureHullStorage = {}

gasses.GetTemperature = function (hull)
    return gasses.temperatureHullStorage[hull] or normalTemperature
end

gasses.AddTemperature = function (hull, amount)
    gasses.temperatureHullStorage[hull] = (gasses.temperatureHullStorage[hull] or normalTemperature) + amount
end

gasses.SetTemperature = function (hull, amount)
    gasses.temperatureHullStorage[hull] = amount
end

gasses.DefineGas = function (gasname)
    table.insert(gasses.listGasses, gasname)
end

gasses.AddGas = function (hull, gasname, amount)
    if gasses.gasHullStorage[hull] == nil then
        gasses.gasHullStorage[hull] = {}
    end

    gasses.gasHullStorage[hull][gasname] = (gasses.gasHullStorage[hull][gasname] or 0) + amount
end

gasses.SetGas = function (hull, gasname, amount)
    if gasses.gasHullStorage[hull] == nil then
        gasses.gasHullStorage[hull] = {}
    end

    gasses.gasHullStorage[hull][gasname] = amount
end

gasses.GetGas = function (hull, gasname)
    if gasses.gasHullStorage[hull] == nil then
        gasses.gasHullStorage[hull] = {}
    end

    return gasses.gasHullStorage[hull][gasname] or 0
end

return gasses