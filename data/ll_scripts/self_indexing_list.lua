if (not mods) then mods = {} end
mods.lightweight_self_indexing_list = {}
local lwsil = mods.lightweight_self_indexing_list

lwsil.SelfIndexingList = {}
lwsil.SelfIndexingList.__index = lwsil.SelfIndexingList

function lwsil.SelfIndexingList:new()
	local list = {
		items = {},
		length = 0
	}
	setmetatable(list, self)
	return list
end

-- Append a new item
function lwsil.SelfIndexingList:append(item)
	self.length = self.length + 1
	item._index = self.length
	self.items[self.length] = item
end

-- Remove an item by index
function lwsil.SelfIndexingList:remove(index)
	if index < 1 or index > self.length then return end

	table.remove(self.items, index)
	self.length = self.length - 1

	-- Reassign indices
	for i = index, self.length do
		self.items[i]._index = i
	end
end

-- Get item by index
function lwsil.SelfIndexingList:get(index)
	return self.items[index]
end

-- Get item by index
function lwsil.SelfIndexingList:size()
	return self.length
end

-- Print all items' indices
function lwsil.SelfIndexingList:print()
	for i, item in ipairs(self.items) do
		print(i, "=>", item._index)
	end
end