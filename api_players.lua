-- Creature registration - Players:

creatures.player_def = {}

function creatures:register_player(name, def)
	creatures.player_def[name] = {}
	creatures.player_def[name].hp_max = def.hp_max
	creatures.player_def[name].armor = def.armor
	creatures.player_def[name].collisionbox = def.collisionbox
	creatures.player_def[name].visual = def.visual
	creatures.player_def[name].mesh = def.mesh
	creatures.player_def[name].textures = def.textures
	creatures.player_def[name].visual_size = def.visual_size
	creatures.player_def[name].animation = def.animation
	creatures.player_def[name].sounds = def.sounds
	creatures.player_def[name].makes_footstep_sound = def.makes_footstep_sound
	creatures.player_def[name].env_damage = def.env_damage
	creatures.player_def[name].teams = def.teams
	creatures.player_def[name].physics = def.physics
	creatures.player_def[name].menu = def.menu
	creatures.player_def[name].inventory_main = def.inventory_main
	creatures.player_def[name].inventory_craft = def.inventory_craft
	creatures.player_def[name].reincarnate = def.reincarnate
	creatures.player_def[name].ghost = def.ghost
	creatures.player_def[name].eye_offset = def.eye_offset
	creatures.player_def[name].sky = def.sky
	creatures.player_def[name].daytime = def.daytime
	creatures.player_def[name].screen = def.screen
	creatures.player_def[name].ambience = def.ambience
	creatures.player_def[name].icon = def.icon
end

-- Functions to handle player settings:

local player_data = {}

local function get_formspec(size_main, size_craft, icon)
	local image = icon
	if not image or image == "" then
		image = "logo.png"
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

	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]
	local animation = race_settings.animation
	if not animation.speed then
		return
	end

	if type == "stand" then
		if animation.stand then
			player:set_animation(
				{x=animation.stand[1], y=animation.stand[2]},
				speed, 0)
			player_data[name].animation = "stand"
		end
	elseif type == "walk" then
		if animation.walk then
			player:set_animation(
				{x=animation.walk[1], y=animation.walk[2]},
				speed, 0)
			player_data[name].animation = "walk"
		end
	elseif type == "walk_punch" then
		if animation.walk_punch then
			player:set_animation(
				{x=animation.walk_punch[1], y=animation.walk_punch[2]},
				speed, 0)
			player_data[name].animation = "walk_punch"
		end
	elseif type == "punch" then
		if animation.punch then
			player:set_animation(
				{x=animation.punch[1], y=animation.punch[2]},
				speed, 0)
			player_data[name].animation = "punch"
		end
	end
end

local function apply_settings (player, settings)
	if not settings then
		return
	end
	local name = player:get_player_name()
	local inv = player:get_inventory()
	local def = creatures.player_def[settings.name or creatures.player_default]
	-- allow custom settings to overwrite anything in def
	for entry, value in pairs(settings) do
		def[entry] = value
	end

	-- set HP accordingly
	if def.hp then
		minetest.sound_play("creatures_possess", {toplayer = player})
		if def.hp > 0 then
			player:set_hp(def.hp)
		else
			player:set_hp(def.hp_max)
		end
	end

	-- if the textures field contains tables, we have multiple texture sets
	if def.textures and type(def.textures[1]) == "table" then
		if not def.skin or not def.textures[def.skin] then
			def.skin = math.random(1, #def.textures)
		end
		def.textures = def.textures[def.skin]
	end

	-- player: configure inventory
	local inv_main = def.inventory_main.x * def.inventory_main.y
	if inv:get_size("main") ~= inv_main then
		inv:set_size("main", inv_main)
		inv:set_width("main", def.inventory_main.x)
	end
	local inv_craft = def.inventory_craft.x * def.inventory_craft.y
	if inv:get_size("craft") ~= inv_craft then
		inv:set_size("craft", inv_craft)
		inv:set_width("craft", def.inventory_craft.x)
	end
	player:hud_set_hotbar_itemcount(def.inventory_main.x)
	if not minetest.setting_getbool("creative_mode") and not minetest.setting_getbool("inventory_crafting_full") then
		if def.menu then
			player:set_inventory_formspec(get_formspec(def.inventory_main, def.inventory_craft, def.icon))
		else
			player:set_inventory_formspec("size[1,1]image[0,0;1,1;"..def.icon.."]")
		end
	end

	-- player: configure properties
	player:set_armor_groups({fleshy = def.armor})
	player:set_physics_override({speed = def.physics.speed, jump = def.physics.jump, gravity = def.physics.gravity})
	player:set_properties({
		collisionbox = def.collisionbox,
		mesh = def.mesh,
		textures = def.textures,
		visual = def.visual,
		visual_size = def.visual_size,
		makes_footstep_sound = def.makes_footstep_sound,
	})

	-- player: configure visual effects
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

	-- player: configure sound effects
	if def.ambience and def.ambience ~= "" then
		player_data[name].ambience = minetest.sound_play(def.ambience, {toplayer = name, loop = true})
	elseif player_data[name].ambience then
		minetest.sound_stop(player_data[name].ambience)
		player_data[name].ambience = nil
	end

	-- player: set local animations
	if def.animation and def.animation.speed then
		player:set_local_animation({x = def.animation.stand[1], y = def.animation.stand[2]},
			{x = def.animation.walk[1], y = def.animation.walk[2]},
			{x = def.animation.punch[1], y = def.animation.punch[2]},
			{x = def.animation.walk_punch[1], y = def.animation.walk_punch[2]},
			def.animation.speed)
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local race = creatures:player_get(name)
		local race_settings = creatures.player_def[race]

		-- handle player animations
		if race_settings.mesh and race_settings.animation then
			local controls = player:get_player_control()
			-- determine if the player is walking
			local walking = controls.up or controls.down or controls.left or controls.right
			-- determine if the player is sneaking, and reduce animation speed if so
			-- TODO: Use run animation and speed when player is running (fast mode)
			local speed = race_settings.animation.speed
			if controls.sneak then
				speed = race_settings.animation.speed / 2
			end

			-- apply animations based on what the player is doing
			if player:get_hp() == 0 then
				-- TODO: mobs don't have a death animation, make the player invisible here
			elseif walking and controls.LMB then
				set_animation(player, "walk_punch", speed)
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
		if race_settings.env_damage.light and race_settings.env_damage.light ~= 0
			and pos.y > 0
			and minetest.env:get_node_light(pos)
			and minetest.env:get_node_light(pos) > 4
			and minetest.env:get_timeofday() > 0.2
			and minetest.env:get_timeofday() < 0.8
		then
			player:set_hp(player:get_hp() - race_settings.env_damage.light)
		end
		if race_settings.env_damage.water and race_settings.env_damage.water ~= 0 and
			minetest.get_item_group(n.name, "water") ~= 0
		then
			player:set_hp(player:get_hp() - race_settings.env_damage.water)
		end
		-- NOTE: Lava damage is applied on top of normal player lava damage
		if race_settings.env_damage.lava and race_settings.env_damage.lava ~= 0 and
			minetest.get_item_group(n.name, "lava") ~= 0
		then
			player:set_hp(player:get_hp() - race_settings.env_damage.lava)
		end

		if race_settings.sounds and race_settings.sounds.random and math.random(1, 50) <= 1 then
			minetest.sound_play(race_settings.sounds.random, {object = player})
		end
	end
end)

-- handle player death
minetest.register_on_dieplayer(function(player)
	local race = creatures:player_get(player:get_player_name())
	local race_settings = creatures.player_def[race]

	if race_settings.sounds and race_settings.sounds.die then
		minetest.sound_play(race_settings.sounds.die, {object = player})
	end
end)

-- turn the player into its ghost upon respawn
minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]
	local ghost = race_settings.ghost
	if not ghost or ghost == "" then
		ghost = creatures.player_default
	end

	if race ~= ghost then
		creatures:player_set (player, {name = ghost, hp = 0})
		minetest.sound_play("creatures_ghost", {toplayer = name})
		return true
	end
end)

-- set player race and data upon joining
minetest.register_on_joinplayer(function(player)
	player_data[player:get_player_name()] = {}
	local get_name, get_skin = creatures:player_get(player)
	creatures:player_set(player, {name = get_name, skin = get_skin})
end)

-- Global functions to get or set player races:

creatures.player_settings = {}

function creatures:player_set (player, settings)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end
	apply_settings(player, settings)

	-- structure: [1] = name, [2] = skin
	creatures.player_settings[pname] = {}
	creatures.player_settings[pname][1] = settings.name or creatures.player_default
	creatures.player_settings[pname][2] = settings.skin or 1
end

function creatures:player_get (player)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end

	-- structure: [1] = name, [2] = skin
	if type(creatures.player_settings[pname]) == "table" then
		return creatures.player_settings[pname][1], creatures.player_settings[pname][2]
	-- old format which contained only the name
	else
		return creatures.player_settings[pname]
	end
end

-- Save and load player races to and from file:

local file = io.open(minetest:get_worldpath().."/races.txt", "r")
if file then
	local table = minetest.deserialize(file:read("*all"))
	if type(table) == "table" then
		creatures.player_settings = table
	else
		minetest.log("error", "Corrupted player races file")
	end
	file:close()
end

local function save_races()
	local file = io.open(minetest:get_worldpath().."/races.txt", "w")
	if file then
		file:write(minetest.serialize(creatures.player_settings))
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
