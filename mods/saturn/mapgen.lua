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

local mapgen_chunksize = minetest.setting_get("chunksize")
local blob_scarcity = 51200 -- chunk_volume/this = amounts of blobs per chunk. Chunk volume is 80*80*80 = 512000, so it is 10 blobs per chunk

minetest.register_ore({
	ore_type       = "sheet",
	ore            = "saturn:fog",
	wherein        = "air",
	clust_scarcity = -1, -- Unused for sheet. Can be any
	clust_num_ores = 30,
	clust_size     = 16,
	y_min     = -300,
	y_max     = 300,
        noise_threshold = 0.5,
        noise_params = {offset=0, scale=1, spread={x=100, y=100, z=100}, seed=23, octaves=3, persist=0.70},
	column_height_max = 1,
})

minetest.register_ore({ 
	ore_type         = "blob",
	ore              = "saturn:water_ice",
	wherein          = {"air","saturn:fog"},
	clust_scarcity   = blob_scarcity,
	clust_size       = 35,
	y_min            = -400,
	y_max            = 400,
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
	clust_scarcity   = blob_scarcity,
	clust_size       = 10,
	y_min            = -750,
	y_max            = 750,
	noise_threshold = 0,
	noise_params     = {
		offset=-0.75, 	-- 0.75
		scale=1, 	-- 1
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
	clust_scarcity   = blob_scarcity,
	clust_size       = 35,
	y_min            = -750,
	y_max            = 750,
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

local is_inside_aabb = saturn.is_inside_aabb
local update_space_station_market = saturn.update_space_station_market

local mapgen_schematics_map = {}

local hss_filename_prefix = minetest.get_modpath("saturn").."/schematics/splitted/".."human_space_station".."_"

for _,ss in ipairs(saturn.human_space_station) do
	local minx = math.floor((ss.x-58+32)/16/mapgen_chunksize)*16*mapgen_chunksize
	local miny = math.floor((ss.y-100+32)/16/mapgen_chunksize)*16*mapgen_chunksize
	local minz = math.floor((ss.z-58+32)/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxx = math.ceil((ss.x+58)/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxy = math.ceil((ss.y+109)/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxz = math.ceil((ss.z+58)/16/mapgen_chunksize)*16*mapgen_chunksize
	for ix = minx, maxx, 16*mapgen_chunksize do
	for iy = miny, maxy, 16*mapgen_chunksize do
	for iz = minz, maxz, 16*mapgen_chunksize do
	    local filename = hss_filename_prefix..math.floor((ix-minx)/16/mapgen_chunksize).."_"..math.floor((iy-miny)/16/mapgen_chunksize).."_"..math.floor((iz-minz)/16/mapgen_chunksize)..".mts"
	    local file = io.open(filename, "r")
	    if file ~= nil then
		mapgen_schematics_map[minetest.hash_node_position(vector.new(ix-32,iy-32,iz-32))] = filename
		file:close()
	    end
	end
	end
	end
end

local ess_filename_prefix = minetest.get_modpath("saturn").."/schematics/splitted/".."enemy_mothership".."_"

for _,ess in ipairs(saturn.enemy_space_station) do
	local minx = math.floor((ess.x-28+32)/16/mapgen_chunksize)*16*mapgen_chunksize
	local miny = math.floor((ess.y-28+32)/16/mapgen_chunksize)*16*mapgen_chunksize
	local minz = math.floor((ess.z-28+32)/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxx = math.ceil((ess.x+228)/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxy = math.ceil((ess.y+28)/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxz = math.ceil((ess.z+28)/16/mapgen_chunksize)*16*mapgen_chunksize
	for ix = minx, maxx, 16*mapgen_chunksize do
	for iy = miny, maxy, 16*mapgen_chunksize do
	for iz = minz, maxz, 16*mapgen_chunksize do
	    local filename = ess_filename_prefix..math.floor((ix-minx)/16/mapgen_chunksize).."_"..math.floor((iy-miny)/16/mapgen_chunksize).."_"..math.floor((iz-minz)/16/mapgen_chunksize)..".mts"
	    local file = io.open(filename, "r")
	    if file ~= nil then
		mapgen_schematics_map[minetest.hash_node_position(vector.new(ix-32,iy-32,iz-32))] = filename
		file:close()
	    else
	    end
	end
	end
	end
end

--[[saturn.gen_timer = os.clock()
saturn.first_gen = os.clock()
saturn.gen_number = 0]]
minetest.register_on_generated(function(minp, maxp, seed)
--[[    local gen_interval = os.clock()-saturn.gen_timer
    saturn.gen_number = saturn.gen_number + 1
    local gen_average = (os.clock()-saturn.first_gen)/saturn.gen_number
    minetest.chat_send_all("Generation takes "..string.format("%4.2f",gen_interval).."s")
    minetest.chat_send_all("Average "..string.format("%4.2f",gen_average).."s")
    saturn.gen_timer = os.clock()]]
    local structure_filename = mapgen_schematics_map[minetest.hash_node_position(minp)]
    if structure_filename then
    	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	minetest.place_schematic_on_vmanip(vm, minp, structure_filename, 0, {}, true)
	vm:calc_lighting()
	vm:write_to_map()
    end
end)
