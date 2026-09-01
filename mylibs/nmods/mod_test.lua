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
-- `data` contains relevant updated information {owner,mobs,blocks}
function MODULE:draw(data)
    if not self.enabled then return end -- You should put this line right before using canvas objects. Usually once is fine.
    if (tick % 100 == 0) then
        print("Testmodule: Draw call")
    end
    -- print("Testmodule Print: Hello!")
end

-- Optional
-- `data` contains relevant updated information {owner,mobs,blocks}
function MODULE:sim(data)
    tick = tick + 1
    if ((tick % 100) == 0) then
        print(string.format("Testmodule: Sim tick %s",tick))
    end
end

-- Optional
-- `event` is the whole event table from os.pullEvent()
function MODULE:input(event)
    if event[1] == "key" then
        print("Testmodule: Key pressed: " .. event[2])
    elseif event[1] == "key_up" then
        print("Testmodule: Key released: " .. event[2])
    elseif event[1] ~= "timer" then
        print(event[1])
    end
    return false -- Returns whether the input was consumed
end

-- Required
-- `data` contains useful dependency-injection information: {ownerName,neural,canvas,canvasSize,speakers}
function MODULE:enable(data)
    -- Make sure to keep track of your canvas objects...
    local canvas = data.canvas
    local size = data.canvasSize
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