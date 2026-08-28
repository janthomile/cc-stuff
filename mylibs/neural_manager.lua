local ownerName = "Spommicus"
-- Primary references
local args = {...}
local neural = peripheral.find("neuralInterface")
local canvas = neural.canvas()
local canvasSize = {x,y} canvasSize.x,canvasSize.y = canvas.getSize()
local canvasResetting = true
local drawDelay = 0.05
local simDelay = 0.05
local lerpSpeed = 10.0
-- Keys
local menuUp = keys.up
local menuDown = keys.down
local menuSelect = keys.right
local menuBack = keys.left
-- Modules
local moduleSettingKey = "neuralman.modules"
local modules = {} -- format {name:"",module:{draw:fun,input:fun,sim:fun}}
local scanCount, senseCount = 0,0
-- Utils
local function getHex(r,g,b,a)
    return (r*0x1000000)+(g*0x10000)+(b*0x100)+a
end

local function lerp(a, b, t)
    return a + (b - a) * t
end
-- Menu constants
local bgColor = getHex(128,128,128,128)
local optionTextColor = getHex(255,255,255,255)
local rectColor = {64,64,64,128}
local rectSelectColor = {128,128,128,128}
local rectEnableColor = {192,192,192,128}
-- Menu params --
-- Cursor
local selectCursor = nil
local cursorColor = getHex(255,255,255,255)
local cursorSize = 0.66
-- Options
local options = {}
local optionFontSize = 0.66
local optionSeparation = 2
local rectSize = {48,optionFontSize*8}
local bgWidth = 56
-- Working vars
local optionElements = {}
local selectedOption = 1 -- Idx
local animAwakeFrames = 0
local animFrames = 0
-- 

-- Manager UI
local function genHudElements()
    local offset = {10,10}
    local optionGroup = canvas.addGroup(offset)
    local bgSize = {bgWidth,rectSize[2]*#options+optionSeparation*(#options-1)}
    local textOffset = {2,0}
    optionGroup.addRectangle(0,0,bgSize[1],bgSize[2],bgColor)
    optionElements = {}
    for i=1,#options do
        local optionText = options[i][1]
        local yoffset = (i-1)*rectSize[2]+optionSeparation*(i-1)
        local elementGroup = optionGroup.addGroup({0,yoffset})
        local rect = elementGroup.addRectangle(0,0,rectSize[1],rectSize[2],getHex(table.unpack(rectColor)))
        local text = elementGroup.addText(textOffset,optionText,optionTextColor,optionFontSize)
        optionElements[#optionElements+1] = {elementGroup,{0,yoffset},rect,text} -- [group,basepos,rect,text]
    end
    --
    selectCursor = optionGroup.addText({0,0},">",cursorColor,cursorSize)
end

local function updateSelected()
    animAwakeFrames = lerpSpeed
    for i=1,#options do
        local element = optionElements[i]
        local rect = element[3]
        if modules[i].enabled then
            rect.setColor(table.unpack(rectEnableColor))
        else
            rect.setColor(table.unpack(rectColor))
        end
    end
end

local function animate(delta)
    if animAwakeFrames > 0 then
        local selectOffset = 4.0
        local baseOffset = 1.0
        for i=1,#optionElements do
            local element = optionElements[i]
            local group = element[1]
            local offset = element[2]
            if i == selectedOption then
                group.setPosition(lerp(group.getPosition(),selectOffset,delta*lerpSpeed),offset[2])
                
            else
                group.setPosition(lerp(group.getPosition(),baseOffset,delta*lerpSpeed),offset[2])
            end
        end
        animAwakeFrames = animAwakeFrames - 1
    end
    selectCursor.setPosition((math.sin(animFrames*0.25)+1.0)*0.5-1,(selectedOption-1)*rectSize[2]+optionSeparation*(selectedOption-1))
    animFrames = animFrames + 1
end
--

-- Startup and Modules
local function initOrGetSettings()
    local modSettings = settings.get(moduleSettingKey)
    if modSettings == nil then
        settings.define(moduleSettingKey, {
            description = "List of modules for the Neural Manager program.",
            default = {},
            type = "table"
        })
        settings.save()
        return {}
    end
    return modSettings
end
local function findModuleEntry(name,modSettings)
    modSettings = modSettings or initOrGetSettings()
    for i=1,#modSettings do
        if next(modSettings[i]) ~= nil and modSettings[i]["name"] == name then return i end
    end
    return nil
end
local function addModule(path)
    if path == nil then print("Invalid path provided.") end
    local modSettings = initOrGetSettings()
    local file, err = loadfile(path)
    if not file then print(string.format("Error loading module file %s: %s",path,err)) return end
    local moduleLoaded = file()
    local name = moduleLoaded.name
    if not name then print("Error loading module: No name provided.") return end
    local existingEntry = findModuleEntry(name,modSettings)
    if existingEntry == nil then
        local moduleEntry = {["name"]=name,["enabled"]=false,["path"]=path}
        table.insert(modSettings,moduleEntry)
    else
        modSettings[existingEntry]["path"] = path
    end
    settings.set(moduleSettingKey,modSettings)
    settings.save()
    print("Added module entry " .. name)
    -- print("Added module entry " .. textutils.serialize({["name"]=name,["path"]=path}))
end
local function removeModule(name)
    local modSettings = initOrGetSettings()
    local existingEntry = findModuleEntry(name,modSettings)
    if existingEntry == nil then print("The module \"" .. name .. "\" does not exist!") return end
    table.remove(modSettings,existingEntry)
    settings.set(moduleSettingKey,modSettings)
    settings.save()
    print("Removed module entry \"" .. name .. "\".")
end
local function loadModules()
    modules = {}
    local modSettings = initOrGetSettings()
    if next(modSettings) == nil then return end
    -- print(textutils.serialize(modSettings))
    for i=1,#modSettings do
        local settingsEntry = modSettings[i]
        local file, err = loadfile(settingsEntry["path"])
        if not file then print(string.format("Error loading module file %s: %s",settingsEntry["path"],err)) return end
        local moduleLoaded = file()
        moduleLoaded.enabled = settingsEntry["enabled"]
        table.insert(modules,moduleLoaded)
    end
end
local function resetCanvas()
    canvasResetting = true
    canvas.clear()
    genHudElements()
    updateSelected()
    for i=1,#modules do
        if modules[i].enabled and modules[i].canvas_setup then
            modules[i]:canvas_setup(canvas)
        end
    end
    canvasResetting = false
end

local function toggleModule(idx,enable)
    local _module = modules[idx]
    _module.enabled = enable
    if not _module then return end
    if enable then
        if _module.doScan then scanCount = scanCount + 1 end
        if _module.doSense then senseCount = senseCount + 1 end
        _module:enable(neural)
    else _module:disable(neural)
        if _module.doScan then scanCount = scanCount - 1 end
        if _module.doSense then senseCount = senseCount - 1 end
    end
    
    resetCanvas()
    modSettings = modSettings or initOrGetSettings()
    modSettings[idx].enabled = enable
    -- print("Toggled module \"" .. modSettings[idx].name .. "\"")
    settings.set(moduleSettingKey,modSettings)
    settings.save()
end
local function listModules()
    local modSettings = initOrGetSettings()
    local list = {}
    if next(modSettings) == nil then print("No modules found") return end
    for i=1,#modSettings do
        if next(modSettings[i]) ~= nil then table.insert(list,modSettings[i]["name"]) end
    end
    print(string.format("Modules:\n\t%s",table.concat(list,",")))
end
local function handleArguments()
    if next(args) == nil then return true
    elseif args[1] == "addmod" then addModule(args[2]) return false
    elseif args[1] == "rmmod" then removeModule(args[2]) return false
    elseif args[1] == "listmod" then listModules() return false
    elseif args[1] == "help" then print("Spommicus's Neural Manager\nAvailable arguments:\nhelp\n-- Show this screen --\naddmod <path>\n-- Add a module at the given path --\nrmmod <name>\n-- Remove a module with with the given name --\nlistmod\n-- Lists modules by their names --") return false
    else print("Unknown argument \"" .. args[1] .. "\".") return false
    end
end

local function toggleOption(idx)
    toggleModule(idx,not modules[idx].enabled)
    updateSelected()
end

local function input()
    while true do
        local event,key,held = os.pullEvent()
        if event == "key" then
            if key == menuUp then
                selectedOption = (((selectedOption-1)+#optionElements-1)%(#optionElements))+1
                updateSelected()
            elseif key == menuDown then
                selectedOption = (((selectedOption-1)+#optionElements+1)%(#optionElements))+1
                updateSelected()
            elseif key == menuSelect then
                toggleOption(selectedOption)
            elseif key == menuBack then
            end
        elseif event == "key_up" then
        end

        for i=1,#modules do
            if modules[i].enabled and modules[i].input then
                modules[i]:input(event,key,held)
            end
        end

    end
end

-- Use available "ping" slots to display mob locations on compass.
local function draw()
    while true do
        if not canvasResetting then
            animate(drawDelay)
            
            for i=1,#modules do
                if modules[i].enabled and modules[i].draw then
                    modules[i]:draw(canvas)
                end
            end
            sleep(drawDelay)
        end
    end
end

local function sim()
    while true do
        local data = {mobs = ((neural.sense and senseCount > 0) and neural.sense() or nil),
            blocks = ((neural.scan and scanCount > 0) and neural.scan() or nil)}
        for i=1,#modules do
            if modules[i].enabled and modules[i].sim then
                modules[i]:sim(data)
            end
        end
        sleep(simDelay)
    end
end

local function setup()
    loadModules()
    for i=1,#modules do
        if modules[i].enabled and modules[i].enable then
            toggleModule(i,true)
        end
    end
    for i=1,#modules do
        local option = {}
        option[1] = modules[i].name
        -- option[2] = false
        options[i] = option
    end
    resetCanvas()
end

if not handleArguments() then return end
setup()
resetCanvas()

local function run()
    parallel.waitForAll(
        draw,
        input,
        sim
    )
end

-- run()

while true do
   local success, result = pcall(run)
    if not success then print("Error in Neural Manager. Restarting...") sleep(1.0) end
end