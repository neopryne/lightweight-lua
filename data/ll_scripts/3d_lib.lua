mods.lightweight_3d = {} --todo actually you don't need to avoid resetting this if this is the only file that you 

--[[Usage:
    local lw3 = mods.lightweight_3d
    local lwl = mods.lightweight_lua
    
    local BLACK = Graphics.GL_Color(0, 0, 0, 1)
    
    --the mesh is just an array of points
    local MESH = {{x = 1, y = 2,, z = 3},
                  {x = 2, y = 3,, z = 1},
                  {x = 3, y = 1,, z = 2},
                  {x = 3, y = 1,, z = 4}}
    --faces define what triangles should be drawn.  These can be any convex polygon, but the points must be in order along the edge, or the triangles won't draw right.
    local MAIN_FACES = {{1, 2, 3, fill_color = Graphics.GL_Color(.8, .5, 0, 1), filled = true, outline_color = BLACK, outline = true, line_width=2}}
    local ALT_FACES = {{1, 3, 4, outline_color = BLACK, outline = true, line_width=2}}
    
    local position = Hyperspace.Point(0,0)
    local rotatedMesh = lw3.rotateAround(MESH, 0, 0, 0, math.pi / 6, math.pi / 3, math.pi / 2)
    local modifiedFaces = lw3.applyAlternateAnimations()
    modifiedFaces = lwl.deepTableMerge(modified_faces, ALT_FACES)
    lw3.drawObject(position, rotatedMesh, modifiedFaces)
    
    
    Currently Omen from FFFTL is the only example of using this, look at that to understand how to define the mesh and face arrays.
    This only supports one mesh at a time, and multiple sets of faces that can be toggled independently.
    
    I recommend not touching the mesh that you use to define your points, and instead storing the rotations to apply to it.
    Then when you go to render the object you can first apply the rotations and whatever effects you want to.
]]--

local X_RENDER_OFFSET = -15
local Y_RENDER_OFFSET = -15

local HIGHLIGHT_YELLOW = Graphics.GL_Color(.8, .8, .0, 1)
local HIGHLIGHT_GREEN = Graphics.GL_Color(.0, .8, .0, 1)


-- Helper function to rotate a point around a fixed point, you probably don't need this.
function mods.lightweight_3d.rotatePointAroundFixed(p, cx, cy, cz, angleX, angleY, angleZ)
    -- Translate the point so the fixed point is at the origin
    local x = p.x - cx
    local y = p.y - cy
    local z = p.z - cz

    -- Rotation around X-axis
    local cosX = math.cos(angleX)
    local sinX = math.sin(angleX)
    local newY = cosX * y - sinX * z
    local newZ = sinX * y + cosX * z
    y = newY
    z = newZ

    -- Rotation around Y-axis
    local cosY = math.cos(angleY)
    local sinY = math.sin(angleY)
    local newX = cosY * x + sinY * z
    newZ = -sinY * x + cosY * z
    x = newX
    z = newZ

    -- Rotation around Z-axis
    local cosZ = math.cos(angleZ)
    local sinZ = math.sin(angleZ)
    newX = cosZ * x - sinZ * y
    newY = sinZ * x + cosZ * y
    x = newX
    y = newY

    -- Translate the point back to its original position
    return {x = x + cx, y = y + cy, z = z + cz}
end

--Rotates the given object around the point cxyz by the given angles in each dimension in radians.
function mods.lightweight_3d.rotateAround(object, cx, cy, cz, angleX, angleY, angleZ)
    local rotatedObject = {}
    for i, vertex in ipairs(object) do
        rotatedObject[i] = mods.lightweight_3d.rotatePointAroundFixed(vertex, cx, cy, cz, angleX, angleY, angleZ)
    end
    return rotatedObject
end

-- Sort faces by their average z-depth for simple face culling.  Internal.
function mods.lightweight_3d.sortFacesByDepth(multifacedObject, active_faces)
    table.sort(active_faces, function(f1, f2)
        -- Compute average z for face f1
        local z1 = 0
        for _, index in ipairs(f1) do
            z1 = z1 + multifacedObject[index].z
        end
        z1 = z1 / #f1

        -- Compute average z for face f2
        local z2 = 0
        for _, index in ipairs(f2) do
            z2 = z2 + multifacedObject[index].z
        end
        z2 = z2 / #f2

        return z1 > z2 -- Sort descending, so that front faces are drawn last
    end)
end

--zeros the location for rendering
function mods.lightweight_3d.relativeX(xPos, position)
    return xPos + position.x + X_RENDER_OFFSET
end

--zeros the location for rendering
function mods.lightweight_3d.relativeY(yPos, position)
    return yPos + position.y + Y_RENDER_OFFSET
end

--discard z for rendering
function mods.lightweight_3d.relativeVertex(vertex, position)
    return Hyperspace.Point(mods.lightweight_3d.relativeX(vertex.x, position), mods.lightweight_3d.relativeY(vertex.y, position))
end

function mods.lightweight_3d.relativeVertexByIndex(mesh, vertexIndex, position)
    return mods.lightweight_3d.relativeVertex(mesh[vertexIndex], position)
end

function mods.lightweight_3d.drawRelativeLine(mesh, vertex1, vertex2, position, line_width, color)
    --Graphics.CSurface.GL_DrawLine(mesh[vertex1].x + position.x,  mesh[vertex1].y + position.y, mesh[vertex2].x + position.x,  mesh[vertex2].y + position.y, 2, BLACK)
    Graphics.CSurface.GL_DrawLine(mods.lightweight_3d.relativeX(mesh[vertex1].x, position),  mods.lightweight_3d.relativeY(mesh[vertex1].y, position), 
            mods.lightweight_3d.relativeX(mesh[vertex2].x, position),  mods.lightweight_3d.relativeY(mesh[vertex2].y, position), line_width, color)
end

function mods.lightweight_3d.glDrawTriangle_Wrapper(mesh, vertex1, vertex2, vertex3, position, color)
    point1 = mods.lightweight_3d.relativeVertexByIndex(mesh, vertex1, position)
    point2 = mods.lightweight_3d.relativeVertexByIndex(mesh, vertex2, position)
    point3 = mods.lightweight_3d.relativeVertexByIndex(mesh, vertex3, position)
    
    --print("rendering triangle", point1.x, ", ", point1.y, " -- ", point2.x, ", ", point2.y, " -- ", point3.x, ", ", point3.y)
    Graphics.CSurface.GL_DrawTriangle(point1, point2, point3, color)
end

--requires that the face points are in order and are a convex polygon.  For internal use.
function mods.lightweight_3d.drawFace(mesh, face, position)
    for i = 3, #face do
        --print("drawing triangle ", i)
        if (face.filled) then
            mods.lightweight_3d.glDrawTriangle_Wrapper(mesh, face[1], face[i-1], face[i], position, face.fill_color)
        end
        if (face.outline) then
            mods.lightweight_3d.drawRelativeLine(mesh, face[i-1], face[i], position, face.line_width, face.outline_color)
        end
    end
    if (face.outline) then
        mods.lightweight_3d.drawRelativeLine(mesh, face[1], face[#face], position, face.line_width, face.outline_color)
        mods.lightweight_3d.drawRelativeLine(mesh, face[1], face[2], position, face.line_width, face.outline_color)
    end
end

--You can currently only draw objects strictly on top of each other unless, so it's best to not have them overlap if you're using seperate meshes, or it could look strange.
function mods.lightweight_3d.drawObject(position, object_mesh, object_faces)
    mods.lightweight_3d.sortFacesByDepth(object_mesh, object_faces)
    --all rendering must be done between pop/push actions it seems?  Actually I have no idea what these do.
    -- Draw faces (filled polygons)
    Graphics.CSurface.GL_PushMatrix()
    for i, face in ipairs(object_faces) do
        mods.lightweight_3d.drawFace(object_mesh, face, position)
    end
    Graphics.CSurface.GL_PopMatrix()
end


--Returns the average of two colors.
function mods.lightweight_3d.mergeColors(c1, c2)
    return Graphics.GL_Color((c1.r + c2.r) / 2, (c1.g + c2.g) / 2, (c1.b + c2.b) / 2, (c1.a + c2.a) / 2)
end

--[[ 
Gives you a new face table with all color rendering info replaced by the given recolor info.
if filled is true, must have a fill_color.  If outline is true, must have an outline_color and line_width.
Unless you know those already exist and are sure you did it right.
example:
    recolor_info = { fill_color = Graphics.GL_Color(.9, .9, .9, 1), outline_color = BLACK, outline = true, line_width=2 }
    (requires that you defined BLACK earlier)
    call with relative = true to perform a merge of the colors, must have an existing fill color to use this
--]]
function mods.lightweight_3d.recolorFaces(object_faces, recolor_info, relativeRecolor)
    local deep_copy_faces = mods.lightweight_lua.deepCopyTable(object_faces)
    for i = 1, #deep_copy_faces do
        local face = deep_copy_faces[i]
        if (recolor_info.filled ~= nil) then
            face.filled = recolor_info.filled
        end
        if (recolor_info.fill_color ~= nil) then
            if (relativeRecolor == nil or relativeRecolor == false) then
                face.fill_color = recolor_info.fill_color
            else
                --print("Relative recolor")
                face.fill_color = mods.lightweight_3d.mergeColors(face.fill_color, recolor_info.fill_color)
            end
        end
        if (recolor_info.outline ~= nil) then
            face.outline = recolor_info.outline
        end
        if (recolor_info.outline_color ~= nil) then
            face.outline_color = recolor_info.outline_color
        end
        if (recolor_info.line_width ~= nil) then
            face.line_width = recolor_info.line_width
        end
    end
    return deep_copy_faces
end

--changes the faces to match the crewmember's selected status
function mods.lightweight_3d.recolorForHighlight(object_faces, crewmem)
    if (crewmem.selectionState == 0) then--not selected, do nothing
        return object_faces
    elseif (crewmem.selectionState == 1) then --selected, relative green fill
        return mods.lightweight_3d.recolorFaces(object_faces, {filled=true, fill_color = HIGHLIGHT_GREEN}, true)
    elseif (crewmem.selectionState == 2) then --hover, green edges
        return mods.lightweight_3d.recolorFaces(object_faces, {outline=true, outline_color=HIGHLIGHT_GREEN, line_width=2})
    end
end

--Applies teleport and selection effects to a list of faces for later rendering with a mesh.
--Only call this once per frame, after you've assembled the entire mesh you're going to render
--crewTable is the table for crewmem. object_faces is the list of faces you want to 
--Always returns a deep copy of the faces passed, so you don't have to worry about modifying the result later.
function mods.lightweight_3d.applyAlternateAnimations(object_faces, crewmem, crewTable)
    local tele_level = crewTable.tele_level
    if not tele_level then
        tele_level = 0
    end
    local initial_ship = crewTable.initial_ship
    if not initial_ship then
        initial_ship = crewmem.currentShipId
    end
    local copy_faces = mods.lightweight_lua.deepCopyTable(object_faces)
    --print("initial alpha: ", object_faces[1].fill_color.a, "initial ship, ", initial_ship, "current ship", crewmem.currentShipId)

    
    copy_faces = mods.lightweight_3d.recolorForHighlight(copy_faces, crewmem)
    if (crewmem.extend.customTele.teleporting) then --teleporting
        local departing
        if (crewmem.currentShipId == initial_ship) then
            departing = 1
        else
            departing = -1
        end
        --print("departing ", departing, "tele_level ", tele_level, 0 - (tele_level * departing))
        tele_level = tele_level + (.03 * departing)
        for i = 1, #copy_faces do
            copy_faces[i].fill_color = Graphics.GL_Color(copy_faces[i].fill_color.r,
                copy_faces[i].fill_color.g, copy_faces[i].fill_color.b,
                math.min(1, math.max(0, copy_faces[i].fill_color.a - tele_level))) 
        end
    else
        --reset teleport
        tele_level = 0
        crewTable.initial_ship = crewmem.currentShipId
    end
    if (crewmem.health.first <= 0 and not crewmem.bDead) then --dying
        return {} --just make it go away right away
    end
    --print("after alpha: ", copy_faces[1].fill_color.a)
    crewTable.tele_level = tele_level
    return copy_faces
end

