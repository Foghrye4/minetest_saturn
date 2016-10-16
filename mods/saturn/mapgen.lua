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
	y_min     = -300,
	y_max     = 300,
        noise_threshold = 0.5,
        noise_params = {offset=0, scale=1, spread={x=100, y=100, z=100}, seed=23, octaves=3, persist=0.70},
	column_y_max = 1,
})

minetest.register_ore({ 
	ore_type         = "blob",
	ore              = "saturn:water_ice",
	wherein          = {"air","saturn:fog"},
	clust_scarcity   = 24*24*24,
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
	clust_scarcity   = 24*24*24,
	clust_size       = 10,
	y_min            = -750,
	y_max            = 750,
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

local mapgen_chunksize = minetest.setting_get("chunksize")

local mapgen_schematics_map = {}

local hss_filename_prefix = minetest.get_modpath("saturn").."/schematics/splitted/".."human_space_station".."_"

for _,ss in ipairs(saturn.human_space_station) do
	local minx = math.floor(ss.minp.x/16/mapgen_chunksize)*16*mapgen_chunksize
	local miny = math.floor(ss.minp.y/16/mapgen_chunksize)*16*mapgen_chunksize
	local minz = math.floor(ss.minp.z/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxx = math.ceil(ss.maxp.x/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxy = math.ceil(ss.maxp.y/16/mapgen_chunksize)*16*mapgen_chunksize
	local maxz = math.ceil(ss.maxp.z/16/mapgen_chunksize)*16*mapgen_chunksize
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


minetest.register_on_generated(function(minp, maxp, seed)
    local structure_filename = mapgen_schematics_map[minetest.hash_node_position(minp)]
    if structure_filename then
    	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	minetest.place_schematic_on_vmanip(vm, minp, structure_filename, 0, {}, true)
	vm:calc_lighting()
	vm:write_to_map()
    end
end)

--[[

saturn.on_first_generation = true

minetest.register_on_generated(function(minp, maxp, seed)
    local all_structures_are_generated = true
    for _indx,ss in ipairs(saturn.human_space_station) do
	if saturn.on_first_generation then
	    minetest.emerge_area(ss.minp, ss.maxp)
	end
	if is_inside_aabb(ss,minp,maxp) then
	    -- Human space staion size 209 Y 116 XZ
	    minetest.place_schematic(vector.new(ss.x-58,ss.y-100,ss.z-58), minetest.get_modpath("saturn").."/schematics/human_space_station.mts", 0, {}, true)
	    ss.is_generated = true
	    return
	end
	if not ss.is_generated then
	    all_structures_are_generated = false
	end
    end
    for _indx,ess in ipairs(saturn.enemy_space_station) do
	if saturn.on_first_generation then
	    minetest.emerge_area(ess.minp, ess.maxp)
	end
	if is_inside_aabb(ess,minp,maxp) then
	    minetest.place_schematic(vector.new(ess.x-26,ess.y-26,ess.z-32), minetest.get_modpath("saturn").."/schematics/enemy_mothership.mts", 0, {}, true)
	    ess.is_generated = true
	    return
	end
	if not ess.is_generated then
	    all_structures_are_generated = false
	end
    end
    saturn.on_first_generation = false
    if all_structures_are_generated then
	table.remove(core.registered_on_generateds, saturn.rog)
    end
end)

saturn.rog = #core.registered_on_generateds ]]--
