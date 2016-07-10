local register_node_with_stats = saturn.register_node_with_stats

-- With small changes functions and objects taken from tenplus1/protector mod
local pos_to_block_pos = function(pos)
    return {
	x=pos.x - (pos.x % 16),
	y=pos.y - (pos.y % 16),
	z=pos.z - (pos.z % 16),}
end

saturn.get_member_list = function(meta)
	return meta:get_string("members"):split(" ")
end

saturn.set_member_list = function(meta, list)
	meta:set_string("members", table.concat(list, " "))
end

saturn.is_member = function (meta, name)
	for _, n in pairs(saturn.get_member_list(meta)) do
		if n == name then
			return true
		end
	end
	return false
end

saturn.position_protected_from = function(pos, digger_name)
    local pos_min = pos_to_block_pos(pos)
    local pos_max = {
	x=pos_min.x + 16,
	y=pos_min.y + 16,
	z=pos_min.z + 16,}
    local wap_poss = minetest.find_nodes_in_area(pos_min, pos_max, {"saturn:world_anchor_protector"})
    for n = 1, #pos do
	local meta = minetest.get_meta(pos[n])
	local owner = meta:get_string("owner") or ""
	if owner ~= digger_name then
	    if not saturn.is_member(meta, digger_name) then
		return true
	    end
	end
    end
    return false
end

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
    if saturn:position_protected_from(pos, name) then
	return true
    end
    return old_is_protected(pos, name)
end

minetest.register_entity("saturn:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	-- wielditem seems to be scaled to 1.5 times original node size
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"saturn:display_node"},
	timer = 0,

	on_activate = function(self, staticdata)

		-- Xanadu server only
		if (mobs and mobs.entity and mobs.entity == false)
		or not self then
			self.object:remove()
		end
	end,

	on_step = function(self, dtime)

		self.timer = self.timer + dtime

		if self.timer > 5 then
			self.object:remove()
		end
	end,
})

-- Display-zone node, Do NOT place the display as a node,
-- it is made to be used as an entity (see above)

local x = 8
minetest.register_node("saturn:display_node", {
	tiles = {"saturn_cyan_frame.png"},
	use_texture_alpha = true,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- sides
			{-(x+.55), -(x+.55), -(x+.55), -(x+.45), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), (x+.45), (x+.55), (x+.55), (x+.55)},
			{(x+.45), -(x+.55), -(x+.55), (x+.55), (x+.55), (x+.55)},
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), (x+.55), -(x+.45)},
			-- top
			{-(x+.55), (x+.45), -(x+.55), (x+.55), (x+.55), (x+.55)},
			-- bottom
			{-(x+.55), -(x+.55), -(x+.55), (x+.55), -(x+.45), (x+.55)},
			-- middle (surround protector)
			{-.55,-.55,-.55, .55,.55,.55},
		},
	},
	selection_box = {
		type = "regular",
	},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",
})


register_node_with_stats("saturn:world_anchor_protector", {
	description = "World anchor and map block protector",
	tiles = {"saturn_anchor_top.png",  "saturn_anchor_top.png",
	         "saturn_anchor_side.png", "saturn_anchor_side.png",
	         "saturn_anchor_side.png", "saturn_anchor_side.png"},
	groups = {cracky = 3},
	legacy_mineral = true,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local old_pos = saturn.players_info[placer:get_player_name()]['forceload_pos']
		if old_pos then
			minetest.remove_node(old_pos)
		end
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("members", "")
		minetest.forceload_block(pos)
		saturn.players_info[placer:get_player_name()]['forceload_pos']=pos
	end,
	on_destruct = function (pos)
		minetest.forceload_free_block(pos)
		saturn.players_info[placer:get_player_name()]['forceload_pos']=nil
	end,
	on_punch = function(pos, node, puncher)

		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end

		minetest.add_entity(vector.add(pos_to_block_pos(pos),8), "saturn:display")
	end,
	},{
	weight = 8000,
	volume = 1,
	price = 1000,
	noise_offset = -1.5,
	is_microfactory = true,
	single_per_player = true,
})

local get_node_power = function(pos)
	local node_name = minetest.get_node(pos).name
	local meta = minetest.get_meta(pos)
	local rated_power = meta:get_int("rated_power")
	local generated_power = meta:get_int("generated_power")
	local stats = saturn.item_stats[node_name]
	if stats ~= nil then
		if stats['rated_power'] then
			rated_power = rated_power + stats['rated_power']
		end
		if stats['generated_power'] then
			generated_power = generated_power + stats['generated_power']
		end
	end
	return generated_power - rated_power
end

local form_or_connect_to_net = function(_pos)
	local all_mf_have_same_id = true
	local microfactory_list = {}
	local dxyz = {0,1,0,0,-1,0,0}
	local pos = {x=_pos.x,
		y=_pos.y,
		z=_pos.z+1}
	local meta = minetest.get_meta(pos)
	local net_id = meta:get_int("microfactory_net_id")
	local last_net_id = net_id
	if net_id ~= 0 then
		table.insert(microfactory_list,net_id)
	end
	-- Check all nodes around. Whenever they are microfactories they will have net_id~=0. Whatever founded will be added to list.
	for i=1,5 do
		pos.x = _pos.x + dxyz[i]
		pos.y = _pos.y + dxyz[i+1]
		pos.z = _pos.z + dxyz[i+2]
		meta = minetest.get_meta(pos)
		last_net_id = net_id
		net_id = meta:get_int("microfactory_net_id")
		if net_id~=0 then
			table.insert(microfactory_list,net_id)
			if last_net_id ~= 0 and last_net_id ~= net_id then
				all_mf_have_same_id = false
			end
			last_net_id = net_id
		end
	end
	-- First case - no microfactories around. Generate new net_id.
	if #microfactory_list == 0 then
		net_id = _pos.x * 31000 * 31000 + _pos.y * 31000 + _pos.z
		meta = minetest.get_meta(_pos)
		meta:set_int("microfactory_net_id",net_id)
		saturn.microfactory_nets[net_id] = {}
		saturn.microfactory_nets[net_id].pos_list = {}
		table.insert(saturn.microfactory_nets[net_id].pos_list,_pos)
		saturn.microfactory_nets[net_id].energy = saturn.microfactory_nets[net_id].energy + get_node_power(_pos)
	-- Second case - only one microfactory or they all have same id. Connect to existing net.
	elseif all_mf_have_same_id then
		meta = minetest.get_meta(_pos)
		meta:set_int("microfactory_net_id",last_net_id)
		table.insert(saturn.microfactory_nets[last_net_id].pos_list,_pos)
		saturn.microfactory_nets[last_net_id].energy = saturn.microfactory_nets[last_net_id].energy + get_node_power(_pos)
	-- Third case - two or more microfactory nets. Connect them together.
	else
		for _,net_id_i in ipairs(microfactory_list) do
			if net_id_i~=last_net_id then
				for _,i_pos in ipairs(saturn.microfactory_nets[net_id_i].pos_list) do
					table.insert(saturn.microfactory_nets[last_net_id].pos_list,i_pos)
					saturn.microfactory_nets[last_net_id].energy = saturn.microfactory_nets[last_net_id].energy + get_node_power(i_pos)
					meta = minetest.get_meta(i_pos)
					meta:set_int("microfactory_net_id",last_net_id)
				end
				saturn.microfactory_nets[net_id_i].pos_list = nil
				saturn.microfactory_nets[net_id_i].energy = 0
				saturn.microfactory_nets[net_id_i] = nil
			end
		end
		meta = minetest.get_meta(_pos)
		meta:set_int("microfactory_net_id",last_net_id)
		table.insert(saturn.microfactory_nets[last_net_id].pos_list,_pos)
		saturn.microfactory_nets[last_net_id].energy = saturn.microfactory_nets[last_net_id].energy + get_node_power(_pos)
	end
end

local reform_net = function(_pos)
	local meta = minetest.get_meta(_pos)
	local net_id = meta:get_int("microfactory_net_id")
	-- Step 1 - destroy net.
	for _,i_pos in ipairs(saturn.microfactory_nets[net_id].pos_list) do
		meta = minetest.get_meta(i_pos)
		meta:set_int("microfactory_net_id",0)
	end
	saturn.microfactory_nets[net_id].energy = 0
	-- Step 2 - relaunch net formation, excluding current position.
	for _,i_pos in ipairs(saturn.microfactory_nets[net_id].pos_list) do
		if i_pos.x ~= _pos.x or i_pos.y ~= _pos.y or i_pos.z ~= _pos.z then
			form_or_connect_to_net(i_pos)
		end
	end
end

local on_microfactory_generator_metadata_inventory_put = function(pos, listname, index, stack, player)
	if listname == "generator_slot" then
		local stack_generated_power = saturn.get_item_stat(stack,"generated_power",0)
		if stack_generated_power ~= 0 then
			local meta = minetest.get_meta(pos)
			local old_power = meta:get_int("generated_power")
			meta:set_int("generated_power", old_power + stack_generated_power)
			local net_id = meta:get_int("microfactory_net_id")
			saturn.microfactory_nets[net_id].energy = saturn.microfactory_nets[net_id].energy + stack_generated_power
		end
	end
end

local on_microfactory_generator_metadata_inventory_take = function(pos, listname, index, stack, player)
	if listname == "generator_slot" then
		local stack_generated_power = saturn.get_item_stat(stack,"generated_power",0)
		if stack_generated_power ~= 0 then
			local meta = minetest.get_meta(pos)
			local old_power = meta:get_int("generated_power")
			meta:set_int("generated_power", old_power - stack_generated_power)
			local net_id = meta:get_int("microfactory_net_id")
			saturn.microfactory_nets[net_id].energy = saturn.microfactory_nets[net_id].energy - stack_generated_power
		end
	end
end,

register_node_with_stats("saturn:microfactory_power_generator", {
	description = "Microfactory power generator",
	tiles = "saturn_microfactory_power_generator.png",
	groups = {cracky = 3},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		form_or_connect_to_net(pos)
	end,
	on_destruct = function (pos)
		reform_net(pos)
	end,
	on_punch = function(pos, node, puncher)
	end,
        on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if from_list~=to_list then
			--i'm so confused right now
			--on_microfactory_generator_metadata_inventory_put(pos, to_list, to_index, stack, player)
			--on_microfactory_generator_metadata_inventory_take(pos, from_listname, from_index, stack, player)
		end
	end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
		on_microfactory_generator_metadata_inventory_put(pos, listname, index, stack, player)
	end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
		on_microfactory_generator_metadata_inventory_take(pos, listname, index, stack, player)
	end,
	},{
	weight = 8000,
	volume = 1,
	price = 200,
	is_microfactory = true,
})

local microfactory_formspec = function(pos, progress, cycle_time)
	default_formspec = "size[8,9.75]"..
	saturn.get_main_inventory_formspec(player,5.75)..
	"list[contex;src;0,0;1,4;]"..
	"list[contex;dst;7,0;1,4;]"..
	

end

local on_microfactory_node_timer = function(pos,elapsed)
	-- Check power. If power balance lower than 0, schedule next check in 1 minute later.
	local meta = minetest.get_meta(pos)
	local node_name = minetest.get_node(pos).name
	local cycle_time = saturn.item_stats[node_name].cycle_time
	local net_id = meta:get_int("microfactory_net_id")
	if saturn.microfactory_nets[net_id].energy < 0 then
		local timer = minetest.get_node_timer(pos)
		timer:start(60.0)
		return true
	end
	-- Check input slot if its possible to process something from it.
	local input_items_list = meta:get_inventory():get_list("src")
	table.insert(input_items_list,	ItemStack(node_name))
	local output, input_result = minetest.get_craft_result({method="shapeless", width=1, items=input_items_list})
	if output.item:is_empty() then
		meta:set_int("progress", 0)
	else
		local progress = meta:get_int("progress")
		if progress > 0 then
			if progress > cycle_time then
				local r_input = minetest.get_craft_recipe(output.item)
				for _,stack in ipairs(r_input.items) do
					meta:get_inventory():remove_item("src", stack)
				end
				for _,stack in ipairs(input_result.items) do
					meta:get_inventory():add_item("src", stack)
				end
				if output.item:is_known() then
					meta:get_inventory():add_item("dst", output.item)
				else
					for _,stack in ipairs(saturn.recipe_outputs[output.item:get_name()]) do
						meta:get_inventory():add_item("dst", stack)
					end
				end
				meta:set_int("progress", 0)
			else
				meta:set_int("progress", progress + 1)
			end
		else
			meta:set_int("progress", 1)
		end
		timer:start(1.0)
	end
	return true
end

register_node_with_stats("saturn:microfactory_fluid_purificator", {
	description = "Microfactory fluid purificator",
	tiles = "saturn_microfactory_fluid_purificator.png",
	groups = {cracky = 3},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		form_or_connect_to_net(pos)
	end,
	on_destruct = function (pos)
		reform_net(pos)
	end,
	on_punch = function(pos, node, puncher)
	end,
	on_timer = on_microfactory_node_timer,
        on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
	end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
		on_microfactory_generator_metadata_inventory_put(pos, listname, index, stack, player)
	end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
		on_microfactory_generator_metadata_inventory_take(pos, listname, index, stack, player)
	end,
	},{
	weight = 2000,
	volume = 1,
	price = 970,
	is_microfactory = true,
	cycle_time = 60.0,
})

local register_microfactory_craft = function(_recipe, _output)
	local item_stack_output = ""
	if type(_output) == "table" then
		local ro_list = {}
		for _,item_stack_string in ipairs(_output) do
			table.insert(ro_list,ItemStack(item_stack_string))
			item_stack_output = item_stack_output .. string.gsub(string.gsub(item_stack_string,"^saturn:",""),"[%d ]","").."_"
		end
		item_stack_output = "saturn:" .. item_stack_output
		saturn.recipe_outputs[item_stack_output] = ro_list
	else
		item_stack_output = _output	
	end
	minetest.register_craft({
	       type = "shapeless",
	       output = item_stack_output,
	       recipe = _recipe
	   })
end

register_microfactory_craft({
           "saturn:microfactory_fluid_purificator",
           "saturn:water_ice",
       }, {"saturn:clean_water 80",
	"saturn:heavy_water 1",
	"saturn:silicate_mix 8"})
