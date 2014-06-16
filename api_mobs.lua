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
		think = def.think,
		view_range = def.view_range,
		damage = def.damage,
		env_damage = def.env_damage,
		disable_fall_damage = def.disable_fall_damage,
		drops = def.drops,
		armor = def.armor,
		drawtype = def.drawtype,
		on_rightclick = def.on_rightclick,
		attack_type = def.attack_type,
		arrow = def.arrow,
		shoot_interval = def.shoot_interval,
		sounds = def.sounds,
		animation = def.animation,
		follow = def.follow,
		jump = def.jump or true,
		teams = def.teams,
		
		mob = true,
		timer_life = 60,
		timer_think = 0,
		timer_attack = 0,
		timer_env_damage = 0,
		walk_velocity = tonumber(minetest.setting_get("movement_speed_walk")) * def.physics.speed,
		run_velocity = tonumber(minetest.setting_get("movement_speed_fast")) * def.physics.speed,
		jump_velocity = tonumber(minetest.setting_get("movement_speed_jump")) * def.physics.jump,
		gravity = tonumber(minetest.setting_get("movement_gravity")) * def.physics.gravity,
		attack = {entity=nil, dist=nil},
		state = "stand",
		v_start = false,
		old_y = nil,
		alliance_action = 0,
		tamed = false,
		
		set_velocity = function(self, v)
			local yaw = self.object:getyaw()
			if self.drawtype == "side" then
				yaw = yaw+(math.pi/2)
			end
			local x = math.sin(yaw) * -v
			local z = math.cos(yaw) * v
			self.object:setvelocity({x=x, y=self.object:getvelocity().y, z=z})
		end,
		
		get_velocity = function(self)
			local v = self.object:getvelocity()
			return (v.x^2 + v.z^2)^(0.5)
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
			if type == "stand" then
				if
					self.animation.stand_start
					and self.animation.stand_end
				then
					self.object:set_animation(
						{x=self.animation.stand_start,y=self.animation.stand_end},
						self.animation.speed, 0
					)
					self.animation.current = "stand"
				end
			elseif type == "walk" then
				if
					self.animation.walk_start
					and self.animation.walk_end
				then
					self.object:set_animation(
						{x=self.animation.walk_start,y=self.animation.walk_end},
						self.animation.speed, 0
					)
					self.animation.current = "walk"
				end
			elseif type == "run" then
				if
					self.animation.run_start
					and self.animation.run_end
				then
					self.object:set_animation(
						{x=self.animation.run_start,y=self.animation.run_end},
						self.animation.speed * 2, 0
					)
					self.animation.current = "run"
				end
			elseif type == "punch" then
				if
					self.animation.punch_start
					and self.animation.punch_end
				then
					self.object:set_animation(
						{x=self.animation.punch_start,y=self.animation.punch_end},
						self.animation.speed, 0
					)
					self.animation.current = "punch"
				end
			end
		end,
		
		on_step = function(self, dtime)
			if self.attack_type and minetest.setting_getbool("only_peaceful_mobs") then
				self.object:remove()
			end
			
			-- remove this mob if its lifetime is up and doing so is appropriate
			self.timer_life = self.timer_life - dtime
			if self.timer_life <= 0 and not self.tamed then
				local player_count = 0
				for _,obj in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), 20)) do
					if obj:is_player() then
						player_count = player_count+1
					end
				end
				if player_count == 0 and self.state ~= "attack" then
					self.object:remove()
					return
				else
					self.timer_life = 60
				end
			end
			
			-- make mobs push forward while jumping and apply gravity
			if self.object:getvelocity().y > 0.1 then
				local yaw = self.object:getyaw()
				if self.drawtype == "side" then
					yaw = yaw+(math.pi/2)
				end
				local x = math.sin(yaw) * -2
				local z = math.cos(yaw) * 2
				self.object:setacceleration({x=x, y=-self.gravity, z=z})
			else
				self.object:setacceleration({x=0, y=-self.gravity, z=0})
			end
			
			-- handle fall damage
			if self.disable_fall_damage and self.object:getvelocity().y == 0 then
				if not self.old_y then
					self.old_y = self.object:getpos().y
				else
					local d = self.old_y - self.object:getpos().y
					if d > 5 then
						local damage = d-5
						self.object:set_hp(self.object:get_hp()-damage)
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
			
			-- handle environment damage
			self.timer_env_damage = self.timer_env_damage + dtime
			if self.timer_env_damage > 1 then
				self.timer_env_damage = 0
				local pos = self.object:getpos()
				pos.y = pos.y - 1 -- exclude player offset
				local n = minetest.env:get_node(pos)
				
				if self.env_damage.light and self.env_damage.light ~= 0
					and pos.y>0
					and minetest.env:get_node_light(pos)
					and minetest.env:get_node_light(pos) > 4
					and minetest.env:get_timeofday() > 0.2
					and minetest.env:get_timeofday() < 0.8
				then
					self.object:set_hp(self.object:get_hp()-self.env_damage.light)
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
					self.object:set_hp(self.object:get_hp()-self.env_damage.water)
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
					end
				end
			end
			
			self.timer_attack = self.timer_attack+dtime

			-- Apply AI think speed, influenced by the mob's current status
			self.timer_think = self.timer_think+dtime
			if self.state == "attack" then
				if self.timer_think < self.think / 10 then
					return
				end
			elseif self.state == "follow" then
				if self.timer_think < self.think / 2 then
					return
				end
			else
				if self.timer_think < self.think then
					return
				end
			end
			self.timer_think = 0
			
			if self.sounds and self.sounds.random and math.random(1, 50) <= 1 then
				minetest.sound_play(self.sounds.random, {object = self.object})
			end

			-- probability of the mob taking actions toward a creature based on friend / foe status
			self.alliance_action = math.random()
			
			-- choose an attack target
			if self.attack_type and minetest.setting_getbool("enable_damage") and self.state ~= "attack" then
				for _,obj in ipairs(minetest.env:get_objects_inside_radius(self.object:getpos(), self.view_range)) do
					if (obj:is_player() or (obj:get_luaentity() and obj:get_luaentity().mob)) and
					1 + creatures:alliance(self.object, obj) < self.alliance_action then
						local s = self.object:getpos()
						local p = obj:getpos()
						local dist = ((p.x-s.x)^2 + (p.y-s.y)^2 + (p.z-s.z)^2)^0.5
						if dist < self.view_range then
							if self.attack.dist then
								if self.attack.dist < dist then
									self.state = "attack"
									self.attack.entity = obj
									self.attack.dist = dist
								end
							else
								self.state = "attack"
								self.attack.entity = obj
								self.attack.dist = dist
							end
						end
					end
				end
			end
			
			-- choose or discard a follow target
			if not self.following and self.state ~= "attack" then
				for _,player in pairs(minetest.get_connected_players()) do
					local s = self.object:getpos()
					local p = player:getpos()
					local dist = ((p.x-s.x)^2 + (p.y-s.y)^2 + (p.z-s.z)^2)^0.5
					if self.view_range and dist < self.view_range then
						-- reasons to start following the player
						if player:get_wielded_item():get_name() == self.follow or
						(not self.tamed and creatures:alliance(self.object, player) >= self.alliance_action) then
							self.following = player
							self.state = "follow"
						end
					end
				end
			elseif self.following then
				-- reasons to stop following the player
				if self.following:get_wielded_item():get_name() ~= self.follow and not
				(not self.tamed and creatures:alliance(self.object, self.following) >= 0) then
					self.following = nil
					self.state = "stand"
				end
			end
			
			-- carry out mob actions
			if self.state == "stand" then
				if math.random(1, 4) == 1 then
					self.object:setyaw(self.object:getyaw()+((math.random(0,360)-180)/180*math.pi))
				end
				self.set_velocity(self, 0)
				self.set_animation(self, "stand")
				if math.random(1, 100) <= 50 then
					self.set_velocity(self, self.walk_velocity)
					self.state = "walk"
					self.set_animation(self, "walk")
				end
			elseif self.state == "walk" then
				if math.random(1, 100) <= 30 then
					self.object:setyaw(self.object:getyaw()+((math.random(0,360)-180)/180*math.pi))
				end
				if self.jump and self.get_velocity(self) <= 0.5 and self.object:getvelocity().y == 0 then
					local v = self.object:getvelocity()
					v.y = self.jump_velocity
					self.object:setvelocity(v)
				end
				self:set_animation("walk")
				self.set_velocity(self, self.walk_velocity)
				if math.random(1, 100) <= 10 then
					self.set_velocity(self, 0)
					self.state = "stand"
					self:set_animation("stand")
				end
			elseif self.state == "attack" and self.attack_type == "melee" then
				if not self.attack.entity or not (self.attack.entity:get_luaentity() or self.attack.entity:is_player()) then
					self.state = "stand"
					self:set_animation("stand")
					return
				end
				local s = self.object:getpos()
				local p = self.attack.entity:getpos()
				local dist = ((p.x-s.x)^2 + (p.y-s.y)^2 + (p.z-s.z)^2)^0.5
				if dist > self.view_range or self.attack.entity:get_hp() <= 0 then
					self.state = "stand"
					self.v_start = false
					self.set_velocity(self, 0)
					self.attack = {player=nil, dist=nil}
					self:set_animation("stand")
					return
				else
					self.attack.dist = dist
				end
				
				local vec = {x=p.x-s.x, y=p.y-s.y, z=p.z-s.z}
				local yaw = math.atan(vec.z/vec.x)+math.pi/2
				if self.drawtype == "side" then
					yaw = yaw+(math.pi/2)
				end
				if p.x > s.x then
					yaw = yaw+math.pi
				end
				self.object:setyaw(yaw)
				if self.attack.dist > 2 then
					if not self.v_start then
						self.v_start = true
						self.set_velocity(self, self.run_velocity)
					else
						if self.jump and self.get_velocity(self) <= 0.5 and self.object:getvelocity().y == 0 then
							local v = self.object:getvelocity()
							v.y = self.jump_velocity
							self.object:setvelocity(v)
						end
						self.set_velocity(self, self.run_velocity)
					end
					self:set_animation("run")
				else
					self.set_velocity(self, 0)
					self:set_animation("punch")
					self.v_start = false
					if self.timer_attack > 1 then
						self.timer_attack = 0
						if self.sounds and self.sounds.attack then
							minetest.sound_play(self.sounds.attack, {object = self.object})
						end
						self.attack.entity:punch(self.object, 1.0,  {
							full_punch_interval=1.0,
							damage_groups = {fleshy=self.damage}
						}, vec)
					end
				end
			elseif self.state == "attack" and self.attack_type == "shoot" then
				if not self.attack.entity or not (self.attack.entity:get_luaentity() or self.attack.entity:is_player()) then
					self.state = "stand"
					self:set_animation("stand")
					return
				end
				local s = self.object:getpos()
				local p = self.attack.entity:getpos()
				local dist = ((p.x-s.x)^2 + (p.y-s.y)^2 + (p.z-s.z)^2)^0.5
				if dist > self.view_range or self.attack.entity:get_hp() <= 0 then
					self.state = "stand"
					self.v_start = false
					self.set_velocity(self, 0)
					self.attack = {player=nil, dist=nil}
					self:set_animation("stand")
					return
				else
					self.attack.dist = dist
				end
				
				local vec = {x=p.x-s.x, y=p.y-s.y, z=p.z-s.z}
				local yaw = math.atan(vec.z/vec.x)+math.pi/2
				if self.drawtype == "side" then
					yaw = yaw+(math.pi/2)
				end
				if p.x > s.x then
					yaw = yaw+math.pi
				end
				self.object:setyaw(yaw)
				self.set_velocity(self, 0)
				
				if self.timer_attack > self.shoot_interval and math.random(1, 100) <= 60 then
					self.timer_attack = 0
					
					self:set_animation("punch")
					
					if self.sounds and self.sounds.attack then
						minetest.sound_play(self.sounds.attack, {object = self.object})
					end
					
					local p = self.object:getpos()
					p.y = p.y + (self.collisionbox[2]+self.collisionbox[5])/2
					local obj = minetest.env:add_entity(p, self.arrow)
					local amount = (vec.x^2+vec.y^2+vec.z^2)^0.5
					local v = obj:get_luaentity().velocity
					vec.y = vec.y+1
					vec.x = vec.x*v/amount
					vec.y = vec.y*v/amount
					vec.z = vec.z*v/amount
					obj:setvelocity(vec)
				end
			elseif self.state == "follow" then
				if not self.following or not self.following:is_player() then
					self.state = "stand"
					self.v_start = false
					self.set_velocity(self, 0)
					self.following = nil
					self:set_animation("stand")
					return
				end
				
				local s = self.object:getpos()
				local p = self.following:getpos()
				local dist = ((p.x-s.x)^2 + (p.y-s.y)^2 + (p.z-s.z)^2)^0.5
				if dist > self.view_range then
					self.state = "stand"
					self.v_start = false
					self.set_velocity(self, 0)
					self.following = nil
					self:set_animation("stand")
					return
				else
					local vec = {x=p.x-s.x, y=p.y-s.y, z=p.z-s.z}
					local yaw = math.atan(vec.z/vec.x)+math.pi/2
					if self.drawtype == "side" then
						yaw = yaw+(math.pi/2)
					end
					if p.x > s.x then
						yaw = yaw+math.pi
					end
					self.object:setyaw(yaw)
					if dist > 2 then
						if not self.v_start then
							self.v_start = true
							self.set_velocity(self, self.walk_velocity)
							self:set_animation("walk")
						else
							if self.jump and self.get_velocity(self) <= 0.5 and self.object:getvelocity().y == 0 then
								local v = self.object:getvelocity()
								v.y = self.jump_velocity
								self.object:setvelocity(v)
							end

							if dist > self.view_range / 2 then
								self.set_velocity(self, self.run_velocity)
								self:set_animation("run")
							else
								self.set_velocity(self, self.walk_velocity)
								self:set_animation("walk")
							end
						end
					else
						self.v_start = false
						self.set_velocity(self, 0)
						self:set_animation("stand")
					end
					return
				end
			end
		end,
		
		on_activate = function(self, staticdata, dtime_s)
			self.object:set_armor_groups({fleshy=self.armor})
			self.object:setacceleration({x=0, y=-10, z=0})
			self.state = "stand"
			self.object:setvelocity({x=0, y=self.object:getvelocity().y, z=0})
			self.object:setyaw(math.random(1, 360)/180*math.pi)
			if self.attack_type and minetest.setting_getbool("only_peaceful_mobs") then
				self.object:remove()
			end
			self.timer_life = 600 - dtime_s
			if staticdata then
				local tmp = minetest.deserialize(staticdata)
				if tmp and tmp.timer_life then
					self.timer_life = tmp.timer_life - dtime_s
				end
				if tmp and tmp.tamed then
					self.tamed = tmp.tamed
				end
			end
			if self.timer_life <= 0 and not self.tamed then
				self.object:remove()
			end
		end,
		
		get_staticdata = function(self)
			local tmp = {
				timer_life = self.timer_life,
				tamed = self.tamed,
			}
			return minetest.serialize(tmp)
		end,
		
		on_punch = function(self, hitter)
			local psettings = creatures.player_settings[creatures:get_race(hitter)]
			local relation = creatures:alliance(self.object, hitter)
			if hitter:is_player() and psettings.sounds and psettings.sounds.attack then
				minetest.sound_play(psettings.sounds.attack, {object = hitter})
			end
			if not self.tamed and hitter == self.following and psettings.reincarnate and relation >= 0 then
				-- handle player possession of mobs
				hitter:setpos(self.object:getpos())
				hitter:set_look_yaw(self.object:getyaw())
				hitter:set_look_pitch(0)
				creatures:set_race(hitter, name)
				self.object:remove()
			elseif self.attack_type and hitter:is_player() and relation >= 0 then
				-- warn and punish the player if hitting an ally
				minetest.chat_send_player(hitter:get_player_name(), "Don't hit your allies!")
				hitter:set_hp(hitter:get_hp() - 1)
				if self.sounds and self.sounds.damage then
					minetest.sound_play(self.sounds.damage, {object = self.object})
				end
			elseif self.object:get_hp() <= 0 then
				-- handle mob death
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
				-- if the creature who hit us is an enemy, attack them
				if 1 + relation < math.random()  then
					local s = self.object:getpos()
					local p = hitter:getpos()
					local dist = ((p.x-s.x)^2 + (p.y-s.y)^2 + (p.z-s.z)^2)^0.5
					self.state = "attack"
					self.attack.entity = hitter
					self.attack.dist = dist
				end
				if self.sounds and self.sounds.damage then
					minetest.sound_play(self.sounds.damage, {object = self.object})
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
