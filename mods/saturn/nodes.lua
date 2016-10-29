minetest.register_node("saturn:fog", {
	groups = {fog = 3},
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
	toughness = 0,
})

local function register_node_with_stats(registry_name, node_def)
	node_def.on_drop = function(itemstack, player, pos)
		minetest.sound_play("saturn_item_drop", {to_player = player:get_player_name()})
		saturn.throw_item(itemstack, player:get_attach(), pos)
		itemstack:clear()
		return itemstack
	end
	local t = node_def.tiles
	if type(t) == "string" then
		node_def.tiles = {t,t,t,t,t,t}
	end
	node_def.wield_image = "null.png"
        node_def.sounds = {
            dig =  {name="saturn_retractor", gain=0.5},
        }
	minetest.register_node(registry_name, node_def)
	if node_def.is_market_item then
		table.insert(saturn.market_items, registry_name)
	end
	if node_def.is_ore then
		table.insert(saturn.ore_market_items, registry_name)
		saturn.ores[registry_name] = node_def
	end
	if node_def.is_microfactory then
		table.insert(saturn.microfactory_market_items, registry_name)
	end
end

saturn.register_node_with_stats = register_node_with_stats

register_node_with_stats("saturn:water_ice", {
	description = "Water ice",
	tiles = "saturn_water_ice.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	weight = 1000, --kg
	volume = 1, --m3
	price = 1.43,
	toughness = 8,
})

table.insert(saturn.ore_market_items, "saturn:water_ice")

register_node_with_stats("saturn:bauxite", {
	description = "Bauxite",
	tiles = "saturn_water_ice.png^saturn_bauxite.png",
	groups = {cracky = 2},
	legacy_mineral = true,
	weight = 2000,
	volume = 1,
	price = 10,
	noise_offset = -1.1,
	is_ore = true,
	toughness = 8,
})

register_node_with_stats("saturn:ironnickel", {
	description = "Iron nickel",
	tiles = "saturn_ironnickel.png",
	groups = {cracky = 1},
	legacy_mineral = true,
	weight = 6000,
	volume = 1,
	price = 10,
	noise_offset = -1.1,
	is_ore = true,
	toughness = 80,
})

register_node_with_stats("saturn:gold", {
	description = "Gold",
	tiles = "saturn_water_ice.png^saturn_gold.png",
	groups = {cracky = 1},
	legacy_mineral = true,
	weight = 18000,
	volume = 1,
	price = 1000,
	noise_offset = -1.5,
	is_ore = true,
	toughness = 80,
})

register_node_with_stats("saturn:pitchblende", {
	description = "Pitchblende",
	tiles = "saturn_pitchblende.png",
	groups = {cracky = 1},
	legacy_mineral = true,
	weight = 8000,
	volume = 1,
	price = 1000,
	noise_offset = -1.5,
	is_ore = true,
	toughness = 80,
})

register_node_with_stats("saturn:nitrile_ice", { -- Give ammonia and various carboxylic acids with water
	description = "Nitrile ice",
	tiles = "saturn_nitrile_ice.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	weight = 690,
	volume = 1,
	price = 10,
	noise_offset = -1.1,
	is_ore = true,
	toughness = 8,
})

register_node_with_stats("saturn:carbon_oxides_ice", { -- Give some water, carbon dioxide and some amorphic carbon
	description = "Carbon oxides ice",
	tiles = "saturn_carbon_oxides_ice.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	weight = 1500,
	volume = 1,
	price = 10,
	noise_offset = -1.1,
	is_ore = true,
	toughness = 8,
})

register_node_with_stats("saturn:hydrogen_sulphide_ice", { -- Give some hydrogen sulphide and some sulphur
	description = "Hydrogen sulphide ice",
	tiles = "saturn_water_ice.png^saturn_hydrogen_sulphide_ice.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	weight = 1500,
	volume = 1,
	price = 10,
	noise_offset = -1.1,
	is_ore = true,
	toughness = 8,
})


register_node_with_stats("saturn:phosphine_clathrate", { -- Give phosphine, orthophosphoric acid and water
	description = "Phosphine clathrate",
	tiles = "saturn_water_ice.png^saturn_phosphine_clathrate.png",
	groups = {cracky = 3},
	legacy_mineral = true,
	weight = 1200,
	volume = 1,
	price = 60,
	noise_offset = -1.2,
	is_ore = true,
	toughness = 8,
})
