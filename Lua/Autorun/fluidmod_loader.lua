local safeTimer = 0
function SafePrint(txt, delay)
    if Timer.GetTime() < safeTimer then return end
    print(txt)
    safeTimer = Timer.GetTime() + (delay or 0.01)
end


dofile("Mods/FluidMod/Lua/fluidmod.lua")
