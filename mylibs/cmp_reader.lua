local ccstrings = require("cc.strings")

local cmp_reader = {
}

function cmp_reader.get_table(file)
    local h = fs.open(file,"r")
    if not h then error("Error opening file",0) return end
    local line = h.readLine()
    local htable = {}
    while line do
        local sline = ccstrings.split(line," ")
        local hlines = {}
        for i=1,#sline do
            if not (sline[i] == "") then
                hlines[#hlines+1] = tonumber(sline[i])
            end
        end
        line = h.readLine()
        htable[#htable+1] = hlines
    end
    return htable
end

function cmp_reader.draw_htable(htable,x,y,colorTable)
    for i=1,#htable do
        local h = htable[i]
        local xoffset=0
        for j=1,#h,2 do
            local color = h[j+1]
            local len = h[j]
            if not (colorTable[color] == -1) then
                paintutils.drawLine(x+xoffset,y+i,x+xoffset+len,y+i,colorTable[color])
            end
            xoffset = xoffset + len
        end
    end
end

return cmp_reader
