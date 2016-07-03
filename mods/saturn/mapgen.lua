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
	height_max     = 100,
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
	y_max            = 100,
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
	y_max            = 200,
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
	y_max            = 100,
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
local ss_min_coord = -128 -- Space station minimal coordinate
local ss_max_coord = 128-- Space station maximal coordinate
local ss_sphere_sqr = 4096 -- Space station inner sphere squared radius
local ss_hatches_console_sqr = 13456 -- Space station inner sphere squared radius
local hull = minetest.get_content_id("saturn:space_station_hull")
local window = minetest.get_content_id("saturn:space_station_window")
local hatch = minetest.get_content_id("saturn:space_station_hatch")

minetest.register_on_generated(function(minp, maxp, seed)
	local minp_x = minp.x
	local minp_y = minp.y
	local minp_z = minp.z
	local maxp_x = maxp.x
	local maxp_y = maxp.y
	local maxp_z = maxp.z
	if maxp_x >= ss_min_coord  + ss_x and 
	maxp_y >= ss_min_coord + ss_y and 
	maxp_z >= ss_min_coord + ss_z and 
	minp_x <= ss_max_coord + ss_x and 
	minp_y <= ss_max_coord + ss_y and 
	minp_z <= ss_max_coord + ss_z then
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local data = vm:get_data()
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
		local param2_data = vm:get_param2_data()
		for z = minp_z, maxp_z do
     		 	for y = minp_y, maxp_y do
       		 	 	for x = minp_x, maxp_x do
					local p_pos = area:index(x, y, z)
					local x1 = x - ss_x
					local y1 = y - ss_y
					local z1 = z - ss_z
					local sq_r = x1*x1+y1*y1+z1*z1
					if sq_r<ss_sphere_sqr then
						if (y1 + 2) % 4 == 0 and 
						math.floor(x1 / 5 - 0.5) % 2 ==0 and
						math.floor(z1 / 5 - 0.5) % 2 ==0 then
							data[p_pos] = window
						else
							data[p_pos] = hull
						end
					else
						if z1 * z1 <= ss_hatches_console_sqr  and 
						y1 * y1 <= ss_hatches_console_sqr and 
						x1 * x1 <= ss_hatches_console_sqr then
							if (x1 * x1 <= 4 and y1 * y1 <= 4) or
							(x1 * x1 <= 4 and z1 * z1 <= 4) or
							(z1 * z1 <= 4 and y1 * y1 <= 4) then
								data[p_pos] = hull
							else
								if z1 % 16 == 0 and z1 * z1 > ss_sphere_sqr + 16 then
									if x1 * x1 == 9 and y1 == 0 then
										data[p_pos] = hatch
										if x1 > 0 then
											param2_data[p_pos] = 2
										else
											param2_data[p_pos] = 3
										end
									end
									if y1 * y1 == 9 and x1 == 0 then
										data[p_pos] = hatch
										if y1 > 0 then
											param2_data[p_pos] = 0
										else
											param2_data[p_pos] = 1
										end
									end
								end
								if y1 % 16 == 0 and y1 * y1 > ss_sphere_sqr + 16 then
									if x1 * x1 == 9 and z1 == 0 then
										data[p_pos] = hatch
										if x1 > 0 then
											param2_data[p_pos] = 2
										else
											param2_data[p_pos] = 3
										end
									end
									if z1 * z1 == 9 and x1 == 0 then
										data[p_pos] = hatch
										if z1 > 0 then
											param2_data[p_pos] = 4
										else
											param2_data[p_pos] = 5
										end
									end
								end
								if x1 % 16 == 0 and x1 * x1 > ss_sphere_sqr + 16 then
									if z1 * z1 == 9 and y1 == 0 then
										data[p_pos] = hatch
										if z1 > 0 then
											param2_data[p_pos] = 4
										else
											param2_data[p_pos] = 5
										end
									end
									if y1 * y1 == 9 and z1 == 0 then
										data[p_pos] = hatch
										if y1 > 0 then
											param2_data[p_pos] = 0
										else
											param2_data[p_pos] = 1
										end
									end
								end
							end
						end
			   		end
				end
      		   	end
   	   	end
		vm:set_data(data)
		vm:set_param2_data(param2_data)
		vm:write_to_map()
		vm:calc_lighting()
	end
end)
