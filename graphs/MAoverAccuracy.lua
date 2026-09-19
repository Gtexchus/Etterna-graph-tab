local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")
local gradeUtils = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.gradeUtils")

local ratios = {
    YaxisLabelOffset = 5 / 1920,
}

local actuals = {
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}


local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local plotAlpha = 0.5
local yAxisLabelCount = 10
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works


local minWife = 0.93
local maxWife = 1
local minFoundWife = 1
local maxFoundWife = 0

local base = 10

SCOREMAN:SortRecentScoresForGame()

local function setValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local wife = score:GetWifeScore()
            local grade = score:GetWifeGrade()
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
            if m > 0 and p > 0 and ma > 1 and wife >= (minWife) and wife <= (maxWife) and grade ~= "Failed" and grade ~= "Grade_Failed" then
                local index = #values + 1
                values[index] = {}
                values[index][1] = wife
                values[index][2] = ma
                minFoundWife = math.min(minFoundWife, wife)
                maxFoundWife = math.max(maxFoundWife, wife)
            end
            
        end
    end
end

local values = {}
setValues(values)
local xAxisLabelCount = (gradeUtils.WifeToGradeNum(minFoundWife, useMidGrades) - gradeUtils.WifeToGradeNum(maxFoundWife, useMidGrades)) + 2

local t = Def.ActorFrame{
    Name = "MAOverAccuracyGraphContainer"
}

t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Xfunc = function(params)
        return cgf.CoordFuncAcc(params, useMidGrades)
    end,

    XvalueFunc = function(params)
        return cgf.ValueFuncAcc(params, useMidGrades)
    end,

    MinXvalueFunc = function(params)
        return cgf.MinValueFuncAcc(params, useMidGrades)
    end,
    
    MaxXvalueFunc = function(params)
        return cgf.MaxValueFuncAcc(params, useMidGrades)
    end,

    XvalueToStringFunc = cgf.ValueToStringFuncAcc,
    XaxisLabelColorFunc = cgf.AxisLabelColorFuncAcc,

    Yfunc = function(params)
        return cgf.CoordFuncLog(params, base)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncLog(params, base)
    end,

    YvalueToStringFunc = cgf.ValueToStringFuncIntegerOr2DP,

    ColorFunc = function(params)
        return cgf.AxisLabelColorFuncAcc({value = params.xValue})
    end,

    XaxisLabelCount = xAxisLabelCount,
    YaxisLabelCount = yAxisLabelCount,
    PlotAlpha = plotAlpha,
    Xunits = "Accuracy",
    Yunits = "MA",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
})

return t