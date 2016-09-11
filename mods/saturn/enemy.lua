saturn.enemy_ai_phase = false
saturn.enemy_spawn_conditions = {}
saturn.current_handled_enemy = 1
saturn.debug_enemy_pos_dump_threshold = 1000
saturn.player_pos_y_max_reached = 400
saturn.player_ship_ref = nil
saturn.loaded_enemy_entity = {}
saturn.current_handled_loaded_enemy = nil
saturn.enemy_respawn_timer = 900 -- Changing this will not change respawn rate.
local enemy_start_number = 12800
local enemy_player_tracking_range = 128
local enemy_player_tracking_interval = 20 -- seconds
local enemy_attack_interval = 5 -- seconds
local max_enemy_ship_spawned = 5
local getVectorPitchAngle = saturn.get_vector_pitch_angle
local getVectorYawAngle = saturn.get_vector_yaw_angle
local punch_object = saturn.punch_object
local enable_damage = minetest.setting_getbool("enable_damage")
local create_shooting_effect = saturn.create_shooting_effect

saturn.save_enemy_info = function()
    local file = io.open(minetest.get_worldpath().."/saturn_enemy_info", "w")
    file:write(minetest.serialize(saturn.virtual_enemy))
    file:close()
    file = io.open(minetest.get_worldpath().."/saturn_enemy_space_station", "w")
    file:write(minetest.serialize(saturn.enemy_space_station))
    file:close()
end

saturn.load_enemy_info = function()
    local file = io.open(minetest.get_worldpath().."/saturn_enemy_info", "r")
    if file ~= nil then
	local text = file:read("*a")
        file:close()
	if text and text ~= "" then
	    saturn.virtual_enemy = minetest.deserialize(text)
	end
    end
    file = io.open(minetest.get_worldpath().."/saturn_enemy_space_station", "r")
    if file ~= nil then
	local text = file:read("*a")
        file:close()
	if text and text ~= "" then
	    saturn.enemy_space_station = minetest.deserialize(text)
	end
    end
end

saturn.load_enemy_info()

if not saturn.enemy_space_station then
	saturn.enemy_space_station = {x = math.min(saturn.get_pseudogaussian_random(15000, 1000),30000),y = math.min(saturn.get_pseudogaussian_random(15000, 1000),30000),z = math.min(saturn.get_pseudogaussian_random(15000, 1000),30000)}
end


if not saturn.virtual_enemy then
	local ess = saturn.enemy_space_station
	saturn.virtual_enemy = {}
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
end



local on_enemy_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
   local obj = puncher:get_attach()
   if obj then
	local lua_entity = obj:get_luaentity()
	if lua_entity then
	    if lua_entity.name == "saturn:spaceship" and not lua_entity.is_escape_pod then
		self.target = obj
	    end
	end
   end
   if self.object:get_hp() <= 0 then
	local loot_level = self.loot_level or 1
	local loot_modifications_scale = self.loot_modifications_scale or 1.0
	local drops_amount = math.min(3,math.floor(saturn.get_pseudogaussian_random(1, 0.1))) -- 50% chance to 0. Capped to 3.
	if drops_amount > 0 then
	    for i=0, drops_amount do
		saturn.throw_item(saturn.generate_random_leveled_enemy_item(loot_level, loot_modifications_scale), self.object, self.object:getpos())
	    end
	end
	saturn.create_explosion_effect(self.object:getpos())
	if self.uid then
		saturn.loaded_enemy_entity[self.uid] = nil
	end
	self.remove_at_init = true
   end
end

local update_loaded_entity_list = function(self)
	local uid = self.uid
	local obj = self.object
	local pos = obj:getpos()
	local vel = obj:getvelocity()
	saturn.loaded_enemy_entity[uid] = {
uid = uid,
object = self.object,
	ve = {x = pos.x,
		y = pos.y,
		z = pos.z,
		vel_x=(vel.x+math.random()-0.5)*10,
		vel_y=(vel.y+math.random()-0.5)*10,
		vel_z=(vel.z+math.random()-0.5)*10,
		entity_name=self.name,}}
end

local find_target = function(self_pos)
    local objs = minetest.env:get_objects_inside_radius(self_pos, enemy_player_tracking_range)
    for k, obj in pairs(objs) do
	local lua_entity = obj:get_luaentity()
	if lua_entity then
	    if lua_entity.name == "saturn:spaceship" and not lua_entity.is_escape_pod then
		local is_clear, node_pos = minetest.line_of_sight(self_pos, obj:getpos(), 2)
		if is_clear then
		    return obj
		end
	    end
	end
    end
    return nil
end

local find_closest_target = function(pos, self_pos)
    local objs = minetest.env:get_objects_inside_radius(pos, enemy_player_tracking_range)
    local target = nil
    local latest_distance_sqrd = enemy_player_tracking_range * enemy_player_tracking_range
    for k, obj in pairs(objs) do
	local lua_entity = obj:get_luaentity()
	if lua_entity then
	    if lua_entity.name == "saturn:spaceship" and not lua_entity.is_escape_pod then
		local obj_pos = obj:getpos()
		if obj_pos and self_pos then
		    local is_clear, node_pos = minetest.line_of_sight(self_pos, obj_pos, 2)
		    if is_clear then
			local dx = obj_pos.x - pos.x
			local dy = obj_pos.y - pos.y
			local dz = obj_pos.z - pos.z
			local dd = dx*dx + dy*dy + dz*dz
			if dd < latest_distance_sqrd then
			    target = obj
			    latest_distance_sqrd = dd
		        end
		    end
		else
		    return nil
		end
	    end
	end
    end
    return target
end

local on_enemy_step = function(self, dtime)
    if self.remove_at_init or saturn.peaceful_mode then
	self.object:remove()
	return
    end
    local self_pos = self.object:getpos()
    if not self.uid then
	self.uid = self_pos.x * 31000 * 31000 + self_pos.y  * 31000 + self_pos.z
    end
    self.age = self.age + dtime
    if self.unlock_ai_next_tick then
	saturn.enemy_ai_phase = false
    end
    if self.target then
	local target_pos = self.target:getpos()
	if target_pos then
	    local nat = self.next_attack_timer - dtime
	    if nat < 0 and not saturn.enemy_ai_phase then
		update_loaded_entity_list(self)
    		saturn.enemy_ai_phase = true
		self.unlock_ai_next_tick = true
		local target_velocity = self.target:getvelocity()
	    	local vector_to_target = vector.subtract(target_pos,self_pos)
		local self_velocity = self.object:getvelocity()
	    	local distance_to_target = vector.length(vector_to_target)
	    	local direction_to_target = vector.divide(vector_to_target,distance_to_target)
	    	local realtive_to_target_speed = vector.subtract(self_velocity,target_velocity)
	    	if distance_to_target > 16 then
		    local v_normal_to_speed_direction = vector.divide(saturn.vector_multiply(realtive_to_target_speed,vector_to_target),distance_to_target)
		    local speed_projection_v = vector.divide(saturn.vector_multiply(v_normal_to_speed_direction,vector_to_target),distance_to_target)
		    local acceleration_v = vector.multiply(vector.normalize(vector.add(vector_to_target,speed_projection_v)),self.acceleration)
		    self.object:setacceleration(acceleration_v)
	   	else
	    	    if vector.length(realtive_to_target_speed) > 0.5 then
			local acceleration_v = vector.multiply(vector.normalize(realtive_to_target_speed),-self.acceleration)
			self.object:setacceleration(acceleration_v)
	    	    else
			self.object:setacceleration(vector.new(0,0,0))
	    	    end
	   	end
	    	local yaw = -getVectorYawAngle(direction_to_target)
	    	local pitch = -getVectorPitchAngle(direction_to_target)
	    	self.object:set_bone_position("Head", {x=0,y=1,z=0}, {x=pitch*180/3.14159,y=0,z=yaw*180/3.14159})
		local lua_entity = self.target:get_luaentity()
		if lua_entity then
		    if lua_entity.is_escape_pod then
			self.target = nil
		    else
		        if lua_entity.driver then
			    local is_clear, node_pos = minetest.line_of_sight(self_pos, target_pos, 2)
			    if is_clear then
				if enable_damage then
				    punch_object(lua_entity.driver, self.object, self.damage)
				end
				minetest.sound_play("saturn_ship_hit", {to_player = lua_entity.driver_name})
			    else
				local node_info = minetest.get_node(node_pos)
				if node_info.name == "saturn:fog" then
					minetest.remove_node(node_pos)
				end
			    end
			    create_shooting_effect(self_pos, direction_to_target, 2)
			end
		    end
		end
		self.next_attack_timer = math.random()*2+3
	    else
		self.next_attack_timer = nat
	    end
	else
	    self.target = nil
	end
    else
	local npt = self.next_player_detect - dtime
	if npt < 0 and not saturn.enemy_ai_phase then
	    update_loaded_entity_list(self)
    	    saturn.enemy_ai_phase = true
	    self.unlock_ai_next_tick = true
	    self.target = find_target(self_pos)
	    self.next_player_detect = 20
	else
	    self.next_player_detect = npt
	end
    end
end

local on_guard_step = function(self, dtime)
    if self.remove_at_init or saturn.peaceful_mode then
	self.object:remove()
	return
    end
    local self_pos = self.object:getpos()
    self.age = self.age + dtime
    if self.unlock_ai_next_tick then
	saturn.enemy_ai_phase = false
    end
    if self.target then
	local target_pos = self.target:getpos()
	if target_pos then
	    local nat = self.next_attack_timer - dtime
	    if nat < 0 and not saturn.enemy_ai_phase then
    		saturn.enemy_ai_phase = true
		self.unlock_ai_next_tick = true
		local target_velocity = self.target:getvelocity()
	    	local vector_to_target = vector.subtract(target_pos,self_pos)
		local self_velocity = self.object:getvelocity()
	    	local distance_to_target = vector.length(vector_to_target)
	    	local direction_to_target = vector.divide(vector_to_target,distance_to_target)
	    	local realtive_to_target_speed = vector.subtract(self_velocity,target_velocity)
		local ess = saturn.enemy_space_station
	    	local distance_to_mothership = vector.distance(self_pos, ess)
		if distance_to_mothership > 32 then
		    local acceleration_v = vector.multiply(vector.normalize(vector.subtract(ess,self_pos)),self.acceleration)
		    self.object:setacceleration(acceleration_v)
	    	elseif distance_to_target > 16 then
		    local v_normal_to_speed_direction = vector.divide(saturn.vector_multiply(realtive_to_target_speed,vector_to_target),distance_to_target)
		    local speed_projection_v = vector.divide(saturn.vector_multiply(v_normal_to_speed_direction,vector_to_target),distance_to_target)
		    local acceleration_v = vector.multiply(vector.normalize(vector.add(vector_to_target,speed_projection_v)),self.acceleration)
		    self.object:setacceleration(acceleration_v)
	   	else
	    	    if vector.length(realtive_to_target_speed) > 0.5 then
			local acceleration_v = vector.multiply(vector.normalize(realtive_to_target_speed),-self.acceleration)
			self.object:setacceleration(acceleration_v)
	    	    else
			self.object:setacceleration(vector.new(0,0,0))
	    	    end
	   	end
	    	local yaw = -getVectorYawAngle(direction_to_target)
	    	local pitch = -getVectorPitchAngle(direction_to_target)
	    	self.object:set_bone_position("Head", {x=0,y=1,z=0}, {x=pitch*180/3.14159,y=0,z=yaw*180/3.14159})
		local lua_entity = self.target:get_luaentity()
		if lua_entity then
		    if lua_entity.is_escape_pod then
			self.target = nil
		    else
		        if lua_entity.driver then
			    local is_clear, node_pos = minetest.line_of_sight(self_pos, target_pos, 2)
			    if is_clear then
				if enable_damage then
				    punch_object(lua_entity.driver, self.object, self.damage)
				end
				minetest.sound_play("saturn_ship_hit", {to_player = lua_entity.driver_name})
			    else
				local node_info = minetest.get_node(node_pos)
				if node_info.name == "saturn:fog" then
					minetest.remove_node(node_pos)
				end
			    end
			    create_shooting_effect(self_pos, direction_to_target, 2)
			end
		    end
		end
		self.next_attack_timer = math.random()*2+3
	    else
		self.next_attack_timer = nat
	    end
	else
	    self.target = nil
	end
    else
	local ess = saturn.enemy_space_station
    	local distance_to_mothership = vector.distance(self_pos, ess)
	if distance_to_mothership > 32 then
	    local acceleration_v = vector.multiply(vector.normalize(vector.subtract(ess,self_pos)),self.acceleration)
	    self.object:setacceleration(acceleration_v)
	end
    end

    local npt = self.next_player_detect - dtime
    if npt < 0 and not saturn.enemy_ai_phase then
    	saturn.enemy_ai_phase = true
	self.unlock_ai_next_tick = true
	self.target = find_closest_target(saturn.enemy_space_station, self_pos)
        self.next_player_detect = 20
    else
	self.next_player_detect = npt
    end
end


local _get_staticdata = function(self)
	return core.serialize({
		remove_at_init = true,
	})
end

local _on_activate = function(self, staticdata, dtime_s)
	local data = core.deserialize(staticdata)
	if data and type(data) == "table" then
		self.remove_at_init = data.remove_at_init
	end
end


local register_enemy = function(name, properties, ring_elevation_level)
	local enemy = {
		hp_max = properties.hp_max,
		physical = true,
		collisionbox = {-1.0,-1.0,-1.0, 1.0, 1.0, 1.0},
		textures = properties.textures,
		visual = "mesh",
		mesh = properties.mesh,
		visual_size = {x=5, y=5},
		velocity = {x=0, y=0, z=0},
		lastpos = {x=0, y=0, z=0},
		age = 0,
		next_attack_timer = 0.2,
		next_player_detect = 0.2,
		acceleration = 0.8,
		target = nil,
		unlock_ai_next_tick = false,
		on_punch = on_enemy_punch,
		on_step = on_enemy_step,
		loot_level = properties.loot_level,
		loot_modifications_scale = properties.loot_modifications_scale,
		damage = properties.damage,
		get_staticdata=_get_staticdata,
		on_activate=_on_activate,
	}
	minetest.register_entity(name, enemy)
	table.insert(saturn.enemy_spawn_conditions,ring_elevation_level, name)
end

local register_enemy_guard = function(name, properties)
	local enemy = {
		hp_max = properties.hp_max,
		physical = true,
		collisionbox = {-0.5,-0.5,-0.5, 0.5, 0.5, 0.5},
		textures = properties.textures,
		visual = "mesh",
		mesh = properties.mesh,
		visual_size = {x=5, y=5},
		velocity = {x=0, y=0, z=0},
		lastpos = {x=0, y=0, z=0},
		age = 0,
		next_attack_timer = 0.2,
		next_player_detect = 0.2,
		acceleration = 0.8,
		target = nil,
		unlock_ai_next_tick = false,
		on_punch = on_enemy_punch,
		on_step = on_guard_step,
		loot_level = properties.loot_level,
		loot_modifications_scale = properties.loot_modifications_scale,
		damage = properties.damage,
	}
	minetest.register_entity(name, enemy)
end

register_enemy("saturn:enemy_01", {
	hp_max = 150,
	textures = {"saturn_enemy_01.png"},
	mesh = "saturn_enemy_01.b3d",
	loot_level = 1,
	loot_modifications_scale = 1.0,
	damage = 25,
	}, 
	1)

register_enemy("saturn:enemy_02", {
	hp_max = 300,
	textures = {"saturn_enemy_01.png"},
	mesh = "saturn_enemy_02.b3d",
	loot_level = 2,
	loot_modifications_scale = 1.5,
	damage = 100,
	},
	2)

register_enemy_guard("saturn:enemy_guard_01", {
	hp_max = 300,
	textures = {"saturn_enemy_guard.png"},
	mesh = "saturn_enemy_guard_01.b3d",
	loot_level = 2,
	loot_modifications_scale = 2,
	damage = 100,
	})

minetest.register_chatcommand("en_pos_thr", {
	params = "threshold",
	description = "debug_enemy_pos_dump_threshold",
	privs = {server = true},
	func = function(name, param)
		saturn.debug_enemy_pos_dump_threshold = tonumber(param)
		return true, ("%d threshold set")
			:format(param)
	end,
})


minetest.register_chatcommand("peaceful_mode", {
	params = "boolean",
	description = "debug_enemy_pos_dump_threshold",
	privs = {server = true},
	func = function(name, param)
		saturn.peaceful_mode = minetest.is_yes(param)
		return true, ("peaceful mode is "..tostring(saturn.peaceful_mode))
	end,
})

local box_slope = { --This 9 lines taken from "moreblocks" mod by Calinou and contributors without any changes. Source: https://github.com/kaeza/calinou_mods/tree/master/moreblocks
	type = "fixed",
	fixed = {
		{-0.5,  -0.5,  -0.5, 0.5, -0.25, 0.5},
		{-0.5, -0.25, -0.25, 0.5,     0, 0.5},
		{-0.5,     0,     0, 0.5,  0.25, 0.5},
		{-0.5,  0.25,  0.25, 0.5,   0.5, 0.5}
	}
}

minetest.register_node("saturn:enemy_mothership_core", {
	description = "Enemy mothership core",
	tiles = {"saturn_enemy_mothership_core.png",
		"saturn_enemy_mothership_core.png",
		"saturn_enemy_mothership_core.png",
		"saturn_enemy_mothership_core.png",
		"saturn_enemy_mothership_core.png",
		"saturn_enemy_mothership_core.png"},
	groups = {enemy_mothership = 1},
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			minetest.remove_node(pointed_thing.under)
		end
	end,
	on_destruct = function(pos)
		saturn.enemy_space_station.is_destroyed = true
	end,
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_hull", {
	description = "Enemy mothership hull",
	tiles = {"saturn_enemy_mothership_hull.png",
		"saturn_enemy_mothership_hull.png",
		"saturn_enemy_mothership_hull_back.png",
		"saturn_enemy_mothership_hull_back.png",
		"saturn_enemy_mothership_hull.png",
		"saturn_enemy_mothership_hull.png"},
	groups = {enemy_mothership = 1},
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			minetest.remove_node(pointed_thing.under)
		end
	end,
	toughness = 800,
})

minetest.register_node("saturn:enemy_forcefield", {
	description = "Enemy forcefield",
	tiles = {
		{
			name = "saturn_enemy_forcefield_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 32.0,
			},
		},
	},
	use_texture_alpha = true,
	groups = {enemy_mothership = 1},
	drawtype = "glasslike",
	light_source = 14,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	drop = "",
	post_effect_color = {a = 50, r = 0, g = 250, b = 240},
})

minetest.register_node("saturn:enemy_mothership_hull_deep", {
	description = "Enemy mothership hull",
	tiles = {"saturn_enemy_mothership_hull.png^[colorize:#000:192",
		"saturn_enemy_mothership_hull.png^[colorize:#000:192",
		"saturn_enemy_mothership_hull_back.png^[colorize:#000:192",
		"saturn_enemy_mothership_hull_back.png^[colorize:#000:192",
		"saturn_enemy_mothership_hull.png^[colorize:#000:192",
		"saturn_enemy_mothership_hull.png^[colorize:#000:192"},
	groups = {enemy_mothership = 1},
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			minetest.remove_node(pointed_thing.under)
		end
	end,
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_hull_slope", {
	description = "Enemy mothership hull slope",
	tiles = {"saturn_enemy_mothership_hull_back.png"},
	drawtype = "mesh",
	mesh = "saturn_slope_h.obj",
	groups = {enemy_mothership = 1},
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
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_inners", {
	description = "Enemy mothership inners",
	tiles = {"saturn_enemy_mothership_inners.png",
		"saturn_enemy_mothership_inners.png",
		"saturn_enemy_mothership_inners_front.png",
		"saturn_enemy_mothership_inners_front.png",
		"saturn_enemy_mothership_inners.png",
		"saturn_enemy_mothership_inners.png"},
	groups = {enemy_mothership = 1},
	light_source = 1,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			minetest.remove_node(pointed_thing.under)
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		minetest.add_node(vector.add(user:getpos(),user:get_look_dir()), {name=itemstack:get_name(), param1=0, param2=0})
	end,
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_guard_spawn_point", {
	description = "Enemy mothership guard spawn point",
	tiles = {"saturn_enemy_mothership_guard_spawner.png",
		"saturn_enemy_mothership_guard_spawner.png",
		"saturn_enemy_mothership_guard_spawner.png",
		"saturn_enemy_mothership_guard_spawner.png",
		"saturn_enemy_mothership_guard_spawner.png",
		"saturn_enemy_mothership_guard_spawner.png"},
	groups = {enemy_mothership = 1},
	light_source = 1,
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_bone", {
	description = "Enemy mothership bone",
	tiles = {"saturn_enemy_mothership_bone.png",
		"saturn_enemy_mothership_bone.png",
		"saturn_enemy_mothership_bone_front.png",
		"saturn_enemy_mothership_bone_front.png",
		"saturn_enemy_mothership_bone.png",
		"saturn_enemy_mothership_bone.png"},
	groups = {enemy_mothership = 1},
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			minetest.remove_node(pointed_thing.under)
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		minetest.add_node(vector.add(user:getpos(),user:get_look_dir()), {name=itemstack:get_name(), param1=0, param2=0})
	end,
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_bone_slope", {
	description = "Enemy mothership bone slope",
	tiles = {"saturn_enemy_mothership_bone.png"},
	drawtype = "mesh",
	mesh = "saturn_slope_h.obj",
	groups = {enemy_mothership = 1},
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
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_bone_slope_left", {
	description = "Enemy mothership bone slope left",
	tiles = {"saturn_enemy_mothership_bone.png"},
	drawtype = "mesh",
	mesh = "saturn_slope_h_left.obj",
	groups = {enemy_mothership = 1},
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
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_hull_peak_h", {
	description = "Enemy mothership hull peak left",
	tiles = {"saturn_enemy_mothership_hull_back.png"},
	drawtype = "mesh",
	mesh = "saturn_peak.obj",
	groups = {enemy_mothership = 1},
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
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_hull_peak_v", {
	description = "Enemy mothership hull peak r",
	tiles = {"saturn_enemy_mothership_hull_back.png"},
	drawtype = "mesh",
	mesh = "saturn_peak_v.obj",
	groups = {enemy_mothership = 1},
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
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_hull_peak_top", {
	description = "Enemy mothership hull peak top",
	tiles = {"saturn_enemy_mothership_hull_back.png"},
	drawtype = "mesh",
	mesh = "saturn_peak_top.obj",
	groups = {enemy_mothership = 1},
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
	toughness = 800,
})

minetest.register_node("saturn:enemy_mothership_hull_peak_bottom", {
	description = "Enemy mothership hull peak bottom",
	tiles = {"saturn_enemy_mothership_hull_back.png"},
	drawtype = "mesh",
	mesh = "saturn_peak_bottom.obj",
	groups = {enemy_mothership = 1},
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
	toughness = 800,
})

minetest.register_abm({
        nodenames = {"saturn:enemy_mothership_guard_spawn_point"},
        interval = 2.0,
        chance = 1,
        catch_up = false,
        action = function(pos, node, active_object_count, active_object_count_wider)
	    local metaref = minetest.get_meta(pos)
	    local quantity_left = 64
	    if metaref:get_string("quantity_left") ~= "" then
		quantity_left = metaref:get_int("quantity_left")
	    end
	    if quantity_left > 0 then
		if active_object_count_wider <= 10 then
		    pos.x = pos.x - 1
		    local entity = minetest.add_entity(pos,"saturn:enemy_guard_01")
		    local direction_velocity = vector.new(-4,0,0)
		    if entity then
			entity:setvelocity(direction_velocity)
			entity:set_bone_position("Head", {x=0,y=1,z=0}, {x=0,y=0,z=270})
		    end
		    metaref:set_int("quantity_left",quantity_left - 1)
		end
	    end
	end
    }
)
