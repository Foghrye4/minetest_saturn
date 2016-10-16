-- Launch after player.lua

if not minetest.register_on_player_inventory_add_item then
    saturn.current_handled_player = 1
    saturn.players_list = {}
    saturn.players_weights = {}    
    saturn.players_weights_total = {}    

    calculate_carried_weight = saturn.calculate_carried_weight
    calculate_carried_volume = saturn.calculate_carried_volume
    refresh_ship_equipment = saturn.refresh_ship_equipment
    apply_cargo = saturn.apply_cargo

    minetest.register_globalstep(function(dtime)
    	local chp = saturn.current_handled_player
    	if chp <= #saturn.players_list then
	    local player = saturn.players_list[chp]
	    if player and player:get_attach() then
		local name = player:get_player_name()
		local inv = player:get_inventory()
		if not saturn.players_weights[name] then
		    saturn.players_weights[name] = {}
		    saturn.players_weights_total[name] = -1
		    for list_name,list in pairs(inv:get_lists()) do
		        if not saturn.players_weights[name][list_name] then
			    saturn.players_weights[name][list_name] = -1
			end
		    end
		end
		local weight = 0
		for list_name,list in pairs(inv:get_lists()) do
		    local listweight = 0
		    for listpos,stack in pairs(list) do
			if stack ~= nil and not stack:is_empty() then
			    listweight = listweight + saturn.get_item_weight(list_name, stack) * stack:get_count()
			end
		    end
		    if listweight ~= saturn.players_weights[name][list_name] then
			refresh_ship_equipment(player, list_name)
			saturn.players_weights[name][list_name] = listweight
		    end
		    weight = weight + listweight
		end
		if saturn.players_weights_total[name] ~= weight then
		    	apply_cargo(player,weight,calculate_carried_volume(inv))
			saturn.players_weights_total[name] = weight
		end
	    end
    	else
	    chp = 0
	    saturn.players_list = minetest.get_connected_players()
    	end
    	saturn.current_handled_player = chp + 1
    end)
end

