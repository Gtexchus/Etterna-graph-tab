local ratios = {
    YaxisLabelOffset = 5 / 1920
}

local actuals = {
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}

local cgf = Var("cgf")

local xAxisLabelCount = 5
local yAxisLabelCount = 10
local plotAlpha = 0.5
local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelInnerLineAlpha = 0.3
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

local base = 10

--if you want to zoom in on the highest density section of the graph (where the most scores are)
--try increasing minLen and scaleDivisor
--e.g. you may want to try minLen = 60 and scaleDivisor = 1000
local minLen = 0 --in seconds
local scaleDivisor = 50

SCOREMAN:SortRecentScoresForGame()

local function asinh(x)
    return math.log(x + math.sqrt(x * x + 1))
end


--remember to take rates into account
local function setValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local dateText = score:GetDate()
            local grade = score:GetWifeGrade()
            if dateText ~= nil and grade ~= "Failed" and grade ~= "Grade_Failed" then
                local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                local steps = SONGMAN:GetStepsByChartKey(score:GetChartKey())
                local len = steps:GetLengthSeconds() / score:GetMusicRate()
                if len > minLen then
                    local index = #values + 1
                    values[index] = {}
                    values[index][1] = date
                    values[index][2] = len
                end
            end
        end
    end
end

local values = {}
setValues(values)

local t = Def.ActorFrame{
    Name = "ChartLengthOverTimeGraphContainer"
}

t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    ColorFunc = function(params) return colorByMusicLength(params.yValue) end,

    Yfunc = function(params)
        return cgf.CoordFuncAsinh(params, scaleDivisor)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncAsinh(params, scaleDivisor)
    end,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,

    YvalueToStringFunc = function(params)
        return SecondsToMMSS(params.value) end,

    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        local color = colorByMusicLength(params.value)
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = yAxisLabelInnerLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end,

    XaxisLabelCount = xAxisLabelCount,
    YaxisLabelCount = yAxisLabelCount,
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth,
    PlotAlpha = plotAlpha,
    Xunits = "Date",
    Yunits = "Chart length"
})

return t