local ratios = {
    yAxisLabelOffset = 5 / 1920
}
local actuals = {
    yAxisLabelOffset = ratios.yAxisLabelOffset * SCREEN_WIDTH
}

local plotAlpha = 0.5
local xAxisLabelScale = 4
local yAxisLabelCount = 10
local xAxisLabelInnerLineAlpha = 0.3
local yAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works
local base = 10

SCOREMAN:SortRecentScoresForGame()

local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local ssr = score:GetSkillsetSSR(skillset)
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
                values[index][1] = ssr
                values[index][2] = ma
            end
        end
    end
end

local values = {}

setValues(values, "overall")

local t = Def.ActorFrame{
    Name = "MAoverMSDGraphContainer",
}


t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    ColorFunc = function(params) return colorByMSD(params.xValue) end,

    Yfunc = function(params)
        local hi = math.log(params.value, base) - math.log(params.minValue, base)
        local bye = math.log(params.maxValue, base) - math.log(params.minValue, base)
        return params.GraphLength * (hi / bye)
    end,

    YvalueFunc = function(params)
        local bye = math.log(params.maxValue, base) - math.log(params.minValue, base)
        local why = params.coord / params.GraphLength
        return base^((why * bye) + math.log(params.minValue, base))
    end,

    XvalueToStringFunc = function(params)
        if string.format("%5.2f", params.value) == string.format("%5.2f", notShit.floor(params.value + 0.0001)) then -- if the first two decimal points are 00
            --this is so the x axis labels are integers and arent 12.00, for example
            -- +0.0001 because of floating point nonsense
            return params.value
        else
            return string.format("%5.2f", params.value)
        end
    end,

    YvalueToStringFunc = function(params)
        return string.format("%5.2f", params.value)
    end,

    XaxisLabelColorFunc = function(params)
        local color = colorByMSD(params.value)
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = xAxisLabelInnerLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,

    MinYvalueFunc = function(params)
        return math.min(params.minValue, base^(math.floor(math.log(params.value, base))))
    end,

    MaxYvalueFunc = function(params)
        return math.max(params.maxValue, base^(math.floor(math.log(params.value, base)) + 1))
    end,

    PlotAlpha = plotAlpha,
    XaxisLabelScale = xAxisLabelScale,
    YaxisLabelCount = yAxisLabelCount,
    YaxisLabelOffset = actuals.yAxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth,
    Xunits = "MSD",
    Yunits = "MA"
})

return t