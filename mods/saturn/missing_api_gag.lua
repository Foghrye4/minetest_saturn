-- Launch after player.lua

if not minetest.register_on_player_inventory_add_item then
    saturn.current_handled_player = 1
    saturn.players_list = {}
    
    calculate_carried_weight = saturn.calculate_carried_weight
    calculate_carried_volume = saturn.calculate_carried_volume
    refresh_ship_equipment = saturn.refresh_ship_equipment
    apply_cargo = saturn.apply_cargo

    minetest.register_globalstep(function(dtime)
    	local chp = saturn.current_handled_player
    	if chp <= #saturn.players_list then
	    local player = saturn.players_list[chp]
	    if player and player:get_attach() then
	    	apply_cargo(player,calculate_carried_weight(player:get_inventory()),calculate_carried_volume(player:get_inventory()))
		refresh_ship_equipment(player, "any")
	    end
    	else
	    chp = 0
	    saturn.players_list = minetest.get_connected_players()
    	end
    	saturn.current_handled_player = chp + 1
    end)
end

