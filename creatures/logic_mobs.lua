-- Creature settings - Mobs, logics:

-- This file contains the default AI functions for mobs. Advanced users can use a different AI instead of this, or execute additional code.

-- adds a stack to the mob's inventory, returns true if successful
local function inventory_add (self, stack, check)
	if not self.inventory then
		return false
	end

	-- if the item already exists in a stack that has room, we can add it to that stack instead
	for i, item in pairs(self.inventory) do
		if item:item_fits(stack) then
			if not check then
				item:add_item(stack)
			end
			return true
		end
	end

	-- if the item wasn't added to an existing stack, see if we can add it to a new slot
	if #self.inventory + 1 <= self.inventory_main.x * self.inventory_main.y then
		if not check then
			table.insert(self.inventory, stack)
		end
		return true
	end

	return false
end

-- drops all of the mob's items
local function inventory_drop (self)
	if not self.inventory then
		return
	end

	local pos = self.object:getpos()
	for _, stack in ipairs(self.inventory) do
		if not stack:is_empty() then
			local obj = minetest.env:add_item(pos, stack)
			obj:setvelocity({x = 1 - math.random() * 2, y = obj:getvelocity().y, z = 1 - math.random() * 2})
		end
	end

	self.inventory = {}
end

-- returns true if the mob is bumping into the given target
local function awareness_bump(self, object)
	local pos1 = self.object:getpos()
	local pos2 = object:getpos()
	local collisionbox1 = self.collisionbox
	local collisionbox2 = object:get_properties().collisionbox
	-- check if the collision boxes of the two mobs are closer than 0.25
	local box1 = {
		x_start = pos1.x + collisionbox1[1] - 0.125,
		y_start = pos1.y + collisionbox1[2] - 0.125,
		z_start = pos1.z + collisionbox1[3] - 0.125,
		x_end = pos1.x + collisionbox1[4] + 0.125,
		y_end = pos1.y + collisionbox1[5] + 0.125,
		z_end = pos1.z + collisionbox1[6] + 0.125,
	}
	local box2 = {
		x_start = pos2.x + collisionbox2[1] - 0.125,
		y_start = pos2.y + collisionbox2[2] - 0.125,
		z_start = pos2.z + collisionbox2[3] - 0.125,
		x_end = pos2.x + collisionbox2[4] + 0.125,
		y_end = pos2.y + collisionbox2[5] + 0.125,
		z_end = pos2.z + collisionbox2[6] + 0.125,
	}
	if box1.x_start <= box2.x_end and box1.x_end >= box2.x_start and
	box1.y_start <= box2.y_end and box1.y_end >= box2.y_start and
	box1.z_start <= box2.z_end and box1.z_end >= box2.z_start then
		return true
	end
	return false
end

-- returns true if the mob can hear the given target
local function awareness_audibility(pos, object, skill)
	local dist = vector.distance(pos, object:getpos())
	local audibility = creatures:audibility_get(object)
	-- account distance plus audibility factor
	if dist <= skill and audibility then
		local range = (1 - dist / skill)
		if range >= 1 - audibility then
			return true
		end
	end
	return false
end

-- returns true if the mob can see the given target
local function awareness_sight (pos1, pos2, yaw, pitch, fov, skill)
	local node_light = minetest.env:get_node_light(pos2)
	local light = node_light and (1 + node_light) / 16
	-- check if distance is within the mob's view range, decreased by light level
	if light and vector.distance(pos1, pos2) <= skill * light then
		-- check that the target is within the mob's field of vision
		if pos_to_angle(pos1, pos2, yaw, pitch) <= fov then
			-- trace a line and check that the target's position isn't blocked by a solid object
			if minetest.line_of_sight(pos1, pos2, 1) then
				return true
			end
		end
	end
	return false
end

-- logic_mob_step: Executed in on_step, handles: animations, movement, attacking, damage, target management, decision making
function logic_mob_step (self, dtime)
	if not self.traits_set or not self.inventory then return end
	local s = self.object:getpos()
	local v = self.object:getvelocity()
	local v_xz = self.get_velocity(self)
	-- estimate head position at 4/5 of total height
	local s_head = {
		x = s.x,
		y = lerp(s.y + self.collisionbox[2], s.y + self.collisionbox[5], 0.8),
		z = s.z,
	}

	-- timer: handle life timer
	if creatures.timer_life and not self.actor then
		self.timer_life = self.timer_life - dtime
		if self.timer_life <= 0 then
			local player_found = false
			local radius = math.max(10, math.max(self.traits_set.vision, self.traits_set.hearing))
			for _, obj in ipairs(minetest.env:get_objects_inside_radius(s, radius)) do
				if obj:is_player() then
					player_found = true
					break
				end
			end

			if player_found then
				self.timer_life = creatures.timer_life
			else
				self.object:remove()
				return
			end
		end
	end

	-- inventory: handle items
	if self.inventory and #self.inventory > 0 then
		for i, item in pairs(self.inventory) do
			-- don't allow more items than the inventory size
			if i > self.inventory_main.x * self.inventory_main.y then
				self.inventory[i] = nil
			-- remove worn out items
			elseif item:get_wear() >= 65535 then
				self.inventory[i] = nil
			end
		end

		-- make sure the wielded item index doesn't exceed our total number of items
		if not self.use_items then
			self.inventory_wield = 0
		elseif self.inventory_wield <= 0 then
			self.inventory_wield = 1
		elseif self.inventory_wield > #self.inventory then
			self.inventory_wield = #self.inventory
		end
	end

	local tool_stack = self.inventory and self.inventory[self.inventory_wield]
	local tool_item = tool_stack and minetest.registered_items[tool_stack:get_name()]

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
						creatures:sound(self.sounds.die, self.object)
					end
					inventory_drop(self)
					self.object:remove()
				else
					if self.sounds and self.sounds.damage then
						creatures:sound(self.sounds.damage, self.object)
					end
				end
			end
			self.old_y = s.y
		end
	end

	-- timer: limit the execution of this code by timer_env, threshold set to 1 second
	self.timer_env = self.timer_env + dtime
	if self.timer_env >= 1 then
		self.timer_env = 0

		local pos = s
		pos.y = pos.y - 1 -- exclude player offset
		local n = minetest.env:get_node(pos)
		local n_head = minetest.env:get_node(s_head)
		local l = minetest.env:get_node_light(pos)
		local dmg = 0

		-- audibility: set mob audibility for node footsteps
		if v_xz > 1 then
			local pos_under = {x = s.x, y = s.y - 1, z = s.z}
			local node_under = minetest.env:get_node(pos_under)
			local sounds = minetest.registered_items[node_under.name].sounds
			local sound = sounds and sounds.footstep
			if sound then
				creatures:audibility_set(self.object, sound.gain, 1)
			end
		end

		-- environment damage: add light damage
		if self.env_damage.light and self.env_damage.light ~= 0 and l and
		(l >= self.env_damage.light_level or l < -self.env_damage.light_level) then
			dmg = dmg + self.env_damage.light
		end

		-- environment damage: add damage_per_second node damage
		local n_damage = minetest.registered_items[n.name].damage_per_second
		if n_damage then
			dmg = dmg + n_damage
		end

		-- environment damage: add group damage
		if self.env_damage.groups then
			for group, amount in pairs(self.env_damage.groups) do
				if amount ~= 0 and minetest.get_item_group(n.name, group) ~= 0 then
					dmg = dmg + amount
				end
			end
		end

		-- environment damage: add drowning damage
		local n_drowning = minetest.registered_items[n_head.name].drowning
		if n_drowning and n_drowning ~= 0 then
			if self.breath > 0 then
				self.breath = self.breath - 1
			else
				dmg = dmg + n_drowning
			end
		elseif self.breath < 11 then
			self.breath = self.breath + 1
		end

		-- environment damage: apply the damage
		if dmg ~= 0 and minetest.setting_getbool("enable_damage") then
			self.object:set_hp(self.object:get_hp() - dmg)
			creatures:particles(self.object, nil)
			if self.object:get_hp() == 0 then
				if self.sounds and self.sounds.die then
					creatures:sound(self.sounds.die, self.object)
				end
				inventory_drop(self)
				self.object:remove()
			else
				if self.sounds and self.sounds.damage then
					creatures:sound(self.sounds.damage, self.object)
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
		local radius = math.max(self.traits_set.vision, self.traits_set.hearing)

		-- alert: modify alert level periodically
		if self.alert then
			self.alert_level = math.max(0, math.min(1, self.alert_level + self.alert.add))
		end

		-- targets: add node targets
		if self.nodes and #self.nodes > 0 then
			local distance = self.traits_set.vision / 2
			local corner_start = {x = s_head.x - distance, y = s_head.y - distance, z = s_head.z - distance}
			local corner_end = {x = s_head.x + distance, y = s_head.y + distance, z = s_head.z + distance}
			for i, node in pairs(self.nodes) do
				local pos_all = minetest.find_nodes_in_area_under_air(corner_start, corner_end, node.nodes)
				for _, pos_this in ipairs(pos_all) do
					local id = "x"..pos_this.x.."y"..pos_this.y.."z"..pos_this.z
					if not creatures:target_get(self, id) then
						local pos_this_up = {x = pos_this.x, y = pos_this.y + 1, z = pos_this.z}
						if awareness_sight(s_head, pos_this_up, self.object:getyaw(), 0, tonumber(minetest.setting_get("fov")), self.traits_set.vision) then
							local name = minetest.env:get_node(pos_this).name
							creatures:target_set(self, id, {position = pos_this_up, name = name, light_min = node.light_min, light_max = node.light_max, objective = node.objective, priority = node.priority})
						end
					end
				end
			end
		end

		-- targets: add player or entity targets
		if self.teams_target.attack or self.teams_target.avoid or self.teams_target.follow then
			local objects = minetest.env:get_objects_inside_radius(s_head, radius)
			for _, obj in pairs(objects) do
				local ent = obj:get_luaentity()
				if obj ~= self.object and (obj:is_player() or ent) then
					local obj_pos = obj:getpos()
					if awareness_bump(self, obj) or
					awareness_audibility(s_head, obj, self.traits_set.hearing) or
					awareness_sight(s_head, obj_pos, self.object:getyaw(), 0, tonumber(minetest.setting_get("fov")), self.traits_set.vision) then
						local relation = creatures:alliance(self.object, obj)

						-- alert: modify alert level based on our relationship with the target
						if self.alert and relation then
							if relation < -creatures.teams_neutral then
								self.alert_level = math.max(0, math.min(1, self.alert_level + (self.alert.add_foe * -relation)))
							elseif relation > creatures.teams_neutral then
								self.alert_level = math.max(0, math.min(1, self.alert_level + (self.alert.add_friend * relation)))
							end
						end

						-- attempt to add the target if it doesn't already exist
						if not creatures:target_get(self, obj) then
							-- this is a dropped item
							if ent and ent.name == "__builtin:item" and self.use_items then
								-- set this as a custom attack target, which will make the mob walk toward the item and pick it up
								local stack = ItemStack(ent.itemstring)
								local stack_count = stack:get_count()
								local stack_capabilities = stack:get_tool_capabilities()
								local stack_damage = 1
								if stack_capabilities.damage_groups then
									for _, dmg in pairs(stack_capabilities.damage_groups) do
										stack_damage = stack_damage * dmg
									end
								end
								-- determine target priority based on count, tool capabilities, and any criteria that can be used to establish its value
								local priority = 1 - 1 / math.max(1, stack_count * (stack_damage / stack_capabilities.full_punch_interval + stack_capabilities.max_drop_level))
								-- custom target function used to pick up the item
								local on_punch = function (self, target)
									local ent = target.entity:get_luaentity()
									local stack = ItemStack(ent.itemstring)
									if inventory_add(self, stack, false) then
										target.entity:remove()
									end
									return false
								end
								-- check if this item can be added to the inventory, and set it as a target if so
								if inventory_add(self, stack, true) then
									creatures:target_set(self, obj, {entity = obj, name = ent.name, objective = "attack", priority = priority, on_punch = on_punch})
								end
							-- this contains an on_mob_target function
							elseif ent and ent.on_mob_target then
								local target = ent.on_mob_target(self)
								if target then
									creatures:target_set(self, obj, target)
								end
							-- this is a creature
							elseif relation and math.abs(relation) > creatures.teams_neutral then
								local name = nil
								if ent then
									name = ent.name
								else
									name = obj:get_player_name()
								end

								-- attack targets
								if self.teams_target.attack and minetest.setting_getbool("enable_damage") and relation <= -1 + self.traits_set.aggressivity then
									creatures:target_set(self, obj, {entity = obj, name = name, objective = "attack", priority = math.abs(relation) * self.traits_set.aggressivity})
								-- avoid targets
								elseif self.teams_target.avoid and relation <= -1 + self.traits_set.fear then
									creatures:target_set(self, obj, {entity = obj, name = name, objective = "avoid", priority = math.abs(relation) * self.traits_set.fear})
								-- follow targets
								elseif self.teams_target.follow and relation >= self.traits_set.loyalty then
									creatures:target_set(self, obj, {entity = obj, name = name, objective = "follow", priority = math.abs(relation) * self.traits_set.loyalty})
								end
							end
						end
					end
				end
			end
		end

		-- targets: remove or modify targets
		for obj, target in pairs(self.targets) do
			if target.position or target.entity:is_player() or target.entity:get_luaentity() then
				if not target.persist then
					local obj_pos = target.position or target.entity:getpos()
					local dist = vector.distance(s_head, obj_pos)
					local dist_max = target.distance or radius
					local ent = nil
					if target.entity then
						ent = target.entity:get_luaentity()
					end

					-- remove targets which are out of range
					if dist > dist_max then
						creatures:target_set(self, obj, nil)
					-- remove node targets that don't meet the necessary criteria
					elseif target.position and not target.entity and target.name then
						local node_pos = {x = target.position.x, y = target.position.y - 1, z = target.position.z}
						local node_name = minetest.env:get_node(node_pos).name
						local node_light = minetest.get_node_light(target.position, nil)
						if node_name ~= target.name or not node_light or node_light < target.light_min or node_light > target.light_max then
							creatures:target_set(self, obj, nil)
						end
					-- remove entity targets which are dead
					elseif target.entity and target.entity:get_hp() <= 0 then
						creatures:target_set(self, obj, nil)
					-- if the mob is no longer fit to fight, change attack targets to avoid
					elseif target.entity and (target.entity:is_player() or (ent and ent.teams)) and
					target.objective == "attack" and self.teams_target.avoid and
					self.object:get_hp() <= self.hp_max * self.traits_set.fear then
						target.objective = "avoid"
						creatures:target_set(self, obj, target)
					-- don't follow mobs which are following someone else or a persistent target
					elseif target.entity and target.objective == "follow" and
					ent and ent.target_current and (ent.target_current.entity or ent.target_current.persist) then
						creatures:target_set(self, obj, nil)
					end
				end
			else
				-- remove entities which are no longer available
				creatures:target_set(self, obj, nil)
			end
		end

		-- targets: choose the most important target
		self.target_current = nil
		local best_priority = 0
		for _, target in pairs(self.targets) do
			local obj_pos = target.position or target.entity:getpos()
			local dist = vector.distance(s_head, obj_pos)
			local dist_max = target.distance or radius

			-- an engine bug occasionally causes incorrect positions, so check that distance isn't 0
			if dist ~= 0 and dist <= dist_max then
				local ent = target and target.entity and target.entity:get_luaentity()
				local interest = target.priority * (1 - dist / dist_max) + ((1 - self.traits_set.determination) * math.random())

				-- alert: choose enemy targets over friendly targets based on alert level
				if self.alert and not target.persist and ((ent and ent.teams) or (target.entity and target.entity:is_player())) then
					if target.objective ~= "follow" then
						interest = interest * self.alert_level
					else
						interest = interest * (1 - self.alert_level)
					end
				end

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
			if not tool_item.on_mob_wield(self, tool_stack) then
				return
			end
		end

		-- targets: if the target has an on_step function, only continue if it returns true
		if self.target_current and self.target_current.on_step then
			if not self.target_current.on_step(self, self.target_current) then
				return
			end
		end

		-- handle actions
		if self.target_current and dest then
			self.v_pos = dest
			self.v_avoid = self.target_current.objective == "avoid"
			local dist = vector.distance(s, dest)
			local dist_max = self.target_current.distance or self.traits_set.vision

			local ent = self.target_current.entity and self.target_current.entity:get_luaentity()
			local use_alert = self.alert and not self.target_current.persist and ((ent and ent.teams) or (self.target_current.entity and self.target_current.entity:is_player()))
			local is_enemy = self.target_current.objective ~= "follow"
			local walk_dist = 0
			if self.target_current.objective == "follow" then
				walk_dist = math.max(5, dist_max / 10)
			elseif self.target_current.objective == "attack" then
				walk_dist = 2
			end

			-- alert: determine possible actions based on alert level
			local action_look = not use_alert or ((is_enemy and self.alert_level >= self.alert.action_look) or (not is_enemy and 1 - self.alert_level >= self.alert.action_look))
			local action_walk = not use_alert or (action_look and (is_enemy and self.alert_level >= self.alert.action_walk) or (not is_enemy and 1 - self.alert_level >= self.alert.action_walk))
			local action_run = not use_alert or (action_walk and (is_enemy and self.alert_level >= self.alert.action_run) or (not is_enemy and 1 - self.alert_level >= self.alert.action_run))
			local action_punch = not use_alert or (is_enemy and action_look and self.alert_level >= self.alert.action_punch)

			-- action: punch the target
			if action_punch and self.target_current.objective == "attack" and dist <= walk_dist then
				creatures:animation_set(self.object, "punch", 1)
				self.v_speed = 0
				if self.timer_attack >= self.traits_set.attack_interval then
					self.timer_attack = 0
					local can_punch = true

					-- inventory: if the wielded item has an on_mob_punch function, only punch if it returns true
					if tool_item and tool_item.on_mob_punch then
						can_punch = tool_item.on_mob_punch(self, tool_stack)
					end

					-- targets: if the target has an on_punch function, only punch if it returns true
					if can_punch and self.target_current.on_punch then
						can_punch = self.target_current.on_punch(self, self.target_current)
					end

					if can_punch then
						local capabilities = self.attack_capabilities
						if self.sounds and self.sounds.attack then
							creatures:sound(self.sounds.attack, self.object)
						end

						-- this is a node target
						if self.target_current.position then
							local pos = {x = self.target_current.position.x, y = self.target_current.position.y - 1, z = self.target_current.position.z}
							local name = minetest.env:get_node(pos).name
							if not self.use_items or inventory_add(self, name, false) then
								minetest.dig_node(pos)
							end
						-- this is an entity target
						elseif self.target_current.entity and capabilities then
							-- if a custom punch interval isn't set, use the attack_interval trait
							if not capabilities.full_punch_interval then
								capabilities.full_punch_interval = self.traits_set.attack_interval
							end

							if tool_stack then
								local tool_capabilities = tool_stack:get_tool_capabilities()
								if tool_capabilities.damage_groups then
									-- use the tool's capabilities instead of the mob's, except for attack_inverval as this causes breakage for mobs
									local attack_interval = capabilities.full_punch_interval
									capabilities = tool_capabilities
									capabilities.full_punch_interval = attack_interval
									-- wear out the tool based on the total amount of damage it can deal
									if creatures.item_wear and creatures.item_wear > 0 and not minetest.setting_getbool("creative_mode") then
										local tool_damage = 1
										for _, dmg in pairs(tool_capabilities.damage_groups) do
											tool_damage = tool_damage * dmg
										end
										tool_stack:add_wear(creatures.item_wear / tool_damage)
									end
								end
							end

							local dir = vector.direction(self.v_pos, s)
							self.target_current.entity:punch(self.object, self.traits_set.attack_interval, capabilities, dir)
						end
					end
				end

			-- action: run toward or away from the target
			elseif action_run and minetest.setting_getbool("fast_mobs") and
			((not self.v_avoid and dist / dist_max >= 1 - self.target_current.priority) or
			(self.v_avoid and dist / dist_max < 1 - self.target_current.priority)) then
				if action_punch and not self.v_avoid then
					creatures:animation_set(self.object, "walk_punch", 2)
				else
					creatures:animation_set(self.object, "walk", 2)
				end
				self.v_speed = self.run_velocity

			-- action: walk toward or away from the target
			elseif action_walk and dist > walk_dist then
				if action_punch and not self.v_avoid then
					creatures:animation_set(self.object, "walk_punch", 1)
				else
					creatures:animation_set(self.object, "walk", 1)
				end
				self.v_speed = self.walk_velocity

			-- action: look toward or away from the target
			elseif action_look and dist > walk_dist then
				if action_punch and not self.v_avoid then
					creatures:animation_set(self.object, "punch", 1)
				else
					creatures:animation_set(self.object, "stand", 1)
				end
				self.v_speed = 0

			-- action: none
			else
				creatures:animation_set(self.object, "stand", 1)
				self.v_speed = nil
			end
		else
			creatures:animation_set(self.object, "stand", 1)
			self.v_speed = nil
			return
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
		local target = self.v_pos
		if self.v_path and #self.v_path > 0 then
			target = self.v_path[1]
		end

		-- movement: jump whenever stuck
		if self.jump and self.v_start and v_xz <= 1 and v.y == 0 then
			v.y = self.jump_velocity * 0.75
			self.object:setvelocity(v)
		end

		-- movement: set orientation and speed
		if target and self.v_speed then
			-- account liquid viscosity
			local pos = s
			pos.y = pos.y - 1 -- exclude player offset
			local n = minetest.env:get_node(pos)
			local viscosity = minetest.registered_items[n.name].liquid_viscosity or 0
			viscosity = viscosity + 1

			-- calculate the orientation
			local dir = vector.direction(target, s)
			local yaw = math.atan(dir.z / dir.x) + math.pi / 2
			if target.x > s.x then
				yaw = yaw + math.pi
			end
			if self.v_avoid then
				yaw = yaw + math.pi
			end

			self.object:setyaw(yaw)
			self.set_velocity(self, self.v_speed / viscosity)
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
	self.object:setacceleration({x = 0, y = -self.gravity, z = 0})
	self.object:setvelocity({x = 0, y = self.object:getvelocity().y, z = 0})

	-- if damage is disabled, make mobs invincible
	if minetest.setting_getbool("enable_damage") then
		self.object:set_armor_groups(self.armor)
	else
		self.object:set_armor_groups({})
	end

	self.set_staticdata(self, staticdata, dtime_s)

	creatures:configure_mob(self)
	creatures:animation_set(self.object, "stand", 1)

	-- randomize timers to prevent mobs from acting synchronously if initialized at the same moment
	self.timer_life = creatures.timer_life and creatures.timer_life * math.random()
	self.timer_think = self.think * math.random()
	self.timer_decision = self.traits_set.decision_interval * math.random()
	self.timer_attack = self.traits_set.attack_interval * math.random()
	self.timer_env = 1 * math.random()
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
		-- trigger the player's attack sound
		if hitter:is_player() and psettings.sounds and psettings.sounds.attack then
			creatures:sound(psettings.sounds.attack, hitter)
		end

		-- if attacker is a player, wear out their wielded tool
		if hitter:is_player() and creatures.item_wear and creatures.item_wear > 0 and not minetest.setting_getbool("creative_mode") then
			local item = hitter:get_wielded_item()
			local item_capabilities = item:get_tool_capabilities()
			if item_capabilities.damage_groups then
				local item_damage = 1
				for _, dmg in pairs(item_capabilities.damage_groups) do
					item_damage = item_damage * dmg
				end
				item:add_wear(creatures.item_wear / item_damage)
				hitter:set_wielded_item(item)
			end
		end

		-- spawn damage particles
		creatures:particles(self.object, nil)
	end

	-- handle mob death
	if self.object:get_hp() <= 0 then
		if self.sounds and self.sounds.die then
			creatures:sound(self.sounds.die, self.object)
		end
		inventory_drop(self)
	elseif not delay and relation then
		-- targets: take action toward the creature who hit us
		if self.teams_target.attack or self.teams_target.avoid then
			local ent = hitter:get_luaentity()
			local def = creatures:target_get(self, hitter)
			if not (def and def.persist) and (hitter:is_player() or (ent and ent.teams)) then
				local importance = (1 - relation) * 0.5
				local action = math.random()
				local name = nil
				if ent then
					name = ent.name
				else
					name = hitter:get_player_name()
				end

				-- alert: modify alert level on punch
				if self.alert then
					self.alert_level = math.max(0, math.min(1, self.alert_level + self.alert.add_punch * importance))
				end

				-- targets: change or add hitter target
				if self.teams_target.attack and minetest.setting_getbool("enable_damage") and importance * self.traits_set.aggressivity >= action then
					if not def then
						creatures:target_set(self, hitter, {entity = hitter, name = name, objective = "attack", priority = importance * self.traits_set.aggressivity})
					else
						def.objective = "attack"
						def.priority = def.priority + importance * self.traits_set.aggressivity
						creatures:target_set(self, hitter, def)
					end
				elseif self.teams_target.avoid and importance * self.traits_set.fear >= action then
					if not def then
						creatures:target_set(self, hitter, {entity = hitter, name = name, objective = "avoid", priority = importance * self.traits_set.fear})
					else
						def.objective = "avoid"
						def.priority = def.priority + importance * self.traits_set.fear
						creatures:target_set(self, hitter, def)
					end
				end
			end
		end

		if self.sounds and self.sounds.damage then
			creatures:sound(self.sounds.damage, self.object)
		end
	end
end

-- logic_mob_rightclick: Executed in on_rightclick, handles: selection
function logic_mob_rightclick (self, clicker)
	creatures.selected[clicker] = self
end
