-- Version 0.007
-- Foghrye4
saturn = rawget(_G, "saturn") or {}

minetest.setting_set("time_speed", 0)
minetest.set_timeofday(0.3)
minetest.setting_set("enable_clouds", "false")
minetest.setting_set("movement_gravity", 0)

local modpath = minetest.get_modpath("saturn")

dofile(modpath .. "/math_utils.lua")
dofile(modpath .. "/localisation_and_units.lua")
dofile(modpath .. "/global_functions_and_variables.lua")
dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/microfactories.lua")
dofile(modpath .. "/items.lua")
dofile(modpath .. "/space_station.lua")
dofile(modpath .. "/player.lua")
dofile(modpath .. "/missing_api_gag.lua")
dofile(modpath .. "/enemy.lua")
dofile(modpath .. "/mapgen.lua")
dofile(modpath .. "/chat_commands.lua")

