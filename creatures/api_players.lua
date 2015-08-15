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
	creatures.player_def[name].particles = def.particles
	creatures.player_def[name].visual_size = def.visual_size
	creatures.player_def[name].animation = def.animation
	creatures.player_def[name].sounds = def.sounds
	creatures.player_def[name].makes_footstep_sound = def.makes_footstep_sound
	creatures.player_def[name].env_damage = def.env_damage
	creatures.player_def[name].teams = def.teams
	creatures.player_def[name].physics = def.physics
	creatures.player_def[name].inventory_main = def.inventory_main
	creatures.player_def[name].inventory_craft = def.inventory_craft
	creatures.player_def[name].ghost = def.ghost
	creatures.player_def[name].eye_offset = def.eye_offset
	creatures.player_def[name].fog = def.fog
	creatures.player_def[name].screen = def.screen
	creatures.player_def[name].ambience = def.ambience
	creatures.player_def[name].icon = def.icon
	creatures.player_def[name].player_join = def.player_join
	creatures.player_def[name].player_step = def.player_step
	creatures.player_def[name].player_hpchange = def.player_hpchange
	creatures.player_def[name].player_die = def.player_die
	creatures.player_def[name].player_respawn = def.player_respawn
	creatures.player_def[name].custom = def.custom
end

-- Functions to handle player settings:

player_data = {}

function creatures:player_animation_get(player)
	local name = player:get_player_name()
	return player_data[name].animation
end

function creatures:player_animation_set(player, type, speed)
	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]

	if not race_settings.animation or type == player_data[name].animation then
		return
	end

	local animation_this = race_settings.animation[type]
	local speed_this = animation_this.speed * speed

	player:set_animation({x = animation_this.x, y = animation_this.y}, speed_this, animation_this.blend, animation_this.loop)
	player_data[name].animation = type
end

local function configure_player (player, settings)
	local name = player:get_player_name()
	local inv = player:get_inventory()
	local def = creatures.player_def[settings.name]
	-- allow custom settings to overwrite anything in def
	for entry, value in pairs(settings) do
		def[entry] = value
	end

	-- set HP accordingly
	if def.hp then
		minetest.sound_play("creatures_possess", {to_player = player})
		if def.hp > 0 then
			player:set_hp(def.hp)
		else
			player:set_hp(def.hp_max)
		end
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
	local formspec = creatures.player_formspec(def)
	if formspec then
		minetest.after(0, function()
			player:set_inventory_formspec(creatures.player_formspec(def))
		end)
	end

	-- player: configure properties
	player:set_armor_groups(def.armor)
	player:set_physics_override({speed = def.physics.speed, jump = def.physics.jump, gravity = def.physics.gravity})
	player:set_properties({
		collisionbox = def.collisionbox,
		mesh = def.mesh,
		textures = def.textures[def.skin] or def.textures,
		visual = def.visual,
		visual_size = def.visual_size,
		makes_footstep_sound = def.makes_footstep_sound,
	})

	-- player: configure visual effects
	player:set_eye_offset(def.eye_offset[1], def.eye_offset[2])
	if def.fog then
		player:set_sky(def.fog, "plain", {})
	else
		player:set_sky({}, "regular", {})
	end
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
		player_data[name].ambience = minetest.sound_play(def.ambience, {to_player = name, loop = true})
	elseif player_data[name].ambience then
		minetest.sound_stop(player_data[name].ambience)
		player_data[name].ambience = nil
	end

	-- player: set local animations
	if def.animation then
		player:set_local_animation(
			{x = def.animation["stand"].x, y = def.animation["stand"].y},
			{x = def.animation["walk"].x, y = def.animation["walk"].y},
			{x = def.animation["punch"].x, y = def.animation["punch"].y},
			{x = def.animation["walk_punch"].x, y = def.animation["walk_punch"].y},
			def.animation["stand"].speed)
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local race = creatures:player_get(name)
		local race_settings = creatures.player_def[race]
		if race and race_settings then
			race_settings.player_step(player, dtime)
		end
	end
end)

minetest.register_on_player_hpchange(function(player, hp_change)
	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]
	if race and race_settings then
		race_settings.player_hpchange(player, hp_change)
	end
end)

minetest.register_on_dieplayer(function(player)
	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]
	if race and race_settings then
		race_settings.player_die(player)
	end
end)

minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]
	if race and race_settings then
		race_settings.player_respawn(player)
	end
	return true
end)

minetest.register_on_joinplayer(function(player)
	-- apply persisted player race or set default race
	player_data[player:get_player_name()] = {}
	local get_name, get_skin = creatures:player_get(player)
	creatures:player_set(player, {name = get_name, skin = get_skin})

	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]
	if race and race_settings then
		race_settings.player_join(player)
	end
end)

-- Global functions to get or set player races:

creatures.player_settings = {}

function creatures:player_set (player, settings)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end

	-- use the default race if no valid creature is specified
	if not creatures.player_def[settings.name] then
		settings.name = creatures.player_default
		settings.hp = 0
	end
	-- make sure the skin is valid
	local textures = creatures.player_def[settings.name].textures
	if textures and type(textures[1]) == "table" then
		if not settings.skin or settings.skin == 0 or not textures[settings.skin] then
			settings.skin = math.random(1, #textures)
		end
	else
		settings.skin = 0
	end

	configure_player(player, settings)
	-- structure: [1] = name, [2] = skin
	creatures.player_settings[pname] = {}
	creatures.player_settings[pname][1] = settings.name or creatures.player_default
	creatures.player_settings[pname][2] = settings.skin or 0
end

function creatures:player_get (player)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end

	-- structure: [1] = name, [2] = skin
	if type(creatures.player_settings[pname]) == "table" then
		return creatures.player_settings[pname][1], creatures.player_settings[pname][2]
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
