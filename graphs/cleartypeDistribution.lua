local smallButtonTextSize = 0.5
local labelTextSize = 0.4
local headerTextSize = 1
local skillsetButtonsMaxWidth = 100
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6
local plotAlpha = 1
local plotAnimationSeconds = 1
local maxSkillsetButtonsPerColumn = 4
local XaxisScale = 1 --make this either an integer or a fractional power of 2 otherwise it will break due to floating point BS


local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphYPadding = 100 / 1080, --distance from x axis to bottom of container
    GraphXPadding = 50 / 1920, --distance from y axis to left of container
    BarWidth = 30 / 1920,
    LabelAboveBarVerticalOffset = 25 / 1080,
    LabelBelowBarVerticalOffset = 10 / 1080,
    SkillsetButtonsX = 640 / 1920,
    SkillsetButtonsY = 20 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
}
ratios.GraphX = ratios.GraphXPadding
ratios.GraphY = ratios.GraphYPadding
ratios.GraphWidth = ratios.Width - (ratios.GraphXPadding * 2)
ratios.GraphHeight = ratios.Height - (ratios.GraphYPadding * 2)
ratios.GraphBottom = ratios.GraphY + ratios.GraphHeight

ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 20 / 1080


local actuals = {
    GraphYPadding = ratios.GraphYPadding * SCREEN_HEIGHT,
    GraphXPadding = ratios.GraphXPadding * SCREEN_WIDTH,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    GraphBottom = ratios.GraphBottom * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
    GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH,
    GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT,
    LabelAboveBarVerticalOffset = ratios.LabelAboveBarVerticalOffset * SCREEN_HEIGHT,
    LabelBelowBarVerticalOffset = ratios.LabelBelowBarVerticalOffset * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
}


local function placeBarVerticesTopLeftAnchor(vertList, x, y, w, h, color)
    vertList[#vertList + 1] = {{x, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y, 0}, color}
    vertList[#vertList + 1] = {{x, y, 0}, color}
end


local function setCleartypeCounts(cleartypeCounts)
    for i=1, #cleartypeCounts do
        cleartypeCounts[i] = 0
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local txt = getClearTypeFromScore(score, 0)
            local index = getClearTypeIndexFromValue(txt)
            cleartypeCounts[index] = cleartypeCounts[index] + 1
        end
    end
end


local cleartypeCounts = {}
for i=1, 11 do --excludes "Infvalid", "No Play" and "--" (wtf even is --)
    cleartypeCounts[i] = 0
end
setCleartypeCounts(cleartypeCounts)

SCOREMAN:SortRecentScoresForGame()


--table of {x, y} values, storing the top left corner of each bar
--this is so we can easily draw the text above each bar
local barCoords = {}



t = Def.ActorFrame{
    Name = "CleartypeDistributionContainer",
    focused = false,
    InitCommand = function(self)
        self:diffusealpha(0)
    end,

    FocusCommand = function(self)
        self:diffusealpha(1)
        self.focused = true
        self:z(1)
    end,

    UnfocusCommand = function(self)
        self:diffusealpha(0)
        self.focused = false
        self:z(-1)
    end,

    LoadFont("Common Normal") .. {
        Name = "Title",
        InitCommand = function(self)
            self:valign(0)
            self:zoom(headerTextSize)
            self:xy(actuals.GraphTitleX, actuals.GraphTitleY)
            self:settext("Cleartype distribution")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end,
    },

}





local graph = Def.ActorFrame{
    Name = "Graph",
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end,
        
    Def.Quad{
        Name = "BG",
        InitCommand = function(self)
            self:halign(0):valign(0)
            self:diffuse(bgColour)
            self:diffusealpha(bgAlpha)
            self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
        end
    },

    Def.ActorMultiVertex{
        Name = "Plots",
        InitCommand = function(self)
            self.skillset = "overall"
            self:diffusealpha(plotAlpha)
            self:playcommand("Plot")
        end,

        PlotCommand = function(self)
            local vertices = {}
            local barSpacing = (actuals.GraphWidth - ((#cleartypeCounts) * actuals.BarWidth)) / (#cleartypeCounts - 1)
            local maxY = 0

            --we cant just do barcoords = {0, 0} etc. due to how lua works
            for i = 1, #barCoords do
                table.remove(barCoords, 1)
            end

            for i = 1, #cleartypeCounts do
                maxY = math.max(maxY, cleartypeCounts[i])
            end

            for i = 1, #cleartypeCounts do
                local x = (i-1) * (actuals.BarWidth + barSpacing)
                local y = actuals.GraphHeight - ((actuals.GraphHeight * (cleartypeCounts[i] / maxY)))
                local height = (actuals.GraphHeight * (cleartypeCounts[i] / maxY))
                local color = getClearTypeColor(i)
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
        SetCommand = function(self, params)
            self:PlayCommandsOnChildren("Set", params)
        end,

        LoadFont("Common Normal") .. {
            --scorecount for each grade and percentage that goes above each bar
            Name = "LabelAboveBar",
            InitCommand = function(self)
                self:zoom(labelTextSize)
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                --we need to set the xy here so it doesnt tween in from (0,0) and look weird
                self:y(plots:GetY() + barCoords[i][2] - actuals.LabelAboveBarVerticalOffset)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
                local total = 0
                for j = 1, #cleartypeCounts do
                    total = total + cleartypeCounts[j]
                end
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                self:y(plots:GetY() + barCoords[i][2] - actuals.LabelAboveBarVerticalOffset)

                self:settextf("%s \n (%4.2f%s)",cleartypeCounts[i], (cleartypeCounts[i] / total) * 100, "%")
            end
        },

        LoadFont("Common Normal") .. {
            --grade text that goes under the bar
            Name = "LabelBelowBar",
            InitCommand = function(self)
                self:zoom(labelTextSize)
                self:valign(0)
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                self:y(plots:GetY() + actuals.GraphHeight + actuals.LabelBelowBarVerticalOffset)
                self:settext(getClearTypeText(i)) 
                self:diffuse(getClearTypeColor(i))
            end,
        }
    }
    
end

local labels = Def.ActorFrame{
    Name = "LabelsContainer"
}

for i = 1, #cleartypeCounts do --make the graph labels
    labels[#labels + 1] = makeLabel(i)
end

graph[#graph + 1] = labels

t[#t + 1] = graph

return t
