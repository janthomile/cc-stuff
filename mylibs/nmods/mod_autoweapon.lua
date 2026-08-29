local MODULE = {
    name = "Autoweapon", -- Required
    enabled = false, -- Required
}
local ownerName = "Spommicus"
local rangedTime = 4.0
local swingTicks = 4
--
local neural
local autoEnabled = true
local tick = 1
--
local melee = {"minecraft:diamond_sword"}
local ranged = {"plethora:module_laser"}

-- -- Optional
-- function MODULE:draw(canvas)
--     if (self.tick % 100 == 0) then
--         print("Testmodule: Draw call")
--     end
--     -- print("Testmodule Print: Hello!")
-- end

-- -- Optional
-- function MODULE:canvas_setup(canvas)
--     print("Nothing to contribute to the canvas!")
-- end

local function setupWeapons()
    local mtable = {}
    for i=1,#melee do
        mtable[melee[i]] = true
    end
    local rtable = {}
    for i=1,#ranged do
        rtable[ranged[i]] = true
    end
    melee = mtable
    ranged = rtable
end

setupWeapons()

-- Optional
function MODULE:sim(data)
    if autoEnabled then
        local meta = neural.getMetaByName(ownerName)
        if meta.heldItem == nil then return end
        local itemName = meta.heldItem.getMetadata().name
        if ((tick % swingTicks) == 0) and melee[itemName] then
            if not neural.swing() then end
        elseif ranged[itemName] then
            neural.use(rangedTime)
        end
    end
    tick = tick + 1
end

-- Optional
function MODULE:input(event,key,held)
    if event == "key_up" then
        if key == keys.enter then
            autoEnabled = not autoEnabled
            tick = 0
            if autoEnabled then print("Autoweapon Active")
            else print("Autoweapon inactive") end
        end
    end
end

-- Required
function MODULE:enable(interface)
    neural = interface
    tick = 1
    print("Autolaser Enabled")
end

-- Required
function MODULE:disable(interface)
    print("Autolaser Disabled")
end

return MODULE