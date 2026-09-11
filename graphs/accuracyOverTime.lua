local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    YaxisLabelOffset = 5 / 1920,
}


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}


local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local minWife = 0.93
local maxWife = 1
local minFoundWife = 1
local maxFoundWife = 0

local plotAlpha = 0.5

local smallButtonTextSize = 0.5
local buttonHoverAlpha = 0.6
local XaxisLabelsCount = 5
local yAxisLabelLineAlpha = 0.3
local xAxisLabelInnerLineColor = color("#52525280")

local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

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
            local dateText = score:GetDate()
            if dateText ~= nil and wife >= (minWife) and wife <= (maxWife) and grade ~= "Failed" and grade ~= "Grade_Failed" then
                local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                local index = #values + 1
                values[index] = {}
                values[index][1] = date
                values[index][2] = wife
                minFoundWife = math.min(minFoundWife, wife)
                maxFoundWife = math.max(maxFoundWife, wife)
            end
        end
    end
end


local values = {}
setValues(values)
local YaxisLabelsCount = (cgf.GetGradeNum(minFoundWife, useMidGrades) - cgf.GetGradeNum(maxFoundWife, useMidGrades)) + 2

local t = Def.ActorFrame{
    Name = "AccuracyOverTimeGraphContainer",
}


t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Yfunc = function(params) 
        return cgf.CoordFuncAcc(params, useMidGrades)
    end,

    ColorFunc = function(params) return colorByGrade(GetGradeFromPercent(params.yValue)) end,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,

    YvalueFunc = function(params)
        return cgf.ValueFuncAcc(params, useMidGrades)
    end,

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

    XaxisLabelCount= XaxisLabelsCount,
    YaxisLabelCount = YaxisLabelsCount,
    XaxisLabelInnerLineColor =xAxisLabelInnerLineColor,
    YaxisLabelInnerLineColor = yAxisLabelInnerLineColor,
    PlotAlpha = plotAlpha,
    Xunits = "Date",
    Yunits = "Accuracy",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
})

return t