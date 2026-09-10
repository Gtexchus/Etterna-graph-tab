local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphWidth = 680 / 1920,
    GraphHeight = 412 / 1080,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
    YaxisLabelOffset = 5 / 1920,
}

local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}

local cgf = Var("cgf")

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local scaleDivisor = 10

local smallButtonTextSize = 0.5
local skillsetButtonsMaxWidth = 100
local buttonHoverAlpha = 0.6
local maxSkillsetButtonsPerColumn = 4
local plotAlpha = 0.5
local XaxisLabelScale = 4
local YaxisLabelCount = 21
local yAxisLabelInnerLineColor = color("#52525280")
local xAxisLabelInnerLineAlpha = 0.3

local minWife = 0.93
local maxWife = 1
local minFoundWife = 1
local maxFoundWife = 0
local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

SCOREMAN:SortRecentScoresForGame()

local function initialiseValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end
end

local function setValues(values, i)
    local score = SCOREMAN:GetRecentScoreForGame(i)
    if score ~= nil then
        local wife = score:GetWifeScore()
        if wife >= (minWife) and wife <= (maxWife) and grade ~= "Failed" and grade ~= "Grade_Failed" then
            local replay = score:GetReplay()
            replay:LoadAllData()
            local ov = replay:GetOffsetVector()
            local mean = wifeMean(ov)
            
            local index = #values + 1
            values[index] = {}
            values[index][1] = wife
            values[index][2] = mean
            minFoundWife = math.min(minFoundWife, wife)
            maxFoundWife = math.max(maxFoundWife, wife)
        end
    end
end

local values = {}


local t = Def.ActorFrame{
    Name = "MeanOverAccuracyGraphContainer",

    FinishedLoadingCommand = function(self)
        if self:GetChild("Graph") then return end --make sure we dont accidentally load multiple graphs

        local XaxisLabelCount = (cgf.GetGradeNum(minFoundWife, useMidGrades) - cgf.GetGradeNum(maxFoundWife, useMidGrades)) + 2
        
        local graph = LoadActorWithParams("templates/scatterGraph.lua", {
            Values = values,
            Xfunc = function(params)
                return cgf.CoordFuncAcc(params, useMidGrades)
            end,

            XvalueFunc = function(params)
                return cgf.ValueFuncAcc(params, useMidGrades)
            end,

            Yfunc = function(params)
                return cgf.CoordFuncAsinh(params, scaleDivisor)
            end,

            YvalueFunc = function(params)
                return cgf.ValueFuncAsinh(params, scaleDivisor)
            end,
            XvalueToStringFunc = cgf.ValueToStringFuncAcc,

            YvalueToStringFunc = function(params)
                return string.format("%5.2f", params.value)
            end,
            MinXvalueFunc = function(params)
                return cgf.MinValueFuncAcc(params, useMidGrades)
            end,

            MaxXvalueFunc = function(params)
                return cgf.MaxValueFuncAcc(params, useMidGrades)
            end,

            ColorFunc = function(params) return colorByGrade(GetGradeFromPercent(params.xValue)) end,

            XaxisLabelColorFunc = function(params)
                return cgf.AxisLabelColorFuncAcc(params, xAxisLabelInnerLineAlpha)
            end,

            YaxisLabelColorFunc = function(params)
                return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
            end,
            GraphWidth = actuals.GraphWidth,
            GraphHeight = actuals.GraphHeight,
            PlotAlpha = plotAlpha,
            XaxisLabelCount = XaxisLabelCount,
            YaxisLabelCount = YaxisLabelCount,
            YoriginCentered = true,
            Xunits = "Accuracy",
            Yunits = "Mean",
            YaxisLabelOffset = actuals.YaxisLabelOffset,
            YaxisLabelTextSize = yAxisLabelTextSize,
            YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
        })

        self:AddChild(graph)
    end
}


t[#t + 1] = LoadActorWithParams("commonActors/loadingHandler.lua", {
    Values = values, 
    InitialiseValues = initialiseValues, 
    SetValues = setValues,
    NumOfValuesToLoad = SCOREMAN:GetTotalNumberOfScores(),
    Increments = 10,
    X = actuals.GraphWidth / 2,
    Y = actuals.GraphHeight / 2
})

return t