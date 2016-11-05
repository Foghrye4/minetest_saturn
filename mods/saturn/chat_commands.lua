minetest.register_chatcommand("saturn_peaceful_mode", {
	params = "boolean",
	description = "Kill enemies immediatly",
	privs = {server = true},
	func = function(name, param)
		saturn.peaceful_mode = minetest.is_yes(param)
		return true, ("peaceful mode is "..tostring(saturn.peaceful_mode))
	end,
})


minetest.register_chatcommand("saturn_tpme", {
	params = "pos",
	description = "teleport to destination",
	privs = {server = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local ship = player:get_attach()
		local pos = minetest.string_to_pos(param)
		if ship then
			ship:setpos(pos)
		end
		player:setpos(pos)
		return true, "teleported"
	end,
})

minetest.register_chatcommand("saturn_tpme_rel", {
	params = "pos",
	description = "teleport destination relatively",
	privs = {server = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local ship = player:get_attach()
		local pos = minetest.string_to_pos(param)
		local ppos = player:getpos() 
		pos = vector.add(ppos,pos)
		if ship then
			ship:setpos(pos)
		end
		player:setpos(pos)
		return true, "teleported"
	end,
})

minetest.register_chatcommand("saturn_tpme_to_enemy", {
	params = "enemy_ship_number",
	description = "teleport to enemy base",
	privs = {server = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local ship = player:get_attach()
		if ship then
			ship:setpos(saturn.enemy_space_station[tonumber(param)])
		end
		player:setpos(saturn.enemy_space_station[tonumber(param)])
		return true, "teleported"
	end,
})

minetest.register_chatcommand("saturn_tpme_to_base", {
	params = "base_number",
	description = "teleport to human base",
	privs = {server = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local ship = player:get_attach()
		if ship then
			ship:setpos(saturn.human_space_station[tonumber(param)])
		end
		player:setpos(saturn.human_space_station[tonumber(param)])
		return true, "teleported"
	end,
})


minetest.register_chatcommand("get_server_status", {
	params = "",
	description = "Get server status",
	privs = {server = true},
	func = function(name, param)
		return true, minetest.get_server_status()
	end,
})

minetest.register_chatcommand("saturn_add_virtual_enemy", {
	params = "amount",
	description = "Enemy reset",
	privs = {server = true},
	func = function(name, param)
		local enemy_start_number = tonumber(param)
		for i=1,enemy_start_number do
			local pos_x = math.random(30000) - 15000
			local pos_y = math.random(20000)
			local pos_z = math.random(30000) - 15000
			local vel_x = math.random(100)-50
			local vel_y = math.random(100)-50
			local vel_z = math.random(100)-50
			local entity_name = saturn.enemy_spawn_conditions[math.min(#saturn.enemy_spawn_conditions, math.floor(pos_y/2000)+1)]
			table.insert(saturn.virtual_enemy,{
				x=pos_x,
				y=pos_y,
				z=pos_z,
				vel_x=vel_x,
				vel_y=vel_y,
				vel_z=vel_z,
				entity_name=entity_name,})
		end
		return true, "New amount of virtual enemy is "..#saturn.virtual_enemy
	end,
})

minetest.register_chatcommand("saturn_create_schematic", {
	params = "filename pos1 pos2",
	description = "Create schematic",
	privs = {server = true},
	func = function(name, param)
		local params_list = string.split(param, " ", false, -1, false)
		minetest.create_schematic(minetest.string_to_pos(params_list[2]), minetest.string_to_pos(params_list[3]), {}, minetest.get_modpath("saturn").."/schematics/"..params_list[1])
		return true, "schematic created"
	end,
})

local chunksize = minetest.setting_get("chunksize")

minetest.register_chatcommand("saturn_create_splitted_schematic", {
	params = "filename pos1 pos2",
	description = "Create schematic",
	privs = {server = true},
	func = function(name, param)
		local params_list = string.split(param, " ", false, -1, false)
		local pos1 = minetest.string_to_pos(params_list[2])
		local pos2 = minetest.string_to_pos(params_list[3])
		local fragments = 0
		local filename_prefix = minetest.get_modpath("saturn").."/schematics/splitted/"..params_list[1].."_"
		for ix = pos1.x, pos2.x + 16*chunksize, 16*chunksize do
		for iy = pos1.y, pos2.y + 16*chunksize, 16*chunksize do
		for iz = pos1.z, pos2.z + 16*chunksize, 16*chunksize do
			fragments = fragments + 1
			local filename = filename_prefix..math.floor((ix-pos1.x)/16/chunksize).."_"..math.floor((iy-pos1.y)/16/chunksize).."_"..math.floor((iz-pos1.z)/16/chunksize)..".mts"
			minetest.create_schematic(vector.new(ix,iy,iz),vector.new(ix+16*chunksize-1,iy+16*chunksize-1,iz+16*chunksize-1) , {}, filename)
		end
		end
		end
		return true, "Schematic created. Chunksize: "..chunksize.." Number of fragments: "..fragments
	end,
})

minetest.register_chatcommand("saturn_place_schematic", {
	params = "filename pos1",
	description = "Create schematic",
	privs = {server = true},
	func = function(name, param)
		local params_list = string.split(param, " ", false, -1, false)
		minetest.place_schematic(minetest.string_to_pos(params_list[2]), minetest.get_modpath("saturn").."/schematics/"..params_list[1], 0, {}, true)
		return true, "schematic placed"
	end,
})

minetest.register_chatcommand("saturn_peek_node", {
	params = "pos",
	description = "Look node info on pos",
	privs = {server = true},
	func = function(name, param)
		return true, "node: "..dump(minetest.get_node(minetest.string_to_pos(param)))
	end,
})

minetest.register_chatcommand("saturn_dump_ss_info", {
	params = "ss_num",
	description = "Dump space station info",
	privs = {server = true},
	func = function(name, param)
		return true, "Space station: "..dump(saturn.human_space_station[tonumber(param)])
	end,
})

minetest.register_chatcommand("saturn_forceload_block", {
	params = "pos",
	description = "Forceload block at node pos",
	privs = {server = true},
	func = function(name, param)
		minetest.forceload_block(minetest.string_to_pos(param))
		return true, "done"
	end,
})

minetest.register_chatcommand("saturn_show_variable", {
	params = "saturn_variable",
	description = "Show variable",
	privs = {server = true},
	func = function(name, param)
		return true, dump(saturn[param])
	end,
})

minetest.register_chatcommand("saturn_show_global_variable", {
	params = "variable",
	description = "Show global variable",
	privs = {server = true},
	func = function(name, param)
		local params_list = string.split(param, ".", false, -1, false)
		local global = rawget(_G, params_list[1])
		return true, dump(global[params_list[2]])
	end,
})

minetest.register_chatcommand("saturn_set_postman_rating_to_player", {
	params = "player variable",
	description = "Set postman rating",
	privs = {server = true},
	func = function(name, param)
		local params_list = string.split(param, " ", false, -1, false)
		if saturn.players_info[params_list[1]] then
			saturn.players_info[params_list[1]]['postman_rating'] = tonumber(params_list[2] or 1)
			return true, "Player '".. params_list[1].."' now has postman rating "..saturn.players_info[params_list[1]]['postman_rating']
		else
			return false, "No such player '".. (params_list[1] or "").."'"
		end
	end,
})

minetest.register_chatcommand("saturn_update_ss", {
	params = "",
	description = "Update space station",
	privs = {server = true},
	func = function(name, param)
		saturn.update_space_station(tonumber(param))
		return true, "Done, SS#"..param.." updated." 
	end,
})


