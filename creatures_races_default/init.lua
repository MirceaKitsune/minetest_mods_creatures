-- Default creatures for the Creatures mod

creatures_races_default = {}

-- #1 - Settings | #1 - Misc settings

creatures.player_default = "creatures_races_default:ghost"
creatures.teams_neutral = 0.1
creatures.timer_life = 100
creatures.item_wear = 1000

if creatures_module_items then
	creatures_module_items.count = 5
end

-- #1 - Settings | #2 - Mob formspec

local function formspec(self, clicker)
	if not self.traits_set or not self.names_set then return end

	local name = creatures:player_get(clicker:get_player_name())
	local alliance = creatures:alliance(clicker, self.object)
	local alliance_color = "#FFFFAA"
	if alliance > creatures.teams_neutral then
		alliance_color = "#AAFFAA"
	elseif alliance < -creatures.teams_neutral then
		alliance_color = "#FFAAAA"
	else
		alliance_color = "#FFFFAA"
	end

	local names = "N/A"
	if #self.names > 0 then
		names = ""
		for i, name in pairs(self.names_set) do
			names = names..name.." "
		end
	end

	local alert = "N/A"
	if self.alert then
		alert = self.alert_level
	end

	local info =
		"Name: "..names..","
		.."Health: "..(self.object:get_hp() * 5).."%,"
		..alliance_color.."Alliance: "..alliance..","
		.."Alert: "..alert..","
	if alliance > creatures.teams_neutral then
		info = info
			.."Traits - Attack: "..string.format("%.3f", 1 / self.traits_set.attack_interval)..","
			.."Traits - Intelligence: "..string.format("%.3f", 1 / self.traits_set.decision_interval)..","
			.."Traits - Vision: "..string.format("%.3f", self.traits_set.vision)..","
			.."Traits - Hearing: "..string.format("%.3f", self.traits_set.hearing)..","
			.."Traits - Loyalty: "..string.format("%.3f", self.traits_set.loyalty)..","
			.."Traits - Fear: "..string.format("%.3f", self.traits_set.fear)..","
			.."Traits - Aggressivity: "..string.format("%.3f", self.traits_set.aggressivity)..","
			.."Traits - Determination: "..string.format("%.3f", self.traits_set.determination)
	end

	local formspec =
		"size[6,5]"
		..default.gui_bg
		..default.gui_bg_img
		..default.gui_slots
		.."image[0,0;1,1;"..self.icon.."]"
		.."textlist[1,0;5,4;;"..info..";0;false]"
	-- Possession is possible
	if name == "creatures_races_default:ghost" and not self.actor then
		formspec = formspec.."button_exit[0,4;3,1;possess;Possess]"
		formspec = formspec.."button_exit[3,4;3,1;quit;Exit]"
	-- Special button for rats
	elseif self.name == "creatures_races_default:animal_rat" then
		formspec = formspec.."button_exit[0,4;3,1;rat;Take]"
		formspec = formspec.."button_exit[3,4;3,1;quit;Exit]"
	-- Special button for sheep
	elseif self.name == "creatures_races_default:animal_sheep" then
		formspec = formspec.."button_exit[0,4;3,1;sheep;Shear / Breed]"
		formspec = formspec.."button_exit[3,4;3,1;quit;Exit]"
	-- No special buttons
	else
		formspec = formspec.."button_exit[0,4;6,1;quit;Exit]"
	end

	minetest.show_formspec(clicker:get_player_name(), "creatures:formspec", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "creatures:formspec" then
		local creature = creatures.selected[player]
		if player:get_hp() > 0 and creature.object and vector.distance(player:getpos(), creature.object:getpos()) <= 5 then
			-- Handle possession:
			if fields["possess"] then
				if not creature.actor then
					creatures:mob_to_player(player, creature)
				end
			-- Handle rats:
			elseif fields["rat"] then
				if player:is_player() and player:get_inventory() then
					player:get_inventory():add_item("main", "creatures_races_default:animal_rat")
					creature.object:remove()
				end
			-- Handle sheep:
			elseif fields["sheep"] then
				local item = player:get_wielded_item()
				if item:get_name() == "farming:wheat" then
					if not creature.actor then
						if not minetest.setting_getbool("creative_mode") then
							item:take_item()
							player:set_wielded_item(item)
						end
						creature.actor = true
					elseif creature.naked then
						if not minetest.setting_getbool("creative_mode") then
							item:take_item()
							player:set_wielded_item(item)
						end
						creature.food = (creature.food or 0) + 1
						if creature.food >= 8 then
							creature.food = 0
							creature.naked = false
							creature.object:set_properties({
								textures = {"mobs_sheep.png"},
								mesh = "mobs_sheep.b3d",
							})
						end
					end
					return
				end

				if player:get_inventory() and not creature.naked then
					creature.naked = true
					-- white wool
					if creature.skin == 1 and minetest.registered_items["wool:white"] then
						player:get_inventory():add_item("main", ItemStack("wool:white "..math.random(1,3)))
					-- grey wool
					elseif creature.skin == 2 and minetest.registered_items["wool:grey"] then
						player:get_inventory():add_item("main", ItemStack("wool:grey "..math.random(1,3)))
					-- black wool
					elseif creature.skin == 3 and minetest.registered_items["wool:black"] then
						player:get_inventory():add_item("main", ItemStack("wool:black "..math.random(1,3)))
					end
					creature.object:set_properties({
						textures = {"mobs_sheep_shaved.png"},
						mesh = "mobs_sheep_shaved.b3d",
					})
				end
			end
		end
	end
end)

-- #1 - Settings | #3 - Player formspec

creatures.player_formspec = function(def)
	if minetest.setting_getbool("creative_mode") then
		return nil
	end

	local icon = def.icon
	if not icon or icon == "" then
		icon = "logo.png"
	end

	-- Formspec for ghosts (default)
	local formspec =
		"size[1,1]"
		..default.gui_bg
		..default.gui_bg_img
		..default.gui_slots
		.."image[0,0;1,1;"
		..def.icon.."]"

	-- If this creature has an inventory, use a full formspec instead
	local size_main = def.inventory_main
	local size_craft = def.inventory_craft
	if minetest.setting_getbool("inventory_crafting_full") then
		size_craft = {x = 3, y = 3}
	end

	if size_main.x > 1 or size_main.y > 1 or size_craft.x > 1 or size_craft.y > 1 then
		local size = {}
		size.x = math.max(size_main.x, (size_craft.x + 3))
		size.y = size_main.y + size_craft.y + 1.25
		formspec =
			"size["..size.x..","..size.y.."]"
			..default.gui_bg
			..default.gui_bg_img
			..default.gui_slots
			.."image_button_exit[0,0;1,1;"..icon..";exorcise;]"
			.."list[current_player;craft;"..(size.x - size_craft.x - 2)..",0;"..size_craft.x..","..size_craft.y..";]"
			.."list[current_player;craftpreview;"..(size.x - 1)..","..math.floor(size_craft.y / 2)..";1,1;]"
			.."list[current_player;main;"..(size.x - size_main.x)..","..(size_craft.y + 1)..";"..size_main.x..",1;]"
			.."list[current_player;main;"..(size.x - size_main.x)..","..(size_craft.y + 2.25)..";"..size_main.x..","..(size_main.y - 1)..";"..size_main.x.."]"
		for i = 0, size_main.x - 1, 1 do
			formspec = formspec.."image["..(size.x - size_main.x + i)..","..(size_craft.y + 1)..";1,1;gui_hb_bg.png]"
		end
	end

	-- Return the formspec string
	return formspec
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "" then
		-- Handle exorcization:
		if fields["exorcise"] then
			creatures:player_to_mob(player)
		end
	end
end)

-- #1 - Settings | #4 - Nodes, items, functions

local nodes_human_male = {
	-- go to bed if it's dark
	{
		nodes = {"group:bed"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		stay = true,
		priority = 0.75,
	},
	-- interact with functional nodes (chests, furnaces, etc) if it's not midday
	{
		nodes = {"default:chest", "default:chest_locked", "default:furnace", "default:furnace_active", "default:sign_wall", "default:bookshelf", "group:door"},
		light_min = 7,
		light_max = 14,
		objective = "follow",
		priority = 0.5,
	},
	-- do some farming if it's midday
	{
		nodes = {"group:field"},
		light_min = 15,
		light_max = 15,
		objective = "follow",
		priority = 0.5,
	},
	-- wander around idly
	{
		nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 7,
		light_max = 15,
		objective = "follow",
		priority = 0.1,
	},
}

local nodes_human_female = {
	-- go to bed if it's dark
	{
		nodes = {"group:bed"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		stay = true,
		priority = 0.75,
	},
	-- interact with functional nodes (chests, furnaces, etc) if it's not midday
	{
		nodes = {"default:chest", "default:chest_locked", "default:furnace", "default:furnace_active", "default:sign_wall", "default:bookshelf", "group:door"},
		light_min = 7,
		light_max = 14,
		objective = "follow",
		priority = 0.5,
	},
	-- do some farming if it's midday
	{
		nodes = {"group:field"},
		light_min = 15,
		light_max = 15,
		objective = "follow",
		priority = 0.5,
	},
	-- wander around idly
	{
		nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 7,
		light_max = 15,
		objective = "follow",
		priority = 0.1,
	},
}

local nodes_anthro_male = nodes_human_male

local nodes_anthro_female = nodes_human_female

local items_all = {
	-- tools this mob possesses
	{
		name = {
			"default:sword_wood", "default:sword_stone", "default:sword_steel", "default:sword_bronze",
			"default:axe_wood", "default:axe_stone", "default:axe_steel", "default:axe_bronze",
			"default:pick_wood", "default:pick_stone", "default:pick_steel", "default:pick_bronze",
			"default:shovel_wood", "default:shovel_stone", "default:shovel_steel", "default:shovel_bronze",
			"farming:hoe_wood", "farming:hoe_stone", "farming:hoe_steel", "farming:hoe_bronze",
		},
		chance = 5,
		count_min = 1,
		count_max = 1,
		wear_min = 0,
		wear_max = 65535 * 0.75, -- 1 / 4 wear max
		metadata = nil,
	},
	-- blocks the mob could have mined
	{
		name = {"default:dirt", "default:stone", "default:cobble", "default:tree", "default:jungletree", "default:pinetree", "default:wood", "default:junglewood", "default:pinewood",},
		chance = 20,
		count_min = 5,
		count_max = 10,
		wear_min = 0,
		wear_max = 0,
		metadata = nil,
	},
	-- materials the mob could have mined
	{
		name = {"default:steel_ingot", "default:bronze_ingot", "default:coal_lump", "default:clay_lump", "default:iron_lump", "default:copper_lump", "default:gold_lump",},
		chance = 10,
		count_min = 5,
		count_max = 10,
		wear_min = 0,
		wear_max = 0,
		metadata = nil,
	},
	-- plants or other farming items
	{
		name = {"default:sapling", "default:junglesapling", "default:pine_sapling", "farming:seed_wheat", "farming:seed_cotton", "farming:wheat",},
		chance = 10,
		count_min = 10,
		count_max = 25,
		wear_min = 0,
		wear_max = 0,
		metadata = nil,
	},
	-- food or other misc items
	{
		name = {"default:apple", "farming:bread", "default:book", "default:stick",},
		chance = 5,
		count_min = 1,
		count_max = 5,
		wear_min = 0,
		wear_max = 0,
		metadata = nil,
	},
}

local items_human_male = items_all

local items_human_female = items_all

local items_anthro_male = items_all

local items_anthro_female = items_all

local alert_all_male = {
	add = -0.01,
	add_friend = -0.05,
	add_foe = 0.5,
	add_punch = 1,
	action_look = 0.25,
	action_walk = 0.5,
	action_run = 0.75,
	action_punch = 0.375,
}

local alert_all_female = {
	add = -0.005,
	add_friend = -0.1,
	add_foe = 0.5,
	add_punch = 1,
	action_look = 0.25,
	action_walk = 0.5,
	action_run = 0.75,
	action_punch = 0.625,
}

-- #1 - Settings | #5 - Outfits and colors

local colors_clothes = {
	"#ff0000", -- red
	"#ffcc00", -- orange
	"#ffff00", -- yellow
	"#00ff00", -- green
	"#00ccff", -- blue
	"#cc00ff", -- purple
	"#ff00ff", -- pink
	"#ffffff", -- white
	"#cccccc", -- gray
	"#000000", -- black
}

local colors_fur = {
	"#ff0000", -- red
	"#ffcc00", -- orange
	"#ffff00", -- yellow
	"#ffffff", -- white
	"#cccccc", -- gray
	"#000000", -- black
}

local colors_eyes = {
	"#ff0000", -- red
	"#ffff00", -- yellow
	"#00ff00", -- green
	"#00ffff", -- cyan
	"#0000ff", -- blue
	"#cc00ff", -- purple
}

local colors_hair = {
	"#ff4444", -- red
	"#ffcc22", -- orange
	"#ffff00", -- yellow
	"#88ffff", -- cyan
	"#2222ff", -- blue
	"#ff44ff", -- pink
	"#ffffff", -- white
	"#000000", -- black
}

local function outfit_human(female)
	local textures = {}

	table.insert(textures, {
		textures = {{"mobs_human_fabric.png"},},
		colors = colors_clothes,
		colors_ratio = 96,
	})

	table.insert(textures, {
		textures = {{"mobs_human_detail_1.png"}, {"mobs_human_detail_2.png"}, {"mobs_human_detail_3.png"},},
	})

	table.insert(textures, {
		textures = {{"mobs_human_eyes.png"},},
		colors = colors_eyes,
		colors_ratio = 128,
	})

	if female then
		table.insert(textures, {
			textures = {{"mobs_human_hair_female_1.png"}, {"mobs_human_hair_female_2.png"}, {"mobs_human_hair_female_3.png"},},
			colors = colors_hair,
			colors_ratio = 128,
		})
	else
		table.insert(textures, {
			textures = {{"mobs_human_hair_male_1.png"}, {"mobs_human_hair_male_2.png"}, {"mobs_human_hair_male_3.png"},},
			colors = colors_hair,
			colors_ratio = 128,
		})
	end

	table.insert(textures, {
		textures = {{"clear.png"}, {"mobs_clothing_1.png"}, {"mobs_clothing_2.png"}, {"mobs_clothing_3.png"},},
	})

	return creatures:outfit(textures)
end

local function outfit_anthro(race, female)
	local textures = {}

	table.insert(textures, {
		textures = {{"mobs_anthro_"..race.."_fur.png"},},
		colors = colors_fur,
		colors_ratio = 96,
	})

	table.insert(textures, {
		textures = {{"mobs_anthro_"..race.."_detail.png"},},
	})

	table.insert(textures, {
		textures = {{"mobs_anthro_"..race.."_eyes.png"},},
		colors = colors_eyes,
		colors_ratio = 128,
	})

	if female then
		table.insert(textures, {
			textures = {{"mobs_anthro_"..race.."_hair.png"},},
			colors = colors_hair,
			colors_ratio = 128,
		})
	end

	table.insert(textures, {
		textures = {{"clear.png"}, {"mobs_clothing_1.png"}, {"mobs_clothing_2.png"}, {"mobs_clothing_3.png"},},
	})

	return creatures:outfit(textures)
end

-- #1 - Settings | #6 - Module functions

-- This area contains local functions which provide shortcuts to all module functions
-- They should be used for sentient mobs (humans, anthros, etc)

local module_custom = {
	-- #1 - Items module
	creatures_module_items = {
		slots = {
			{
				inventory = "main",
				bone = "Arm_Right",
				pos = {x = 0, y = 9, z = 3},
				rot = {x = 90, y = 270, z = 270},
				size = 0.3,
				on_step = nil,
			},
			{
				inventory = "main",
				bone = "Body",
				pos = {x = 2, y = 0, z = -1},
				rot = {x = 0, y = 0, z = 0},
				size = 0.15,
				on_step = nil,
			},
			{
				inventory = "main",
				bone = "Body",
				pos = {x = -2, y = 0, z = -1},
				rot = {x = 0, y = 0, z = 0},
				size = 0.15,
				on_step = nil,
			},
			{
				inventory = "main",
				bone = "Body",
				pos = {x = 2, y = 0, z = 1},
				rot = {x = 0, y = 0, z = 0},
				size = 0.15,
				on_step = nil,
			},
			{
				inventory = "main",
				bone = "Body",
				pos = {x = -2, y = 0, z = 1},
				rot = {x = 0, y = 0, z = 0},
				size = 0.15,
				on_step = nil,
			},
		},
	},
}

local function module_mob_activate (self, staticdata, dtime_s)
	-- #1 - Items module
	if creatures_module_items then
		creatures_module_items:on_activate(self, staticdata, dtime_s)
	end
end

local function module_player_join (player)
	-- #1 - Items module
	if creatures_module_items then
		creatures_module_items:player_join(player)
	end
end

-- #2 - Creatures | #1 - Ghosts

-- The ghost is intended for players only, and should not be spawned as a mob

creatures:register_creature("creatures_races_default:ghost", {
	-- Common properties:
	icon = "mobs_ghost_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.5, 0, -0.5, 0.5, 2, 0.5},
	visual = "sprite",
	mesh = "",
	textures = {"clear.png"},
	particles = nil,
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = nil,
	sounds = {
		random_idle = "creatures_ghost_random", -- must be implemented as a custom function
		attack = "creatures_ghost_attack",
		damage = "creatures_ghost_damage",
		die = "creatures_ghost_die",
	},
	makes_footstep_sound = false,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 1, y = 1},
	inventory_craft = {x = 1, y = 1},
	teams = {monsters = 1, humans = 1, anthropomorphics = 1, animals = 1},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = {},
	nodes = {},
	traits = {
		attack_interval = {1, 1},
		decision_interval = {1, 1},
		vision = {15, 15},
		hearing = {10, 10},
		loyalty = {0.5, 0.5},
		fear = {0.5, 0.5},
		aggressivity = {0.5, 0.5},
		determination = {0.5, 0.5},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = {r = 64, g = 0, b = 128},
	screen = "hud_ghost.png",
	ambience = "creatures_ambient_ghost",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

-- #2 - Creatures | #2 - Humans

creatures:register_creature("creatures_races_default:human_male", {
	-- Common properties:
	icon = "mobs_human_male_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_human.b3d",
	textures = outfit_human(false),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_male_attack",
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.6, humans = 1, anthropomorphics = -0.1, animals = 0},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_human_male,
	nodes = nodes_human_male,
	traits = {
		attack_interval = {0.75, 1.25},
		decision_interval = {1, 2},
		vision = {25, 35},
		hearing = {20, 25},
		loyalty = {0.25, 1},
		fear = {0, 0.5},
		aggressivity = {0.5, 1},
		determination = {0.5, 1},
	},
	names = {
		{"Alex", "Daniel", "Mike", "Sam", "Earl", "Steve", "Charlie", "Claude", "Arnold", "Andrew", "David", "Damian", "Bob", "Tom", "Gabriel", "Walter", "Jerry", "Jake", "Michael", "Nate", "Oliver", "Bubba",},
		{"Wheeler", "Anderson", "Simpson", "Jackson", "Parker", "Adams", "Steven", "Johnson",},
	},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_male,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:human_male", {
	nodes = {"default:dirt", "default:dirt_with_grass", "default:sand", "default:desert_sand", "default:dirt_with_snow", "default:snowblock"},
	neighbors = {"air"},
	interval = 10,
	chance = 16000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:human_female", {
	-- Common properties:
	icon = "mobs_human_female_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_human.b3d",
	textures = outfit_human(true),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_female_attack",
		damage = "creatures_human_female_damage",
		die = "creatures_human_female_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.5, humans = 1, anthropomorphics = -0.1, animals = 0.1},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_human_female,
	nodes = nodes_human_female,
	traits = {
		attack_interval = {1, 1.5},
		decision_interval = {1, 2},
		vision = {25, 35},
		hearing = {20, 25},
		loyalty = {0.5, 1},
		fear = {0.5, 1},
		aggressivity = {0, 0.5},
		determination = {0.5, 1},
	},
	names = {
		{"Ana", "Maria", "Kate", "Michelle", "Sarah", "Mona", "Rose", "Stephanie", "Cleopatra", "Denise",},
		{"Wheeler", "Anderson", "Simpson", "Jackson", "Parker", "Adams", "Steven", "Johnson",},
	},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_female,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:human_female", {
	nodes = {"default:dirt", "default:dirt_with_grass", "default:sand", "default:desert_sand", "default:dirt_with_snow", "default:snowblock"},
	neighbors = {"air"},
	interval = 10,
	chance = 18000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

-- #2 - Creatures | #3 - Anthros

creatures:register_creature("creatures_races_default:anthro_fox_male", {
	-- Common properties:
	icon = "mobs_anthro_fox_male_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("fox", false),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_male_attack",
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.4, humans = -0.1, anthropomorphics = 1, animals = 0.2},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_male,
	nodes = nodes_anthro_male,
	traits = {
		attack_interval = {0.75, 1.25},
		decision_interval = {0.5, 1},
		vision = {20, 30},
		hearing = {25, 30},
		loyalty = {0.75, 1},
		fear = {0.25, 0.75},
		aggressivity = {0.25, 1},
		determination = {0.5, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_male,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_fox_male", {
	nodes = {"default:dirt", "default:dirt_with_grass", "default:sand", "default:desert_sand", "default:dirt_with_snow", "default:snowblock"},
	neighbors = {"air"},
	interval = 10,
	chance = 24000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_fox_female", {
	-- Common properties:
	icon = "mobs_anthro_fox_female_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("fox", true),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_female_attack",
		damage = "creatures_human_female_damage",
		die = "creatures_human_female_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.3, humans = -0.1, anthropomorphics = 1, animals = 0.3},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_female,
	nodes = nodes_anthro_female,
	traits = {
		attack_interval = {1, 1.25},
		decision_interval = {0.5, 1},
		vision = {20, 30},
		hearing = {25, 30},
		loyalty = {0.75, 1},
		fear = {0.25, 1},
		aggressivity = {0, 0.5},
		determination = {0.5, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_female,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_fox_female", {
	nodes = {"default:dirt", "default:dirt_with_grass", "default:sand", "default:desert_sand", "default:dirt_with_snow", "default:snowblock"},
	neighbors = {"air"},
	interval = 10,
	chance = 24000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_wolf_male", {
	-- Common properties:
	icon = "mobs_anthro_wolf_male_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("wolf", false),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_male_attack",
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1.25,
		gravity = 1.25,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.5, humans = -0.2, anthropomorphics = 1, animals = 0.2},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_male,
	nodes = nodes_anthro_male,
	traits = {
		attack_interval = {0.5, 0.75},
		decision_interval = {1.5, 2},
		vision = {25, 35},
		hearing = {25, 30},
		loyalty = {0.75, 1},
		fear = {0.25, 0.5},
		aggressivity = {0.5, 1},
		determination = {0.75, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_male,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_wolf_male", {
	nodes = {"default:dirt_with_snow", "default:snowblock"},
	neighbors = {"air"},
	interval = 10,
	chance = 18000,
	min_height = -31000,
	max_height = 31000,
	min_light = 3,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_wolf_female", {
	-- Common properties:
	icon = "mobs_anthro_wolf_female_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("wolf", true),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_female_attack",
		damage = "creatures_human_female_damage",
		die = "creatures_human_female_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1.25,
		gravity = 1.25,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.4, humans = -0.2, anthropomorphics = 1, animals = 0.3},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_female,
	nodes = nodes_anthro_female,
	traits = {
		attack_interval = {0.5, 0.75},
		decision_interval = {1.5, 2},
		vision = {25, 35},
		hearing = {25, 30},
		loyalty = {0.75, 1},
		fear = {0.25, 0.75},
		aggressivity = {0.25, 0.75},
		determination = {0.75, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_female,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_wolf_female", {
	nodes = {"default:dirt_with_snow", "default:snowblock"},
	neighbors = {"air"},
	interval = 10,
	chance = 20000,
	min_height = -31000,
	max_height = 31000,
	min_light = 3,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_leopard_male", {
	-- Common properties:
	icon = "mobs_anthro_leopard_male_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("leopard", false),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_male_attack",
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1.5,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.6, humans = -0.2, anthropomorphics = 1, animals = 0.2},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_male,
	nodes = nodes_anthro_male,
	traits = {
		attack_interval = {0.25, 0.75},
		decision_interval = {1, 2},
		vision = {30, 40},
		hearing = {30, 40},
		loyalty = {0, 0.5},
		fear = {0.25, 0.75},
		aggressivity = {0.5, 1},
		determination = {0.25, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_male,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_leopard_male", {
	nodes = {"default:sand", "default:desert_sand"},
	neighbors = {"air"},
	interval = 10,
	chance = 20000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_leopard_female", {
	-- Common properties:
	icon = "mobs_anthro_leopard_female_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("leopard", true),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_female_attack",
		damage = "creatures_human_female_damage",
		die = "creatures_human_female_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1.5,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.5, humans = -0.2, anthropomorphics = 1, animals = 0.3},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_female,
	nodes = nodes_anthro_female,
	traits = {
		attack_interval = {0.5, 0.75},
		decision_interval = {1, 2},
		vision = {30, 40},
		hearing = {30, 40},
		loyalty = {0, 0.75},
		fear = {0.5, 0.75},
		aggressivity = {0.25, 0.75},
		determination = {0.25, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_female,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_leopard_female", {
	nodes = {"default:sand", "default:desert_sand"},
	neighbors = {"air"},
	interval = 10,
	chance = 22000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_rabbit_male", {
	-- Common properties:
	icon = "mobs_anthro_rabbit_male_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("rabbit", false),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_male_attack",
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1.5,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.4, humans = 0, anthropomorphics = 1, animals = 0.4},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_male,
	nodes = nodes_anthro_male,
	traits = {
		attack_interval = {1.5, 2},
		decision_interval = {1.5, 2},
		vision = {15, 25},
		hearing = {10, 15},
		loyalty = {0.75, 1},
		fear = {0.5, 1},
		aggressivity = {0, 0.75},
		determination = {0.5, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_male,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_rabbit_male", {
	nodes = {"default:dirt", "default:dirt_with_grass"},
	neighbors = {"air"},
	interval = 10,
	chance = 20000,
	min_height = -31000,
	max_height = 31000,
	min_light = 11,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_rabbit_female", {
	-- Common properties:
	icon = "mobs_anthro_rabbit_female_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("rabbit", true),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_female_attack",
		damage = "creatures_human_female_damage",
		die = "creatures_human_female_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1.5,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.3, humans = 0, anthropomorphics = 1, animals = 0.5},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_female,
	nodes = nodes_anthro_female,
	traits = {
		attack_interval = {1.75, 2},
		decision_interval = {1.5, 2},
		vision = {15, 25},
		hearing = {10, 15},
		loyalty = {0.75, 1},
		fear = {0.75, 1},
		aggressivity = {0, 0.5},
		determination = {0.5, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_female,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_rabbit_female", {
	nodes = {"default:dirt", "default:dirt_with_grass"},
	neighbors = {"air"},
	interval = 10,
	chance = 18000,
	min_height = -31000,
	max_height = 31000,
	min_light = 11,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_squirrel_male", {
	-- Common properties:
	icon = "mobs_anthro_squirrel_male_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("squirrel", false),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_male_attack",
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 0.75,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.4, humans = -0.1, anthropomorphics = 1, animals = 0.2},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_male,
	nodes = nodes_anthro_male,
	traits = {
		attack_interval = {1.25, 1.75},
		decision_interval = {1, 1.5},
		vision = {20, 30},
		hearing = {25, 35},
		loyalty = {0.25, 0.75},
		fear = {0.25, 0.75},
		aggressivity = {0.25, 0.5},
		determination = {0.25, 0.75},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_male,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_squirrel_male", {
	nodes = {"default:leaves", "default:jungleleaves"},
	neighbors = {"air"},
	interval = 10,
	chance = 18000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:anthro_squirrel_female", {
	-- Common properties:
	icon = "mobs_anthro_squirrel_female_icon.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("squirrel", true),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_human_female_attack",
		damage = "creatures_human_female_damage",
		die = "creatures_human_female_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 0.75,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = -0.3, humans = -0.1, anthropomorphics = 1, animals = 0.3},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = items_anthro_female,
	nodes = nodes_anthro_female,
	traits = {
		attack_interval = {1.5, 1.75},
		decision_interval = {1, 1.5},
		vision = {20, 30},
		hearing = {25, 35},
		loyalty = {0.25, 0.75},
		fear = {0.25, 1},
		aggressivity = {0, 0.5},
		determination = {0.25, 0.75},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = alert_all_female,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = module_custom,
})

creatures:register_spawn("creatures_races_default:anthro_squirrel_female", {
	nodes = {"default:leaves", "default:jungleleaves"},
	neighbors = {"air"},
	interval = 10,
	chance = 18000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

-- #2 - Creatures | #4 - Monsters

creatures:register_creature("creatures_races_default:monster_dirt", {
	-- Common properties:
	icon = "mobs_dirt_monster_icon.png",
	hp_max = 5,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_stone_monster.b3d",
	textures = {"mobs_dirt_monster.png"},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 15,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 14, speed = 20, blend = 0, loop = true},
		walk = {x = 15, y = 38, speed = 20, blend = 0, loop = true},
		walk_punch = {x = 40, y = 63, speed = 20, blend = 0, loop = true},
		punch = {x = 40, y = 63, speed = 20, blend = 0, loop = true},
	},
	sounds = {
		random_idle = "creatures_monster_random", -- must be implemented as a custom function
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 1},
		light = 1,
		light_level = 7,
	},
	physics = {
		speed = 0.5,
		jump = 0.75,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	teams = {monsters = 1, humans = -0.4, anthropomorphics = -0.4, animals = 0},

	-- Mob properties:
	think = 1,
	attack_capabilities = {damage_groups = {fleshy = 1}},
	items = {
		{
			name = "default:dirt",
			chance = 1,
			count_min = 3,
			count_max = 5,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
	},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 7,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {1.5, 1.75},
		decision_interval = {3, 4},
		vision = {10, 15},
		hearing = {0, 0},
		loyalty = {0, 0},
		fear = {0, 0.25},
		aggressivity = {0.75, 1},
		determination = {0.35, 0.65},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:monster_dirt", {
	nodes = {"default:dirt", "default:dirt_with_grass"},
	neighbors = {"air"},
	interval = 10,
	chance = 8000,
	min_height = -31000,
	max_height = 31000,
	min_light = 0,
	max_light = 7,
})

creatures:register_creature("creatures_races_default:monster_stone", {
	-- Common properties:
	icon = "mobs_stone_monster_icon.png",
	hp_max = 10,
	armor = {fleshy = 90},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_stone_monster.b3d",
	textures = {"mobs_stone_monster.png"},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 15,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 14, speed = 25, blend = 0, loop = true},
		walk = {x = 15, y = 38, speed = 25, blend = 0, loop = true},
		walk_punch = {x = 40, y = 63, speed = 25, blend = 0, loop = true},
		punch = {x = 40, y = 63, speed = 25, blend = 0, loop = true},
	},
	sounds = {
		random_idle = "creatures_monster_random", -- must be implemented as a custom function
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 0.75,
		jump = 0.5,
		gravity = 1.25,
	},
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	teams = {monsters = 1, humans = -0.8, anthropomorphics = -0.8, animals = -0.2},

	-- Mob properties:
	think = 1,
	attack_capabilities = {damage_groups = {fleshy = 3}},
	items = {
		{
			name = "default:mossycobble",
			chance = 1,
			count_min = 3,
			count_max = 5,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
	},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 7,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {1, 1.25},
		decision_interval = {2, 3},
		vision = {15, 20},
		hearing = {5, 10},
		loyalty = {0, 0.25},
		fear = {0, 0},
		aggressivity = {0.75, 1},
		determination = {0.75, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:monster_stone", {
	nodes = {"default:stone", "default:cobblestone"},
	neighbors = {"air"},
	interval = 10,
	chance = 12000,
	min_height = -31000,
	max_height = 0,
	min_light = 0,
	max_light = 3,
})

creatures:register_creature("creatures_races_default:monster_sand", {
	-- Common properties:
	icon = "mobs_sand_monster_icon.png",
	hp_max = 5,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_sand_monster.b3d",
	textures = {"mobs_sand_monster.png"},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 15,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 39, speed = 20, blend = 0, loop = true},
		walk = {x = 41, y = 72, speed = 20, blend = 0, loop = true},
		walk_punch = {x = 74, y = 105, speed = 20, blend = 0, loop = true},
		punch = {x = 74, y = 105, speed = 20, blend = 0, loop = true},
	},
	sounds = {
		random_idle = "creatures_monster_random", -- must be implemented as a custom function
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 3},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 0.5,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	teams = {monsters = 1, humans = -0.6, anthropomorphics = -0.4, animals = -0.4},

	-- Mob properties:
	think = 1,
	attack_capabilities = {damage_groups = {fleshy = 2}},
	items = {
		{
			name = "default:sand",
			chance = 1,
			count_min = 3,
			count_max = 5,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
	},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 15,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {1.25, 1.5},
		decision_interval = {2.5, 3.5},
		vision = {30, 30},
		hearing = {0, 5},
		loyalty = {0.25, 0.5},
		fear = {0.15, 0.3},
		aggressivity = {0.7, 0.9},
		determination = {0.6, 0.8},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:monster_sand", {
	nodes = {"default:sand", "default:desert_sand"},
	neighbors = {"air"},
	interval = 10,
	chance = 8000,
	min_height = -31000,
	max_height = 31000,
	min_light = 0,
	max_light = 7,
})

creatures:register_creature("creatures_races_default:monster_snow", {
	-- Common properties:
	icon = "mobs_snow_monster_icon.png",
	hp_max = 5,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_sand_monster.b3d",
	textures = {"mobs_snow_monster.png"},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 15,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 39, speed = 25, blend = 0, loop = true},
		walk = {x = 41, y = 72, speed = 25, blend = 0, loop = true},
		walk_punch = {x = 74, y = 105, speed = 25, blend = 0, loop = true},
		punch = {x = 74, y = 105, speed = 25, blend = 0, loop = true},
	},
	sounds = {
		random_idle = "creatures_monster_random", -- must be implemented as a custom function
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 3},
		light = 1,
		light_level = 7,
	},
	physics = {
		speed = 0.75,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	teams = {monsters = 1, humans = -0.6, anthropomorphics = -0.4, animals = 0.2},

	-- Mob properties:
	think = 1,
	attack_capabilities = {damage_groups = {fleshy = 2}},
	items = {
		{
			name = "default:snowblock",
			chance = 1,
			count_min = 3,
			count_max = 5,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
	},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 7,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {1, 1.25},
		decision_interval = {2, 3},
		vision = {15, 20},
		hearing = {5, 10},
		loyalty = {0.3, 0.6},
		fear = {0.1, 0.25},
		aggressivity = {0.5, 0.75},
		determination = {0.5, 0.75},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:monster_snow", {
	nodes = {"default:dirt_with_snow", "default:snowblock"},
	neighbors = {"air"},
	interval = 10,
	chance = 8000,
	min_height = -31000,
	max_height = 31000,
	min_light = 0,
	max_light = 3,
})

creatures:register_creature("creatures_races_default:monster_tree", {
	-- Common properties:
	icon = "mobs_tree_monster_icon.png",
	hp_max = 10,
	armor = {fleshy = 90},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_tree_monster.b3d",
	textures = {"mobs_tree_monster.png"},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 96,
		pos_max_y = 96,
		size_x = 4,
		size_y = 4,
		amount = 15,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 24, speed = 25, blend = 0, loop = true},
		walk = {x = 25, y = 47, speed = 25, blend = 0, loop = true},
		walk_punch = {x = 48, y = 62, speed = 25, blend = 0, loop = true},
		punch = {x = 48, y = 62, speed = 25, blend = 0, loop = true},
	},
	sounds = {
		random_idle = "creatures_monster_random", -- must be implemented as a custom function
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 1},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 0.75,
		jump = 1.5,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	teams = {monsters = 0.8, humans = -0.4, anthropomorphics = 0, animals = 0.6},

	-- Mob properties:
	think = 1,
	attack_capabilities = {damage_groups = {fleshy = 2}},
	items = {
		{
			name = "default:sapling",
			chance = 3,
			count_min = 1,
			count_max = 2,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
		{
			name = "default:junglesapling",
			chance = 3,
			count_min = 1,
			count_max = 2,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
		{
			name = "default:pine_sapling",
			chance = 3,
			count_min = 1,
			count_max = 2,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
	},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 15,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {1, 1.25},
		decision_interval = {2, 2.5},
		vision = {25, 30},
		hearing = {15, 20},
		loyalty = {0.6, 0.8},
		fear = {0.4, 0.6},
		aggressivity = {0.4, 0.8},
		determination = {0.6, 0.8},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:monster_tree", {
	nodes = {"default:leaves", "default:jungleleaves"},
	neighbors = {"air"},
	interval = 10,
	chance = 10000,
	min_height = -31000,
	max_height = 31000,
	min_light = 0,
	max_light = 11,
})

creatures:register_creature("creatures_races_default:monster_oerkki", {
	-- Common properties:
	icon = "mobs_oerkki_icon.png",
	hp_max = 10,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_oerkki.b3d",
	textures = {"mobs_oerkki.png"},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 51,
		pos_max_y = 50,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 23, speed = 40, blend = 0, loop = true},
		walk = {x = 24, y = 36, speed = 40, blend = 0, loop = true},
		walk_punch = {x = 37, y = 49, speed = 40, blend = 0, loop = true},
		punch = {x = 37, y = 49, speed = 40, blend = 0, loop = true},
	},
	sounds = {
		random_idle = "creatures_human_male_attack", -- must be implemented as a custom function
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = false,
	env_damage = {
		groups = {water = 0},
		light = 1,
		light_level = 7,
	},
	physics = {
		speed = 1.25,
		jump = 1.25,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = 0.5, humans = 0.5, anthropomorphics = -0.5, animals = 0.5},

	-- Mob properties:
	think = 1,
	attack_capabilities = {damage_groups = {fleshy = 3}},
	items = {},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 7,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {0.75, 1},
		decision_interval = {1.5, 2.5},
		vision = {15, 25},
		hearing = {10, 20},
		loyalty = {0.25, 0.75},
		fear = {0.2, 0.4},
		aggressivity = {0.4, 0.6},
		determination = {0.4, 0.8},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:monster_oerkki", {
	nodes = {"default:stone"},
	neighbors = {"air"},
	interval = 10,
	chance = 14000,
	min_height = -31000,
	max_height = 0,
	min_light = 0,
	max_light = 7,
})

creatures:register_creature("creatures_races_default:monster_dungeon_master", {
	-- Common properties:
	icon = "mobs_dungeon_master_icon.png",
	hp_max = 10,
	armor = {fleshy = 80},
	collisionbox = {-0.7, -0.01, -0.7, 0.7, 2.6, 0.7},
	visual = "mesh",
	mesh = "mobs_dungeon_master.b3d",
	textures = {"mobs_dungeon_master.png"},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 31,
		pos_max_y = 39,
		size_x = 5,
		size_y = 5,
		amount = 20,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 19, speed = 20, blend = 0, loop = true},
		walk = {x = 20, y = 35, speed = 20, blend = 0, loop = true},
		walk_punch = {x = 20, y = 35, speed = 20, blend = 0, loop = true},
		punch = {x = 36, y = 48, speed = 20, blend = 0, loop = true},
	},
	sounds = {
		random_idle = "creatures_monster_large_random", -- must be implemented as a custom function
		attack = "creatures_fireball",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 0.75,
		jump = 1.25,
		gravity = 1.25,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = 1, humans = -1, anthropomorphics = -1, animals = -0.2},

	-- Mob properties:
	think = 1,
	attack_capabilities = {damage_groups = {fleshy = 4}},
	items = {
		{
			name = "default:mese",
			chance = 50,
			count_min = 1,
			count_max = 2,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
	},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 7,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {2.5, 3},
		decision_interval = {2, 3},
		vision = {15, 20},
		hearing = {25, 30},
		loyalty = {0.3, 0.7},
		fear = {0, 0.25},
		aggressivity = {0.75, 1},
		determination = {0.75, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 5, z = 0}, {x = 0, y = 5, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:monster_dungeon_master", {
	nodes = {"default:stone"},
	neighbors = {"air"},
	interval = 10,
	chance = 18000,
	min_height = -31000,
	max_height = -50,
	min_light = 0,
	max_light = 3,
})

-- #2 - Creatures | #5 - Animals

creatures:register_creature("creatures_races_default:animal_sheep", {
	-- Common properties:
	icon = "mobs_sheep_icon.png",
	hp_max = 5,
	armor = {fleshy = 100},
	collisionbox = {-0.5, -0.01, -0.5, 0.65, 1, 0.5},
	visual = "mesh",
	mesh = "mobs_sheep.b3d",
	textures = {
		{"mobs_sheep_white.png"},
		{"mobs_sheep_grey.png"},
		{"mobs_sheep_black.png"},
	},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 40,
		pos_max_y = 36,
		size_x = 3,
		size_y = 3,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 80, speed = 15, blend = 0, loop = true},
		walk = {x = 81, y = 100, speed = 15, blend = 0, loop = true},
		walk_punch = {x = 81, y = 100, speed = 15, blend = 0, loop = true},
		punch = {x = 81, y = 100, speed = 15, blend = 0, loop = true},
	},
	sounds = {
		random_idle = "creatures_sheep_random", -- must be implemented as a custom function
		damage = "creatures_sheep_damage",
		die = "creatures_sheep_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 0.5,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 1},
	inventory_craft = {x = 1, y = 1},
	teams = {monsters = -0.4, humans = 0.2, anthropomorphics = 0, animals = 1},

	-- Mob properties:
	think = 1.5,
	items = {
		{
			name = "creatures_races_default:meat_raw",
			chance = 1,
			count_min = 2,
			count_max = 3,
			wear_min = 0,
			wear_max = 0,
			metadata = nil,
		},
	},
	nodes = {
		-- eat grass if it's midday
		{
			nodes = {"group:flora"},
			light_min = 15,
			light_max = 15,
			objective = "attack",
			priority = 0.5,
		},
		-- wander around idly
		{
			nodes = {"group:crumbly"},
			light_min = 7,
			light_max = 15,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {2, 3},
		decision_interval = {4, 6},
		vision = {15, 20},
		hearing = {10, 15},
		loyalty = {0.6, 0.8},
		fear = {0.8, 1},
		aggressivity = {0, 0.2},
		determination = {0.4, 0.6},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = -5, z = 0}, {x = 0, y = -5, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:animal_sheep", {
	nodes = {"default:dirt_with_grass"},
	neighbors = {"air"},
	interval = 10,
	chance = 12000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

minetest.register_craftitem("creatures_races_default:meat_raw", {
	description = "Raw Meat",
	inventory_image = "mobs_meat_raw.png",
})

minetest.register_craftitem("creatures_races_default:meat", {
	description = "Meat",
	inventory_image = "mobs_meat.png",
	on_use = minetest.item_eat(8),
})

minetest.register_craft({
	type = "cooking",
	output = "creatures_races_default:meat",
	recipe = "creatures_races_default:meat_raw",
	cooktime = 5,
})

creatures:register_creature("creatures_races_default:animal_rabbit", {
	-- Common properties:
	icon = "mobs_rabbit_icon.png",
	hp_max = 2,
	armor = {fleshy = 100},
	collisionbox = {-0.25, -0.01, -0.25, 0.25, 0.5, 0.25},
	visual = "mesh",
	mesh = "mobs_rabbit.b3d",
	textures = {
		{"mobs_rabbit_white_blue.png"},
		{"mobs_rabbit_white_brown.png"},
		{"mobs_rabbit_white_brown_spots.png"},
		{"mobs_rabbit_gray.png"},
		{"mobs_rabbit_brown.png"},
	},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 2,
		size_y = 2,
		amount = 5,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 60, speed = 25, blend = 0, loop = true},
		walk = {x = 61, y = 80, speed = 25, blend = 0, loop = true},
		walk_punch = {x = 61, y = 80, speed = 25, blend = 0, loop = true},
		punch = {x = 61, y = 80, speed = 25, blend = 0, loop = true},
	},
	sounds = {},
	makes_footstep_sound = true,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 0.75,
	},
	inventory_main = {x = 8, y = 1},
	inventory_craft = {x = 1, y = 1},
	teams = {monsters = -0.4, humans = -0.2, anthropomorphics = 0, animals = 1},

	-- Mob properties:
	think = 1.5,
	items = {},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 7,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {2, 2.5},
		decision_interval = {4, 5},
		vision = {15, 20},
		hearing = {10, 15},
		loyalty = {0.25, 0.5},
		fear = {0.75, 1},
		aggressivity = {0, 0.25},
		determination = {0.5, 0.75},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = -10, z = 0}, {x = 0, y = -10, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:animal_rabbit", {
	nodes = {"default:dirt_with_grass"},
	neighbors = {"air"},
	interval = 10,
	chance = 14000,
	min_height = -31000,
	max_height = 31000,
	min_light = 7,
	max_light = 15,
})

creatures:register_creature("creatures_races_default:animal_rat", {
	-- Common properties:
	icon = "mobs_rat_icon.png",
	hp_max = 1,
	armor = {fleshy = 100},
	collisionbox = {-0.2, -0.01, -0.2, 0.2, 0.2, 0.2},
	visual = "mesh",
	mesh = "mobs_rat.b3d",
	textures = {"mobs_rat.png"},
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 32,
		pos_max_y = 32,
		size_x = 2,
		size_y = 2,
		amount = 5,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	sounds = {
		random_idle = "creatures_rat_random", -- must be implemented as a custom function
		damage = "creatures_rat_damage",
		die = "creatures_rat_die",
	},
	makes_footstep_sound = false,
	env_damage = {
		groups = {water = 0},
		light = 0,
		light_level = 0,
	},
	physics = {
		speed = 1,
		jump = 0.75,
		gravity = 0.75,
	},
	inventory_main = {x = 8, y = 1},
	inventory_craft = {x = 1, y = 1},
	teams = {monsters = 0.4, humans = -0.6, anthropomorphics = -0.2, animals = 1},

	-- Mob properties:
	think = 1.5,
	items = {},
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 7,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {1.5, 2},
		decision_interval = {4, 5},
		vision = {10, 15},
		hearing = {10, 15},
		loyalty = {0, 0.5},
		fear = {0.3, 0.7},
		aggressivity = {0.4, 0.6},
		determination = {0.25, 0.5},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = false,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)
		formspec(self, clicker)
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = -15, z = 0}, {x = 0, y = -15, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:animal_rat", {
	nodes = {"default:dirt", "default:dirt_with_grass", "default:stone", "default:cobblestone"},
	neighbors = {"air"},
	interval = 10,
	chance = 8000,
	min_height = -31000,
	max_height = 31000,
	min_light = 0,
	max_light = 15,
})

minetest.register_craftitem("creatures_races_default:animal_rat", {
	description = "Rat",
	inventory_image = "mobs_rat_inventory.png",

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.above then
			creatures:spawn("creatures_races_default:animal_rat", pointed_thing.above)
			itemstack:take_item()
		end
		return itemstack
	end,
})

minetest.register_craftitem("creatures_races_default:animal_rat_cooked", {
	description = "Cooked Rat",
	inventory_image = "mobs_cooked_rat.png",

	on_use = minetest.item_eat(3),
})

minetest.register_craft({
	type = "cooking",
	output = "creatures_races_default:animal_rat_cooked",
	recipe = "creatures_races_default:animal_rat",
	cooktime = 5,
})

-- #2 - Creatures | #6 - Easter Eggs
-- This section contains rare and secret creatures. Don't look here if you don't want spoilers.

creatures:register_creature("creatures_races_default:anthro_fox_demon", {
	-- Common properties:
	icon = "clear.png",
	hp_max = 20,
	armor = {fleshy = 100},
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_anthro.b3d",
	textures = outfit_anthro("fox", math.random() > 0.5),
	particles = {
		pos_min_x = 0,
		pos_min_y = 0,
		pos_max_x = 64,
		pos_max_y = 32,
		size_x = 4,
		size_y = 4,
		amount = 10,
		time = 1,
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		stand = {x = 0, y = 79, speed = 30, blend = 0, loop = true},
		walk = {x = 168, y = 187, speed = 30, blend = 0, loop = true},
		walk_punch = {x = 200, y = 219, speed = 30, blend = 0, loop = true},
		punch = {x = 189, y = 198, speed = 30, blend = 0, loop = true},
	},
	sounds = {
		attack = "creatures_ghost_attack",
		damage = "creatures_ghost_damage",
		die = "creatures_ghost_die",
	},
	makes_footstep_sound = false,
	env_damage = {
		groups = {water = 0},
		light = 1,
		light_level = 15,
	},
	physics = {
		speed = 2,
		jump = 1,
		gravity = 1,
	},
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	teams = {monsters = 0, humans = 0, anthropomorphics = 0, animals = 0},

	-- Mob properties:
	think = 0.5,
	attack_capabilities = {damage_groups = {fleshy = 4}},
	items = nil,
	nodes = {
		{
			nodes = {"group:crumbly", "group:cracky", "group:choppy"},
			light_min = 0,
			light_max = 7,
			objective = "follow",
			priority = 0.1,
		},
	},
	traits = {
		attack_interval = {0.25, 0.25},
		decision_interval = {0.5, 1},
		vision = {20, 20},
		hearing = {10, 10},
		loyalty = {0, 0},
		fear = {0, 0},
		aggressivity = {1, 1},
		determination = {1, 1},
	},
	names = {{"Help me.", "You found me...", "Stay away...", "Run!", "No... please!", "It hurts!", "He has me.", "He's behind you..."},},
	teams_target = {attack = true, avoid = true, follow = true},
	alert = nil,
	use_items = true,
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
		module_mob_activate(self, staticdata, dtime_s)

		-- unkasked demons are not persisted
		if self.actor then
			self.object:remove()
		end
	end,
	on_step = function(self, dtime)
		logic_mob_step(self, dtime)
	end,
	on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
		logic_mob_punch(self, hitter, time_from_last_punch, tool_capabilities, dir)

		-- unmask the demon when we punch it
		if not self.actor then
			self.object:set_properties({textures = {"mobs_anthro_fox_demon_mob.png"}})
			self.actor = true
		end
	end,
	on_rightclick = function(self, clicker)
		logic_mob_rightclick(self, clicker)

		if self.actor then
			-- 50/50 chance of the player dying or becoming the demon
			if math.random() > 0.5 then
				creatures:player_set(clicker, {name = self.name, skin = self.skin, hp = 20})
				clicker:set_properties({textures = {"mobs_anthro_fox_demon_player.png"}})
			else
				clicker:set_hp(0)
			end
			self.object:remove()
		else
			-- unmask the demon if we haven't already
			formspec(self, clicker)
			self.object:set_properties({textures = {"mobs_anthro_fox_demon_mob.png"}})
			self.actor = true
		end
	end,

	-- Player properties:
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = {r = 64, g = 0, b = 0},
	screen = "",
	ambience = "creatures_ambient_ghost",
	player_join = function(player)
		logic_player_join (player)
		module_player_join (player)

		-- become a normal fox when rejoining
		local creature = "creatures_races_default:anthro_fox_male"
		if math.random() > 0.5 then
			creature = "creatures_races_default:anthro_fox_female"
		end
		creatures:player_set(player, {name = creature, hp = 20})
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
	end,
	player_hpchange = function(player, hp_change)
		logic_player_hpchange (player, hp_change)
	end,
	player_die = function(player)
		logic_player_die (player)
	end,
	player_respawn = function(player)
		logic_player_respawn (player)
	end,

	-- Module properties:
	custom = {},
})

creatures:register_spawn("creatures_races_default:anthro_fox_demon", {
	nodes = {"default:dirt", "default:dirt_with_grass", "default:sand", "default:desert_sand", "default:dirt_with_snow", "default:snowblock"},
	neighbors = {"air"},
	interval = 100,
	chance = 1000000,
	min_height = -31000,
	max_height = 31000,
	min_light = 0,
	max_light = 7,
	on_spawn = function(pos, node)
		-- this must not be a creative server
		if not minetest.setting_getbool("creative_mode") then
			-- the world must be older than a week
			if minetest.get_gametime() >= (60 * 60 * 24 * 7) then
				-- it must be between sunset and sunrise in the game
				local hour_game = minetest.get_timeofday()
				if hour_game > 0.75 or hour_game < 0.25 then
					-- the system clock must be between 6PM and 6AM
					local hour_real = os.date('*t').hour
					if hour_real >= 18 or hour_real < 6 then
						return true
					end
				end
			end
		end
		return false
	end,
})

if minetest.setting_get("log_mods") then
	minetest.log("action", "creatures_races_default loaded")
end
