--[[
Usage:

local lwui = mods.lightweight_user_interface
local myTextBox = lwui.buildFixedTextBox(660, 348, 220, 35, , 18)
lwui.addTopLevelObject(mDescriptionHeader, "SHIP_SPARKS")

--todo swap to spriteRenderFunction with the image of your choice.
local myButton = lwui.buildButton(300, 400, 15, 15, lwui.alwaysOnVisibilityFunction, lwui.solidRectRenderFunction(Graphics.GL_Color(.2, .81, .8, 1)), function() print("button clicked!") end, function() print("button released.") end)
lwui.addTopLevelObject(myButton, "SHIP_SPARKS")

Objects just render
Buttons can be hovered and clicked
    Inventory buttons are made to hold Items
Text boxes render text
    Dynamic ones expand and use the font size specified
    Fixed size ones try to render text at the specified size, but will shrink it to fit the box.
Items have various methods you can use to give them properties.
Containers can hold other objects by calling container.addObject(object) and/or passing them in the constructor.
    Scroll bars are containers that can deal with things larger than themselves
    Directional containers are useful for building evenly spaced layouts and dynamically adding and removing items for use with Scroll Bars.
    
lwui.helpBarContainer is a vertical container you can add 11x11 buttons to which will people can press to get more information about your addon.
use --lwui.addHelpButton(helpButton).  The button must be constructed with lwui.buildButton, and must have a .lwuiHelpText field you fill out.

Example:
local function NOOP() end
local mHelpButton = lwui.buildButton(1, 0, 11, 11, lwui.alwaysOnVisibilityFunction, lwui.solidRectRenderFunction(Graphics.GL_Color(.2, .81, .8, 1)), NOOP, NOOP)
mHelpButton.lwuiHelpText = "your text here"
lwui.addHelpButton(mHelpButton)
--]]

if (not mods) then mods = {} end
local lwl = mods.lightweight_lua
mods.lightweight_user_interface = lwl.setIfNil(mods.lightweight_user_interface, {})
local lwui = mods.lightweight_user_interface

--[[

TODO:

Containers that don't resize themselves are broken, and have the wrong box size.
    I can't reproduce this anymore, revisit if it happens again.

Does mean I need a way to stretch an image.  I wonder if GL will just do that for me.

Radio buttons maybe?  You can do this yourself, but I'll see if it seems worth putting here when I build it.

For usage examples, please refer to Grimdark Expy.

Functions are built to deal with objects (renderable).
Objects are tables, so you can add fields to them as you see fit.

Internal fields:
getPos() --Call to get a table {x=x, y=y}.  This is the absolute position of the object on screen, and what you should probably be using if you want to interact with an object.

Object {x,y,getPos,height,width,visibilityFunction,renderFunction} --x and y are relative to the containing object, or the global UI if top level.
--Button {onClick, enabledFunction} --enabled tells the button if it should work or not, some buttons have different render states based on this as well.
--Container {Objects} (Abstract, if that makes any sense.)
----Scroll Bar {internals={scrollUpButton, scrollDown, scrollBar, scrollCursor}} (barWidth?  maybe I'll make a scroll bar graphics template, and include the base package with this.)
----Button Group {padding?}

special
scroll buttons must be square.  That's the law, it will throw you an error otherwise. --TODO implement
--ScrollBarGraphicAssets(scrollUp, nubImage, renderScrollButton)

Another law is that in order to inherit from something, you have to call its build function.
So if you call buildObject, you are a class of object, and so on.
--]]
local TAG = "LW UI"
local function NOOP() end
local function GEN_NOOP() return NOOP end
local MIN_FONT_SIZE = 5
local FULL_SCREEN_MASK
local function FULL_SCREEN_MASK_FUNCTION() return FULL_SCREEN_MASK end

local GL_WHITE = Graphics.GL_Color(1, 1, 1, 1)
local GL_BLACK = Graphics.GL_Color(0, 0, 0, 1)
local GL_TRAVELLER_GRAY = Graphics.GL_Color(160/255, 162/255, 171/255, 1)
local GL_TRAVELLER_BLUE = Graphics.GL_Color(58/255, 127/255, 255/255, 1)

local RENDER_LAYERS = { --todo maybe I should actually have the ship layers be relative to their respective ships...
    MAIN_MENU = {},
    GUI_CONTAINER = {},
    LAYER_BACKGROUND = {},
    LAYER_FOREGROUND = {},
    LAYER_ASTEROIDS = {},
    LAYER_PLAYER = {},
    SHIP = {},
    SHIP_MANAGER = {},
    SHIP_JUMP = {},
    SHIP_HULL = {},
    SHIP_ENGINES = {},
    SHIP_FLOOR = {},
    SHIP_BREACHES = {},
    SHIP_SPARKS = {},
    LAYER_FRONT = {},
    SPACE_STATUS = {},
    TABBED_WINDOW = {},
    MOUSE_CONTROL = {}
}

lwui.classNames = {
    OBJECT = "object",
    BUTTON = "button",
    HORIZONTAL_CONTAINER = "horizontalContainer",
    VERTICAL_CONTAINER = "verticalContainer",
    SCROLL_CONTAINER = "scrollContainer", --todo can I safely rename this?
    ITEM = "item",
    INVENTORY_BUTTON = "inventoryButton",
    TEXT_BOX = "textBox",
    FIXED_TEXT_BOX = "fixedTextBox",
    DYNAMIC_TEXT_BOX = "dynamicTextBox",
    TOGGLE_BUTTON = "toggleButton"
}
local classNames = lwui.classNames

local mTopLevelRenderLists = {}
local mLayersPerTick
lwui.mHoveredObject = nil --todo this means you need to update your CEL in lockstep.  todo change to mHoveredObject
local mHoveredScrollContainer = nil
local mScrollContainerHoverTimer = 0 --in layers
lwui.mClickedObject = nil --mouseUp will be called on this. --todo rename
local mItemList = {}
local mLayersWithoutHover = 0

function lwui.isWithinMask(mousePos, mask)
    --[[print("within mask? ", mousePos.x >= mask.getPos().x and mousePos.x <= mask.getPos().x + mask.width and
           mousePos.y >= mask.getPos().y and mousePos.y <= mask.getPos().y + mask.height
           , mousePos.x, mousePos.y, mask.getPos().x, mask.getPos().x + mask.width, mask.getPos().y, mask.getPos().y + mask.height)--]]
    return mousePos.x >= mask.getPos().x and mousePos.x <= mask.getPos().x + mask.width and
           mousePos.y >= mask.getPos().y and mousePos.y <= mask.getPos().y + mask.height
end

--Used to register your top level objects so they render themselves / their contents.
function lwui.addTopLevelObject(object, renderLayer)
    for name,_ in pairs(mTopLevelRenderLists) do
        if (name == renderLayer) then
            table.insert(mTopLevelRenderLists[renderLayer], object)
            --print("There are now", #mTopLevelRenderLists[renderLayer], "items in", renderLayer)
            return
        end
    end
    error("Invalid layer name ", renderLayer)
end

--chatgpt created
function lwl.print_function_source(f)
    local info = debug.getinfo(f, "S")

    -- 1. No source available (e.g. C function, stripped bytecode)
    if info.what ~= "Lua" then
        print("No Lua source available for this function.")
        return
    end

    -- 2. Function created with load/loadfile? The source is inside info.source.
    -- If it's from a file, info.source starts with '@'.
    if info.source:sub(1,1) == "@" then
        print("File source")
        local filename = info.source:sub(2)
        local file = io.open(filename, "r")
        if not file then
            print("Could not open file:", filename)
            return
        end
        local lines = {}
        for line in file:lines() do
            table.insert(lines, line)
        end
        file:close()

        print("File source", filename, info.linedefined, info.lastlinedefined)
        -- print only the lines that correspond to this function
        for i = info.linedefined, info.lastlinedefined do
            print(lines[i] or "")
        end
        return
    end

    -- 3. Function created from a string chunk: source *is literally the string*
    -- and includes the leading '=' or actual source text.
    if info.source:sub(1,1) == "=" then
        print("String source ", info.source:sub(2))
        return
    end

    -- 4. Raw chunk from load("...") — entire source is inside info.source
    print("Raw source", info.source)
end

--[[
Objects must be registered somehow with the topLevelRenderList to appear, be visible, and thus be interacted with.
--Objects are basic things that are visible, but have no other features.
--All items constructed from this point down are objects.
--Render functions for pure objects should return false/not have a return value or it will break the button logic.
--
x: The relative x position of the object to its container.
y: The relative y position of the object to its container.
width: Horizontal size
height: Vertical size
visibilityFunction: lets you have further control over when you want things to show up, like in specific menu tabs.
renderFunction: 
--]]
---Creates a generic lwui object.  This is a rectangle that can be given lots of properties.  It renders according to the space it is in.
---Actually... Ugh.  lwui has no concept of space right now, so anything on the ship layers will render on both ships.
---I guess I need to fix that before someone (me) runs into that.  I had only been using lwui for global stuff like player interfaces.
---
---
---Properties:
--- focusable: False by default. Determines if the object can be hovered.
---     If multiple items that can be hovered are in a stack, only the top one will be hovered.
--- 
--- setOnClick(onClickFunction) Call this to give the object an onClick function which takes three arguments:
---     the object, the x coordinate of the mouse click, and the y coordinate of the mouse click.
---     Also implicitly sets focusable to true.
--- 
--- setOnRelease(onReleaseFunction) Call this to give the object an onClick function which takes three arguments:
---     the object, the x coordinate of the mouse click, and the y coordinate of the mouse click.
---     Also implicitly sets focusable to true
--- 
--- className: Each kind of object has its own name to help differentiate them when debugging.
---
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@return table the constructed object
function lwui.buildObject(x, y, width, height, visibilityFunction, renderFunction)
    local object = {}
    object.focusable = false

    local function renderObject(mask)
        --print("should render? ", visibilityFunction())
        if not object.visibilityFunction then
            lwl.logError(TAG, "vis func for object "..object.getPos().x..", "..object.getPos().y.." is nil!")
            return true
        end
        if object.visibilityFunction() then
            local hovering = false
            if object.focusable then
                local mousePos = Hyperspace.Mouse.position
                local objectMask = object.maskFunction()
                --print("rendering button ", button.getPos().x)
                if lwui.isWithinMask(mousePos, objectMask) then
                    hovering = true
                    -- if not (lwui.mHoveredObject == object) then
                    --     print("button_hovered ", button)
                    -- end
                    lwui.mHoveredObject = object
                end
            end
            local internalHover = lwl.resolveToBoolean(renderFunction(object)) --todo this is a hack for this returning a function, TODO fix this by ensuring we don't return functions here.
            -- if hovering or internalHover then 
            --     print("robject", x, y, internalHover, hovering)
            --     --lwl.print_function_source(thing)
            -- end
            return hovering or internalHover --TODO ensure every render function returns the proper hover values.
        end
    end
    
    local function getPosition()
        if (object.x == nil) then error("x was nil for"..lwl.dumpObject(object)) end
        if (object.y == nil) then error("y was nil for"..lwl.dumpObject(object)) end
        return {x=object.x, y=object.y}
    end
    
    local function maskFunctionNoOp() --mask has only x, y, width, height; can't be concave with current settings.
        return object
    end
    
    local function setMaskFunction(maskFunc)
        object.maskFunction = maskFunc
    end

    object.setOnClick = function(onClickFunction)
        object.focusable = true
        object.onClick = function(self, x1, y1)
            --print("Clicked", object)
            if object.visibilityFunction then
                onClickFunction(self, x1, y1) --can't be button b/c that stack overflows.
            end
        end
    end

    object.setOnRelease = function(onReleaseFunction)
        object.focusable = true
        object.onRelease = function(self, x1, y1)
            --print("Released", object)
            if object.visibilityFunction then
                onReleaseFunction(self, x1, y1) --can't be button b/c that stack overflows.
            end
        end
    end
    
    object.x = x
    object.y = y
    object.getPos = getPosition
    object.width = width
    object.height = height
    object.visibilityFunction = visibilityFunction
    object.renderFunction = renderObject
    object.setMaskFunction = setMaskFunction
    object.maskFunction = maskFunctionNoOp --call this each frame to get the mask to pass to render func.
    object.className = classNames.OBJECT
    object.onClick = NOOP
    object.onRelease = NOOP
    -- print("\nCreating object", lwl.dumpObject(object))
    return object
end

--onClick(x, y): args being passed are global position of the cursor when click occurs.
---A button is an object that can be clicked and hovered by default.
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@param onClick function|nil Optional function called when button is clicked. Takes three arguments: the object, the x coordinate
---@    of the mouse click, and the y coordinate of the mouse click.
---@param onRelease function|nil Optional function called when the mouse is released after clicking this button.
---@    Takes three arguments: the object, the x coordinate of the mouse click, and the y coordinate of the mouse click.
---@return table the button
function lwui.buildButton(x, y, width, height, visibilityFunction, renderFunction, onClick, onRelease)--todo order changed, update calls.
    local button
    
    local function renderButton(mask)
        local hovered = renderFunction(mask)
        -- if hovering then
        -- print("rendering button", x, y, hovered)
        -- end
        return hovered
    end

    button = lwui.buildObject(x, y, width, height, visibilityFunction, renderButton)
    
    if onClick then
        button.setOnClick(onClick)
    end
    if onRelease then
        button.setOnRelease(onRelease)
    end
    button.className = classNames.BUTTON
    -- print("\nCreating button", lwl.dumpObject(button))
    return button
end

--todo this can't dyanmically update based on the values of object1 and object2?  I mean it should, that's what the mask function does.
--a mask is an object, so this also returns an function that returns an object.
local function combineMasks(object1, object2)
    local maskFunction1 = object1.maskFunction --in the base case, these masks are the objects themselves, and will have all properties of an object.
    local maskFunction2 = object2.maskFunction
    
    local function combinedMaskFunction()
        local mask1 = maskFunction1() --in the base case, these masks are the objects themselves, and will have all properties of an object.
        local mask2 = maskFunction2()
        local x1 = mask1.getPos().x
        local y1 = mask1.getPos().y
        local x2 = mask2.getPos().x
        local y2 = mask2.getPos().y
        local x = math.max(x1, x2)
        local y = math.max(y1, y2)
        local width = math.max(0, math.min(x1 + mask1.width, x2 + mask2.width) - x)
        local height = math.max(0, math.min(y1 + mask1.height, y2 + mask2.height) - y)
        --print("combinedMask: ", x, y, width, height, " xs ", x1, x2, " ys ", y1 , y2)
        local combinedMask = lwui.buildObject(x, y, width, height, NOOP, NOOP)
        return combinedMask
    end
    
    return combinedMaskFunction
end

--Once a scroll bar is created, adding things to it means adding things to the content container.
--This requires a dynamic container update method.  Probably worth having.
--.
--[[
addObject(object): call this if you need to add something to the container after creation.
renderOutsideBounds: if true, objects will render even if out of bounds of the container.
sizeToContent: if true, the container will dynamically adjust itself to the smallest sizes that hold all of its contents.
--]]

---Constructs a container, an object that can hold other objects.
---
---Properties:
--- addObject(object) Puts this object inside this container.  It will render relative to its immediate container.
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@param objects table of lwui objects (all elements are objects)
---@param renderOutsideBounds boolean if false, will only render contents strictly inside the container's rectangle.
---@param sizeToContent boolean if true, will dynamically resize the container to fit its contents.
---@return table the container
function lwui.buildContainer(x, y, width, height, visibilityFunction, renderFunction, objects, renderOutsideBounds, sizeToContent)
    local container
    --Append container rendering behavior to whatever function the user wants (if any) to show up as the container's background.
    local function renderContainer(mask)
        local hovered = renderFunction(container)
        local hovering = false
        --todo Render contents, shifting window to cut off everything outside it., setting hovering to true as in the tab render
        --This will obfuscate the fact that buttons are wonky near container edges, so I should TODO go back and fix this.
        
        local i = 1
        for _, object in ipairs(container.objects) do
            if (container.sizeToContent) then
                container.height = math.max(container.height, object.y + object.height)
                container.width = math.max(container.width, object.x + object.width)
            end
            --print("render object at ", object.getPos().x, ", ", object.getPos().y)
            if object.renderFunction(object) then
                hovering = true
            end
            i = i + 1
        end
        -- if hovering then
        -- print("rendering container", x, y, hovering)
        -- end
        return hovering or hovered
    end
    
    --This should be called once the thing is created with the default maskFunction
    --todo should this logic be moved into addObject?
    --Right now it won't be called on things added with addObject()
    local function setMaskFunction(maskFunc)
        --if container.renderOutsideBounds then return end
        container.maskFunction = maskFunc
        for _, object in ipairs(container.objects) do
            object.setMaskFunction(combineMasks(container, object))
        end
    end
    
    local function addObject(object)
        if object == nil then
            print("Container at ", container.x, container.y, "Registered nil object!") --TODO add this back
            return
        end
        -- print("addobject", object)
        -- if object then
        --     print("addobject ", lwl.dumpObject(object, 2))
        -- end
        if not container.renderOutsideBounds then
            object.setMaskFunction(combineMasks(container, object))
        end
        --adjust getPos
        local oldGetPos = object.getPos
        local function containedGetPos()
            local newX = container.getPos().x + oldGetPos().x
            local newY = container.getPos().y + oldGetPos().y
            --print("containedGetPos newX ", newX, "newy ", newY, " getPos function ", object.getPos)
            return {x=newX, y=newY}
        end
        object.getPos = containedGetPos
        --adjust visibilityFunction
        --object is only visible if partially inside container.
        local oldVisibilityFunction = object.visibilityFunction
        local function containedVisibilityFunction()--TODO if this breaks, it's probably because I made this local.
            local retVal = false
            if container.renderOutsideBounds then return true end
            if ((object.getPos().x > container.getPos().x + container.width) or (object.getPos().x + object.width < container.getPos().x) or
                (object.getPos().y > container.getPos().y + container.height) or (object.getPos().y + object.height < container.getPos().y)) then
                retVal = false
            else
                if (not oldVisibilityFunction) then
                    lwl.logError(TAG, "vis func for contained object "..object.getPos().x..", "..object.getPos().y.." is nil!")
                    return true
                end
                retVal = oldVisibilityFunction()
            end
            --print("Called containing vis function ", retVal)
            return retVal
        end
        object.visibilityFunction = containedVisibilityFunction
        table.insert(container.objects, object)
    end

    container = lwui.buildObject(x, y, width, height, visibilityFunction, renderContainer)
    container.objects = {}
    container.addObject = addObject
    --pass the mask to contained objects
    container.renderOutsideBounds = renderOutsideBounds
    container.sizeToContent = sizeToContent
    container.setMaskFunction = setMaskFunction
    if renderOutsideBounds then
        container.maskFunction = FULL_SCREEN_MASK_FUNCTION
    end
    --container.setMaskFunction(container.maskFunction)--todo comment out
    for _, object in ipairs(objects) do
        addObject(object)
    end
    return container
end

--and horizontal.  With this, my suite of UI calls will be complete
--As this is meant for organizing things, you probably want renderOutsideBounds to be true
--This type of container does not respect its contents x and y position, and controls them itself.
--You can't create this type of container with contents in the constructor, they must be added later with addObject() --TODO also this new style fixes this!
--Maybe don't use dynamicHeightTextBoxes inside positional containers, they will bully your other items.
--todo might be an issue where sizeToContent=false causes issues
---Constructs a container that forces its items to be in a column, starting from the top.
---
---Properties:
--- addObject(object) Puts this object inside this container.  This container will control where it renders.
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@param objects table of lwui objects (all elements are objects)
---@param renderOutsideBounds boolean if false, will only render contents strictly inside the container's rectangle.
---@param sizeToContent boolean if true, will dynamically resize the container to fit its contents.
---@param padding any The space between items in the container.
---@return table the container
function lwui.buildVerticalContainer(x, y, width, height, visibilityFunction, renderFunction, objects, renderOutsideBounds, sizeToContent, padding)
    local container
    local function verticalSnapRender(maskFunction)
        local hovering = renderFunction(maskFunction)
        local maxPos = 0
        for i=1,#container.objects do
            local object = container.objects[i]
            object.y = maxPos
            maxPos = maxPos + container.padding + object.height
        end
        -- if hovering then
        -- print("Rendering vcontainer", hovering)
        -- end
        return hovering
    end
    container = lwui.buildContainer(x, y, width, height, visibilityFunction, verticalSnapRender, objects, renderOutsideBounds, sizeToContent)
    container.padding = padding
    container.className = classNames.VERTICAL_CONTAINER
    return container
end

---Constructs a container that forces its items to be in a row, starting from the left.
---
---Properties:
--- addObject(object) Puts this object inside this container.  This container will control where it renders.
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@param objects table of lwui objects (all elements are objects)
---@param renderOutsideBounds boolean if false, will only render contents strictly inside the container's rectangle.
---@param sizeToContent boolean if true, will dynamically resize the container to fit its contents.
---@param padding any The space between items in the container.
---@return table the container
function lwui.buildHorizontalContainer(x, y, width, height, visibilityFunction, renderFunction, objects, renderOutsideBounds, sizeToContent, padding)
    local container
    local function horizontalSnapRender(maskFunction)
        local hovering = renderFunction(maskFunction)
        local maxPos = 0
        for i=1,#container.objects do
            local object = container.objects[i]
            object.x = maxPos
            maxPos = maxPos + container.padding + object.width
        end
        -- if hovering then
        -- print("Rendering hcontainer", hovering)
        -- end
        return hovering
    end
    container = lwui.buildContainer(x, y, width, height, visibilityFunction, horizontalSnapRender, objects, renderOutsideBounds, sizeToContent)
    container.padding = padding
    container.className = classNames.HORIZONTAL_CONTAINER
    return container
end

--scroll bars are a two-leveled container.  This one goes up and down.
--container
----scroll buttons
----scroll bar
----scroll nub
----content (This is an object you pass in to the scroll bar, it will be cut off horiz if it's too large.)
--Content is a single item with a y coordinate of 0. It can have variable size, and can be longer than the scroll container, but not wider.
--scroll bars always grow to fit their content, if you want one that doesn't, ping me.
--NOTE: the contained elements of the scroll bar are refered to statically here, but I don't see a reason why they would be replaced, so I'm leaving it.
---Constructs a scrollable container.  You usually want to put a verticalContainer inside as the only object, and
--- then put other things inside that.
---
---Properties:
--- addObject(object) Puts this object inside this container.  This container will control where it renders.
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param content table The contents of the scroll bar.  This cannot be changed after initialization, so you probably want it to be a conteiner.
---@param scrollBarSkin table created with lwui.constructScrollBarSkin.  defaultScrollBarSkin is the usual window style.
---@return table
function lwui.buildVerticalScrollContainer(x, y, width, height, visibilityFunction, content, scrollBarSkin) --TODO scroll bars should basically always have containers inside them.  Maybe do that by default.  A container of the same direction as the bar.
    local barWidth = scrollBarSkin.barWidth
    local scrollIncrement = 30 --seems fine
    --scrollValue is absolute position of the scroll bar.
    local scrollContainer
    local contentContainer
    local scrollBar
    local scrollUpButton
    local scrollDownButton
    local scrollNub
    local function scrollUp()
        scrollContainer.scrollValue = scrollContainer.scrollValue - scrollIncrement
    end
    local function scrollDown()
        scrollContainer.scrollValue = scrollContainer.scrollValue + scrollIncrement
    end
    
    local function nubClicked() --Don't use the values passed here, they break when resizing the window.  Use the one Hyperspace gives you.
        local mousePos = Hyperspace.Mouse.position
        scrollNub.mouseTracking = true
        scrollNub.mouseOffset = mousePos.y - scrollNub.getPos().y
        --print("mouse offset: ", mousePos.y - scrollNub.getPos().y, " mousePos ", mousePos.y, " scrollNub ", scrollNub.getPos().y)
    end
    local function nubReleased()
        scrollNub.mouseTracking = false
    end
    
    local function nubMinPos()
        return barWidth
    end
        
    local function nubMaxPos()
        return math.max(nubMinPos(), scrollContainer.height - (barWidth + scrollNub.height))
    end
    
    local function minWindowScroll()
        return 0
    end
    
    local function maxWindowScroll()
        return math.max(minWindowScroll(), content.height - contentContainer.height)
    end
    
    --TODO test scroll bar with too small thing inside.
    --todo I don't think this math is right...  Check that scroll makes things do right numbers.
    local function scrollToNub(scrollValue)
        return nubMinPos() + ((scrollValue - minWindowScroll()) / math.max(1, (maxWindowScroll() - minWindowScroll())) * (nubMaxPos() - nubMinPos()))
    end
    
    local function nubToScroll(nubPosition)
        return minWindowScroll() + ((nubPosition - nubMinPos()) / math.max(1, (nubMaxPos() - nubMinPos())) * (maxWindowScroll() - minWindowScroll()))
    end
    
    scrollBar = lwui.buildObject(width - barWidth, barWidth, barWidth, height - (barWidth * 2), visibilityFunction,
        scrollBarSkin.barRender)
    --TODO disable buttons if scrolling is impossible?
    
    scrollUpButton = lwui.buildButton(width - barWidth, 0, barWidth, barWidth, visibilityFunction, --TODO are these backwards?
        scrollBarSkin.upButtonRender, scrollUp, NOOP)
    scrollDownButton = lwui.buildButton(width - barWidth, height - barWidth, barWidth, barWidth, visibilityFunction,
        scrollBarSkin.downButtonRender, scrollDown, NOOP)--TODO fix
    scrollNub = lwui.buildButton(width - barWidth, barWidth, barWidth, barWidth, visibilityFunction,
        scrollBarSkin.nubRender, nubClicked, nubReleased)
    scrollNub.mouseTracking = false
    
    --todo nub should change size based on scrollDelta, clamped to barWidth and  contentContainer.height - (barWidth * 2)
    local function renderContent()
        local mousePos = Hyperspace.Mouse.position
        if lwui.isWithinMask(mousePos, scrollContainer.maskFunction()) then
            mHoveredScrollContainer = scrollContainer
            mScrollContainerHoverTimer = 0
        end
        
        local scrollWindowRange = maxWindowScroll() - minWindowScroll()
        scrollContainer.scrollWindowRange = scrollWindowRange
        --scrollbar slider size
        local maxNubSize = contentContainer.height - (barWidth * 2)
        local nubSize = 50 * maxNubSize / math.max(1, scrollWindowRange)
        scrollNub.height = math.max(10, math.min(maxNubSize, nubSize)) --clamp to container
        
        if (scrollNub.mouseTracking) then
            scrollNub.y = mousePos.y - scrollContainer.y - scrollNub.mouseOffset
            scrollContainer.scrollValue = nubToScroll(scrollNub.y)
        end
        
        scrollContainer.scrollValue = math.max(minWindowScroll(), math.min(maxWindowScroll(), scrollContainer.scrollValue))
        scrollNub.y = scrollToNub(scrollContainer.scrollValue)
        
        content.y = -scrollContainer.scrollValue --todo does this size the scroll bar correctly?
        --print("Rendering content level")
    end
    
    --todo decide about scroll bar backgrounds
    --TODO I should put the vertical container inside the scroll bar so you don't have to keep making it yourself.
    contentContainer = lwui.buildContainer(0, 0, width - barWidth, height, visibilityFunction, renderContent, {content}, false, false)
    scrollContainer = lwui.buildContainer(x, y, width, height, visibilityFunction, scrollBarSkin.backgroundRender,
        {contentContainer, scrollBar, scrollUpButton, scrollDownButton, scrollNub}, false, false)
    scrollContainer.scrollValue = barWidth
    scrollContainer.scrollUp = scrollUp
    scrollContainer.scrollDown = scrollDown
    scrollContainer.contentContainer = contentContainer
    scrollNub.scrollContainer = scrollContainer
    scrollContainer.className = classNames.SCROLL_CONTAINER
    scrollContainer.invertScroll = false
    return scrollContainer
end

--[[
Items are tables with the following properties

itemType: describes what kind of thing the item is, used for determing which inventory buttons can hold which kinds of items. (type is a reserved word)
name: what exactly you have stored in that slot.
renderFunction: hopefully a png that's the same size as their button.
--]]
--[[
    onCreate(self)
        --set up variables specific to this object's implementation.  Check that this is actually a good way of doing this, vs decoupling the object instance from the logic it uses
        --That version would involve each crewmem looking up their equipped items in the persisted values, and is probably better as a first guess at what a good model looks like.
        If it isn't, we can just combine the objects.
    end
--]]
--visibility function inherited from the button they're attached to.
--containingButton is the inventoryButton that holds this item.  render won't be called if this is nil as said button is the thing that calls it.
--onCreate is passed the item, all others are for external use, and it's up to you to define their signatures and what they do.
---Items are objects that exist within inventoryButtons, and as such, do not have their own position.
---They can be dragged between any inventoryButtons defined as being able to hold them.
---
---@param name string the name of the item
---@param itemType string Used in determining which inventoryButtons can hold which items.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@param description string Some information about the object for your players.
---@param onCreate function Called when the object is being created.
---@param onTick function External use. Your UI implementation should call this whenever a given object should be ticking.
---@param onEquip function External use. Your UI implementation should call this whenever a given object is put into an active state.
---@param onRemove function External use. Your UI implementation should call this whenever a given object is removed from an active state.
---@return table the item
function lwui.buildItem(name, itemType, width, height, visibilityFunction, renderFunction, description, onCreate, onTick, onEquip, onRemove)
    local item
    local function itemRender()
        if (item.trackMouse) then
            local mousePos = Hyperspace.Mouse.position
            item.x = mousePos.x - item.mouseOffsetX
            item.y = mousePos.y - item.mouseOffsetY
        else
            item.x = item.containingButton.getPos().x
            item.y = item.containingButton.getPos().y
        end
        local hovering = renderFunction(item)
        -- if hovering then
        -- print("Rendering item", name, hovering)
        -- end
        return hovering
    end
    
    local function itemMask()
        if item.trackMouse then
            return item
        else
            --This works because items only render when attached to an intentoryButton, so it will never be nil here.
            return item.containingButton.maskFunction()
        end
    end
    
    item = lwui.buildObject(0, 0, width, height, visibilityFunction, itemRender)
    item.name = name
    item.itemType = itemType
    item.description = description
    item.onCreate = onCreate
    item.onTick = onTick
    item.onEquip = onEquip
    item.onRemove = onRemove --todo maybe I just always have to check for crewmem to be nil here.
    item.maskFunction = itemMask
    
    item.onCreate(item)
    table.insert(mItemList, item)
    item.className = classNames.ITEM
    return item
end


--I might actually put this in the UI library, it's pretty useful.
--todo is this also a container for the item?  not currently.
--todo add onRemove?
--onItemAddedFunction: called with (button, item) when an item is added to this button successfully.
---Creates a button that can hold items.
---@param name string the name of the inventoryButton
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@param allowedItemsFunction function takes a lwui item, returns a boolean: true if this button can hold the item, and false otherwise.
---@param onItemAddedFunction function takes a button (this button) and an item (the added item), returns nothing.  Called when an item
---@    is successfully added to this button.
---@param onItemRemovedFunction function takes a button (this button) and an item (the removed item), returns nothing.  Called when an item
---@    is successfully removed from this button.
---@return table
function lwui.buildInventoryButton(name, x, y, width, height, visibilityFunction, renderFunction, allowedItemsFunction, onItemAddedFunction, onItemRemovedFunction)
    --todo custom logic has to go somewhere else, as these need to work even when the button isn't rendered.
    local button
    
    local function onClick()
        if (button.item) then
            local buttonItem = button.item
            local mousePos = Hyperspace.Mouse.position
            buttonItem.mouseOffsetY = mousePos.y - buttonItem.getPos().y
            buttonItem.mouseOffsetX = mousePos.x - buttonItem.getPos().x
            buttonItem.trackMouse = true
        end
    end
    
    local function onRelease()
        local mousePos = Hyperspace.Mouse.position
        if (button.item) then
            button.item.trackMouse = false
            if (lwui.mHoveredObject and lwui.mHoveredObject.addItem) then
                
                --try swapping them
                local heldItem = button.item
                local hoveredItem = lwui.mHoveredObject.item
                if (hoveredItem) then --todo I can probably write the swap code better than this.
                    button.item = nil
                    lwui.mHoveredObject.item = nil
                    if (button.allowedItemsFunction(hoveredItem) and lwui.mHoveredObject.allowedItemsFunction(heldItem)) then
                        button.onItemRemovedFunction(button, heldItem)--todo improve this code.
                        lwui.mHoveredObject.onItemRemovedFunction(lwui.mHoveredObject, hoveredItem)
                        button.addItem(hoveredItem)
                        lwui.mHoveredObject.addItem(heldItem)
                    else
                        button.item = heldItem
                        lwui.mHoveredObject.item = hoveredItem
                    end
                else
                    if (lwui.mHoveredObject.addItem(button.item)) then
                        button.onItemRemovedFunction(button, button.item)
                        button.item = nil
                    end
                end
            end
        end
    end
    
    local function addItem(item)
        if button.item then
            --print("iButton already contains ", button.item.name)
            return false
        end
        if button.allowedItemsFunction(item) then
            button.item = item
            item.containingButton = button
            --print("added item ",  button.item.name)
            button.onItemAddedFunction(button, item)
            return true
        end
        --print("item type not allowed: ", item.itemType)
        return false
    end
    
    local function buttonRender() --todo make render args consistent cross all these.
        local hovering = renderFunction(button)
        if (button.item) then
            --print("rendering item ", button.item.name)
            button.item.renderFunction(button.item)
        end
        -- if hovering then
        -- print("Rendering ibutton", name, hovering)
        -- end
        return hovering
    end
    
    button = lwui.buildButton(x, y, width, height, visibilityFunction, buttonRender, onClick, onRelease)
    button.addItem = addItem
    button.allowedItemsFunction = allowedItemsFunction
    button.onItemAddedFunction = onItemAddedFunction
    button.onItemRemovedFunction = onItemRemovedFunction
    button.className = classNames.INVENTORY_BUTTON
    button.name = name --todo move or remove
    return button
end

--todo some kind of typewriter print function you can pass in to text boxes.  setTypewriterText that slowly changes the text to what you pass.

--todo fix the rendering on text boxes, right now it's not handling the size of the text correctly.

--Internal fields:  text, what this will display.  I could do something clever where it tries to shrink the font size if it's too big, or another thing where I only put these inside scroll windows which would be pretty clever.
--This needs to set its height dynamically and be used inside a scroll bar, or change font size dynamically.
--This one actually is local, the other ones are what I'll expose for use.
--textColor (GL_Color) controls the color of the text.
local function buildTextBox(x, y, width, height, visibilityFunction, renderFunction, fontSize)
    local textBox
    
    local function renderText()
        local mask = textBox.maskFunction()
        local hovering = renderFunction(textBox)--todo should this be the mask instead?
        -- if hovering then
        -- print("Rendering text box", textBox.text, hovering)
        -- end
        --todo stencil this out, text has no interactivity so it's fine. based on mask.
        Graphics.CSurface.GL_PushStencilMode()
        Graphics.CSurface.GL_SetStencilMode(1,1,1)
        Graphics.CSurface.GL_ClearAll()
        Graphics.CSurface.GL_SetStencilMode(1,1,1)
        Graphics.CSurface.GL_PushMatrix()
        --Stencil of the size of the box
        Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y, mask.width, mask.height, textBox.textColor)
        Graphics.CSurface.GL_PopMatrix()
        Graphics.CSurface.GL_SetStencilMode(2,1,1)
        --Actually print the text
        local oldColor = Graphics.CSurface.GL_GetColor()
        Graphics.CSurface.GL_SetColor(textBox.textColor)
        Graphics.freetype.easy_printAutoNewlines(textBox.fontSize, textBox.getPos().x, textBox.getPos().y, textBox.width, textBox.text)
        Graphics.CSurface.GL_SetColor(oldColor)
        Graphics.CSurface.GL_SetStencilMode(0,1,1)
        Graphics.CSurface.GL_PopStencilMode()
        return hovering
    end
    
    textBox = lwui.buildObject(x, y, width, height, visibilityFunction, renderText)
    textBox.text = ""
    textBox.fontSize = fontSize
    textBox.textColor = Graphics.GL_Color(1, 1, 1, 1)
    textBox.className = classNames.TEXT_BOX
    return textBox
end

--Minimum font size is five, choosing smaller will make it bigger than five.
--You can put this one inside of a scroll window for good effect
---Creates an object that contains and displays text, and resizes its height dynamically to accomidate it.
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@param fontSize number How big the font should be.  Numbers smaller than 6 are all the same.
---@return table the text box
function lwui.buildDynamicHeightTextBox(x, y, width, height, visibilityFunction, renderFunction, fontSize)
    local textBox
    local function expandingRenderFunction()
        local lowestY = Graphics.freetype.easy_printAutoNewlines(textBox.fontSize, 5000, textBox.getPos().y, textBox.width, textBox.text).y
        textBox.height = lowestY - textBox.getPos().y
        local hovering = renderFunction(textBox)
        -- if hovering then
        -- print("Rendering dynamic text box", textBox.text, hovering)
        -- end
        return hovering
    end
    
    textBox = buildTextBox(x, y, width, height, visibilityFunction, expandingRenderFunction, fontSize)
    textBox.className = classNames.DYNAMIC_TEXT_BOX
    return textBox
end

--Font shrinks to accomidate text, I don't think this one looks as good generally, but I wanted to make it available.
---Creates an object that contains and displays text, and dynamically resizes the font to fit the text in the box.
---@param x number (in pixels) x position relative to this object's container.  If top level, is x position.
---@param y number (in pixels) y position relative to this object's container.  If top level, is y position.
---@param width number in pixels
---@param height number in pixels
---@param visibilityFunction function returns true if this object should render, and false otherwise.  Takes no arguments.
---@param renderFunction function Takes one argument, which will be the created object.  This is where you put your render code,
---@ such as lwui.solidRectRenderFunction.
---@param maxFontSize number The largest font this box should try to use.
---@return table the text box
function lwui.buildFixedTextBox(x, y, width, height, visibilityFunction, renderFunction, maxFontSize)
    local textBox
    local function scalingFontRenderFunction()
        local hovering = renderFunction(textBox)
        -- if hovering then
        -- print("Rendering fixed text box", textBox.text, hovering)
        -- end
        --textBox.text = textBox.text.."f"
        if (#textBox.text > textBox.lastLength) then
            textBox.lastLength = #textBox.text
            --check if reduction needed
            --print offscreen to avoid clutter
            while ((textBox.fontSize > MIN_FONT_SIZE) and
                    (Graphics.freetype.easy_printAutoNewlines(textBox.fontSize, 5000, textBox.getPos().y, textBox.width, textBox.text).y > textBox.getPos().y + textBox.height)) do
                --print("Lowest Y ", Graphics.freetype.easy_printAutoNewlines(textBox.fontSize, 5000, textBox.getPos().y, textBox.width, textBox.text).y)
                textBox.fontSize = textBox.fontSize - 1
                --print("New Lowest Y ", Graphics.freetype.easy_printAutoNewlines(textBox.fontSize, 5000, textBox.getPos().y, textBox.width, textBox.text).y)
            end
        elseif (#textBox.text < textBox.lastLength) then
            textBox.lastLength = #textBox.text
            --check if we can increase size
            while ((textBox.fontSize < textBox.maxFontSize) and
                    (Graphics.freetype.easy_printAutoNewlines(textBox.fontSize + 1, 5000, textBox.getPos().y, textBox.width, textBox.text).y < textBox.getPos().y + textBox.height)) do
                textBox.fontSize = textBox.fontSize + 1
            end
        end
        return hovering
    end
    
    textBox = buildTextBox(x, y, width, height, visibilityFunction, scalingFontRenderFunction, maxFontSize)
    textBox.maxFontSize = maxFontSize
    textBox.lastLength = #textBox.text
    textBox.className = classNames.FIXED_TEXT_BOX
    return textBox
end

---Stateful button with an onClick that turns something on and off.
---@param x number
---@param y number
---@param width number
---@param height number
---@param visibilityFunction function
---@param renderFunction function Must be created with lwui.toggleButtonRenderFunction
---@param onClick function called when state toggles, with self and new state
---@return table
function lwui.buildToggleButton(x, y, width, height, visibilityFunction, renderFunction, onClick)
    local button
    local function buttonClick(self)
        self.state = not self.state
        onClick(self, self.state)
    end
    
    button = lwui.buildButton(x, y, width, height, visibilityFunction, renderFunction, buttonClick, NOOP)
    button.className = classNames.TOGGLE_BUTTON
    button.state = false
    return button
end
------------------------------------RENDER FUNCTIONS----------------------------------------------------------

---@return true
function lwui.alwaysOnVisibilityFunction()
    return true
end

local primitiveList = {}
--Allows a render event to refer to an already-existing primitive of a png file if possible to avoid creating duplicates.
local function primitiveListManager(string)
    if not primitiveList[string] then
        local stringID = Hyperspace.Resources:GetImageId(string)
        primitiveList[string] = Hyperspace.Resources:CreateImagePrimitiveString(
            string,
            0,
            0,
            0,
            Graphics.GL_Color(1, 1, 1, 1),
            1.0,
            false
        )
    end
    return primitiveList[string]
end

function lwui.solidRectRenderFunction(glColor)
    return function(object)
        if object == nil then
            lwl.logError(TAG, "in solidRectRenderFunction: Object was nil!")
            return
        end
        local mask = object.maskFunction()
        Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y, mask.width, mask.height, glColor)
    end
end

---To make a button look disabled, have the main color be lighter.  To make it look enabled, have the main color be darker.
---@param object any
---@param mainColor any
---@param frameColor any
function lwui.inventoryButtonCustomColors(object, mainColor, frameColor)
    if object == nil then
        lwl.logError(TAG, "in inventoryButtonDefault: Object was nil!")
        return
    end
    local mask = object.maskFunction()
    local xScaling = math.floor(.08 * mask.width)
    local yScaling = math.floor(.08 * mask.height)
    Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y, mask.width, mask.height, frameColor)
    Graphics.CSurface.GL_DrawRect(mask.getPos().x + xScaling, mask.getPos().y + yScaling,
        mask.width - xScaling, mask.height - yScaling, mainColor)
end

---A render function.  A nice skin for inventoryButtons that fits well with the standard game UI.
---@param object any
function lwui.inventoryButtonDefault(object)
    lwui.inventoryButtonCustomColors(object, Graphics.GL_Color(4/255, 8/255, 13/255, 1), Graphics.GL_Color(63/255, 63/255, 67/255, 1))
end

--Listed backwards to lock eyes with god and walk backwards into hell
local gayTransColors = {Graphics.GL_Color(83/100, 0/255, 255/255, .3), Graphics.GL_Color(0/255, 18/100, 255/255, .3),
    Graphics.GL_Color(0/255, 255/255, 89.2/100, .3), Graphics.GL_Color(0/100, 255/255, 2/255, .3), 
    Graphics.GL_Color(255/255, 250/255, 13/255, .3), Graphics.GL_Color(255/255, 140/255, 0/255, .3),
    Graphics.GL_Color(255/255, 13/255, 0/255, .3)}

function lwui.inventoryButtonFadedGayDefault(object)
    local mask = object.maskFunction()
    lwui.inventoryButtonCustomColors(object, Graphics.GL_Color(4/255, 8/255, 13/255, 1), Graphics.GL_Color(63/255, 63/255, 67/255, 1))
    
    --todo Be gay about it
    for i = 1,#gayTransColors do
        local scaleFactor = (#gayTransColors - i + 1) / #gayTransColors --ok the scaling version only works if its not trans. Means this is harder.  Eh, do it anyway, see how it looks
        Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y, mask.width, mask.height * scaleFactor, gayTransColors[i])
    end
end

function lwui.inventoryButtonGayDefault(object)
    local mask = object.maskFunction()
    lwui.inventoryButtonCustomColors(object, Graphics.GL_Color(4/255, 8/255, 13/255, 1), Graphics.GL_Color(63/255, 63/255, 67/255, 1))
    --todo Be gay about it
    for i = 1,#gayTransColors do
        local scaleFactor = ((#gayTransColors - i) / #gayTransColors) --ok the scaling version only works if its not trans. Means this is harder.  Eh, do it anyway, see how it looks
        Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y + (mask.height * scaleFactor), mask.width, mask.height / #gayTransColors, gayTransColors[i])
    end
end

function lwui.inventoryButtonDefaultDisabled(object)
    lwui.inventoryButtonCustomColors(object, Graphics.GL_Color(63/255, 63/255, 67/255, 1), Graphics.GL_Color(93/255, 93/255, 97/255, 1))
end

---Allows you to change the rendered image at runtime from a specified set of images.
---@param spritePaths table the path under your /img/ folder.  If the sprite is larger than the mask rendering it, it will be cut off, so create objects with the same size of the sprites you want them to use.
---@param indexSelectFunction function must return a valid index for the table of paths you have provided.
---@return function A render function that can be used with all lwui objects.
function lwui.dynamicSpriteRenderFunction(spritePaths, indexSelectFunction)
    return function (object)
        local mask = object.maskFunction()
        Graphics.CSurface.GL_PushStencilMode()
        Graphics.CSurface.GL_SetStencilMode(1,1,1)
        Graphics.CSurface.GL_ClearAll()
        Graphics.CSurface.GL_SetStencilMode(1,1,1)
        Graphics.CSurface.GL_PushMatrix()
        --Stencil of the size of the box
        Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y, mask.width, mask.height, GL_WHITE)
        Graphics.CSurface.GL_PopMatrix()
        Graphics.CSurface.GL_SetStencilMode(2,1,1)
        --Render sprite image, might be larger than the stencil
        Graphics.CSurface.GL_PushMatrix()
        --TODO scale primative to the size of the object, but for now just get it working rendering images for things.
        local primitive = primitiveListManager(spritePaths[indexSelectFunction(object)])
        Graphics.CSurface.GL_Translate(object.getPos().x, object.getPos().y, 0)
        Graphics.CSurface.GL_RenderPrimitive(primitive)
        Graphics.CSurface.GL_PopMatrix()
        Graphics.CSurface.GL_SetStencilMode(0,1,1)
        Graphics.CSurface.GL_PopStencilMode()
    end
end

---Four paths for the four states of a toggle button.
---@param off string path to the image for the off state
---@param on string path to the image for the on state
---@param hoveredOff string path to the image for the off but hovered state
---@param hoveredOn string path to the image for the on but hovered state
---@return function a render function that changes based on the associated button's state.
function lwui.toggleButtonRenderFunction(off, hoveredOff, on, hoveredOn)
    local function indexSelectFunction(toggleButton)
        if toggleButton.class == classNames.TOGGLE_BUTTON then
            --todo doesn't work with inheritance.  or rather, objects have no concept of parents right now.
            --I should change that, actually.
            print("Expected toggle button, found", toggleButton.class)
        end
        local enabled = toggleButton.state
        if enabled then
            if lwui.mHoveredObject == toggleButton then
                return 4
            else
                return 3
            end
        else
            if lwui.mHoveredObject == toggleButton then
                return 2
            else
                return 1
            end
        end
    end
    return lwui.dynamicSpriteRenderFunction({off, hoveredOff, on, hoveredOn}, indexSelectFunction)
end

function lwui.spriteRenderFunction(spritePath)
    return lwui.dynamicSpriteRenderFunction({spritePath}, function () return 1 end)
end

local function animRenderFunction(animation)
    --todo maybe use brightness or something, idk?
    --Don't really know how to get a crew member's animations.
end

FULL_SCREEN_MASK = lwui.buildObject(0, 0, 5000, 5000, NOOP, NOOP)

--pretty minor but I want this
function lwui.constructScrollBarSkin(upButtonRender, downButtonRender, nubRender, barRender, backgroundRender, barWidth)
    return {upButtonRender=upButtonRender, downButtonRender=downButtonRender, nubRender=nubRender, barRender=barRender, backgroundRender=backgroundRender, barWidth=barWidth}
end

function lwui.travellerScrollNubRender() --TODO only works for vertical ones.  
    return function(object)
        local mask = object.maskFunction()
        local nubColor = GL_WHITE
        --If object is hovered
        if lwui.mHoveredObject == object then
            nubColor = GL_TRAVELLER_BLUE
        end
        --If object cannae scroll
        if (object.scrollContainer.scrollWindowRange < 1) then
            nubColor = GL_TRAVELLER_GRAY
        end
        
        Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y + 1, mask.width, mask.height - 2, nubColor)
        Graphics.CSurface.GL_DrawRect(mask.getPos().x + 1, mask.getPos().y, mask.width - 2, 1, nubColor)
        Graphics.CSurface.GL_DrawRect(mask.getPos().x + 1, mask.getPos().y + mask.height - 1, mask.width - 2, 1, nubColor)
    end
end

--uh this is hard because things might not line up with their sizes and require stretching or scaling to fit.
--So that means I need to...  Uh...  I need to make a render function that tesselates the image?
--I need to pass more values to spriteRenderFunction, like the initial size of the thing being rendered so it knows how to operate.
--Check GL methods
lwui.defaultScrollBarSkin = lwui.constructScrollBarSkin(
        lwui.spriteRenderFunction("scrollbarStyles/traveller/scroll_up_on.png"),
        lwui.spriteRenderFunction("scrollbarStyles/traveller/scroll_down_on.png"),
        lwui.travellerScrollNubRender(),
        lwui.spriteRenderFunction("scrollbarStyles/traveller/scroll_bar.png"),
        GEN_NOOP, --lwui.solidRectRenderFunction(Graphics.GL_Color(.06, .06, .1, .5)),
        16)

lwui.testScrollBarSkin = lwui.constructScrollBarSkin(
        lwui.solidRectRenderFunction(Graphics.GL_Color(0, 1, 1, 1)),
        lwui.solidRectRenderFunction(Graphics.GL_Color(0, 1, 1, 1)),
        lwui.solidRectRenderFunction(Graphics.GL_Color(.4, .1, 1, 1)),
        lwui.solidRectRenderFunction(Graphics.GL_Color(.5, .5, .5, .8)),
        lwui.solidRectRenderFunction(Graphics.GL_Color(.2, .8, .8, .3)),
        12)
------------------------------------RENDERING LOGIC----------------------------------------------------------
--this makes the z-ordering of buttons based on the order of the sButtonList, Lower values on top.
local function renderObjects(layerName)
    --print("render layer "..layerName)
    local hovering = false
    Graphics.CSurface.GL_PushMatrix()
    local i = 1
    for _, object in ipairs(mTopLevelRenderLists[layerName]) do
        local hovered = object.renderFunction(object)
        if hovered then
            hovering = true
            mLayersWithoutHover = 0
        end
        -- if (hovered) then
        --     print("render object "..i.." on layer "..layerName, "hovered=", hovered, lwl.dumpObject(object))
        -- else
        --     -- print("render object "..i.." on layer "..layerName, "hovered=", hovered)
        -- end
        i = i + 1
    end
    if not hovering and mLayersWithoutHover < 300 then --todo probably some reason this is large, kludgy.
        mLayersWithoutHover = mLayersWithoutHover + 1
    end
    if mScrollContainerHoverTimer < 300 then --todo probably some reason this is large, kludgy.
        mScrollContainerHoverTimer = mScrollContainerHoverTimer + 1
    end

    if (lwui.mHoveredObject ~= nil and mLayersWithoutHover > mLayersPerTick) then
        -- print("Went ", mLayersWithoutHover, "layers without hovering, setting hover to nil.")
        --todo this actually makes things feel laggy on some systems.  Revise.
        lwui.mHoveredObject = nil
    end
    if mHoveredScrollContainer ~= nil and mScrollContainerHoverTimer > mLayersPerTick then
        mHoveredScrollContainer = nil
    end
    -- print("Went ", mLayersWithoutHover, "layers without hovering")
    --print("Hovering:", layerName, hovering, lwui.mHoveredObject, mHoveredScrollContainer)
    Graphics.CSurface.GL_PopMatrix()
end

--item ticking should be left up to the consumers.
--yeah, select those items and hold them!
lwl.safe_script.on_internal_event("lwui_hovered_button", Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x,y)
-- script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x,y)
    local mousePos = Hyperspace.Mouse.position
    --print("clicked ", mousePos.x, mousePos.y, ", button_hovered ", lwui.mHoveredObject)
    if lwui.mHoveredObject then
        --print("clicked ", lwui.mHoveredObject)
        lwui.mHoveredObject.onClick(lwui.mHoveredObject, x, y)
        lwui.mClickedObject = lwui.mHoveredObject
    end

    return Defines.Chain.CONTINUE
end)

lwl.safe_script.on_internal_event("lwui_clicked_button", Defines.InternalEvents.ON_MOUSE_L_BUTTON_UP, function(x,y)
-- script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_UP, function(x,y)
    if (lwui.mClickedObject) then
        lwui.mClickedObject.onRelease(lwui.mClickedObject, x, y)
        lwui.mClickedObject = nil
    end
    return Defines.Chain.CONTINUE
end)

--todo handle nested scroll bars, sideways scrolling, and other things?
lwl.safe_script.on_internal_event("lwui_scroll_action", Defines.InternalEvents.ON_MOUSE_SCROLL, function(direction)
-- script.on_internal_event(Defines.InternalEvents.ON_MOUSE_SCROLL, function(direction)
    if not mHoveredScrollContainer then return end --Only preempt if we actually are using it.
    if lwl.xor(direction > 0, mHoveredScrollContainer.invertScroll) then
        mHoveredScrollContainer.scrollDown()
    else
        mHoveredScrollContainer.scrollUp()
    end
    return Defines.Chain.PREEMPT
end)

local function registerRenderEvents(eventList)
    for name, _ in pairs(eventList) do
        mTopLevelRenderLists[name] = {}
        mTopLevelRenderLists[name.."_PRE"] = {}
        lwl.safe_script.on_render_event("lwui_"..name.."render_layer", Defines.RenderEvents[name], function(_)
        -- script.on_render_event(Defines.RenderEvents[name], function(_)
            renderObjects(name .. "_PRE")
        end, function(_)
            renderObjects(name)
        end)
    end
    mLayersPerTick = 2 * lwl.countKeys(mTopLevelRenderLists)
end
registerRenderEvents(RENDER_LAYERS)


------------------------------------HELP BAR CONTAINER----------------------------------------------------------
--todo this will be in MV 5.5, remove after that.  It's also already in fusion.
local mRenderHelp = false
local function helpTextVisibilityFunction()
    return mRenderHelp
end

local function helpBarVisibilityFunction()
    return lwl.varAsBoolean(Hyperspace.metaVariables["lwl_display_help"])
end

local mHelpBarContainer = lwui.buildVerticalContainer(1264, 10, 13, 200, helpBarVisibilityFunction, lwui.solidRectRenderFunction(Graphics.GL_Color(.2, .3, .4, .5)), {}, false, true, 2)
local mHelpTextBox = lwui.buildDynamicHeightTextBox(927, 25, 330, 90, helpTextVisibilityFunction, lwui.solidRectRenderFunction(Graphics.GL_Color(.1, .1, .1, .74)), 11)
mHelpTextBox.text = "oh yeah baby this rendered some text and it's really big yo dode"
lwui.addTopLevelObject(mHelpBarContainer, "MOUSE_CONTROL_PRE")
lwui.addTopLevelObject(mHelpTextBox, "MOUSE_CONTROL_PRE")
function lwui.addHelpButton(helpButton)
    --print("Added help button", helpButton.lwuiHelpText)
    mHelpBarContainer.addObject(helpButton)
end

lwl.safe_script.on_internal_event("lwui_render_help", Defines.InternalEvents.ON_TICK, function()
-- script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if lwui.mHoveredObject then
        local helpText = lwui.mHoveredObject.lwuiHelpText
        if helpText then
            mHelpTextBox.text = helpText
            mRenderHelp = true
            return
        end
    end
    mRenderHelp = false
    end)
---------------------------BRIGHTNESS PARTICLES SUPPORT--------------------------------

if (mods.Brightness) then
    --todo Define methods for registering brightness particles as objects.  They still primarily render via brightness
    --I can probably grab control of whatever elements of brightness I need to like unset the particles path maybe ?
    
end
