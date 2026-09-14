local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")
local gradeUtils = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.gradeUtils")

local ratios = {
    YaxisLabelOffset = 5 / 1920
}

local actuals = {
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}

local plotAlpha = 0.5
local xAxisLabelCount = 10
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works
local xAxisLabelInnerLineColor = color("#52525280")

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
                values[index][1] = len
                values[index][2] = wife
                minFoundWife = math.min(minFoundWife, wife)
                maxFoundWife = math.max(maxFoundWife, wife)
            end
        end
    end
end

local values = {}
setValues(values)
local yAxisLabelCount = (gradeUtils.WifeToGradeNum(minFoundWife, useMidGrades) - gradeUtils.WifeToGradeNum(maxFoundWife, useMidGrades)) + 2

local t = Def.ActorFrame{
    Name = "AccuracyOverChartLengthGraphContainer"
}

t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Xfunc = function(params)
        return cgf.CoordFuncAsinh(params, scaleDivisor)
    end,

    XvalueFunc = function(params)
        return cgf.ValueFuncAsinh(params, scaleDivisor)
    end,

    XvalueToStringFunc = function(params) return SecondsToMMSS(params.value) end,

    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,

    Yfunc = function(params)
        return cgf.CoordFuncAcc(params, useMidGrades)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncAcc(params, useMidGrades)
    end,

    MinYvalueFunc = function(params)
        return cgf.MinValueFuncAcc(params, useMidGrades)
    end,
    
    MaxYvalueFunc = function(params)
        return cgf.MaxValueFuncAcc(params, useMidGrades)
    end,

    YvalueToStringFunc = cgf.ValueToStringFuncAcc,
    YaxisLabelColorFunc = cgf.AxisLabelColorFuncAcc,

    ColorFunc = function(params)
        return colorByGrade(GetGradeFromPercent(params.yValue))
    end,

    XaxisLabelCount = xAxisLabelCount,
    YaxisLabelCount = yAxisLabelCount,
    PlotAlpha = plotAlpha,
    Xunits = "Chart length",
    Yunits = "Accuracy",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
})

return t