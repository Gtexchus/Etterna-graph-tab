local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
}

local actuals = {
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
}

local XaxisLabelsCount = 5
local YaxisLabelsScale = 4
local plotAlpha = 0.5
local selectedColor = color("#A400FF")

SCOREMAN:SortRecentScoresForGame()

local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local dateText = score:GetDate()
            local ssr = score:GetSkillsetSSR(skillset)
            if dateText ~= nil then
                local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                local index = #values + 1
                values[index] = {}
                values[index][1] = date
                values[index][2] = ssr
            end
        end
    end
end

local values = {}
setValues(values, "overall")


local t = Def.ActorFrame{
    Name = "MSDOverTimeGraphContainer",
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


--make graph

t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    ColorFunc = function(params) return cgf.AxisLabelColorFuncMSD({value = params.yValue}) end,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,

    YvalueToStringFunc = cgf.ValueToStringFuncIntegerOr2DP,

    YaxisLabelColorFunc = cgf.AxisLabelColorFuncMSD,

    XaxisLabelCount = 5,
    YaxisLabelScale = YaxisLabelsScale,
    
    PlotAlpha = plotAlpha,
    Xunits = "Date",
    Yunits = "MSD"
})

return t