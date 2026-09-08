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

local scaleDivisor = 50

local smallButtonTextSize = 0.5
local skillsetButtonsMaxWidth = 100
local buttonHoverAlpha = 0.6
local maxSkillsetButtonsPerColumn = 4
local plotAlpha = 0.5
local XaxisLabelScale = 4
local YaxisLabelCount = 21
local yAxisLabelInnerLineColor = color("#52525280")
local xAxisLabelLineAlpha = 0.3
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

    FinishedLoadingCommand = function(self)
        --loadingHandler has finished loading values
        --so its time to load the graph and other relevant things

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

            ColorFunc = function(params) return colorByMSD(params.xValue) end,

            XaxisLabelColorFunc = function(params)
                return cgf.AxisLabelColorFuncMSD(params, xAxisLabelLineAlpha)
            end,
            YaxisLabelColorFunc = function(params)
                return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
            end,
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
        self:GetChild("SkillsetButtonsContainer"):diffusealpha(1) --make skillset buttons visible
    end
}

--make skillset buttons
local function makeSkillsetButton(skillset_, x, y)
    return UIElements.TextButton(1, 1, "Common Normal") .. {
        Name = skillset_ .. "Button",
        InitCommand = function(self)
            local txt = self:GetChild("Text")
            local bg = self:GetChild("BG")
            self:xy(x, y)
            bg:zoomto(actuals.SkillsetButtonsHorizontalSpacing, actuals.SkillsetButtonsVerticalSpacing)
            txt:zoom(smallButtonTextSize)
            txt:diffusealpha(1)
            txt:settext(ms.SkillSetsTranslatedByName[skillset_])
            txt:maxwidth(skillsetButtonsMaxWidth)
            self:playcommand("Update", {skillset = "Overall"}) --so overall is highlighted when the graph is first loaded
        end,

        UpdateCommand = function(self, params)
            local txt = self:GetChild("Text")
            if params.skillset == skillset_ then
                txt:strokecolor(color("#A400FF"))
            else
                txt:strokecolor(color("0,0,0,0"))
            end
        end,

        ClickCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "OnMouseDown" then
                local graphContainer = self:GetParent():GetParent()
                local plots = graphContainer:GetChild("Graph"):GetChild("Plots")
                local sbc = graphContainer:GetChild("SkillsetButtonsContainer")
                local labelsContainer = self:GetParent():GetParent():GetChild("Graph"):GetChild("LabelsContainer")
                local skillsetButtons = sbc:GetChildren()
                --update everything
                setValuesSkillsetOnly(values, skillset_)
                plots:playcommand("Set")
                sbc:PlayCommandsOnChildren("Update", {skillset = skillset_})
            end
        end,

        RolloverUpdateCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "in" then
                self:diffusealpha(buttonHoverAlpha)
            else
                self:diffusealpha(1)
            end
        end
    }
end
local sbc = Def.ActorFrame{
    Name = "SkillsetButtonsContainer",

    InitCommand = function(self)
        self:xy(actuals.SkillsetButtonsX, actuals.SkillsetButtonsY)
        self:diffusealpha(0) --invisible on init
    end
}
for i=1, #ms.SkillSets do
    sbc[#sbc + 1] = makeSkillsetButton(ms.SkillSets[i], math.floor((i-1)/ maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsHorizontalSpacing, ((i-1) % maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsVerticalSpacing)
end

t[#t + 1] = sbc

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