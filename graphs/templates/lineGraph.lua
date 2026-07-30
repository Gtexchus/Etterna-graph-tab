local ratios = {}
local actuals = {}

--returns an actorframe that is halign(0):valign(0)
--i may add the option to change halign:valign in the future

--[[slightly confusing terminology that is used in this:
xValue means the value of a point relative to the scale of the x axis
x means the point's screen coordinates relative to the parent actor t

for example, if each pixel on the screen was worth 2 MSD, the point 5 pixels to the right of the y axis would have xValue = 10, and x = 5
same goes for yValue and y
]]


-----------------------------------------------------params-----------------------------------------------------

--values is the only thing that MUST be passed in (how do you expect me to make a graph with no values?)
--values is a table that appears like a 1-indexed array, where each item is a tuple {x, y} which is used to calculate screen coordinates for a point
--the way screen coordinates are calculated is determined by xFunc and yFunc

--[[values must:
    be 1-indexed
    have all indexes as consecutive whole numbers
    e.g. values = {[1] = {0, 1}, [3] = {5, 7}} WILL NOT WORK because the index [2] is missing
]]
--just treat values as an array instead of a table

--e.g. values may be {[1] = {6, 7}, [2] = {67, 67}, [3] = {910, 21}}
--in this case, the resulting plot will contain 3 points. The first point will be made from the tuple in index [1], and so on


--maybe this is a bad idea??? should i return an error message actorframe or just allow the lua errors to run normally???
--idk what to do in this situation
if Var("Values") == nil then
    return Def.ActorFrame{
        LoadFont("Common Normal") .. {
            InitCommand = function(self) --return an actorframe with a nice error message if there are no values passed in
                self:settext("ERROR: VALUES IS NIL")
            end
        }
    }
elseif #Var("Values") == 0 then
    return Def.ActorFrame{
        LoadFont("Common Normal") .. {
            InitCommand = function(self)
                self:settext("ERROR: VALUES IS EMPTY")
            end
        }
    }
end


local values = Var("Values")



--functions
local xFunc = Var("Xfunc") or function(params) return params.GraphWidth * ((params.xValue - params.minXvalue) / (params.maxXvalue - params.minXvalue)) end
--[[xFunc:
purpose: returns an x coordinate calculated from an x value. Inverse of xValueFunc.

params: 
xValue [number] (point's value)
GraphWidth [number] (total width of graph)
GraphHeight [number] (total height of graph)
minXvalue [number] (lowest x value a point may have)
maxXvalue [number] (highest value a point may have)

returns: number (x coordinate of point)
]]

local yFunc = Var("Yfunc") or function(params) return params.GraphHeight * (1-(params.yValue - params.minYvalue)/ (params.maxYvalue - params.minYvalue)) end  
--[[yFunc
purpose: returns a y coordinate calculated from a y value. Inverse of yValueFunc.

params: 
yValue [number] (point's y value)
GraphWidth [number] (total width of graph)
GraphHeight [number] (total height of graph)
minYvalue [number] (lowest y value a point may have)
maxYvalue [number] (highest y value a point may have)

returns: number (y coordinate of point)
]]

local colorFunc = Var("ColorFunc") or function(params) return color("#ffffff") end 
--[[colorFunc 
purpose: returns a color for a point, given that point's xValue and yValue

params: 
xValue [number] (point's x value) 
yValue [number] (point's y value)  

returns: color (color for the point)
]]

local xAxisLabelColorFunc = Var("XaxisLabelColorFunc") or function(params) return {text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = color("#ffffff")} end
--[[xAxisLabelColorFunc
purpose: colors all parts of the x axis label (text, outer line, inner line)

params:
xValue [number] (label's x value)

returns: table of colors, with keys {text, outerLine, innerLine}
]]

local yAxisLabelColorFunc = Var("YaxisLabelColorFunc") or function(params) return {text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = color("#ffffff")} end
--[[yAxisLabelColorFunc
purpose: colors all parts of the y axis label (text, outer line, inner line)

params:
yValue [number] (label's y value)

returns: table of colors, with keys {text, outerLine, innerLine}
]]

local xValueToStringFunc = Var("XvalueToStringFunc") or function(params) return tostring(params.xValue) end
--[[xValueToStringFunc 
purpose: returns a string representation of a given xValue

params:
xValue [number] (point's x value)
GraphWidth [number] (total width of graph)
GraphHeight [number] (total height of graph)
minXvalue [number] (lowest x value a point may have)
maxXvalue [number] (highest x value a point may have)

returns: string (string representation of xValue) 
]]

local yValueToStringFunc = Var("YvalueToStringFunc") or function(params) return tostring(params.yValue) end
--[[yValueToStringFunc 
purpose: returns a string representation of a given yValue

params:
yValue [number] (point's y value)
GraphWidth [number] (total width of graph)
GraphHeight [number] (total height of graph)
minYvalue [number] (lowest y value a point may have)
maxYvalue [number] (highest y value a point may have)

returns: string (string representation of yValue)
]]

local xValueFunc = Var("XvalueFunc") or function(params) return ((params.x / params.GraphWidth) * (params.maxXvalue - params.minXvalue)) + params.minXvalue end
--[[xValueFunc 
purpose: returns an x value calculated from an x coordinate. Inverse of xFunc.

params:
x [number] (the x coordinate)
minXvalue [number] (lowest x value a point may have)
maxXvalue [number] (highest x value a point may have)
GraphWidth [number] (total width of graph)

returns: number (the x value corresponding to the x coordinate)
]]

local yValueFunc = Var("YvalueFunc") or function(params) return ((1-(params.y / params.GraphHeight)) * (params.maxYvalue - params.minYvalue)) + params.minYvalue end
--[[yValueFunc 
purpose: returns a y value calculated from a y coordinate. Inverse of yFunc.

params:
y [number] (the y coordinate)
minXvalue [number] (lowest y value a point may have)
maxXvalue [number] (highest y value a point may have)
GraphHeight [number] (total height of graph)

returns: number (the y value corresponding to the y coordinate)
]]

local minXvalueFunc = Var("MinXvalueFunc") or function(params) return math.min(params.minXvalue, params.xValue) end
--[[minXvalueFunc
purpose: returns an updated minXvalue given the current minXvalue and an xValue

params:
minXvalue [number] (the current minXvalue)
xValue [number] (an xValue)

returns: number (an updated minXvalue)
]]

local maxXvalueFunc = Var("MaxXvalueFunc") or function(params) return math.max(params.maxXvalue, params.xValue) end

local minYvalueFunc = Var("MinYvalueFunc") or function(params) return math.min(params.minYvalue, params.yValue) end

local maxYvalueFunc = Var("MaxYvalueFunc") or function(params) return math.max(params.maxYvalue, params.yValue) end


actuals.GraphWidth = Var("GraphWidth") or ((680 / 1920) * SCREEN_WIDTH) --total width of graph
actuals.GraphHeight = Var("GraphHeight") or ((412 / 1080) * SCREEN_HEIGHT) --total height of graph
actuals.XaxisLabelOffset = Var("XaxisLabelOffset") or ((20 / 1920) * SCREEN_WIDTH) --how far left the x axis label is from the y axis
actuals.YaxisLabelOffset = Var("YaxisLabelOffset") or ((20 / 1080) * SCREEN_HEIGHT) --how far down the y axis label is from the x axis
actuals.XaxisLabelLineThickness = Var("XaxisLabelLineThickness") or ((1 / 1920) * SCREEN_WIDTH) --how thick the x axis label is
actuals.YaxisLabelLineThickness = Var("YaxisLabelLineThickness") or ((1 / 1080) * SCREEN_HEIGHT) --how thick the y axis label is


--get the min and max x and y values
local minXvalue = values[1][1] --smallest x value there is
local maxXvalue = values[1][1]
local minYvalue = values[1][2]
local maxYvalue = values[1][2]

for i = 1, #values do 
    minXvalue = minXvalueFunc({minXvalue = minXvalue, xValue = values[i][1]})
    maxXvalue = maxXvalueFunc({maxXvalue = maxXvalue, xValue = values[i][1]})
    minYvalue = minYvalueFunc({minYvalue = minYvalue, yValue = values[i][2]})
    maxYvalue = maxYvalueFunc({maxYvalue = maxYvalue, yValue = values[i][2]})
end

if minXvalue < 0 and maxXvalue > 0 and Var("XoriginCentered") then -- if XoriginCentered = true then x=0 is in the vertical center of the graph
    local greatest = math.max(math.abs(minXvalue), maxXvalue)
    maxXvalue = greatest
    minXvalue = -greatest
end
if minYvalue < 0 and maxYvalue > 0 and Var("YoriginCentered") then-- if YoriginCentered = true then y=0 is in the horizontal center of the graph
    local greatest = math.max(math.abs(minYvalue), maxYvalue)
    maxYvalue = greatest
    minYvalue = -greatest
end



local bgColor = Var("BGcolor") or color("#000000A2") --color of bg quad
local xAxisLabelOuterLineColor = Var("XaxisLabelOuterLineColor") or color("#ffffff")
local xAxisLabelInnerLineColor = Var("XaxisLabelInnerLineColor") or color("#ffffff")
local yAxisLabelOuterLineColor = Var("YaxisLabelOuterLineColor") or color("#ffffff")
local yAxisLabelInnerLineColor = Var("XaxisLabelInnerLineColor") or color("#ffffff")
local mouseHoverIndicatorColor = Var("MouseHoverIndicatorColor") or color("#ff000080")
local plotAlpha = Var("PlotAlpha") or 1 --alpha of plot
local xAxisLabelTextSize = Var("XaxisLabelTextSize") or 0.5 --size of x axis label text
local yAxisLabelTextSize = Var("YaxisLabelTextSize") or 0.5 --size of y axis label text
local plotAnimationSeconds = Var("PlotAnimationSeconds") or 1 --tween time of plot
local lineThickness = Var("LineThickness") or 1
local xUnits = Var("Xunits") or "X" --units of measurement the x axis is in, e.g. MSD, time, etc.
local yUnits = Var("Yunits") or "Y" --units of measurement the y axis is in

local xAxisLabelsCount = 1
local xAxisLabelScale = 1
local yAxisLabelsCount = 1
local yAxisLabelScale = 1


--you can either pick labelsScale or labelsCount, not both
if Var("XaxisLabelScale") then
    xAxisLabelScale = Var("XaxisLabelScale") or 1 --the scale of the x axis labels
    maxXvalue = ((notShit.floor(maxXvalue  / xAxisLabelScale) + 1) * xAxisLabelScale) + (minXvalue%xAxisLabelScale)--round maxXvalue up to the next x axis label, so the graph will have a label at the right
    --this is only needed if a scale is entered instead of a count
    xAxisLabelsCount = ((maxXvalue - minXvalue) / xAxisLabelScale) + 1
else
    xAxisLabelsCount = Var("XaxisLabelCount") or 1 --how many x axis labels there are
    xAxisLabelScale = (maxXvalue - minXvalue) / (xAxisLabelsCount - 1) 
end

if Var("YaxisLabelScale") then
    yAxisLabelScale = Var("YaxisLabelScale") or 1 --the scale of y axis labels
    maxYvalue = ((notShit.floor(maxYvalue / yAxisLabelScale) + 1) * yAxisLabelScale)  + (minYvalue%yAxisLabelScale)--round maxYvalue up to the nearest y axis label, so the graph will have a label at the top
    yAxisLabelsCount = ((maxYvalue - minYvalue) / yAxisLabelScale) + 1
else
    yAxisLabelsCount = Var("YaxisLabelCount") or 1 --how many y axis labels there are
    yAxisLabelScale = (maxYvalue - minYvalue) / (yAxisLabelsCount - 1) 
end

--to prevent division by 0
if minXvalue == maxXvalue then
    maxXvalue = minXvalue + 1
end

if minYvalue == maxYvalue then
    maxYvalue = minYvalue + 1
end


-----------------------------------------------------end of params-----------------------------------------------------


local function placeLineVertices(vertList, x, y, color)
    vertList[#vertList + 1] = {{x, y, 0}, color}
end

--this is bullshit and i gave up on it
--this was designed to be used with DrawMode_QuadStrip
--[[
local function placeLineVerticesWithConstantThickness(vertList, x, y, color, i)
    --vertices hacve to be placed on a line that is perpendicular to the line connecting the current and previous coords
    if #vertList == 0 then
        vertList[#vertList + 1] = {{x - (lineThickness / 2), y - (lineThickness / 2), 0}, color}
        vertList[#vertList + 1] = {{x + (lineThickness / 2), y + (lineThickness / 2), 0}, color}
        return
    end


    local prevValue = values[i-1]
    
    local prevX = xFunc({xValue = prevValue[1],
        GraphWidth = actuals.GraphWidth,
        GraphHeight = actuals.GraphHeight,
        minXvalue = minXvalue,
        maxXvalue = maxXvalue
        })

    local prevY = yFunc({yValue = prevValue[2],
        GraphWidth = actuals.GraphWidth,
        GraphHeight = actuals.GraphHeight,
        minYvalue = minYvalue,
        maxYvalue = maxYvalue
        })

    
    local prevColor = colorFunc({xValue = prevValue[1], yValue = prevValue[2]})

    local dx = x - prevX --might have to do math.abs???
    local dy = y - prevY

    local dist = math.sqrt(dx^2 + dy^2)

    local scaleFactor = lineThickness/dist
    --dy used for horizontal separation because the vertices are placed on a line perpendicular to the line connecting the current and previous coords
    local vertexHorizontalSeparation = math.abs(dy) * scaleFactor 
    local vertexVerticalSeparation = math.abs(dx) * scaleFactor

    local horizontalOffset = 0
    local verticalOffset = 0
    if i > 2 then
        local prevPrevValue = values[i-2]
        local prevPrevX = xFunc({xValue = prevPrevValue[1],
            GraphWidth = actuals.GraphWidth,
            GraphHeight = actuals.GraphHeight,
            minXvalue = minXvalue,
            maxXvalue = maxXvalue
            })

        local prevPrevY = yFunc({yValue = prevPrevValue[2],
            GraphWidth = actuals.GraphWidth,
            GraphHeight = actuals.GraphHeight,
            minYvalue = minYvalue,
            maxYvalue = maxYvalue
            })
        local prevdx = prevX - prevPrevX
        local prevdy = prevY - prevPrevY
        local prevDist = math.sqrt(prevdx^2 + prevdy^2)
        --the previous line's vertices need to be shortened/extended by lineThickness / sin(the angle between the two points)
        --the vertex on the inside of the turn needs to be shortened
        --local angle = math.acos(((dx * prevdx) + (dy * prevdy)) / (dist * prevDist))
        local v1 = {dx, dy}
        local v2 = {prevdx, prevdy}
        local bearing1 = math.atan2(v1[2], v1[1])
        local bearing2 = math.atan2(v2[2], v2[1])
        local angle = bearing2 - bearing1
        local sin = math.sin(angle)
        if sin == 0 then
            sin = 0.1
        end
        local vertexOffset = (lineThickness / sin)
        if vertexOffset ~= vertexOffset then
            vertexOffset = 0 --genuinely what do i do here
        end
        --cos for horizontal, sin for vertical
        horizontalOffset = vertexOffset * math.cos(bearing2)
        verticalOffset = vertexOffset * math.sin(bearing2)
    end

    local prevVert1 = vertList[#vertList][1]
    local prevVert2 = vertList[#vertList -1][1]
    vertList[#vertList][1][1] = prevVert1[1] + horizontalOffset
    vertList[#vertList][1][2] = prevVert1[2] + verticalOffset

    vertList[#vertList][2][1] = prevVert2[1] - horizontalOffset
    vertList[#vertList][2][2] = prevVert2[2] - verticalOffset

    
    vertList[#vertList + 1] = {{x + (vertexHorizontalSeparation / 2), y - (vertexVerticalSeparation / 2), 0}, color}
    vertList[#vertList + 1] = {{x - (vertexHorizontalSeparation / 2), y + (vertexVerticalSeparation / 2), 0}, color}
end
]]


local t = Def.ActorFrame{
    Name = "Graph",
    InitCommand = function(self)
        local mouseOver = false
        local bg = self:GetChild("BG")
        self:SetUpdateFunction(function()
            --the function for setting the tooltip when hovered over the graph
            --this assumes the graph goes only from left to right, i.e. no lines go backwards
            if self:IsInvisible() then return end
            if isOver(bg) then
                mouseOver = true
                local absoluteMouseX = INPUTFILTER:GetMouseX()
                local absoluteMouseY = INPUTFILTER:GetMouseY()
                local mouseX = absoluteMouseX - bg:GetTrueX()
                local mouseY = absoluteMouseY - bg:GetTrueY()
                mouseX = math.floor(mouseX+0.5) --round
                mouseY = math.floor(mouseY + 0.5)
                local xValue = xValueFunc({x = mouseX,
                minXvalue = minXvalue,
                maxXvalue = maxXvalue,
                GraphWidth = actuals.GraphWidth
                })
                local yValueMouse = yValueFunc({y = mouseY,
                minYvalue = minYvalue,
                maxYvalue = maxYvalue,
                GraphHeight = actuals.GraphHeight
                })

                local function binarySearchExceptTheValueProbablyDoesntExist(t, v)
                    --given table t and value v, finds the index of the closest-lowest value in t
                    --basically index(floor(v)) but using only values in t
                    local l = 1
                    local r = #t
                    local i
                    while l <= r do
                        i = notShit.floor(((r-l)/2)+l)
                        if v < t[i] then
                            r = i - 1
                        elseif v > t[i] then
                            l = i + 1
                        else
                            return i
                        end
                    end
                    return r
                end

                local xt = {}
                for i=1, #values do
                    xt[#xt+1] = values[i][1]
                end
                --get the index of the data point to the left of the cursor
                local left = binarySearchExceptTheValueProbablyDoesntExist(xt, xValue)

                --values of data points either side of the cursor
                local leftXvalue = values[left][1]
                local rightXvalue = values[left+1][1]
                local leftYvalue = values[left][2]
                local rightYvalue = values[left+1][2]
                --linearly interpolate the y value
                local p = (xValue - leftXvalue) / (rightXvalue - leftXvalue)
                local yValue = leftYvalue + (p * (rightYvalue - leftYvalue))

                local xStr = xValueToStringFunc({xValue = xValue,
                GraphWidth = actuals.GraphWidth,
                GraphHeight = actuals.GraphHeight,
                minXvalue = minXvalue,
                maxXvalue = maxXvalue
                })

                local yStr = yValueToStringFunc({yValue = yValue,
                GraphWidth = actuals.GraphWidth,
                GraphHeight = actuals.GraphHeight,
                minYvalue = minYvalue,
                maxYvalue = maxYvalue
                })

                local tooltipStr = string.format("%s: %s\n%s: %s", xUnits, xStr, yUnits, yStr)
                TOOLTIP:SetText(tooltipStr)
                TOOLTIP:Show()
                self:GetChild("MouseHoverIndicator"):playcommand("MouseHover", {x = mouseX})
            else
                if mouseOver then
                    --do this so the tooltip isnt always being hidden
                    TOOLTIP:Hide()
                    self:GetChild("MouseHoverIndicator"):playcommand("MouseUnhover")
                    mouseOver = false
                end
            end
        end)
    end,

    Def.Quad{
        Name = "BG", 
        InitCommand = function(self)
            self:halign(0):valign(0)
            self:diffuse(bgColor)
            self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
        end
    },

    Def.ActorMultiVertex{
        Name = "Plots",
        InitCommand = function(self)
            self:diffusealpha(plotAlpha)
            self:playcommand("Set")
            self:SetLineWidth(lineThickness)
        end,
        SetCommand = function(self) --plots the points on the graph
            local vertices = {}
            local color
            local prevY
            for i = 1, #values do
                local x = xFunc({xValue = values[i][1],
                GraphWidth = actuals.GraphWidth,
                GraphHeight = actuals.GraphHeight,
                minXvalue = minXvalue,
                maxXvalue = maxXvalue
                })
                local y = yFunc({yValue = values[i][2],
                GraphWidth = actuals.GraphWidth,
                GraphHeight = actuals.GraphHeight,
                minYvalue = minYvalue,
                maxYvalue = maxYvalue
                })

                color = colorFunc({xValue = values[i][1], yValue = values[i][2]})
                placeLineVertices(vertices, x, y, color, i)
            end

            local function removeRedundantVertices(vertices)
                --removes all vertices that lie on a straight horizontal line, except the leftmost and rightmost points on said line
                --e.g. if a line is made of vertices *-*-*-*-*-* (where * represents a vertex)
                --the line after this function will look like *---------*
                --maybe I should update this to include lines of all angles, but thats really unlikely to happen so why bother
                local toRemove = {}
                local i = 2
                while i < #vertices-1 do --we dont want to remove the first or last ones
                    local current = vertices[i][1][2]
                    local prev = vertices[i-1][1][2]
                    local next_ = vertices[i+1][1][2]
                    if current == prev and current == next_ then
                        table.remove(vertices, i)
                    else
                        i = i + 1 --table.remove shifts all elements down to fill the empty space,
                        --so only incrament i if no elements have been shifted
                    end
                end
            end
            removeRedundantVertices(vertices)
            if self:GetNumVertices() ~= 0 then
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
            end
            self:SetVertices(vertices)

            self:SetDrawState({Mode = "DrawMode_LineStrip", First = 1, Num = #vertices})
        end,
    },

    Def.Quad{
        Name = "MouseHoverIndicator",
        InitCommand = function(self)
            self:diffuse(mouseHoverIndicatorColor)
            self:valign(0)
            self:zoomto(1, actuals.GraphHeight)
            self:diffusealpha(0)
        end,
        MouseHoverCommand = function(self, params)
            self:diffuse(mouseHoverIndicatorColor)
            self:x(params.x)
        end,
        MouseUnhoverCommand = function(self)
            self:diffusealpha(0)
        end,
    },
}


--axis labels

local XaxisLabelsContainer = Def.ActorFrame{
    Name = "XaxisLabelsContainer",
    InitCommand = function(self)
        self:y(actuals.GraphHeight + actuals.XaxisLabelOffset)
    end
}


for i=1, (xAxisLabelsCount) do
    XaxisLabelsContainer[#XaxisLabelsContainer+1] = Def.ActorFrame{
        Name = "XaxisLabel",
        InitCommand = function(self)
            self:x((((i-1)/(xAxisLabelsCount-1)) * actuals.GraphWidth))
        end,

        LoadFont("Common Normal") .. {
            Name = "XaxisLabelStr",
            InitCommand = function(self)
                self:valign(0)
                self:zoom(xAxisLabelTextSize)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local x = (((i-1)/(xAxisLabelsCount-1)) * actuals.GraphWidth) --for some reason using GetParent():GetX() doesnt work

                local xValue = xValueFunc({x = x,
                minXvalue = minXvalue,
                maxXvalue = maxXvalue,
                GraphWidth = actuals.GraphWidth
                })

                local xStr = xValueToStringFunc({xValue = xValue,
                GraphWidth = actuals.GraphWidth,
                GraphHeight = actuals.GraphHeight,
                minXvalue = minXvalue,
                maxXvalue = maxXvalue
                }) 
                self:settext(xStr)
                self:diffuse(xAxisLabelColorFunc({xValue = xValue}).text)
            end
        },

        Def.Quad{
            Name = "XaxisLabelOuterLine",
            InitCommand = function(self)
                self:valign(0)
                self:y(-actuals.XaxisLabelOffset)
                self:zoomto(actuals.XaxisLabelLineThickness, actuals.XaxisLabelOffset)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local x = (((i-1)/(xAxisLabelsCount-1)) * actuals.GraphWidth) --for some reason using GetParent():GetX() doesnt work

                local xValue = xValueFunc({x = x,
                minXvalue = minXvalue,
                maxXvalue = maxXvalue,
                GraphWidth = actuals.GraphWidth
                })

                self:diffuse(xAxisLabelColorFunc({xValue = xValue}).outerLine)
            end
        },

        Def.Quad{
            Name = "XaxisLabelInnerLine",
            InitCommand = function(self)
                self:valign(0)
                self:y(-(actuals.XaxisLabelOffset + actuals.GraphHeight))
                self:zoomto(actuals.XaxisLabelLineThickness, actuals.GraphHeight)
                self:diffuse(xAxisLabelInnerLineColor)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local x = (((i-1)/(xAxisLabelsCount-1)) * actuals.GraphWidth) --for some reason using GetParent():GetX() doesnt work

                local xValue = xValueFunc({x = x,
                minXvalue = minXvalue,
                maxXvalue = maxXvalue,
                GraphWidth = actuals.GraphWidth
                })

                self:diffuse(xAxisLabelColorFunc({xValue = xValue}).innerLine)
            end
        }
    }
end






local YaxisLabelsContainer = Def.ActorFrame{
    Name = "YaxisLabelsContainer",
    InitCommand = function(self)
        self:xy(-actuals.YaxisLabelOffset, actuals.GraphHeight)
    end
}


for i=1, (yAxisLabelsCount) do
    YaxisLabelsContainer[#YaxisLabelsContainer+1] = Def.ActorFrame{
        Name = "YaxisLabel",
        InitCommand = function(self)
            self:y(-((i-1)/(yAxisLabelsCount-1)) * actuals.GraphHeight)
        end,

        LoadFont("Common Normal") .. {
            Name = "YaxisLabelStr",
            InitCommand = function(self)
                self:halign(1)
                self:zoom(yAxisLabelTextSize)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                --for some reason using GetParent():GetY() doesnt work
                --i genuinely have no idea why +actuals.GraphHeight works, but it works
                local y = (-((i-1)/(yAxisLabelsCount-1)) * actuals.GraphHeight) + actuals.GraphHeight
                local yValue = yValueFunc({y = y,
                minYvalue = minYvalue,
                maxYvalue = maxYvalue,
                GraphHeight = actuals.GraphHeight
                })
                local yStr = yValueToStringFunc({yValue = yValue,
                GraphWidth = actuals.GraphWidth,
                GraphHeight = actuals.GraphHeight,
                minYvalue = minYvalue,
                maxYvalue = maxYvalue
                })
                self:settext(yStr)
                self:diffuse(yAxisLabelColorFunc({yValue = yValue}).text)
            end
        },

        Def.Quad{
            Name = "YaxisLabelOuterLine",
            InitCommand = function(self)
                self:halign(0)
                self:x(0)
                self:zoomto(actuals.YaxisLabelOffset, actuals.YaxisLabelLineThickness)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local y = (-((i-1)/(yAxisLabelsCount-1)) * actuals.GraphHeight) + actuals.GraphHeight --for some reason using GetParent():GetY() doesnt work

                local yValue = yValueFunc({y = y,
                minYvalue = minYvalue,
                maxYvalue = maxYvalue,
                GraphHeight = actuals.GraphHeight
                })

                self:diffuse(yAxisLabelColorFunc({yValue = yValue}).outerLine)
            end
        },

        Def.Quad{
            Name = "YaxisLabelInnerLine",
            InitCommand = function(self)
                self:halign(0)
                self:x(actuals.YaxisLabelOffset)
                self:zoomto(actuals.GraphWidth, actuals.YaxisLabelLineThickness)
                self:diffuse(yAxisLabelInnerLineColor)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local y = (-((i-1)/(yAxisLabelsCount-1)) * actuals.GraphHeight) + actuals.GraphHeight --for some reason using GetParent():GetY() doesnt work

                local yValue = yValueFunc({y = y,
                minYvalue = minYvalue,
                maxYvalue = maxYvalue,
                GraphHeight = actuals.GraphHeight
                })

                self:diffuse(yAxisLabelColorFunc({yValue = yValue}).innerLine)
            end
        }
    }
end

t[#t + 1] = XaxisLabelsContainer
t[#t + 1] = YaxisLabelsContainer

return t