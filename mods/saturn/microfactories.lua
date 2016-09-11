local register_node_with_stats = saturn.register_node_with_stats

saturn.input_item_to_microfactory_map = {}
saturn.microfactory_to_output_item_map = {}
-- With small changes functions and objects taken from tenplus1/protector mod
local pos_to_block_pos = function(pos)
    return {
	x=pos.x - (pos.x % 16),
	y=pos.y - (pos.y % 16),
	z=pos.z - (pos.z % 16)}
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

saturn.position_protected_from = function(pos_min,pos_max, digger_name)
    local wap_poss = minetest.find_nodes_in_area(pos_min, pos_max, {"saturn:world_anchor_protector"})
    for n = 1, #wap_poss do
	local meta = minetest.get_meta(wap_poss[n])
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
    local pos_min = {
	x=pos.x - (pos.x % 16),
	y=pos.y - (pos.y % 16),
	z=pos.z - (pos.z % 16)}
    local pos_max = {
	x=pos_min.x + 16,
	y=pos_min.y + 16,
	z=pos_min.z + 16}
    if saturn.position_protected_from(pos_min,pos_max, name) then
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
		local meta = minetest.get_meta(pos)
		minetest.forceload_free_block(pos)
		saturn.players_info[meta:get_string("owner")]['forceload_pos']=nil
	end,
	on_punch = function(pos, node, puncher)
		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end
		minetest.add_entity(vector.add(pos_to_block_pos(pos),8), "saturn:display")
	end,
	weight = 8000,
	volume = 1,
	price = 1000,
	single_per_player = true,
})

register_node_with_stats("saturn:torch", {
	description = "Torch",
	drawtype = "mesh",
	mesh = "saturn_torch.b3d",
	tiles = {"saturn_torch.png", 
		"saturn_torch.png", 
		"saturn_torch.png", 
		"saturn_torch.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	groups = {cracky = 3},
	sunlight_propagates = true,
	walkable = false,
	light_source = 14,
	weight = 100,
	volume = 0.3,
	price = 10,
})


table.insert(saturn.microfactory_market_items, "saturn:world_anchor_protector")
table.insert(saturn.microfactory_market_items, "saturn:torch")

local get_node_power = function(pos)
	local node_name = minetest.get_node(pos).name
	local meta = minetest.get_meta(pos)
	local rated_power = meta:get_int("rated_power")
	local generated_power = meta:get_int("generated_power")
	local stats = minetest.registered_items[node_name]
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
	local net_id = meta:get_string("microfactory_net_id")
	local last_net_id = net_id
	if net_id ~= "" then
		table.insert(microfactory_list,net_id)
	end
	-- Check all nodes around. Whenever they are microfactories they will have net_id~=0. Whatever founded will be added to list.
	for i=1,5 do
		pos.x = _pos.x + dxyz[i]
		pos.y = _pos.y + dxyz[i+1]
		pos.z = _pos.z + dxyz[i+2]
		meta = minetest.get_meta(pos)
		net_id = meta:get_string("microfactory_net_id")
		if net_id~= "" then
			table.insert(microfactory_list,net_id)
			if last_net_id ~= "" and last_net_id ~= net_id then
				all_mf_have_same_id = false
			end
			last_net_id = net_id
		end
	end
	-- First case - no microfactories around. Generate new net_id.
	if #microfactory_list == 0 then
		last_net_id = tostring(_pos.x * 31000 * 31000 + _pos.y * 31000 + _pos.z)
		meta = minetest.get_meta(_pos)
		meta:set_string("microfactory_net_id",last_net_id)
		saturn.microfactory_nets[last_net_id] = {}
		saturn.microfactory_nets[last_net_id].pos_list = {}
		table.insert(saturn.microfactory_nets[last_net_id].pos_list,_pos)
		saturn.microfactory_nets[last_net_id].energy = get_node_power(_pos)
	-- Second case - only one microfactory or they all have same id. Connect to existing net.
	elseif all_mf_have_same_id then
		meta = minetest.get_meta(_pos)
		meta:set_string("microfactory_net_id",last_net_id)
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
					meta:set_string("microfactory_net_id",last_net_id)
				end
				saturn.microfactory_nets[net_id_i].pos_list = nil
				saturn.microfactory_nets[net_id_i].energy = nil
				saturn.microfactory_nets[net_id_i] = nil
			end
		end
		meta = minetest.get_meta(_pos)
		meta:set_string("microfactory_net_id",last_net_id)
		table.insert(saturn.microfactory_nets[last_net_id].pos_list,_pos)
		saturn.microfactory_nets[last_net_id].energy = saturn.microfactory_nets[last_net_id].energy + get_node_power(_pos)
	end
	for _,i_pos in ipairs(saturn.microfactory_nets[last_net_id].pos_list) do
		local node_def = minetest.registered_nodes[minetest.get_node(i_pos).name]
		if node_def then
			if node_def['on_net_form'] then
				node_def.on_net_form(i_pos, last_net_id)
			end
		end
	end
end

local reform_net = function(_pos)
	local meta = minetest.get_meta(_pos)
	local net_id = meta:get_string("microfactory_net_id")
	if net_id ~= 0 and saturn.microfactory_nets[net_id] then
		-- Step 1 - destroy net.
		for _,i_pos in ipairs(saturn.microfactory_nets[net_id].pos_list) do
			meta = minetest.get_meta(i_pos)
			meta:set_string("microfactory_net_id","")
		end
		saturn.microfactory_nets[net_id].energy = 0
		-- Step 2 - relaunch net formation, excluding current position.
		for _,i_pos in ipairs(saturn.microfactory_nets[net_id].pos_list) do
			if i_pos.x ~= _pos.x or i_pos.y ~= _pos.y or i_pos.z ~= _pos.z then
				form_or_connect_to_net(i_pos)
			end
		end
	end
end

local get_microfactory_generator_formspec = function(pos, net_id)
	local meta = minetest.get_meta(pos)
	local power = meta:get_int("generated_power")
	local total_power = saturn.microfactory_nets[net_id].energy
	local formspec = "size[8,5.25]"..
	saturn.get_main_inventory_formspec(nil,1.25)..
	"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";generator_slot;0,0;1,1;]"..
	"label[1,0;Generated power: "..string.format('%.1f',power).." MW]"..
	"label[1,0.2;Free net power: "..string.format('%.1f',total_power).." MW]"
	return formspec
end


local on_microfactory_generator_metadata_inventory_put = function(pos, listname, index, stack, player)
	if listname == "generator_slot" then
		local stack_generated_power = saturn.get_item_stat(stack,"generated_power",0)
		if stack_generated_power ~= 0 then
			local meta = minetest.get_meta(pos)
			local old_power = meta:get_int("generated_power")
			meta:set_int("generated_power", stack_generated_power)
			local net_id = meta:get_string("microfactory_net_id")
			local old_energy = saturn.microfactory_nets[net_id].energy
			saturn.microfactory_nets[net_id].energy = old_energy + stack_generated_power
			minetest.get_node_timer(pos):start(10)
			for _,i_pos in ipairs(saturn.microfactory_nets[net_id].pos_list) do
				local node_def = minetest.registered_nodes[minetest.get_node(i_pos).name]
				if node_def then
					if node_def['on_net_power_change'] then
						node_def.on_net_power_change(i_pos, net_id)
					end
				end
			end
		end
	end
end

local on_microfactory_generator_metadata_inventory_take = function(pos, listname, index, stack, player)
	if listname == "generator_slot" then
		local stack_generated_power = saturn.get_item_stat(stack,"generated_power",0)
		if stack_generated_power ~= 0 then
			local meta = minetest.get_meta(pos)
			local old_power = meta:get_int("generated_power")
			meta:set_int("generated_power", 0)
			local net_id = meta:get_string("microfactory_net_id")
			local old_energy = saturn.microfactory_nets[net_id].energy
			saturn.microfactory_nets[net_id].energy = old_energy - stack_generated_power
			for _,i_pos in ipairs(saturn.microfactory_nets[net_id].pos_list) do
				local node_def = minetest.registered_nodes[minetest.get_node(i_pos).name]
				if node_def then
					if node_def['on_net_power_change'] then
						node_def.on_net_power_change(i_pos, net_id)
					end
				end
			end
		end
	end
end

local on_generator_node_timer = function(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	for listpos,stack in pairs(inv:get_list("generator_slot")) do
		if stack ~= nil and not stack:is_empty() then
			local stack_generated_power = saturn.get_item_stat(stack,"generated_power",0)
			if stack_generated_power ~= 0 then
				stack:add_wear(elapsed * saturn.MAX_ITEM_WEAR / saturn.get_item_stat(stack,"max_wear",saturn.MAX_ITEM_WEAR))
				if stack:is_empty() then
					local old_power = meta:get_int("generated_power")
					meta:set_int("generated_power", 0)
					local net_id = meta:get_string("microfactory_net_id")
					local old_energy = saturn.microfactory_nets[net_id].energy
					saturn.microfactory_nets[net_id].energy = old_energy - stack_generated_power
					for _,i_pos in ipairs(saturn.microfactory_nets[net_id].pos_list) do
						local node_def = minetest.registered_nodes[minetest.get_node(i_pos).name]
						if node_def then
							if node_def['on_net_power_change'] then
								node_def.on_net_power_change(i_pos, net_id)
							end
						end
					end
					return false
				else
					inv:set_stack("generator_slot", listpos, stack)
				end
			end
		end
	end
	return true
end

register_node_with_stats("saturn:microfactory_power_generator", {
	description = "Microfactory power generator",
	tiles = "saturn_microfactory_power_generator.png",
	groups = {cracky = 3},
--	on_load = function(pos)

--	end,
	on_net_form = function(pos, net_id)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",get_microfactory_generator_formspec(pos, net_id))
	end,
	on_net_power_change = function(pos, net_id)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",get_microfactory_generator_formspec(pos, net_id))
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('generator_slot', 1)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		form_or_connect_to_net(pos)
		local meta = minetest.get_meta(pos)
		local net_id = meta:get_string("microfactory_net_id")
		meta:set_string("formspec",get_microfactory_generator_formspec(pos, net_id))
		minetest.get_node_timer(pos):start(10)
	end,
	on_destruct = function (pos)
		reform_net(pos)
	end,
	on_punch = function(pos, node, puncher)
	end,
	can_dig = function(pos, player)
		return not minetest.is_protected(pos, player:get_player_name())
	end,
	on_timer = on_generator_node_timer,
        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		else
			return count
		end
	end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		else
			return stack:get_count()
		end
	end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		else
			return stack:get_count()
		end
	end,
        on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		--Do nothing
	end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
		on_microfactory_generator_metadata_inventory_put(pos, listname, index, stack, player)
	end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
		on_microfactory_generator_metadata_inventory_take(pos, listname, index, stack, player)
	end,
	weight = 8000,
	volume = 1,
	price = 200,
	is_microfactory = true,
})

local microfactory_formspec = function(pos, progress, cycle_time, energy_fail)
	local minutes_left = math.floor((cycle_time - progress)/60)
	local seconds_left = cycle_time - progress - minutes_left*60
	local timer_frame_number = math.floor(progress*29/cycle_time)
	local formspec = "size[8,9.75]"..
	saturn.get_main_inventory_formspec(nil,5.75)..
	"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";src;0,0;1,4;]"..
	"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";dst;6,0;2,4;]"..
	"image[3,1;2,2;saturn_timer_frames.png^[verticalframe:29:"..timer_frame_number.."]"..
	"label[3.6,1.5;"..string.format('%02d',minutes_left)..":"..string.format('%02d',seconds_left).."]"..
	"image_button[1,3;1,1;saturn_settings_button_icon.png;settings;]"
	if energy_fail then
		formspec = formspec.."label[2,3;Not enought energy to operate!]"
	end
	return formspec
end

local get_microfactory_formspec = function(pos, node)
	local meta = minetest.get_meta(pos)
	local cycle_time = minetest.registered_items[node.name].cycle_time
	local progress = meta:get_int("progress")
	local net_id = meta:get_string("microfactory_net_id")
	return microfactory_formspec(pos, progress, cycle_time, saturn.microfactory_nets[net_id].energy<0)
end

local request_primary_products = function(meta, node_name, net_id)
	-- Check all not disabled recipes.
	local output_list = saturn.microfactory_to_output_item_map[node_name]
	for _,output_item in ipairs(output_list) do
		local output_quantityless = string.gsub(output_item,"[%d ]","") -- Just in case this is real stack
		if meta:get_int(output_quantityless) == 0 then -- Only if recipe is not disabled
			local r_input = minetest.get_craft_recipe(output_quantityless)
			for _,stack in ipairs(r_input.items) do
				-- if there is no necessary stack in 'src' list, search one in a net.
				if not meta:get_inventory():contains_item("src", stack) then
					for _,pos in ipairs(saturn.microfactory_nets[net_id].pos_list) do
						local inv_ref_net = minetest.get_meta(pos):get_inventory()
						if inv_ref_net:contains_item("dst", stack) then
							inv_ref_net:remove_item("dst", stack)
							meta:get_inventory():add_item("src", stack)
							return true
						end
					end
				end
			end
		end
	end
	return false
end

local on_microfactory_node_timer = function(pos,elapsed)
	-- Check power. If power balance lower than 0, schedule next check in 1 minute later.
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local node_name = node.name
	local cycle_time = minetest.registered_items[node_name].cycle_time
	local progress = meta:get_int("progress")
	local net_id = meta:get_string("microfactory_net_id")
	if saturn.microfactory_nets[net_id].energy < 0 then
		meta:set_string("formspec", get_microfactory_formspec(pos, node))
		return true
	end
	-- Check input slot if its possible to process something from it.
	local input_items_list = meta:get_inventory():get_list("src")
	table.insert(input_items_list,	ItemStack(node_name))
	local output, input_result = minetest.get_craft_result({method="shapeless", width=1, items=input_items_list})
	if output.item:is_empty() then
		meta:set_int("progress", 0)
		request_primary_products(meta, node_name, net_id)
		return true
	elseif meta:get_int(string.gsub(output.item:get_name(),"[%d ]",""))>0 then
		return true
	else
		local r_input = minetest.get_craft_recipe(output.item:get_name()) -- r_input.items is STRING list
		for _,stack in ipairs(r_input.items) do
			if stack ~= node_name and not meta:get_inventory():contains_item("src", stack) then
				meta:set_int("progress", 0)
				request_primary_products(meta, node_name, net_id)
				return true
			end
		end
		if progress > 0 then
			if progress >= cycle_time then
				for _,stack in ipairs(r_input.items) do
					meta:get_inventory():remove_item("src", stack)
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
	end
	meta:set_string("formspec", get_microfactory_formspec(pos, node))
	return true
end

local saturn_recipe_info_inventory = minetest.create_detached_inventory("saturn_recipe_info_inventory", {
        allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
        allow_put = function(inv, listname, index, stack, player)
		return 0
	end,
        allow_take = function(inv, listname, index, stack, player)
		return 0
	end,
})

saturn.recipe_info_inventory = saturn_recipe_info_inventory
for i=1,9 do
	saturn_recipe_info_inventory:set_size('src_'..i, 4)
	saturn_recipe_info_inventory:set_size('dst_'..i, 6)
end

local get_recipe_info_formspec_with_vertical_offset = function(recipe_number, input, output_item, is_recipe_disabled)
	local vertical_offset = (recipe_number - 1)  * 1.5 + 0.4
	local input_items = input.items
	table.remove(input_items , #input_items)
	saturn_recipe_info_inventory:set_list('src_'..recipe_number, input_items)
	if ItemStack(output_item):is_known() then
		saturn_recipe_info_inventory:set_list('dst_'..recipe_number, {output_item})
	else
		saturn_recipe_info_inventory:set_list('dst_'..recipe_number, saturn.recipe_outputs[output_item])
	end
	local formspec = "checkbox[0,"..(0.75+vertical_offset)..";disable_recipe_"..output_item..";disable recipe;"..
		tostring(is_recipe_disabled).."]"..
		"box[0.25,"..(1.05+vertical_offset)..";1.55,0.3;#000]"..
		"image[0,"..(1.35+vertical_offset)..";8,0.05;saturn_horizontal_line.png]"..
		"image[4,"..(vertical_offset)..";1,1;saturn_green_right_arrow_icon.png]"..
		"list[detached:saturn_recipe_info_inventory;src_"..recipe_number..";0,"..vertical_offset..";4,1;]"..
		"list[detached:saturn_recipe_info_inventory;dst_"..recipe_number..";5,"..vertical_offset..";4,1;]"
	for ix = 1, 4 do
		formspec = formspec.."image_button["..(ix-0.19)..","..(vertical_offset)..";0.3,0.4;saturn_info_button_icon.png;item_info_detached+saturn_recipe_info_inventory+src_"..recipe_number.."+"..(ix)..";]"..
			"image_button["..(ix+4.81)..","..(vertical_offset)..";0.3,0.4;saturn_info_button_icon.png;item_info_detached+saturn_recipe_info_inventory+dst_"..recipe_number.."+"..(ix)..";]"
	end
	return formspec
end

local get_microfactory_crafts_info_formspec = function(pos)
	local formspec = "size[9,9.75]"..
		saturn.get_color_formspec_frame(-0.2,-0.2,9.4,10.4,"#000000",0.05)..
		"bgcolor[#FFFFFF69;false]"..
		"listcolors[#00000069;#00000000;#000000;#30434C;#FFF]"..
		"image_button[7.5,0.1;1.5,0.4;saturn_back_button_icon.png;ii_return;Back  ;false;false;saturn_back_button_icon.png]"
	local node_name = minetest.get_node(pos).name
	local output_list = saturn.microfactory_to_output_item_map[node_name]
	if output_list then
		local meta = minetest.get_meta(pos)
		for i,output in ipairs(output_list) do
			local output_quantityless = string.gsub(output,"[%d ]","")
			local input = minetest.get_craft_recipe(output_quantityless)
			local is_disabled = meta:get_int(output_quantityless)>0
			local r_info = get_recipe_info_formspec_with_vertical_offset(i, input, output, is_disabled)
			formspec = formspec .. r_info
		end
	end
	return formspec
end

local on_microfactory_receive_fields = function(pos, formname, fields, sender)
	if minetest.is_protected(pos, sender:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	if fields.ii_return or fields.quit then
		meta:set_string("formspec", get_microfactory_formspec(pos, minetest.get_node(pos)))
		minetest.get_node_timer(pos):start(1.0)
	elseif fields.settings then
		minetest.get_node_timer(pos):stop()
		meta:set_string("formspec", get_microfactory_crafts_info_formspec(pos))
	else
		for key,v in pairs(fields) do
			local output, match = string.gsub(key, "^disable_recipe_", "")
			if match == 1 and output then
				local output_quantityless = string.gsub(output,"[%d ]","")
				local old_is_disabled = meta:get_int(output_quantityless)
				meta:set_int(output_quantityless,math.abs(old_is_disabled-1))
				meta:set_string("formspec", get_microfactory_crafts_info_formspec(pos))
				return
			else
				local item_stack_location, match = string.gsub(key, "^item_info_", "")
				if match == 1 and item_stack_location then
					local item_stack_location_data = string.split(item_stack_location, "+", false, -1, false)
					local inventory_type = item_stack_location_data[1]
					local inventory_name = item_stack_location_data[2]
					local inventory_list_name = item_stack_location_data[3]
					local inventory_slot_number = tonumber(item_stack_location_data[4])
					local inventory = minetest.get_inventory({type=inventory_type, name=inventory_name})
					local item_stack = inventory:get_stack(inventory_list_name, inventory_slot_number)
					if not item_stack:is_empty() then
						meta:set_string("formspec", saturn.get_item_info_formspec(item_stack))
						return
					end
				end
			end
		end
	end

end

local register_microfactory = function(name, _description, texture, _rated_power, _price)
    register_node_with_stats(name, {
	description = _description,
	tiles = texture,
	groups = {cracky = 3},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('src', 4)
		inv:set_size('dst', 8)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		form_or_connect_to_net(pos)
		minetest.get_node_timer(pos):start(1.0)
		meta:set_string("formspec", get_microfactory_formspec(pos, minetest.get_node(pos)))
	end,
	on_destruct = function (pos)
		reform_net(pos)
	end,
	on_timer = on_microfactory_node_timer,
	can_dig = function(pos, player)
		return not minetest.is_protected(pos, player:get_player_name())
	end,
        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		else
			return count
		end
	end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		else
			return stack:get_count()
		end
	end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		else
			return stack:get_count()
		end
	end,
        on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
	end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
	end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
	end,
	on_receive_fields = on_microfactory_receive_fields,
	rated_power = _rated_power,
	weight = 2000,
	volume = 1,
	price = _price,
	is_microfactory = true,
	cycle_time = 60.0,
    })

end

register_microfactory("saturn:microfactory_fluid_purificator", 
	"Microfactory fluid purificator", 
	"saturn_microfactory_fluid_purificator.png", 
	2, -- Rated power
	500) -- Price

register_microfactory("saturn:microfactory_liquid_phase_chemical_reactor", 
	"Microfactory liquid phase chemical reactor", 
	"saturn_microfactory_liquid_phase_chemical_reactor.png", 
	0.5, -- Rated power
	400) -- Price

register_microfactory("saturn:microfactory_catalytic_oxydizer", 
	"Microfactory catalytic oxydizer", 
	"saturn_microfactory_catalytic_oxydizer.png", 
	0.5, -- Rated power
	400) -- Price

register_microfactory("saturn:microfactory_hydroponic_farm", 
	"Microfactory hydroponic farm", 
	"saturn_microfactory_hydroponic_farm.png", 
	0.25, -- Rated power
	500) -- Price

register_microfactory("saturn:microfactory_ion_separator", 
	"Microfactory ion separator", 
	"saturn_microfactory_ion_separator.png", 
	4, -- Rated power
	600) -- Price

register_microfactory("saturn:microfactory_ion_exchange_resin_chamber", 
	"Microfactory ion_exchange resin chamber", 
	"saturn_microfactory_ion_exchange_resin_chamber.png", 
	0.5, -- Rated power
	500) -- Price


local register_microfactory_craft = function(craft_device, _recipe, _output)
	for _,item in ipairs(_recipe) do
		local item_name_no_quantity = string.gsub(item,"[%d ]","")
		if not saturn.input_item_to_microfactory_map[item_name_no_quantity] then
			saturn.input_item_to_microfactory_map[item_name_no_quantity] = {}
		end
		table.insert(saturn.input_item_to_microfactory_map[item_name_no_quantity],craft_device)
	end
	table.insert(_recipe,craft_device)
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
	if not saturn.microfactory_to_output_item_map[craft_device] then
		saturn.microfactory_to_output_item_map[craft_device] = {}
	end
	table.insert(saturn.microfactory_to_output_item_map[craft_device],item_stack_output)
end

minetest.register_lbm({
        name = "saturn:load_microfactory_nets",
        nodenames = saturn.microfactory_market_items,
        run_at_every_load = true,
        action = function(pos, node)
		local node_def = minetest.registered_nodes[node.name]
		local meta = minetest.get_meta(pos)
		local net_id = meta:get_string("microfactory_net_id")
		if net_id~="" then
			if node_def['on_load'] then
				node_def:on_load(pos)
			end
			if saturn.microfactory_nets[net_id] then
				saturn.microfactory_nets[net_id].energy = saturn.microfactory_nets[net_id].energy + get_node_power(pos)
				table.insert(saturn.microfactory_nets[net_id].pos_list,pos)
			else
				saturn.microfactory_nets[net_id] = {}
				saturn.microfactory_nets[net_id].pos_list = {}
				saturn.microfactory_nets[net_id].energy = get_node_power(pos)
				table.insert(saturn.microfactory_nets[net_id].pos_list,pos)
			end
		end
	end,
})

register_microfactory_craft("saturn:microfactory_fluid_purificator", 
	{"saturn:water_ice"}, 
	{"saturn:clean_water 80",
	"saturn:heavy_water 1",
	"saturn:silicate_mix 8"})

register_microfactory_craft("saturn:microfactory_fluid_purificator", 
	{"saturn:carbon_oxides_ice"}, 
	{"saturn:amorphous_carbon 20",
	"saturn:carbon_dioxide 60",
	"saturn:silicate_mix 10"})

register_microfactory_craft("saturn:microfactory_fluid_purificator", 
	{"saturn:phosphine_clathrate"}, 
	{"saturn:phosphine 55",
	"saturn:orthophosphoric_acid 15",
	"saturn:silicate_mix 3"})

register_microfactory_craft("saturn:microfactory_fluid_purificator", 
	{"saturn:hydrogen_sulphide_ice"}, 
	{"saturn:hydrogen_sulphide 45",
	"saturn:sulphur 15",
	"saturn:clean_water 15",
	"saturn:sulphide_salts_mix 10"})

register_microfactory_craft("saturn:microfactory_liquid_phase_chemical_reactor",
	{"saturn:clean_water 80",
           "saturn:nitrile_ice"}, 
	{"saturn:acetic_acid 20",
	"saturn:formic_acid 60",
	"saturn:ammonia 90"})

register_microfactory_craft("saturn:microfactory_liquid_phase_chemical_reactor",
	{"saturn:ammonia 10",
           "saturn:nitric_acid 10"},
	{"saturn:ammonia_nitrate 20"})

register_microfactory_craft("saturn:microfactory_liquid_phase_chemical_reactor",
	{"saturn:orthophosphoric_acid 2",
	"saturn:sulphuric_acid 1",
	"saturn:sodiumless_lithiumless_alkali_solution 4",
	"saturn:ammonia_nitrate 8"},
	{"saturn:complex_fertilizer 15"})

register_microfactory_craft("saturn:microfactory_catalytic_oxydizer",
	{"saturn:oxygen 15",
           "saturn:ammonia 10"},
	{"saturn:nitric_acid 25"})

register_microfactory_craft("saturn:microfactory_catalytic_oxydizer",
	{"saturn:oxygen 20",
           "saturn:phosphine 10"},
	{"saturn:orthophosphoric_acid 35"})

register_microfactory_craft("saturn:microfactory_catalytic_oxydizer",
	{"saturn:oxygen 20",
           "saturn:hydrogen_sulphide 10"},
	{"saturn:sulphuric_acid 35"})

register_microfactory_craft("saturn:microfactory_ion_separator", -- A product for any silicates should be solution of water solveable metal hydroxides, mix of undissolveable hydroxides and SiO2
	{"saturn:silicate_mix 10",
         "saturn:clean_water 10"},
	{"saturn:alkali_solution 3",
	"saturn:metal_oxides_sludge 3",
	"saturn:silicon_dioxide 8"})

register_microfactory_craft("saturn:microfactory_ion_exchange_resin_chamber",
	{"saturn:alkali_solution 10",
	"saturn:clean_water 10"},
	{"saturn:sodiumless_lithiumless_alkali_solution 5",
	"saturn:sodium_hydroxide 1",
	"saturn:lithium_hydroxide 1"})

register_microfactory_craft("saturn:microfactory_hydroponic_farm",
	{"saturn:carbon_dioxide 20",
	"saturn:clean_water 10",
	"saturn:complex_fertilizer 1"},
	{"saturn:fresh_fruits_and_vegetables 5",
	"saturn:oxygen 10"})
