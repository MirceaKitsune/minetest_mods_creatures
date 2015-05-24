-- Creature registration - Mobs:

function creatures:register_mob(name, def)
	-- Players are offset by 1 node in the Minetest code. In order for mobs to have the same height, we must apply a similar offset to them
	-- This is a bad choice, as the real position of mobs will be off by one unit. But it's the only way to make players and mobs work with the same models
	def.collisionbox[2] = def.collisionbox[2] - 1
	def.collisionbox[5] = def.collisionbox[5] - 1

	minetest.register_entity(name, {
		-- static properties:
		hp_max = def.hp_max,
		physical = true,
		collisionbox = def.collisionbox,
		visual = def.visual,
		visual_size = def.visual_size,
		mesh = def.mesh,
		textures = def.textures,
		particles = def.particles,
		makes_footstep_sound = def.makes_footstep_sound,
		env_damage = def.env_damage,
		drops = def.drops,
		armor = def.armor,
		icon = def.icon,
		nodes = def.nodes,
		think = def.think,
		attack_damage = def.attack_damage,
		attack_type = def.attack_type,
		attack_projectile = def.attack_projectile,
		sounds = def.sounds,
		animation = def.animation,
		jump = def.jump or true,
		teams = def.teams,
		teams_target = def.teams_target or {attack = true, avoid = true, follow = true},
		traits = def.traits,
		names = def.names,
		custom = def.custom,

		on_step = def.on_step,
		on_rightclick = def.on_rightclick,
		on_activate = def.on_activate,
		on_punch = def.on_punch,

		-- initialized properties:
		traits_set = nil,
		names_set = nil,
		skin = 0,

		-- dynamic properties:
		timer_life = 60,
		timer_think = 0,
		timer_decision = 0,
		timer_attack = 0,
		timer_env_damage = 0,
		walk_velocity = tonumber(minetest.setting_get("movement_speed_walk")) * def.physics.speed,
		run_velocity = tonumber(minetest.setting_get("movement_speed_fast")) * def.physics.speed,
		jump_velocity = tonumber(minetest.setting_get("movement_speed_jump")) * def.physics.jump,
		gravity = tonumber(minetest.setting_get("movement_gravity")) * def.physics.gravity,
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
			tmp.yaw = self.object:getyaw()
			tmp.hp = self.object:get_hp()
			tmp.skin = self.skin
			tmp.timer_life = self.timer_life
			tmp.actor = self.actor
			tmp.traits_set = self.traits_set
			tmp.names_set = self.names_set
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
				if tmp and tmp.yaw then
					self.object:setyaw(tmp.yaw)
				end
				if tmp and tmp.hp then
					self.object:set_hp(tmp.hp)
				end
				if tmp and tmp.skin then
					self.skin = tmp.skin
				end
				if tmp and tmp.timer_life then
					self.timer_life = tmp.timer_life - dtime_s
				end
				if tmp and tmp.actor then
					self.actor = tmp.actor
				end
				if tmp and tmp.traits_set then
					self.traits_set = tmp.traits_set
				end
				if tmp and tmp.names_set then
					self.names_set = tmp.names_set
				end
				if tmp and tmp.targets then
					self.targets = tmp.targets
				end
			end
		end,
	})
end

-- Mob configuration:
-- This must be executed immediately after the entity is initialized!

function creatures:configure_mob(self)
	-- set personality: each trait is a random value between min and max
	if not self.traits_set then
		self.traits_set = {}
		for i, trait in pairs(self.traits) do
			self.traits_set[i] = math.random() * (trait[2] - trait[1]) + trait[1]
		end
	end

	-- set name: choose one name from all potential names
	if not self.names_set then
		self.names_set = {}
		for i, name in pairs(self.names) do
			self.names_set[i] = name[math.random(#name)]
		end
	end

	-- if the textures field contains tables, we have multiple texture sets
	if self.textures and type(self.textures[1]) == "table" then
		if self.skin == 0 or not self.textures[self.skin] then
			self.skin = math.random(1, #self.textures)
		end
		self.object:set_properties({textures = self.textures[self.skin]})
	end
end

-- Mob spawning:

function creatures:register_spawn(name, def)
	minetest.register_abm({
		nodenames = def.nodes,
		neighbors = def.neighbors,
		interval = def.interval,
		chance = def.chance,
		action = function(pos, node, _, active_object_count_wider)
			if active_object_count_wider > 1 then
				return
			end
			pos.y = pos.y + 1
			if pos.y < def.min_height or pos.y > def.max_height then
				return
			end
			local light = minetest.env:get_node_light(pos)
			if not light or light < def.min_light or light > def.max_light then
				return
			end
			local liquidtype = minetest.registered_nodes[minetest.env:get_node(pos).name].liquidtype
			if minetest.env:get_node(pos).name ~= "air" and liquidtype == "none" then
				return
			end
			if def.on_spawn and not def.on_spawn(pos, node) then
				return
			end

			pos.y = pos.y + 1
			if minetest.setting_getbool("display_mob_spawn") then
				minetest.chat_send_all("[mobs] Add "..name.." at "..minetest.pos_to_string(pos))
			end
			minetest.env:add_entity(pos, name)
		end
	})
end

-- Mob projectiles:

function creatures:register_projectile(name, def)
	minetest.register_entity(name, {
		physical = false,
		visual = def.visual,
		visual_size = def.visual_size,
		textures = def.textures,
		velocity = def.velocity,
		hit_player = def.hit_player,
		hit_node = def.hit_node,
		
		on_step = function(self, dtime)
		-- TODO: This must damage other mobs as well
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

-- Causes a player to possess a mob:

function creatures:possess(player, creature)
	player:setpos(creature.object:getpos())
	player:set_look_yaw(creature.object:getyaw())
	player:set_look_pitch(0)
	creatures:player_set(player, {name = creature.name, skin = creature.skin, hp = creature.object:get_hp()})
	creature.object:remove()
end

-- This field is set when a player interacts with a mob, and indicates the last mob clicked:

creatures.selected = {}
minetest.register_on_leaveplayer(function(player)
	creatures.selected[player] = nil
end)
