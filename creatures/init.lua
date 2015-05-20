creatures = {}

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
	local creature1_teams = {}
	if creature1:get_luaentity() then
		creature1_teams = creature1:get_luaentity().teams
	elseif creature1:is_player() then
		local race = creatures:player_get(creature1)
		creature1_teams = creatures.player_def[race].teams
	end

	local creature2_teams = {}
	if creature2:get_luaentity() then
		creature2_teams = creature2:get_luaentity().teams
	elseif creature2:is_player() then
		local race = creatures:player_get(creature2)
		creature2_teams = creatures.player_def[race].teams
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

-- Pipe the creature registration function into the player and mob api
function creatures:register_creature(name, def)
	creatures:register_mob(name, def)
	creatures:register_player(name, def)
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
