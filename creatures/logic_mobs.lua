-- Creature settings - Mobs, logics:

-- This file contains the default AI functions for mobs. Advanced users can use a different AI instead of this, or execute additional code.

-- logic_mob_step: Executed in on_step, handles: animations, movement, attacking, damage, target management, decision making
function logic_mob_step (self, dtime)
	if not self.traits_set then return end

	self.timer_life = self.timer_life - dtime
	if self.timer_life <= 0 and not self.actor then
		local player_count = 0
		for _, obj in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), math.max(10, self.traits_set.vision))) do
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
	local v = self.object:getvelocity()
	local v_xz = self.get_velocity(self)
	local tool = self.inventory and self.inventory[self.inventory_wield]
	local tool_item = tool and minetest.registered_items[tool:get_name()]

	-- inventory: handle items
	if self.inventory and #self.inventory > 0 then
		for i, entry in pairs(self.inventory) do
			-- don't allow more items than the inventory size
			if i > self.inventory_main.x * self.inventory_main.y then
				self.inventory[i] = nil
			-- remove worn out items
			elseif entry:get_wear() >= 65535 then
				self.inventory[i] = nil
			end
		end

		-- make sure the wielded item index doesn't exceed our total number of items
		if self.inventory_wield > #self.inventory then
			self.inventory_wield = #self.inventory
		end
	end

	-- physics: apply gravity
	if v.y > 0.1 then
		self.object:setacceleration({x = 0, y= -self.gravity, z = 0})
	end

	-- physics: float toward the liquid surface
	if self.in_liquid then
		self.object:setacceleration({x = 0, y = self.gravity/(math.max(1, v.y) ^ 2), z = 0})
	end

	-- physics: always push forward when airborne, to help with jumping or other movements
	if self.v_start and self.v_speed and self.v_speed > 0 and v_xz <= 1 and v.y ~= 0 then
		self.set_velocity(self, self.v_speed)
	end

	-- damage: handle fall damage
	if v.y == 0 and minetest.setting_getbool("enable_damage") then
		if not self.old_y then
			self.old_y = s.y
		else
			local d = self.old_y - s.y
			if d > 5 then
				local damage = d - 5
				self.object:set_hp(self.object:get_hp() - damage)
				creatures:particles(self.object, nil)
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
			self.old_y = s.y
		end
	end

	-- timer: limit the execution of this code by timer_env_damage, threshold set to 1 second
	self.timer_env_damage = self.timer_env_damage + dtime
	if self.timer_env_damage >= 1 and minetest.setting_getbool("enable_damage") then
		self.timer_env_damage = 0

		local pos = s
		pos.y = pos.y - 1 -- exclude player offset
		local n = minetest.env:get_node(pos)
		local l = minetest.env:get_node_light(pos)

		-- environment damage: handle light damage
		if self.env_damage.light and self.env_damage.light ~= 0 and l and
		(l >= self.env_damage.light_level or l < -self.env_damage.light_level) then
			self.object:set_hp(self.object:get_hp() - self.env_damage.light)
			creatures:particles(self.object, nil)
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

		-- environment damage: handle water damage
		if self.env_damage.water and self.env_damage.water ~= 0 and
		minetest.get_item_group(n.name, "water") ~= 0 then
			self.object:set_hp(self.object:get_hp() - self.env_damage.water)
			creatures:particles(self.object, nil)
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
				if self.jump and v.y == 0 then
					v.y = self.jump_velocity * 0.75
					self.object:setvelocity(v)
				end
			end
		end

		-- environment damage: handle lava damage
		if self.env_damage.lava and self.env_damage.lava ~= 0 and
		minetest.get_item_group(n.name, "lava") ~= 0 then
			self.object:set_hp(self.object:get_hp()-self.env_damage.lava)
			creatures:particles(self.object, nil)
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
				if self.jump and v.y == 0 then
					v.y = self.jump_velocity * 0.75
					self.object:setvelocity(v)
				end
			end
		end
	end

	-- timer: limit the execution of this code by timer_decision, threshold set by the decision_interval trait
	self.timer_decision = self.timer_decision + dtime
	if self.timer_decision >= self.traits_set.decision_interval then
		self.timer_decision = 0

		-- targets: add node targets
		if self.nodes and #self.nodes > 0 then
			local distance = self.traits_set.vision / 2
			local corner_start = {x = s.x - distance, y = s.y - distance / 2, z = s.z - distance}
			local corner_end = {x = s.x + distance, y = s.y + distance / 2, z = s.z + distance}
			for i, node in pairs(self.nodes) do
				if node.priority >= math.random() then
					local pos_all = minetest.find_nodes_in_area_under_air(corner_start, corner_end, node.nodes)
					for _, pos_this in ipairs(pos_all) do
						local id = "x"..pos_this.x.."y"..pos_this.y.."z"..pos_this.z
						if not self.targets[id] then
							local pos_this_up = {x = pos_this.x, y = pos_this.y + 1, z = pos_this.z}
							if vector.distance(s, pos_this_up) <= self.traits_set.vision and minetest.line_of_sight(s, pos_this_up, 1) then
								local name = minetest.env:get_node(pos_this).name
								self.targets[id] = {position = pos_this_up, name = name, light_min = node.light_min, light_max = node.light_max, objective = node.objective, priority = node.priority}
							end
						end
					end
				end
			end
		end

		-- targets: add player or entity targets
		if self.teams_target.attack or self.teams_target.avoid or self.teams_target.follow then
			local objects = minetest.env:get_objects_inside_radius(s, self.traits_set.vision)
			for _, obj in pairs(objects) do
				local ent = obj:get_luaentity()
				if obj ~= self.object and (obj:is_player() or ent) and not self.targets[obj] then
					local p = obj:getpos()
					local relation = creatures:alliance(self.object, obj)

					if vector.distance(s, p) <= self.traits_set.vision and minetest.line_of_sight(s, p, 1) then
						-- this is a dropped item
						if ent and ent.name == "__builtin:item" and creatures.item_priority then
							-- set this as an attack target, which will make the mob walk toward it and pick it up
							-- since we have no better criteria to establish the value of an item, use the count of the stack to determine target priority
							local stack = ItemStack(ent.itemstring)
							local count = stack:get_count()
							self.targets[obj] = {entity = obj, name = "__builtin:item", objective = "attack", priority = math.min(1, count / creatures.item_priority)}
						-- this is a creature target
						elseif relation and math.abs(relation) > creatures.teams_neutral then
							local action = math.random()
							local name = nil
							if ent then
								name = ent.name
							else
								name = obj:get_player_name()
							end

							-- attack targets
							if self.teams_target.attack and minetest.setting_getbool("enable_damage") and relation * self.traits_set.aggressivity <= -action then
								self.targets[obj] = {entity = obj, name = name, objective = "attack", priority = math.abs(relation) * self.traits_set.aggressivity}
							-- avoid targets
							elseif self.teams_target.avoid and relation * self.traits_set.fear <= -action then
								self.targets[obj] = {entity = obj, name = name, objective = "avoid", priority = math.abs(relation) * self.traits_set.fear}
							-- follow targets
							elseif self.teams_target.follow and relation * self.traits_set.loyalty >= action then
								self.targets[obj] = {entity = obj, name = name, objective = "follow", priority = math.abs(relation) * self.traits_set.loyalty}
							end
						end
					end
				end
			end
		end

		-- targets: remove or modify targets
		for obj, target in pairs(self.targets) do
			if not target.persist then
				if target.position or (target.entity:is_player() or target.entity:get_luaentity()) then
					local p = target.position or target.entity:getpos()
					local dist = vector.distance(s, p)
					local dist_max = target.distance or self.traits_set.vision
					local ent = nil
					if target.entity then
						ent = target.entity:get_luaentity()
					end

					-- remove targets which are out of range
					if dist > dist_max then
						self.targets[obj] = nil
					-- remove node targets that don't meet the necessary criteria
					elseif target.position and not target.entity and target.name then
						local pos = {x = target.position.x, y = target.position.y - 1, z = target.position.z}
						local name = minetest.env:get_node(pos).name
						local light = minetest.get_node_light(target.position, nil)
						if name ~= target.name or not light or light < target.light_min or light > target.light_max then
							self.targets[obj] = nil
						end
					-- remove entity targets which are dead
					elseif target.entity and target.entity:get_hp() <= 0 then
						self.targets[obj] = nil
					-- if the mob is no longer fit to fight, change attack targets to avoid
					elseif target.entity and ent and ent.teams and target.objective == "attack" and self.teams_target.avoid and self.object:get_hp() <= self.hp_max * self.traits_set.fear then
						self.targets[obj].objective = "avoid"
					-- don't follow mobs which are following someone else or a persistent target
					elseif target.entity and target.objective == "follow" then
						if ent and ent.target_current and (ent.target_current.entity or ent.target_current.persist) then
							self.targets[obj] = nil
						end
					end
				else
					-- remove entities which are no longer available
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
			local dist_max = target.distance or self.traits_set.vision
			local interest = target.priority * (1 - dist / dist_max) + ((1 - self.traits_set.determination) * math.random())

			-- an engine bug occasionally causes incorrect positions, so check that distance isn't 0
			if dist ~= 0 and dist <= dist_max then
				if interest >= best_priority then
					best_priority = interest
					self.target_current = target
				end
			end
		end
	end

	-- timer: limit the execution of this code by timer_think, threshold set by the creature's think rate
	-- if this creature is attacking, choose the smallest threshold between think rate and attack inverval
	self.timer_attack = self.timer_attack + dtime
	self.timer_think = self.timer_think + dtime
	local threshold_think = self.think
	if self.target_current and self.target_current.objective == "attack" and self.target_current.entity then
		threshold_think = math.min(self.think, self.traits_set.attack_interval)
	end
	if self.timer_think >= threshold_think then
		self.timer_think = 0

		-- determine if this mob is in a liquid
		local node = minetest.env:get_node(s)
		local liquidtype = minetest.registered_nodes[node.name].liquidtype
		if (liquidtype == "source" or liquidtype == "flowing") then
			self.in_liquid = true
		else
			self.in_liquid = false
		end

		-- determine target position
		local dest = nil
		if self.target_current then
			dest = self.target_current.position or self.target_current.entity:getpos()
		end

		-- inventory: if the wielded item has an on_mob_wield function, only continue if it returns true
		if tool_item and tool_item.on_mob_wield then
			if not tool_item.on_mob_wield(self) then
				return
			end
		end

		-- state: idle
		if not self.target_current or not dest then
			self:set_animation("stand")
			self.v_speed = nil
			return

		-- state: attacking
		elseif self.target_current.objective == "attack" then
			self.v_pos = dest
			self.v_avoid = false
			local dist = vector.distance(s, dest)
			local dist_max = self.target_current.distance or self.traits_set.vision

			if minetest.setting_getbool("fast_mobs") and dist > 2 and dist / dist_max >= 1 - self.target_current.priority then
				self:set_animation("walk_punch")
				self.v_speed = self.run_velocity
			elseif dist > 2 then
				self:set_animation("walk_punch")
				self.v_speed = self.walk_velocity
			else
				self:set_animation("punch")
				self.v_speed = 0
				if self.timer_attack >= self.traits_set.attack_interval then
					self.timer_attack = 0

					-- if the wielded item has an on_mob_punch function, only punch if it returns true
					local can_punch = true
					if tool_item and tool_item.on_mob_punch then
						can_punch = tool_item.on_mob_punch(self)
					end

					if can_punch then
						-- this is a node target
						if self.target_current.position then
							-- dig the node
							local pos = {x = self.target_current.position.x, y = self.target_current.position.y - 1, z = self.target_current.position.z}
							local name = minetest.env:get_node(pos).name
							minetest.dig_node(pos)
							-- add the node to the mob's inventory
							local stack = ItemStack(name)
							table.insert(self.inventory, stack)
						-- this is an entity target
						elseif self.target_current.entity then
							-- if this is an item, pick it up
							if self.target_current.name == "__builtin:item" then
								local ent = self.target_current.entity:get_luaentity()
								local stack = ItemStack(ent.itemstring)
								table.insert(self.inventory, stack)
								self.target_current.entity:remove()
							-- if this is a creature, punch it
							else
								if self.sounds and self.sounds.attack then
									minetest.sound_play(self.sounds.attack, {object = self.object})
								end

								local capabilities = {
									full_punch_interval = self.traits_set.attack_interval,
									damage_groups = {fleshy = self.attack_damage},
								}
								if tool then
									local tool_capabilities = tool:get_tool_capabilities()
									local tool_damage = tool_capabilities.damage_groups and tool_capabilities.damage_groups.fleshy
									if tool_damage then
										-- multiply with the tool capabilities of the wielded item
										capabilities.full_punch_interval = capabilities.full_punch_interval * tool_capabilities.full_punch_interval
										capabilities.damage_groups.fleshy = capabilities.damage_groups.fleshy * tool_damage
										-- wear out the tool
										if creatures.item_wear and not minetest.setting_getbool("creative_mode") then
											tool:add_wear(creatures.item_wear / tool_damage)
										end
									end
								end
								local dir = vector.direction(self.v_pos, s)

								self.target_current.entity:punch(self.object, self.traits_set.attack_interval, capabilities, dir)
							end
						end
					end
				end
			end

		-- state: following or avoiding
		elseif self.target_current.objective == "follow" or self.target_current.objective == "avoid" then
			self.v_pos = dest
			self.v_avoid = self.target_current.objective == "avoid"
			local dist = vector.distance(s, dest)
			local dist_max = self.target_current.distance or self.traits_set.vision

			if minetest.setting_getbool("fast_mobs") and
			((not self.v_avoid and dist / dist_max >= 1 - self.target_current.priority) or
			(self.v_avoid and dist / dist_max < 1 - self.target_current.priority)) then
				self:set_animation("walk")
				self.v_speed = self.run_velocity
			elseif self.v_avoid or dist > math.max(5, dist_max / 10) then
				self:set_animation("walk")
				self.v_speed = self.walk_velocity
			else
				self:set_animation("stand")
				self.v_speed = nil
			end
		end

		-- pathfinding: calculate path, when none exists or the target position changed
		if self.v_pos and self.v_speed and self.v_speed > 0 and not self.v_avoid and minetest.setting_getbool("pathfinding") and
		(not self.v_path or #self.v_path == 0 or vector.distance(self.v_path[#self.v_path], self.v_pos) > 1) then
			self.v_path = nil
			local p1 = {x = s.x, y = s.y, z = s.z}
			local p2 = {x = self.v_pos.x, y = self.v_pos.y, z = self.v_pos.z}
			local new_path = minetest.find_path(p1, p2, self.traits_set.vision, 1, 5, "Dijkstra")
			if new_path and #new_path > 0 then
				self.v_path = new_path
			end
		end

		-- pathfinding: if we have reached the first node in the path, remove it
		if self.v_path and #self.v_path > 0 then
			if vector.distance(s, self.v_path[1]) <= 1 then
				table.remove(self.v_path, 1)
			end
		end

		-- pathfinding: set our destination to the first node in the path, or the target if no path is present
		local pos = self.v_pos
		if self.v_path and #self.v_path > 0 then
			pos = self.v_path[1]
		end

		-- movement: jump whenever stuck
		if self.jump and self.v_start and v_xz <= 1 and v.y == 0 then
			v.y = self.jump_velocity * 0.75
			self.object:setvelocity(v)
		end

		-- movement: handle orientation and walking
		if pos and self.v_speed then
			local dir = vector.direction(pos, s)
			local yaw = math.atan(dir.z / dir.x) + math.pi / 2
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
end

-- logic_mob_activate: Executed in on_activate, handles: initialization, static data management
function logic_mob_activate (self, staticdata, dtime_s)
	self.timer_life = 600 - dtime_s
	self.object:setacceleration({x = 0, y = -self.gravity, z = 0})
	self.object:setvelocity({x = 0, y = self.object:getvelocity().y, z = 0})

	-- if damage is disabled, make mobs invincible
	if minetest.setting_getbool("enable_damage") then
		self.object:set_armor_groups({fleshy = self.armor})
	else
		self.object:set_armor_groups({fleshy = 0})
	end

	self.set_staticdata(self, staticdata, dtime_s)

	if self.timer_life <= 0 and not self.actor then
		self.object:remove()
		return
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

	creatures:configure_mob(self)
	self:set_animation("stand")

	-- randomize timers to prevent mobs from acting synchronously if initialized at the same moment
	self.timer_think = self.think * math.random()
	self.timer_decision = self.traits_set.decision_interval * math.random()
	self.timer_attack = self.traits_set.attack_interval * math.random()
	self.timer_env_damage = 1 * math.random()
end

-- logic_mob_punch: Executed in on_punch, handles: damage, death, target management
function logic_mob_punch (self, hitter, time_from_last_punch, tool_capabilities, dir)
	if not self.traits_set or not minetest.setting_getbool("enable_damage") then
		return
	end

	local psettings = creatures.player_def[creatures:player_get(hitter)]
	local relation = creatures:alliance(self.object, hitter)
	local s = self.object:getpos()
	local delay = time_from_last_punch < 1 and hitter:is_player()

	if not delay then
		-- if attacker is a player, wear out their wielded tool
		if hitter:is_player() and creatures.item_wear and not minetest.setting_getbool("creative_mode") then
			local item = hitter:get_wielded_item()
			local item_capabilities = item:get_tool_capabilities()
			local item_damage = item_capabilities.damage_groups and item_capabilities.damage_groups.fleshy
			if item_damage then
				item:add_wear(creatures.item_wear / item_damage)
			end
			hitter:set_wielded_item(item)
		end

		-- trigger the player's attack sound
		if hitter:is_player() and psettings.sounds and psettings.sounds.attack then
			minetest.sound_play(psettings.sounds.attack, {object = hitter})
		end

		-- spawn damage particles
		creatures:particles(self.object, nil)
	end

	-- handle mob death
	if self.object:get_hp() <= 0 then
		if self.inventory and hitter and hitter:is_player() and hitter:get_inventory() then
			for _, item in ipairs(self.inventory) do
				hitter:get_inventory():add_item("main", item)
			end
		end
		if self.sounds and self.sounds.die then
			minetest.sound_play(self.sounds.die, {object = self.object})
		end
	elseif not delay and relation then
		-- targets: take action toward the creature who hit us
		if self.teams_target.attack or self.teams_target.avoid then
			local ent = hitter:get_luaentity()
			if not (self.targets[hitter] and self.targets[hitter].persist) and (hitter:is_player() or (ent and ent.teams)) then
				local importance = (1 - relation) * 0.5
				local action = math.random()
				local name = nil
				if ent then
					name = ent.name
				else
					name = hitter:get_player_name()
				end

				if self.teams_target.attack and minetest.setting_getbool("enable_damage") and importance * self.traits_set.aggressivity >= action then
					if not self.targets[hitter] then
						self.targets[hitter] = {entity = hitter, name = name, objective = "attack", priority = importance * self.traits_set.aggressivity}
					else
						self.targets[hitter].objective = "attack"
						self.targets[hitter].priority = self.targets[hitter].priority + importance * self.traits_set.aggressivity
					end
				elseif self.teams_target.avoid and importance * self.traits_set.fear >= action then
					if not self.targets[hitter] then
						self.targets[hitter] = {entity = hitter, name = name, objective = "avoid", priority = importance * self.traits_set.fear}
					else
						self.targets[hitter].objective = "avoid"
						self.targets[hitter].priority = self.targets[hitter].priority + importance * self.traits_set.fear
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
