local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphY = 100 / 1080,
    GraphX = 50 / 1920,
    SkillsetButtonsX = 640 / 1920,
    SkillsetButtonsY = 20 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
}

local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
}

local smallButtonTextSize = 0.5
local skillsetButtonsMaxWidth = 100
local buttonHoverAlpha = 0.6
local maxSkillsetButtonsPerColumn = 4
local plotAlpha = 0.5
local XaxisLabelScale = 4
local YaxisLabelCount = 21
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
                txt:strokecolor(color("#A400FF"))
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
                local labelsContainer = self:GetParent():GetParent():GetChild("Graph"):GetChild("LabelsContainer")
                local skillsetButtons = sbc:GetChildren()
                --update everything
                setValuesSkillsetOnly(values, skillset_)
                plots:playcommand("Set")
                sbc:PlayCommandsOnChildren("Update", {skillset = skillset_})
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
        local scale = math.max(math.abs(params.minYvalue), math.abs(params.maxYvalue)) / 50
        --higher scale means the graph starts squishing at a higher y value
        --e.g. scale = 0.5 may begin to squish the graph at yValue = 5, but scale = 5 may begin to squish the graph at yValue = 50
        local shit = asinh(params.yValue / scale) - asinh(params.minYvalue / scale)
        local fatShit = asinh(params.maxYvalue / scale) - asinh(params.minYvalue / scale)
        return params.GraphHeight * (shit / fatShit)
    end,
    YvalueFunc = function(params)
        local scale = math.max(math.abs(params.minYvalue), math.abs(params.maxYvalue)) / 50
        local fatShit = asinh(params.maxYvalue / scale) - asinh(params.minYvalue / scale)
        local wetFart = params.y / params.GraphHeight
        return math.sinh((fatShit * wetFart) + asinh(params.minYvalue / scale)) * scale
    end,
    XvalueToStringFunc = function(params)
        if string.format("%5.2f", params.xValue) == string.format("%5.2f", notShit.floor(params.xValue + 0.0001)) then -- if the first two decimal points are 00
            --this is so the x axis labels are integers and arent 12.00, for example
            -- +0.0001 because of floating point nonsense
            return params.xValue
        else
            return string.format("%5.2f", params.xValue)
        end
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