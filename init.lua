creatures = {}

-- Pipe the creature registration function into the player and mob api
function creatures:register_creature(name, def)
	creatures:register_mob(name, def)
	creatures:register_player(name, def)
end

-- Load files
dofile(minetest.get_modpath("creatures").."/api_mobs.lua")
dofile(minetest.get_modpath("creatures").."/api_players.lua")
dofile(minetest.get_modpath("creatures").."/races.lua")
