creatures = {}

-- Determines whether two players or mobs are allies
function creatures:allied(creature1, creature2)
	local creature1_teams = {}
	if creature1:get_luaentity() then
		creature1_teams = creature1:get_luaentity().teams
	elseif creature1:is_player() then
		local race = creatures:get_race(creature1)
		creature1_teams = creatures.player_settings[race].teams
	end

	local creature2_teams = {}
	if creature2:get_luaentity() then
		creature2_teams = creature2:get_luaentity().teams
	elseif creature2:is_player() then
		local race = creatures:get_race(creature2)
		creature2_teams = creatures.player_settings[race].teams
	end

	for _, team1 in ipairs(creature1_teams) do
		for _, team2 in ipairs(creature2_teams) do
			if team1 == team2 then
				return true
			end
		end
	end
	return false
end

-- Pipe the creature registration function into the player and mob api
function creatures:register_creature(name, def)
	creatures:register_mob(name, def)
	creatures:register_player(name, def)
end

-- Load files
dofile(minetest.get_modpath("creatures").."/api_mobs.lua")
dofile(minetest.get_modpath("creatures").."/api_players.lua")
dofile(minetest.get_modpath("creatures").."/races.lua")
