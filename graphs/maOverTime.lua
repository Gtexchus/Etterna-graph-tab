local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    YaxisLabelOffset = 5 / 1920,
}

local actuals = {
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}


local plotAlpha = 0.5
local xAxisLabelCount = 5
local yAxisLabelCount = 10
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

local base = 10

SCOREMAN:SortRecentScoresForGame()

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
                    values[index][1] = date
                    values[index][2] = ma
                end
            end
        end
    end
end

local values = {}

setValues(values)

local t = Def.ActorFrame{
    Name = "MAOverTimeGraphContainer"
}


t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,

    Yfunc = function(params)
        return cgf.CoordFuncLog(params, base)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncLog(params, base)
    end,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,

    YvalueToStringFunc = function(params)
        return string.format("%5.2f", params.value)
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
    XaxisLabelCount = xAxisLabelCount,
    YaxisLabelCount = yAxisLabelCount,
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth,
    Xunits = "Date",
    Yunits = "MA"
})

return t