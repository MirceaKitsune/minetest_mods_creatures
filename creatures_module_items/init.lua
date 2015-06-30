creatures_module_items = {}

-- Default settings

creatures_module_items.count = 10

-- Functions

local function item_step_mob (self)
	local ent = self.owner:get_luaentity()
	local settings = ent.custom.creatures_module_items
	local entry = settings and settings.slots[self.number]

	-- if attachment configuration wasn't done yet, run it
	-- since for players we must check if race changed, use the same check here for consistency
	if self.owner_race ~= ent.name then
		self.object:set_properties({visual_size = {x = entry.size, y = entry.size}})
		self.object:set_attach(self.owner, entry.bone, entry.pos, entry.rot)
		self.enabled = true
		self.owner_race = ent.name
	end

	-- return if there is nothing to do
	if not self.enabled then return end

	-- if this entry has an on_step function, only continue if it returns true
	if entry.on_step then
		if not entry.on_step(self) then return end
	end

	-- determine the inventory slot this item represents
	-- the first entry always represents the wielded item
	local item = nil
	if self.number == 1 then
		local num = ent.inventory_wield
		local stack = ent.inventory and ent.inventory[num]
		item = stack and stack:get_name()
	elseif self.number - 1 ~= ent.inventory_wield then
		local num = self.number - 1
		local stack = ent.inventory and ent.inventory[num]
		item = stack and stack:get_name()
	end

	-- if the item has changed, update visual appearance
	if self.owner_item ~= item then
		if item and item ~= "" then
			self.object:set_properties({textures = {item}, is_visible = true})
		else
			self.object:set_properties({textures = {"air"}, is_visible = false})
		end
		self.owner_item = item
	end
end

local function item_step_player (self)
	-- since the player can turn into any creature at any time, the item must always check the creature settings
	local race = creatures:player_get(self.owner)
	local settings = creatures.player_def[race].custom.creatures_module_items
	local entry = settings and settings.slots[self.number]

	-- if the player race has changed, update attachment position and validity
	if self.owner_race ~= race then
		if entry then
			self.object:set_properties({visual_size = {x = entry.size, y = entry.size}})
			self.object:set_attach(self.owner, entry.bone, entry.pos, entry.rot)
			self.owner_item = ""
			self.enabled = true
		else
			self.object:set_properties({textures = {"air"}, is_visible = false})
			self.object:set_attach(self.owner, nil, {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
			self.owner_item = ""
			self.enabled = false
		end
		self.owner_race = race
	end

	-- return if there is nothing to do
	if not self.enabled then return end

	-- if this entry has an on_step function, only continue if it returns true
	if entry.on_step then
		if not entry.on_step(self) then return end
	end

	-- determine the inventory slot this item represents
	-- the first entry always represents the wielded item
	local item = nil
	if self.number == 1 then
		local num = self.owner:get_wield_index()
		local inv = self.owner:get_inventory()
		local stack = inv:get_stack(entry.inventory, num)
		item = stack:get_name()
	elseif self.number - 1 ~= self.owner:get_wield_index() then
		local num = self.number - 1
		local inv = self.owner:get_inventory()
		local stack = inv:get_stack(entry.inventory, num)
		item = stack:get_name()
	end

	-- if the player item has changed, update visual appearance
	if self.owner_item ~= item then
		if item and item ~= "" then
			self.object:set_properties({textures = {item}, is_visible = true})
		else
			self.object:set_properties({textures = {"air"}, is_visible = false})
		end
		self.owner_item = item
	end
end

minetest.register_entity("creatures_module_items:item", {
	hp_max = 1,
	visual = "wielditem",
	visual_size = {x = 0, y = 0},
	collisionbox = {0, 0, 0, 0, 0, 0},
	textures = {"air"},
	is_visible = false,
	physical = false,

	-- item specific parameters
	enabled = false,
	owner = nil,
	owner_race = "",
	owner_item = "",
	inventory = "",
	number = 0,

	-- functions
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
				item_step_mob(self)
			-- owner is a player
			elseif self.owner:is_player() then
				item_step_player(self)
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

function creatures_module_items:on_activate (self, staticdata, dtime_s)
	local pos = self.object:getpos()
	local ent = self.object:get_luaentity()
	local settings = ent.custom.creatures_module_items
	if not settings then return end

	-- add an item entity for each slot in order
	local count = math.min(#settings.slots, creatures_module_items.count)
	for i = 1, count do
		local obj = minetest.env:add_entity(pos, "creatures_module_items:item")
		local ent = obj:get_luaentity()
		ent.owner = self.object
		ent.number = i
	end
end

function creatures_module_items:player_join (player, dtime)
	local pos = player:getpos()

	-- add an item entity for each slot in order
	-- since the player can turn into any creature at any time, add all possible item entities
	for i = 1, creatures_module_items.count do
		local obj = minetest.env:add_entity(pos, "creatures_module_items:item")
		local ent = obj:get_luaentity()
		ent.owner = player
		ent.number = i
	end
end
