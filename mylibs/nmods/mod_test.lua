local MODULE = {
    name = "Test Module", -- Required
    enabled = false, -- Required
    -- These help keep track of whether the Entity Sensor and Block Scanner are needed,
    -- to conserve the energy that they use.
    doScan = false, -- Recommended
    doSense = false -- Recommended
}

local tick = 1 -- You can use local variables just fine
local text = nil
local rect = nil

-- Optional
-- Note that the standard canvas size is 512 x 288 (for some reason)
function MODULE:draw(canvas)
    if not self.enabled then return end -- You should put this line right before using canvas objects. Usually once is fine.
    if (tick % 100 == 0) then
        print("Testmodule: Draw call")
    end
    -- print("Testmodule Print: Hello!")
end

-- Optional
function MODULE:sim(data)
    tick = tick + 1
    if ((tick % 100) == 0) then
        print(string.format("Testmodule: Sim tick %s",tick))
    end
end

-- Optional
function MODULE:input(event,key,held)
    if event == "key" then
        print("Testmodule: Key pressed: " .. key)
    elseif event == "key_up" then
        print("Testmodule: Key released: " .. key)
    end
end

-- Required
-- `data` contains useful dependency-injection information: {neural,canvas,ownerName}
function MODULE:enable(data)
    -- Make sure to keep track of your canvas objects...
    local canvas = data.canvas
    local size = {x,y} size.x,size.y=canvas.getSize()
    text = canvas.addText({size.x-19*3,1},"TEST MODULE ENABLED",0xFFFFFFFF,0.5)
    rect = canvas.addRectangle(0,0,size.x,size.y,0x77111111)
end

-- Required
function MODULE:disable(data)
    -- ...And to remove your canvas objects when disabling
    text.remove()
    rect.remove()
end

return MODULE