--params that are passed in:
--barWidth OR barSpacing
--table of values
--function to calc y from values
--function to calc color from values
--function to calc label below bar from index
--graphWidth
--graphHeight
--bgColor
--plotAlpha
--barCoords
local ratios = {}

local actuals = {}
local plotAnimationSeconds = 1


--things that must be passed in
--variables
--local barCoords = Var("BarCoords")
local values = Var("Values")
--functions
local yFunc = Var("Yfunc") --calculates y coord from values[i]
local colorFunc = Var("ColorFunc") --has params (index, value) because the color could be made from either
local barLabelStrFunc = Var("BarLabelStrFunc") --returns text from i


--things that may be passed in
actuals.GraphWidth = Var("GraphWidth") or ((680 / 1920) * SCREEN_WIDTH)
actuals.GraphHeight = Var("GraphHeight") or ((412 / 1080) * SCREEN_HEIGHT)
actuals.TopLabelVerticalOffset = Var("TopLabelVerticalOffset") or ((25 / 1080) * SCREEN_HEIGHT)
actuals.BottomLabelVerticalOffset = Var("BottomLabelVerticalOffset") or ((10 / 1080) * SCREEN_HEIGHT)

if Var("BarWidth") then
    actuals.BarWidth = Var("BarWidth") or 1
    actuals.BarSpacing = (actuals.GraphWidth - ((#values) * actuals.BarWidth)) / (#values - 1)
else
    actuals.BarSpacing = Var("BarSpacing") or 1
    actuals.BarWidth = (actuals.GraphWidth - (actuals.BarSpacing * (#values - 1))) / #values
end


local bgColor = Var("BGcolor") or color("#000000A2")
local plotAlpha = Var("PlotAlpha") or 1
local labelTextSize = Var("LabelTextSize") or 0.5
local topLabelDefaultAlpha = Var("TopLabelDefaultAlpha") or 1
local topLabelHoverAlpha = Var("TopLabelHoverAlpha") or 1
local bottomLabelDefaultAlpha = Var("BottomLabelDefaultAlpha") or 1
local bottomLabelHoverAlpha = Var("BottomLabelHoverAlpha") or 1







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
            local maxY = 0

            --we cant just do barcoords = {0, 0} etc. due to how lua works
            for i = 1, #barCoords do
                table.remove(barCoords, 1)
            end

            for i = 1, #values do
                maxY = math.max(maxY, values[i])
            end

            for i = 1, #values do
                local x = (i-1) * (actuals.BarWidth + actuals.BarSpacing)
                local y = yFunc({
                    value = values[i],
                    GraphWidth = actuals.GraphWidth,
                    GraphHeight = actuals.GraphHeight,
                    maxY = maxY,
                })
                local height = actuals.GraphHeight - y
                local color = colorFunc(i, values[i])
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
                self:y(barCoords[i][2])
                self:zoomto(actuals.BarWidth, actuals.GraphHeight - barCoords[i][2])
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
                self:zoom(labelTextSize)
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
                self:zoom(labelTextSize)
                self:valign(0)
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                self:y(plots:GetY() + actuals.GraphHeight + actuals.BottomLabelVerticalOffset)
                
                self:settext(barLabelStrFunc(i)) 
                self:diffuse(colorFunc(i, values[i]))
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
