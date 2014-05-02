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
	creatures.player_settings[name].makes_footstep_sound = def.makes_footstep_sound
	creatures.player_settings[name].teams = def.teams
	creatures.player_settings[name].physics_speed = def.physics_speed
	creatures.player_settings[name].physics_jump = def.physics_jump
	creatures.player_settings[name].physics_gravity = def.physics_gravity
	creatures.player_settings[name].inventory_main = def.inventory_main
	creatures.player_settings[name].inventory_craft = def.inventory_craft
	creatures.player_settings[name].hotbar = def.hotbar
	creatures.player_settings[name].inventory = def.inventory
	creatures.player_settings[name].interact = def.interact
	creatures.player_settings[name].eye_offset = def.eye_offset
	creatures.player_settings[name].sky = def.sky
	creatures.player_settings[name].daytime = def.daytime
	creatures.player_settings[name].screen = def.screen
end

-- Functions to handle player settings:

local player_hud = {}

local function get_formspec(intentory, size_main, size_craft)
	if not intentory then
		return "size[1,1]"
	end

	local size = {}
	size.x = math.max(size_main.x, (size_craft.x + 2))
	size.y = size_main.y + size_craft.y + 1
	local formspec =
		"size["..size.x..","..size.y.."]"
		.."list[current_player;craft;"..(size.x - size_craft.x - 2)..",0;"..size_craft.x..","..size_craft.y..";]"
		.."list[current_player;craftpreview;"..(size.x - 1)..","..math.floor(size_craft.y / 2)..";1,1;]"
		.."list[current_player;main;"..(size.x - size_main.x)..","..(size_craft.y + 1)..";"..size_main.x..","..size_main.y..";]"
	return formspec
end

local function apply_settings (player, race)
	if not race then race = "default" end
	local settings = creatures.player_settings[race]
	local name = player:get_player_name()
	local inv = player:get_inventory()
	-- configure inventory
	inv:set_size("main", settings.inventory_main.x * settings.inventory_main.y)
	inv:set_size("craft", settings.inventory_craft.x * settings.inventory_craft.y)
	player:hud_set_hotbar_itemcount(settings.hotbar)
	player:hud_set_flags({hotbar = settings.inventory, wielditem = settings.inventory})
	if not minetest.setting_getbool("creative_mode") and not minetest.setting_getbool("inventory_crafting_full") then
		player:set_inventory_formspec(get_formspec(settings.inventory, settings.inventory_main, settings.inventory_craft))
	end
	-- configure properties
	player:set_hp(settings.hp_max)
	player:set_armor_groups({fleshy = settings.armor})
	player:set_physics_override({speed = settings.physics_speed, jump = settings.physics_jump, gravity = settings.physics_gravity})
	player:set_properties({
		collisionbox = settings.collisionbox,
		drawtype = settings.drawtype,
		mesh = settings.mesh,
		textures = settings.textures,
		visual = settings.visual,
		visual_size = settings.visual_size,
		makes_footstep_sound = settings.makes_footstep_sound,
	})
	-- configure visual effects
	player:set_eye_offset(settings.eye_offset[1], settings.eye_offset[2])
	player:override_day_night_ratio(settings.daytime)
	player:set_sky(settings.sky[1], settings.sky[2], settings.sky[3])
	if settings.screen ~= "" then
		player_hud[name] = player:hud_add({
			hud_elem_type = "image",
			text = settings.screen,
			name = "creatures:screen",
			scale = {x=-100, y=-100},
			position = {x=0, y=0},
			alignment = {x=1, y=1},
		})
	elseif player_hud[name] then
		player:hud_remove(player_hud[name])
		player_hud[name] = nil
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local race = creatures.player_races[player:get_player_name()]
		if not race then race = "default" end
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
				player:set_animation({x = race_settings.animation.walk_start, y = race_settings.animation.walk_end}, speed)
			elseif controls.LMB then
				player:set_animation({x = race_settings.animation.punch_start, y = race_settings.animation.punch_end}, speed)
			else
				player:set_animation({x = race_settings.animation.stand_start, y = race_settings.animation.stand_end}, speed)
			end
			-- set local animations
			player:set_local_animation({x = race_settings.animation.stand_start, y = race_settings.animation.stand_end},
			{x = race_settings.animation.walk_start, y = race_settings.animation.walk_end},
			{x = race_settings.animation.punch_start, y = race_settings.animation.punch_end},
			{x = race_settings.animation.walk_start, y = race_settings.animation.walk_end},
			race_settings.animation.speed_normal_player)
		end

		-- prevent creatures without an inventory from holding any items
		if not race_settings.inventory then
			local inv = player:get_inventory()
			inv:set_list("main", {})
		end
	end
end)

-- revert any node modified by a creature without interact abilities
minetest.register_on_dignode(function(pos, oldnode, digger)
	local race = creatures.player_races[digger:get_player_name()]
	if not race then race = "default" end
	local race_settings = creatures.player_settings[race]

	if not race_settings.interact then
		minetest.set_node(pos, oldnode)
	end
end)

-- revert any node modified by a creature without interact abilities
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	local race = creatures.player_races[placer:get_player_name()]
	if not race then race = "default" end
	local race_settings = creatures.player_settings[race]

	if not race_settings.interact then
		minetest.set_node(pos, oldnode)
	end
end)

-- turn the player into a ghost upon death
minetest.register_on_respawnplayer(function(player)
	local race = creatures.player_races[player:get_player_name()]
	if race then
		creatures:set_race (player, nil)
		return true
	end
end)

-- Global functions to get or set player races:

creatures.player_races = {}

function creatures:set_race (player, race)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end

	local prace = race
	if prace == "default" then
		prace = nil
	end
	creatures.player_races[pname] = prace
	apply_settings(player, prace)
end

function creatures:get_race (player)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end

	local prace = creatures.player_races[pname]
	if prace == "default" then
		prace = nil
	end
	return prace
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0, function() creatures:set_race(player, nil) end)
end)
