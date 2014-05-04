-- Creature registration - Players:

creatures.player_settings = {}

function creatures:register_player(name, def)
	creatures.player_settings[name] = {}
	creatures.player_settings[name].hp_max = def.hp_max
	creatures.player_settings[name].armor = def.armor
	creatures.player_settings[name].collisionbox = def.collisionbox
	creatures.player_settings[name].visual = def.visual
	creatures.player_settings[name].mesh = def.mesh
	creatures.player_settings[name].textures = def.textures
	creatures.player_settings[name].visual_size = def.visual_size
	creatures.player_settings[name].drawtype = def.drawtype
	creatures.player_settings[name].animation = def.animation
	creatures.player_settings[name].sounds = def.sounds
	creatures.player_settings[name].makes_footstep_sound = def.makes_footstep_sound
	creatures.player_settings[name].water_damage = def.water_damage
	creatures.player_settings[name].lava_damage = def.lava_damage
	creatures.player_settings[name].light_damage = def.light_damage
	creatures.player_settings[name].teams = def.teams
	creatures.player_settings[name].physics_speed = def.physics_speed
	creatures.player_settings[name].physics_jump = def.physics_jump
	creatures.player_settings[name].physics_gravity = def.physics_gravity
	creatures.player_settings[name].inventory_main = def.inventory_main
	creatures.player_settings[name].inventory_craft = def.inventory_craft
	creatures.player_settings[name].hotbar = def.hotbar
	creatures.player_settings[name].inventory = def.inventory
	creatures.player_settings[name].interact = def.interact
	creatures.player_settings[name].reincarnate = def.reincarnate
	creatures.player_settings[name].ghost = def.ghost
	creatures.player_settings[name].eye_offset = def.eye_offset
	creatures.player_settings[name].sky = def.sky
	creatures.player_settings[name].daytime = def.daytime
	creatures.player_settings[name].screen = def.screen
	creatures.player_settings[name].ambience = def.ambience
	creatures.player_settings[name].icon = def.icon
end

-- Functions to handle player settings:

local player_data = {}

local function get_formspec(intentory, size_main, size_craft, icon)
	local image = icon
	if not image or image == "" then
		image = "logo.png"
	end

	if not intentory then
		local formspec =
			"size[1,1]"
			.."image[0,0;1,1;"..image.."]"
		return formspec
	end

	local size = {}
	size.x = math.max(size_main.x, (size_craft.x + 3))
	size.y = size_main.y + size_craft.y + 1
	local formspec =
		"size["..size.x..","..size.y.."]"
		.."image[0,0;1,1;"..image.."]"
		.."list[current_player;craft;"..(size.x - size_craft.x - 2)..",0;"..size_craft.x..","..size_craft.y..";]"
		.."list[current_player;craftpreview;"..(size.x - 1)..","..math.floor(size_craft.y / 2)..";1,1;]"
		.."list[current_player;main;"..(size.x - size_main.x)..","..(size_craft.y + 1)..";"..size_main.x..","..size_main.y..";]"
	return formspec
end

local function set_animation(player, type, speed)
	local name = player:get_player_name()
	if not player_data[name].animation then
		player_data[name].animation = ""
	end
	if type == player_data[name].animation then
		return
	end

	local race = creatures.player_races[name]
	local race_settings = creatures.player_settings[race]
	local animation = race_settings.animation
	if not animation.speed_normal_player then
		return
	end

	if type == "stand" then
		if animation.stand_start and animation.stand_end then
			player:set_animation(
				{x=animation.stand_start, y=animation.stand_end},
				speed, 0)
			player_data[name].animation = "stand"
		end
	elseif type == "walk" then
		if animation.walk_start and animation.walk_end then
			player:set_animation(
				{x=animation.walk_start, y=animation.walk_end},
				speed, 0)
			player_data[name].animation = "walk"
		end
	elseif type == "run" then
		if animation.run_start and animation.run_end then
			player:set_animation(
				{x=animation.run_start, y=animation.run_end},
				speed, 0)
			player_data[name].animation = "run"
		end
	elseif type == "punch" then
		if animation.punch_start and animation.punch_end then
			player:set_animation(
				{x=animation.punch_start, y=animation.punch_end},
				speed, 0)
			player_data[name].animation = "punch"
		end
	end
end

local function apply_settings (player, race)
	minetest.sound_play("creatures_possess", {toplayer = player})
	local def = creatures.player_settings[race]
	local name = player:get_player_name()
	local inv = player:get_inventory()

	-- configure inventory
	inv:set_size("main", def.inventory_main.x * def.inventory_main.y)
	inv:set_size("craft", def.inventory_craft.x * def.inventory_craft.y)
	player:hud_set_hotbar_itemcount(def.hotbar)
	player:hud_set_flags({hotbar = def.inventory, wielditem = def.inventory})
	if not minetest.setting_getbool("creative_mode") and not minetest.setting_getbool("inventory_crafting_full") then
		player:set_inventory_formspec(get_formspec(def.inventory, def.inventory_main, def.inventory_craft, def.icon))
	end

	-- configure properties
	player:set_hp(def.hp_max)
	player:set_armor_groups({fleshy = def.armor})
	player:set_physics_override({speed = def.physics_speed, jump = def.physics_jump, gravity = def.physics_gravity})
	player:set_properties({
		collisionbox = def.collisionbox,
		drawtype = def.drawtype,
		mesh = def.mesh,
		textures = def.textures,
		visual = def.visual,
		visual_size = def.visual_size,
		makes_footstep_sound = def.makes_footstep_sound,
	})

	-- configure visual effects
	player:set_eye_offset(def.eye_offset[1], def.eye_offset[2])
	player:override_day_night_ratio(def.daytime)
	player:set_sky(def.sky[1], def.sky[2], def.sky[3])
	if def.screen and def.screen ~= "" then
		player_data[name].hud = player:hud_add({
			hud_elem_type = "image",
			text = def.screen,
			name = "creatures:screen",
			scale = {x=-100, y=-100},
			position = {x=0, y=0},
			alignment = {x=1, y=1},
		})
	elseif player_data[name].hud then
		player:hud_remove(player_data[name].hud)
		player_data[name].hud = nil
	end

	-- configure sound effects
	if def.ambience and def.ambience ~= "" then
		player_data[name].ambience = minetest.sound_play(def.ambience, {toplayer = name, loop = true})
	elseif player_data[name].ambience then
		minetest.sound_stop(player_data[name].ambience)
		player_data[name].ambience = nil
	end

	-- set local animations
	if def.animation and def.animation.speed_normal_player then
		player:set_local_animation({x = def.animation.stand_start, y = def.animation.stand_end},
			{x = def.animation.walk_start, y = def.animation.walk_end},
			{x = def.animation.punch_start, y = def.animation.punch_end},
			{x = def.animation.walk_start, y = def.animation.walk_end},
			def.animation.speed_normal_player)
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local race = creatures.player_races[name]
		local race_settings = creatures.player_settings[race]

		-- handle player animations
		if race_settings.mesh and race_settings.animation then
			local controls = player:get_player_control()
			-- determine if the player is walking
			local walking = controls.up or controls.down or controls.left or controls.right
			-- determine if the player is sneaking, and reduce animation speed if so
			-- TODO: Use run animation and speed when player is running (fast mode)
			local speed = race_settings.animation.speed_normal_player
			if controls.sneak then
				speed = race_settings.animation.speed_normal_player / 2
			end

			-- apply animations based on what the player is doing
			if player:get_hp() == 0 then
				-- mobs don't have a death animation, make the player invisible here perhaps?
			elseif walking then
				set_animation(player, "walk", speed)
			elseif controls.LMB then
				set_animation(player, "punch", speed)
			else
				set_animation(player, "stand", speed)
			end
		end

		-- play damage sounds
		if player_data[name].last_hp and player:get_hp() < player_data[name].last_hp and player:get_hp() > 0 then
			if race_settings.sounds and race_settings.sounds.damage then
				minetest.sound_play(race_settings.sounds.damage, {object = player})
			end
		end
		player_data[name].last_hp = player:get_hp()

		-- don't let players have more HP than their race allows
		if player:get_hp() > race_settings.hp_max then
			player:set_hp(race_settings.hp_max)
		end

		-- prevent creatures without an inventory from holding any items
		if not race_settings.inventory then
			local inv = player:get_inventory()
			inv:set_list("main", {})
		end

		-- limit execution of code beyond this point
		if not player_data[name].timer then
			player_data[name].timer = 0
		end
		player_data[name].timer = player_data[name].timer + dtime
		if player_data[name].timer < 1 then
			return
		end
		player_data[name].timer = 0

		-- handle player environment damage
		local pos = player:getpos()
		local n = minetest.env:get_node(pos)
		if race_settings.light_damage and race_settings.light_damage ~= 0
			and pos.y > 0
			and minetest.env:get_node_light(pos)
			and minetest.env:get_node_light(pos) > 4
			and minetest.env:get_timeofday() > 0.2
			and minetest.env:get_timeofday() < 0.8
		then
			player:set_hp(player:get_hp() - race_settings.light_damage)
		end
		if race_settings.water_damage and race_settings.water_damage ~= 0 and
			minetest.get_item_group(n.name, "water") ~= 0
		then
			player:set_hp(player:get_hp() - race_settings.water_damage)
		end
		-- NOTE: Lava damage is applied on top of normal player lava damage
		if race_settings.lava_damage and race_settings.lava_damage ~= 0 and
			minetest.get_item_group(n.name, "lava") ~= 0
		then
			player:set_hp(player:get_hp() - race_settings.lava_damage)
		end

		if race_settings.sounds and race_settings.sounds.random and math.random(1, 50) <= 1 then
			minetest.sound_play(race_settings.sounds.random, {object = player})
		end
	end
end)

-- revert any node modified by a creature without interact abilities
minetest.register_on_dignode(function(pos, oldnode, digger)
	local race = creatures.player_races[digger:get_player_name()]
	local race_settings = creatures.player_settings[race]

	if not race_settings.interact then
		minetest.set_node(pos, oldnode)
	end
end)

-- revert any node modified by a creature without interact abilities
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	local race = creatures.player_races[placer:get_player_name()]
	local race_settings = creatures.player_settings[race]

	if not race_settings.interact then
		minetest.set_node(pos, oldnode)
	end
end)

-- handle player death
minetest.register_on_dieplayer(function(player)
	local race = creatures.player_races[player:get_player_name()]
	local race_settings = creatures.player_settings[race]

	if race_settings.sounds and race_settings.sounds.die then
		minetest.sound_play(race_settings.sounds.die, {object = player})
	end
end)

-- turn the player into its ghost upon respawn
minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()
	local race = creatures.player_races[name]
	local race_settings = creatures.player_settings[race]
	local ghost = race_settings.ghost
	if not ghost or ghost == "" then
		ghost = creatures.player_default
	end

	if race ~= ghost then
		creatures:set_race (player, ghost)
		minetest.sound_play("creatures_ghost", {toplayer = name})
		return true
	end
end)

-- set player race and data upon joining
minetest.register_on_joinplayer(function(player)
	player_data[player:get_player_name()] = {}
	local race = creatures:get_race(player)
	if not race then
		creatures:set_race(player, creatures.player_default)
	else
		creatures:set_race(player, race)
	end
end)

-- Global functions to get or set player races:

creatures.player_races = {}

function creatures:set_race (player, race)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end
	apply_settings(player, race)
	creatures.player_races[pname] = race
end

function creatures:get_race (player)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end
	return creatures.player_races[pname]
end

-- Save and load player races to and from file:

local file = io.open(minetest:get_worldpath().."/races.txt", "r")
if file then
	local table = minetest.deserialize(file:read("*all"))
	if type(table) == "table" then
		creatures.player_races = table
	else
		minetest.log("error", "Corrupted player races file")
	end
	file:close()
end

local function save_races()
	local file = io.open(minetest:get_worldpath().."/races.txt", "w")
	if file then
		file:write(minetest.serialize(creatures.player_races))
		file:close()
	else
		minetest.log("error", "Can't save player races to file")
	end
end

local save_races_timer = 0
minetest.register_globalstep(function(dtime)
	save_races_timer = save_races_timer + dtime
	if save_races_timer > 10 then
		save_races_timer = 0
		save_races()
	end
end)

minetest.register_on_shutdown(function()
	save_races()
end)
