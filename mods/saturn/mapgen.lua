minetest.register_alias("mapgen_stone", "air")
minetest.register_alias("mapgen_dirt", "saturn:fog")
minetest.register_alias("mapgen_dirt_with_grass", "saturn:fog")
minetest.register_alias("mapgen_sand", "saturn:fog")
minetest.register_alias("mapgen_water_source", "saturn:fog")
minetest.register_alias("mapgen_river_water_source", "saturn:fog")
minetest.register_alias("mapgen_lava_source", "air")
minetest.register_alias("mapgen_gravel", "saturn:fog")
minetest.register_alias("mapgen_desert_stone", "saturn:fog")
minetest.register_alias("mapgen_desert_sand", "saturn:fog")
minetest.register_alias("mapgen_dirt_with_snow", "saturn:fog")
minetest.register_alias("mapgen_snowblock", "saturn:fog")
minetest.register_alias("mapgen_snow", "saturn:fog")
minetest.register_alias("mapgen_ice", "saturn:fog")
minetest.register_alias("mapgen_sandstone", "saturn:fog")

minetest.register_ore({
	ore_type       = "sheet",
	ore            = "saturn:fog",
	wherein        = "air",
	clust_scarcity = 60*60*60,
	clust_num_ores = 30,
	clust_size     = 16,
	height_min     = -14000,
	height_max     = 800,
        noise_threshold = 0.5,
        noise_params = {offset=0, scale=1, spread={x=100, y=100, z=100}, seed=23, octaves=3, persist=0.70},
	column_height_max = 1,
})

minetest.register_ore({ 
	ore_type         = "blob",
	ore              = "saturn:water_ice",
	wherein          = {"air","saturn:fog"},
	clust_scarcity   = 24*24*24,
	clust_size       = 35,
	y_min            = -14900,
	y_max            = 800,
	noise_threshold = 0,
	noise_params     = {
		offset=-0.75,
		scale=1,
		spread={x=100, y=100, z=100},
		seed=484,
		octaves=3,
		persist=0.8
	},
})

minetest.register_ore({ 
	ore_type         = "blob",
	ore              = "saturn:water_ice",
	wherein          = {"air","saturn:fog"},
	clust_scarcity   = 24*24*24,
	clust_size       = 10,
	y_min            = -15000,
	y_max            = 1000,
	noise_threshold = 0,
	noise_params     = {
		offset=-0.75,
		scale=1,
		spread={x=50, y=50, z=50},
		seed=485,
		octaves=3,
		persist=0.8
	},
})

local noise_seed = 485
for ore_name,stats in pairs(saturn.ores) do
    noise_seed = noise_seed + 1
    minetest.register_ore({ 
	ore_type         = "blob",
	ore              = ore_name,
	wherein          = {"saturn:water_ice"},
	clust_scarcity   = 24*24*24,
	clust_size       = 35,
	y_min            = -14900,
	y_max            = 1000,
	noise_threshold = 0,
	noise_params     = {
		offset=stats['noise_offset'],
		scale=1,
		spread={x=100, y=100, z=100},
		seed=noise_seed,
		octaves=3,
		persist=0.8
	},
    })

end

local ss_x = saturn.space_station_pos.x
local ss_y = saturn.space_station_pos.y
local ss_z = saturn.space_station_pos.z

local ess_x = saturn.enemy_space_station.x
local ess_y = saturn.enemy_space_station.y
local ess_z = saturn.enemy_space_station.z

minetest.register_on_generated(function(minp, maxp, seed)
	local minp_x = minp.x
	local minp_y = minp.y
	local minp_z = minp.z
	local maxp_x = maxp.x
	local maxp_y = maxp.y
	local maxp_z = maxp.z
	if maxp_x >= ss_x and 
	maxp_y >= ss_y and 
	maxp_z >= ss_z and 
	minp_x < ss_x and 
	minp_y < ss_y and 
	minp_z < ss_z then
		minetest.place_schematic(saturn.space_station_pos, minetest.get_modpath("saturn").."/schematics/human_space_station.mts", 0, {}, true)
	elseif maxp_x >= ess_x and 
	maxp_y >= ess_y and 
	maxp_z >= ess_z and 
	minp_x < ess_x and 
	minp_y < ess_y and 
	minp_z < ess_z then
		minetest.place_schematic(saturn.enemy_space_station, minetest.get_modpath("saturn").."/schematics/enemy_mothership.mts", 0, {}, true)
	end
end)
