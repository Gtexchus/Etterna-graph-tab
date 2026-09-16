local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphWidth = 680 / 1920,
    GraphHeight = 412 / 1080,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    YaxisLabelOffset = 5 / 1920,
}

local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}


local scaleDivisor = 50

local plotAlpha = 0.5
local selectedColor = color("#A400FF")
local XaxisLabelScale = 4
local YaxisLabelCount = 21
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

SCOREMAN:SortRecentScoresForGame()

local function asinh(x)
    return math.log(x + math.sqrt(x * x + 1))
end

local function initialiseValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end
end

local function setValues(values, i, params)
    local score = SCOREMAN:GetRecentScoreForGame(i)
    if score ~= nil then
        local replay = score:GetReplay()
        if replay ~= nil then
            replay:LoadAllData()
            local ov = replay:GetOffsetVector()
            local mean = wifeMean(ov)
            local ssr = score:GetSkillsetSSR(params.skillset)
            local index = #values + 1
            values[index] = {}
            values[index][1] = ssr
            values[index][2] = mean
        end
    end
end

local function setValuesSkillsetOnly(values, skillset) --for skillset buttons
    local index = 1
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local ssr = score:GetSkillsetSSR(skillset)

            values[index][1] = ssr
            index = index + 1
        end
    end
end

local values = {}



local t = Def.ActorFrame{
    Name = "MeanOverMSDGraphContainer",
    InitCommand = function(self)
        --we dont want to see the buttons while loading
        self:GetChild("SingleSelectButtonContainer"):diffusealpha(0)
    end,

    FinishedLoadingCommand = function(self)
        --loadingHandler has finished loading values
        --so its time to load the graph and other relevant things
        if self:GetChild("Graph") then return end --make sure we dont accidentally load multiple graphs

        local graph = LoadActorWithParams("templates/scatterGraph.lua", {
            Values = values,
            Yfunc = function(params)
                return cgf.CoordFuncAsinh(params, scaleDivisor)
            end,

            YvalueFunc = function(params)
                return cgf.ValueFuncAsinh(params, scaleDivisor)
            end,

            XvalueToStringFunc = cgf.ValueToStringFuncIntegerOr2DP,

            YvalueToStringFunc = function(params)
                return string.format("%5.2f", params.value)
            end,

            ColorFunc = function(params) return cgf.AxisLabelColorFuncMSD({value = params.xValue}) end,

            XaxisLabelColorFunc = cgf.AxisLabelColorFuncMSD,

            PlotAlpha = plotAlpha,
            XaxisLabelScale = XaxisLabelScale,
            YaxisLabelCount = YaxisLabelCount,
            YoriginCentered = true,
            Xunits = "MSD",
            Yunits = "Mean",
            YaxisLabelOffset = actuals.YaxisLabelOffset,
            YaxisLabelTextSize = yAxisLabelTextSize,
            YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth,
            GraphWidth = actuals.GraphWidth,
            GraphHeight = actuals.GraphHeight,
        })
        self:AddChild(graph)
        self:GetChild("SingleSelectButtonContainer"):diffusealpha(1) --make skillset buttons visible
    end
}


t[#t + 1] = LoadActorWithParams("commonActors/singleSelectButtons.lua", {
    Values = values,
    OnClick = setValuesSkillsetOnly,
    ButtonNames = ms.SkillSets,
    ButtonValues = ms.SkillSets,
    X = actuals.SkillsetButtonsX,
    Y = actuals.SkillsetButtonsY,
    SelectedColor = selectedColor
})


t[#t + 1] = LoadActorWithParams("commonActors/loadingHandler.lua", {
    Values = values, 
    InitialiseValues = initialiseValues, 
    SetValues = setValues,
    SetValuesParams = {skillset = "overall"},
    NumOfValuesToLoad = SCOREMAN:GetTotalNumberOfScores(),
    Increments = 10,
    X = actuals.GraphWidth / 2,
    Y = actuals.GraphHeight / 2
})

return t