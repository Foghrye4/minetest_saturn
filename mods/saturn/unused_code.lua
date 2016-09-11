-- A bunch of structured text, saved here for a case if I will use it sometimes.

local walking_turret_animation = {walk={x=0,y=41},shoot={x=42,y=60},stand={x=61,y=100}}
local c_air = minetest.get_content_id("air")

local get_list_of_primary_directions = function(self_pos, target_pos)
	local dir_vect_nn = vector.subtract(target_pos,self_pos)
	local abs_x = math.abs(dir_vect_nn.x)
	local abs_y = math.abs(dir_vect_nn.y)
	local abs_z = math.abs(dir_vect_nn.z)
	local primary_dir = vector.new(0,0,0)
	local secondary_dir = vector.new(0,0,0)
	local tertiary_dir = vector.new(0,0,0)
	if abs_x >= abs_y and abs_x >= abs_z then
		primary_dir.x = math.sign(dir_vect_nn.x)
		if abs_y >= abs_z then
			secondary_dir.y = math.sign(dir_vect_nn.y)
			tertiary_dir.z = math.sign(dir_vect_nn.z)
		else
			secondary_dir.z = math.sign(dir_vect_nn.z)
			tertiary_dir.y = math.sign(dir_vect_nn.y)
		end
	elseif abs_y > abs_x and abs_y >= abs_z then
		primary_dir.y = math.sign(dir_vect_nn.y)
		if abs_x >= abs_z then
			secondary_dir.x = math.sign(dir_vect_nn.x)
			tertiary_dir.z = math.sign(dir_vect_nn.z)
		else
			secondary_dir.z = math.sign(dir_vect_nn.z)
			tertiary_dir.x = math.sign(dir_vect_nn.x)
		end
	else
		primary_dir.z = math.sign(dir_vect_nn.z)
		if abs_x >= abs_y then
			secondary_dir.x = math.sign(dir_vect_nn.x)
			tertiary_dir.y = math.sign(dir_vect_nn.y)
		else
			secondary_dir.y = math.sign(dir_vect_nn.y)
			tertiary_dir.x = math.sign(dir_vect_nn.x)
		end
	end
	return {primary_dir,secondary_dir,tertiary_dir,vector.multiply(tertiary_dir, -1),vector.multiply(secondary_dir, -1)}
end

local get_aceptable_start_point = function(start_pos, condition)
	local node_pos = vector.new(start_pos.x,start_pos.y,start_pos.z)
	if not condition(start_pos) then
	    for ix = -2,2 do
		for iy = -2,2 do
		    for iz = -2,2 do
			node_pos.x = start_pos.x + ix
			node_pos.y = start_pos.y + iy
			node_pos.z = start_pos.z + iz
			if condition(node_pos) then
			     return node_pos
			end
		    end
		end		
	    end
	end
	return node_pos
end

local get_closest_point_to_target = function(self_pos, target_pos, condition, primary_dir_list)
	local path = {}
	local node_pos = vector.new(math.floor(self_pos.x),math.floor(self_pos.y),math.floor(self_pos.z))
	node_pos = get_aceptable_start_point(node_pos, condition)
	local c_pos = vector.new(node_pos.x,node_pos.y,node_pos.z)
	local last_tpds = 16384
	local hashs = {}
	for i=0,64 do
	    local thread_continue = false
	    for i=1,#primary_dir_list do
		c_pos = vector.add(node_pos, primary_dir_list[i])
		local dx = target_pos.x-c_pos.x
		local dy = target_pos.y-c_pos.y
		local dz = target_pos.z-c_pos.z
		local tpds = dx*dx + dy*dy + dz*dz
		if condition(c_pos) and tpds <= last_tpds + 32 then
			node_pos = vector.add(node_pos, primary_dir_list[i])
			table.insert(path,node_pos)
			local hash = minetest.hash_node_position(node_pos)
			hashs[hash] = true
			if tpds < last_tpds then
				last_tpds = tpds
			end
			thread_continue = tpds > 1
			break
		end
	    end
	    if not thread_continue then
		break
	    end
	end
	return node_pos, path
end

local condition_not_air = function(pos)
	local node = minetest.get_node(pos)
	return node.name ~= "air"
end

local condition_surface = function(_pos)
	if condition_not_air(_pos) then
		return false
	end
	local pos = vector.new(_pos.x,_pos.y,_pos.z)
	for ix = -1,1 do
		for iy = -1,1 do
			for iz = -1,1 do
				pos.x = _pos.x + ix
				pos.y = _pos.y + iy
				pos.z = _pos.z + iz
				if condition_not_air(pos) then
					return true
				end
			end
		end		
	end
	return false
end

local get_path_to_target = function(self_pos, target_pos)
	local primary_dir_list = get_list_of_primary_directions(self_pos, target_pos)
	local target_node_pos = get_closest_point_to_target(self_pos, target_pos, condition_not_air, primary_dir_list)
	local node_pos, path = get_closest_point_to_target(self_pos, vector.add(target_node_pos,primary_dir_list[1]), condition_surface, primary_dir_list)
	return path
end

-- Not working. I will keep it just in case --
local _get_surface_normal = function(pos)
    minetest.chat_send_all(dump(pos))
    local minp_x = math.floor(pos.x - 2)
    local maxp_x = math.floor(pos.x + 2)
    local minp_y = math.floor(pos.y - 2)
    local maxp_y = math.floor(pos.y + 2)
    local minp_z = math.floor(pos.z - 2)
    local maxp_z = math.floor(pos.z + 2)
    local emin = {x=minp_x,y=minp_y,z=minp_z}
    local emax = {x=maxp_x,y=maxp_y,z=maxp_z}
    local xn = 0
    local yn = 0
    local zn = 0
    local vm = minetest.get_voxel_manip(emin, emax)
    local data = vm:get_data()
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    for z = minp_z, maxp_z do
 	for y = minp_y, maxp_y do
	    for x = minp_x, maxp_x do
		local p_pos = area:index(x, y, z)
		minetest.chat_send_all("data[p_pos]="..data[p_pos].." for "..x..";"..y..";"..z)
		if data[p_pos] == c_air then
		    if x > pos.x then
			xn = xn + 1
		    elseif x < pos.x then
			xn = xn - 1
		    end
		    if y > pos.y then
			yn = yn + 1
		    elseif y < pos.y then
			yn = yn - 1
		    end
		    if z > pos.z then
			zn = zn + 1
		    elseif z < pos.z then
			zn = zn - 1
		    end
		end
	    end
	end
    end
    return vector.normalize(vector.new(xn,yn,zn))
end
-------------------------------------------

local get_surface_normal = function(_pos)
    local xn = 0
    local yn = 0
    local zn = 0
    local dxyz = {0,1,0,0,-1,0,0}
    local pos = {x=math.floor(_pos.x),
		y=math.floor(_pos.y),
		z=math.floor(_pos.z)+1}
    local node = minetest.get_node(pos)
    if node.name == "air" then
	zn = 1
    end
    for i=1,5 do
	pos.x = math.floor(_pos.x) + dxyz[i]
	pos.y = math.floor(_pos.y) + dxyz[i+1]
	pos.z = math.floor(_pos.z) + dxyz[i+2]
	node = minetest.get_node(pos)
	if node.name == "air" then
		xn = xn + dxyz[i]
		yn = yn + dxyz[i+1]
		zn = zn + dxyz[i+2]
	end
    end
    if xn == 0 and yn == 0 and zn == 0 then
	    dxyz = {0,0,2,0,0,-2,0,0}
	    for i=1,6 do
		pos.x = math.floor(_pos.x) + dxyz[i]
		pos.y = math.floor(_pos.y) + dxyz[i+1]
		pos.z = math.floor(_pos.z) + dxyz[i+2]
		node = minetest.get_node(pos)
		if node.name == "air" then
			xn = xn + dxyz[i]
			yn = yn + dxyz[i+1]
			zn = zn + dxyz[i+2]
		end
	    end
    end
    return xn, yn, zn
end

local cartesian_planar_non_normalized_to_polar_degree = function(x, y, z)
	--start pos = (0,0,1) 90 degr. pitch turn to (0,-1,0)
	local pitch = 0
	local yaw = 0
	if y < 0 and z == 0 then
		pitch = 90
	elseif y > 0 and z == 0 then
		pitch = 270
	elseif y == 0 and z > 0 then
		pitch = 0
	elseif y == 0 and z < 0 then
		pitch = 180
	elseif y > 0 and z > 0 then
		pitch = 315
	elseif y < 0 and z > 0 then
		pitch = 45
	elseif y > 0 and z < 0 then
		pitch = 225
	elseif y < 0 and z < 0 then
		pitch = 135
	elseif y==0 and z==0 then
		pitch = 90
	end
	if x > 0 then
		yaw = 90
	elseif x < 0 then
		yaw = 270
	end
	return pitch, yaw
end

local get_pitch_and_yaw = function(x, y, z)
	return cartesian_planar_non_normalized_to_polar_degree(x, y, z)
end

local can_shoot_target = function(self_pos, surface_normal, target_obj)
    	local dir_to_target = vector.direction(target_obj:getpos(),self_pos)
	local s_c_summ = vector.length(vector.add(dir_to_target,surface_normal))
	return s_c_summ > 1
end

local AI_TASK_IDLE = 0
local AI_TASK_SHOOT = 1
local AI_TASK_WALK = 2

local get_yaw_angle = saturn.get_vector_yaw_angle
local get_pitch_angle = saturn.get_vector_pitch_angle
local on_walking_turret_step = function(self, dtime)
    self.age = self.age + 1
    local self_pos = self.object:getpos()
    local node_x = math.floor(self_pos.x)
    local node_y = math.floor(self_pos.y)
    local node_z = math.floor(self_pos.z)
    local lnp  = self.last_node_pos
    if self.unlock_ai_next_tick then
	saturn.enemy_ai_phase = false
    end
    if self.ai_task == AI_TASK_WALK and self.next_waypoint then
	local dwpx = self.next_waypoint.x - self_pos.x
	local dwpy = self.next_waypoint.y - self_pos.y
	local dwpz = self.next_waypoint.z - self_pos.z
	if dwpx*dwpx + dwpy*dwpy + dwpz*dwpz < 0.1 then
		if #self.path > 0 then
			self.next_waypoint = table.remove(self.path,1)
			local vel = vector.multiply(vector.subtract(self.next_waypoint,self.object:getpos()),0.1)
			self.object:setvelocity(vel)
		else
			self.ai_task = AI_TASK_IDLE
		end
	end
	return
    end
    if node_x ~= lnp.x or node_y ~= lnp.y or node_z ~= lnp.z then
	lnp.x = node_x
	lnp.y = node_y
	lnp.z = node_z
	local snx,sny,snz = get_surface_normal(self_pos)
	self.surface_normal = vector.normalize(vector.new(snx,sny,snz))
	local pitch, yaw = get_pitch_and_yaw(snx,sny,snz)
	if self.age == 1 then
		local objs = minetest.env:get_objects_inside_radius(self_pos, 0.5)
		for k, obj in pairs(objs) do
		    local lua_entity = obj:get_luaentity()
		    if lua_entity and lua_entity.name == "saturn:walking_turret_model_01" then
			obj:set_attach(self.object, "Body", {x=0,y=1,z=0}, {x=pitch*180/3.14159,y=0,z=yaw*180/3.14159})
			obj:set_animation(walking_turret_animation.walk, 15, 0, true)
			self.model_entity = obj
			break
		    end
		end
		if not self.model_entity then
			local model_entity = minetest.add_entity(self_pos, "saturn:walking_turret_model_01")
			model_entity:set_animation(walking_turret_animation.walk, 15, 0, true)
			model_entity:set_attach(self.object, "Body", {x=0,y=1,z=0}, {x=pitch*180/3.14159,y=0,z=yaw*180/3.14159})
			self.model_entity = model_entity
		end
	end
	if self.model_entity then
		self.model_entity:set_attach(self.object, "Body", {x=0,y=1,z=0}, {x=pitch,y=0,z=yaw}) 
	end
   end
    if self.target then
	if can_shoot_target(self_pos, self.surface_normal, self.target) then
		self.ai_task = AI_TASK_SHOOT
		return
	else
		self.path = get_path_to_target(self_pos, self.target:getpos())
		if #self.path > 0 then
			self.next_waypoint = table.remove(self.path,1)
			local vel = vector.multiply(vector.subtract(self.next_waypoint,self.object:getpos()),0.1)
			self.object:setvelocity(vel)
			self.model_entity:set_animation(walking_turret_animation.walk, 15, 0, true)
			self.ai_task = AI_TASK_WALK
			return
		end
	end
    else
	local npt = self.next_player_detect - dtime
	if npt < 0 and not saturn.enemy_ai_phase then
    	    saturn.enemy_ai_phase = true
	    self.unlock_ai_next_tick = true
	    self.target = find_target(self_pos)
	    self.next_player_detect = 20
	else
	    self.next_player_detect = npt
	end
    end

-- z controls direction around blender Y axis and minetest Z axis
-- x controls direction around blender X axis and minetest X axis
end

local on_walking_turret_model_step = function(self, dtime)
	self.age = self.age + 1
	if self.age > 10 and not self.object:get_attach() then
		self.object:remove()
	end
end

local walking_turret = {
	hp_max = 300,
	physical = true,
	collisionbox = {-1.0,-1.0,-1.0, 1.0, 1.0, 1.0},
	textures = {"null.png"},
	visual = "sprite",
	visual_size = {x=1, y=1},
	velocity = {x=0, y=0, z=0},
	last_node_pos = {x=0, y=0, z=0},
	age = 0,
	next_attack_timer = 0.2,
	next_player_detect = 0.2,
	target = nil,
	unlock_ai_next_tick = false,
	on_step = on_walking_turret_step,
	loot_level = 2,
	loot_modifications_scale = 1.5,
	damage = 150,
	model_entity = nil,
	surface_normal = vector.new(0,1,0),
	ai_task = 0,
	path = {},
	next_waypoint = nil,
}

local walking_turret_model = {
	physical = false,
	collisionbox = {0,0,0,0,0,0},
	textures = {"saturn_enemy_walking_turret.png"},
	mesh = "saturn_enemy_walking_turret_01.b3d",
	visual = "mesh",
	visual_size = {x=5, y=5},
	age = 0,
	on_step = on_walking_turret_model_step,
}

minetest.register_entity("saturn:walking_turret_01", walking_turret)
minetest.register_entity("saturn:walking_turret_model_01", walking_turret_model)

local ss_min_coord = -128 -- Space station minimal coordinate
local ss_max_coord = 128-- Space station maximal coordinate
local ss_sphere_sqr = 4096 -- Space station inner sphere squared radius
local ss_hatches_console_sqr = 13456 -- Space station inner sphere squared radius
local hull = minetest.get_content_id("saturn:space_station_hull")
local window = minetest.get_content_id("saturn:space_station_window")
local hatch = minetest.get_content_id("saturn:space_station_hatch")

minetest.register_on_generated(function(minp, maxp, seed)
	local minp_x = minp.x
	local minp_y = minp.y
	local minp_z = minp.z
	local maxp_x = maxp.x
	local maxp_y = maxp.y
	local maxp_z = maxp.z
	if maxp_x >= ss_min_coord  + ss_x and 
	maxp_y >= ss_min_coord + ss_y and 
	maxp_z >= ss_min_coord + ss_z and 
	minp_x <= ss_max_coord + ss_x and 
	minp_y <= ss_max_coord + ss_y and 
	minp_z <= ss_max_coord + ss_z then
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local data = vm:get_data()
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
		local param2_data = vm:get_param2_data()
		for z = minp_z, maxp_z do
     		 	for y = minp_y, maxp_y do
       		 	 	for x = minp_x, maxp_x do
					local p_pos = area:index(x, y, z)
					local x1 = x - ss_x
					local y1 = y - ss_y
					local z1 = z - ss_z
					local sq_r = x1*x1+y1*y1+z1*z1
					if sq_r<ss_sphere_sqr then
						if (y1 + 2) % 4 == 0 and 
						math.floor(x1 / 5 - 0.5) % 2 ==0 and
						math.floor(z1 / 5 - 0.5) % 2 ==0 then
							data[p_pos] = window
						else
							data[p_pos] = hull
						end
					else
						if z1 * z1 <= ss_hatches_console_sqr  and 
						y1 * y1 <= ss_hatches_console_sqr and 
						x1 * x1 <= ss_hatches_console_sqr then
							if (x1 * x1 <= 4 and y1 * y1 <= 4) or
							(x1 * x1 <= 4 and z1 * z1 <= 4) or
							(z1 * z1 <= 4 and y1 * y1 <= 4) then
								data[p_pos] = hull
							else
								if z1 % 16 == 0 and z1 * z1 > ss_sphere_sqr + 16 then
									if x1 * x1 == 9 and y1 == 0 then
										data[p_pos] = hatch
										if x1 > 0 then
											param2_data[p_pos] = 2
										else
											param2_data[p_pos] = 3
										end
									end
									if y1 * y1 == 9 and x1 == 0 then
										data[p_pos] = hatch
										if y1 > 0 then
											param2_data[p_pos] = 0
										else
											param2_data[p_pos] = 1
										end
									end
								end
								if y1 % 16 == 0 and y1 * y1 > ss_sphere_sqr + 16 then
									if x1 * x1 == 9 and z1 == 0 then
										data[p_pos] = hatch
										if x1 > 0 then
											param2_data[p_pos] = 2
										else
											param2_data[p_pos] = 3
										end
									end
									if z1 * z1 == 9 and x1 == 0 then
										data[p_pos] = hatch
										if z1 > 0 then
											param2_data[p_pos] = 4
										else
											param2_data[p_pos] = 5
										end
									end
								end
								if x1 % 16 == 0 and x1 * x1 > ss_sphere_sqr + 16 then
									if z1 * z1 == 9 and y1 == 0 then
										data[p_pos] = hatch
										if z1 > 0 then
											param2_data[p_pos] = 4
										else
											param2_data[p_pos] = 5
										end
									end
									if y1 * y1 == 9 and z1 == 0 then
										data[p_pos] = hatch
										if y1 > 0 then
											param2_data[p_pos] = 0
										else
											param2_data[p_pos] = 1
										end
									end
								end
							end
						end
			   		end
				end
      		   	end
   	   	end
		vm:set_data(data)
		vm:set_param2_data(param2_data)
		vm:write_to_map()
		vm:calc_lighting()
	end
end)
