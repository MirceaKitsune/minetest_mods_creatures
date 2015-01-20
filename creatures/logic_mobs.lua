-- Creature settings - Mobs, logics:

-- This file contains the default AI functions for mobs. Advanced users can use a different AI instead of this, or execute additional code.

local highest_vision = 0

-- logic_mob_step: Executed in on_step, handles: animations, movement, attacking, damage, target management, decision making
function logic_mob_step (self, dtime)
	if self.attack_type and minetest.setting_getbool("only_peaceful_mobs") then
		self.object:remove()
	end

	-- remove this mob if its lifetime is up and doing so is appropriate
	self.timer_life = self.timer_life - dtime
	if self.timer_life <= 0 and not self.actor then
		local player_count = 0
		for _,obj in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 20)) do
			if obj:is_player() then
				player_count = player_count + 1
			end
		end
		if player_count == 0 then
			self.object:remove()
			return
		else
			self.timer_life = 60
		end
	end

	local s = self.object:getpos()

	-- physics: apply gravity
	if self.object:getvelocity().y > 0.1 then
		self.object:setacceleration({x = 0, y= -self.gravity, z = 0})
	end

	-- physics: float toward the liquid surface
	if self.in_liquid then
		local v = self.object:getvelocity()
		self.object:setacceleration({x = 0, y = self.gravity/(math.max(1, v.y) ^ 2), z = 0})
	end

	-- damage: handle fall damage
	if self.disable_fall_damage and self.object:getvelocity().y == 0 then
		if not self.old_y then
			self.old_y = self.object:getpos().y
		else
			local d = self.old_y - self.object:getpos().y
			if d > 5 then
				local damage = d - 5
				self.object:set_hp(self.object:get_hp() - damage)
				if self.object:get_hp() == 0 then
					if self.sounds and self.sounds.die then
						minetest.sound_play(self.sounds.die, {object = self.object})
					end
					self.object:remove()
				else
					if self.sounds and self.sounds.damage then
						minetest.sound_play(self.sounds.damage, {object = self.object})
					end
				end
			end
			self.old_y = self.object:getpos().y
		end
	end

	-- damage: handle environment damage
	self.timer_env_damage = self.timer_env_damage + dtime
	if self.timer_env_damage > 1 then
		self.timer_env_damage = 0
		local pos = s
		pos.y = pos.y - 1 -- exclude player offset
		local n = minetest.env:get_node(pos)
		
		if self.env_damage.light and self.env_damage.light ~= 0
			and pos.y > 0
			and minetest.env:get_node_light(pos)
			and minetest.env:get_node_light(pos) > 4
			and minetest.env:get_timeofday() > 0.2
			and minetest.env:get_timeofday() < 0.8
		then
			self.object:set_hp(self.object:get_hp() - self.env_damage.light)
			if self.object:get_hp() == 0 then
				if self.sounds and self.sounds.die then
					minetest.sound_play(self.sounds.die, {object = self.object})
				end
				self.object:remove()
			else
				if self.sounds and self.sounds.damage then
					minetest.sound_play(self.sounds.damage, {object = self.object})
				end
			end
		end

		if self.env_damage.water and self.env_damage.water ~= 0 and
			minetest.get_item_group(n.name, "water") ~= 0
		then
			self.object:set_hp(self.object:get_hp() - self.env_damage.water)
			if self.object:get_hp() == 0 then
				if self.sounds and self.sounds.die then
					minetest.sound_play(self.sounds.die, {object = self.object})
				end
				self.object:remove()
			else
				if self.sounds and self.sounds.damage then
					minetest.sound_play(self.sounds.damage, {object = self.object})
				end

				-- jump if we're standing on something solid
				local v = self.object:getvelocity()
				if self.jump and v.y == 0 then
					v.y = self.jump_velocity
					self.object:setvelocity(v)
				end
			end
		end

		if self.env_damage.lava and self.env_damage.lava ~= 0 and
			minetest.get_item_group(n.name, "lava") ~= 0
		then
			self.object:set_hp(self.object:get_hp()-self.env_damage.lava)
			if self.object:get_hp() == 0 then
				if self.sounds and self.sounds.die then
					minetest.sound_play(self.sounds.die, {object = self.object})
				end
				self.object:remove()
			else
				if self.sounds and self.sounds.damage then
					minetest.sound_play(self.sounds.damage, {object = self.object})
				end
				
				-- jump if we're standing on something solid
				local v = self.object:getvelocity()
				if self.jump and v.y == 0 then
					v.y = self.jump_velocity
					self.object:setvelocity(v)
				end
			end
		end
	end

	self.timer_attack = self.timer_attack + dtime

	-- apply AI think speed, influenced by the mob's current status
	self.timer_think = self.timer_think+dtime
	if self.target_current and self.target_current.objective == "attack" then
		if self.timer_think < self.traits.think / 10 then
			return
		end
	elseif self.target_current and (self.target_current.objective == "follow" or self.target_current.objective == "avoid") then
		if self.timer_think < self.traits.think / 2 then
			return
		end
	else
		if self.timer_think < self.traits.think then
			return
		end
	end
	self.timer_think = 0

	-- determine if this mob is in a liquid
	local node = minetest.env:get_node(s)
	local liquidtype = minetest.registered_nodes[node.name].liquidtype
	if (liquidtype == "source" or liquidtype == "flowing") then
		self.in_liquid = true
	else
		self.in_liquid = false
	end

	-- targets: set node targets
	if self.nodes and #self.nodes > 0 then
		local corner_start = {x = s.x - self.traits.vision / 2, y = s.y - self.traits.vision / 2, z = s.z - self.traits.vision / 2}
		local corner_end = {x = s.x + self.traits.vision / 2, y = s.y + self.traits.vision / 2, z = s.z + self.traits.vision / 2}
		for i, node in pairs(self.nodes) do
			local pos_all = minetest.find_nodes_in_area(corner_start, corner_end, node.nodes)
			local pos_all_good = {}
			if node.priority >= math.random() then
				for _, pos_this in pairs(pos_all) do
					local pos_this_up = {x = pos_this.x, y = pos_this.y + 1, z = pos_this.z}
					if vector.distance(s, pos_this_up) <= self.traits.vision then
						local node_this_up = minetest.env:get_node(pos_this_up)
						if node_this_up.name == "air" then
							local light_this_up = minetest.get_node_light(pos_this_up, nil)
							if light_this_up >= node.light_min and light_this_up <= node.light_max then
								table.insert(pos_all_good, pos_this_up)
							end
						end
					end
				end

				if #pos_all_good > 0 then
					local pos = pos_all_good[math.random(#pos_all_good)]
					local obj = "follow"
					if node.avoid then
						obj = "avoid"
					end
					self.targets[i] = {position = pos, objective = obj, priority = node.priority}
				else
					self.targets[i] = nil
				end
			end
		end
	end

	-- targets: add player or mob targets
	if self.teams_target.attack or self.teams_target.avoid or self.teams_target.follow then
		local objects = minetest.env:get_objects_inside_radius(self.object:getpos(), self.traits.vision)
		for _, obj in pairs(objects) do
			if obj ~= self.object and (obj:is_player() or (obj:get_luaentity() and obj:get_luaentity().teams)) and not self.targets[obj] then
				local p = obj:getpos()
				local dist = vector.distance(s, p)
				if dist <= self.traits.vision and minetest.line_of_sight(s, p, 1) then
					local relation = creatures:alliance(self.object, obj)
					local action = math.random()

					-- attack targets
					if self.teams_target.attack and self.attack_type and minetest.setting_getbool("enable_damage") and relation * self.traits.aggressivity <= -action then
						self.targets[obj] = {entity = obj, objective = "attack", priority = math.abs(relation) * self.traits.aggressivity}
					-- avoid targets
					elseif self.teams_target.avoid and relation * self.traits.fear <= -action then
						self.targets[obj] = {entity = obj, objective = "avoid", priority = math.abs(relation) * self.traits.fear}
					-- follow targets
					elseif self.teams_target.follow and relation * self.traits.loyalty >= action then
						self.targets[obj] = {entity = obj, objective = "follow", priority = math.abs(relation) * self.traits.loyalty}
					end
				end
			end
		end
	end

	-- targets: remove or modify player or mob targets
	for obj, target in pairs(self.targets) do
		if not target.persist then
			if target.position or (target.entity:is_player() or target.entity:get_luaentity()) then
				local p = target.position or target.entity:getpos()
				local dist = vector.distance(s, p)
				local dist_target = target.distance or self.traits.vision
				local ent = nil
				if target.entity then
					ent = target.entity:get_luaentity()
				end

				-- remove targets which are dead or out of range
				if dist > dist_target or (target.entity and target.entity:get_hp() <= 0) then
					self.targets[obj] = nil
				-- if the mob is no longer fit to fight, change attack targets to avoid
				elseif self.teams_target.attack and self.teams_target.avoid and target.objective == "attack" and self.object:get_hp() <= self.hp_max * self.traits.fear then
					self.targets[obj].objective = "avoid"
				-- don't follow mobs which are following someone else or a persistent target
				elseif self.teams_target.follow and target.objective == "follow" and ent then
					if ent.target_current and (ent.target_current.entity or ent.target_current.persist) then
						self.targets[obj] = nil
					end
				end
			else
				-- remove players that disconnected or mobs that were removed from the world
				self.targets[obj] = nil
			end
		end
	end

	-- targets: choose the most important target
	self.target_current = nil
	local best_priority = 0
	for i, target in pairs(self.targets) do
		local p = target.position or target.entity:getpos()
		local dist = vector.distance(s, p)
		local interest = target.priority * (self.traits.vision / dist)

		-- an engine bug occasionally causes incorrect positions, so check that distance isn't 0
		if dist ~= 0 and target.priority >= (1 - self.traits.determination) and interest >= best_priority then
			best_priority = interest
			self.target_current = target
		end
	end

	-- state: idle
	if not self.target_current then
		self:set_animation("stand")
		self.v_speed = nil
	-- state: attacking, melee
	elseif self.target_current.objective == "attack" and self.attack_type == "melee" then
		self.v_pos = self.target_current.position or self.target_current.entity:getpos()
		self.v_avoid = false
		local dist = vector.distance(s, self.v_pos)
		local dist_target = self.target_current.distance or self.traits.vision

		if minetest.setting_getbool("fast_mobs") and dist > 2 and dist / dist_target >= 1 - self.target_current.priority then
			self:set_animation("walk_punch")
			self.v_speed = self.run_velocity
		elseif dist > 2 then
			self:set_animation("walk_punch")
			self.v_speed = self.walk_velocity
		else
			self:set_animation("punch")
			self.v_speed = 0
			if self.timer_attack > self.traits.attack_interval then
				self.timer_attack = 0
				if self.sounds and self.sounds.attack then
					minetest.sound_play(self.sounds.attack, {object = self.object})
				end
				if self.target_current.entity then
					self.target_current.entity:punch(self.object, 1.0,  {
						full_punch_interval = 1.0,
						damage_groups = {fleshy = self.attack_damage}
					}, vec)
				end
			end
		end

		if self.sounds and self.sounds.random_attack and math.random(1, 50) <= 1 then
			minetest.sound_play(self.sounds.random_attack, {object = self.object})
		end
	-- state: attacking, shoot
	elseif self.target_current.objective == "attack" and self.attack_type == "shoot" then
		self:set_animation("punch")
		self.v_pos = self.target_current.position or self.target_current.entity:getpos()
		self.v_avoid = false
		self.v_speed = 0

		if self.timer_attack > self.traits.attack_interval then
			self.timer_attack = 0
			if self.sounds and self.sounds.attack then
				minetest.sound_play(self.sounds.attack, {object = self.object})
			end

			s.y = s.y + (self.collisionbox[2] + self.collisionbox[5]) / 2
			local obj = minetest.env:add_entity(s, self.attack_arrow)
			local amount = (vec.x ^ 2 + vec.y ^ 2 + vec.z ^ 2) ^ 0.5
			local v = obj:get_luaentity().velocity
			vec.y = vec.y + 1
			vec.x = vec.x * v / amount
			vec.y = vec.y * v / amount
			vec.z = vec.z * v / amount
			obj:setvelocity(vec)
		end

		if self.sounds and self.sounds.random_attack and math.random(1, 50) <= 1 then
			minetest.sound_play(self.sounds.random_attack, {object = self.object})
		end
	-- state: following or avoiding
	elseif self.target_current.objective == "follow" or self.target_current.objective == "avoid" then
		self.v_pos = self.target_current.position or self.target_current.entity:getpos()
		self.v_avoid = self.target_current.objective == "avoid"
		local dist = vector.distance(s, self.v_pos)
		local dist_target = self.target_current.distance or self.traits.vision

		if minetest.setting_getbool("fast_mobs") and
		(not self.v_avoid and dist / dist_target >= 1 - self.target_current.priority) or
		(self.v_avoid and dist / dist_target < 1 - self.target_current.priority) then
			self:set_animation("walk")
			self.v_speed = self.run_velocity
		elseif dist > dist_target / 5 then
			self:set_animation("walk")
			self.v_speed = self.walk_velocity
		else
			self:set_animation("stand")
			self.v_speed = nil
		end

		if self.sounds and math.random(1, 50) <= 1 then
			if self.target_current.priority == 0 then
				if self.sounds.random_idle then
					minetest.sound_play(self.sounds.random_idle, {object = self.object})
				end
			elseif self.v_avoid and self.sounds.random_avoid then
				minetest.sound_play(self.sounds.random_avoid, {object = self.object})
			elseif not self.v_avoid and self.sounds.random_follow then
				minetest.sound_play(self.sounds.random_follow, {object = self.object})
			end
		end
	end

	-- movement: jump whenever stuck
	if self.jump and self.v_start and self.get_velocity(self) <= 1 and self.object:getvelocity().y == 0 then
		local v = self.object:getvelocity()
		v.y = self.jump_velocity
		self.object:setvelocity(v)
	end

	-- movement: handle pathfinding
	local pos = self.v_pos
	if pos and self.v_speed and self.v_speed > 0 and minetest.setting_getbool("pathfinding") and not self.v_avoid then
		pos = nil
		if not self.v_start or (self.v_path and #self.v_path == 0) then
			self.v_path = nil
		end
		-- only calculate path when none exists or the target position changed
		if not self.v_path or vector.distance(self.v_path[#self.v_path], self.v_pos) > 1 then
			local p1 = {x = math.floor(s.x), y = math.floor(s.y), z = math.floor(s.z)}
			local p2 = {x = math.floor(self.v_pos.x), y = math.floor(self.v_pos.y), z = math.floor(self.v_pos.z)}
			local new_path = minetest.find_path(p1, p2, self.traits.vision, 1, 5, nil)
			if new_path and #new_path > 0 then
				self.v_path = new_path
			end
		end
		-- if the next entry is closer than 1 block, it's a destination we have reached, so remove it
		if self.v_path then
			if vector.distance(s, self.v_path[1]) <= 1 then
				table.remove(self.v_path, 1)
			end
			if #self.v_path > 0 then
				pos = self.v_path[1]
			end
		end
	end

	-- movement: handle orientation and walking
	if pos and self.v_speed then
		local vec = {x = pos.x - s.x, y = pos.y - s.y, z = pos.z - s.z}
		local yaw = math.atan(vec.z / vec.x) + math.pi / 2
		if pos.x > s.x then
			yaw = yaw + math.pi
		end
		if self.v_avoid then
			yaw = yaw + math.pi
		end
		self.object:setyaw(yaw)
		self.set_velocity(self, self.v_speed)
		self.v_start = self.v_speed > 0
	else
		self.set_velocity(self, 0)
		self.v_speed = nil
		self.v_start = false
	end
end

-- logic_mob_activate: Executed in on_activate, handles: initialization, static data management
function logic_mob_activate (self, staticdata, dtime_s)
	self.object:set_armor_groups({fleshy = self.armor})
	self.object:setacceleration({x = 0, y = -10, z = 0})
	self.object:setvelocity({x = 0, y = self.object:getvelocity().y, z = 0})
	self.object:setyaw(math.random(1, 360) / 180 * math.pi)
	if self.attack_type and minetest.setting_getbool("only_peaceful_mobs") then
		self.object:remove()
	end
	self.timer_life = 600 - dtime_s

	self.set_staticdata(self, staticdata, dtime_s)

	if self.timer_life <= 0 and not self.actor then
		self.object:remove()
	end

	-- set personality: each trait is a random value per mob, between the min and max values defined
	-- on_step must never execute before this is set, the code expects a single value for each trait!
	for trait, entry in pairs(self.traits) do
		if type(entry) == "table" then
			self.traits[trait] = math.random() * (entry[2] - entry[1]) + entry[1]
		end
	end

	-- if the textures field contains tables, we have multiple texture sets
	if self.textures and type(self.textures[1]) == "table" then
		if self.skin == 0 or not self.textures[self.skin] then
			self.skin = math.random(1, #self.textures)
		end
		self.object:set_properties({textures = self.textures[self.skin]})
	end

	-- we want to note what's the furthest distance a mob can see
	if self.traits.vision > highest_vision then
		highest_vision = self.traits.vision
	end
end

-- logic_mob_punch: Executed in on_punch, handles: damage, death, target management
function logic_mob_punch (self, hitter)
	local psettings = creatures.player_def[creatures:player_get(hitter)]
	local relation = creatures:alliance(self.object, hitter)
	local s = self.object:getpos()

	-- trigger the player's attack sound
	if hitter:is_player() and psettings.sounds and psettings.sounds.attack then
		minetest.sound_play(psettings.sounds.attack, {object = hitter})
	end
	-- handle mob death
	if self.object:get_hp() <= 0 then
		if hitter and hitter:is_player() and hitter:get_inventory() then
			for _,drop in ipairs(self.drops) do
				if math.random(1, drop.chance) == 1 then
					hitter:get_inventory():add_item("main", ItemStack(drop.name.." "..math.random(drop.min, drop.max)))
				end
			end
		end
		if self.sounds and self.sounds.die then
			minetest.sound_play(self.sounds.die, {object = self.object})
		end
	else
		-- targets: take action toward the creature who hit us
		if self.teams_target.attack or self.teams_target.avoid then
			local ent = hitter:get_luaentity()
			if not (self.targets[hitter] and self.targets[hitter].persist) and (hitter:is_player() or (ent and ent.teams)) then
				local importance = (1 - relation) * 0.5
				local action = math.random()
				if self.teams_target.attack and self.attack_type and minetest.setting_getbool("enable_damage") and importance * self.traits.aggressivity >= action then
					if not self.targets[hitter] then
						self.targets[hitter] = {entity = hitter, objective = "attack", priority = importance * self.traits.aggressivity}
					else
						self.targets[hitter].objective = "attack"
						self.targets[hitter].priority = self.targets[hitter].priority + importance * self.traits.aggressivity
					end
				elseif self.teams_target.avoid and importance * self.traits.fear >= action then
					if not self.targets[hitter] then
						self.targets[hitter] = {entity = hitter, objective = "avoid", priority = importance * self.traits.fear}
					else
						self.targets[hitter].objective = "aviod"
						self.targets[hitter].priority = self.targets[hitter].priority + importance * self.traits.fear
					end
				end
			end
		end

		if self.sounds and self.sounds.damage then
			minetest.sound_play(self.sounds.damage, {object = self.object})
		end
	end
end

-- logic_mob_rightclick: Executed in on_rightclick, handles: selection
function logic_mob_rightclick (self, clicker)
	creatures.selected[clicker] = self
end
