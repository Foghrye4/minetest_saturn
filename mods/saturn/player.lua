
local function remove_unfitted_items_to_hold(player_inv, list_name, slots_max)
    if player_inv:get_size(list_name) > slots_max then
	for listpos,stack in pairs(player_inv:get_list(list_name)) do
	    if listpos > slots_max and stack ~= nil then
		player_inv:remove_item(list_name, stack)
		player_inv:add_item("main", stack)
	    end
	end
    end
end

local function define_player_inventory_slots(player, start_hull)
    local player_inv = player:get_inventory()
    local hull_stats = saturn.get_item_stats(start_hull:get_name())
    local engine_slots = hull_stats.engine_slots
    local power_generator_slots  = hull_stats.power_generator_slots
    local droid_slots = hull_stats.droid_slots
    local radar_slots = hull_stats.radar_slots
    local forcefield_generator_slots = hull_stats.forcefield_generator_slots
    local special_equipment_slots = hull_stats.special_equipment_slots
    player_inv:set_size("ship_hull", 1)
    for i = 1, saturn.NUMBER_OF_SPACE_STATIONS do
	player_inv:set_size("hangar"..i, 6)
    end
    remove_unfitted_items_to_hold(player_inv, "engine", engine_slots)
    remove_unfitted_items_to_hold(player_inv, "power_generator", power_generator_slots)
    remove_unfitted_items_to_hold(player_inv, "droid", droid_slots)
    remove_unfitted_items_to_hold(player_inv, "radar", radar_slots)
    remove_unfitted_items_to_hold(player_inv, "forcefield_generator", forcefield_generator_slots)
    remove_unfitted_items_to_hold(player_inv, "special_equipment", special_equipment_slots)
    player_inv:set_size("engine", engine_slots)
    player_inv:set_size("power_generator", power_generator_slots)
    player_inv:set_size("droid", droid_slots)
    player_inv:set_size("radar", radar_slots)
    player_inv:set_size("forcefield_generator", forcefield_generator_slots)
    player_inv:set_size("special_equipment", special_equipment_slots)
end

local function give_initial_stuff(player, start_hull)
    local player_inv = player:get_inventory()
    player_inv:add_item("ship_hull", start_hull)
    player_inv:add_item("main", ItemStack("saturn:basic_retractor"))
    player_inv:add_item("engine", ItemStack("saturn:ionic_engine"))
    player_inv:add_item("power_generator", ItemStack("saturn:mmfnr"))
end

local function calculate_carried_weight(inv)
	local weight = 0
	for list_name,list in pairs(inv:get_lists()) do
		for listpos,stack in pairs(list) do
			if stack ~= nil then
				weight = weight + saturn.get_item_weight(list_name, stack) * stack:get_count()
			end
		end
	end
	return weight
end

local function calculate_carried_volume(inv)
	local volume = 0
	for list_name,list in pairs(inv:get_lists()) do
		if list_name ~= "ship_hull" and list_name ~= "craft" and list_name ~= "craftresult" then
			for listpos,stack in pairs(list) do
				if stack ~= nil then
					volume = volume + saturn.get_item_volume(list_name, stack) * stack:get_count()
				end
			end
		end
	end
	return volume
end

local function apply_cargo(player, new_carried_weight, new_carried_volume)
	local ship_lua = player:get_attach():get_luaentity()
	ship_lua['weight']=new_carried_weight
	ship_lua['volume']=new_carried_volume
	player:set_inventory_formspec(saturn.get_player_inventory_formspec(player,ship_lua['current_gui_tab']))
end

saturn.calculate_carried_weight = calculate_carried_weight
saturn.calculate_carried_volume = calculate_carried_volume
saturn.apply_cargo = apply_cargo

local function apply_modificator_to_ship_safe(ship_lua, modificator_key, value)
	if ship_lua.total_modificators[modificator_key] then
		ship_lua.total_modificators[modificator_key] = ship_lua.total_modificators[modificator_key] + value
	else
		ship_lua.total_modificators[modificator_key] = value
	end
end

local function apply_modificators(ship_lua)
	ship_lua.total_modificators = {}
	for modificator_key,value in pairs(ship_lua.hull_modificators) do
		apply_modificator_to_ship_safe(ship_lua, modificator_key, value)
	end
	for modificator_key,value in pairs(ship_lua.engine_modificators) do
		apply_modificator_to_ship_safe(ship_lua, modificator_key, value)
	end
	for modificator_key,value in pairs(ship_lua.power_generator_modificators) do
		apply_modificator_to_ship_safe(ship_lua, modificator_key, value)
	end
	for modificator_key,value in pairs(ship_lua.droid_modificators) do
		apply_modificator_to_ship_safe(ship_lua, modificator_key, value)
	end
	for modificator_key,value in pairs(ship_lua.radar_modificators) do
		apply_modificator_to_ship_safe(ship_lua, modificator_key, value)
	end
	for modificator_key,value in pairs(ship_lua.forcefield_modificators) do
		apply_modificator_to_ship_safe(ship_lua, modificator_key, value)
	end
	for modificator_key,value in pairs(ship_lua.special_equipment_modificators) do
		apply_modificator_to_ship_safe(ship_lua, modificator_key, value)
	end
end

local function refresh_hull(player)
	local player_inv = player:get_inventory()
	local ship_lua = player:get_attach():get_luaentity()
	ship_lua.hull_modificators = {}
	local stack = player_inv:get_stack("ship_hull", 1)
	if not stack:is_empty() then
	local stack_name = stack:get_name()
	local stats = saturn.get_item_stats(stack_name)
		ship_lua.is_escape_pod = (stack_name == "saturn:escape_pod")
		if stats then
			if stats['free_space'] and 
			stats['engine_slots'] and
			stats['power_generator_slots'] and
			stats['droid_slots'] and
			stats['radar_slots'] and
			stats['forcefield_generator_slots'] and
			stats['special_equipment_slots'] then
				ship_lua['free_space'] = stats['free_space']
				define_player_inventory_slots(player, stack)
				player:set_properties(stats.player_visual)
				local metadata = minetest.deserialize(stack:get_metadata())
				if metadata then
					for modificator_key,value in pairs(metadata) do
						if ship_lua.hull_modificators[modificator_key] then
							ship_lua.hull_modificators[modificator_key] = ship_lua.hull_modificators[modificator_key] + value
						else
							ship_lua.hull_modificators[modificator_key] = value
						end
					end
				end
			end
		end
	end
end

local function refresh_traction(player)
    local ship_lua = player:get_attach():get_luaentity()
    ship_lua.engine_modificators = {}
    local traction = 0 
    local engine_consumed_power = 0 
    if player:get_inventory():get_size("engine") > 0 then
	for listpos,stack in pairs(player:get_inventory():get_list("engine")) do
		if stack ~= nil and not stack:is_empty() then
			local stats = saturn.get_item_stats(stack:get_name())
			if stats then
				if stats['traction'] and stats['rated_power'] then
					traction = traction + stats['traction']
					engine_consumed_power = engine_consumed_power + stats['rated_power']
					local metadata = minetest.deserialize(stack:get_metadata())
					if metadata then
						if metadata['rated_power'] then
							engine_consumed_power = engine_consumed_power + metadata['rated_power']
						end
						for modificator_key,value in pairs(metadata) do
							if ship_lua.engine_modificators[modificator_key] then
								ship_lua.engine_modificators[modificator_key] = ship_lua.engine_modificators[modificator_key] + value
							else
								ship_lua.engine_modificators[modificator_key] = value
							end
						end
					end
				end
			end
		end
	end
    end
    ship_lua['traction']=traction
    ship_lua['engine_consumed_power']=engine_consumed_power
end

local function refresh_forcefield(player)
    local ship_lua = player:get_attach():get_luaentity()
    ship_lua.forcefield_modificators = {}
    local forcefield_protection = 0 
    local forcefield_consumed_power = 0 
    if player:get_inventory():get_size("forcefield_generator") > 0 then
	for listpos,stack in pairs(player:get_inventory():get_list("forcefield_generator")) do
		if stack ~= nil and not stack:is_empty() then
			local stats = saturn.get_item_stats(stack:get_name())
			if stats then
				if stats['forcefield_protection'] and stats['rated_power'] then
					forcefield_protection = forcefield_protection + stats['forcefield_protection']
					forcefield_consumed_power = forcefield_consumed_power + stats['rated_power']
					local metadata = minetest.deserialize(stack:get_metadata())
					if metadata then
						if metadata['rated_power'] then
							forcefield_consumed_power = forcefield_consumed_power + metadata['rated_power']
						end
						for modificator_key,value in pairs(metadata) do
							if ship_lua.forcefield_modificators[modificator_key] then
								ship_lua.forcefield_modificators[modificator_key] = ship_lua.forcefield_modificators[modificator_key] + value
							else
								ship_lua.forcefield_modificators[modificator_key] = value
							end
						end
					end
				end
			end
		end
	end
    end
    ship_lua['forcefield_protection']=forcefield_protection
    ship_lua['forcefield_generator_consumed_power']=forcefield_consumed_power
end

local function refresh_radar(player)
    local ship_lua = player:get_attach():get_luaentity()
    ship_lua.radar_modificators = {}
    local radar_range = 0
    local radar_consumed_power = 0
    if player:get_inventory():get_size("radar") > 0 then
	for listpos,stack in pairs(player:get_inventory():get_list("radar")) do
		if stack ~= nil and not stack:is_empty() then
			local stats = saturn.get_item_stats(stack:get_name())
			if stats then
				if stats['radar_range'] and stats['rated_power'] then
					radar_range = math.max(radar_range, stats['radar_range'])
					radar_consumed_power = radar_consumed_power + stats['rated_power']
					local metadata = minetest.deserialize(stack:get_metadata())
					if metadata then
						if metadata['rated_power'] then
							radar_consumed_power = radar_consumed_power + metadata['rated_power']
						end
						for modificator_key,value in pairs(metadata) do
							if ship_lua.radar_modificators[modificator_key] then
								ship_lua.radar_modificators[modificator_key] = ship_lua.radar_modificators[modificator_key] + value
							else
								ship_lua.radar_modificators[modificator_key] = value
							end
						end
					end
				end
			end
		end
	end
    end
    ship_lua['radar_range']=radar_range
    ship_lua['radar_consumed_power']=radar_consumed_power
end

local function refresh_power(player)
     local ship_lua = player:get_attach():get_luaentity()
     ship_lua.power_generator_modificators = {}
     local generated_power = 0
     if player:get_inventory():get_size("power_generator") > 0 then
	for listpos,stack in pairs(player:get_inventory():get_list("power_generator")) do
		if stack ~= nil and not stack:is_empty() then
			local stats = saturn.get_item_stats(stack:get_name())
			if stats then
				if stats['generated_power'] then
					generated_power = generated_power + stats['generated_power']
					local metadata = minetest.deserialize(stack:get_metadata())
					if metadata then
						for modificator_key,value in pairs(metadata) do
							if ship_lua.power_generator_modificators[modificator_key] then
								ship_lua.power_generator_modificators[modificator_key] = ship_lua.power_generator_modificators[modificator_key] + value
							else
								ship_lua.power_generator_modificators[modificator_key] = value
							end
						end
					end
				end
			end
		end
	end
    end
    ship_lua['generated_power']=generated_power
end

local function refresh_droid(player)
    local ship_lua = player:get_attach():get_luaentity()
    ship_lua.droid_modificators = {}
    local droid_efficiency = 0 
    local droid_consumed_power = 0 
    if player:get_inventory():get_size("droid") > 0 then
	for listpos,stack in pairs(player:get_inventory():get_list("droid")) do
		if stack ~= nil and not stack:is_empty() then
			local stats = saturn.get_item_stats(stack:get_name())
			if stats then
				if stats['droid_efficiency'] and stats['rated_power'] then
					droid_efficiency = droid_efficiency + stats['droid_efficiency']
					droid_consumed_power = droid_consumed_power + stats['rated_power']
					local metadata = minetest.deserialize(stack:get_metadata())
					if metadata then
						if metadata['rated_power'] then
							droid_consumed_power = droid_consumed_power + metadata['rated_power']
						end
						for modificator_key,value in pairs(metadata) do
							if ship_lua.engine_modificators[modificator_key] then
								ship_lua.engine_modificators[modificator_key] = ship_lua.engine_modificators[modificator_key] + value
							else
								ship_lua.engine_modificators[modificator_key] = value
							end
						end
					end
				end
			end
		end
	end
    end
    ship_lua['droid_efficiency']=droid_efficiency
    ship_lua['droid_consumed_power']=droid_consumed_power
end

local refresh_ship_equipment = function(player, list_to)
	saturn.radars[player:get_player_name()] = nil
	if list_to == "ship_hull" or list_to == "any" then
		refresh_hull(player)
	end
	if list_to == "power_generator" or list_to == "any" then
		refresh_power(player)
	end
	if list_to == "forcefield_generator" or list_to == "any" then
		refresh_forcefield(player)
	end
	if list_to == "engine" or list_to == "any" then
		refresh_traction(player)
	end
	if list_to == "droid" or list_to == "any" then
		refresh_droid(player)
	end
	if list_to == "radar" or list_to == "any" then
		refresh_radar(player)
	end
	local ship_lua = player:get_attach():get_luaentity()
	apply_modificators(ship_lua)
	ship_lua['free_power'] = ship_lua['generated_power'] + (ship_lua.total_modificators['generated_power'] or 0) - ship_lua['engine_consumed_power'] - ship_lua['droid_consumed_power'] - ship_lua['radar_consumed_power'] - ship_lua['forcefield_generator_consumed_power'] - ship_lua['special_equipment_consumed_power']
    	if ship_lua['free_power'] > 0 and ship_lua['radar_range'] > 0 then
	    saturn.radars[player:get_player_name()] = {obj = player:get_attach(), radius = ship_lua['radar_range'] + (ship_lua.total_modificators['radar_range'] or 0)}
	end
	player:set_inventory_formspec(saturn.get_player_inventory_formspec(player,ship_lua['current_gui_tab']))
end

saturn.refresh_ship_equipment = refresh_ship_equipment

local hud_health_energy_bar_frame_definition = {
		hud_elem_type = "image",
		position = { x=0.5, y=1 },
		size = { x=320, y=18},
		text = "saturn_hud_bar_frames.png",
		number = 2,
		alignment = {x=0,y=-1},
		offset = { x=-160, y=-88},
	}


local hud_healthbar_definition = {
		hud_elem_type = "statbar",
		position = { x=0.5, y=1 },
		size = { x=2, y=6},
		text = "saturn_hud_bar.png^[verticalframe:32:1",
		number = 316,
		alignment = {x=0,y=-1},
		offset = { x=-158, y=-86},
	}

local hud_energybar_filler_definition = {
		hud_elem_type = "statbar",
		position = { x=0.5, y=1 },
		size = { x=2, y=6},
		text = "saturn_hud_bar.png^[verticalframe:32:31",
		number = 316,
		alignment = {x=0,y=-1},
		offset = { x=-158, y=-78},
	}


local hud_energybar_definition = {
		hud_elem_type = "statbar",
		position = { x=0.5, y=1 },
		size = { x=2, y=6},
		text = "saturn_hud_bar.png^[verticalframe:32:30",
		number = 316,
		alignment = {x=0,y=-1},
		offset = { x=-158, y=-78},
	}

local hud_hotbar_cooldown = {}

for i=1,8 do
	hud_hotbar_cooldown[i] = {
		hud_elem_type = "statbar",
		position = { x=0.5, y=1 },
		size = { x=0.5, y=0.5 },
		text = "saturn_hud_bar.png^[verticalframe:32:29",
		number = 0,--44,
		alignment = {x=0,y=-1},
		offset = { x=56*(i-5)+4, y=-24},
	}
end

local hud_relative_velocity_definition = {
		hud_elem_type = "text",
		position = { x=1, y=1 },
		size = { x=2, y=24 },
		text = "Relative to ring velocity: ",
		number = 0x65FFCE,
		alignment = {x=1,y=1},
		offset = { x=-250, y=-25},
	}

local hud_attack_info_text_definition = {
		hud_elem_type = "text",
		position = { x=1, y=1 },
		size = { x=2, y=24 },
		text = "",
		number = 0xFF0000,
		alignment = {x=1,y=1},
		offset = { x=-250, y=-50},
	}

local hud_attack_info_frame_definition = {
		hud_elem_type = "image",
		scale = { x=2, y=2 }, 
		position = { x=0.5, y=0.5 },
		size = { x=2, y=24 },
		text = "null.png",
		number = 0xFF0000,
		alignment = {x=0,y=0},
		offset = {x=0, y=0},
	}

local hud_radar_shelf = {}
local hud_radar_text = {}

for i=1,8 do
	hud_radar_shelf[i] = {
		hud_elem_type = "image",
		scale = {x=2, y=2}, 
		size = {x=1, y=1},
		position = { x=0.5, y=0.5 },
		text = "null.png",
		number = 0xFF0000,
		alignment = {x=0,y=0},
		offset = {x=0, y=0},
	}
	hud_radar_text[i] = {
		hud_elem_type = "text",
		scale = {x=2, y=2}, 
		size = {x=1, y=1},
		position = {x=0.5, y=0.5},
		text = "",
		number = 0xFF8A00,
		alignment = {x=0,y=0},
		offset = {x=0, y=0},
	}
end

local hud_waypoint_shelf_definition = {
		hud_elem_type = "image",
		scale = {x=2, y=2}, 
		size = {x=1, y=1},
		position = { x=0.5, y=0.5 },
		text = "null.png",
		number = 0xFF0000,
		alignment = {x=0,y=0},
		offset = {x=0, y=0},
}

local hud_waypoint_text_definition = {
		hud_elem_type = "text",
		scale = {x=2, y=2}, 
		size = {x=1, y=1},
		position = {x=0.5, y=0.5},
		text = "",
		number = 0xFF8A00,
		alignment = {x=0,y=0},
		offset = {x=0, y=0},
}

local attach_player_to_ship = function(player, ship_lua)
	local name = player:get_player_name()
	local old_attach = player:get_attach()
	if old_attach then
		old_attach:remove()
	end
	player:set_attach(ship_lua.object, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
	ship_lua.driver = player
	ship_lua.driver_name = player:get_player_name()
	saturn.refresh_health_hud(player)
	if not saturn.players_info[name] then
	    saturn.players_info[name] = {}
	    if minetest.setting_getbool("creative_mode") then
		    saturn.players_info[name]['money'] = 2147483648
	    else
		    saturn.players_info[name]['money'] = 100
	    end
	    saturn.players_info[name]['postman_rating'] = 1
	    local start_hull = ItemStack("saturn:basic_ship_hull")
	    define_player_inventory_slots(player, start_hull)
	    give_initial_stuff(player, start_hull)
	end
	apply_cargo(player,calculate_carried_weight(player:get_inventory()),calculate_carried_volume(player:get_inventory()))
	refresh_ship_equipment(player, "any")
	saturn.refresh_health_hud(player)
end

local create_new_player = function(player)
    local name = player:get_player_name()
    local ship = minetest.add_entity(player:getpos(), "saturn:spaceship")
    if ship then
    	ship:set_armor_groups({immortal=1})
    	local ship_lua = ship:get_luaentity()
    	ship_lua.driver_name = name
    	attach_player_to_ship(player, ship_lua)
    else
	minetest.after(10, saturn.restore_missing_ship, player)
    end
end

saturn.load_players()

local skybox = {
   "sky_up.png", -- +y
   "sky_down.png", -- -y
   "sky_right.png", -- +z, North
   "sky_left.png", -- -z, South
   "sky_back.png", -- -x, West
   "sky_forward.png", -- +x, East
}

local spaceship = {
	physical = false,
	collisionbox = {-0.01,-0.01,-0.01, 0.01, 0.01, 0.01},
	textures = {"null.png"},
	visual = "sprite",
	visual_size = {x=0.1, y=0.1},
	driver = nil,
	driver_name = nil,
	is_escape_pod = false,
	engine_sound_handler = nil,
	weapon_sound_handler = nil,
	velocity = {x=0, y=0, z=0},
	lastpos = {x=0, y=0, z=0},
	last_attacker = nil,
	radar_object_list = {},
	radar_object_state = {},
	age = 0,
	one_second_timer = 0.0,
	hit_effect_timer = 0,
	weight = 65535,
	volume = 0,
	free_space = 0,
	traction = 0,
	droid_efficiency = 0,
	radar_range = 0,
	forcefield_protection = 0,
	generated_power = 0,
	free_power = 65535,
	recharging_equipment_power_consumption = 0,
	engine_consumed_power = 0,
	droid_consumed_power = 0,
	radar_consumed_power = 0,
	forcefield_generator_consumed_power = 0,
	special_equipment_consumed_power = 0,
	total_modificators = {},
	hull_modificators = {},
	engine_modificators = {},
	power_generator_modificators = {},
	droid_modificators = {},
	radar_modificators = {},
	forcefield_modificators = {},
	special_equipment_modificators = {},
	current_gui_tab = 1,
	ignore_cooldown = false,
	waypoint = nil,
}

function spaceship:on_step(dtime)
	self.age = self.age + dtime
	if self.driver and self.driver:get_look_dir() then
		local player = self.driver
		local name = player:get_player_name()
		local pos = self.object:getpos()
		local controls=player:get_player_control() --{jump=bool,right=bool,left=bool,LMB=bool,RMB=bool,sneak=bool,aux1=bool,down=bool,up=bool}
		local is_player_has_nothing_in_hand = player:get_wielded_item():is_empty()
		local forward_acceleration=0
		local side_acceleration=0
		local level_acceleration=0
		local traction = self['traction']
		local traction_bonus = self.total_modificators['traction']
		if traction_bonus then
			traction = traction + traction_bonus
		end
		local acceleration_module = 0
		if self['weight'] > 0 and self['free_power']>=0 then
			acceleration_module = traction/self['weight']
		end
		local look_dir=player:get_look_dir()
		local look_x=look_dir.x
		local look_y=look_dir.y
		local look_z=look_dir.z
		local look_horizontal = player:get_look_horizontal()
		local look_vertical = player:get_look_vertical()
		if look_horizontal < -math.pi*2 then
			look_horizontal = -math.pi*2
		elseif look_horizontal > math.pi*2 or look_horizontal ~= look_horizontal then
			look_horizontal = math.pi*2
		end
		if look_vertical < -math.pi*0.5 then
			look_vertical = -math.pi*0.5
		elseif look_vertical > math.pi*0.5 or look_vertical ~= look_vertical then -- Check if NaN
			look_vertical = math.pi*0.5
		end
		local velocity = self.object:getvelocity()
		local velocity_module = vector.length(velocity)
		local is_engine_working = false
		if ((controls.right and controls.left) or (is_player_has_nothing_in_hand and controls.RMB)) and velocity_module > 0 and acceleration_module > 0 then
			if velocity_module > acceleration_module then
				is_engine_working = true
				local counteracceleration = {
								x=-velocity.x*acceleration_module/velocity_module,
								y=-velocity.y*acceleration_module/velocity_module,
								z=-velocity.z*acceleration_module/velocity_module,
							}
				self.object:setacceleration(counteracceleration)
			else
				local zero = {x=0, y=0, z=0}
				self.object:setacceleration(zero)
				self.object:setvelocity(zero)
			end				
		elseif acceleration_module > 0 then
			if controls.right and not controls.left then
				is_engine_working = true
				side_acceleration=acceleration_module
			end
			if controls.left and not controls.right then
				is_engine_working = true
				side_acceleration=-acceleration_module
			end
			if controls.jump and not controls.sneak then
				is_engine_working = true
				level_acceleration=acceleration_module
			end
			if controls.sneak and not controls.jump then
				is_engine_working = true
				level_acceleration=-acceleration_module
			end
			if controls.up and not controls.down then
				is_engine_working = true
				forward_acceleration=acceleration_module
			end
			if controls.down and not controls.up then
				is_engine_working = true
				forward_acceleration=-acceleration_module
			end
			local acceleration={
				x=look_x*forward_acceleration+math.cos(look_horizontal)*side_acceleration+look_y*math.sin(look_horizontal)*level_acceleration,
				y=look_y*forward_acceleration+(look_x*look_x+look_z*look_z)*level_acceleration,
				z=look_z*forward_acceleration+math.sin(look_horizontal)*side_acceleration-look_y*math.cos(look_horizontal)*level_acceleration
			}
			self.object:setacceleration(acceleration)
		end
		local het = self.hit_effect_timer
		if het > 0 then
			self.hit_effect_timer = het - dtime
			if het - dtime <= 0 then
				player:hud_change(saturn.hud_attack_info_frame_id, "text", "null.png")
				player:hud_change(saturn.hud_attack_info_text_id, "text", "")
			else
				if self.last_attacker then
					if self.last_attacker:getpos() then
						local lahd = saturn.get_onscreen_coords_of_object(player, self.last_attacker)
						player:hud_change(saturn.hud_attack_info_frame_id, "position", lahd)
						player:hud_change(saturn.hud_attack_info_frame_id, "text", "saturn_arrows_and_frame.png^[verticalframe:9:"..lahd.frame)
						player:hud_change(saturn.hud_attack_info_text_id, "text", "Attack is detected!")
						local color = 0xFF0000
						if het % 0.5 - 0.25 < 0 then
							color = 0xFFAA00
						end
						player:hud_change(saturn.hud_attack_info_text_id, "number", color)
					end
				end
			end
		end
		local rol = self.radar_object_list
		if #rol > 0 then
			if saturn.radars[name] then
				for i=1,8 do
					local clear_hud = false
					local ro = rol[i]
					if ro then
					    local radar_range = saturn.radars[name].radius
					    if ro.x > pos.x - radar_range and
							ro.x < pos.x + radar_range and
							ro.y > pos.y - radar_range and
							ro.y < pos.y + radar_range and
							ro.z > pos.z - radar_range and
							ro.z < pos.z + radar_range then
						local ocodo = saturn.get_onscreen_coords_of_object(player, rol[i])
						if ocodo.frame == 0 then
							player:hud_change(saturn.hud_radar_shelf[i], "position", ocodo)
							player:hud_change(saturn.hud_radar_shelf[i], "text", "saturn_radar_mark.png")
							player:hud_change(saturn.hud_radar_text[i], "position", ocodo)
							player:hud_change(saturn.hud_radar_text[i], "text", string.format("%4.1f",vector.distance(pos,rol[i])/1000).."km")
						else 
							clear_hud = true
						end
					    else
						self.radar_object_state[ro] = nil
						table.remove(rol,i)
						clear_hud = true
					    end
					else
						clear_hud = true
					end
					if clear_hud then
						player:hud_change(saturn.hud_radar_shelf[i], "text", "null.png")
						player:hud_change(saturn.hud_radar_text[i], "text", "")
					end
				end
			else
				self.radar_object_list = {}
			end
		end
		if self.waypoint then
			local ocodo = saturn.get_onscreen_coords_of_object(player, self.waypoint)
			player:hud_change(saturn.hud_waypoint_shelf, "position", ocodo)
			player:hud_change(saturn.hud_waypoint_shelf, "text", "saturn_arrows_and_frame_blue.png^[verticalframe:10:"..ocodo.frame)
			player:hud_change(saturn.hud_waypoint_text, "position", ocodo)
			player:hud_change(saturn.hud_waypoint_text, "text", string.format("%4.1f",vector.distance(pos,self.waypoint)/1000).."km")
		end
		local one_second_timer = self.one_second_timer + dtime
		local inv = player:get_inventory()
		if one_second_timer > 1.0 then
			one_second_timer = one_second_timer - 1.0
	    		if is_engine_working and inv:get_size("engine") > 0 then
				for listpos,stack in pairs(inv:get_list("engine")) do
					if stack ~= nil then
						local stats = saturn.get_item_stats(stack:get_name())
						if stats then
							if stats['traction'] and stats['rated_power'] then
								stack:add_wear(saturn.MAX_ITEM_WEAR / stats['max_wear'])
								inv:set_stack("engine", listpos, stack)
							end
						end
					end
				end
			end
	    		if inv:get_size("power_generator") > 0 then
				for listpos,stack in pairs(inv:get_list("power_generator")) do
					if stack ~= nil then
						local stats = saturn.get_item_stats(stack:get_name())
						if stats then
							if stats['generated_power'] then
								stack:add_wear(saturn.MAX_ITEM_WEAR / stats['max_wear'])
								inv:set_stack("power_generator", listpos, stack)
							end
						end
					end
				end
			end
	    		if inv:get_size("radar") > 0 then
				for listpos,stack in pairs(inv:get_list("radar")) do
					if stack ~= nil then
						local stats = saturn.get_item_stats(stack:get_name())
						if stats then
							if stats['radar_range'] then
								stack:add_wear(saturn.MAX_ITEM_WEAR / stats['max_wear'])
								inv:set_stack("radar", listpos, stack)
							end
						end
					end
				end
			end
			local hull = inv:get_stack("ship_hull", 1)
			local hull_stats = saturn.get_item_stats(hull:get_name())
	    		if inv:get_size("droid") > 0 and self['free_power'] > 0 and hull:get_wear() > 0 then
				local droid_repair_rate = math.floor((self['droid_efficiency'] + (self.total_modificators['droid_efficiency'] or 0)) * saturn.MAX_ITEM_WEAR / hull_stats['max_wear'])
				if droid_repair_rate > 0 then
					hull:add_wear(-droid_repair_rate)
					inv:set_stack("ship_hull", 1, hull)
					saturn.refresh_health_hud(self.driver)
				end
				for listpos,stack in pairs(inv:get_list("droid")) do
					if stack ~= nil then
						local stats = saturn.get_item_stats(stack:get_name())
						if stats then
							if stats['droid_efficiency'] then
								stack:add_wear(saturn.MAX_ITEM_WEAR / stats['max_wear'])
								inv:set_stack("droid", listpos, stack)
							end
						end
					end
				end
			end
		end
		self.one_second_timer = one_second_timer
		if is_engine_working and self.engine_sound_handler == nil then
			local engine_sound_parameters = 
			{
			        object = self.object,
			        gain = 1.0, -- default
			        max_hear_distance = 0.5, -- default, uses an euclidean metric
			        loop = true, -- only sounds connected to objects can be looped
			}
			self.engine_sound_handler = minetest.sound_play("saturn_engine_work_loop", engine_sound_parameters)
		end
		if not is_engine_working and self.engine_sound_handler ~= nil then
			minetest.sound_stop(self.engine_sound_handler)
			self.engine_sound_handler = nil
		end
		player:hud_change(saturn.hud_relative_velocity_id, "text", "Relative to ring velocity: "..string.format ('%4.2f',velocity_module).." m/s")
		player:set_bone_position("Head", {x=0,y=1,z=0}, {x=-look_vertical*180/math.pi,y=0,z=-look_horizontal*180/math.pi})
		local node = minetest.env:get_node(pos)
		if self.lastpos.x~=nil then
			if node.name ~= "air" and node.name ~= "saturn:fog" and node.name ~= "ignore" then
				self.object:setpos(self.lastpos)
				self.object:setvelocity(vector.multiply(velocity, -0.1))
				saturn.punch_object(self.driver, self.object, velocity_module)
				minetest.sound_play("saturn_ship_collision", {to_player = name})
			else
				local node = minetest.env:get_node(vector.add(velocity,pos))
				if node.name ~= "air" and node.name ~= "saturn:fog" and node.name ~= "ignore" then
					self.object:setpos(self.lastpos)
					self.object:setvelocity(vector.multiply(velocity, -0.1))
					saturn.punch_object(self.driver, self.object, velocity_module)
					minetest.sound_play("saturn_ship_collision", {to_player = name})
				end
			end
		end
		self.lastpos={x=pos.x, y=pos.y, z=pos.z}
		if math.abs(pos.y) > saturn.player_pos_y_max_reached + 1 then
			saturn.player_ship_ref = self.object
			saturn.player_pos_y_max_reached = math.abs(pos.y)
		elseif pos.y < 1000 and self.object == saturn.player_ship_ref then
			saturn.player_ship_ref = nil
		end
	elseif self.driver_name and self.driver_name ~= "" then
		local player = minetest.get_player_by_name(self.driver_name)
		if player then
			attach_player_to_ship(player, self)
		end
	end
end

function spaceship:on_activate(staticdata, dtime_s)
	self.object:set_armor_groups({immortal=1})
	if staticdata then
		local data = minetest.deserialize(staticdata)
		if data then
			if data.driver_name then
				local name = data.driver_name
				self.driver_name = name
				self.is_escape_pod = data.is_escape_pod
				saturn.saturn_spaceships[name] = self.object
				local player = minetest.get_player_by_name(name)
				if player then
					attach_player_to_ship(player, self)
				end
			end
			if data.velocity then
				self.object:setvelocity(data.velocity)
			end
		end
	end
end

function spaceship:get_staticdata()
	return minetest.serialize({
		driver_name = self.driver_name,
		velocity = self.object:getvelocity(),
		is_escape_pod = self.is_escape_pod,
	})
end

function spaceship:on_punch(puncher, time_from_last_punch, tool_capabilities, dir)
	saturn.punch_object(self.driver, puncher, tool_capabilities.damage_groups.fleshy)
end

minetest.register_entity("saturn:spaceship", spaceship)

saturn.restore_missing_ship = function(player)
    if not player:get_attach() then
	create_new_player(player)
    end
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
        player:set_sky({r=0, g=0, b=0, a=0}, "skybox", skybox)
	minetest.hud_replace_builtin("health",hud_healthbar_definition)
	player:hud_add(hud_health_energy_bar_frame_definition)
        saturn.hud_healthbar_id = player:hud_add(hud_healthbar_definition)
	saturn.hud_energybar_filler_id = player:hud_add(hud_energybar_filler_definition)
        saturn.hud_energybar_id = player:hud_add(hud_energybar_definition)
        saturn.hud_relative_velocity_id = player:hud_add(hud_relative_velocity_definition)
	saturn.hud_attack_info_text_id = player:hud_add(hud_attack_info_text_definition)
	saturn.hud_attack_info_frame_id = player:hud_add(hud_attack_info_frame_definition)
	saturn.hud_hotbar_cooldown[name] = {}
	saturn.hotbar_cooldown[name] = {[1] = -1,[2] = -1,[3] = -1,[4] = -1,[5] = -1,[6] = -1,[7] = -1,[8] = -1}
	for i=1,8 do
		saturn.hud_hotbar_cooldown[name][i] = player:hud_add(hud_hotbar_cooldown[i])
	end
	for i=1,8 do
		saturn.hud_radar_shelf[i] = player:hud_add(hud_radar_shelf[i])
		saturn.hud_radar_text[i] = player:hud_add(hud_radar_text[i])
	end
	saturn.hud_waypoint_shelf = player:hud_add(hud_waypoint_shelf_definition)
	saturn.hud_waypoint_text = player:hud_add(hud_waypoint_text_definition)
	if saturn.players_info[name] == nil then
		create_new_player(player)
	end
	local flb_pos = saturn.players_info[name]['forceload_pos']
	if flb_pos then
		minetest.forceload_block(flb_pos)
	end
	minetest.after(10, saturn.restore_missing_ship, player)
end)

minetest.register_on_leaveplayer(function(player)
	saturn:save_players()
	local flb_pos = saturn.players_info[player:get_player_name()]['forceload_pos']
	if flb_pos then
		minetest.forceload_free_block(flb_pos)
	end
	if player:get_attach() and player:get_attach() == saturn.player_ship_ref then
		saturn.player_ship_ref = nil
	end
end)

if minetest.register_on_player_inventory_add_item then

   minetest.register_on_player_inventory_add_item(function(player, list_to, slot, stack)
    	if player:get_attach() then
	    local name = player:get_player_name()
	    local ship_lua = player:get_attach():get_luaentity()
	    local new_carried_weight = ship_lua['weight'] + saturn.get_item_weight(list_to, stack) * stack:get_count()
	    local new_carried_volume = ship_lua['volume'] + saturn.get_item_volume(list_to, stack) * stack:get_count()
	    local hull = player:get_inventory():get_stack("ship_hull", 1)
	    local hull_volume = ship_lua['free_space']
	    refresh_ship_equipment(player, list_to)
	    apply_cargo(player,new_carried_weight, new_carried_volume)
	    if list_to ~= "ship_hull" and new_carried_volume > hull_volume then
		minetest.sound_play("saturn_whoosh", {to_player = name})
		saturn.throw_item(stack, player:get_attach(), player:getpos())
		player:get_inventory():remove_item(list_to, stack)
	    end
    	end
    end)

    minetest.register_on_player_inventory_change_item(function(player, list_to, slot, old_item, new_item)
    	if player:get_attach() then
	    if old_item:get_name() ~= new_item:get_name() then
		local name = player:get_player_name()
		local ship_lua = player:get_attach():get_luaentity()
		local new_carried_weight = ship_lua['weight'] + saturn.get_item_weight(list_to, new_item) * new_item:get_count() - saturn.get_item_weight(list_to, old_item) * old_item:get_count()
		local hull_volume = ship_lua['free_space']
		local new_carried_volume = ship_lua['volume'] + saturn.get_item_volume(list_to, new_item) * new_item:get_count() - saturn.get_item_volume(list_to, old_item) * old_item:get_count()
		refresh_ship_equipment(player, list_to)
		apply_cargo(player,new_carried_weight, new_carried_volume)
		if list_to ~= "ship_hull" and new_carried_volume > hull_volume then
			saturn.throw_item(new_item, player:get_attach(), player:getpos())
			player:get_inventory():remove_item(list_to, new_item)
		end
	    end
    	end
    end)

    minetest.register_on_player_inventory_remove_item(function(player, list_from, stack)
    	if player:get_attach() then
	    local name = player:get_player_name()
	    local ship_lua = player:get_attach():get_luaentity()
	    local new_carried_weight = ship_lua['weight'] - saturn.get_item_weight(list_from, stack) * stack:get_count()
	    local new_carried_volume = ship_lua['volume'] - saturn.get_item_volume(list_from, stack) * stack:get_count()
	    refresh_ship_equipment(player, list_from)
	    apply_cargo(player,new_carried_weight, new_carried_volume)
	end
    end)

end
-- The hand
minetest.register_item(":", {
	type = "none",
	wield_image = "null.png",
	wield_scale = {x=1,y=1,z=1},
	tool_capabilities = {
		full_punch_interval = 0,
		max_drop_level = 0,
		groupcaps = {},
		damage_groups = {},
	}
})
