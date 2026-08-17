local draw_grid = {
    gridSize = {x,y}, -- Size of monitor grid
    gridOrder = {}, -- Order of monitors in peripherals
    monitors = {}, -- Total monitor list
    monitorSize = {x=1,y=1}, -- Monitor base size. All monitors must share the same dimensions.
    totalSize = {x=0,y=0}, --Track total size
    offsets = {} -- Pixel offset pos for each monitor
}

-- monitorsize should be a {x,y} table,
-- gridsize should be an {x,y} table,
-- monitororder should be order of the grid, left-right, top-down.
function draw_grid:setup(monitorsize,gridsize,monitororder)
    self.gridSize= {x=gridsize[1],y=gridsize[2]}
    self.gridOrder = monitororder
    self.monitorSize = monitorsize
    -- Setup total size
    local size = {x=0,y=0}
    for i=1,self.gridSize.x do
        size.x = size.x + monitorsize.x
    end
    for i=1,self.gridSize.y do
        size.y = size.y + monitorsize.y
    end
    self.totalSize = size
    -- Setup offsets
    for i=1,#self.gridOrder do
        local idx = self.gridOrder[i]
        local x_mult = (i-1)%self.gridSize.x
        local y_mult = math.floor((i-1)/self.gridSize.x)
        local offset = {x=self.monitorSize.x*x_mult,y=self.monitorSize.y*y_mult}
        self.offsets[idx] = offset
    end
end

-- Takes x,y and monitor index and returns the relative pixel coordinate 
function draw_grid:relativeCoord(monitorx,monitory,monitoridx)
    local coord = self.offsets[monitoridx]
    coord = {x=coord.x + monitorx,y=coord.y + monitory}
    return coord
end

-- Unifies the colors in the monitors.
-- Takes a list of monitors and a list of colors (16)
function draw_grid:setColors(monitorList,colorList)
    local bshift = bit32.lshift
    for m=1,#monitorList do
        for c=1,#colorList do
            monitorList[m].setPaletteColor(bshift(1,c-1),colorList[c])
        end
    end
end

function draw_grid:setTextScale(monitorList,scale)
    for m=1,#monitorList do
        monitorList[m].setTextScale(scale)
    end
end

return draw_grid

-- COLOR ORDER
-- White,Orange,Magenta,LightBlue,Yellow,Lime,Pink,Gray,
-- LightGray,Cyan,Purple,Blue,Brown,Green,Red,Black
-- DEFAULT_COLORS = {0xF0F0F0,0xF2B233,0xE57FD8,0x99B2F2,0xDEDE6C,0x7FCC19,0xF2B2CC,0x4C4C4C,0x999999,0x4C99B2,0xB266E5,0x3366CC,0x7F664C,0x57A64E,0xCC4C4C,0x111111}