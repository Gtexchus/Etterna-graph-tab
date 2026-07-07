local ratios = {}

local actuals = {}

-----------------------------------------------------params-----------------------------------------------------

--values is the only thing that MUST be passed in (how do you expect me to make a graph with no values?)
--values is a table that appears like a 1-indexed array, where each item at index i is a number n which is used to calculate the height of the i'th bar
--the way height is calculated is determined by yFunc

--[[values must:
    be 1-indexed
    have all indexes as consecutive whole numbers
    e.g. values = {[1] = 6, [3] = 7} WILL NOT WORK because the index [2] is missing
]]
--just treat values as an array instead of a table

--e.g. values may be {[1] = 6, [2] = 7, [3] = 67}
--in this case, the resulting plot will contain 3 bars. The height of the first bar will be calculated from the number 6, and so on
if Var("Values") == nil then
    return Def.ActorFrame{
        LoadFont("Common Normal") .. {
            InitCommand = function(self) --return an actorframe with a nice error message if there are no values passed in
                self:settext("ERROR: VALUES IS NIL")
            end
        }
    }
end
local values = Var("Values")


--functions
local yFunc = Var("Yfunc") or function(params) return params.GraphHeight - ((params.GraphHeight * (params.value/ params.maxValue))) end  
--[[yFunc
purpose: returns a y coordinate calculated from a bar's value.

params: 
value [number] (bar's value)
GraphWidth [number] (total width of graph)
GraphHeight [number] (total height of graph)
minYvalue [number] (lowest y value a point may have)
maxYvalue [number] (highest y value a point may have)

returns: number (y coordinate of point)
]]

local colorFunc = Var("ColorFunc") or function(params) return color("#ffffff") end 
--[[colorFunc 
purpose: returns a color for a bar, given that bar's number and value

params: 
barNum [number] (bar's number) 
value [number] (bar's value)  

returns: color (color for the point)
]]

local barNumToStringFunc = Var("BarNumToStringFunc") or function(params) return params.barNum end 
--[[barNumToStringFunc 
purpose: returns a string representation of a bar's number

params:
barNum [number] (bar's number) 
 
returns: string (string representation of barNum)
]]


actuals.GraphWidth = Var("GraphWidth") or ((680 / 1920) * SCREEN_WIDTH) --total width of graph
actuals.GraphHeight = Var("GraphHeight") or ((412 / 1080) * SCREEN_HEIGHT) --total height of graph
actuals.TopLabelVerticalOffset = Var("TopLabelVerticalOffset") or ((25 / 1080) * SCREEN_HEIGHT) --how far above the bar the top label is
actuals.BottomLabelVerticalOffset = Var("BottomLabelVerticalOffset") or ((10 / 1080) * SCREEN_HEIGHT) --how far below the bar the bottom label is

--you can either pick barWidth or barSpacing, not both
if Var("BarWidth") then
    actuals.BarWidth = Var("BarWidth") or 1 --width of bar
    actuals.BarSpacing = (actuals.GraphWidth - ((#values) * actuals.BarWidth)) / (#values - 1)
else
    actuals.BarSpacing = Var("BarSpacing") or 1 --how far apart each bar is
    actuals.BarWidth = (actuals.GraphWidth - (actuals.BarSpacing * (#values - 1))) / #values
end


local bgColor = Var("BGcolor") or color("#000000A2") --color of bg quad
local plotAlpha = Var("PlotAlpha") or 1 --alpha of plot
local topLabelTextSize = Var("TopLabelTextSize") or 0.5 --size of top label
local bottomLabelTextSize = Var("BottomLabelTextSize") or 0.5 --size of bottom label
local topLabelDefaultAlpha = Var("TopLabelDefaultAlpha") or 1 --alpha of top label when not hovered
local topLabelHoverAlpha = Var("TopLabelHoverAlpha") or 1 --alpha of top label when hovered
local bottomLabelDefaultAlpha = Var("BottomLabelDefaultAlpha") or 1 --alpha of bottom label when not hovered
local bottomLabelHoverAlpha = Var("BottomLabelHoverAlpha") or 1 --alpha of bottom label when hovered
local plotAnimationSeconds = Var("PlotAnimationSeconds") or 1 --tween time of plot


-----------------------------------------------------end of params-----------------------------------------------------

local function placeBarVerticesTopLeftAnchor(vertList, x, y, w, h, color)
    vertList[#vertList + 1] = {{x, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y, 0}, color}
    vertList[#vertList + 1] = {{x, y, 0}, color}
end

--table of {x, y} values, storing the top left corner of each bar
--this is so we can easily draw the text above each bar
local barCoords = {}

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

        SetCommand = function(self)
            local vertices = {}
            local maxValue = 0

            --we cant just do barcoords = {0, 0} etc. due to how lua works
            for i = 1, #barCoords do
                table.remove(barCoords, 1)
            end

            for i = 1, #values do
                maxValue = math.max(maxValue, values[i])
            end

            for i = 1, #values do
                local x = (i-1) * (actuals.BarWidth + actuals.BarSpacing)
                local y = yFunc({
                    value = values[i],
                    GraphWidth = actuals.GraphWidth,
                    GraphHeight = actuals.GraphHeight,
                    maxValue = maxValue,
                })
                local height = actuals.GraphHeight - y
                local color = colorFunc({barNum = i, 
                value = values[i]})
                barCoords[#barCoords + 1] = {x, y}
                placeBarVerticesTopLeftAnchor(vertices, x, y, actuals.BarWidth, height, color)
            end

            if self:GetNumVertices() ~= 0 then
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
            end
            self:SetVertices(vertices)
            self:SetDrawState {Mode = "DrawMode_Quads", First = 1, Num = #vertices}
        end,
    }
}
    

local function makeLabel(i)
    return Def.ActorFrame{
        Name = "Label",

        InitCommand = function(self)
            local plots = self:GetParent():GetParent():GetChild("Plots")
            self:x(plots:GetX() + barCoords[i][1] + (actuals.BarWidth / 2))
        end,

        UIElements.QuadButton(1, 1) .. {
            InitCommand = function(self)
                self:valign(0)
                self:diffusealpha(0)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                self:zoomto(actuals.BarWidth, actuals.GraphHeight)
            end,
            MouseOverCommand = function(self)
                local topLabel = self:GetParent():GetChild("TopLabel")
                local bottomLabel = self:GetParent():GetChild("BottomLabel")
                topLabel:diffusealpha(topLabelHoverAlpha)
                bottomLabel:diffusealpha(bottomLabelHoverAlpha)
            end,

            MouseOutCommand = function(self)
                local topLabel = self:GetParent():GetChild("TopLabel")
                local bottomLabel = self:GetParent():GetChild("BottomLabel")
                topLabel:diffusealpha(topLabelDefaultAlpha)
                bottomLabel:diffusealpha(bottomLabelDefaultAlpha)
            end,
        },

        LoadFont("Common Normal") .. {
            --scorecount for each grade and percentage that goes above each bar
            Name = "TopLabel",
            InitCommand = function(self)
                self:zoom(topLabelTextSize)
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                --we need to set the xy here so it doesnt tween in from (0,0) and look weird
                self:y(plots:GetY() + barCoords[i][2] - actuals.TopLabelVerticalOffset)
                self:diffusealpha(topLabelDefaultAlpha)
                self:playcommand("Set")
            end,


            SetCommand = function(self)
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
                local total = 0
                for j = 1, #values do
                    local value = 0
                    if values[j] ~= nil then 
                        value = values[j]
                    end
                    total = total + value
                end
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                self:y(plots:GetY() + barCoords[i][2] - actuals.TopLabelVerticalOffset)
                local value = 0
                if values[i] ~= nil then 
                    value = values[i]
                end
                self:settextf("%s \n (%4.2f%s)", value, (value / total) * 100, "%")
            end
        },

        LoadFont("Common Normal") .. {
            --grade text that goes under the bar
            Name = "BottomLabel",
            InitCommand = function(self)
                self:zoom(bottomLabelTextSize)
                self:valign(0)
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                self:y(plots:GetY() + actuals.GraphHeight + actuals.BottomLabelVerticalOffset)
                
                self:settext(barNumToStringFunc({barNum = i})) 
                self:diffuse(colorFunc({barNum = i, 
                value = values[i]}))
                self:diffusealpha(bottomLabelDefaultAlpha)
            end,
        }
    }
    
end

local labels = Def.ActorFrame{
    Name = "LabelsContainer"
}

for i = 1, #values do --make the graph labels
    labels[#labels + 1] = makeLabel(i)
end

t[#t + 1] = labels



return t
