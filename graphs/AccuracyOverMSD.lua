local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")
local gradeUtils = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.gradeUtils")

local ratios = {
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    YaxisLabelOffset = 5 / 1920,
}


local actuals = {
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}


local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local minWife = 0.93
local maxWife = 1
local minFoundWife = 1
local maxFoundWife = 0

local plotAlpha = 0.5

local selectedColor = color("#A400FF")

local XaxisLabelsScale = 4
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

SCOREMAN:SortRecentScoresForGame()

local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local ssr = score:GetSkillsetSSR(skillset)
            local wife = score:GetWifeScore()
            local grade = score:GetWifeGrade()
            if wife >= (minWife) and wife <= (maxWife) and grade ~= "Failed" and grade ~= "Grade_Failed" then
                local index = #values + 1
                values[index] = {}
                values[index][1] = ssr
                values[index][2] = wife
                minFoundWife = math.min(minFoundWife, wife)
                maxFoundWife = math.max(maxFoundWife, wife)
            end
        end
    end
end

local values = {}
setValues(values, "overall")
local YaxisLabelsCount = (gradeUtils.WifeToGradeNum(minFoundWife, useMidGrades) - gradeUtils.WifeToGradeNum(maxFoundWife, useMidGrades)) + 2


local t = Def.ActorFrame{
    Name = "AccuracyOverMSDGraphContainer",
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


--ts is a pain to make
t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Yfunc = function(params) 
        return cgf.CoordFuncAcc(params, useMidGrades)
    end,

    YvalueFunc = function(params)
        return cgf.ValueFuncAcc(params, useMidGrades)
    end,

    ColorFunc = function(params) return cgf.AxisLabelColorFuncAcc({value = params.yValue}) end,
    XvalueToStringFunc = cgf.ValueToStringFuncIntegerOr2DP,

    YvalueToStringFunc = cgf.ValueToStringFuncAcc,

    MinYvalueFunc = function(params)
        return cgf.MinValueFuncAcc(params, useMidGrades)
    end,

    MaxYvalueFunc = function(params)
        return cgf.MaxValueFuncAcc(params, useMidGrades)
    end,

    YaxisLabelColorFunc = cgf.AxisLabelColorFuncAcc,

    XaxisLabelScale = XaxisLabelsScale,
    YaxisLabelCount = YaxisLabelsCount,
    PlotAlpha = plotAlpha,
    Xunits = "MSD",
    Yunits = "Accuracy",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
})

return t