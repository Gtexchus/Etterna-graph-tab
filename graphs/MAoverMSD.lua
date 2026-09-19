local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    yAxisLabelOffset = 5 / 1920,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
}
local actuals = {
    yAxisLabelOffset = ratios.yAxisLabelOffset * SCREEN_WIDTH,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
}


local selectedColor = color("#A400FF")
local plotAlpha = 0.5
local xAxisLabelScale = 4
local yAxisLabelCount = 10
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
    Name = "MAOverMSDGraphContainer",
}

t[#t + 1] = LoadActorWithParams("commonActors/singleSelectButtons.lua", {
    Values = values,
    OnClick = setValues,
    ButtonNames = ms.SkillSets,
    ButtonValues = ms.SkillSets,
    X = actuals.SkillsetButtonsX,
    Y = actuals.SkillsetButtonsY,
    SelectedColor = selectedColor
})

t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    ColorFunc = function(params) return cgf.AxisLabelColorFuncMSD({value = params.xValue}) end,

    Yfunc = function(params)
        return cgf.CoordFuncLog(params, base)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncLog(params, base)
    end,

    XvalueToStringFunc = cgf.ValueToStringFuncIntegerOr2DP,

    YvalueToStringFunc = function(params)
        return string.format("%5.2f", params.value)
    end,

    XaxisLabelColorFunc = cgf.AxisLabelColorFuncMSD,

    --[[ --use this to make the axis labels start and end on some power of base
    MinYvalueFunc = function(params)
        return math.min(params.minValue, base^(math.floor(math.log(params.value, base))))
    end,

    MaxYvalueFunc = function(params)
        return math.max(params.maxValue, base^(math.floor(math.log(params.value, base)) + 1))
    end,
    ]]

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