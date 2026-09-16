local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
}

local actuals = {
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
}


local plotAlpha = 0.5
local selectedColor = color("#A400FF")
local yAxisLabelScale = 4
local xAxisLabelCount = 10

--if you want to zoom in on the highest density section of the graph (where the most scores are)
--try increasing minLen and scaleDivisor
--e.g. you may want to try minLen = 60 and scaleDivisor = 1000
local minLen = 0 --in seconds
local scaleDivisor = 50

SCOREMAN:SortRecentScoresForGame()

local function asinh(x)
    return math.log(x + math.sqrt(x * x + 1))
end


local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local grade = score:GetWifeGrade()
            if grade ~= "Failed" and grade ~= "Grade_Failed" then
                local ssr = score:GetSkillsetSSR(skillset)
                local steps = SONGMAN:GetStepsByChartKey(score:GetChartKey())
                local len = steps:GetLengthSeconds() / score:GetMusicRate()
                if len > minLen then
                    local index = #values + 1
                    values[index] = {}
                    values[index][1] = len
                    values[index][2] = ssr
                end
            end
        end
    end
end

local values = {}
setValues(values, "overall")

local t = Def.ActorFrame{
    Name = "MSDoverChartLengthGraphContainer",
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
    ColorFunc = function(params) return cgf.AxisLabelColorFuncMSD({value = params.yValue}) end,

    Xfunc = function(params)
        return cgf.CoordFuncAsinh(params, scaleDivisor)
    end,

    XvalueFunc = function(params)
        return cgf.ValueFuncAsinh(params, scaleDivisor)
    end,

    YvalueToStringFunc = cgf.ValueToStringFuncIntegerOr2DP,

    XvalueToStringFunc = function(params) return SecondsToMMSS(params.value) end,

    YaxisLabelColorFunc = cgf.AxisLabelColorFuncMSD,

    YaxisLabelScale = yAxisLabelScale,
    XaxisLabelCount = xAxisLabelCount,
    PlotAlpha = plotAlpha,
    Xunits = "Chart length",
    Yunits = "MSD",
})

return t