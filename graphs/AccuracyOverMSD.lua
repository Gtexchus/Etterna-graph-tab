local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
    YaxisLabelOffset = 5 / 1920,
}


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}

local cgf = Var("cgf")

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local smallButtonTextSize = 0.5
local skillsetButtonsMaxWidth = 100
local buttonHoverAlpha = 0.6
--the idea is to have each midgrade take up the same physical space on the graph


local minWife = 0.93
local maxWife = 1
local minFoundWife = 1
local maxFoundWife = 0

local plotAlpha = 0.5
local maxSkillsetButtonsPerColumn = 4

local XaxisLabelsScale = 4
local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelLineAlpha = 0.3
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

SCOREMAN:SortRecentScoresForGame()

local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local ssr = score:GetSkillsetSSR(skillset)
            local wife = score:GetWifeScore()
            local grade = score:GetWifeGrade()
            if wife >= (minWife) and wife <= (maxWife) and grade ~= "Failed" and grade ~= "Grade_Failed" then
                local index = #values + 1
                values[index] = {}
                values[index][1] = ssr
                values[index][2] = wife
                minFoundWife = math.min(minFoundWife, wife)
                maxFoundWife = math.max(maxFoundWife, wife)
            end
        end
    end
end

local values = {}
setValues(values, "overall")
local YaxisLabelsCount = (cgf.GetGradeNum(minFoundWife, useMidGrades) - cgf.GetGradeNum(maxFoundWife, useMidGrades)) + 2


local t = Def.ActorFrame{
    Name = "AccuracyOverMSDGraphContainer",
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


--make graph

--ts is a pain to make
t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Yfunc = function(params) 
        return cgf.CoordFuncAcc(params, useMidGrades)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncAcc(params, useMidGrades)
    end,

    ColorFunc = function(params) return colorByGrade(GetGradeFromPercent(params.yValue)) end,
    XvalueToStringFunc = cgf.ValueToStringFuncIntegerOr2DP,

    YvalueToStringFunc = cgf.ValueToStringFuncAcc,

    MinYvalueFunc = function(params)
        return cgf.MinValueFuncAcc(params, useMidGrades)
    end,

    MaxYvalueFunc = function(params)
        return cgf.MaxValueFuncAcc(params, useMidGrades)
    end,

    
    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return cgf.AxisLabelColorFuncAcc(params, yAxisLabelLineAlpha)
    end,

    XaxisLabelScale = XaxisLabelsScale,
    YaxisLabelCount = YaxisLabelsCount,
    PlotAlpha = plotAlpha,
    Xunits = "MSD",
    Yunits = "Accuracy",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
})


local function gradeTierToWife(n, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    --afaik there isnt a function to convert from 
    --grade tier to wife (there isnt an inverse of GetGradeFromPercent())
    --so this table will have to do
    local toWife = { 
        [0] = 1, --not technically a grade but its here for convenience
        0.999935, --AAAAA
        0.9998,
        0.9997,
        0.99955, --AAAA
        0.999,
        0.998,
        0.997, --AAA
        0.99,
        0.965,
        0.93, --AA
        0.9,
        0.85,
        0.8, --A
        0.7, --B
        0.6 --C
    }

    local toWifeNoMidGrades = { 
        [0] = 1, --not technically a grade but its here for convenience
        0.999935, --AAAAA
        0.99955, --AAAA
        0.997, --AAA
        0.93, --AA
        0.8, --A
        0.7, --B
        0.6 --C
    }

    if useMidGrades then
        return toWife[n]
    end
    return toWifeNoMidGrades[n]
end


local function getLowerGradeBoundary(wife, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    return gradeTierToWife(cgf.GetGradeNum(wife, useMidGrades), useMidGrades)
end

local function getUpperGradeBoundary(wife, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    if wife == 1 then
        return 1
    end
    return gradeTierToWife(cgf.GetGradeNum(wife, useMidGrades) - 1, useMidGrades)
end


local accCurveValues = {{}}

local resolutionPerSection = 2

local minSSR = 100
local maxSSR = 0
local function setAccCurveValues(accCurveValues)
    local minGradeTier = cgf.GetGradeNum(minFoundWife, useMidGrades) 
    local maxGradeTier = cgf.GetGradeNum(maxFoundWife, useMidGrades)
    for i=1, YaxisLabelsCount - 1 do
        for j=1, resolutionPerSection do
            local currentWife = gradeTierToWife(minGradeTier - (i-1))
            local lowerGradeBoundary = getLowerGradeBoundary(currentWife, useMidGrades)
            local upperGradeBoundary = getUpperGradeBoundary(currentWife, useMidGrades)

            local h = (upperGradeBoundary - lowerGradeBoundary) / resolutionPerSection
            local lowerBound = lowerGradeBoundary + ((j-1) * h)
            local upperBound = lowerGradeBoundary + (j * h)
            local mid = (lowerBound + upperBound) / 2

            local c = 0
            local totalSSR = 0
            local totalSSRsquared = 0
            for k=1, #values do
                local w = values[k][2]
                local ssr = values[k][1]
                minSSR = math.min(ssr, minSSR)
                maxSSR = math.max(ssr, maxSSR)
                if w > lowerBound and w < upperBound then
                    totalSSR = totalSSR + ssr
                    totalSSRsquared = totalSSRsquared + ssr^2
                    c = c + 1
                end
            end

            if c > 0 then
                local mean = totalSSR / c
                local meanOfSquares = totalSSRsquared / c
                local sd = math.sqrt(meanOfSquares - mean^2)

                local highestPossible = mean + (sd * 2)

                local i = #accCurveValues[1] + 1
                accCurveValues[1][i] = {}
                accCurveValues[1][i][1] = highestPossible
                accCurveValues[1][i][2] = mid
            end
        end
    end
end

setAccCurveValues(accCurveValues)

t[#t + 1] = LoadActorWithParams("templates/lineGraph.lua", {
    Values = accCurveValues,
    Yfunc = function(params) 
        return cgf.CoordFuncAcc(params, useMidGrades)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncAcc(params, useMidGrades)
    end,

    XvalueToStringFunc = cgf.ValueToStringFuncIntegerOr2DP,

    YvalueToStringFunc = cgf.ValueToStringFuncAcc,

    MinYvalueFunc = function(params)
        return cgf.MinValueFuncAcc({value = minFoundWife, minValue = minFoundWife}, useMidGrades)
    end,

    MaxYvalueFunc = function(params)
        return cgf.MaxValueFuncAcc({value = maxFoundWife, maxValue = maxFoundWife}, useMidGrades)
    end,

    MinXvalueFunc = function(params)
        return minSSR
    end,

    MaxXvalueFunc = function(params)
        return maxSSR
    end,

    
    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return cgf.AxisLabelColorFuncAcc(params, yAxisLabelLineAlpha)
    end,

    PlotAlpha = plotAlpha,
    XaxisLabelScale = XaxisLabelsScale,
    Xunits = "MSD",
    Yunits = "Accuracy",
    BGcolor = color("#ffffff00")
})


return t