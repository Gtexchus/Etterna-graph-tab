local ratios = {
    yAxisLabelOffset = 5 / 1920,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
}
local actuals = {
    yAxisLabelOffset = ratios.yAxisLabelOffset * SCREEN_WIDTH,
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
local xAxisLabelScale = 4
local yAxisLabelCount = 10
local xAxisLabelInnerLineAlpha = 0.3
local yAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works
local base = 10

SCOREMAN:SortRecentScoresForGame()

local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local ssr = score:GetSkillsetSSR(skillset)
            local m = 0
            local p = 0
            if PREFSMAN:GetPreference("SortBySSRNormPercent") then
                m = score:GetTNSNormalized(ms.JudgeCount[1])
                p = score:GetTNSNormalized(ms.JudgeCount[2])
            else
                m = score:GetTapNoteScore(ms.JudgeCount[1])
                p = score:GetTapNoteScore(ms.JudgeCount[2])
            end
            local ma = m/p
            if m > 0 and p > 0 and ma > 1 then
                local index = #values + 1
                values[index] = {}
                values[index][1] = ssr
                values[index][2] = ma
            end
        end
    end
end

local values = {}

setValues(values, "overall")

local t = Def.ActorFrame{
    Name = "MAoverMSDGraphContainer",
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
                setValues(values, skillset_)
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
    ColorFunc = function(params) return colorByMSD(params.xValue) end,

    Yfunc = function(params)
        local hi = math.log(params.value, base) - math.log(params.minValue, base)
        local bye = math.log(params.maxValue, base) - math.log(params.minValue, base)
        return params.GraphLength * (hi / bye)
    end,

    YvalueFunc = function(params)
        local bye = math.log(params.maxValue, base) - math.log(params.minValue, base)
        local why = params.coord / params.GraphLength
        return base^((why * bye) + math.log(params.minValue, base))
    end,

    XvalueToStringFunc = function(params)
        if string.format("%5.2f", params.value) == string.format("%5.2f", notShit.floor(params.value + 0.0001)) then -- if the first two decimal points are 00
            --this is so the x axis labels are integers and arent 12.00, for example
            -- +0.0001 because of floating point nonsense
            return params.value
        else
            return string.format("%5.2f", params.value)
        end
    end,

    YvalueToStringFunc = function(params)
        return string.format("%5.2f", params.value)
    end,

    XaxisLabelColorFunc = function(params)
        local color = colorByMSD(params.value)
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = xAxisLabelInnerLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,

    --[[ --use this to make the axis labels start and end on some power of base
    MinYvalueFunc = function(params)
        return math.min(params.minValue, base^(math.floor(math.log(params.value, base))))
    end,

    MaxYvalueFunc = function(params)
        return math.max(params.maxValue, base^(math.floor(math.log(params.value, base)) + 1))
    end,
    ]]

    PlotAlpha = plotAlpha,
    XaxisLabelScale = xAxisLabelScale,
    YaxisLabelCount = yAxisLabelCount,
    YaxisLabelOffset = actuals.yAxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth,
    Xunits = "MSD",
    Yunits = "MA"
})

return t