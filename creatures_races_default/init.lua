-- Default mob formspec:
local function formspec(self, clicker)
	if not self.traits_set or not self.names_set then return end

	local name = creatures:player_get(clicker:get_player_name())
	local alliance = creatures:alliance(clicker, self.object)
	local alliance_color = "#FFFFAA"
	if alliance > 0 then
		alliance_color = "#AAFFAA"
	elseif alliance < 0 then
		alliance_color = "#FFAAAA"
	end

	local names = "N/A"
	if #self.names > 0 then
		names = ""
		for i, name in pairs(self.names_set) do
			names = names..name.." "
		end
	end

	local info =
		"Name: "..names..","
		.."Health: "..(self.object:get_hp() * 5).."%,"
		..alliance_color.."Alliance: "..alliance..","
	if alliance > 0 then
		info = info
			.."Traits - Attack: "..string.format("%.3f", self.traits_set.attack_interval)..","
			.."Traits - Intelligence: "..string.format("%.3f", 1 / self.traits_set.think)..","
			.."Traits - Vision: "..string.format("%.3f", self.traits_set.vision)..","
			.."Traits - Loyalty: "..string.format("%.3f", self.traits_set.loyalty)..","
			.."Traits - Fear: "..string.format("%.3f", self.traits_set.fear)..","
			.."Traits - Aggressivity: "..string.format("%.3f", self.traits_set.aggressivity)..","
			.."Traits - Determination: "..string.format("%.3f", self.traits_set.determination)
	end

	local formspec =
		"size[6,4]"
		..default.gui_bg
		..default.gui_bg_img
		..default.gui_slots
		.."image[0,0;1,1;"..self.icon.."]"
		.."textlist[1,0;5,3;;"..info..";0;false]"
	-- Possession is possible
	if name == "creatures_races_default:ghost" and not self.actor then
		formspec = formspec.."button_exit[0,3;3,1;possess;Possess]"
		formspec = formspec.."button_exit[3,3;3,1;quit;Exit]"
	-- Special button for rats
	elseif self.name == "creatures_races_default:rat" then
		formspec = formspec.."button_exit[0,3;3,1;rat;Take]"
		formspec = formspec.."button_exit[3,3;3,1;quit;Exit]"
	-- Special button for sheep
	elseif self.name == "creatures_races_default:sheep" then
		formspec = formspec.."button_exit[0,3;3,1;sheep;Shear / Breed]"
		formspec = formspec.."button_exit[3,3;3,1;quit;Exit]"
	-- No special buttons
	else
		formspec = formspec.."button_exit[0,3;6,1;quit;Exit]"
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
					creatures:possess(player, creature)
				end
			-- Handle rats:
			elseif fields["rat"] then
				if player:is_player() and player:get_inventory() then
					player:get_inventory():add_item("main", "creatures_races_default:rat")
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
								mesh = "mobs_sheep.x",
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
						mesh = "mobs_sheep_shaved.x",
					})
				end
			end
		end
	end
end)

-- Inventory formspec for players:
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
			.."image[0,0;1,1;"..icon.."]"
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

-- Default race for new players:
creatures.player_default = "creatures_races_default:ghost"

-- Default player definitions:

-- player ghost, don't spawn as a mob
creatures:register_creature("creatures_races_default:ghost", {
	-- Common properties:
	icon = "mobs_ghost_icon.png",
	hp_max = 20,
	armor = 100,
	collisionbox = {-0.5, 0, -0.5, 0.5, 2, 0.5},
	visual = "sprite",
	mesh = "",
	textures = {"clear.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = nil,
	sounds = {
		random_idle = "creatures_ghost_random",
		attack = "creatures_ghost_attack",
		damage = "creatures_ghost_damage",
		die = "creatures_ghost_die",
	},
	makes_footstep_sound = false,
	env_damage = {
		water = 0,
		lava = 0,
		light = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = 1.0, people = 1.0, animals = 1.0},

	-- Mob properties:
	drops = {},
	attack_damage = 1,
	attack_type = "melee",
	nodes = {},
	traits = {
		attack_interval = {1, 1},
		think = {1, 1},
		vision = {15, 15},
		loyalty = {0.5, 0.5},
		fear = {0.5, 0.5},
		aggressivity = {0.5, 0.5},
		determination = {0.5, 0.5},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 1, y = 1},
	inventory_craft = {x = 1, y = 1},
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = {r = 64, g = 0, b = 128},
	screen = "hud_ghost.png",
	ambience = "creatures_ambient_ghost",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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

-- Creature definitions:

creatures:register_creature("creatures_races_default:human_male", {
	-- Common properties:
	icon = "mobs_human_male_icon.png",
	hp_max = 20,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_human.x",
	textures = {
		{"mobs_human_1.png"},
		{"mobs_human_2.png"},
		{"mobs_human_3.png"},
		{"mobs_human_4.png"},
		{"mobs_human_6.png"},
		{"mobs_human_9.png"},
		{"mobs_human_10.png"},
		{"mobs_human_11.png"},
		{"mobs_human_12.png"},
		{"mobs_human_13.png"},
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 30,
		stand = {0, 79},
		walk = {168, 187},
		walk_punch = {200, 219},
		punch = {189, 198},
	},
	sounds = {
		attack = "creatures_human_male_attack",
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 0,
		lava = 5,
		light = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = -0.6, people = 1.0, animals = 0.0},

	-- Mob properties:
	drops = {
		{name = "default:sword_bronze",
		chance = 40,
		min = 1,
		max = 1,},
		{name = "default:sword_steel",
		chance = 60,
		min = 1,
		max = 1,},
		{name = "default:sword_diamond",
		chance = 80,
		min = 1,
		max = 1,},
	},
	attack_damage = 1,
	attack_type = "melee",
	nodes = {
		-- go to bed if it's dark
		{nodes = {"group:bed"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		stay = true,
		priority = 0.75,},
		-- interact with functional nodes (chests, furnaces, etc) if it's not midday
		{nodes = {"default:chest", "default:chest_locked", "default:furnace", "default:furnace_active", "default:sign_wall", "default:bookshelf", "group:door"},
		light_min = 7,
		light_max = 14,
		objective = "follow",
		priority = 0.5,},
		-- do some farming if it's midday
		{nodes = {"group:field", "group:flora", "group:seed"},
		light_min = 15,
		light_max = 15,
		objective = "follow",
		priority = 0.5,},
		-- wander around idly
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 7,
		light_max = 15,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {0.75, 1.25},
		think = {0.5, 1.0},
		vision = {25, 35},
		loyalty = {0.25, 1.0},
		fear = {0.0, 0.5},
		aggressivity = {0.5, 1.0},
		determination = {0.5, 1.0},
	},
	names = {
		{"Alex", "Daniel", "Mike", "Sam", "Earl", "Steve", "Charlie", "Claude", "Arnold", "Andrew", "David", "Damian", "Bob", "Tom", "Gabriel", "Walter", "Jerry", "Jake", "Michael", "Nate", "Oliver", "Bubba",},
		{"Wheeler", "Anderson", "Simpson", "Jackson", "Parker", "Adams", "Steven", "Johnson",},
	},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	ghost = "",
	eye_offset = {{x = 0, y = 0,z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:human_male", {"default:dirt", "default:dirt_with_grass", "default:sand", "default:desert_sand", "default:dirt_with_snow", "default:snowblock"}, 20, -1, 9000, 1, 31000)

creatures:register_creature("creatures_races_default:human_female", {
	-- Common properties:
	icon = "mobs_human_female_icon.png",
	hp_max = 20,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_human.x",
	textures = {
		{"mobs_human_5.png"},
		{"mobs_human_7.png"},
		{"mobs_human_8.png"},
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 30,
		stand = {0, 79},
		walk = {168, 187},
		walk_punch = {200, 219},
		punch = {189, 198},
	},
	sounds = {
		attack = "creatures_human_female_attack",
		damage = "creatures_human_female_damage",
		die = "creatures_human_female_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 0,
		lava = 5,
		light = 0,
	},
	physics = {
		speed = 1,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = -0.5, people = 1.0, animals = 0.1},

	-- Mob properties:
	drops = {
		{name = "farming:bread",
		chance = 30,
		min = 1,
		max = 1,},
	},
	attack_damage = 1,
	attack_type = "melee",
	nodes = {
		-- go to bed if it's dark
		{nodes = {"group:bed"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		stay = true,
		priority = 0.75,},
		-- interact with functional nodes (chests, furnaces, etc) if it's not midday
		{nodes = {"default:chest", "default:chest_locked", "default:furnace", "default:furnace_active", "default:sign_wall", "default:bookshelf", "group:door"},
		light_min = 7,
		light_max = 14,
		objective = "follow",
		priority = 0.5,},
		-- do some farming if it's midday
		{nodes = {"group:field", "group:flora", "group:seed"},
		light_min = 15,
		light_max = 15,
		objective = "follow",
		priority = 0.5,},
		-- wander around idly
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 7,
		light_max = 15,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {1.0, 1.5},
		think = {0.5, 1.0},
		vision = {25, 35},
		loyalty = {0.5, 1.0},
		fear = {0.5, 1.0},
		aggressivity = {0.0, 0.5},
		determination = {0.5, 1.0},
	},
	names = {
		{"Ana", "Maria", "Kate", "Michelle", "Sarah", "Mona", "Rose", "Stephanie", "Cleopatra", "Denise",},
		{"Wheeler", "Anderson", "Simpson", "Jackson", "Parker", "Adams", "Steven", "Johnson",},
	},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	ghost = "",
	eye_offset = {{x = 0, y = 0,z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:human_female", {"default:dirt", "default:dirt_with_grass", "default:sand", "default:desert_sand", "default:dirt_with_snow", "default:snowblock"}, 20, -1, 13000, 1, 31000)

creatures:register_creature("creatures_races_default:dirt_monster", {
	-- Common properties:
	icon = "mobs_dirt_monster_icon.png",
	hp_max = 5,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_stone_monster.x",
	textures = {"mobs_dirt_monster.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 20,
		stand = {0, 14},
		walk = {15, 38},
		walk_punch = {40, 63},
		punch = {40, 63},
	},
	sounds = {
		random_idle = "creatures_monster_random",
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 1,
		lava = 5,
		light = 1,
	},
	physics = {
		speed = 0.5,
		jump = 0.75,
		gravity = 1,
	},
	teams = {monsters = 1.0, people = -0.4, animals = 0.0},

	-- Mob properties:
	drops = {
		{name = "default:dirt",
		chance = 1,
		min = 3,
		max = 5,},
	},
	attack_damage = 1,
	attack_type = "melee",
	nodes = {
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {1.5, 1.75},
		think = {1.5, 1.75},
		vision = {10, 15},
		loyalty = {0.0, 0.0},
		fear = {0.0, 0.25},
		aggressivity = {0.75, 1.0},
		determination = {0.35, 0.65},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	ghost = "",
	eye_offset = {{x = 0, y = 0,z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:dirt_monster", {"default:dirt", "default:dirt_with_grass"}, 3, -1, 7000, 3, 31000)

creatures:register_creature("creatures_races_default:stone_monster", {
	-- Common properties:
	icon = "mobs_stone_monster_icon.png",
	hp_max = 10,
	armor = 80,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_stone_monster.x",
	textures = {"mobs_stone_monster.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 25,
		stand = {0, 14},
		walk = {15, 38},
		walk_punch = {40, 63},
		punch = {40, 63},
	},
	sounds = {
		random_idle = "creatures_monster_random",
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 0,
		lava = 0,
		light = 0,
	},
	physics = {
		speed = 0.75,
		jump = 0.5,
		gravity = 1.25,
	},
	teams = {monsters = 1.0, people = -0.8, animals = -0.2},

	-- Mob properties:
	drops = {
		{name = "default:mossycobble",
		chance = 1,
		min = 3,
		max = 5,},
	},
	attack_damage = 3,
	attack_type = "melee",
	nodes = {
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {1, 1.25},
		think = {1, 1.25},
		vision = {15, 20},
		loyalty = {0.0, 0.25},
		fear = {0.0, 0.0},
		aggressivity = {0.75, 1},
		determination = {0.75, 1},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:stone_monster", {"default:stone", "default:cobblestone"}, 3, -1, 7000, 3, 0)

creatures:register_creature("creatures_races_default:sand_monster", {
	-- Common properties:
	icon = "mobs_sand_monster_icon.png",
	hp_max = 5,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_sand_monster.x",
	textures = {"mobs_sand_monster.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 20,
		stand = {0, 39},
		walk = {41, 72},
		walk_punch = {74, 105},
		punch = {74, 105},
	},
	sounds = {
		random_idle = "creatures_monster_random",
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 3,
		lava = 1,
		light = 0,
	},
	physics = {
		speed = 0.5,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = 1.0, people = -0.6, animals = -0.4},

	-- Mob properties:
	drops = {
		{name = "default:sand",
		chance = 1,
		min = 3,
		max = 5,},
	},
	attack_damage = 2,
	attack_type = "melee",
	nodes = {
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 0,
		light_max = 15,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {1.25, 1.5},
		think = {1.35, 1.65},
		vision = {30, 30},
		loyalty = {0.25, 0.5},
		fear = {0.15, 0.3},
		aggressivity = {0.7, 0.9},
		determination = {0.6, 0.8},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:sand_monster", {"default:sand", "default:desert_sand"}, 20, -1, 7000, 3, 31000)

creatures:register_creature("creatures_races_default:snow_monster", {
	-- Common properties:
	icon = "mobs_snow_monster_icon.png",
	hp_max = 5,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_sand_monster.x",
	textures = {"mobs_snow_monster.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 25,
		stand = {0, 39},
		walk = {41, 72},
		walk_punch = {74, 105},
		punch = {74, 105},
	},
	sounds = {
		random_idle = "creatures_monster_random",
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 3,
		lava = 5,
		light = 1,
	},
	physics = {
		speed = 0.75,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = 1.0, people = -0.6, animals = 0.2},

	-- Mob properties:
	drops = {
		{name = "default:snowblock",
		chance = 1,
		min = 3,
		max = 5,},
	},
	attack_damage = 2,
	attack_type = "melee",
	nodes = {
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {1.0, 1.25},
		think = {1.0, 1.25},
		vision = {15, 20},
		loyalty = {0.3, 0.6},
		fear = {0.1, 0.25},
		aggressivity = {0.5, 0.75},
		determination = {0.5, 0.75},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:snow_monster", {"default:dirt_with_snow", "default:snowblock"}, 3, -1, 7000, 3, 31000)

creatures:register_creature("creatures_races_default:tree_monster", {
	-- Common properties:
	icon = "mobs_tree_monster_icon.png",
	hp_max = 10,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_tree_monster.x",
	textures = {"mobs_tree_monster.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 25,
		stand = {0, 24},
		walk = {25, 47},
		walk_punch = {48, 62},
		punch = {48, 62},
	},
	sounds = {
		random_idle = "creatures_monster_random",
		attack = "creatures_monster_attack",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 1,
		lava = 5,
		light = 0,
	},
	physics = {
		speed = 0.75,
		jump = 1.5,
		gravity = 1,
	},
	teams = {monsters = 0.8, people = -0.4, animals = 0.6},

	-- Mob properties:
	drops = {
		{name = "default:sapling",
		chance = 3,
		min = 1,
		max = 2,},
		{name = "default:junglesapling",
		chance = 3,
		min = 1,
		max = 2,},
	},
	disable_fall_damage = true,
	attack_damage = 2,
	attack_type = "melee",
	nodes = {
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 0,
		light_max = 15,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {1.0, 1.25},
		think = {1.15, 1.35},
		vision = {25, 30},
		loyalty = {0.6, 0.8},
		fear = {0.4, 0.6},
		aggressivity = {0.4, 0.8},
		determination = {0.6, 0.8},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:tree_monster", {"default:leaves", "default:jungleleaves"}, 20, -1, 7000, 3, 31000)

creatures:register_creature("creatures_races_default:sheep", {
	-- Common properties:
	icon = "mobs_sheep_icon.png",
	hp_max = 5,
	armor = 100,
	collisionbox = {-0.5, -0.01, -0.5, 0.65, 1, 0.5},
	visual = "mesh",
	mesh = "mobs_sheep.x",
	textures = {
		{"mobs_sheep_white.png"},
		{"mobs_sheep_grey.png"},
		{"mobs_sheep_black.png"},
	},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 15,
		stand = {0, 80},
		walk = {81, 100},
		walk_punch = {81, 100},
		punch = {81, 100},
	},
	sounds = {
		random_idle = "creatures_sheep_random",
		damage = "creatures_sheep_damage",
		die = "creatures_sheep_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 0,
		lava = 5,
		light = 0,
	},
	physics = {
		speed = 0.5,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = -0.4, people = 0.2, animals = 1.0},

	-- Mob properties:
	drops = {
		{name = "creatures_races_default:meat_raw",
		chance = 1,
		min = 2,
		max = 3,},
	},
	nodes = {
		-- eat grass if it's midday
		{nodes = {"group:flora"},
		light_min = 15,
		light_max = 15,
		objective = "attack",
		priority = 0.5,},
		-- wander around idly
		{nodes = {"group:crumbly"},
		light_min = 7,
		light_max = 15,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {2, 3},
		think = {1.5, 2},
		vision = {15, 20},
		loyalty = {0.6, 0.8},
		fear = {0.8, 1.0},
		aggressivity = {0.0, 0.2},
		determination = {0.4, 0.6},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 1},
	inventory_craft = {x = 1, y = 1},
	ghost = "",
	eye_offset = {{x = 0, y = -5, z = 0}, {x = 0, y = -5, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:sheep", {"default:dirt_with_grass"}, 20, 8, 9000, 1, 31000)

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

creatures:register_creature("creatures_races_default:rat", {
	-- Common properties:
	icon = "mobs_rat_icon.png",
	hp_max = 1,
	armor = 100,
	collisionbox = {-0.2, -0.01, -0.2, 0.2, 0.2, 0.2},
	visual = "mesh",
	mesh = "mobs_rat.x",
	textures = {"mobs_rat.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	sounds = {
		random_idle = "creatures_rat_random",
		damage = "creatures_rat_damage",
		die = "creatures_rat_die",
	},
	makes_footstep_sound = false,
	env_damage = {
		water = 0,
		lava = 1,
		light = 0,
	},
	physics = {
		speed = 1,
		jump = 0.75,
		gravity = 0.75,
	},
	teams = {monsters = 0.4, people = -0.6, animals = 1.0},

	-- Mob properties:
	drops = {},
	nodes = {
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {1.5, 2},
		think = {1.5, 1.75},
		vision = {10, 15},
		loyalty = {0.0, 0.5},
		fear = {0.3, 0.7},
		aggressivity = {0.4, 0.6},
		determination = {0.25, 0.5},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 1},
	inventory_craft = {x = 1, y = 1},
	ghost = "",
	eye_offset = {{x = 0, y = -10, z = 0}, {x = 0, y = -10, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:rat", {"default:dirt", "default:dirt_with_grass", "default:stone", "default:cobblestone"}, 20, -1, 7000, 1, 31000)

minetest.register_craftitem("creatures_races_default:rat", {
	description = "Rat",
	inventory_image = "mobs_rat_inventory.png",

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.above then
			minetest.env:add_entity(pointed_thing.above, "creatures_races_default:rat")
			itemstack:take_item()
		end
		return itemstack
	end,
})

minetest.register_craftitem("creatures_races_default:rat_cooked", {
	description = "Cooked Rat",
	inventory_image = "mobs_cooked_rat.png",

	on_use = minetest.item_eat(3),
})

minetest.register_craft({
	type = "cooking",
	output = "creatures_races_default:rat_cooked",
	recipe = "creatures_races_default:rat",
	cooktime = 5,
})

creatures:register_creature("creatures_races_default:oerkki", {
	-- Common properties:
	icon = "mobs_oerkki_icon.png",
	hp_max = 10,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_oerkki.x",
	textures = {"mobs_oerkki.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 40,
		stand = {0, 23},
		walk = {24, 36},
		walk_punch = {37, 49},
		punch = {37, 49},
	},
	sounds = {
		random_idle = "creatures_human_male_attack",
		damage = "creatures_human_male_damage",
		die = "creatures_human_male_die",
	},
	makes_footstep_sound = false,
	env_damage = {
		water = 0,
		lava = 1,
		light = 1,
	},
	physics = {
		speed = 1.25,
		jump = 1.25,
		gravity = 1,
	},
	teams = {monsters = 0.5, people = 0.5, animals = 0.5},

	-- Mob properties:
	drops = {},
	attack_damage = 3,
	attack_type = "melee",
	nodes = {
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		priority = 0.25,},
	},
	traits = {
		attack_interval = {0.75, 1.0},
		think = {0.75, 1.25},
		vision = {15, 25},
		loyalty = {0.25, 0.75},
		fear = {0.2, 0.4},
		aggressivity = {0.4, 0.6},
		determination = {0.4, 0.8},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:oerkki", {"default:stone"}, 2, -1, 7000, 3, -10)

creatures:register_creature("creatures_races_default:dungeon_master", {
	-- Common properties:
	icon = "mobs_dungeon_master_icon.png",
	hp_max = 10,
	armor = 60,
	collisionbox = {-0.7, -0.01, -0.7, 0.7, 2.6, 0.7},
	visual = "mesh",
	mesh = "mobs_dungeon_master.x",
	textures = {"mobs_dungeon_master.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 20,
		stand = {0, 19},
		walk = {20, 35},
		punch = {36, 48},
	},
	sounds = {
		random_idle = "creatures_monster_large_random",
		attack = "creatures_fireball",
		damage = "creatures_monster_damage",
		die = "creatures_monster_die",
	},
	makes_footstep_sound = true,
	env_damage = {
		water = 0,
		lava = 1,
		light = 0,
	},
	physics = {
		speed = 0.75,
		jump = 1.25,
		gravity = 1.25,
	},
	teams = {monsters = 1.0, people = -1.0, animals = -0.2},

	-- Mob properties:
	drops = {
		{name = "default:mese",
		chance = 50,
		min = 1,
		max = 2,},
	},
	attack_damage = 4,
	attack_type = "shoot",
	nodes = {
		{nodes = {"group:crumbly", "group:cracky", "group:choppy"},
		light_min = 0,
		light_max = 7,
		objective = "follow",
		priority = 0.25,},
	},
	attack_projectile = "creatures_races_default:fireball",
	traits = {
		attack_interval = {2.5, 3},
		think = {1.25, 1.75},
		vision = {15, 20},
		loyalty = {0.3, 0.7},
		fear = {0.0, 0.25},
		aggressivity = {0.75, 1.0},
		determination = {0.75, 1.0},
	},
	names = {},
	teams_target = {attack = true, avoid = true, follow = true},
	on_activate = function(self, staticdata, dtime_s)
		logic_mob_activate(self, staticdata, dtime_s)
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
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	ghost = "",
	eye_offset = {{x = 0, y = 5, z = 0}, {x = 0, y = 5, z = 0}},
	fog = nil,
	screen = "",
	ambience = "",
	player_join = function(player)
		logic_player_join (player)
	end,
	player_step = function(player, dtime)
		logic_player_step (player, dtime)
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
creatures:register_spawn("creatures_races_default:dungeon_master", {"default:stone"}, 2, -1, 7000, 1, -50)

creatures:register_projectile("creatures_races_default:fireball", {
	visual = "sprite",
	visual_size = {x=1, y=1},
	textures = {"mobs_fireball.png"},
	velocity = 5,
	hit_player = function(self, player)
		local s = self.object:getpos()
		local p = player:getpos()
		local vec = {x=s.x-p.x, y=s.y-p.y, z=s.z-p.z}
		player:punch(self.object, 1.0,  {
			full_punch_interval=1.0,
			damage_groups = {fleshy=4},
		}, vec)
		local pos = self.object:getpos()
		for dx=-1,1 do
			for dy=-1,1 do
				for dz=-1,1 do
					local p = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
					local n = minetest.env:get_node(pos).name
					if minetest.registered_nodes[n].groups.flammable or math.random(1, 100) <= 30 then
						minetest.env:set_node(p, {name="fire:basic_flame"})
					else
						minetest.env:remove_node(p)
					end
				end
			end
		end
	end,
	hit_node = function(self, pos, node)
		for dx=-1,1 do
			for dy=-2,1 do
				for dz=-1,1 do
					local p = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
					local n = minetest.env:get_node(pos).name
					if minetest.registered_nodes[n].groups.flammable or math.random(1, 100) <= 30 then
						minetest.env:set_node(p, {name="fire:basic_flame"})
					else
						minetest.env:remove_node(p)
					end
				end
			end
		end
	end
})

if minetest.setting_get("log_mods") then
	minetest.log("action", "creatures_races_default loaded")
end
