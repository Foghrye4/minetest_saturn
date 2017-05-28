-- Version 0.011
-- Foghrye4
saturn = rawget(_G, "saturn") or {}

minetest.setting_set("time_speed", 0)
minetest.set_timeofday(0.3)
minetest.setting_set("enable_clouds", "false")

-- Set gravity to 0 on each player without modifying minetest.conf
minetest.register_on_joinplayer(function(player)
	player:set_physics_override({
		gravity = 0
	})
end)

local modpath = minetest.get_modpath("saturn")

dofile(modpath .. "/math_utils.lua")
dofile(modpath .. "/localisation_and_units.lua")
dofile(modpath .. "/global_functions_and_variables.lua")
dofile(modpath .. "/gui.lua")
dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/microfactories.lua")
dofile(modpath .. "/items.lua")
dofile(modpath .. "/space_station.lua")
dofile(modpath .. "/player.lua")
dofile(modpath .. "/missing_api_gag.lua")
dofile(modpath .. "/enemy.lua")
dofile(modpath .. "/mapgen.lua")
dofile(modpath .. "/chat_commands.lua")

