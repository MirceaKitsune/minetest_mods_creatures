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
		items = def.items,
		armor = def.armor,
		icon = def.icon,
		nodes = def.nodes,
		think = def.think,
		attack_capabilities = def.attack_capabilities,
		sounds = def.sounds,
		animation = def.animation,
		jump = def.jump or true,
		use_items = def.use_items,
		inventory_main = def.inventory_main,
		inventory_craft = def.inventory_craft,
		teams = def.teams,
		teams_target = def.teams_target or {attack = true, avoid = true, follow = true},
		alert = def.alert,
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
		inventory = nil,
		inventory_wield = 0,
		timer_life = 0,
		timer_think = 0,
		timer_decision = 0,
		timer_attack = 0,
		timer_env = 0,
		walk_velocity = tonumber(minetest.setting_get("movement_speed_walk")) * def.physics.speed,
		run_velocity = tonumber(minetest.setting_get("movement_speed_fast")) * def.physics.speed,
		jump_velocity = tonumber(minetest.setting_get("movement_speed_jump")) * def.physics.jump,
		gravity = tonumber(minetest.setting_get("movement_gravity")) * def.physics.gravity,
		targets = {},
		target_current = nil,
		alert_level = 0,
		in_liquid = false,
		breath = 11,
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

		get_animation = function(self)
			return self.animation.current
		end,

		set_animation = function(self, type, speed)
			if not self.animation or type == self.animation.current then
				return
			end

			local animation_this = self.animation[type]
			local speed_this = animation_this.speed * speed

			self.object:set_animation({x = animation_this.x, y = animation_this.y}, speed_this, animation_this.blend, animation_this.loop)
			self.animation.current = type
		end,

		get_staticdata = function(self)
			local tmp = {}
			tmp.yaw = self.object:getyaw()
			tmp.hp = self.object:get_hp()
			tmp.breath = self.breath
			tmp.alert_level = self.alert_level
			tmp.skin = self.skin
			tmp.actor = self.actor
			tmp.traits_set = self.traits_set
			tmp.names_set = self.names_set
			-- add inventory entries
			if self.inventory then
				tmp.inventory = {}
				for obj, item in pairs(self.inventory) do
					-- userdata cannot be serialized, convert to table
					tmp.inventory[obj] = item:to_table()
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
				if tmp and tmp.breath then
					self.breath = tmp.breath
				end
				if tmp and tmp.alert_level then
					self.alert_level = tmp.alert_level
				end
				if tmp and tmp.skin then
					self.skin = tmp.skin
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
				if tmp and tmp.inventory then
					self.inventory = {}
					for obj, item in pairs(tmp.inventory) do
						-- userdata cannot be serialized, convert from table
						self.inventory[obj] = ItemStack(item)
					end
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

	-- set initial mob inventory
	if not self.inventory then
		self.inventory = {}
		for i, item in pairs(self.items) do
			if math.random(1, item.chance) == 1 then
				local name = item.name
				if type(item.name) == "table" then
					name = item.name[math.random(1, #item.name)]
				end
				local count = math.random(item.count_min, item.count_max)
				local wear = nil
				if item.wear_min and item.wear_max and item.wear_max > 0 then
					wear = math.random(item.wear_min, item.wear_max)
				end
				local metadata = item.metadata

				local stack = {
					name = name,
					count = count,
					wear = wear,
					metadata = metadata,
				}
				table.insert(self.inventory, ItemStack(stack))
			end
		end
	end
end

-- Mob spawning:

function creatures:spawn(name, pos)
	pos.y = pos.y + 1
	if minetest.setting_getbool("display_mob_spawn") then
		minetest.chat_send_all("[mobs] Add "..name.." at "..minetest.pos_to_string(pos))
	end
	local obj = minetest.env:add_entity(pos, name)
	return obj
end

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

			creatures:spawn(name, pos)
		end
	})
end

-- Other functions:

-- sets the target object in the mob's target list
function creatures:target_set (self, object, def)
	if not object then
		return
	end
	self.targets[object] = def
end

-- gets the target object from the mob's target list
function creatures:target_get (self, object)
	if not object then
		return self.target_current
	end
	return self.targets[object]
end

-- this field is set when a player interacts with a mob, and indicates the last mob clicked:
creatures.selected = {}
minetest.register_on_leaveplayer(function(player)
	creatures.selected[player] = nil
end)
