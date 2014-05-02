-- Creature registration - Players:

creatures.players = {}

function creatures:register_player(name, def)
	creatures.players[name] = {}
	creatures.players[name].hp_max = def.hp_max
	creatures.players[name].armor = def.armor
	creatures.players[name].collisionbox = def.collisionbox
	creatures.players[name].visual = def.visual
	creatures.players[name].mesh = def.mesh
	creatures.players[name].textures = def.textures
	creatures.players[name].visual_size = def.visual_size
	creatures.players[name].drawtype = def.drawtype
	creatures.players[name].animation = def.animation
	creatures.players[name].makes_footstep_sound = def.makes_footstep_sound
	creatures.players[name].teams = def.teams
	creatures.players[name].physics_speed = def.physics_speed
	creatures.players[name].physics_jump = def.physics_jump
	creatures.players[name].physics_gravity = def.physics_gravity
	creatures.players[name].inventory_main = def.inventory_main
	creatures.players[name].inventory_craft = def.inventory_craft
	creatures.players[name].eye_offset = def.eye_offset
end

-- Functions to handle player settings:

creatures.hud = {}

local function get_formspec(ghost, size_main, size_craft)
	if ghost then
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
	if not race then race = "ghost" end
	local settings = creatures.players[race]
	local name = player:get_player_name()
	local inv = player:get_inventory()
	-- configure inventory
	inv:set_size("main", settings.inventory_main.x * settings.inventory_main.y)
	inv:set_size("craft", settings.inventory_craft.x * settings.inventory_craft.y)
	player:hud_set_hotbar_itemcount(settings.hotbar)
	player:hud_set_flags({hotbar = not (race == "ghost"), wielditem = not (race == "ghost")})
	if not minetest.setting_getbool("creative_mode") and not minetest.setting_getbool("inventory_crafting_full") then
		player:set_inventory_formspec(get_formspec((race == "ghost"), settings.inventory_main, settings.inventory_craft))
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
	player:set_eye_offset(settings.eye_offset[1], settings.eye_offset[2])
	-- configure visuals
	if (race == "ghost") then
		player:override_day_night_ratio(0.15)
		player:set_sky({r = 64, g = 0, b = 128}, "plain", {})
		if not creatures.hud[name] then
			creatures.hud[name] = player:hud_add({
				hud_elem_type = "image",
				text = "hud_ghost.png",
				name = "hud_ghost",
				scale = {x=-100, y=-100},
				position = {x=0, y=0},
				alignment = {x=1, y=1},
			})
		end
	else
		player:override_day_night_ratio(nil)
		player:set_sky({}, "regular", {})
		if creatures.hud[name] then
			player:hud_remove(creatures.hud[name])
			creatures.hud[name] = nil
		end
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local race = creatures.races[player:get_player_name()]
		if not race then race = "ghost" end
		local race_settings = creatures.players[race]

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
				-- mobs don't have a death animation, make the player invisible here instead
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

		-- prevent ghosts from having any items
		if not race or race == "ghost" then
			local inv = player:get_inventory()
			inv:set_list("main", {})
		end
	end
end)

-- revert any node modified by a ghost
minetest.register_on_dignode(function(pos, oldnode, digger)
	local race = creatures.races[digger:get_player_name()]
	if not race or race == "ghost" then
		minetest.set_node(pos, oldnode)
	end
end)

-- revert any node modified by a ghost
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	local race = creatures.races[placer:get_player_name()]
	if not race or race == "ghost" then
		minetest.set_node(pos, oldnode)
	end
end)

-- turn the player into a ghost when he dies
minetest.register_on_respawnplayer(function(player)
	local race = creatures.races[player:get_player_name()]
	if race then
		creatures:set_race (player, nil)
		return true
	end
end)

-- Global functions to read or change player settings:

creatures.races = {}

function creatures:set_race (player, race)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end

	local prace = race
	if prace == "ghost" then
		prace = nil
	end
	creatures.races[pname] = prace
	apply_settings(player, prace)
end

function creatures:get_race (player)
	local pname = player
	if type(pname) ~= "string" then
		pname = player:get_player_name()
	end

	local prace = creatures.races[pname]
	if prace == "ghost" then
		prace = nil
	end
	return prace
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0, function() creatures:set_race(player, nil) end)
end)
