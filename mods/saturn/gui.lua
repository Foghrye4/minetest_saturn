local format_pos = function(format,pos)
	return "("..string.format(format,pos.x)..","..string.format(format,pos.y)..","..string.format(format,pos.z)..")"
end

local PROJECTION_XZ = 1
local PROJECTION_XY = 2
local scale_map = {1,2,4,8,16,32,64,128}

local get_map_scale_bar_formspec = function(scale)
    local x_pos = 0.2
    local y_pos = 4
    local bar_length = 8
    local formspec = "image_button["..x_pos..","..y_pos..
";0.5,0.5;"..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:1")..";set_map_scale_"..math.min(scale+1,bar_length)..";;false;false;"
..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:1").."]"..
	"image_button["..x_pos..","..(y_pos+bar_length*0.35+0.35)..
";0.5,0.5;"..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:2")..";set_map_scale_"..math.max(scale-1,1)..";;false;false;"
..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:2").."]"
    for i=1,bar_length do
	if i == scale then
		formspec = formspec .. "image_button["..x_pos..","..(y_pos+(bar_length-i+1)*0.35)..
";0.5,0.5;"..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:6")..";set_map_scale_"..i..";;false;false;"
..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:6").."]"
	else
		formspec = formspec .. "image_button["..x_pos..","..(y_pos+(bar_length-i+1)*0.35)..
";0.5,0.5;"..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:5")..";set_map_scale_"..i..";;false;false;"
..minetest.formspec_escape("saturn_gui_icons.png^[verticalframe:8:5").."]"
	end
    end
    return formspec
end

local get_map_mark_formspec = function(scale, projection, pos, player_pos, title, width, height)
    local scale_multiplier = scale_map[scale]
    local x_pos = ((pos.x - player_pos.x) * scale_multiplier + 31000) * width / 62000
    local y_pos = ((player_pos.z - pos.z) * scale_multiplier + 31000) * height / 62000
    if projection == PROJECTION_XY then
	y_pos = ((player_pos.y - pos.y) * scale_multiplier + 31000) * height / 62000
    end
    if x_pos > 0 and x_pos < width and y_pos > 0 and y_pos < height then
	return "image["..x_pos..","..(y_pos+1)..";0.5,0.5;saturn_arrows_and_frame_blue.png^[verticalframe:10:9]"..
"label["..x_pos..","..(y_pos+1)..";"..title..format_pos("%d",pos).."]"
    else
	return ""
    end
end

local get_color_formspec_frame = function(x,y,w,h,color,thickness)
	local gap = 0.2
	return "box["..(x-thickness+gap)..","..(y-thickness)..";"..(w+thickness-0.2-gap*2)..","..(thickness)..";"..color.."]"..
"box["..(x+w-0.2)..","..(y-thickness+gap)..";"..(thickness)..","..(h+thickness-0.2-gap*2)..";"..color.."]"..
"box["..(x+gap)..","..(y+h-0.2)..";"..(w+thickness-0.2-gap*2)..","..(thickness)..";"..color.."]"..
"box["..(x-thickness)..","..(y+gap)..";"..(thickness)..","..(h+thickness-0.2-gap*2)..";"..color.."]"
end

saturn.get_color_formspec_frame = get_color_formspec_frame

local get_map_formspec = function(scale, projection, player)
    local form_width = 9
    local form_height = 9
    local coordinate_arrows = "saturn_map_zero_xz_mark.png"
    if projection == PROJECTION_XY then
	coordinate_arrows = "saturn_map_zero_xy_mark.png"
    end
    local formspec = get_map_mark_formspec(scale, projection, player:getpos(), player:getpos(), "YOU", form_width, form_height)..
	"image["..(form_width - 1.5)..","..(form_height - 1.5)..";1,1;"..coordinate_arrows.."]"..
	get_map_scale_bar_formspec(scale)..
	get_color_formspec_frame(0,0,form_width,form_height,"#041",0.05)..
	"field[0.5,1;2,0.2;set_waypoint;"..minetest.formspec_escape("Set waypoint:")..";(0,0,0)]"
    for _,ss in ipairs(saturn.human_space_station) do
	formspec = formspec .. get_map_mark_formspec(scale, projection, ss, player:getpos(), "SS#".._, form_width, form_height)
    end
    for _,ess in ipairs(saturn.enemy_space_station) do
	formspec = formspec .. get_map_mark_formspec(scale, projection, ess, player:getpos(), "EMS#".._, form_width, form_height)
    end
    return formspec
end

local get_equipment_box = function(title, player, iname, ix, iy, w, h, color)
    local inv = player:get_inventory()
    local name = player:get_player_name()
    local formspec = ""
    local size = inv:get_size(iname)
    local dx, dy
    if size > 0 then
	formspec = formspec..(
	    "label["..ix..","..(iy-0.5)..";"..title.."]"..
	    "box"..("["..
		ix..","..iy..";"..
		(w-0.2)..","..(h-0.1)..";"..
		color..
	    "]").."list"..("["..
		"current_player;"..iname..";"..
		ix..","..iy..";"..
		w..","..h..";"..
	    "]")
	)
	for dx = 0, w-1 do
	    for dy = 0, h-1 do
		local loc = dy*w+dx+1
		if loc <= size then
		    formspec = formspec.."image_button"..("["..
			(ix+dx+0.81)..","..(iy+dy)..";"..
			"0.3,0.4;"..
			"saturn_info_button_icon.png;"..(
			    "item_info_player+"..
			    name.."+"..
			    iname.."+"..
			    loc..";"
			)..
		    "]")
		end
	    end
	end
    end
    return formspec
end

saturn.get_ship_equipment_formspec = function(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()
	local formspec =
	get_equipment_box("Hull", player, "ship_hull", 13, 3.4, 1, 1,"#FFFFFF")..
	get_equipment_box("Weapons", player, "main", 0, 0.4, 2, 4,"#000000")..
	get_equipment_box("Engines", player, "engine", 2, 0.4, 2, 4,"#FFA800")..
	get_equipment_box("Power", player, "power_generator", 4, 0.4, 2, 2,"#FF2200")..
	get_equipment_box("Droids", player, "droid", 6, 0.4, 2, 2,"#770000")..
	get_equipment_box("Radar", player, "radar", 6, 3.4, 1, 1,"#00FFF0")..
	get_equipment_box("Shields", player, "forcefield_generator", 10, 0.4, 5, 2,"#A0A0FF")..
	get_equipment_box("Special", player, "special_equipment", 8, 0.4, 2, 2,"#A0FFA0")
	return formspec
end

saturn.get_main_inventory_formspec = function(player, vertical_offset)
    local default_formspec = saturn.default_slot_color
    if player then
    local name = player:get_player_name()
	local hold_size = player:get_inventory():get_size("hold")
        if hold_size > 0 then
	    default_formspec = default_formspec .. "list[current_player;hold;0,"..vertical_offset..";12,4;]"
	    for iy = 0, 3 do
	        for ix = 0, 11 do
			if ix+12*iy >= hold_size then
			    return default_formspec
			end
			default_formspec = default_formspec.."image_button["..(ix+0.81)..","..
				(iy+vertical_offset)..";0.3,0.4;saturn_info_button_icon.png;"..
				"item_info_player+"..name.."+hold+"..(ix+1+12*iy)..";]"
		end
	    end
        end
    end
    return default_formspec
end

local calculate_volumes_for_inventory = function(inv, name, output)
    local slotcnt = inv:get_size(name)
    for i=1,slotcnt do
	local content = inv:get_stack(name, i)
	local count = content:get_count()
	if count == 0 then
	    output.free = output.free + 100
	else
	    output.allocated = output.allocated + 100
	    local volume = saturn.get_item_volume_core(content)
	    output.used = output.used + volume * count
	end
    end
end

local calculate_volumes = function(player)
    local inv = player:get_inventory()
    local output = {allocated = 0, used = 0, free = 0}
    calculate_volumes_for_inventory(inv, "hold", output)
    calculate_volumes_for_inventory(inv, "main", output)
    calculate_volumes_for_inventory(inv, "engine", output)
    calculate_volumes_for_inventory(inv, "power_generator", output)
    calculate_volumes_for_inventory(inv, "droid", output)
    calculate_volumes_for_inventory(inv, "radar", output)
    calculate_volumes_for_inventory(inv, "forcefield_generator", output)
    calculate_volumes_for_inventory(inv, "special_equipment", output)
    return output.allocated, output.used, output.free
end

local get_cargo_hold_space_status = function(player)
    local allocated, used, free
    allocated, used, free = calculate_volumes(player)
    local name = player:get_player_name()
    local money_str = string.format ('%4.0f',saturn.players_info[name]['money'])
    local ship = player:get_attach()
    local ship_lua = ship:get_luaentity()
    local weight = ship_lua['weight']
    local traction = ship_lua['traction'] + (ship_lua.total_modificators['traction'] or 0)
    local forcefield_protection = ship_lua['forcefield_protection'] + (ship_lua.total_modificators['forcefield_protection'] or 0)
    local protection = string.format ('%1.1f',forcefield_protection)
    local formspec = (
	"label[0,4.6;Cargo hold space (m3)]"..
	"label[0,4.95;Used]"..
	"label[0,5.3;"..string.format('%1.2f',used).."]"..
	"label[1.5,4.95;Alloc.]"..
	"label[1.5,5.3;"..string.format('%1.0f',allocated).."]"..
	"label[3,4.95;Free]"..
	"label[3,5.3;"..string.format('%1.0f',free).."]"..
	"label[4.2,4.6;Total ship]"..
	"label[4.2,4.9;weight (kg)]"..
	"label[4.2,5.3;"..string.format ('%1.0f',weight).."]"..
	"label[6,4.6;Traction]"..
	"label[6,4.9;(kN)]"..
	"label[6,5.3;"..string.format ('%1.1f',traction/1000).."]"..
	"label[7.5,4.6;Maximal]"..
	"label[7.5,4.9;accel. (m/s2)]"..
	"label[7.5,5.3;"..string.format('%1.4f',traction/weight).."]"..
	"label[7.5,2.4;Power output]"..
	"label[7.5,2.7;??? MW]"..
	"label[7.5,3.1;Consumption]"..
	"label[7.5,3.4;??? MW]"..
	"label[7.5,3.8;Battery level]"..
	"label[7.5,4.1;??? MJ]"..
	"label[9.7,2.4;Shield output]"..
	"label[9.7,2.8;"..protection.." %/s]"..
	"label[9.7,3.4;Shield level]"..
	"label[9.7,3.8;??? %]"..
	"label[9.7,4.9;Money (Cr)]"..
	"label[9.7,5.3;"..money_str.."]"
    )
    return formspec
end

local get_player_inventory_formspec = function(player, tab)
	local name = player:get_player_name()
	local default_formspec =
		"size[15,9.6]" ..
		"tabheader[0,0;tabs;Hull,Map;"..tab..";true;false]"
	local hull = player:get_inventory():get_stack("ship_hull", 1)
	local hull_stats = saturn.get_item_stats(hull:get_name())
	if hull_stats then
		if tab == 1 then
			return default_formspec..
				get_cargo_hold_space_status(player)..
				saturn.get_ship_equipment_formspec(player)..
				saturn.get_main_inventory_formspec(player,5.85)
		elseif tab == 2 then
			local ship = player:get_attach()
			local ship_lua = ship:get_luaentity()
			local map_scale = ship_lua['map_scale'] or 1
			local map_projection = ship_lua['map_projection'] or 1
			return default_formspec..
				get_map_formspec(map_scale, map_projection, player)
		end
	end
	return default_formspec
end

saturn.get_player_inventory_formspec = get_player_inventory_formspec

saturn.get_item_info_formspec = function(item_stack)
	local item_name = item_stack:get_name()
	local formspec = "size[8,8.6]"..
		"item_image[0,0;1,1;"..item_name.."]"..
		"label[1,0.0;"..item_name.."]"..
		"image_button[6.5,0.1;1.5,0.4;saturn_back_button_icon.png;ii_return;Back  ;false;false;saturn_back_button_icon.png]"
	local row_step = 0.3
	local row = 1
	formspec = formspec.."label[0,"..row..";Basic properties:]"
	row = row + 0.1
	if minetest.registered_items[item_name] then
		for key,value in pairs(minetest.registered_items[item_name]) do
			if not saturn.localisation_and_units[key] then
				error("Missing localisation for "..key)
				return
			end
			if not saturn.localisation_and_units[key].hidden then
				row = row + row_step
				local localisation = saturn.localisation_and_units[key]
				local string_value
				if localisation.format_normal == "date" then
					string_value = saturn.date_to_string(value) .." ".. localisation.units
				elseif type(value) == "number" then
					string_value = string.format(localisation.format_normal,value) .." ".. localisation.units
				else
					string_value = tostring(value)
				end
				formspec = formspec.."label[0,"..row..";"..localisation.name..": "..string_value.."]"
			end
		end
	end
	local metadata = minetest.deserialize(item_stack:get_metadata())
	if metadata then
		row = row + row_step*2
		formspec = formspec.."label[0,"..row..";Special properties:]"
		row = row + 0.1
		for key,value in pairs(metadata) do
			if not saturn.localisation_and_units[key] then
				error("Missing localisation for "..key)
				return
			end
			if not saturn.localisation_and_units[key].hidden then
				row = row + row_step
				local localisation = saturn.localisation_and_units[key]
				local string_value
				if localisation.format_special == "date" then
					string_value = saturn.date_to_string(value) .." ".. localisation.units
				elseif type(value) == "number" then
					string_value = string.format(localisation.format_special,value) .." ".. localisation.units
				else
					string_value = tostring(value)
				end
				formspec = formspec.."label[0,"..row..";"..localisation.name..": "..string_value.."]"
			end
		end
	end
	return formspec
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local ship = player:get_attach()
    if ship then
	local ship_lua = ship:get_luaentity()
	if fields.tabs or fields.ii_return then
		if fields.ii_return then
			ship_lua['info_active'] = nil
		end
		local tab = ship_lua['current_gui_tab']
		if fields.tabs then
			tab = tonumber(fields.tabs)
		end
		ship_lua['current_gui_tab'] = tab
		if formname == "saturn:space_station" then
			minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, tab, ship_lua['last_ss']))
		end
	elseif fields.repair then
		saturn.repair_player_inventory_and_get_price(player, true)
		minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, ship_lua['current_gui_tab'], ship_lua['last_ss']))
		saturn.refresh_health_hud(player)
	elseif fields.deliver then
		saturn.deliver_package_and_get_reward(ship_lua['last_ss'], player, true)
		minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_space_station_formspec(player, ship_lua['current_gui_tab'], ship_lua['last_ss']))
	elseif fields.set_waypoint then
		for key,v in pairs(fields) do
			local parameters_list, match = string.gsub(key, "^set_map_scale_", "")
			if match == 1 and parameters_list then
				local scale = tonumber(parameters_list)
				ship_lua['map_scale'] = scale
			end
		end
		if fields.quit then
			local wp_pos = minetest.string_to_pos(fields.set_waypoint)
			if wp_pos then
				ship_lua['waypoint'] = wp_pos
			else
				local number, match = string.gsub(fields.set_waypoint, "^SS#", "")
				if match == 1 and tonumber(number) and tonumber(number)<=saturn.NUMBER_OF_SPACE_STATIONS then
					ship_lua['waypoint'] = saturn.human_space_station[tonumber(number)]
				end
				number, match = string.gsub(fields.set_waypoint, "^EMS#", "")
				if match == 1 and tonumber(number) and tonumber(number)<=#saturn.enemy_space_station then
					ship_lua['waypoint'] = saturn.enemy_space_station[tonumber(number)]
				end
			end
		end
	elseif fields.quit then
		if formname == "saturn:space_station" then
			local tab = ship_lua['last_gui_tab']
			ship_lua['last_gui_tab'] = nil
			ship_lua['current_gui_tab'] = tab
		end
		ship_lua['is_node_gui_opened'] = false
		ship_lua['info_active'] = nil
	else
		for key,v in pairs(fields) do
			local parameters_list, match = string.gsub(key, "^item_info_", "")
			if match == 1 and parameters_list then
				local item_stack_location_data = string.split(parameters_list, "+", false, -1, false)
				local inventory_type = item_stack_location_data[1]
				local inventory_name_or_pos = item_stack_location_data[2]
				local inventory_list_name = item_stack_location_data[3]
				local inventory_slot_number = tonumber(item_stack_location_data[4])
				local inventory
				if inventory_type == "nodemeta" then
					inventory = minetest.get_inventory({type=inventory_type, pos=minetest.string_to_pos(inventory_name_or_pos)})
					if not inventory then
						error("Calling inventory failed for "..parameters_list)
					end
				else
					inventory = minetest.get_inventory({type=inventory_type, name=inventory_name_or_pos})
				end
				local item_stack = inventory:get_stack(inventory_list_name, inventory_slot_number)
				if not item_stack:is_empty() then
					ship_lua['info_active'] = true
					if formname == "saturn:space_station" then
						minetest.show_formspec(player:get_player_name(), "saturn:space_station", saturn.get_item_info_formspec(item_stack))
					else
						player:set_inventory_formspec(saturn.get_item_info_formspec(item_stack))
					end
					return true
				end
			end
		end
	end
    end
end)

