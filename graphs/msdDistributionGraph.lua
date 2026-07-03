local smallButtonTextSize = 0.5
local labelTextSize = 0.3
local headerTextSize = 1
local skillsetButtonsMaxWidth = 100
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6
local plotAlpha = 1
local plotAnimationSeconds = 1
local maxSkillsetButtonsPerColumn = 4
local XaxisScale = 1 --make this either an integer or a fractional power of 2 otherwise it will break due to floating point BS
local minMSD = 0
local maxMSD = 4

local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphYPadding = 100 / 1080, --distance from x axis to bottom of container
    GraphXPadding = 50 / 1920, --distance from y axis to left of container
    BarWidth = 10 / 1920,
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

local function setMSDcounts(msdCounts, skillset)
    for i=1, #msdCounts do
        msdCounts[i] = 0
    end
    local offset = minMSD - 1 --offset to shift all the indexes so [index of minMSD]= 1
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            if score:GetSkillsetSSR(skillset) ~= 0 then
                local msd = notShit.floor(((score:GetSkillsetSSR(skillset) + (XaxisScale/2)) / XaxisScale)) * XaxisScale
                local index = notShit.floor((msd / XaxisScale) - offset)

                if msdCounts[index] ~= nil then
                    msdCounts[index] = msdCounts[index] + 1
                else
                    msdCounts[index] = 1
                end
            end
        end
    end
end

local function getMSDfromi(i)
    return (i + (minMSD - 1)) * XaxisScale
end




SCOREMAN:SortRecentScoresForGame()


--find max msd
for i = 1, SCOREMAN:GetTotalNumberOfScores() do
    local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i)
    if score ~= nil then
        if score:GetSkillsetSSR("overall") > maxMSD then
            maxMSD = score:GetSkillsetSSR("overall")
        end
    end
end

--table of {x, y} values, storing the top left corner of each bar
--this is so we can easily draw the text above each bar
local barCoords = {}
local msdCounts = {}
for i=1, (notShit.floor((maxMSD - minMSD) / XaxisScale) + 2) do --set everything we need to 0 (i dont really know why its +2 here, it looks like it should be +1 but that breaks)
    msdCounts[i] = 0
end


t = Def.ActorFrame{
    Name = "MSDdistributionContainer",
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
            self:settext("Overall MSD distribution")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end,

        UpdateCommand = function(self, params)
            self:settext(params.skillset .. " MSD distribution")
        end
    },

}


local function makeSkillsetButton(skillset_, x, y)
    return UIElements.TextButton(1, 1, "Common Normal") .. {
        Name = skillset_ .. "Button",
        InitCommand = function(self)
            local txt = self:GetChild("Text")
            local bg = self:GetChild("BG")
            self:xy(x, y)
            bg:zoomto(actuals.SkillsetButtonsHorizontalSpacing, actuals.SkillsetButtonsVerticalSpacing)
            txt:zoom(smallButtonTextSize)
            txt:diffusealpha(1)
            txt:settext(ms.SkillSetsTranslatedByName[skillset_])
            txt:maxwidth(skillsetButtonsMaxWidth)
            self:playcommand("Update", {skillset = "Overall"}) --so overall is highlighted when the graph is first loaded
        end,

        UpdateCommand = function(self, params)
            local txt = self:GetChild("Text")
            if params.skillset == skillset_ then
                txt:strokecolor(Brightness(COLORS:getMainColor("PrimaryText"), 0.7))
            else
                txt:strokecolor(color("0,0,0,0"))
            end
        end,

        ClickCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "OnMouseDown" then
                local graphContainer = self:GetParent():GetParent()
                local plots = graphContainer:GetChild("Graph"):GetChild("Plots")
                local sbc = graphContainer:GetChild("SkillsetButtonsContainer")
                local title = graphContainer:GetChild("Title")
                local labelsContainer = self:GetParent():GetParent():GetChild("Graph"):GetChild("LabelsContainer")
                local skillsetButtons = sbc:GetChildren()
                --update everything
                plots:playcommand("Update", {skillset = skillset_}) --this needs to be run first because setMSDcounts is run there
                sbc:PlayCommandsOnChildren("Update", {skillset = skillset_})
                title:playcommand("Update", {skillset = skillset_})
                labelsContainer:PlayCommandsOnChildren("Set")
            end
        end,

        RolloverUpdateCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "in" then
                self:diffusealpha(buttonHoverAlpha)
            else
                self:diffusealpha(1)
            end
        end
    }
end

--make skillset buttons

local sbc = Def.ActorFrame{
    Name = "SkillsetButtonsContainer",

    InitCommand = function(self)
        self:xy(actuals.SkillsetButtonsX, actuals.SkillsetButtonsY)
    end
}

for i=1, #ms.SkillSets do
    sbc[#sbc + 1] = makeSkillsetButton(ms.SkillSets[i], math.floor((i-1)/ maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsHorizontalSpacing, ((i-1) % maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsVerticalSpacing)
end

t[#t + 1] = sbc



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
            setMSDcounts(msdCounts, self.skillset)
            local vertices = {}
            local barSpacing = (actuals.GraphWidth - ((#msdCounts) * actuals.BarWidth)) / (#msdCounts - 1)
            local maxY = 0

            --we cant just do barcoords = {0, 0} etc. due to how lua works
            for i = 1, #barCoords do
                table.remove(barCoords, 1)
            end

            for i = 1, #msdCounts do
                maxY = math.max(maxY, msdCounts[i])
            end

            for i = 1, #msdCounts do
                local x = (i-1) * (actuals.BarWidth + barSpacing)
                local msd = getMSDfromi(i)
                local msdCount = 0
                if msdCounts[i] ~= nil then 
                    msdCount = msdCounts[i]
                end
                local y = actuals.GraphHeight - ((actuals.GraphHeight * (msdCount / maxY)))
                local height = (actuals.GraphHeight * (msdCounts[i] / maxY))
                local color = colorByMSD(msd)
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

        UpdateCommand = function(self, params)
            if params.skillset ~= self.skillset then
                self.skillset = params.skillset
                self:playcommand("Plot")
            end
        end

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
                local labelAboveBar = self:GetParent():GetChild("LabelAboveBar")
                labelAboveBar:diffusealpha(1)
            end,

            MouseOutCommand = function(self)
                local labelAboveBar = self:GetParent():GetChild("LabelAboveBar")
                labelAboveBar:diffusealpha(0)
            end,
        },

        LoadFont("Common Normal") .. {
            --scorecount for each grade and percentage that goes above each bar
            Name = "LabelAboveBar",
            InitCommand = function(self)
                self:zoom(labelTextSize)
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                --we need to set the xy here so it doesnt tween in from (0,0) and look weird
                self:y(plots:GetY() + barCoords[i][2] - actuals.LabelAboveBarVerticalOffset)
                self:diffusealpha(0)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
                local total = 0
                for j = 1, #msdCounts do
                    local msdCount = 0
                    if msdCounts[j] ~= nil then 
                        msdCount = msdCounts[j]
                    end
                    total = total + msdCount
                end
                local plots = self:GetParent():GetParent():GetParent():GetChild("Plots")
                self:y(plots:GetY() + barCoords[i][2] - actuals.LabelAboveBarVerticalOffset)
                local msdCount = 0
                if msdCounts[i] ~= nil then 
                    msdCount = msdCounts[i]
                end
                self:settextf("%s \n (%4.2f%s)",msdCount, (msdCount / total) * 100, "%")
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
                local msd = getMSDfromi(i)
                self:settext(msd) 
                self:diffuse(colorByMSD(msd))
            end,
        }
    }
    
end

local labels = Def.ActorFrame{
    Name = "LabelsContainer"
}

for i = 1, #msdCounts do --make the graph labels
    labels[#labels + 1] = makeLabel(i)
end

graph[#graph + 1] = labels

t[#t + 1] = graph

return t
