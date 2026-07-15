local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    X = 1 - (780 / 1920), --x and y of the box
    Y = 1 - (612 / 1080), 
    
    GraphYPadding = 100 / 1080,
    GraphXPadding = 50 / 1920,

    SkillsetButtonsX = 640 / 1920,
    SkillsetButtonsY = 20 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
    XaxisLabelsYpadding = 20 / 1080,
    YaxisLabelsXpadding = 8 / 1920,
    XaxisLabelLineWidth = 1 / 1920,
    YaxisLabelLineHeight = 1 / 1080

}

--for some fuckass reason you cant reference values in tables during initialisation so they must be done after the fact
ratios.GraphX = ratios.GraphXPadding
ratios.GraphY = ratios.GraphYPadding
ratios.GraphWidth = ratios.Width - (ratios.GraphXPadding * 2)
ratios.GraphHeight = ratios.Height - (ratios.GraphYPadding * 2) 
ratios.GraphBottom = ratios.GraphY + ratios.GraphHeight
ratios.GraphTitleCenterX = ratios.Width / 2
ratios.GraphTitleCenterY = 20 / 1080


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphYPadding = ratios.GraphYPadding * SCREEN_HEIGHT,
    GraphXPadding = ratios.GraphXPadding * SCREEN_WIDTH,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    GraphBottom = ratios.GraphBottom * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    GraphTitleCenterX = ratios.GraphTitleCenterX * SCREEN_WIDTH,
    GraphTitleCenterY = ratios.GraphTitleCenterY * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
    X = ratios.X * SCREEN_WIDTH,
    Y = ratios.Y * SCREEN_HEIGHT,
    XaxisLabelsYpadding = ratios.XaxisLabelsYpadding * SCREEN_HEIGHT,
    YaxisLabelsXpadding = ratios.YaxisLabelsXpadding * SCREEN_WIDTH,
    XaxisLabelLineWidth = ratios.XaxisLabelLineWidth * SCREEN_WIDTH,
    YaxisLabelLineHeight = ratios.YaxisLabelLineHeight * SCREEN_HEIGHT
}

local smallButtonTextSize = 0.5
local headerTextSize = 1
local skillsetButtonsMaxWidth = 100
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6

local plotWidth = (3 / 1920) * SCREEN_WIDTH
local plotHeight = (3 / 1080) * SCREEN_HEIGHT
local plotAlpha = 0.5
local plotAnimationSeconds = 1
local maxSkillsetButtonsPerColumn = 4

local XaxisLabelScale = 4
local YaxisLabelCount = 21
local XaxisLabelsSize = 0.5
local YaxisLabelsSize = 0.5
local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelInnerLineColor = color("#52525280")
local xAxisLabelLineAlpha = 0.3

SCOREMAN:SortRecentScoresForGame()

local function asinh(x)
    return math.log(x + math.sqrt(x * x + 1))
end

local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local replay = score:GetReplay()
	        replay:LoadAllData()
            local ov = replay:GetOffsetVector()
            local mean = wifeMean(ov)
            local ssr = score:GetSkillsetSSR(skillset)

            local index = #values + 1
            values[index] = {}
            values[index][1] = ssr
            values[index][2] = mean
        end
    end
end

local function setValuesSkillsetOnly(values, skillset) --for skillset buttons
    local index = 1
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local ssr = score:GetSkillsetSSR(skillset)

            values[index][1] = ssr
            index = index + 1
        end
    end
end

local values = {}
setValues(values, "overall")


local t = Def.ActorFrame{
    Name = "MeanOverMSDGraphContainer",
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
            self:xy(actuals.GraphTitleCenterX, actuals.GraphTitleCenterY)
            self:settext("Mean over Overall MSD")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end,

        UpdateCommand = function(self, params)
            self:settext("Mean over " .. params.skillset .. " MSD")
        end
    },
}

--make skillset buttons


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
                setValuesSkillsetOnly(values, skillset_)
                plots:playcommand("Set")
                sbc:PlayCommandsOnChildren("Update", {skillset = skillset_})
                title:playcommand("Update", {skillset = skillset_})
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

t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Yfunc = function(params)
        --make it an asinh graph because it squishes big values like a log graph but works nicely for negatives and 0
        local scale = math.max(math.abs(params.minYvalue), math.abs(params.maxYvalue)) / 100
        --higher scale means the graph starts squishing at a higher y value
        --e.g. scale = 0.5 may begin to squish the graph at yValue = 5, but scale = 5 may begin to squish the graph at yValue = 50
        local shit = asinh(params.yValue / scale) - asinh(params.minYvalue / scale)
        local fatShit = asinh(params.maxYvalue / scale) - asinh(params.minYvalue / scale)
        return params.GraphHeight * (1 - (shit / fatShit))
    end,
    YvalueFunc = function(params)
        local scale = math.max(math.abs(params.minYvalue), math.abs(params.maxYvalue)) / 100
        local fatShit = asinh(params.maxYvalue / scale) - asinh(params.minYvalue / scale)
        local wetFart = 1 - (params.y / params.GraphHeight)
        return math.sinh((fatShit * wetFart) + asinh(params.minYvalue / scale)) * scale
    end,
    XvalueToStringFunc = function(params)
        return string.format("%5.2f", params.xValue)
    end,
    YvalueToStringFunc = function(params)
        return string.format("%5.2f", params.yValue)
    end,
    ColorFunc = function(params) return colorByMSD(params.xValue) end,
    XaxisLabelColorFunc = function(params)
        local color = colorByMSD(params.xValue)
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = xAxisLabelLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end,
    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,
    PlotAlpha = plotAlpha,
    XaxisLabelScale = XaxisLabelScale,
    YaxisLabelCount = YaxisLabelCount,
    YoriginCentered = true,
    Xunits = "MSD",
    Yunits = "Mean"
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t