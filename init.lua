creatures = {}

-- Determines whether two players or mobs are allies
function creatures:allied(creature1, creature2)
	local creature1_teams = {}
	if creature1.object then
		creature1_teams = creature1.teams
	elseif creature1:is_player() then
		local race = creatures:get_race(creature1)
		if not race then return true end
		creature1_teams = creatures.players[creatures:get_race(creature1)].teams
	end

	local creature2_teams = {}
	if creature2.object then
		creature2_teams = creature1.teams
	elseif creature2:is_player() then
		local race = creatures:get_race(creature2)
		if not race then return true end
		creature2_teams = creatures.players[creatures:get_race(creature2)].teams
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
