if (not mods) then mods = {} end
mods.lightweight_user_interface = {}
local lwui = mods.lightweight_user_interface
local lwl = mods.lightweight_lua

--[[

TODO: Image-based rendering, and scroll bar skin packs.
Gonna make the one arc uses the default one as it's pretty good.
Does mean I need a way to stretch an image.  I wonder if GL will just do that for me.

Radio buttons maybe?  You can do this yourself, but I'll see if it seems worth putting here when I build it.

todo if holding an item and hovering a full button that can hold it, switch them

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
--]]

local function NOOP() end
local function GEN_NOOP() return NOOP end
local MIN_FONT_SIZE = 5
local FULL_SCREEN_MASK
local function FULL_SCREEN_MASK_FUNCTION() return FULL_SCREEN_MASK end

local GL_WHITE = Graphics.GL_Color(1, 1, 1, 1)
local GL_TRAVELLER_GRAY = Graphics.GL_Color(160/255, 162/255, 171/255, 1)
local GL_TRAVELLER_BLUE = Graphics.GL_Color(58/255, 127/255, 255/255, 1)

local mTopLevelRenderList = {}
lwui.mHoveredButton = nil
local mHoveredScrollContainer = nil
lwui.mClickedButton = nil --mouseUp will be called on this.
local mItemList = {}


function lwui.isWithinMask(mousePos, mask)
    return mousePos.x >= mask.getPos().x and mousePos.x <= mask.getPos().x + mask.width and
           mousePos.y >= mask.getPos().y and mousePos.y <= mask.getPos().y + mask.height
end

--for testing, mostly don't use this and define your own.
function lwui.alwaysOnVisibilityFunction()
    return true
end

--Used to register your top level objects so they render themselves / their contents.
function lwui.addTopLevelObject(object)
    --print("added an object", object.getPos().y)
    table.insert(mTopLevelRenderList, object)
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
function lwui.buildObject(x, y, width, height, visibilityFunction, renderFunction)
    local object = {}
    local function renderObject(mask)
        --print("should render? ", visibilityFunction())
        if not object.visibilityFunction then
            print("ERROR: vis func for object ", object.getPos().x, ", ", object.getPos().y, " is nil!")
            return true
        end
        if object.visibilityFunction() then
            return renderFunction(object)
        end
    end
    
    local function getPosition()
        return {x=object.x, y=object.y}
    end
    
    local function maskFunctionNoOp() --mask has only x, y, width, height; can't be concave with current settings.
        return object
    end
    
    local function setMaskFunction(maskFunc)
        object.maskFunction = maskFunc
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
    object.className = "object"
    return object
end

--onClick(x, y): args being passed are global position of the cursor when click occurs.
function lwui.buildButton(x, y, width, height, visibilityFunction, renderFunction, onClick, onRelease)--todo order changed, update calls.
    if not (onRelease) then onRelease = NOOP end
    if not (onClick) then onClick = NOOP end
    local button
    local function buttonClick(x1, y1)
        if button.visibilityFunction then
            onClick(x1, y1)
        end
    end
    
    local function renderButton(mask)
        local hovering = false
        local mousePos = Hyperspace.Mouse.position
        local buttonMask = button.maskFunction()
        if lwui.isWithinMask(mousePos, buttonMask) then
            hovering = true
            if not (lwui.mHoveredButton == button) then
                --print("button_hovered ", button)
                lwui.mHoveredButton = button
            end
        end
        renderFunction(button)
        return hovering
    end
    
    button = lwui.buildObject(x, y, width, height, visibilityFunction, renderButton)
    button.onClick = buttonClick
    button.onRelease = onRelease
    button.className = "button"
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
function lwui.buildContainer(x, y, width, height, visibilityFunction, renderFunction, objects, renderOutsideBounds, sizeToContent)
    local container
    --Append container rendering behavior to whatever function the user wants (if any) to show up as the container's background.
    local function renderContainer(mask)
        renderFunction(container)
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
        return hovering
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
        if not container.renderOutsideBounds then
            object.setMaskFunction(combineMasks(container, object))
        end
        --adjust getPos
        local oldGetPos = object.getPos
        function containedGetPos()
            local newX = container.getPos().x + oldGetPos().x
            local newY = container.getPos().y + oldGetPos().y
            --print("containedGetPos newX ", newX, "newy ", newY, " getPos function ", object.getPos)
            return {x=newX, y=newY}
        end
        object.getPos = containedGetPos
        --adjust visibilityFunction
        --object is only visible if partially inside container.
        local oldVisibilityFunction = object.visibilityFunction
        function containedVisibilityFunction()--TODO is this outdated?
            local retVal = false
            if container.renderOutsideBounds then return true end
            if ((object.getPos().x > container.getPos().x + container.width) or (object.getPos().x + object.width < container.getPos().x) or
                (object.getPos().y > container.getPos().y + container.height) or (object.getPos().y + object.height < container.getPos().y)) then
                retVal = false
            else
                if (not oldVisibilityFunction) then
                    print("ERROR: vis func for contained object ", object.getPos().x, ", ", object.getPos().y, " is nil!")
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
function lwui.buildVerticalContainer(x, y, width, height, visibilityFunction, renderFunction, objects, renderOutsideBounds, sizeToContent, padding)
    local container
    local function verticalSnapRender(maskFunction)
        renderFunction(maskFunction)
        local maxPos = 0
        for i=1,#container.objects do
            local object = container.objects[i]
            object.x = 0
            object.y = maxPos
            maxPos = maxPos + container.padding + object.height
        end
    end
    container = lwui.buildContainer(x, y, width, height, visibilityFunction, verticalSnapRender, objects, renderOutsideBounds, sizeToContent)
    container.padding = padding
    container.className = "verticalContainer"
    return container
end

function lwui.buildHorizontalContainer(x, y, width, height, visibilityFunction, renderFunction, objects, renderOutsideBounds, sizeToContent, padding)
    local container
    local function horizontalSnapRender(maskFunction)
        renderFunction(maskFunction)
        local maxPos = 0
        for i=1,#container.objects do
            local object = container.objects[i]
            object.y = 0
            object.x = maxPos
            maxPos = maxPos + container.padding + object.width
        end
    end
    container = lwui.buildContainer(x, y, width, height, visibilityFunction, horizontalSnapRender, objects, renderOutsideBounds, sizeToContent)
    container.padding = padding
    container.className = "horizontalContainer"
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
function lwui.buildVerticalScrollContainer(x, y, width, height, visibilityFunction, content, scrollBarSkin)
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
        
        content.y = -scrollContainer.scrollValue
        --print("Rendering content level")
    end
    
    --todo decide about scroll bar backgrounds
    contentContainer = lwui.buildContainer(0, 0, width - barWidth, height, visibilityFunction, renderContent, {content}, false, false)
    scrollContainer = lwui.buildContainer(x, y, width, height, visibilityFunction, scrollBarSkin.backgroundRender,
        {contentContainer, scrollBar, scrollUpButton, scrollDownButton, scrollNub}, false, false)
    scrollContainer.scrollValue = barWidth
    scrollContainer.scrollUp = scrollUp
    scrollContainer.scrollDown = scrollDown
    scrollContainer.contentContainer = contentContainer
    scrollNub.scrollContainer = scrollContainer
    scrollContainer.className = "scrollContainer"
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
function lwui.buildItem(name, itemType, width, height, visibilityFunction, renderFunction, description, onCreate, onTick, onEquip, onRemove)
    local item
    local function itemRender()
        if (item.trackMouse) then
            local mousePos = Hyperspace.Mouse.position
            item.x = mousePos.x
            item.y = mousePos.y
        else
            item.x = item.containingButton.getPos().x
            item.y = item.containingButton.getPos().y
        end
        renderFunction(item)
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
    item.className = "item"
    return item
end


--I might actually put this in the UI library, it's pretty useful.
--todo is this also a container for the item?
--onItemAddedFunction: called with (button, item) when an item is added to this button successfully.
function lwui.buildInventoryButton(name, x, y, width, height, visibilityFunction, renderFunction, allowedItemsFunction, onItemAddedFunction)
    --todo custom logic has to go somewhere else, as these need to work even when the button isn't rendered.
    local button
    
    local function onClick()
        if (button.item) then
            button.item.trackMouse = true
        end
    end
    
    local function onRelease()
        local mousePos = Hyperspace.Mouse.position
        if (button.item) then
            button.item.trackMouse = false
            if (lwui.mHoveredButton and lwui.mHoveredButton.addItem) then
                if (lwui.mHoveredButton.addItem(button.item)) then
                    button.item = nil
                end
            end
        end
    end
    
    local function addItem(item)
        if button.item then
            print("iButton already contains ", button.item.name)
            return false
        end
        if allowedItemsFunction(item) then
            button.item = item
            item.containingButton = button
            print("added item ",  button.item.name)
            button.onItemAddedFunction(button, item)
            return true
        end
        print("item type not allowed: ", item.itemType)
        return false
    end
    
    local function buttonRender()
        renderFunction(button)
        if (button.item) then
            --print("rendering item ", button.item.name)
            button.item.renderFunction(button.item)
        end
    end
    
    button = lwui.buildButton(x, y, width, height, visibilityFunction, buttonRender, onClick, onRelease)
    button.addItem = addItem
    button.allowedItemsFunction = allowedItemsFunction
    button.onItemAddedFunction = onItemAddedFunction
    button.className = "inventoryButton"
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
        renderFunction()
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
        Graphics.freetype.easy_printAutoNewlines(textBox.fontSize, textBox.getPos().x, textBox.getPos().y, textBox.width, textBox.text)
        Graphics.CSurface.GL_SetStencilMode(0,1,1)
        Graphics.CSurface.GL_PopStencilMode()
    end
    
    textBox = lwui.buildObject(x, y, width, height, visibilityFunction, renderText)
    textBox.text = ""
    textBox.fontSize = fontSize
    textBox.textColor = Graphics.GL_Color(1, 1, 1, 1)
    textBox.className = "textBox"
    return textBox
end

--Minimum font size is five, choosing smaller will make it bigger than five.
--You can put this one inside of a scroll window for good effect
function lwui.buildDynamicHeightTextBox(x, y, width, height, visibilityFunction, fontSize)
    local textBox   
    local function expandingRenderFunction()
        local lowestY = Graphics.freetype.easy_printAutoNewlines(textBox.fontSize, 5000, textBox.getPos().y, textBox.width, textBox.text).y
        textBox.height = lowestY - textBox.getPos().y
    end
    
    textBox = buildTextBox(x, y, width, height, visibilityFunction, expandingRenderFunction, fontSize)
    textBox.className = "dynamicTextBox"
    return textBox
end

--Font shrinks to accomidate text, I don't think this one looks as good generally, but I wanted to make it available.
function lwui.buildFixedTextBox(x, y, width, height, visibilityFunction, maxFontSize)
    local textBox
    local function scalingFontRenderFunction()
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
    end
    
    textBox = buildTextBox(x, y, width, height, visibilityFunction, scalingFontRenderFunction, maxFontSize)
    textBox.maxFontSize = maxFontSize
    textBox.lastLength = #textBox.text
    textBox.className = "fixedTextBox"
    return textBox
end


------------------------------------RENDER FUNCTIONS----------------------------------------------------------
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
            print("Error in solidRectRenderFunction: Object was nil!")
            return
        end
        local mask = object.maskFunction()
        Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y, mask.width, mask.height, glColor)
    end
end

function lwui.inventoryButtonDefault(object)
    if object == nil then
        print("Error in inventoryButtonDefault: Object was nil!")
        return
    end
    local mask = object.maskFunction()
    local xScaling = math.floor(.08 * mask.width)
    local yScaling = math.floor(.08 * mask.height)
    Graphics.CSurface.GL_DrawRect(mask.getPos().x, mask.getPos().y, mask.width, mask.height, Graphics.GL_Color(63/255, 63/255, 67/255, 1))
    Graphics.CSurface.GL_DrawRect(mask.getPos().x + xScaling, mask.getPos().y + yScaling,
        mask.width - xScaling, mask.height - yScaling, Graphics.GL_Color(4/255, 8/255, 13/255, 1))
end

--spritePath is the path under your /img/ folder.  If the sprite is larger than the mask rendering it, it will be cut off, so create objects with the same size of the sprites you want them to use.
--This one isn't done yet, don't use it.
function lwui.spriteRenderFunction(spritePath)
    --this needs to use the stencil mode.  I could use it for both, but it seems more efficient not to.  I could be wrong.
    return function(object)
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
        local primitive = primitiveListManager(spritePath)
        Graphics.CSurface.GL_Translate(object.getPos().x, object.getPos().y, 0)
        Graphics.CSurface.GL_RenderPrimitive(primitive)
        Graphics.CSurface.GL_PopMatrix()
        Graphics.CSurface.GL_SetStencilMode(0,1,1)
        Graphics.CSurface.GL_PopStencilMode()
    end
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
        if lwui.mHoveredButton == object then
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
        GEN_NOOP,
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
function renderObjects()
    local hovering = false
    Graphics.CSurface.GL_PushMatrix()
    local i = 1
    for _, object in ipairs(mTopLevelRenderList) do
        --print("render object"..i)
        if object.renderFunction(object) then
            hovering = true
        end
        i = i + 1
    end
    if not hovering then
        lwui.mHoveredButton = nil
    end
    Graphics.CSurface.GL_PopMatrix()
end

if (script) then
    --item ticking should be left up to the consumers.
    script.on_render_event(Defines.RenderEvents.TABBED_WINDOW, function()
    end, function(tabName)
        renderObjects()
    end)

--yeah, select those items and hold them!
    script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x,y)
        local mousePos = Hyperspace.Mouse.position
        --print("clicked ", mousePos.x, mousePos.y, ", button_hovered ", lwui.mHoveredButton)
        if lwui.mHoveredButton then
            --print("clicked ", lwui.mHoveredButton)
            lwui.mHoveredButton.onClick(x, y)
            lwui.mClickedButton = lwui.mHoveredButton
        end

        return Defines.Chain.CONTINUE
    end)

    script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_UP, function(x,y)
        if (lwui.mClickedButton) then
            lwui.mClickedButton.onRelease()
            lwui.mClickedButton = nil
        end
        return Defines.Chain.CONTINUE
    end)

--[[
TODO add this when hyperspace adds the event for scrolling
    script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_UP, function(x,y)
        if (mHoveredScrollContainer) then
            mHoveredScrollContainer.scrollDown()
        end
        return Defines.Chain.CONTINUE
    end)
--todo add scroll wheel scrolling to scroll bars, prioritizing the lowest level one.
--]]
end
