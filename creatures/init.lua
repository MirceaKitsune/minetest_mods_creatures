creatures = {}

-- Default settings

creatures.player_default = ""
creatures.teams_neutral = 0
creatures.sleep_raduis = 10
creatures.timer_life = 100
creatures.item_wear = 0

-- Local & Global values

-- stores the audibility of objects
creatures.audibility = {}

-- Helper functions

-- calculates the linear interpolation between two numbers
function lerp (value_start, value_end, control)
	return (1 - control) * value_start + control * value_end
end

-- returns the angle difference between pos1 and pos2, as seen from pos1 at the specified yaw and pitch
function pos_to_angle (pos1, pos2, yaw, pitch)
	-- note: we must invert the yaw for x in yaw_vec, to keep the result from inverting when facing opposite directions (0* becoming 180*)
	local yaw_vec = {x = -math.sin(yaw) * math.cos(pitch), y = math.sin(pitch), z = math.cos(yaw) * math.cos(pitch)}
	local pos_subtract = vector.subtract(pos2, pos1)
	local pos_dotproduct = (yaw_vec.x * pos_subtract.x) + (yaw_vec.y * pos_subtract.y) + (yaw_vec.z * pos_subtract.z)
	local angle = math.deg(math.acos(pos_dotproduct / (vector.length(yaw_vec) * vector.length(pos_subtract))))
	return angle
end

-- Global functions

-- transforms a mob into a player:
function creatures:mob_to_player(player, mob)
	-- set player position and race
	player:setpos(mob.object:getpos())
	player:set_look_yaw(mob.object:getyaw())
	player:set_look_pitch(0)
	creatures:player_set(player, {name = mob.name, skin = mob.skin, hp = mob.object:get_hp()})
	player:set_breath(mob.breath)

	-- move inventory from the mob to the player
	local inv_player = player:get_inventory()
	local inv_mob = mob.inventory
	if inv_player then
		inv_player:set_list("main", {})
		for _, entry in pairs(inv_mob) do
			inv_player:add_item("main", entry)
		end
	end

	-- remove the mob
	mob.object:remove()
end

-- transforms a player into a mob:
function creatures:player_to_mob(player)
	-- get player position and race
	local name, skin = creatures:player_get(player)
	local obj = creatures:spawn(name, player:getpos())
	local ent = obj:get_luaentity()
	obj:setyaw(player:get_look_yaw() - (math.pi / 2))
	obj:set_hp(player:get_hp())
	ent.skin = skin
	ent.breath = player:get_breath()

	-- move inventory from the player to the mob
	ent.inventory = {}
	local inv = player:get_inventory()
	local size = inv:get_size("main")
	for i = 1, size do
		local stack = inv:get_stack("main", i)
		if not stack:is_empty() then
			table.insert(ent.inventory, stack)
		end
	end
	inv:set_list("main", {})

	-- configure the mob's properties, and change the player into the default creature
	creatures:configure_mob(ent)
	creatures:player_set(player, {name = creatures.player_default})
end

-- Gets the audibility of this object or position
function creatures:audibility_get(object)
	if object then
		return creatures.audibility[object]
	end
	return nil
end

-- Sets the audibility of this object or position
function creatures:audibility_set(object, amount, duration)
	if object then
		creatures.audibility[object] = amount
		minetest.after(duration, function()
			if object then
				creatures.audibility[object] = nil
			end
		end)
	end
end

-- Plays a creature sound
function creatures:sound(snd, obj)
	minetest.sound_play(snd, {object = obj})
	creatures:audibility_set(obj, 1, 2)
end

-- Creates a particle burst using random pieces of the creature's texture
function creatures:particles(creature, multiplier)
	-- select the creature settings
	local textures, skin, particles = nil
	if creature:get_luaentity() then
		local def = creature:get_luaentity()
		textures = def.textures
		skin = def.skin
		particles = def.particles
	elseif creature:is_player() then
		local get_name, get_skin = creatures:player_get(creature)
		local def = creatures.player_def[get_name]
		textures = def.textures
		skin = get_skin
		particles = def.particles
	end

	if not particles then
		return
	end

	if not multiplier then
		multiplier = 1
	end

	local pos = creature:getpos()
	local size = (particles.size_x + particles.size_y) / 2
	local gravity = tonumber(minetest.setting_get("movement_gravity"))

	-- select the texture group based on skin, then use a random texture from it
	local texture = textures
	if skin > 0 then
		texture = textures[skin]
	end
	texture = texture[math.random(1, #texture)]
	texture = texture.."^[noalpha"

	-- determine the area on the player texture to pick
	local texture_pos_x_min = particles.pos_min_x
	local texture_pos_x_max = math.max(particles.pos_min_x, particles.pos_max_x - particles.size_x)
	local texture_pos_x = math.random(texture_pos_x_min, texture_pos_x_max)
	local texture_pos_y_min = particles.pos_min_y
	local texture_pos_y_max = math.max(particles.pos_min_y, particles.pos_max_y - particles.size_y)
	local texture_pos_y = math.random(texture_pos_y_min, texture_pos_y_max)
	local image = "[combine:"..particles.size_x.."x"..particles.size_y..":-"..texture_pos_x..",-"..texture_pos_y.."="..texture

	-- create the particle spawner
	minetest.add_particlespawner({
		amount = particles.amount * multiplier,
		time = 0.1,
		minpos = pos,
		maxpos = pos,
		minvel = {x=-1 * size, y=-1 * size, z=-1 * size},
		maxvel = {x=1 * size, y=1 * size, z=1 * size},
		minacc = {x=0, y=-gravity * size * 0.5, z=0},
		maxacc = {x=0, y=-gravity * size * 1.0, z=0},
		minexptime = particles.time * 0.5,
		maxexptime = particles.time * 1.0,
		minsize = size * 0.25,
		maxsize = size * 0.5,
		collisiondetection = true,
		vertical = false,
		texture = image,
	})
end

-- Determines whether two players or mobs are allies
function creatures:alliance(creature1, creature2)
	local creature1_teams = nil
	if creature1:get_luaentity() then
		creature1_teams = creature1:get_luaentity().teams
	elseif creature1:is_player() then
		local race = creatures:player_get(creature1)
		creature1_teams = creatures.player_def[race].teams
	end

	local creature2_teams = nil
	if creature2:get_luaentity() then
		creature2_teams = creature2:get_luaentity().teams
	elseif creature2:is_player() then
		local race = creatures:player_get(creature2)
		creature2_teams = creatures.player_def[race].teams
	end

	if not creature1_teams or not creature2_teams then
		return nil
	end

	local common = 0
	for i, element1 in pairs(creature1_teams) do
		local element2 = creature2_teams[i]
		if element2 then
			common = common + (element1 * element2)
		end
	end
	common = math.min(1, math.max(-1, common))

	return common
end

-- Generates an outfit using multiple textures and colors
function creatures:outfit(def)
	local layers = {}

	-- colorize each material with each color
	for i, entry in pairs(def) do
		local layer = {}
		for _, texture in pairs(entry.textures) do
			-- colors are defined, colorize each texture in the material
			if entry.colors and #entry.colors > 0 then
				local ratio = entry.colors_ratio or 0
				for _, color in pairs(entry.colors) do
					local sub_textures = {}
					for _, sub_texture in pairs(texture) do
						table.insert(sub_textures, sub_texture.."^[colorize:"..color..":"..ratio)
					end
					table.insert(layer, sub_textures)
				end
			-- no colors are defined, apply the material as is
			else
				table.insert(layer, texture)
			end
		end
		table.insert(layers, layer)
	end

	-- function that combines the paired textures of two materials in order
	local function product(t1, t2)
		local t = {}
		local n = 1
		for _, v1 in pairs(t1) do
			for _, v2 in pairs(t2) do
				local sub_t = {}
				local sub_count = math.min(#v1, #v2)
				for i = 1, sub_count do
					table.insert(sub_t, v1[i].."^("..v2[i]..")")
				end
				if #sub_t > 0 then
					t[n] = sub_t
					n = n + 1
				end
			end
		end
		return t
	end

	-- obtain all possible material combinations into a single skin table
	local skins = layers[1]
	if #layers > 1 then
		for i, entry in pairs(layers) do
			if i > 1 then
				skins = product(skins, layers[i])
			end
		end
	end

	return skins
end

-- Pipe the creature registration function into the player and mob api
function creatures:register_creature(name, def)
	creatures:register_mob(name, def)
	creatures:register_player(name, def)
end

-- Pipe the get_animation function into the player and mob api
function creatures:animation_get(self)
	local ent = self:get_luaentity()
	if ent then
		return ent.get_animation(ent)
	elseif self:is_player() then
		return creatures:player_animation_get(self)
	end
	return nil
end

-- Pipe the set_animation function into the player and mob api
function creatures:animation_set(self, type, speed)
	local ent = self:get_luaentity()
	if ent then
		ent.set_animation(ent, type, speed)
	elseif self:is_player() then
		creatures:player_animation_set(self, type, speed)
	end
end

-- Load files
dofile(minetest.get_modpath("creatures").."/api_players.lua")
dofile(minetest.get_modpath("creatures").."/api_mobs.lua")
dofile(minetest.get_modpath("creatures").."/logic_players.lua")
dofile(minetest.get_modpath("creatures").."/logic_mobs.lua")

-- Log mod
if minetest.setting_get("log_mods") then
	minetest.log("action", "creatures loaded")
end
