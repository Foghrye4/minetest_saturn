minetest.register_node("saturn:fog", {
	description = "Enviroment fog",
	drawtype = "glasslike",
	tiles = {"saturn_fog.png"},
	use_texture_alpha = true,
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	post_effect_color = {a = 50, r = 255, g = 250, b = 240},
})

local function register_node_with_stats(registry_name, node_definition, stats)
	node_definition.on_drop = function(itemstack, player, pos)
		minetest.sound_play("saturn_item_drop", {to_player = player:get_player_name()})
		saturn.throw_item(itemstack, player:get_attach(), pos)
		itemstack:clear()
		return itemstack
	end
	local t = node_definition.tiles
	if type(t) == "string" then
		node_definition.tiles = {t,t,t,t,t,t}
	end
	node_definition.wield_image = "null.png"
        node_definition.sounds = {
            dig =  {name="saturn_retractor", gain=0.5},
            --dug = <SimpleSoundSpec>,
        }
	minetest.register_node(registry_name, node_definition)
	saturn.set_item_stats(registry_name, stats)
	if stats.is_market_item then
		table.insert(saturn.market_items, registry_name)
	end
	if stats.is_ore then
		table.insert(saturn.ore_market_items, registry_name)
		saturn.ores[registry_name] = stats
	end
	if stats.is_microfactory then
		table.insert(saturn.microfactory_market_items, registry_name)
	end
end

saturn.register_node_with_stats = register_node_with_stats

register_node_with_stats("saturn:water_ice", {
	description = "Water ice",
	tiles = "saturn_water_ice.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	},{
	weight = 1000, --kg
	volume = 1, --m3
	price = 1.43,
})

register_node_with_stats("saturn:bauxite", {
	description = "Bauxite",
	tiles = "saturn_water_ice.png^saturn_bauxite.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	},{
	weight = 2000,
	volume = 1,
	price = 10,
	noise_offset = -1.1,
	is_ore = true,
})

register_node_with_stats("saturn:ironnickel", {
	description = "Iron nickel",
	tiles = "saturn_ironnickel.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	},{
	weight = 6000,
	volume = 1,
	price = 10,
	noise_offset = -1.1,
	is_ore = true,
})

register_node_with_stats("saturn:gold", {
	description = "Gold",
	tiles = "saturn_water_ice.png^saturn_gold.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	},{
	weight = 18000,
	volume = 1,
	price = 1000,
	noise_offset = -1.5,
	is_ore = true,
})

register_node_with_stats("saturn:pitchblende", {
	description = "Pitchblende",
	tiles = "saturn_pitchblende.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	},{
	weight = 8000,
	volume = 1,
	price = 1000,
	noise_offset = -1.5,
	is_ore = true,
})
