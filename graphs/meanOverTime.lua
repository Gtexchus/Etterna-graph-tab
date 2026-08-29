local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphY = 100 / 1080,
    GraphX = 50 / 1920,
}

local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
}

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



local values = {}
setValues(values)


local t = Def.ActorFrame{
    Name = "MeanOverTimeGraphContainer",
}

--i dont know how to colour the plots on this one
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
        local dateTable = os.date("*t", params.xValue)
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
        return string.format("%5.2f", params.yValue)
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
    Xunits = "Time",
    Yunits = "Mean"
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t