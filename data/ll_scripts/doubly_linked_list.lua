mods.lightweight_doublylinkedlist = {}
mods.lightweight_doublylinkedlist.__index = mods.lightweight_doublylinkedlist

--[[Usage:
    local LwLinkedList = mods.lightweight_doublylinkedlist
    local myList = LwLinkedList.new()
    myList.insert([thing])
    --etc.
--]]


local lwl = mods.lightweight_lua
local LOG_TAG = "lightweight_doublylinkedlist"
local DEBUG_LEVEL = 1 --todo make this global or remove.

function mods.lightweight_doublylinkedlist:new()
    return setmetatable({ head = nil, tail = nil, current = nil, size = 0 }, self)
end

-- Node structure
local function createNode(data, prev, next)
    return { data = data, prev = prev, next = next }
end

-- Private logging function
function mods.lightweight_doublylinkedlist:logCurrent()
    if self.current then
        lwl.logDebug(LOG_TAG, "Current node:"..self.current.data, DEBUG_LEVEL)
    end
end

-- Private method: Generic insertion logic
function mods.lightweight_doublylinkedlist:_insertAt(data, position)
    local newNode = createNode(data, nil, nil)

    if not self.head then
        -- If list is empty, set this as the first node
        self.head, self.tail, self.current = newNode, newNode, newNode
    elseif position == "before" then
        newNode.prev = self.current and self.current.prev or nil
        newNode.next = self.current
        if self.current then
            if self.current.prev then self.current.prev.next = newNode end
            self.current.prev = newNode
        end
        if self.current == self.head then self.head = newNode end
    elseif position == "after" then
        newNode.next = self.current and self.current.next or nil
        newNode.prev = self.current
        if self.current then
            if self.current.next then self.current.next.prev = newNode end
            self.current.next = newNode
        end
        if self.current == self.tail then self.tail = newNode end
    end

    self.size = self.size + 1
    self.current = newNode -- Update current node to new insertion
    self:logCurrent() -- Log new current node
end

-- Public insert methods.  Inserts a node and moves to it.
function mods.lightweight_doublylinkedlist:insertBefore(data)
    self:_insertAt(data, "before")
end

function mods.lightweight_doublylinkedlist:insert(data)
    self:_insertAt(data, "after")
end

-- Insert a new node at a specific position, and move to that node
function mods.lightweight_doublylinkedlist:insertAt(data, position)
    local newNode = createNode(data, nil, nil)

    if position <= 1 or not self.head then
        -- Insert at the beginning
        newNode.next = self.head
        if self.head then self.head.prev = newNode end
        self.head = newNode
        if not self.tail then self.tail = newNode end
    else
        local temp = self.head
        local index = 1
        while temp.next and index < position - 1 do
            temp = temp.next
            index = index + 1
        end
        -- Insert at position
        newNode.next = temp.next
        newNode.prev = temp
        if temp.next then temp.next.prev = newNode end
        temp.next = newNode
        if not newNode.next then self.tail = newNode end
    end

    self.current = newNode
    self.size = self.size + 1
    self:logCurrent() -- Log new current node
end

-- Move to the previous node
function mods.lightweight_doublylinkedlist:previous()
    if self.current and self.current.prev then
        self.current = self.current.prev
        self:logCurrent()
        return self.current
    end
    return nil
end

-- Move to the next node
function mods.lightweight_doublylinkedlist:next()
    if self.current and self.current.next then
        self.current = self.current.next
        self:logCurrent()
        return self.current
    end
    return nil
end

-- Remove the current node and move to the next or previous node if next does not exist, and no node if now empty.
function mods.lightweight_doublylinkedlist:remove()
    if not self.current then return nil end
    local nextNode = self.current.next
    local prevNode = self.current.prev

    if prevNode then
        prevNode.next = nextNode
    else
        self.head = nextNode -- Update head if removing first node
    end

    if nextNode then
        nextNode.prev = prevNode
    else
        self.tail = prevNode -- Update tail if removing last node
    end

    self.size = self.size - 1
    self.current = nextNode or prevNode
    self:logCurrent() -- Log new current node
    return self.current
end

-- Returns the length
function mods.lightweight_doublylinkedlist:length()
    return self.size
end

-- Print the list as a comma-separated string
function mods.lightweight_doublylinkedlist:printList()
    local temp = self.head
    local result = {}

    while temp do
        table.insert(result, tostring(temp.data))
        temp = temp.next
    end

    print(table.concat(result, ", "))
end

-- Example usage:
local list = mods.lightweight_doublylinkedlist:new()
list:printList()
list:insert("A") -- Insert at start
list:insertAt("B", 2) -- Insert at position 2
list:insertAt("C", 3) -- Insert at position 3
list:insert("D") -- Insert after current
list:previous() -- Move to previous node
list:insertBefore("E") -- Insert before current
list:remove() -- Remove current node
list:printList() -- Output: A, E, C, D
print("List length:", list:length())
list:remove() -- Remove current node
list:remove() -- Remove current node
print("List length:", list:length())
list:remove() -- Remove current node
print("List length:", list:length())
list:remove() -- Remove current node
print("List length:", list:length())
list:remove() -- Remove current node
print("List length:", list:length())

--LLM TDD

--First describe the problem space for yourself and describe the tests in your own words.  Give this to the AI and ask it to generate these tests, and also the code that satisfies them.
--See if that works.

-- Test Suite for mods.lightweight_doublylinkedlist

function runTests()
    local function assertEqual(actual, expected, message)
        if actual ~= expected then
            error("Test failed: " .. message .. " (Expected: " .. tostring(expected) .. ", Got: " .. tostring(actual) .. ")")
        end
    end

    local function assertNil(actual, message)
        if actual ~= nil then
            error("Test failed: " .. message .. " (Expected: nil, Got: " .. tostring(actual) .. ")")
        end
    end

    local function assertNotNil(actual, message)
        if actual == nil then
            error("Test failed: " .. message .. " (Expected non-nil value)")
        end
    end

    print("Running tests...")

    -- Create a new list
    local list = mods.lightweight_doublylinkedlist:new()

    -- EDGE CASES
    print("Testing edge cases...")

    -- Operations on an empty list
    assertNil(list:previous(), "Previous should return nil on an empty list")
    assertNil(list:next(), "Next should return nil on an empty list")
    assertNil(list:remove(), "Remove should return nil on an empty list")
    assertEqual(list:length(), 0, "Empty list should have length 0")

    -- Inserting into an empty list should set head, tail, and current
    list:insertAt("A", 1)
    assertEqual(list:length(), 1, "Length should be 1 after inserting into empty list")
    assertEqual(list.current.data, "A", "Current should be 'A' after inserting into empty list")
    assertEqual(list.head.data, "A", "Head should be 'A' after inserting into empty list")
    assertEqual(list.tail.data, "A", "Tail should be 'A' after inserting into empty list")

    -- Out of bounds insert (negative index should default to first position)
    list:insertAt("B", -5)
    list:printList()
    assertEqual(list:length(), 2, "Length should be 2 after inserting at negative index")
    assertEqual(list.head.data, "B", "Head should be 'B' after inserting at negative index")
    assertEqual(list.current.data, "B", "Current should be 'B' after inserting at negative index")

    -- Out of bounds insert (large index should append)
    list:insertAt("C", 100)
    assertEqual(list:length(), 3, "Length should be 3 after inserting at large index")
    assertEqual(list.tail.data, "C", "Tail should be 'C' after inserting at large index")
    assertEqual(list.current.data, "C", "Current should be 'C' after inserting at large index")

    -- NORMAL CASES
    print("Testing normal cases...")

    -- Insert at specific position
    list:insertAt("D", 2) -- Insert at position 2 (between B and C)
    assertEqual(list:length(), 4, "Length should be 4 after inserting at position 2")
    assertEqual(list.current.data, "D", "Current should be 'D' after inserting at position 2")

    -- Insert before current
    list:insertBefore("E")
    assertEqual(list:length(), 5, "Length should be 5 after insertBefore")
    assertEqual(list.current.data, "E", "Current should be 'E' after insertBefore")
    assertEqual(list.current.next.data, "D", "Next node should be 'D' after insertBefore")

    -- Insert after current
    list:insert("F")
    assertEqual(list:length(), 6, "Length should be 6 after insertAfter")
    assertEqual(list.current.data, "F", "Current should be 'F' after insertAfter")
    assertEqual(list.current.prev.data, "E", "Previous node should be 'E' after insertAfter")

    -- Moving through the list
    list:previous()
    assertEqual(list.current.data, "E", "Current should be 'E' after moving previous")

    list:next()
    list:next()
    assertEqual(list.current.data, "D", "Current should be 'D' after moving next twice")

    -- Removing a node
    list:remove()
    list:printList()
    assertEqual(list:length(), 5, "Length should be 5 after remove")
    assertNotNil(list.current, "Current should not be nil after remove")
    assertEqual(list.current.data, "A", "Current should be 'A' after remove, as this was next after D")

    -- Removing until the list is empty
    list:remove()
    list:remove()
    list:remove()
    list:remove()
    assertEqual(list:length(), 1, "List should have 1 element left")
    assertNotNil(list.current, "Current should still be valid")
    assertEqual(list.current.data, "B", "Current should be 'B' after removing all but one node.")
    list:remove()
    assertEqual(list:length(), 0, "List should be empty after removing last element")
    assertNil(list.current, "Current should be nil after removing last element")
    list:remove()
    assertEqual(list:length(), 0, "Removing from empty list should still be zero length")
    assertNil(list.current, "Current should be nil after removing from empty list")

    -- SIDE EFFECTS
    print("Testing side effects...")

    -- Inserting should update current
    list:insertAt("X", 1)
    assertEqual(list.current.data, "X", "Current should be 'X' after inserting into an empty list")

    list:insertAt("Y", 2)
    assertEqual(list.current.data, "Y", "Current should be 'Y' after inserting at position 2")

    list:insertBefore("Z")
    assertEqual(list.current.data, "Z", "Current should be 'Z' after insertBefore")

    list:insert("W")
    assertEqual(list.current.data, "W", "Current should be 'W' after insertAfter")

    print("All tests passed!")
end

-- Run the test suite
runTests()





