local get_item_repair_price = function(stack)
	local stats = saturn.get_item_stats(stack:get_name())
	if stats then
		if stats['max_wear'] and stats['price'] then
			return stats['price'] * stack:get_count() * stack:get_wear() * stats['max_wear'] * saturn.REPAIR_PRICE_PER_WEAR / saturn.MAX_ITEM_WEAR
		end
	end
	return 0
end

saturn.repair_player_inventory_and_get_price = function(player, _do_repair)
	local do_repair = _do_repair
	local total_repair_price = 0
	local inv = player:get_inventory()
	for list_name,list in pairs(inv:get_lists()) do
		for listpos,stack in pairs(list) do
			if stack ~= nil then
				local repair_price = get_item_repair_price(stack)
				total_repair_price = total_repair_price + repair_price
				if do_repair then
					local money = saturn.players_info[player:get_player_name()]['money']
					if money >= repair_price then
						stack:set_wear(0)
						inv:set_stack(list_name, listpos, stack)
						saturn.players_info[player:get_player_name()]['money'] = money - repair_price
					else
						do_repair = false
					end
				end
			end
		end
	end
	return total_repair_price
end

saturn.get_space_station_formspec = function(player, tab)
	local name = player:get_player_name()
	local default_formspec = 
		"label[0,3.75;"..minetest.formspec_escape("Money: ")..string.format ('%4.0f',saturn.players_info[name]['money']).." Cr.]"..
		"tabheader[0,0;tabs;Equipment market,Ore market,Microfactory market,Hangar and ship;"..tab..";true;false]"..
		saturn.default_slot_color..
		"label[6.8,4.1;Buyout spot:]".."image[7,4.5;1,1;saturn_money.png]"..
		"list[detached:space_station;buying_up_spot;7,4.5;1,1;]"..
		"label[0,4.1;"..minetest.formspec_escape("Hangar: ").."]"..
		"list[current_player;hangar;0,4.5;6,1;]"
	for ix = 1, 6 do
		default_formspec = default_formspec.."image_button["..(ix-0.19)..",4.5;0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+hangar+"..ix..";]"
	end
	if tab == 1 then
		default_formspec = "size[8,7]"..
		default_formspec..
		"list[detached:space_station;market;0,0;8,4;]"..
		"button[0,6;8,1;repair;Repair all player equipment. Price: "..string.format ('%4.0f',saturn.repair_player_inventory_and_get_price(player, false)).." Cr.]"
		for ix = 1, 8 do
			for iy = 0, 3 do
				default_formspec = default_formspec.."image_button["..(ix-0.19)..","..(iy)..";0.3,0.4;saturn_info_button_icon.png;item_info_detached+space_station+market+"..(ix+8*iy)..";]"
			end
		end
	elseif tab == 2 then
		default_formspec = "size[8,7]"..
		default_formspec..
		"list[detached:space_station;ore_market;0,0;8,4;]"..
		"button[0,6;8,1;repair;Repair all player equipment. Price: "..string.format ('%4.0f',saturn.repair_player_inventory_and_get_price(player, false)).." Cr.]"
		for ix = 1, 8 do
			for iy = 0, 3 do
				default_formspec = default_formspec.."image_button["..(ix-0.19)..","..(iy)..";0.3,0.4;saturn_info_button_icon.png;item_info_detached+space_station+ore_market+"..(ix+8*iy)..";]"
			end
		end
	elseif tab == 3 then
		default_formspec = "size[8,7]"..
		default_formspec..
		"list[detached:space_station;microfactory_market;0,0;8,4;]"..
		"button[0,6;8,1;repair;Repair all player equipment. Price: "..string.format ('%4.0f',saturn.repair_player_inventory_and_get_price(player, false)).." Cr.]"
		for ix = 1, 8 do
			for iy = 0, 3 do
				default_formspec = default_formspec.."image_button["..(ix-0.19)..","..(iy)..";0.3,0.4;saturn_info_button_icon.png;item_info_detached+space_station+microfactory_market+"..(ix+8*iy)..";]"
			end
		end
	else
		default_formspec = "size[8,9.75]"..
		default_formspec..
		saturn.get_ship_equipment_formspec(player)..
		saturn.get_main_inventory_formspec(player,5.75)
	end
	return default_formspec
end

saturn.space_station_inv = minetest.create_detached_inventory("space_station", {
    allow_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
	return 0
    end,
    allow_put = function(inv, listname, index, stack, player) 
	return stack:get_count()
    end,
    allow_take = function(inv, listname, index, stack, player) 
	if saturn.players_info[player:get_player_name()]['money'] < saturn.get_item_price(stack:get_name()) * stack:get_count() then
		return 0
	else
		return stack:get_count()
	end
    end,
    on_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
    end,
    on_put = function(inv, listname, index, stack, player) 
	local add_money = saturn.get_item_price(stack:get_name()) * stack:get_count() * 0.7
	saturn.players_info[player:get_player_name()]['money'] = saturn.players_info[player:get_player_name()]['money'] + add_money
	saturn.space_station_inv:remove_item("buying_up_spot", stack)
	local tab = 1
	if player:get_attach() then
		local ship_lua = player:get_attach():get_luaentity()
		tab = ship_lua['current_gui_tab']
	end
	minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, tab))
    end,
    on_take = function(inv, listname, index, stack, player)
	saturn.players_info[player:get_player_name()]['money'] = saturn.players_info[player:get_player_name()]['money'] - saturn.get_item_price(stack:get_name()) * stack:get_count()
	local tab = 1
	if player:get_attach() then
		local ship_lua = player:get_attach():get_luaentity()
		tab = ship_lua['current_gui_tab']
	end
	minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, tab))
    end,
})

saturn.space_station_inv:set_size("market", 8 * 4)
saturn.space_station_inv:set_size("ore_market", 8 * 4)
saturn.space_station_inv:set_size("microfactory_market", 8 * 4)
saturn.space_station_inv:set_size("buying_up_spot", 1)

local box_slope = { --This 9 lines taken from "moreblocks" mod by Calinou and contributors without any changes. Source: https://github.com/kaeza/calinou_mods/tree/master/moreblocks
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5, 0.5, -0.25, 0.5},
		{-0.5, -0.25, -0.25, 0.5,     0, 0.5},
		{-0.5,     0,     0, 0.5,  0.25, 0.5},
		{-0.5,  0.25,  0.25, 0.5,   0.5, 0.5}
	}
}

minetest.register_node("saturn:space_station_hull", {
	description = "Space station hull",
	tiles = {"saturn_space_station_hull.png"},
	groups = {space_station = 1},
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			minetest.remove_node(pointed_thing.under)
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		minetest.add_node(vector.add(user:getpos(),user:get_look_dir()), {name=itemstack:get_name(), param1=0, param2=0})
	end,
})

minetest.register_node("saturn:space_station_hull_slope", {
	description = "Space station hull slope",
	drawtype = "mesh",
	mesh = "saturn_slope.obj",--This mesh taken from "moreblocks" mod by Calinou and contributors with small changes. Source: https://github.com/kaeza/calinou_mods/tree/master/moreblocks
	tiles = {"saturn_space_station_hull.png"},
	groups = {space_station = 1},
	collision_box = box_slope,
	paramtype = "light",
	paramtype2 = "wallmounted",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			local old_node = minetest.get_node(pointed_thing.under)
			if old_node.param2 < 5 then
				old_node.param2 = old_node.param2 + 1
			else
				old_node.param2 = 0
			end
			minetest.swap_node(pointed_thing.under, old_node)
		end
	end,
})


minetest.register_node("saturn:space_station_window", {
	description = "Space station window",
	tiles = {"saturn_space_station_window.png"},
	groups = {space_station = 1},
})

minetest.register_node("saturn:space_station_gates", {
	description = "Space station gates",
	tiles = {"saturn_space_station_hull.png",
		"saturn_space_station_gates.png",
		"saturn_space_station_gates.png",
		"saturn_space_station_gates.png",
		"saturn_space_station_gates.png",
		"saturn_space_station_gates.png",},
	groups = {space_station = 1},
})

minetest.register_node("saturn:space_station_yellow_black_stripes", {
	description = "Space station yellow black stripes",
	tiles = {"saturn_space_station_yellow_black_stripes.png"},
	groups = {space_station = 1},
})


minetest.register_node("saturn:space_station_hatch", {
	description = "Space station hatch",
	tiles = {"saturn_space_station_hatch.png"},
	groups = {space_station = 1},
	on_rightclick = function(pos, node, player)
		if player:get_attach() then
			local ship_lua = player:get_attach():get_luaentity()
			ship_lua['current_gui_tab']=1
		end
		minetest.show_formspec(
			player:get_player_name(),
			"saturn:space_station",
			saturn.get_space_station_formspec(player, 1)
		)
	end,
})

local generate_random_market_item = function()
	local item_name = saturn.market_items[math.random(#saturn.market_items)]
	return ItemStack(item_name.." "..minetest.registered_items[item_name].stack_max)
end

local generate_random_ore_market_item = function()
	local item_name = saturn.ore_market_items[math.random(#saturn.ore_market_items)]
	return ItemStack(item_name.." 99")
end

local generate_random_microfactory_market_item = function()
	local item_name = saturn.microfactory_market_items[math.random(#saturn.microfactory_market_items)]
	return ItemStack(item_name)
end

local update_space_station_market = function()
	local stack = generate_random_market_item()
	if saturn.space_station_inv:room_for_item("market", stack) then
		saturn.space_station_inv:add_item("market", stack)
	else
		saturn.space_station_inv:set_stack("market",math.random(8*4), stack)
	end
	local stack = generate_random_ore_market_item()
	if saturn.space_station_inv:room_for_item("ore_market", stack) then
		saturn.space_station_inv:add_item("ore_market", stack)
	else
		saturn.space_station_inv:set_stack("ore_market",math.random(8*4), stack)
	end
	local stack = generate_random_microfactory_market_item()
	if saturn.space_station_inv:room_for_item("microfactory_market", stack) then
		saturn.space_station_inv:add_item("microfactory_market", stack)
	else
		saturn.space_station_inv:set_stack("microfactory_market",math.random(8*4), stack)
	end
end

saturn.update_space_station_market = update_space_station_market

for i=0, 8*4 do
	update_space_station_market()
end

minetest.register_chatcommand("create_schematic", {
	params = "filename pos1 pos2",
	description = "Create schematic",
	privs = {server = true},
	func = function(name, param)
		local params_list = string.split(param, " ", false, -1, false)
		minetest.create_schematic(minetest.string_to_pos(params_list[2]), minetest.string_to_pos(params_list[3]), {}, minetest.get_modpath("saturn").."/schematics/"..params_list[1])
		return true, "schematic created"
	end,
})

minetest.register_chatcommand("place_schematic", {
	params = "filename pos1",
	description = "Create schematic",
	privs = {server = true},
	func = function(name, param)
		local params_list = string.split(param, " ", false, -1, false)
		minetest.place_schematic(minetest.string_to_pos(params_list[2]), minetest.get_modpath("saturn").."/schematics/"..params_list[1], 0, {}, true)
		return true, "schematic placed"
	end,
})
