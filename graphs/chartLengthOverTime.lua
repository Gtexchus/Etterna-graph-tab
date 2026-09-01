local ratios = {
    YaxisLabelOffset = 5 / 1920
}

local actuals = {
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}

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
        --make it an asinh graph because it squishes big values like a log graph but works nicely for negatives and 0
        local scale = math.max(math.abs(params.minValue), math.abs(params.maxValue)) / scaleDivisor
        --higher scale means the graph starts squishing at a higher y value
        --e.g. scale = 0.5 may begin to squish the graph at yValue = 5, but scale = 5 may begin to squish the graph at yValue = 50
        local shit = asinh(params.value / scale) - asinh(params.minValue / scale)
        local fatShit = asinh(params.maxValue / scale) - asinh(params.minValue / scale)
        return params.GraphLength * (shit / fatShit)
    end,
    YvalueFunc = function(params)
        local scale = math.max(math.abs(params.minValue), math.abs(params.maxValue)) / scaleDivisor
        local fatShit = asinh(params.maxValue / scale) - asinh(params.minValue / scale)
        local wetFart = params.coord / params.GraphLength
        return math.sinh((fatShit * wetFart) + asinh(params.minValue / scale)) * scale
    end,

    XvalueToStringFunc = function(params)
        local dateTable = os.date("*t", params.value)
        local day = tostring(dateTable["day"])
        local month = tostring(dateTable["month"])
        local year = tostring(dateTable["year"])
        if string.len(day) == 1 then --e.g. if its 1 then make it 01
            day = 0 .. day
        end
        if string.len(month) == 1 then
            month = 0 .. month
        end
        return string.format("%s-%s-%s", year, month, day)
    end,
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