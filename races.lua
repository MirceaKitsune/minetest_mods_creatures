-- Default player definitions:

-- default race for new players
creatures.player_default = "creatures:ghost"

-- player ghost, don't spawn as a mob
creatures:register_creature("creatures:ghost", {
	-- Common properties:
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
		random = "creatures_ghost_random",
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
	teams = {monsters = 0.8, people = 1, animals = 0.6},

	-- Mob properties:
	drops = {},
	on_rightclick = nil,
	attack_damage = 1,
	attack_type = "melee",
	traits = {
		attack_interval = {1, 1},
		think = {1, 1},
		vision = {15, 15},
		roam = {0.5, 0.5},
		loyalty = {0.5, 0.5},
		fear = {0.5, 0.5},
		aggressivity = {0.5, 0.5},
		determination = {0.5, 0.5},
	},

	-- Player properties:
	menu = false,
	inventory_main = {x = 1, y = 1},
	inventory_craft = {x = 1, y = 1},
	reincarnate = true,
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{r = 64, g = 0, b = 128}, "plain", {}},
	daytime = 0.15,
	screen = "hud_ghost.png",
	ambience = "creatures_ambient_ghost",
	icon = "mobs_ghost_icon.png",
})

-- Creature definitions:

creatures:register_creature("creatures:human", {
	-- Common properties:
	hp_max = 20,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_human.x",
	textures = {"mobs_human.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 30,
		stand_start = 0,
		stand_end = 79,
		walk_start = 168,
		walk_end = 187,
		run_start = 200,
		run_end = 219,
		punch_start = 189,
		punch_end = 198,
	},
	sounds = {
		attack = "creatures_human_attack",
		damage = "creatures_human_damage",
		die = "creatures_human_die",
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
	teams = {monsters = -0.4, people = 0.6, animals = 0.1},

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
	on_rightclick = nil,
	attack_damage = 1,
	attack_type = "melee",
	traits = {
		attack_interval = {0.75, 1},
		think = {0.5, 0.75},
		vision = {15, 20},
		roam = {0.5, 0.65},
		loyalty = {0.5, 0.75},
		fear = {0.25, 0.5},
		aggressivity = {0.5, 0.75},
		determination = {0.8, 1},
	},

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = 0,z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_human_icon.png",
})
creatures:register_spawn("creatures:human", {"default:dirt_with_grass"}, 20, -1, 9000, 1, 31000)
creatures:register_spawn("creatures:human", {"default:desert_sand"}, 20, -1, 14000, 3, 26000)

creatures:register_creature("creatures:dirt_monster", {
	-- Common properties:
	hp_max = 5,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_stone_monster.x",
	textures = {"mobs_dirt_monster.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 25,
		stand_start = 0,
		stand_end = 14,
		walk_start = 15,
		walk_end = 38,
		run_start = 40,
		run_end = 63,
		punch_start = 40,
		punch_end = 63,
	},
	sounds = {
		random = "creatures_monster_random",
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
		speed = 0.75,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = 0.4, people = -0.2, animals = 0},

	-- Mob properties:
	drops = {
		{name = "default:dirt",
		chance = 1,
		min = 3,
		max = 5,},
	},
	on_rightclick = nil,
	attack_damage = 1,
	attack_type = "melee",
	traits = {
		attack_interval = {1.35, 1.65},
		think = {1.5, 1.65},
		vision = {10, 15},
		roam = {0.35, 0.5},
		loyalty = {0.15, 0.3},
		fear = {0.3, 0.5},
		aggressivity = {0.7, 0.9},
		determination = {0.6, 0.8},
	},

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = 0,z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_dirt_monster_icon.png",
})
creatures:register_spawn("creatures:dirt_monster", {"default:dirt_with_grass"}, 3, -1, 7000, 3, 31000)

creatures:register_creature("creatures:stone_monster", {
	-- Common properties:
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
		stand_start = 0,
		stand_end = 14,
		walk_start = 15,
		walk_end = 38,
		run_start = 40,
		run_end = 63,
		punch_start = 40,
		punch_end = 63,
	},
	sounds = {
		random = "creatures_monster_random",
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
		jump = 0.75,
		gravity = 1.25,
	},
	teams = {monsters = 0.6, people = -0.4, animals = -0.2},

	-- Mob properties:
	drops = {
		{name = "default:mossycobble",
		chance = 1,
		min = 3,
		max = 5,},
	},
	attack_damage = 3,
	attack_type = "melee",
	traits = {
		attack_interval = {1, 1.25},
		think = {1, 1.25},
		vision = {10, 10},
		roam = {0.5, 0.5},
		loyalty = {0.3, 0.5},
		fear = {0.1, 0.3},
		aggressivity = {0.8, 1},
		determination = {0.9, 1},
	},

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_stone_monster_icon.png",
})
creatures:register_spawn("creatures:stone_monster", {"default:stone"}, 3, -1, 7000, 3, 0)

creatures:register_creature("creatures:sand_monster", {
	-- Common properties:
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
		stand_start = 0,
		stand_end = 39,
		walk_start = 41,
		walk_end = 72,
		run_start = 74,
		run_end = 105,
		punch_start = 74,
		punch_end = 105,
	},
	sounds = {
		random = "creatures_monster_random",
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
	teams = {monsters = 0.5, people = -0.2, animals = -0.2},

	-- Mob properties:
	drops = {
		{name = "default:sand",
		chance = 1,
		min = 3,
		max = 5,},
	},
	attack_damage = 2,
	attack_type = "melee",
	traits = {
		attack_interval = {1.25, 1.5},
		think = {1.35, 1.5},
		vision = {20, 20},
		roam = {0.35, 0.5},
		loyalty = {0.4, 0.7},
		fear = {0.15, 0.3},
		aggressivity = {0.7, 0.9},
		determination = {0.6, 0.8},
	},

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_sand_monster_icon.png",
})
creatures:register_spawn("creatures:sand_monster", {"default:desert_sand"}, 20, -1, 7000, 3, 31000)

creatures:register_creature("creatures:tree_monster", {
	-- Common properties:
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
		stand_start = 0,
		stand_end = 24,
		walk_start = 25,
		walk_end = 47,
		run_start = 48,
		run_end = 62,
		punch_start = 48,
		punch_end = 62,
	},
	sounds = {
		random = "creatures_monster_random",
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
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = 0.5, people = -0.4, animals = 0.6},

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
	traits = {
		attack_interval = {1.25, 1.5},
		think = {1.15, 1.35},
		vision = {15, 20},
		roam = {0.35, 0.65},
		loyalty = {0.5, 0.75},
		fear = {0.4, 0.6},
		aggressivity = {0.6, 0.8},
		determination = {0.7, 0.9},
	},

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 2},
	inventory_craft = {x = 2, y = 2},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_tree_monster_icon.png",
})
creatures:register_spawn("creatures:tree_monster", {"default:leaves", "default:jungleleaves"}, 20, -1, 7000, 3, 31000)

creatures:register_creature("creatures:sheep", {
	-- Common properties:
	hp_max = 5,
	armor = 100,
	collisionbox = {-0.5, -0.01, -0.5, 0.65, 1, 0.5},
	visual = "mesh",
	mesh = "mobs_sheep.x",
	textures = {"mobs_sheep.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = {
		speed = 10,
		stand_start = 0,
		stand_end = 80,
		walk_start = 81,
		walk_end = 100,
		run_start = 81,
		run_end = 100,
		punch_start = 81,
		punch_end = 100,
	},
	sounds = {
		random = "creatures_sheep_random",
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
		speed = 0.35,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = -0.3, people = 0.5, animals = 0.6},

	-- Mob properties:
	drops = {
		{name = "creatures:meat_raw",
		chance = 1,
		min = 2,
		max = 3,},
	},
	traits = {
		think = {1.5, 2},
		vision = {5, 5},
		roam = {0.15, 0.25},
		loyalty = {0.2, 0.4},
		fear = {0.8, 1},
		determination = {0.4, 0.6},
	},
	
	on_rightclick = function(self, clicker)
		local item = clicker:get_wielded_item()
		if item:get_name() == "farming:wheat" then
			if not self.actor then
				if not minetest.setting_getbool("creative_mode") then
					item:take_item()
					clicker:set_wielded_item(item)
				end
				self.actor = true
			elseif self.naked then
				if not minetest.setting_getbool("creative_mode") then
					item:take_item()
					clicker:set_wielded_item(item)
				end
				self.food = (self.food or 0) + 1
				if self.food >= 8 then
					self.food = 0
					self.naked = false
					self.object:set_properties({
						textures = {"mobs_sheep.png"},
						mesh = "mobs_sheep.x",
					})
				end
			end
			return
		end
		if clicker:get_inventory() and not self.naked then
			self.naked = true
			if minetest.registered_items["wool:white"] then
				clicker:get_inventory():add_item("main", ItemStack("wool:white "..math.random(1,3)))
			end
			self.object:set_properties({
				textures = {"mobs_sheep_shaved.png"},
				mesh = "mobs_sheep_shaved.x",
			})
		end
	end,

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 1},
	inventory_craft = {x = 1, y = 1},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = -5, z = 0}, {x = 0, y = -5, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_sheep_icon.png",
})
creatures:register_spawn("creatures:sheep", {"default:dirt_with_grass"}, 20, 8, 9000, 1, 31000)

minetest.register_craftitem("creatures:meat_raw", {
	description = "Raw Meat",
	inventory_image = "mobs_meat_raw.png",
})

minetest.register_craftitem("creatures:meat", {
	description = "Meat",
	inventory_image = "mobs_meat.png",
	on_use = minetest.item_eat(8),
})

minetest.register_craft({
	type = "cooking",
	output = "creatures:meat",
	recipe = "creatures:meat_raw",
	cooktime = 5,
})

creatures:register_creature("creatures:rat", {
	-- Common properties:
	hp_max = 1,
	armor = 100,
	collisionbox = {-0.2, -0.01, -0.2, 0.2, 0.2, 0.2},
	visual = "mesh",
	mesh = "mobs_rat.x",
	textures = {"mobs_rat.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	sounds = {
		random = "creatures_rat_random",
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
	teams = {monsters = 0.2, people = -0.4, animals = 0.4},

	-- Mob properties:
	drops = {},
	traits = {
		think = {1.5, 1.75},
		vision = {5, 5},
		roam = {0.5, 0.75},
		loyalty = {0.15, 0.3},
		fear = {0.5, 0.7},
		determination = {0.3, 0.5},
	},
	
	on_rightclick = function(self, clicker)
		if clicker:is_player() and clicker:get_inventory() then
			clicker:get_inventory():add_item("main", "creatures:rat")
			self.object:remove()
		end
	end,

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 1},
	inventory_craft = {x = 1, y = 1},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = -10, z = 0}, {x = 0, y = -10, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_rat_icon.png",
})
creatures:register_spawn("creatures:rat", {"default:dirt_with_grass", "default:stone"}, 20, -1, 7000, 1, 31000)

minetest.register_craftitem("creatures:rat", {
	description = "Rat",
	inventory_image = "mobs_rat_inventory.png",
	
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.above then
			minetest.env:add_entity(pointed_thing.above, "creatures:rat")
			itemstack:take_item()
		end
		return itemstack
	end,
})
	
minetest.register_craftitem("creatures:rat_cooked", {
	description = "Cooked Rat",
	inventory_image = "mobs_cooked_rat.png",
	
	on_use = minetest.item_eat(3),
})

minetest.register_craft({
	type = "cooking",
	output = "creatures:rat_cooked",
	recipe = "creatures:rat",
	cooktime = 5,
})

creatures:register_creature("creatures:oerkki", {
	-- Common properties:
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
		stand_start = 0,
		stand_end = 23,
		walk_start = 24,
		walk_end = 36,
		run_start = 37,
		run_end = 49,
		punch_start = 37,
		punch_end = 49,
	},
	sounds = {
		attack = "creatures_human_attack",
		damage = "creatures_human_damage",
		die = "creatures_human_die",
	},
	makes_footstep_sound = false,
	env_damage = {
		water = 0,
		lava = 1,
		light = 1,
	},
	physics = {
		speed = 1.25,
		jump = 1,
		gravity = 1,
	},
	teams = {monsters = 0.4, people = 0.3, animals = 0.4},

	-- Mob properties:
	drops = {},
	attack_damage = 3,
	attack_type = "melee",
	traits = {
		attack_interval = {0.85, 1.15},
		think = {0.75, 1.25},
		vision = {10, 15},
		roam = {0.35, 0.5},
		loyalty = {0.3, 0.7},
		fear = {0.1, 0.4},
		aggressivity = {0.4, 0.6},
		determination = {0.6, 0.8},
	},

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_oerkki_icon.png",
})
creatures:register_spawn("creatures:oerkki", {"default:stone"}, 2, -1, 7000, 3, -10)

creatures:register_creature("creatures:dungeon_master", {
	-- Common properties:
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
		stand_start = 0,
		stand_end = 19,
		walk_start = 20,
		walk_end = 35,
		punch_start = 36,
		punch_end = 48,
	},
	sounds = {
		random = "creatures_monster_large_random",
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
		speed = 0.65,
		jump = 1.25,
		gravity = 1.25,
	},
	teams = {monsters = 0.8, people = -0.8, animals = -0.4},

	-- Mob properties:
	drops = {
		{name = "default:mese",
		chance = 50,
		min = 1,
		max = 2,},
	},
	on_rightclick = nil,
	attack_damage = 4,
	attack_type = "shoot",
	attack_arrow = "creatures:fireball",
	traits = {
		attack_interval = {2.5, 3},
		think = {1.25, 1.75},
		vision = {10, 15},
		roam = {0.15, 0.25},
		loyalty = {0.4, 0.7},
		fear = {0, 0.25},
		aggressivity = {0.8, 1},
		determination = {0.5, 0.7},
	},

	-- Player properties:
	menu = true,
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	reincarnate = false,
	ghost = "",
	eye_offset = {{x = 0, y = 5, z = 0}, {x = 0, y = 5, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
	ambience = "",
	icon = "mobs_dungeon_master_icon.png",
})
creatures:register_spawn("creatures:dungeon_master", {"default:stone"}, 2, -1, 7000, 1, -50)

creatures:register_arrow("creatures:fireball", {
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
	minetest.log("action", "mobs loaded")
end
