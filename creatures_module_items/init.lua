creatures_module_items = {}

-- Functions

minetest.register_entity("creatures_module_items:item", {
	hp_max = 1,
	visual = "wielditem",
	visual_size = {x = 0, y = 0},
	collisionbox = {0, 0, 0, 0, 0, 0},
	textures = {"air"},
	is_visible = false,
	physical = false,
	on_activate = function(self, staticdata, dtime_s)
		-- inventory item objects are created whenever the server starts, so don't persist old ones
		local tmp = minetest.deserialize(staticdata)
		if tmp and tmp.remove then
			self.object:remove()
			return
		end
	end,
	on_step = function(self, dtime)
		if self.owner then
			-- owner is a mob
			if self.owner:get_luaentity() then
				-- mob component to be implemented
			-- owner is a player
			elseif self.owner:is_player() then
				local num = self.number - 1
				local num_wield = self.owner:get_wield_index()
				-- the first entry always represents the wielded item
				if num == 0 then
					num = num_wield
				-- if this is the wielded item, it appears in our hand as specified above, so it shouldn't appear in another slot as well
				elseif num == num_wield then
					self.object:set_properties({textures = {"air"}, is_visible = false})
					return
				end

				local inv = self.owner:get_inventory()
				local stack = inv:get_stack(self.inventory, num)
				local item = stack:get_name()

				if item and item ~= "" then
					self.object:set_properties({textures = {item}, is_visible = true})
				else
					self.object:set_properties({textures = {"air"}, is_visible = false})
				end
			-- owner is gone
			else
				self.object:remove()
				return
			end
		end
	end,
	get_staticdata = function(self)
		-- inventory item objects are created whenever the server starts, so don't persist old ones
		local tmp = {}
		tmp.remove = true
		return minetest.serialize(tmp)
	end,
})

function creatures_module_items:player_join (player, dtime)
	local pos = player:getpos()
	local race = creatures:player_get(player)
	local settings = creatures.player_def[race].custom.creatures_module_items

	-- add an item entity for each slot in order
	for i, entry in pairs(settings.slots) do
		local obj = minetest.env:add_entity(pos, "creatures_module_items:item")
		local ent = obj:get_luaentity()
		ent.owner = player
		ent.inventory = entry.inventory
		ent.number = i
		obj:set_properties({visual_size = {x = entry.size, y = entry.size}})
		obj:set_attach(player, entry.bone, entry.pos, entry.rot)
	end
end
