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
--values is a table that appears like a 1-indexed array, where each item is a tuple {x, y} which is used to construct screen coordinates for a point
--the way screen coordinates are constructed is determined by xFunc and yFunc

--[[values must:
    be 1-indexed
    have all indexes as consecutive whole numbers
    e.g. values = {[1] = {0, 1}, [3] = {5, 7}} WILL NOT WORK because the index [2] is missing
]]
--just treat values as an array instead of a table

--e.g. values may be {[1] = {6, 7}, [2] = {67, 67}, [3] = {910, 21}}
--in this case, the resulting plot will contain 3 points. The first point will be made from the tuple in index [1], and so on
if Var("Values") == nil then
    return LoadFont("Common Normal") .. {
        InitCommand = function(self)
            self:settext("ERROR: VALUES IS NIL")
        end
    }
end
local values = Var("Values")

--get the min and max x and y values
local minXvalue = values[1][1] --smallest x value there is
local maxXvalue = 1
local minYvalue = values[1][2]
local maxYvalue = 1
for i = 1, #values do --todo: optimise this by sorting
    minXvalue = math.min(minXvalue, values[i][1])
    maxXvalue = math.max(maxXvalue, values[i][1])
    minYvalue = math.min(minYvalue, values[i][2])
    maxYvalue = math.max(maxYvalue, values[i][2])
end


--functions
local xFunc = Var("Xfunc") or function(params) return params.GraphWidth * ((params.xValue - params.minXvalue) / (params.maxXvalue - params.minXvalue)) end
--[[xFunc:
purpose: returns an x coordinate calculated from an x value. Inverse of xValueFunc.

inputs: 
xValue (point's value)
GraphWidth (total width of graph)
GraphHeight (total height of graph)
minXvalue (lowest x value a point may have)
maxXvalue (highest value a point may have)

returns: x coordinate of point
]]

local yFunc = Var("Yfunc") or function(params) return params.GraphHeight - ((params.GraphHeight * ((params.yValue - params.minYvalue)/ (params.maxYvalue - params.minYvalue)))) end  
--[[yFunc
purpose: returns a y coordinate calculated from a y value. Inverse of yValueFunc.

inputs: 
yValue (point's y value)
GraphWidth (total width of graph)
GraphHeight (total height of graph)
minYvalue (lowest y value a point may have)
maxYvalue (highest y value a point may have)

returns: y coordinate of point
]]

local colorFunc = Var("ColorFunc") or function(params) return color("#ffffff") end 
--[[colorFunc 
purpose: returns a color for a point, given that point's xValue and yValue

inputs: 
xValue (point's x value) 
yValue (point's y value)  

returns: color for the point
]]

local xValueToStringFunc = Var("XvalueToStringFunc") or function(params) return params.xValue end
--[[xValueToStringFunc 
purpose: returns a string representation of a given xValue

inputs:
xValue (point's x value)
GraphWidth (total width of graph)
GraphHeight (total height of graph)
minXvalue (lowest x value a point may have)
maxXvalue (highest x value a point may have)

returns: a string to label that point's x value
]]

local yValueToStringFunc = Var("YvalueToStringFunc") or function(params) return params.yValue end
--[[yValueToStringFunc 
purpose: returns a string representation of a given yValue

inputs:
yValue (point's y value)
GraphWidth (total width of graph)
GraphHeight (total height of graph)
minYvalue (lowest y value a point may have)
maxYvalue (highest y value a point may have)

returns: a string to label that point's y value
]]

local xValueFunc = Var("XvalueFunc") or function(params) return ((params.x / params.GraphWidth) * (params.maxXvalue - params.minXvalue)) + params.minXvalue end
--[[xValueFunc 
purpose: returns an x value calculated from an x coordinate. Inverse of xFunc.

inputs:
x (the x coordinate)
minXvalue (lowest x value a point may have)
maxXvalue (highest x value a point may have)
GraphWidth (total width of graph)

returns: the x value corresponding to the x coordinate
]]

local yValueFunc = Var("YvalueFunc") or function(params) return (((params.GraphHeight - params.y) / params.GraphHeight) * (params.maxYvalue - params.minYvalue)) + params.minYvalue end
--yValueFunc is the inverse of yFunc
--[[yValueFunc 
purpose: returns a y value calculated from a y coordinate. Inverse of yFunc.

inputs:
y (the y coordinate)
minXvalue (lowest y value a point may have)
maxXvalue (highest y value a point may have)
GraphHeight (total height of graph)

returns: the y value corresponding to the y coordinate
]]


actuals.GraphWidth = Var("GraphWidth") or ((680 / 1920) * SCREEN_WIDTH) --total width of graph
actuals.GraphHeight = Var("GraphHeight") or ((412 / 1080) * SCREEN_HEIGHT) --total height of graph
actuals.XaxisLabelsOffset = Var("XaxisLabelsOffset") or ((20 / 1920) * SCREEN_WIDTH) --how far left the x axis label is from the y axis
actuals.YaxisLabelsOffset = Var("YaxisLabelsOffset") or ((20 / 1080) * SCREEN_HEIGHT) --how far down the y axis label is from the x axis
actuals.XaxisLabelLineThickness = Var("XaxisLabelLineThickness") or ((1 / 1920) * SCREEN_WIDTH) --how thick the x axis label is
actuals.YaxisLabelLineThickness = Var("YaxisLabelLineThickness") or ((1 / 1080) * SCREEN_HEIGHT) --how thick the y axis label is


local bgColor = Var("BGcolor") or color("#000000A2") --color of bg quad
local xAxisLabelOuterLineColor = Var("XaxisLabelOuterLineColor") or color("#ffffff")
local xAxisLabelInnerLineColor = Var("XaxisLabelInnerLineColor") or color("#ffffff")
local yAxisLabelOuterLineColor = Var("YaxisLabelOuterLineColor") or color("#ffffff")
local yAxisLabelInnerLineColor = Var("XaxisLabelInnerLineColor") or color("#ffffff")
local plotAlpha = Var("PlotAlpha") or 1 --alpha of plot
local xAxisLabelTextSize = Var("XaxisLabelTextSize") or 0.5 --size of x axis label text
local yAxisLabelTextSize = Var("YaxisLabelTextSize") or 0.5 --size of y axis label text
local plotAnimationSeconds = Var("PlotAnimationSeconds") or 1 --tween time of plot
local plotWidth = Var("PlotWidth") or 2 --width of a single point
local plotHeight = Var("PlotHeight") or 2 --height of a single point
local xUnits = Var("Xunits") or "X" --units of measurement the x axis is in, e.g. MSD, time, etc.
local yUnits = Var("Yunits") or "Y" --units of measurement the y axis is in

local xAxisLabelsCount = 1
local xAxisLabelsScale = 1
local yAxisLabelsCount = 1
local yAxisLabelsScale = 1


--you can either pick labelsScale or labelsCount, not both
if Var("XaxisLabelsScale") then
    xAxisLabelsScale = Var("XaxisLabelsScale") or 1 --the scale of the x axis labels
    maxXvalue = (math.floor(maxXvalue / xAxisLabelsScale) + 1) * xAxisLabelsScale --round maxXvalue up to the next x axis label, so the graph will have a label at the right
    --this is only needed if a scale is entered instead of a count
    xAxisLabelsCount = ((maxXvalue - minXvalue) / xAxisLabelsScale) + 1
else
    xAxisLabelsCount = Var("XaxisLabelsCount") or 1 --how many x axis labels there are
    xAxisLabelsScale = (maxXvalue - minXvalue) / (xAxisLabelsCount - 1) 
end

if Var("YaxisLabelsScale") then
    yAxisLabelsScale = Var("YaxisLabelsScale") or 1 --the scale of y axis labels
    maxYvalue = (math.floor(maxYvalue / yAxisLabelsScale) + 1) * yAxisLabelsScale --round maxYvalue up to the nearest y axis label, so the graph will have a label at the top
    yAxisLabelsCount = ((maxYvalue - minYvalue) / yAxisLabelsScale) + 1
else
    yAxisLabelsCount = Var("YaxisLabelsCount") or 1 --how many y axis labels there are
    yAxisLabelsScale = (maxYvalue - minYvalue) / (yAxisLabelsCount - 1) 
end


-----------------------------------------------------end of params-----------------------------------------------------


-- 4 xyz coordinates are given to make up the 4 corners of a quad to draw
local function placeDotVertices(vertList, x, y, color)
    vertList[#vertList + 1] = {{x - (plotWidth/2), y + (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x + (plotWidth/2), y + (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x + (plotWidth/2), y - (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x - (plotWidth/2), y - (plotHeight/2), 0}, color}
end


local t = Def.ActorFrame{
    Name = "Graph",

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
        end,

        SetCommand = function(self) --plots the points on the graph
            local vertices = {}
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

                local color = colorFunc({xValue = values[i][1], yValue = values[i][2]})
                placeDotVertices(vertices, x, y, color)
            end
            if self:GetNumVertices() ~= 0 then
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
            end
            self:SetVertices(vertices)
            self:SetDrawState {Mode = "DrawMode_Quads", First = 1, Num = #vertices}
        end,

    },


    UIElements.TextToolTip(1, 1, "Common Normal") .. {
        Name = "DisplayXY",
        InitCommand = function(self)
            local mouseOver = false
            self:halign(0):valign(0)
            self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
            self:diffusealpha(1)
            
        end,

        MouseOverCommand = function(self)
            if self:GetParent():GetParent().focused and not self:IsInvisible() then
                self.mouseOver = true
                self:queuecommand("DisplayMouseCoords")
            end
            
        end,

        MouseOutCommand = function(self)
            self.mouseOver = false
            TOOLTIP:Hide()
        end,

        DisplayMouseCoordsCommand = function(self, params)
            if self.mouseOver then
                local absoluteMouseX = INPUTFILTER:GetMouseX()
                local absoluteMouseY = INPUTFILTER:GetMouseY()

                local mouseX = absoluteMouseX - self:GetTrueX()
                local mouseY = absoluteMouseY - self:GetTrueY()
                mouseX = math.floor(mouseX+0.5) --round
                mouseY = math.floor(mouseY + 0.5)

                local xValue = xValueFunc({x = mouseX,
                minXvalue = minXvalue,
                maxXvalue = maxXvalue,
                GraphWidth = actuals.GraphWidth
                })

                local yValue = yValueFunc({y = mouseY,
                minYvalue = minYvalue,
                maxYvalue = maxYvalue,
                GraphHeight = actuals.GraphHeight
                })

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
                self:sleep(0.05)
                self:queuecommand("DisplayMouseCoords")
            end
        end
    }
}


--axis labels

local XaxisLabelsContainer = Def.ActorFrame{
    Name = "XaxisLabelsContainer",
    InitCommand = function(self)
        self:y(actuals.GraphHeight + actuals.XaxisLabelsOffset)
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
            end
        },

        Def.Quad{
            Name = "XaxisLabelOuterLine",
            InitCommand = function(self)
                self:valign(0)
                self:y(-actuals.XaxisLabelsOffset)
                self:zoomto(actuals.XaxisLabelLineThickness, actuals.XaxisLabelsOffset)
                self:diffuse(xAxisLabelOuterLineColor)
            end
        },

        Def.Quad{
            Name = "XaxisInnerLine",
            InitCommand = function(self)
                self:valign(0)
                self:y(-(actuals.XaxisLabelsOffset + actuals.GraphHeight))
                self:zoomto(actuals.XaxisLabelLineThickness, actuals.GraphHeight)
                self:diffuse(xAxisLabelInnerLineColor)
            end
        }
    }
end






local YaxisLabelsContainer = Def.ActorFrame{
    Name = "YaxisLabelsContainer",
    InitCommand = function(self)
        self:xy(-actuals.YaxisLabelsOffset, actuals.GraphHeight)
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
            end
        },

        Def.Quad{
            Name = "YaxisLabelLineThatsOutsideOfTheGraph",
            InitCommand = function(self)
                self:halign(0)
                self:x(0)
                self:zoomto(actuals.YaxisLabelsOffset, actuals.YaxisLabelLineThickness)
                self:diffuse(yAxisLabelOuterLineColor)
            end
        },

        Def.Quad{
            Name = "YaxisLabelLineThatsInsideTheGraph",
            InitCommand = function(self)
                self:halign(0)
                self:x(actuals.YaxisLabelsOffset)
                self:zoomto(actuals.GraphWidth, actuals.YaxisLabelLineThickness)
                self:diffuse(yAxisLabelInnerLineColor)
            end
        }
    }
end

t[#t + 1] = XaxisLabelsContainer
t[#t + 1] = YaxisLabelsContainer

return t