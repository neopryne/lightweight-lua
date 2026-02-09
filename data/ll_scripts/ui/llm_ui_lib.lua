--todo what it has named lwui is really lwui_object.

local lwui = {}
lwui.__index = lwui




function lwui.addTopLevel(node, layer)
    local list = lwui.layers[layer]
    if not list then
        error("Invalid layer: " .. tostring(layer))
    end

    node.parent = nil
    node.layer = layer
    table.insert(list, node)
end

--Checks which nodes are marked as dirty and recomputes them.
--Uh, I think with my current layout, this means an update anywhere means an entire rerender.
function lwui.updateAll()
    
end

function lwui.renderAll()
    for _, layerName in ipairs({"background", "ui", "overlay"}) do
        for _, node in ipairs(lwui.layers[layerName]) do
            node:draw()
        end
    end
end












