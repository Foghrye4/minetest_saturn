saturn.max_loot_level = 10

local default_enemy_item_possible_modifications = {
		weight = {-10,10}, -- Given values define a scale of pseudogaussian random value
		volume = {-1,1},
		traction = {-1000,1000},
		rated_power = {-10,10},
		damage = {-1,1},
		cooldown = {-0.1,0.1},
		generated_power = {-10,10},
		forcefield_protection = {-0.1,0.1},
		droid_efficiency = {-0.1,0.1},
	}

local default_enemy_generator_item_possible_modifications = {
		weight = {-10,10},
		volume = {-1,1},
		traction = {-1000,1000},
		damage = {-1,1},
		cooldown = {-0.1,0.1},
		generated_power = {-10,10},
		forcefield_protection = {-0.1,0.1},
		droid_efficiency = {-0.1,0.1},
	}


local default_enemy_weapon_item_possible_modifications = {
		weight = {-10,10},
		volume = {-1,1},
		rated_power = {-10,10},
		damage = {-10,10},
		cooldown = {-0.1,0.1},
	}

local function register_wearable_item(registry_name, def)
        def.wield_image = "null.png"
        def.stack_max = 1
	def.on_drop = function(itemstack, player, pos)
		minetest.sound_play("saturn_item_drop", {to_player = player:get_player_name()})
		saturn.throw_item(itemstack, player, pos)
		itemstack:clear()
		return itemstack
	end
	minetest.register_tool(registry_name, def)
	if def.is_market_item then
		table.insert(saturn.market_items,registry_name)
	end
	if def.is_enemy_item then
		table.insert(saturn.enemy_items,registry_name)
		for level = def.loot_level,saturn.max_loot_level do
			if not saturn.enemy_items_by_level[level] then
				saturn.enemy_items_by_level[level] = {}
			end
			table.insert(saturn.enemy_items_by_level[level],registry_name)
		end
	end
end

-- Hulls

register_wearable_item("saturn:basic_ship_hull",{
		description = "Basic ship hull",
		inventory_image = "saturn_basic_ship_hull.png",
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 40000,
	volume = 400,
	free_space = 100,
	price = 300,
	max_wear = 100, -- out of 65535
	engine_slots = 2,
	power_generator_slots = 1,
	droid_slots = 0,
	radar_slots = 0,
	forcefield_generator_slots = 0,
	special_equipment_slots = 0,
	is_market_item = true,
	player_visual = {
		mesh = "basic_ship.b3d",
		textures = {"basic_ship.png", "basic_ship.png", "basic_ship.png", "basic_ship.png"},
		visual = "mesh",
		visual_size = {x=10, y=10},
	},
	equipment_slot = "ship_hull",
})

register_wearable_item("saturn:basic_ship_hull_me",{
		description = "Basic ship hull military edition",
		inventory_image = "saturn_basic_ship_hull_me.png",
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 60000,
	volume = 800,
	free_space = 200,
	price = 8000,
	max_wear = 400, -- out of 65535
	engine_slots = 2,
	power_generator_slots = 1,
	droid_slots = 0,
	radar_slots = 1,
	forcefield_generator_slots = 1,
	special_equipment_slots = 0,
	is_market_item = true,
	player_visual = {
		mesh = "basic_ship.b3d",
		textures = {"basic_ship_military_edition.png", "basic_ship_military_edition.png", "basic_hull_military_edition.png", "basic_hull_military_edition.png"},
		visual = "mesh",
		visual_size = {x=10, y=10},
	},
	equipment_slot = "ship_hull",
})

register_wearable_item("saturn:overkiller_hull",{
		description = "Overkiller hull",
		inventory_image = "saturn_overkiller_hull.png",
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 1200000,
	volume = 8000,
	free_space = 2000,
	price = 2000000,
	max_wear = 65535, -- out of 65535
	engine_slots = 8,
	power_generator_slots = 4,
	droid_slots = 4,
	radar_slots = 1,
	forcefield_generator_slots = 1,
	special_equipment_slots = 4,
	is_market_item = true,
	player_visual = {
		mesh = "saturn_overkiller_ship.b3d",
		textures = {"saturn_overkiller_ship.png"},
		visual = "mesh",
		visual_size = {x=10, y=10},
	},
	equipment_slot = "ship_hull",
})

register_wearable_item("saturn:escape_pod",{
		description = "Escape pod",
		inventory_image = "saturn_escape_pod.png",
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 1000,
	volume = 0,
	free_space = 0,
	price = 0,
	max_wear = 65535, -- out of 65535
	engine_slots = 0,
	power_generator_slots = 0,
	droid_slots = 0,
	radar_slots = 0,
	forcefield_generator_slots = 0,
	special_equipment_slots = 0,
	player_visual = {
		mesh = "escape_pod.b3d",
		textures = {"basic_ship.png"},
		visual = "mesh",
		visual_size = {x=10, y=10},
	},
	equipment_slot = "ship_hull",
})

-- Retractors
local retractor_on_use = function(stack, player, pointed_thing)
	local return_value = true -- can use secondary
	local stats = saturn.get_item_stats(stack:get_name())
	local max_wear = stats['max_wear']
	local rated_power = stats['rated_power']
	local metadata = minetest.deserialize(stack:get_metadata())
	if metadata then
		if metadata['rated_power'] then
			rated_power = rated_power + metadata['rated_power']
		end
	end
	local ship_obj = player:get_attach()
	if ship_obj then
		local ship_lua = ship_obj:get_luaentity()
		if ship_lua['free_power'] - ship_lua['recharging_equipment_power_consumption'] >= rated_power then
		    local time_of_last_shoot = 0
		    local cooldown = stats['cooldown']
		    local action_range = stats['action_range']
		    if metadata then
			if metadata['time_of_last_shoot'] then
			    time_of_last_shoot = metadata['time_of_last_shoot']
			end
			if metadata['cooldown'] then
			    cooldown = cooldown + metadata['cooldown']
			end
			if metadata['action_range'] then
			    action_range = action_range + metadata['action_range']
			end
		    else
			metadata = {}
		    end
		    if ship_lua.total_modificators['cooldown'] then
			cooldown = math.max(cooldown + ship_lua.total_modificators['cooldown'], 0.05) -- cannot be zero
		    end
		    local current_time = minetest.get_gametime()
		    local timediff = current_time - time_of_last_shoot
		    if timediff >= cooldown then
			if ship_lua.total_modificators['action_range'] then
			    damage = damage + ship_lua.total_modificators['action_range']
			end
			local name = player:get_player_name()
			local search_area = action_range
			local p_pos = player:getpos()
			p_pos.y = p_pos.y + 1.6
			local player_look_vec = vector.multiply(player:get_look_dir(),search_area)
			local abs_player_look = vector.add(p_pos,player_look_vec)
			local objs = minetest.env:get_objects_inside_radius(abs_player_look, search_area)
			local shoot_miss = true
			for k, obj in pairs(objs) do
			    local lua_entity = obj:get_luaentity()
			    if lua_entity then
				if lua_entity.name == "saturn:throwable_item_entity" then
				    local threshold = 0.75
				    local object_pos = obj:getpos()
				    local player_look_to_obj = vector.multiply(player:get_look_dir(),vector.length(vector.subtract(object_pos,p_pos)))		
				    local target_pos = vector.add(p_pos,player_look_to_obj)
				    if math.abs(object_pos.x-target_pos.x)<threshold and  
				    math.abs(object_pos.y-target_pos.y)<threshold and
				    math.abs(object_pos.z-target_pos.z)<threshold then
					shoot_miss = false
					local is_clear, node_pos = minetest.line_of_sight(p_pos, object_pos, 2)
					if is_clear then 
						local inv = player:get_inventory()
						if inv and lua_entity.itemstring ~= '' then
							inv:add_item("main", lua_entity.itemstring)
							stack:add_wear(saturn.MAX_ITEM_WEAR / max_wear)
						end
						lua_entity.itemstring = ''
						obj:remove()
						minetest.sound_play({name="saturn_retractor", gain=0.5}, {to_player = name})
						return_value = false
					else
						object_pos = vector.subtract(node_pos, player:get_look_dir())
						local node_info = minetest.get_node(node_pos)
						if node_info.name == "saturn:fog" then
							minetest.remove_node(node_pos)
						end
					end
					minetest.add_particle({
						pos = object_pos,
						velocity = {x=0, y=0, z=0},
						acceleration = {x=0, y=0, z=0},
						expirationtime = 1.0,
						size = 16,
						collisiondetection = false,
						vertical = false,
						texture = "saturn_green_halo.png"
					})
				    end
				end
			    end
			end
			if shoot_miss then
				local is_clear, node_pos = minetest.line_of_sight(p_pos, abs_player_look, 1)
				if not is_clear then 
					local player_look_to_obj = vector.multiply(player:get_look_dir(),vector.length(vector.subtract(node_pos,p_pos)))		
					local target_pos = vector.add(p_pos,player_look_to_obj)
					local object_pos = vector.subtract(target_pos, player:get_look_dir())
					minetest.add_particle({
						pos = object_pos,
						velocity = {x=0, y=0, z=0},
						acceleration = {x=0, y=0, z=0},
						expirationtime = 1.0,
						size = 16,
						collisiondetection = false,
						vertical = false,
						texture = "saturn_green_halo.png"
					})
					local node_info = minetest.get_node(node_pos)
					if node_info.name == "saturn:fog" then
						minetest.remove_node(node_pos)
					end
				end
			end
			metadata['time_of_last_shoot'] = current_time
			stack:set_metadata(minetest.serialize(metadata))
			stack:add_wear(saturn.MAX_ITEM_WEAR / max_wear)
			saturn.hotbar_cooldown[name][player:get_wield_index()] = cooldown
			ship_lua['recharging_equipment_power_consumption'] = ship_lua['recharging_equipment_power_consumption'] + rated_power
			saturn.refresh_energy_hud(ship_lua.driver)
			minetest.after(cooldown, saturn.release_delayed_power_and_try_to_shoot_again, ship_lua, rated_power, player:get_wield_index())
		    else
			return_value = false
		    end
		else
			minetest.chat_send_player(player:get_player_name(), "Not enought free power to use this retractor!")
			return_value = false
		end
	return return_value
	end
end


local retractor_on_secondary_use = function(stack, player, pointed_thing)
	local stats = saturn.get_item_stats(stack:get_name())
	local max_wear = stats['max_wear']
	local rated_power = stats['rated_power']
	if player:get_attach() then
		local ship_lua = player:get_attach():get_luaentity()
		if ship_lua['free_power'] >= rated_power then
			local objs = minetest.env:get_objects_inside_radius(vector.add(player:getpos(),player:get_look_dir()), 4)
			for k, obj in pairs(objs) do
				local lua_entity = obj:get_luaentity()
				if lua_entity then
					if lua_entity.name == "saturn:throwable_item_entity" then
						local inv = player:get_inventory()
						if inv and lua_entity.itemstring ~= '' then
							inv:add_item("main", lua_entity.itemstring)
							stack:add_wear(saturn.MAX_ITEM_WEAR / max_wear)
						end
						lua_entity.itemstring = ''
						obj:remove()
						minetest.sound_play({name="saturn_retractor", gain=0.5}, {to_player = name})
					end
				end
			end
		else
			minetest.chat_send_player(player:get_player_name(), "Not enought free power to use this retractor!")
		end
	return stack
	end
end

register_wearable_item("saturn:basic_retractor",{
		description = "Basic retractor",
		inventory_image = "saturn_basic_retractor.png",
	        range = 4.0,
		tool_capabilities = {
	            full_punch_interval = 1.0,
	            max_drop_level=0,
	            groupcaps={
	                cracky={times={[1]=3.00, [2]=2.00, [3]=1.30}, uses=2000, maxlevel=1},
	            },
    		},
		on_secondary_use = function(stack, player, pointed_thing)
			if retractor_on_use(stack, player, pointed_thing) then
				return retractor_on_secondary_use(stack, player, pointed_thing)
			else
				return stack
			end
		end,
	weight = 400,
	volume = 1,
	price = 100,
	cooldown = 0.5,
	action_range = 16,
	max_wear = 2000, -- out of 65535
	rated_power = 1, -- MW, megawatts
	is_market_item = true,
})

register_wearable_item("saturn:retractor_scr2",{
		description = "Retractor SCR-2",
		inventory_image = "saturn_retractor_scr2.png",
	        range = 4.0,
		tool_capabilities = {
	            full_punch_interval = 1.0,
	            max_drop_level=0,
	            groupcaps={
	                cracky={times={[1]=1.50, [2]=1.00, [3]=0.60}, uses=2000, maxlevel=1},
	            },
    		},
		on_secondary_use = function(stack, player, pointed_thing)
			if retractor_on_use(stack, player, pointed_thing) then
				return retractor_on_secondary_use(stack, player, pointed_thing)
			else
				return stack
			end
		end,
	weight = 800,
	volume = 1.5,
	price = 200,
	cooldown = 0.5,
	action_range = 32,
	max_wear = 2000, -- out of 65535
	rated_power = 2, -- MW, megawatts
	is_market_item = true,
})

-- Engines

register_wearable_item("saturn:ionic_engine",{
		description = "Ionic engine",
		inventory_image = "saturn_ionic_engine.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 400,
	volume = 4,
	price = 100,
	traction = 80000,
	max_wear = 50000, -- out of 65535
	rated_power = 4, -- MW, megawatts
	is_market_item = true,
	equipment_slot = "engine",
})

register_wearable_item("saturn:gravitational_engine",{
		description = "Gravitational engine",
		inventory_image = "saturn_gravitational_engine.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 400,
	volume = 4,
	price = 10000,
	traction = 800000,
	max_wear = 50000, -- out of 65535
	rated_power = 4, -- MW, megawatts
	is_market_item = true,
	equipment_slot = "engine",
})

register_wearable_item("saturn:enemy_engine",{
		description = "Enemy engine",
		inventory_image = "saturn_enemy_engine.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 440,
	volume = 5,
	price = 1000,
	traction = 81000,
	max_wear = 40000, -- out of 65535
	rated_power = 4, -- MW, megawatts
	is_enemy_item = true,
	possible_modifications = default_enemy_item_possible_modifications,
	loot_level = 1,
	equipment_slot = "engine",
})

-- Droids

register_wearable_item("saturn:basic_droid",{
		description = "Basic droid",
		inventory_image = "saturn_basic_droid.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 440,
	volume = 5,
	price = 1000,
	droid_efficiency = 1,
	max_wear = 2000, -- out of 65535
	rated_power = 4, -- MW, megawatts
	is_market_item = true,
	equipment_slot = "droid",
})

-- Radars

register_wearable_item("saturn:short_range_radar",{
		description = "Short range radar",
		inventory_image = "saturn_short_range_radar.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 400,
	volume = 4,
	price = 100,
	radar_range = 1000,
	max_wear = 20000, -- out of 65535
	rated_power = 4, -- MW, megawatts
	is_market_item = true,
	equipment_slot = "radar",
})

-- Power generators

register_wearable_item("saturn:mmfnr", {
	description = "Miniature maintenance free reactor",
	inventory_image = "saturn_mmfnr.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 2000, -- 1000 kg
	volume = 10, -- 1000 cubic meter
	generated_power = 6,
	max_wear = 60000,
	price = 100,
	is_market_item = true,
	equipment_slot = "power_generator",
})

register_wearable_item("saturn:mmfnr2", {
	description = "Miniature maintenance free reactor MMFNR2",
	inventory_image = "saturn_mmfnr2.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 7800, -- 1000 kg
	volume = 38, -- 1000 cubic meter
	generated_power = 24,
	max_wear = 60000,
	price = 1600,
	is_market_item = true,
	equipment_slot = "power_generator",
})

register_wearable_item("saturn:enemy_power_generator", {
	description = "Enemy power generator",
	inventory_image = "saturn_enemy_power_generator.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 7000,
	volume = 50,
	generated_power = 20,
	max_wear = 60000,
	price = 10000,
	is_enemy_item = true,
	possible_modifications = default_enemy_generator_item_possible_modifications,
	loot_level = 1,
	equipment_slot = "power_generator",
})

-- Forcefield generators

register_wearable_item("saturn:forcefield_generator", {
	description = "Forcefield generator",
	inventory_image = "saturn_forcefield_generator.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 7000,
	volume = 10,
	rated_power = 8,
	forcefield_protection = 3.0,
	max_wear = 2000,
	price = 1000,
	is_market_item = true,
	equipment_slot = "forcefield_generator",
})

register_wearable_item("saturn:enemy_forcefield_generator", {
	description = "Enemy forcefield generator",
	inventory_image = "saturn_enemy_forcefield_generator.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
	weight = 8500,
	volume = 12,
	rated_power = 10,
	forcefield_protection = 2.7,
	max_wear = 2000,
	price = 8000,
	is_enemy_item = true,
	possible_modifications = default_enemy_item_possible_modifications,
	loot_level = 2,
	equipment_slot = "forcefield_generator",
})

-- Weapons

local entity_queue_effect = {
	physical = false,
	collisionbox = {0,0,0,0,0,0},
	textures = {"saturn_incandescent_gradient.png"},
	visual = "mesh",
	mesh = "saturn_ray.b3d",
	visual_size = {x=1, y=1},
	age = 0,
	is_visible = true,
}

function entity_queue_effect:on_step(dtime)
	self.age = self.age + dtime
	if self.age > 0.4 then
		self.object:remove()
		return
	end
end

minetest.register_entity("saturn:entity_queue_effect", entity_queue_effect)

local getVectorPitchAngle = saturn.get_vector_pitch_angle
local getVectorYawAngle = saturn.get_vector_yaw_angle

local is_correct_ammo_type = function(stack, ammo_type)
	if stack then
		local stats = saturn.get_item_stats(stack:get_name())
		if stats and stats[ammo_type] then
			return true
		end
	end
	return false
end

local weapon_on_use = function(stack, player, pointed_thing)
	local stop_sound = true
	local stats = saturn.get_item_stats(stack:get_name())
	local max_wear = stats['max_wear']
	local rated_power = stats['rated_power']
	local metadata = minetest.deserialize(stack:get_metadata())
	if metadata then
		if metadata['rated_power'] then
			rated_power = rated_power + metadata['rated_power']
		end
	end
	local ship_obj = player:get_attach()
	if ship_obj then
	    local ship_lua = ship_obj:get_luaentity()
	    if ship_lua['free_power'] - ship_lua['recharging_equipment_power_consumption'] >= rated_power then
		local ammo_ok = true
		local ammo_type = stats['use_ammo_type']
		local use_ammo_amount = 1
		local ammo_itemstack = nil
		if ammo_type then
		    ammo_ok = false
		    local ammo_amount = stats['use_ammo_amount']
		    local ammo_slot = 1
		    use_ammo_amount = ammo_amount
		    if metadata and metadata['last_ammo_slot'] then
		    	ammo_slot = metadata['last_ammo_slot']
		    end
		    local main_list = player:get_inventory():get_list("main")
		    if is_correct_ammo_type(main_list[ammo_slot], ammo_type) then
			ammo_ok = true
		    else
			for i=ammo_slot+1, #main_list do
			    if is_correct_ammo_type(main_list[i], ammo_type) then
				ammo_slot = i
				ammo_ok = true
			    else
				for i=1, ammo_slot-1 do
				    if is_correct_ammo_type(main_list[i], ammo_type) then
					ammo_slot = i
					ammo_ok = true
				    end
				end
			    end
			end
		    end
		    if ammo_ok then
			local _ammo_itemstack = main_list[ammo_slot]
			ammo_itemstack = _ammo_itemstack:take_item(ammo_amount)
			use_ammo_amount = ammo_itemstack:get_count()
			player:get_inventory():set_stack("main", ammo_slot, _ammo_itemstack)
			if metadata then
			    metadata['last_ammo_slot'] = ammo_slot
			end
		    end
		end
		if ammo_ok then
		    local time_of_last_shoot = 0
		    local cooldown = stats['cooldown']
		    local damage = stats['damage']
		    if metadata then
			if metadata['time_of_last_shoot'] then
			    time_of_last_shoot = metadata['time_of_last_shoot']
			end
			if metadata['cooldown'] then
			    cooldown = cooldown + metadata['cooldown']
			end
			if metadata['damage'] then
			    damage = damage + metadata['damage']
			end
		    else
			metadata = {}
		    end
		    if ship_lua.total_modificators['cooldown'] then
			cooldown = math.max(cooldown + ship_lua.total_modificators['cooldown'], 0.2) -- cannot be zero
		    end
		    local current_time = minetest.get_gametime()
		    if current_time - time_of_last_shoot >= cooldown or ship_lua['ignore_cooldown'] then
			local p_pos = player:getpos()
			p_pos.y = p_pos.y + 1.6
			local p_look = player:get_look_dir()
			local search_area = 64
			local player_look_vec = vector.multiply(p_look,search_area)
--[[ Too laggy		if ammo_type then
			    local ship_v = ship_obj:getvelocity()
			    local entity_queue_effect_obj = minetest.add_entity(p_pos, "saturn:entity_queue_effect")
			    local yaw = -getVectorYawAngle(p_look)
			    local pitch = -getVectorPitchAngle(p_look)
			    entity_queue_effect_obj:set_bone_position("Head", {x=0,y=1,z=0}, {x=player:get_look_pitch()*180/3.14159,y=0,z=90-player:get_look_yaw()*180/3.14159})
			    entity_queue_effect_obj:setvelocity({x=p_look.x*128+ship_v.x,y=p_look.y*128+ship_v.y,z=p_look.z*128+ship_v.z})
			end]]
			ship_lua['ignore_cooldown'] = false
			if ship_lua.total_modificators['damage'] then
			    damage = damage + ship_lua.total_modificators['damage']
			end
			if ammo_type then
				damage = damage * use_ammo_amount * saturn.get_item_stat(ammo_itemstack, "damage_modificator", 1.0)
			end
			local name = player:get_player_name()
			local abs_player_look = vector.add(p_pos,player_look_vec)
			local objs = minetest.env:get_objects_inside_radius(abs_player_look, search_area)
			local shoot_miss = true
			for k, obj in pairs(objs) do
			    local lua_entity = obj:get_luaentity()
			    if lua_entity and lua_entity.physical then
				if lua_entity.name ~= "saturn:spaceship" or lua_entity.driver ~= player then
				    local threshold = 0.75
				    local object_pos = obj:getpos()
				    local player_look_to_obj = vector.multiply(player:get_look_dir(),vector.length(vector.subtract(object_pos,p_pos)))		
				    local target_pos = vector.add(p_pos,player_look_to_obj)
				    if math.abs(object_pos.x-target_pos.x)<threshold and  
				    math.abs(object_pos.y-target_pos.y)<threshold and
				    math.abs(object_pos.z-target_pos.z)<threshold then
					shoot_miss = false
					local is_clear, node_pos = minetest.line_of_sight(p_pos, object_pos, 2)
					if is_clear then 
						saturn.punch_object(obj, player, damage)
					else
						object_pos = vector.subtract(node_pos, player:get_look_dir())
						local node_info = minetest.get_node(node_pos)
						if node_info.name == "saturn:fog" then
							minetest.remove_node(node_pos)
							local is_clear, node_pos = minetest.line_of_sight(object_pos, node_pos, 2)
							if is_clear then
								saturn.punch_object(obj, player, damage)
							else
								if node_info.name == "saturn:fog" then
									minetest.remove_node(node_pos)
									saturn.punch_object(obj, player, damage)
								end
							end
						end
					end
					stats.create_hit_effect(0.2, 1, target_pos)
				    end
				end
			    end
			end
			if shoot_miss then
				local is_clear, node_pos = minetest.line_of_sight(p_pos, abs_player_look, 1)
				if not is_clear then 
					local player_look_to_obj = vector.multiply(player:get_look_dir(),vector.length(vector.subtract(node_pos,p_pos)))		
					local target_pos = vector.add(p_pos,player_look_to_obj)
					local object_pos = vector.subtract(target_pos, player:get_look_dir())
					stats.create_hit_effect(0.2, 1, object_pos)
					local node_info = minetest.get_node(node_pos)
					local node_stats = saturn.get_item_stats(node_info.name)
					if not minetest.is_protected(node_pos) and node_stats.toughness and node_stats.toughness < damage then
						minetest.remove_node(node_pos)
						saturn.create_node_explosion_effect(node_pos, node_info.name)
					end
				end
			end
			metadata['time_of_last_shoot'] = current_time
			stack:set_metadata(minetest.serialize(metadata))
			stack:add_wear(saturn.MAX_ITEM_WEAR / max_wear)
			saturn.hotbar_cooldown[name][player:get_wield_index()] = cooldown
			if cooldown < 0.3 and stats.sound_spec_loop then
				local sound_spec = stats.sound_spec_loop
				sound_spec.object = ship_obj
				if not ship_lua['weapon_sound_handler'] then
					ship_lua['weapon_sound_handler'] = minetest.sound_play(sound_spec.name,sound_spec)
				end
			else
				minetest.sound_play(stats.sound_spec_single_shot,{to_player=player:get_player_name()})
			end
			ship_lua['recharging_equipment_power_consumption'] = ship_lua['recharging_equipment_power_consumption'] + rated_power
			saturn.refresh_energy_hud(ship_lua.driver)
			minetest.after(cooldown, saturn.release_delayed_power_and_try_to_shoot_again, ship_lua, rated_power, player:get_wield_index())
			stop_sound = false
		    end
		else
		    minetest.chat_send_player(player:get_player_name(), "Not enought ammo to use this weapon!")
		end
	    else
		minetest.chat_send_player(player:get_player_name(), "Not enought free power to use this weapon!")
	    end
	if stop_sound and ship_lua['weapon_sound_handler'] then
		minetest.sound_stop(ship_lua['weapon_sound_handler'])
		ship_lua['weapon_sound_handler'] = nil
	end
	return stack
	end
end

register_wearable_item("saturn:cdbcemw",{
		description = "Carbon dioxide based coherent electromagnetic wave emitter",
		inventory_image = "saturn_cdbcemw.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
		on_use = weapon_on_use,
	weight = 400,
	damage = 25,
	cooldown = 1.5, -- seconds
	volume = 2.5,
	price = 200,
	max_wear = 2000, -- out of 65535
	rated_power = 6, -- MW, megawatts
	is_market_item = true,
	sound_spec_single_shot = {name="saturn_plasm_accelerator", gain=0.5},
	create_hit_effect = saturn.create_hit_effect,
})

register_wearable_item("saturn:uhv_railgun",{
		description = "Ultra high velocity railgun",
		inventory_image = "saturn_uhv_railgun.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
		on_use = weapon_on_use,
	weight = 4000,
	damage = 2500,
	cooldown = 50, -- seconds
	use_ammo_type = "railgun_ammo",
	use_ammo_amount = 1,
	volume = 25,
	price = 200000,
	max_wear = 500, -- out of 65535
	rated_power = 120, -- MW, megawatts
	is_market_item = true,
	sound_spec_single_shot = {name="saturn_railgun_shot", gain=0.5},
	create_hit_effect = saturn.create_railgun_hit_effect,
})

register_wearable_item("saturn:enemy_particle_emitter",{
		description = "Enemy particle emitter",
		inventory_image = "saturn_enemy_particle_emitter.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		        groupcaps = {},
    		},
		on_use = weapon_on_use,
	weight = 500,
	damage = 27,
	cooldown = 1.5, -- seconds
	volume = 3.5,
	price = 2000,
	max_wear = 2000, -- out of 65535
	rated_power = 6, -- MW, megawatts
	is_enemy_item = true,
	possible_modifications = default_enemy_weapon_item_possible_modifications,
	sound_spec_single_shot = {name="saturn_plasm_accelerator", gain=0.5},
	create_hit_effect = saturn.create_hit_effect,
	loot_level = 1,
})

register_wearable_item("saturn:gauss_mg",{
		description = "Gauss MG",
		inventory_image = "saturn_gauss_mg.png",
	        range = 0.0,
		tool_capabilities = {
		        max_drop_level = 0,
		            groupcaps={
		                cracky={maxlevel=3},
		            },
    		},
		on_use = weapon_on_use,
	weight = 1200,
	damage = 5, -- per "use_ammo_amount" ammo
	use_ammo_type = "gauss_ammo",
	use_ammo_amount = 2,
	cooldown = 0.2, -- seconds
	volume = 10,
	price = 8000,
	max_wear = 4000, -- out of 65535
	rated_power = 12, -- MW, megawatts
	is_market_item = true,
	sound_spec_loop = {name="saturn_gauss_mg_shot", gain=1.0, max_hear_distance = 0.5, loop=true},
	sound_spec_single_shot = {name="saturn_gauss_mg_shot_single", gain=1.0, max_hear_distance = 0.5},
	create_hit_effect = saturn.create_gauss_hit_effect,
})

minetest.register_chatcommand("give_enemy_item", {
	params = "",
	description = "Give to me random enemy item",
	privs = {give = true},
	func = function(name, param)
		local itemstack = saturn.generate_random_enemy_item()
		local leftover = minetest.get_player_by_name(name):get_inventory():add_item("main", itemstack)
		local partiality
		if leftover:is_empty() then
			partiality = ""
		elseif leftover:get_count() == itemstack:get_count() then
			partiality = "could not be "
		else
			partiality = "partially "
		end
		local stackstring = itemstack:to_string()
		return true, ("%q %sadded to inventory.")
			:format(stackstring, partiality)
	end,
})

-- Craft items

local function register_craft_item(registry_name, def)
        def.wield_image = "null.png"
	def.on_drop = function(itemstack, player, pos)
		minetest.sound_play("saturn_item_drop", {to_player = player:get_player_name()})
		saturn.throw_item(itemstack, player, pos)
		itemstack:clear()
		return itemstack
	end
	minetest.register_craftitem(registry_name, def)
	if def.is_market_item then
		table.insert(saturn.market_items,registry_name)
	end
	if def.is_enemy_item then
		table.insert(saturn.enemy_items,registry_name)
	end
	if def.is_ore then
		table.insert(saturn.ore_market_items, registry_name)
	end
end

-- Enemy non-wearable items

register_craft_item("saturn:enemy_hull_shard_a",{
		description = "Enemy hull shard A",
		inventory_image = "saturn_enemy_hull_shards.png^[verticalframe:4:1",
	weight = 400,
	volume = 10,
	price = 100,
	is_enemy_item = true,
	loot_level = 1,
})

register_craft_item("saturn:enemy_hull_shard_b",{
		description = "Enemy hull shard B",
		inventory_image = "saturn_enemy_hull_shards.png^[verticalframe:4:2",
	weight = 500,
	volume = 10,
	price = 120,
	is_enemy_item = true,
	loot_level = 1,
})

register_craft_item("saturn:enemy_hull_shard_c",{
		description = "Enemy hull shard C",
		inventory_image = "saturn_enemy_hull_shards.png^[verticalframe:4:3",
	weight = 400,
	volume = 10,
	price = 100,
	is_enemy_item = true,
	loot_level = 1,
})

register_craft_item("saturn:enemy_hull_shard_d",{
		description = "Enemy hull shard D",
		inventory_image = "saturn_enemy_hull_shards.png^[verticalframe:4:4",
	weight = 400,
	volume = 10,
	price = 100,
	is_enemy_item = true,
	loot_level = 1,
})

-- Ammo

register_craft_item("saturn:gauss_solid_ironnickel_bullets",{
		description = "Gauss solid ironnickel bullets",
		inventory_image = "saturn_gauss_solid_ironnickel_bullets.png",
		stack_max = 999,
	weight = 10,
	volume = 0.0001,
	price = 1,
	is_market_item = true,
	gauss_ammo = true,
	damage_modificator = 1.0,
})

register_craft_item("saturn:gauss_mo_permalloy_with_depleted_uranium_core_bullets",{
		description = "Gauss Mo-permalloy with depleted uranium core bullets",
		inventory_image = "saturn_gauss_mo_permalloy_with_depleted_uranium_core_bullets.png",
		stack_max = 999,
	weight = 11,
	volume = 0.0001,
	price = 2.25,
	is_market_item = true,
	gauss_ammo = true,
	damage_modificator = 1.5,
})

register_craft_item("saturn:railgun_aluminium_uhmwpe_ammo",{
		description = "Railgun UHMWPE bullets with aluminium conductive part",
		inventory_image = "saturn_railgun_aluminium_uhmwpe_ammo.png",
		stack_max = 999,
	weight = 4,
	volume = 0.0001,
	price = 1,
	is_market_item = true,
	railgun_ammo = true,
	damage_modificator = 1.0,
})

-- Misc.

register_craft_item("saturn:mail_package",{
		description = "Mail package",
		inventory_image = "saturn_mail_package.png",
		stack_max = 1,
	weight = 100,
	volume = 0.5,
	price = 0,
})

-- Resources

register_craft_item("saturn:clean_water",{
		description = "Clean water",
		inventory_image = "saturn_cells.png^[verticalframe:64:1",
	weight = 10,
	volume = 0.01,
	price = 0.2,
	is_ore = true,
})

register_craft_item("saturn:heavy_water",{
		description = "Heavy water",
		inventory_image = "saturn_cells.png^[verticalframe:64:2",
	weight = 10,
	volume = 0.01,
	price = 1,
	is_ore = true,
})

register_craft_item("saturn:silicate_mix",{
		description = "Silicate mix",
		inventory_image = "saturn_cells.png^[verticalframe:64:3",
	weight = 10,
	volume = 0.01,
	price = 0.1,
	is_ore = true,
})

register_craft_item("saturn:ammonia",{
		description = "Ammonia",
		inventory_image = "saturn_cells.png^[verticalframe:64:4",
	weight = 10,
	volume = 0.01,
	price = 0.5,
	is_ore = true,
})

register_craft_item("saturn:acetic_acid",{
		description = "Acetic acid",
		inventory_image = "saturn_cells.png^[verticalframe:64:5",
	weight = 10,
	volume = 0.01,
	price = 0.1,
	is_ore = true,
})

register_craft_item("saturn:formic_acid",{
		description = "Formic acid",
		inventory_image = "saturn_cells.png^[verticalframe:64:6",
	weight = 10,
	volume = 0.01,
	price = 0.1,
	is_ore = true,
})

register_craft_item("saturn:amorphous_carbon",{
		description = "Amorphous carbon",
		inventory_image = "saturn_cells.png^[verticalframe:64:7",
	weight = 10,
	volume = 0.01,
	price = 0.1,
	is_ore = true,
})

register_craft_item("saturn:carbon_dioxide",{
		description = "Carbon dioxide",
		inventory_image = "saturn_cells.png^[verticalframe:64:8",
	weight = 10,
	volume = 0.01,
	price = 0.5,
	is_ore = true,
})

register_craft_item("saturn:phosphine",{
		description = "Phosphine",
		inventory_image = "saturn_cells.png^[verticalframe:64:9",
	weight = 10,
	volume = 0.01,
	price = 1.5,
	is_ore = true,
})

register_craft_item("saturn:orthophosphoric_acid",{
		description = "Orthophosphoric acid",
		inventory_image = "saturn_cells.png^[verticalframe:64:10",
	weight = 10,
	volume = 0.01,
	price = 3,
	is_ore = true,
})

register_craft_item("saturn:ammonia_nitrate",{
		description = "Ammonia nitrate",
		inventory_image = "saturn_cells.png^[verticalframe:64:11",
	weight = 10,
	volume = 0.01,
	price = 1,
	is_ore = true,
})

register_craft_item("saturn:diammonium_phosphate",{
		description = "Diammonium phosphate",
		inventory_image = "saturn_cells.png^[verticalframe:64:12",
	weight = 10,
	volume = 0.01,
	price = 1,
	is_ore = true,
})

register_craft_item("saturn:oxygen",{
		description = "Oxygen",
		inventory_image = "saturn_cells.png^[verticalframe:64:13",
	weight = 10,
	volume = 0.01,
	price = 0.5,
	is_ore = true,
})

register_craft_item("saturn:nitric_acid",{
		description = "Nitric acid",
		inventory_image = "saturn_cells.png^[verticalframe:64:14",
	weight = 10,
	volume = 0.01,
	price = 1.5,
	is_ore = true,
})

register_craft_item("saturn:hydrogen_sulphide",{
		description = "Hydrogen sulphide",
		inventory_image = "saturn_cells.png^[verticalframe:64:15",
	weight = 10,
	volume = 0.01,
	price = 0.5,
	is_ore = true,
})

register_craft_item("saturn:sulphur",{
		description = "Sulphur",
		inventory_image = "saturn_cells.png^[verticalframe:64:16",
	weight = 10,
	volume = 0.01,
	price = 0.2,
	is_ore = true,
})

register_craft_item("saturn:sulphide_salts_mix",{
		description = "Sulphide salts mix",
		inventory_image = "saturn_cells.png^[verticalframe:64:17",
	weight = 10,
	volume = 0.01,
	price = 0.2,
	is_ore = true,
})

register_craft_item("saturn:silicon_dioxide",{
		description = "Silicon_dioxide",
		inventory_image = "saturn_cells.png^[verticalframe:64:18",
	weight = 10,
	volume = 0.01,
	price = 1.5,
	is_ore = true,
})

register_craft_item("saturn:potassium_oxide",{
		description = "Potassium oxide",
		inventory_image = "saturn_cells.png^[verticalframe:64:19",
	weight = 10,
	volume = 0.01,
	price = 10,
	is_ore = true,
})

register_craft_item("saturn:calcium_oxide",{
		description = "Calcium oxide",
		inventory_image = "saturn_cells.png^[verticalframe:64:20",
	weight = 10,
	volume = 0.01,
	price = 10,
	is_ore = true,
})

register_craft_item("saturn:magnesium_oxide",{
		description = "Magnesium oxide",
		inventory_image = "saturn_cells.png^[verticalframe:64:21",
	weight = 10,
	volume = 0.01,
	price = 10,
	is_ore = true,
})

register_craft_item("saturn:sodium_oxide",{
		description = "Sodium oxide",
		inventory_image = "saturn_cells.png^[verticalframe:64:22",
	weight = 10,
	volume = 0.01,
	price = 10,
	is_ore = true,
})

register_craft_item("saturn:alkali_solution",{
		description = "Alkali solution",
		inventory_image = "saturn_cells.png^[verticalframe:64:23",
	weight = 10,
	volume = 0.01,
	price = 1.5,
	is_ore = true,
})

register_craft_item("saturn:metal_oxides_sludge",{
		description = "Metal oxides sludge",
		inventory_image = "saturn_cells.png^[verticalframe:64:24",
	weight = 10,
	volume = 0.01,
	price = 1.5,
	is_ore = true,
})

register_craft_item("saturn:sodiumless_lithiumless_alkali_solution",{
		description = "Sodiumless lithiumless alkali solution",
		inventory_image = "saturn_cells.png^[verticalframe:64:25",
	weight = 10,
	volume = 0.01,
	price = 6,
	is_ore = true,
})

register_craft_item("saturn:sulphuric_acid",{
		description = "Sulphuric acid",
		inventory_image = "saturn_cells.png^[verticalframe:64:26",
	weight = 10,
	volume = 0.01,
	price = 1.1,
	is_ore = true,
})

register_craft_item("saturn:sodium_hydroxide",{
		description = "Sodium hydroxide",
		inventory_image = "saturn_cells.png^[verticalframe:64:27",
	weight = 10,
	volume = 0.01,
	price = 6,
	is_ore = true,
})

register_craft_item("saturn:lithium_hydroxide",{
		description = "lithium hydroxide",
		inventory_image = "saturn_cells.png^[verticalframe:64:28",
	weight = 10,
	volume = 0.01,
	price = 6,
	is_ore = true,
})

register_craft_item("saturn:complex_fertilizer",{
		description = "Complex fertilizer pellets for hydroponic farms",
		inventory_image = "saturn_complex_fertilizer.png",
	weight = 10,
	volume = 0.01,
	price = 4.5,
	is_ore = true,
})

register_craft_item("saturn:fresh_fruits_and_vegetables",{
		description = "Fresh fruits and vegetables",
		inventory_image = "saturn_fresh_fruits_and_vegetables.png",
	weight = 10,
	volume = 0.01,
	price = 8,
})
