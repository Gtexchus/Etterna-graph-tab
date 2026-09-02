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

local cgf = Var("cgf")

local scaleDivisor = 50

local plotAlpha = 0.5
local XaxisLabelCount = 5
local YaxisLabelCount = 21
local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelInnerLineColor = color("#52525280")

SCOREMAN:SortRecentScoresForGame()

local function asinh(x)
    return math.log(x + math.sqrt(x * x + 1))
end

local function setValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local dateText = score:GetDate()
            if dateText ~= nil then
                local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                local replay = score:GetReplay()
                replay:LoadAllData()
                local ov = replay:GetOffsetVector()
                local mean = wifeMean(ov)

                local index = #values + 1
                values[index] = {}
                values[index][1] = date
                values[index][2] = mean
            end
        end
    end
end

local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

local values = {}
setValues(values)


local t = Def.ActorFrame{
    Name = "MeanOverTimeGraphContainer",
}

--i dont know how to colour the plots on this one
t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Yfunc = function(params)
        return cgf.CoordFuncAsinh(params, scaleDivisor)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncAsinh(params, scaleDivisor)
    end,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,

    YvalueToStringFunc = function(params)
        return string.format("%5.2f", params.value)
    end,

    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,

    PlotAlpha = plotAlpha,
    XaxisLabelCount = XaxisLabelCount,
    YaxisLabelCount = YaxisLabelCount,
    YoriginCentered = true,
    Xunits = "Date",
    Yunits = "Mean",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
})

return t