local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphWidth = 680 / 1920,
    GraphHeight = 412 / 1080,
    YaxisLabelOffset = 5 / 1920,
}

local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}

local scaleDivisor = 50

local plotAlpha = 0.5
local XaxisLabelCount = 5
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

local function setValues(values, i)
    local score = SCOREMAN:GetRecentScoreForGame(i)
    if score ~= nil then
        local dateText = score:GetDate()
        if dateText ~= nil then
            local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
            local replay = score:GetReplay()
            if replay ~= nil then
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


local t = Def.ActorFrame{
    Name = "MeanOverTimeGraphContainer",

    FinishedLoadingCommand = function(self)
        if self:GetChild("Graph") then return end --make sure we dont accidentally load multiple graphs
        --i dont know how to colour the plots on this one
        local graph = LoadActorWithParams("templates/scatterGraph.lua", {
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

            GraphWidth = actuals.GraphWidth,
            GraphHeight = actuals.GraphHeight,
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