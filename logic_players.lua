-- Creature settings - Players, logics:

-- This file contains the default functions for players. Advanced users can use a different function set instead of this, or execute additional code.

-- logic_player_step: Executed in minetest.register_globalstep, handles: animations, movement, damage
function logic_player_step (player, dtime)
	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]
	if not race or not race_settings then
		return
	end

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
			creatures:set_animation(player, "walk_punch", speed)
		elseif walking then
			creatures:set_animation(player, "walk", speed)
		elseif controls.LMB then
			creatures:set_animation(player, "punch", speed)
		else
			creatures:set_animation(player, "stand", speed)
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
end

-- logic_player_die: Executed in minetest.register_on_dieplayer, handles: death
function logic_player_die (player)
	local race = creatures:player_get(player:get_player_name())
	local race_settings = creatures.player_def[race]

	if race_settings.sounds and race_settings.sounds.die then
		minetest.sound_play(race_settings.sounds.die, {object = player})
	end
end

-- logic_player_respawn: Executed in minetest.register_on_respawnplayer, handles: respawn, creature settings
function logic_player_respawn (player)
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
	end
end

-- logic_player_join: Executed in minetest.register_on_joinplayer, handles: N/A
function logic_player_join (player)
	-- currently there is no default on_joinplayer function
end
