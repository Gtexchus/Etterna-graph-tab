local ratios = {
    YaxisLabelOffset = 5 / 1920
}

local actuals = {
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}
local commonGraphFunctions = Var("CommonGraphFunctions")

local plotAlpha = 0.5
local yAxisLabelCount = 10
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works
local yAxisLabelInnerLineColor = color("#52525280")

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

--if you want to zoom in on the highest density section of the graph (where the most scores are)
--try increasing minLen and scaleDivisor
--e.g. you may want to try minLen = 60 and scaleDivisor = 1000
local minLen = 0 --in seconds
local scaleDivisor = 50

local minWife = 0.93
local maxWife = 1
local minFoundWife = 1
local maxFoundWife = 0

SCOREMAN:SortRecentScoresForGame()


local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local wife = score:GetWifeScore()
            local grade = score:GetWifeGrade()
            local steps = SONGMAN:GetStepsByChartKey(score:GetChartKey())
            local len = steps:GetLengthSeconds() / score:GetMusicRate()
            local notes = steps:GetRadarValues(PLAYER_1):GetValue("RadarCategory_Notes")
            if wife >= (minWife) and wife <= (maxWife) and grade ~= "Failed" and grade ~= "Grade_Failed" and len > minLen and notes >= 200 then
                local index = #values + 1
                values[index] = {}
                values[index][1] = wife
                values[index][2] = len
                minFoundWife = math.min(minFoundWife, wife)
                maxFoundWife = math.max(maxFoundWife, wife)
            end
        end
    end
end

local values = {}
setValues(values)
local xAxisLabelCount = (commonGraphFunctions.GetGradeNum(minFoundWife, useMidGrades) - commonGraphFunctions.GetGradeNum(maxFoundWife, useMidGrades)) + 2

local t = Def.ActorFrame{
    Name = "ChartLengthOverAccuracyGraphContainer"
}

t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Xfunc = function(params)
        return commonGraphFunctions.CoordFuncAcc(params, useMidGrades)
    end,

    XvalueFunc = function(params)
        return commonGraphFunctions.ValueFuncAcc(params, useMidGrades)
    end,

    MinXvalueFunc = function(params)
        return commonGraphFunctions.MinValueFuncAcc(params, useMidGrades)
    end,
    
    MaxXvalueFunc = function(params)
        return commonGraphFunctions.MaxValueFuncAcc(params, useMidGrades)
    end,

    XvalueToStringFunc = commonGraphFunctions.ValueToStringFuncAcc,
    XaxisLabelColorFunc = commonGraphFunctions.AxisLabelColorFuncAcc,

    Yfunc = function(params)
        return commonGraphFunctions.CoordFuncAsinh(params, scaleDivisor)
    end,

    YvalueFunc = function(params)
        return commonGraphFunctions.ValueFuncAsinh(params, scaleDivisor)
    end,

    YvalueToStringFunc = function(params) return SecondsToMMSS(params.value) end,

    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,

    ColorFunc = function(params)
        return colorByGrade(GetGradeFromPercent(params.xValue))
    end,

    XaxisLabelCount = xAxisLabelCount,
    YaxisLabelCount = yAxisLabelCount,
    PlotAlpha = plotAlpha,
    Xunits = "Accuracy",
    Yunits = "Chart length",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
})

return t