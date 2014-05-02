-- Default player definition:

creatures:register_player("default", {
	hp_max = 20,
	armor = 100,
	collisionbox = {-0.5, 0, -0.5, 0.5, 2, 0.5},
	visual = "sprite",
	mesh = "",
	textures = {"clear.png"},
	visual_size = {x=1, y=1},
	drawtype = "front",
	animation = nil,
	makes_footstep_sound = false,
	teams = {},
	physics_speed = 1,
	physics_jump = 1,
	physics_gravity = 1,
	inventory_main = {x = 1, y = 1},
	inventory_craft = {x = 1, y = 1},
	hotbar = 1,
	inventory = false,
	interact = false,
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{r = 64, g = 0, b = 128}, "plain", {}},
	daytime = 0.15,
	screen = "hud_ghost.png",
})

-- Creature definitions:

creatures:register_creature("creatures:dirt_monster", {
	-- Player and mob properties:
	hp_max = 5,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_stone_monster.x",
	textures = {"mobs_dirt_monster.png"},
	visual_size = {x=3, y=2.6},
	drawtype = "front",
	animation = {
		speed_normal = 15,
		speed_normal_player = 30,
		speed_run = 20,
		stand_start = 0,
		stand_end = 14,
		walk_start = 15,
		walk_end = 38,
		run_start = 40,
		run_end = 63,
		punch_start = 40,
		punch_end = 63,
	},
	makes_footstep_sound = true,
	teams = {"monsters"},

	-- Mob properties:
	type = "monster",
	view_range = 15,
	walk_velocity = 1,
	run_velocity = 3,
	damage = 2,
	drops = {
		{name = "default:dirt",
		chance = 1,
		min = 3,
		max = 5,},
	},
	water_damage = 1,
	lava_damage = 5,
	light_damage = 2,
	on_rightclick = nil,
	attack_type = "dogfight",
	possession = 0.25,

	-- Player properties:
	physics_speed = 1,
	physics_jump = 1,
	physics_gravity = 1,
	inventory_main = {x = 8, y = 3},
	inventory_craft = {x = 3, y = 3},
	hotbar = 8,
	inventory = true,
	interact = true,
	eye_offset = {{x = 0, y = 0,z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
})
creatures:register_spawn("creatures:dirt_monster", {"default:dirt_with_grass"}, 3, -1, 7000, 3, 31000)

creatures:register_creature("creatures:stone_monster", {
	-- Player and mob properties:
	hp_max = 10,
	armor = 80,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_stone_monster.x",
	textures = {"mobs_stone_monster.png"},
	visual_size = {x=3, y=2.6},
	drawtype = "front",
	animation = {
		speed_normal = 15,
		speed_normal_player = 30,
		speed_run = 20,
		stand_start = 0,
		stand_end = 14,
		walk_start = 15,
		walk_end = 38,
		run_start = 40,
		run_end = 63,
		punch_start = 40,
		punch_end = 63,
	},
	makes_footstep_sound = true,
	teams = {"monsters"},

	-- Mob properties:
	type = "monster",
	view_range = 10,
	walk_velocity = 0.5,
	run_velocity = 2,
	damage = 3,
	drops = {
		{name = "default:mossycobble",
		chance = 1,
		min = 3,
		max = 5,},
	},
	light_resistant = true,
	water_damage = 0,
	lava_damage = 0,
	light_damage = 0,
	attack_type = "dogfight",
	possession = 0.25,

	-- Player properties:
	physics_speed = 1,
	physics_jump = 1,
	physics_gravity = 1,
	inventory_main = {x = 8, y = 3},
	inventory_craft = {x = 3, y = 3},
	hotbar = 8,
	inventory = true,
	interact = true,
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
})
creatures:register_spawn("creatures:stone_monster", {"default:stone"}, 3, -1, 7000, 3, 0)

creatures:register_creature("creatures:sand_monster", {
	-- Player and mob properties:
	hp_max = 3,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_sand_monster.x",
	textures = {"mobs_sand_monster.png"},
	visual_size = {x=8,y=8},
	drawtype = "front",
	animation = {
		speed_normal = 15,
		speed_normal_player = 30,
		speed_run = 20,
		stand_start = 0,
		stand_end = 39,
		walk_start = 41,
		walk_end = 72,
		run_start = 74,
		run_end = 105,
		punch_start = 74,
		punch_end = 105,
	},
	makes_footstep_sound = true,
	teams = {"monsters"},

	-- Mob properties:
	type = "monster",
	view_range = 15,
	walk_velocity = 1.5,
	run_velocity = 4,
	damage = 1,
	drops = {
		{name = "default:sand",
		chance = 1,
		min = 3,
		max = 5,},
	},
	light_resistant = true,
	water_damage = 3,
	lava_damage = 1,
	light_damage = 0,
	attack_type = "dogfight",
	possession = 0.25,

	-- Player properties:
	physics_speed = 1,
	physics_jump = 1,
	physics_gravity = 1,
	inventory_main = {x = 8, y = 3},
	inventory_craft = {x = 3, y = 3},
	hotbar = 8,
	inventory = true,
	interact = true,
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
})
creatures:register_spawn("creatures:sand_monster", {"default:desert_sand"}, 20, -1, 7000, 3, 31000)

creatures:register_creature("creatures:tree_monster", {
	-- Player and mob properties:
	hp_max = 5,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_tree_monster.x",
	textures = {"mobs_tree_monster.png"},
	visual_size = {x=4.5,y=4.5},
	drawtype = "front",
	animation = {
		speed_normal = 15,
		speed_normal_player = 30,
		speed_run = 20,
		stand_start = 0,
		stand_end = 24,
		walk_start = 25,
		walk_end = 47,
		run_start = 48,
		run_end = 62,
		punch_start = 48,
		punch_end = 62,
	},
	makes_footstep_sound = true,
	teams = {"monsters", "animals"},

	-- Mob properties:
	type = "monster",
	view_range = 15,
	walk_velocity = 1,
	run_velocity = 3,
	damage = 2,
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
	light_resistant = true,
	water_damage = 1,
	lava_damage = 5,
	light_damage = 2,
	disable_fall_damage = true,
	attack_type = "dogfight",
	possession = 0.25,

	-- Player properties:
	physics_speed = 1,
	physics_jump = 1,
	physics_gravity = 1,
	inventory_main = {x = 8, y = 3},
	inventory_craft = {x = 3, y = 3},
	hotbar = 8,
	inventory = true,
	interact = true,
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
})
creatures:register_spawn("creatures:tree_monster", {"default:leaves", "default:jungleleaves"}, 3, -1, 7000, 3, 31000)

creatures:register_creature("creatures:sheep", {
	-- Player and mob properties:
	hp_max = 5,
	armor = 200,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1, 0.4},
	visual = "mesh",
	mesh = "mobs_sheep.x",
	textures = {"mobs_sheep.png"},
	visual_size = {x=1.0,y=1.0},
	drawtype = "front",
	animation = {
		speed_normal = 15,
		speed_normal_player = 30,
		stand_start = 0,
		stand_end = 80,
		walk_start = 81,
		walk_end = 100,
		run_start = 81,
		run_end = 100,
		punch_start = 81,
		punch_end = 100,
	},
	makes_footstep_sound = true,
	teams = {"animals", "people"},

	-- Mob properties:
	type = "animal",
	walk_velocity = 1,
	drops = {
		{name = "creatures:meat_raw",
		chance = 1,
		min = 2,
		max = 3,},
	},
	water_damage = 1,
	lava_damage = 5,
	light_damage = 0,
	sounds = {
		random = "mobs_sheep",
	},
	follow = "farming:wheat",
	view_range = 5,
	possession = 0.35,
	
	on_rightclick = function(self, clicker)
		local item = clicker:get_wielded_item()
		if item:get_name() == "farming:wheat" then
			if not self.tamed then
				if not minetest.setting_getbool("creative_mode") then
					item:take_item()
					clicker:set_wielded_item(item)
				end
				self.tamed = true
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
	physics_speed = 0.5,
	physics_jump = 1,
	physics_gravity = 1,
	inventory_main = {x = 8, y = 1},
	inventory_craft = {x = 2, y = 2},
	hotbar = 8,
	inventory = true,
	interact = true,
	eye_offset = {{x = 0, y = -5, z = 0}, {x = 0, y = -5, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
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
	-- Player and mob properties:
	hp_max = 1,
	armor = 200,
	collisionbox = {-0.2, -0.01, -0.2, 0.2, 0.2, 0.2},
	visual = "mesh",
	mesh = "mobs_rat.x",
	textures = {"mobs_rat.png"},
	visual_size = {x=1.0,y=1.0},
	drawtype = "front",
	makes_footstep_sound = false,
	teams = {"animals", "monsters"},

	-- Mob properties:
	type = "animal",
	walk_velocity = 1,
	drops = {},
	water_damage = 0,
	lava_damage = 1,
	light_damage = 0,
	possession = 0.5,
	
	on_rightclick = function(self, clicker)
		if clicker:is_player() and clicker:get_inventory() then
			clicker:get_inventory():add_item("main", "creatures:rat")
			self.object:remove()
		end
	end,

	-- Player properties:
	physics_speed = 1,
	physics_jump = 0.75,
	physics_gravity = 0.75,
	inventory_main = {x = 4, y = 1},
	inventory_craft = {x = 1, y = 1},
	hotbar = 4,
	inventory = true,
	interact = true,
	eye_offset = {{x = 0, y = -10, z = 0}, {x = 0, y = -10, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
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
	-- Player and mob properties:
	hp_max = 8,
	armor = 100,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4},
	visual = "mesh",
	mesh = "mobs_oerkki.x",
	textures = {"mobs_oerkki.png"},
	visual_size = {x=5, y=5},
	drawtype = "front",
	animation = {
		speed_normal = 15,
		speed_normal_player = 30,
		speed_run = 20,
		stand_start = 0,
		stand_end = 23,
		walk_start = 24,
		walk_end = 36,
		run_start = 37,
		run_end = 49,
		punch_start = 37,
		punch_end = 49,
	},
	makes_footstep_sound = false,
	teams = {"monsters", "people"},

	-- Mob properties:
	type = "monster",
	view_range = 15,
	walk_velocity = 1,
	run_velocity = 3,
	damage = 4,
	drops = {},
	light_resistant = true,
	water_damage = 1,
	lava_damage = 1,
	light_damage = 0,
	attack_type = "dogfight",
	possession = 0.25,

	-- Player properties:
	physics_speed = 1,
	physics_jump = 1,
	physics_gravity = 1,
	inventory_main = {x = 8, y = 4},
	inventory_craft = {x = 3, y = 3},
	hotbar = 8,
	inventory = true,
	interact = true,
	eye_offset = {{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
})
creatures:register_spawn("creatures:oerkki", {"default:stone"}, 2, -1, 7000, 3, -10)

creatures:register_creature("creatures:dungeon_master", {
	-- Player and mob properties:
	hp_max = 10,
	armor = 60,
	collisionbox = {-0.7, -0.01, -0.7, 0.7, 2.6, 0.7},
	visual = "mesh",
	mesh = "mobs_dungeon_master.x",
	textures = {"mobs_dungeon_master.png"},
	visual_size = {x=8, y=8},
	drawtype = "front",
	animation = {
		speed_normal = 15,
		speed_normal_player = 30,
		speed_run = 20,
		stand_start = 0,
		stand_end = 19,
		walk_start = 20,
		walk_end = 35,
		punch_start = 36,
		punch_end = 48,
	},
	makes_footstep_sound = true,
	teams = {"monsters"},

	-- Mob properties:
	type = "monster",
	view_range = 15,
	walk_velocity = 1,
	run_velocity = 3,
	damage = 4,
	drops = {
		{name = "default:mese",
		chance = 100,
		min = 1,
		max = 2,},
	},
	water_damage = 1,
	lava_damage = 1,
	light_damage = 0,
	on_rightclick = nil,
	attack_type = "shoot",
	arrow = "creatures:fireball",
	shoot_interval = 2.5,
	sounds = {
		attack = "mobs_fireball",
	},
	possession = 0.15,

	-- Player properties:
	physics_speed = 1,
	physics_jump = 1.25,
	physics_gravity = 1.25,
	inventory_main = {x = 8, y = 5},
	inventory_craft = {x = 3, y = 3},
	hotbar = 8,
	inventory = true,
	interact = true,
	eye_offset = {{x = 0, y = 5, z = 0}, {x = 0, y = 5, z = 0}},
	sky = {{}, "regular", {}},
	daytime = nil,
	screen = "",
})
creatures:register_spawn("creatures:dungeon_master", {"default:stone"}, 2, -1, 7000, 1, -50)

creatures:register_arrow("creatures:fireball", {
	visual = "sprite",
	visual_size = {x=1, y=1},
	--textures = {{name="mobs_fireball.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=0.5}}}, FIXME
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
