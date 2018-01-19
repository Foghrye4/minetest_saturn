saturn.NUMBER_OF_SPACE_STATIONS = 5

saturn.save_human_space_station = function()
    local file = io.open(minetest.get_worldpath().."/saturn_human_space_station", "w")
    file:write(minetest.serialize(saturn.human_space_station))
    file:close()
end

saturn.load_human_space_station = function()
    local file = io.open(minetest.get_worldpath().."/saturn_human_space_station", "r")
    if file ~= nil then
	local text = file:read("*a")
        file:close()
	if text and text ~= "" then
	    saturn.human_space_station = minetest.deserialize(text)
	end
    end
end

saturn.load_human_space_station()

local n_chunksize = minetest.setting_get("chunksize") * 16

if not saturn.human_space_station then
    saturn.human_space_station = {}
    for i = 1, saturn.NUMBER_OF_SPACE_STATIONS do
	local x,y,z
	if i==1 then
	    x = 0
	    y = -100
	    z = 0
	else
	    x = math.floor((math.random(7750) - 3875) * (i-1) / n_chunksize) * n_chunksize + 58 - 32
	    y = math.floor(saturn.get_pseudogaussian_random(-100, 10) / n_chunksize) * n_chunksize + 100 - 32
	    z = math.floor((math.random(7750) - 3875) * (i-1) / n_chunksize) * n_chunksize + 58 - 32
	end
	local minp = {
		x = x - 58 - 80,
		y = y - 100,
		z = z - 58 - 80,}
	local maxp = {
		x = x + 58 + 80,
		y = y + 109 + 80,
		z = z + 58 + 80,}
	saturn.human_space_station[i] = {x = x,
		y = y,
		z = z,
		minp = minp,
		maxp = maxp,
		index = i,
		max_urgency_class = 1,
		}
    end
end

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
			if stack ~= nil and not stack:is_empty() then
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

saturn.deliver_package_and_get_reward = function(ss_index, player, do_deliver)
	local name = player:get_player_name()
	local total_delivery_reward = 0
	local inv = player:get_inventory()
	for list_name,list in pairs(inv:get_lists()) do
		for listpos,stack in pairs(list) do
			if stack ~= nil and not stack:is_empty() and stack:get_name() == "saturn:mail_package" then
				local metadata = minetest.deserialize(stack:get_metadata())
				if metadata and metadata.delivery_address == ss_index then
					local punctuality = math.min(1, (metadata.delivery_term * 2 - (minetest.get_gametime() - metadata.sending_date))/metadata.delivery_term)
					local reward =  metadata.reward * punctuality + 10
					total_delivery_reward = total_delivery_reward + reward
					if do_deliver then
						local postman_rating = saturn.players_info[name]['postman_rating']
						if punctuality >= 1 then
							saturn.players_info[name]['postman_rating'] = postman_rating + 2
							saturn.human_space_station[ss_index].max_urgency_class = saturn.human_space_station[ss_index].max_urgency_class + 1
						end
						local money = saturn.players_info[name]['money']
						saturn.players_info[name]['money'] = money + reward
						stack:clear()
						inv:set_stack(list_name, listpos, stack)
					end
				end
			end
		end
	end
	return total_delivery_reward
end

local get_market_formspec = function(player, market_name, ss_index)
	local player_name = player:get_player_name()
	local default_formspec =
	"list[detached:space_station"..ss_index..";"..market_name..";0,0;8,4;]"..
	"label[0,4.1;"..minetest.formspec_escape("Hangar: ").."]"..
	"list[current_player;hangar"..ss_index..";0,4.5;6,1;]"..
	"button[0,6;8,1;repair;Repair all player equipment. Price: "..string.format ('%4.0f',saturn.repair_player_inventory_and_get_price(player, false)).." Cr.]"
	for ix = 1, 8 do
		for iy = 0, 3 do
			default_formspec = default_formspec.."image_button["..(ix-0.19)..","..(iy)..";0.3,0.4;saturn_info_button_icon.png;item_info_detached+space_station"..ss_index.."+"..market_name.."+"..(ix+8*iy)..";]"
		end
	end
	for ix = 1, 6 do
		default_formspec = default_formspec.."image_button["..(ix-0.19)..",4.5;0.3,0.4;saturn_info_button_icon.png;item_info_player+"..player_name.."+hangar"..ss_index.."+"..ix..";]"
	end
	return default_formspec
end

saturn.get_space_station_formspec = function(player, tab, ss_index)
	local name = player:get_player_name()
	local size = "size[15,9.6]"
	local money = "label[12,4.5;".."Money:\n"..string.format ('%4.0f',saturn.players_info[name]['money']).." Cr.]"
	local buyout =
	"label[12,5.45;Buyout spot:]".."image[12,5.85;1,1;saturn_money.png]"..
	"list[detached:space_station"..ss_index..";buying_up_spot;12,5.85;1,1;]"
	local default_formspec = "tabheader[0,0;tabs;Equipment market,Ore market,Microfactory market,Intelligence info,Post office,Hangar and ship;"..tab..";true;false]"..
		saturn.default_slot_color
	if tab == 1 then
		default_formspec = size .. money .. buyout .. get_market_formspec(player, "market", ss_index) .. default_formspec
	elseif tab == 2 then
		default_formspec = size .. money .. buyout .. get_market_formspec(player, "ore_market", ss_index) .. default_formspec
	elseif tab == 3 then
		default_formspec = size .. money .. buyout .. get_market_formspec(player, "microfactory_market", ss_index) .. default_formspec
	elseif tab == 4 then
		default_formspec = size .. default_formspec..
		"label[0,0;Amount of enemy ships near saturn:]"..		
		"label[5,0;"..#saturn.virtual_enemy.."]"
		local row = -0.3
		for _indx,ss in ipairs(saturn.enemy_space_station) do
			row = row + 0.6
			local ss_x = math.floor(ss.x/10)*10
			local ss_y = math.floor(ss.y/10)*10
			local ss_z = math.floor(ss.z/10)*10
			default_formspec = default_formspec..
			"label[0,"..row..";Enemy motherships near saturn at:]"..
			"label[5,"..row..";("..ss_x..","..ss_y..","..ss_z..")]"..
			"label[0,"..(row+0.3)..";Is deactivated:]"..
			"label[5,"..(row+0.3)..";"..tostring(ss.is_destroyed or "false").."]"
		end
		row = row + 0.6
		for _indx,ss in ipairs(saturn.human_space_station) do
			row = row + 0.3
			local ss_x = math.floor(ss.x/10)*10
			local ss_y = math.floor(ss.y/10)*10
			local ss_z = math.floor(ss.z/10)*10
			default_formspec = default_formspec..
			"label[0,"..row..";Human stations near saturn at:]"..
			"label[5,"..row..";("..ss_x..","..ss_y..","..ss_z..")]"
		end
	elseif tab == 5 then
		default_formspec = size .. default_formspec..
		"list[detached:space_station"..ss_index..";post_office;0,0;1,4;]"..
		money ..
		"label[12,2.5;".."Current time:\n"..saturn.date_to_string(minetest.get_gametime()).."]"..
		"label[12,3.5;Your postman rating:\n"..(saturn.players_info[name]['postman_rating']).."]"..
		"label[0,4;"..
		"The stated reward is paid if delivered before the time indicated. On late delivery,\n"..
		"the reward is reduced proportionally to the delay. If delayed by more than 100%\n"..
		"of the delivery term, the reward is 10 Cr. By taking any of those packages you\n"..
		"accept these terms and conditions of delivery."..
		"]"..
		saturn.get_main_inventory_formspec(player,5.85)
		local delivery_reward = saturn.deliver_package_and_get_reward(ss_index, player, false)
		if delivery_reward > 0 then
			default_formspec = default_formspec..
			"button[12,5.85;3,1;deliver;Deliver packages\nReward: "..string.format ('%d',delivery_reward).." Cr.]"
		end
		local row = 0
		local inv = saturn.space_station_inv[ss_index]
		for listpos,stack in pairs(inv:get_list("post_office")) do
			local metadata = minetest.deserialize(stack:get_metadata())
			if metadata and metadata.sending_date then
				local dst = metadata.delivery_address
				local ss = saturn.human_space_station[dst]
				local ss_x = math.floor(ss.x/10)*10
				local ss_y = math.floor(ss.y/10)*10
				local ss_z = math.floor(ss.z/10)*10
				default_formspec = default_formspec..
				"label[1,"..row..";Sending date:]"..
				"label[3.2,"..row..";"..saturn.date_to_string(metadata.sending_date).."]"..
				"label[5,"..row..";Destination:]"..
				"label[7.2,"..row..";SS#"..dst.." ("..ss_x..","..ss_y..","..ss_z..")]"..
				"label[1,"..(row+0.6)..";Reward:]"..
				"label[3,"..(row+0.6)..";"..string.format('%d', metadata.reward).." Cr.]"..
				"label[5,"..(row+0.3)..";Urgency class:]"..
				"label[7.2,"..(row+0.3)..";"..metadata.urgency_class.."]"..
				"label[1,"..(row+0.3)..";Deliver before:]"..
				"label[3.2,"..(row+0.3)..";"..saturn.date_to_string(metadata.sending_date + metadata.delivery_term).."]"
			end
			row = row + 1
		end

	else
		default_formspec = size .. default_formspec..
		money ..
		saturn.get_ship_equipment_formspec(player)..
		buyout..
		"list[current_player;hangar"..ss_index..";0,4.5;6,1;]"..
		saturn.get_main_inventory_formspec(player,5.85)
		for ix = 1, 6 do
			default_formspec = default_formspec.."image_button["..(ix-0.19)..",4.5;0.3,0.4;saturn_info_button_icon.png;item_info_player+"..name.."+hangar"..ss_index.."+"..ix..";]"
		end
	end
	return default_formspec
end

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

local generate_random_mail_package = function(ss_index)
	local package = ItemStack("saturn:mail_package")
	local delivery_address
	delivery_address = math.random(1,saturn.NUMBER_OF_SPACE_STATIONS-1)
	if delivery_address == ss_index then
	    delivery_address = delivery_address + 1
	end
	local sending_date = minetest.get_gametime()
	local delivery_distance = vector.distance(saturn.human_space_station[ss_index],saturn.human_space_station[delivery_address])
	local urgency_class = math.random(saturn.human_space_station[ss_index].max_urgency_class)
	local delivery_term = (delivery_distance / (10 + urgency_class * urgency_class))*60 + 500
	local reward = urgency_class * urgency_class * delivery_distance
	package:set_metadata(minetest.serialize({
		delivery_address = delivery_address,
		sending_date = sending_date,
		delivery_term = delivery_term,
		urgency_class = urgency_class,
		reward = reward,}))
	return package
end

local get_oldest_mail_package_slot = function(inv)
	local last_sending_date = -1
	local last_slot = 1
	for listpos,stack in pairs(inv:get_list("post_office")) do
		if stack ~= nil and not stack:is_empty() then
			local metadata = minetest.deserialize(stack:get_metadata())
			if metadata and metadata.sending_date then
				if last_sending_date == -1 or last_sending_date > metadata.sending_date then
					last_sending_date = metadata.sending_date
					last_slot = listpos
				end
			end
		end
	end
	return last_slot
end

saturn.space_station_inv = {}
local update_space_station = function(ss_index)
	local inv = saturn.space_station_inv[ss_index]
	local stack = generate_random_market_item()
	if inv:room_for_item("market", stack) then
		inv:add_item("market", stack)
	else
		inv:set_stack("market", math.random(8*4), stack)
	end
	stack = generate_random_ore_market_item()
	if inv:room_for_item("ore_market", stack) then
		inv:add_item("ore_market", stack)
	else
		inv:set_stack("ore_market", math.random(8*4), stack)
	end
	stack = generate_random_microfactory_market_item()
	if inv:room_for_item("microfactory_market", stack) then
		inv:add_item("microfactory_market", stack)
	else
		inv:set_stack("microfactory_market", math.random(8*4), stack)
	end
	if minetest.get_gametime() then
		stack = generate_random_mail_package(ss_index)
		if inv:room_for_item("post_office", stack) then
			inv:add_item("post_office", stack)
		else
			inv:set_stack("post_office", get_oldest_mail_package_slot(inv), stack)
		end
	end
end
saturn.update_space_station = update_space_station

for i=1,saturn.NUMBER_OF_SPACE_STATIONS do
    local inv = minetest.create_detached_inventory("space_station"..i, {
    	allow_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
	    return 0
	end,
    	allow_put = function(inv, listname, index, stack, player) 
		if listname == "post_office" then
			return 0
		end
		return stack:get_count()
    	end,
    	allow_take = function(inv, listname, index, stack, player) 
		if saturn.players_info[player:get_player_name()]['money'] < saturn.get_item_price(stack:get_name()) * stack:get_count() then
			return 0
		else
			if listname == "post_office" then
				local metadata = minetest.deserialize(stack:get_metadata())
				if metadata and metadata.sending_date then
					if saturn.players_info[player:get_player_name()]['postman_rating'] < metadata.urgency_class then
						return 0
					end
				end
			end
			return stack:get_count()
		end
  	  end,
 	on_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
 	end,
 	on_put = function(inv, listname, index, stack, player) 
		local add_money = saturn.get_item_price(stack:get_name()) * stack:get_count() * 0.7
		saturn.players_info[player:get_player_name()]['money'] = saturn.players_info[player:get_player_name()]['money'] + add_money
		inv:remove_item("buying_up_spot", stack)
		local tab = 1
		if player:get_attach() then
			local ship_lua = player:get_attach():get_luaentity()
			tab = ship_lua['current_gui_tab']
		end
		minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, tab, i))
	end,
	on_take = function(inv, listname, index, stack, player)
		saturn.players_info[player:get_player_name()]['money'] = saturn.players_info[player:get_player_name()]['money'] - saturn.get_item_price(stack:get_name()) * stack:get_count()
		if listname == "post_office" then
			saturn.players_info[player:get_player_name()]['postman_rating'] = saturn.players_info[player:get_player_name()]['postman_rating'] - 1
		end
		local tab = 1
		if player:get_attach() then
			local ship_lua = player:get_attach():get_luaentity()
			tab = ship_lua['current_gui_tab']
		end
		minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, tab, i))
	end,
    })
    inv:set_size("market", 8 * 4)
    inv:set_size("ore_market", 8 * 4)
    inv:set_size("microfactory_market", 8 * 4)
    inv:set_size("buying_up_spot", 1)
    inv:set_size("post_office", 4)
    saturn.space_station_inv[i] = inv
    for i1=1,4 do
        update_space_station(i)
    end
end

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

local function update_post_office(player)
    local restart = true
    if player:get_attach() then
	local ship_lua = player:get_attach():get_luaentity()
	local tab = ship_lua['current_gui_tab']
	local i = ship_lua['last_ss']
	local opened = ship_lua['is_node_gui_opened']
	if opened then
	    if tab == 5 then
		    minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, tab, i))
	    end
	else
		restart = false
	end
    end
    if restart then
	minetest.after(0.1, update_post_office, player)
    end
end

minetest.register_node("saturn:space_station_hatch", {
	description = "Space station hatch",
	tiles = {"saturn_space_station_hatch.png"},
	groups = {space_station = 1},
	on_rightclick = function(pos, node, player)
	    for _indx,ss in ipairs(saturn.human_space_station) do
		if saturn.is_inside_aabb(pos,ss.minp,ss.maxp) then
		    if player:get_attach() then
			local ship_lua = player:get_attach():get_luaentity()
			ship_lua['current_gui_tab']=1
			ship_lua['last_ss']=ss.index
			ship_lua['is_node_gui_opened']=true
			minetest.show_formspec(
				player:get_player_name(),
				"saturn:space_station",
				saturn.get_space_station_formspec(player, 1, _indx))
			minetest.after(0.1, update_post_office, player)
		    end
		    return
		end
	    end
	end,
})
