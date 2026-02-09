

local Node = {}
Node.__index = Node

function lwui.newNode(props)
    local n = {
        -- geometry (local to parent)
        x = props.x or 0,
        y = props.y or 0,
        width  = props.width  or 0,
        height = props.height or 0,

        -- children
        children = {},
        parent = nil,

        -- rendering
        render = props.render,           -- function(node)
        visible = props.visible or function() return true end,
        clip = props.clip or false,       -- stencil/scissor hint

        -- interaction
        hovered = false,
        pressed = false,
        onClick = nil,
        onRelease = nil,

        -- layout / behavior
        sizeToContent = props.sizeToContent ~= false,
        layout = props.layout,            -- "horizontal" | "vertical" | nil
        reverse = props.reverse or false,

        -- scrolling
        scrollX = 0,
        scrollY = 0,

        -- bookkeeping
        layer = nil,
        dead = false,
    }

    return setmetatable(n, Node)
end


function Node:add(child)
    child:remove() -- detach from any previous parent/layer
    child.parent = self
    table.insert(self.children, child)
end


function Node:remove()
    if self.parent then
        local siblings = self.parent.children
        for i = #siblings, 1, -1 do
            if siblings[i] == self then
                table.remove(siblings, i)
                break
            end
        end
        self.parent = nil

    elseif self.layer then
        local list = lwui.layers[self.layer]
        for i = #list, 1, -1 do
            if list[i] == self then
                table.remove(list, i)
                break
            end
        end
        self.layer = nil
    end
end

function Node:destroy()
    for i = #self.children, 1, -1 do
        self.children[i]:destroy()
    end
    self.children = {}
    self:remove()
    self.dead = true
end

function Node:getAbsolutePos()
    local x, y = self.x - self.scrollX, self.y - self.scrollY
    if self.parent then
        local px, py = self.parent:getAbsolutePos()
        return px + x, py + y
    end
    return x, y
end

function Node:hitTest(mx, my)
    if not self:visible() then return nil end

    -- children first, topmost wins
    for i = #self.children, 1, -1 do
        local hit = self.children[i]:hitTest(mx, my)
        if hit then return hit end
    end

    local ax, ay = self:getAbsolutePos()
    if mx >= ax and mx <= ax + self.width
       and my >= ay and my <= ay + self.height then
        return self
    end

    return nil
end

function lwui.resolveHover(mx, my)
    for _, layerName in ipairs({"overlay", "ui", "background"}) do
        local list = lwui.layers[layerName]
        for i = #list, 1, -1 do
            local hit = list[i]:hitTest(mx, my)
            if hit then return hit end
        end
    end
end

function Node:draw()
    if not self:visible() then return end

    -- optional clipping
    if self.clip then
        -- push stencil / scissor here
    end

    if self.render then
        self.render(self)
    end

    for _, child in ipairs(self.children) do
        child:draw()
    end

    if self.clip then
        -- pop stencil / scissor
    end
end



function Node:markLayoutDirty()
    self.layoutDirty = true
    if self.parent then self.parent:markLayoutDirty() end
end

function Node:applyLayoutIfNeeded()
    if not self.layoutDirty then return end
    self:applyLayout()
    self.layoutDirty = false
end