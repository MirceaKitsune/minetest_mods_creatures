-- Creature registration - Mobs:

function creatures:register_mob(name, def)
	-- Players are offset by 1 node in the Minetest code. In order for mobs to have the same height, we must apply a similar offset to them
	-- This is a bad choice, as the real position of mobs will be off by one unit. But it's the only way to make players and mobs work with the same models
	def.collisionbox[2] = def.collisionbox[2] - 1
	def.collisionbox[5] = def.collisionbox[5] - 1

	minetest.register_entity(name, {
		hp_max = def.hp_max,
		physical = true,
		collisionbox = def.collisionbox,
		visual = def.visual,
		visual_size = def.visual_size,
		mesh = def.mesh,
		textures = def.textures,
		makes_footstep_sound = def.makes_footstep_sound,
		env_damage = def.env_damage,
		disable_fall_damage = def.disable_fall_damage,
		drops = def.drops,
		armor = def.armor,
		icon = def.icon,
		nodes = def.nodes,
		attack_damage = def.attack_damage,
		attack_type = def.attack_type,
		attack_arrow = def.attack_arrow,
		sounds = def.sounds,
		animation = def.animation,
		jump = def.jump or true,
		teams = def.teams,
		teams_target = def.teams_target or {attack = true, avoid = true, follow = true},
		traits = def.traits, -- set in on_activate
		names = def.names, -- set in on_activate
		custom = def.custom,

		on_step = def.on_step,
		on_rightclick = def.on_rightclick,
		on_activate = def.on_activate,
		on_punch = def.on_punch,

		timer_life = 60,
		timer_think = 0,
		timer_attack = 0,
		timer_env_damage = 0,
		walk_velocity = tonumber(minetest.setting_get("movement_speed_walk")) * def.physics.speed,
		run_velocity = tonumber(minetest.setting_get("movement_speed_fast")) * def.physics.speed,
		jump_velocity = tonumber(minetest.setting_get("movement_speed_jump")) * def.physics.jump,
		gravity = tonumber(minetest.setting_get("movement_gravity")) * def.physics.gravity,
		skin = 0,
		targets = {},
		target_current = nil,
		in_liquid = false,
		v_pos = nil,
		v_avoid = false,
		v_speed = nil,
		v_start = false,
		v_path = nil,
		old_y = nil,
		actor = false,

		get_velocity = function(self)
			local v = self.object:getvelocity()
			return (v.x^2 + v.z^2)^(0.5)
		end,
		
		set_velocity = function(self, v)
			local yaw = self.object:getyaw()
			local x = math.sin(yaw) * -v
			local z = math.cos(yaw) * v
			self.object:setvelocity({x=x, y=self.object:getvelocity().y, z=z})
		end,
		
		set_animation = function(self, type)
			if not self.animation or not self.animation.speed then
				return
			end
			if not self.animation.current then
				self.animation.current = ""
			end
			if type == self.animation.current then
				return
			end

			local speed = self.animation.speed
			if self.get_velocity(self) >= (self.walk_velocity + self.run_velocity) / 2 then
				speed = self.animation.speed * 2
			end

			if type == "stand" then
				if self.animation.stand then
					self.object:set_animation(
						{x=self.animation.stand[1], y=self.animation.stand[2]},
						speed, 0)
					self.animation.current = "stand"
				end
			elseif type == "walk" then
				if self.animation.walk then
					self.object:set_animation(
						{x=self.animation.walk[1], y=self.animation.walk[2]},
						speed, 0)
					self.animation.current = "walk"
				end
			elseif type == "walk_punch" then
				if self.animation.walk_punch then
					self.object:set_animation(
						{x=self.animation.walk_punch[1], y=self.animation.walk_punch[2]},
						speed, 0)
					self.animation.current = "walk_punch"
				end
			elseif type == "punch" then
				if self.animation.punch then
					self.object:set_animation(
						{x=self.animation.punch[1], y=self.animation.punch[2]},
						speed, 0)
					self.animation.current = "punch"
				end
			end
		end,

		get_staticdata = function(self)
			local tmp = {}
			tmp.skin = self.skin
			tmp.timer_life = self.timer_life
			tmp.actor = self.actor
			tmp.traits = self.traits
			tmp.names = self.names
			-- only add persistent targets
			tmp.targets = {}
			for obj, target in pairs(self.targets) do
				if target.persist then
					tmp.targets[obj] = target
				end
			end
			return minetest.serialize(tmp)
		end,

		set_staticdata = function(self, staticdata, dtime_s)
			if staticdata then
				local tmp = minetest.deserialize(staticdata)
				if tmp and tmp.skin then
					self.skin = tmp.skin
				end
				if tmp and tmp.timer_life then
					self.timer_life = tmp.timer_life - dtime_s
				end
				if tmp and tmp.actor then
					self.actor = tmp.actor
				end
				if tmp and tmp.traits then
					self.traits = tmp.traits
				end
				if tmp and tmp.names then
					self.names = tmp.names
				end
				if tmp and tmp.targets then
					self.targets = tmp.targets
				end
			end
		end,
	})
end

-- Mob spawning:

creatures.spawning_mobs = {}

function creatures:register_spawn(name, nodes, max_light, min_light, chance, active_object_count, max_height, spawn_func)
	creatures.spawning_mobs[name] = true
	minetest.register_abm({
		nodenames = nodes,
		neighbors = {"air"},
		interval = 30,
		chance = chance,
		action = function(pos, node, _, active_object_count_wider)
			if active_object_count_wider > active_object_count then
				return
			end
			if not creatures.spawning_mobs[name] then
				return
			end
			pos.y = pos.y+1
			if not minetest.env:get_node_light(pos) then
				return
			end
			if minetest.env:get_node_light(pos) > max_light then
				return
			end
			if minetest.env:get_node_light(pos) < min_light then
				return
			end
			if pos.y > max_height then
				return
			end
			if minetest.env:get_node(pos).name ~= "air" then
				return
			end
			pos.y = pos.y+1
			if minetest.env:get_node(pos).name ~= "air" then
				return
			end
			if spawn_func and not spawn_func(pos, node) then
				return
			end
			
			if minetest.setting_getbool("display_mob_spawn") then
				minetest.chat_send_all("[mobs] Add "..name.." at "..minetest.pos_to_string(pos))
			end
			minetest.env:add_entity(pos, name)
		end
	})
end

-- Mob arrows:

function creatures:register_arrow(name, def)
	minetest.register_entity(name, {
		physical = false,
		visual = def.visual,
		visual_size = def.visual_size,
		textures = def.textures,
		velocity = def.velocity,
		hit_player = def.hit_player,
		hit_node = def.hit_node,
		
		on_step = function(self, dtime)
			local pos = self.object:getpos()
			if minetest.env:get_node(self.object:getpos()).name ~= "air" then
				self.hit_node(self, pos, node)
				self.object:remove()
				return
			end
			pos.y = pos.y-1
			for _,player in pairs(minetest.env:get_objects_inside_radius(pos, 1)) do
				if player:is_player() then
					self.hit_player(self, player)
					self.object:remove()
					return
				end
			end
		end
	})
end

-- Checks if a player can possess a mob:

function creatures:can_possess(player, creature)
	local psettings = creatures.player_def[creatures:player_get(player)]
	if creature and not creature.actor and player:is_player() and psettings.reincarnates then
		return true
	end
	return false
end

-- Causes a player to possess a mob:

function creatures:possess(player, creature)
	if creatures:can_possess(player, creature) then
		player:setpos(creature.object:getpos())
		player:set_look_yaw(creature.object:getyaw())
		player:set_look_pitch(0)
		creatures:player_set(player, {name = creature.name, skin = creature.skin, hp = creature.object:get_hp()})
		creature.object:remove()
	end
end

-- Interaction: This field is set when a player interacts with a mob, and indicates the last mob clicked:

creatures.selected = {}
minetest.register_on_leaveplayer(function(player)
	creatures.selected[player] = nil
end)

-- Interaction: Handle the default formspec commands:

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "creatures:formspec" then
		local creature = creatures.selected[player]

		-- Handle possession:
		if fields["possess"] then
			creatures:possess(player, creature)
		end
	end
end)
