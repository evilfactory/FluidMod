local utils = {}

utils.clamp = function(value, min, max)
    return math.min(math.max(value, min), max);
end

return utils