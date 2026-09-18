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
local xFunc = Var("Xfunc") or function(params) return params.GraphLength * ((params.value - params.minValue) / (params.maxValue - params.minValue)) end
--[[xFunc:
purpose: returns an x coordinate calculated from an x value. Inverse of xValueFunc.

params: 
value [number] (point's value)
GraphLength [number] (total width of graph)
minValue [number] (lowest x value a point may have)
maxValue [number] (highest value a point may have)

returns: number (x coordinate of point)
]]

local yFunc = Var("Yfunc") or function(params) return params.GraphLength * ((params.value - params.minValue)/ (params.maxValue - params.minValue)) end  
--[[yFunc
purpose: returns a y coordinate calculated from a y value. Inverse of yValueFunc.

params: 
value [number] (point's y value)
GraphLength [number] (total height of graph)
minValue [number] (lowest y value a point may have)
maxValue [number] (highest y value a point may have)

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

local xAxisLabelColorFunc = Var("XaxisLabelColorFunc") or function(params) return color("#ffffff") end
--[[xAxisLabelColorFunc
purpose: colors all parts of the x axis label (text, outer line, inner line)

params:
value [number] (label's x value)

returns: color
]]

local yAxisLabelColorFunc = Var("YaxisLabelColorFunc") or function(params) return color("#ffffff") end
--[[yAxisLabelColorFunc
purpose: colors all parts of the y axis label (text, outer line, inner line)

params:
value [number] (label's y value)

returns: color
]]

local xValueToStringFunc = Var("XvalueToStringFunc") or function(params) return tostring(params.value) end
--[[xValueToStringFunc 
purpose: returns a string representation of a given xValue

params:
value [number] (point's x value)
GraphLength [number] (total width of graph)
minValue [number] (lowest x value a point may have)
maxValue [number] (highest x value a point may have)

returns: string (string representation of xValue) 
]]

local yValueToStringFunc = Var("YvalueToStringFunc") or function(params) return tostring(params.value) end
--[[yValueToStringFunc 
purpose: returns a string representation of a given yValue

params:
value [number] (point's y value)
GraphLength [number] (total height of graph)
minValue [number] (lowest y value a point may have)
maxValue [number] (highest y value a point may have)

returns: string (string representation of yValue)
]]

local xValueFunc = Var("XvalueFunc") or function(params) return ((params.coord / params.GraphLength) * (params.maxValue - params.minValue)) + params.minValue end
--[[xValueFunc 
purpose: returns an x value calculated from an x coordinate. Inverse of xFunc.

params:
coord [number] (the x coordinate)
minValue [number] (lowest x value a point may have)
maxValue [number] (highest x value a point may have)
GraphLength [number] (total width of graph)

returns: number (the x value corresponding to the x coordinate)
]]

local yValueFunc = Var("YvalueFunc") or function(params) return ((params.coord / params.GraphLength) * (params.maxValue - params.minValue)) + params.minValue end
--[[yValueFunc 
purpose: returns a y value calculated from a y coordinate. Inverse of yFunc.

params:
coord [number] (the y coordinate)
minValue [number] (lowest y value a point may have)
maxValue [number] (highest y value a point may have)
GraphLength [number] (total height of graph)

returns: number (the y value corresponding to the y coordinate)
]]

local minXvalueFunc = Var("MinXvalueFunc") or function(params) return math.min(params.minValue, params.value) end
--[[minXvalueFunc
purpose: returns an updated minXvalue given the current minXvalue and an xValue

params:
minValue [number] (the current minXvalue)
value [number] (an xValue)

returns: number (an updated minXvalue)
]]

local maxXvalueFunc = Var("MaxXvalueFunc") or function(params) return math.max(params.maxValue, params.value) end

local minYvalueFunc = Var("MinYvalueFunc") or function(params) return math.min(params.minValue, params.value) end

local maxYvalueFunc = Var("MaxYvalueFunc") or function(params) return math.max(params.maxValue, params.value) end


actuals.GraphWidth = Var("GraphWidth") or ((680 / 1920) * SCREEN_WIDTH) --total width of graph
actuals.GraphHeight = Var("GraphHeight") or ((412 / 1080) * SCREEN_HEIGHT) --total height of graph
actuals.XaxisLabelOffset = Var("XaxisLabelOffset") or ((20 / 1080) * SCREEN_HEIGHT) --how far down the x axis label is from the x axis
actuals.YaxisLabelOffset = Var("YaxisLabelOffset") or ((20 / 1920) * SCREEN_WIDTH) --how far left the y axis label is from the y axis
actuals.XaxisLabelLineThickness = Var("XaxisLabelLineThickness") or ((1 / 1920) * SCREEN_WIDTH) --how thick the x axis label is
actuals.YaxisLabelLineThickness = Var("YaxisLabelLineThickness") or ((1 / 1080) * SCREEN_HEIGHT) --how thick the y axis label is


--get the min and max x and y values
local minXvalue = values[1][1] --smallest x value there is
local maxXvalue = values[1][1]
local minYvalue = values[1][2]
local maxYvalue = values[1][2]

for i = 1, #values do 
    minXvalue = minXvalueFunc({minValue = minXvalue, value = values[i][1]})
    maxXvalue = maxXvalueFunc({maxValue = maxXvalue, value = values[i][1]})
    minYvalue = minYvalueFunc({minValue = minYvalue, value = values[i][2]})
    maxYvalue = maxYvalueFunc({maxValue = maxYvalue, value = values[i][2]})
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
local plotAlpha = Var("PlotAlpha") or 1 --alpha of plot
local xAxisLabelInnerLineAlpha = Var("XaxisLabelInnerLineAlpha") or 0.2
local yAxisLabelInnerLineAlpha = Var("YaxisLabelInnerLineAlpha") or 0.2
local xAxisLabelTextSize = Var("XaxisLabelTextSize") or 0.5 --size of x axis label text
local yAxisLabelTextSize = Var("YaxisLabelTextSize") or 0.5 --size of y axis label text
local xAxisLabelTextMaxWidth = Var("XaxisLabelTextMaxWidth") or 500 --max width of x axis label text
local yAxisLabelTextMaxWidth = Var("YaxisLabelTextMaxWidth") or 500 --max width of y axis label text
local plotAnimationSeconds = Var("PlotAnimationSeconds") or 1 --tween time of plot
local dotWidth = Var("DotWidth") or 2 --width of a single point
local dotHeight = Var("DotHeight") or 2 --height of a single point
local xUnits = Var("Xunits") or "X" --units of measurement the x axis is in, e.g. MSD, time, etc.
local yUnits = Var("Yunits") or "Y" --units of measurement the y axis is in

local xAxisLabelsCount = 1
local xAxisLabelScale = 1
local yAxisLabelsCount = 1
local yAxisLabelScale = 1


local maxNumOfAxisLabelsWhenRounding = 10 --should this be a param?

--you can either pick labelsScale or labelsCount, not both
if Var("XaxisLabelScale") then
    xAxisLabelScale = Var("XaxisLabelScale") or 1 --the scale of the x axis labels
    minXvalue = notShit.floor(minXvalue / xAxisLabelScale) * xAxisLabelScale --round minXvalue down to the closest x axis label
    maxXvalue = ((notShit.floor(maxXvalue  / xAxisLabelScale) + 1) * xAxisLabelScale)--round maxXvalue up to the next x axis label
    --this is only needed if a scale is entered instead of a count
    xAxisLabelsCount = ((maxXvalue - minXvalue) / xAxisLabelScale) + 1
elseif Var("XaxisLabelRound") then
    --this code is highkey DOGSHIT but i dont even care at this point
    local xAxisLabelRound = Var("XaxisLabelRound")
    xAxisLabelScale = notShit.floor((((maxXvalue - minXvalue)/maxNumOfAxisLabelsWhenRounding) / xAxisLabelRound) + 1) * xAxisLabelRound
    minXvalue = notShit.floor(minXvalue / xAxisLabelScale) * xAxisLabelScale --round minXvalue down to the closest x axis label
    maxXvalue = ((notShit.floor(maxXvalue  / xAxisLabelScale) + 1) * xAxisLabelScale)--round maxXvalue up to the next x axis label
    xAxisLabelsCount = ((maxXvalue - minXvalue) / xAxisLabelScale) + 1
else
    xAxisLabelsCount = Var("XaxisLabelCount") or 1 --how many x axis labels there are
    xAxisLabelScale = (maxXvalue - minXvalue) / (xAxisLabelsCount - 1) 
end

if Var("YaxisLabelScale") then
    yAxisLabelScale = Var("YaxisLabelScale") or 1 --the scale of y axis labels
    minYvalue = notShit.floor(minYvalue / yAxisLabelScale) * yAxisLabelScale--round minYvalue down to the closest y axis label
    maxYvalue = ((notShit.floor(maxYvalue / yAxisLabelScale) + 1) * yAxisLabelScale)--round maxYvalue up to the nearest y axis label
    yAxisLabelsCount = ((maxYvalue - minYvalue) / yAxisLabelScale) + 1
elseif Var("YaxisLabelRound") then
    --copy and pasting code is my passion
    local yAxisLabelRound = Var("YaxisLabelRound")
    yAxisLabelScale = notShit.floor((((maxYvalue - minYvalue)/maxNumOfAxisLabelsWhenRounding) / yAxisLabelRound) + 1) * yAxisLabelRound
    minYvalue = notShit.floor(minYvalue / yAxisLabelScale) * yAxisLabelScale--round minYvalue down to the closest y axis label
    maxYvalue = ((notShit.floor(maxYvalue / yAxisLabelScale) + 1) * yAxisLabelScale)--round maxYvalue up to the nearest y axis label
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


-- 4 xyz coordinates are given to make up the 4 corners of a quad to draw
local function placeDotVertices(vertList, x, y, color)
    vertList[#vertList + 1] = {{x - (dotWidth/2), y + (dotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x + (dotWidth/2), y + (dotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x + (dotWidth/2), y - (dotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x - (dotWidth/2), y - (dotHeight/2), 0}, color}
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
                local x = xFunc({value = values[i][1],
                GraphLength = actuals.GraphWidth,
                minValue = minXvalue,
                maxValue = maxXvalue
                })

                local y = actuals.GraphHeight - yFunc({value = values[i][2],
                GraphLength = actuals.GraphHeight,
                minValue = minYvalue,
                maxValue = maxYvalue
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
            if not self:IsInvisible() then
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

                local xValue = xValueFunc({coord = mouseX,
                minValue = minXvalue,
                maxValue = maxXvalue,
                GraphLength = actuals.GraphWidth
                })

                local yValue = yValueFunc({coord = actuals.GraphHeight - mouseY,
                minValue = minYvalue,
                maxValue = maxYvalue,
                GraphLength = actuals.GraphHeight
                })

                local xStr = xValueToStringFunc({value = xValue,
                GraphLength = actuals.GraphWidth,
                minValue = minXvalue,
                maxValue = maxXvalue
                })

                local yStr = yValueToStringFunc({value = yValue,
                GraphLength = actuals.GraphHeight,
                minValue = minYvalue,
                maxValue = maxYvalue
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

                local xValue = xValueFunc({coord = x,
                minValue = minXvalue,
                maxValue = maxXvalue,
                GraphLength = actuals.GraphWidth
                })

                local xStr = xValueToStringFunc({value = xValue,
                GraphLength = actuals.GraphWidth,
                minValue = minXvalue,
                maxValue = maxXvalue
                }) 
                self:settext(xStr)
                self:diffuse(xAxisLabelColorFunc({value = xValue}))
                self:maxwidth(xAxisLabelTextMaxWidth)
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

                local xValue = xValueFunc({coord = x,
                minValue = minXvalue,
                maxValue = maxXvalue,
                GraphLength = actuals.GraphWidth
                })

                self:diffuse(xAxisLabelColorFunc({value = xValue}))
            end
        },

        Def.Quad{
            Name = "XaxisLabelInnerLine",
            InitCommand = function(self)
                self:valign(0)
                self:y(-(actuals.XaxisLabelOffset + actuals.GraphHeight))
                self:zoomto(actuals.XaxisLabelLineThickness, actuals.GraphHeight)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local x = (((i-1)/(xAxisLabelsCount-1)) * actuals.GraphWidth) --for some reason using GetParent():GetX() doesnt work

                local xValue = xValueFunc({coord = x,
                minValue = minXvalue,
                maxValue = maxXvalue,
                GraphLength = actuals.GraphWidth
                })

                self:diffuse(xAxisLabelColorFunc({value = xValue}))
                self:diffusealpha(xAxisLabelInnerLineAlpha)
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
                local yValue = yValueFunc({coord = actuals.GraphHeight - y,
                minValue = minYvalue,
                maxValue = maxYvalue,
                GraphLength = actuals.GraphHeight
                })
                local yStr = yValueToStringFunc({value = yValue,
                GraphLength = actuals.GraphHeight,
                minValue = minYvalue,
                maxValue = maxYvalue
                })
                self:settext(yStr)
                self:diffuse(yAxisLabelColorFunc({value = yValue}))
                self:maxwidth(yAxisLabelTextMaxWidth)
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

                local yValue = yValueFunc({coord = actuals.GraphHeight - y,
                minValue = minYvalue,
                maxValue = maxYvalue,
                GraphLength = actuals.GraphHeight
                })

                self:diffuse(yAxisLabelColorFunc({value = yValue}))
            end
        },

        Def.Quad{
            Name = "YaxisLabelInnerLine",
            InitCommand = function(self)
                self:halign(0)
                self:x(actuals.YaxisLabelOffset)
                self:zoomto(actuals.GraphWidth, actuals.YaxisLabelLineThickness)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local y = (-((i-1)/(yAxisLabelsCount-1)) * actuals.GraphHeight) + actuals.GraphHeight --for some reason using GetParent():GetY() doesnt work

                local yValue = yValueFunc({coord = actuals.GraphHeight - y,
                minValue = minYvalue,
                maxValue = maxYvalue,
                GraphLength = actuals.GraphHeight
                })

                self:diffuse(yAxisLabelColorFunc({value = yValue}))
                self:diffusealpha(yAxisLabelInnerLineAlpha)
            end
        }
    }
end

t[#t + 1] = XaxisLabelsContainer
t[#t + 1] = YaxisLabelsContainer

return t