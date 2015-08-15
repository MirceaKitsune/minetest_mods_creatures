-- Creature settings - Players, logics:

-- This file contains the default functions for players. Advanced users can use a different function set instead of this, or execute additional code.

-- set player audibility for node placement
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	local sounds = minetest.registered_items[newnode.name].sounds
	local sound = sounds and sounds.place
	if sound then
		creatures:audibility_set(placer, sound.gain, 1)
	end
end)

-- set player audibility for node digging
minetest.register_on_dignode(function(pos, oldnode, digger)
	local sounds = minetest.registered_items[oldnode.name].sounds
	local sound = sounds and (sounds.dig or sounds.dug)
	if sound then
		creatures:audibility_set(digger, sound.gain, 1)
	end
end)

-- set player audibility for node punching
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	local sounds = minetest.registered_items[node.name].sounds
	local sound = sounds and (sounds.dig or sounds.dug)
	if sound then
		creatures:audibility_set(puncher, sound.gain, 1)
	end
end)

-- logic_player_hpchange: Executed in minetest.register_on_player_hpchange, handles: damage
function logic_player_hpchange (player, hp_change)
	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]

	if hp_change < 0 then
		-- play damage sounds
		if race_settings.sounds and race_settings.sounds.damage then
			creatures:sound(race_settings.sounds.damage, player)
		end

		-- spawn damage particles
		creatures:particles(player, nil)
	end
end

-- logic_player_step: Executed in minetest.register_globalstep, handles: animations, movement, damage
function logic_player_step (player, dtime)
	local name = player:get_player_name()
	local race = creatures:player_get(name)
	local race_settings = creatures.player_def[race]
	local controls = player:get_player_control()

	-- handle player animations
	if race_settings.mesh and race_settings.animation then
		-- determine if the player is walking
		local walking = controls.up or controls.down or controls.left or controls.right
		-- determine if the player is sneaking, and reduce animation speed if so
		-- TODO: Use 2x speed when the player is running (fast mode)
		local speed = 1
		if controls.sneak then
			speed = 0.5
		end

		-- apply animations based on what the player is doing
		if player:get_hp() == 0 then
			-- TODO: mobs don't have a death animation, make the player invisible here
		elseif walking and controls.LMB then
			creatures:animation_set(player, "walk_punch", speed)
		elseif walking then
			creatures:animation_set(player, "walk", speed)
		elseif controls.LMB then
			creatures:animation_set(player, "punch", speed)
		else
			creatures:animation_set(player, "stand", speed)
		end
	end

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

	local pos = player:getpos()
	local n = minetest.env:get_node(pos)
	local l = minetest.env:get_node_light(pos)

	-- set player audibility for node footsteps
	-- since we can't easily get the player's velocity, check movement keys
	if controls.jump or
	((controls.up or controls.down) and not (controls.up and controls.down) and not controls.sneak) or
	((controls.left or controls.right) and not (controls.left and controls.right) and not controls.sneak) then
		local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
		local node_under = minetest.env:get_node(pos_under)
		local sounds = minetest.registered_items[node_under.name].sounds
		local sound = sounds and sounds.footstep
		if sound then
			creatures:audibility_set(player, sound.gain, 1)
		end
	end

	-- environment damage: add light damage
	if race_settings.env_damage.light and race_settings.env_damage.light ~= 0 and l and
	(l >= race_settings.env_damage.light_level or l < -race_settings.env_damage.light_level) then
		player:set_hp(player:get_hp() - race_settings.env_damage.light)
	end

	-- environment damage: add group damage
	if race_settings.env_damage.groups then
		for group, amount in pairs(race_settings.env_damage.groups) do
			if amount ~= 0 and minetest.get_item_group(n.name, group) ~= 0 then
				player:set_hp(player:get_hp() - amount)
			end
		end
	end
end

-- logic_player_die: Executed in minetest.register_on_dieplayer, handles: death
function logic_player_die (player)
	local race = creatures:player_get(player:get_player_name())
	local race_settings = creatures.player_def[race]

	if race_settings.sounds and race_settings.sounds.die then
		creatures:sound(race_settings.sounds.die, player)
	end

	-- drop the player's inventory
	local pos = player:getpos()
	local inv = player:get_inventory()
	local size = inv:get_size("main")
	for i = 1, size do
		local stack = inv:get_stack("main", i)
		if not stack:is_empty() then
			local obj = minetest.env:add_item(pos, stack)
			obj:setvelocity({x = 1 - math.random() * 2, y = obj:getvelocity().y, z = 1 - math.random() * 2})
		end
	end
	inv:set_list("main", {})
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
		minetest.sound_play("creatures_ghost", {to_player = name})
	end
end

-- logic_player_join: Executed in minetest.register_on_joinplayer, handles: initialization
function logic_player_join (player)
	creatures:animation_set(player, "stand", 1)
end
