local MODULE = {
    name = "Test Module", -- Required
    enabled = false, -- Required
    tick = 1
}

-- Optional
function MODULE:draw(canvas)
    if (self.tick % 100 == 0) then
        print("Testmodule: Draw call")
    end
    -- print("Testmodule Print: Hello!")
end

-- Optional
function MODULE:canvas_setup(canvas)
    print("Nothing to contribute to the canvas!")
end

-- Optional
function MODULE:sim(data)
    self.tick = self.tick + 1
    if ((self.tick % 100) == 0) then
        print(string.format("Testmodule: Sim tick %s",self.tick))
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
function MODULE:enable(interface)
    print("Testmodule: enabled!")
end

-- Required
function MODULE:disable(interface)
    print("Testmodule: disabled!")
end

return MODULE