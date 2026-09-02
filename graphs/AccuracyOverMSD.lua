local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
    YaxisLabelOffset = 5 / 1920,
}


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
}

local commonGraphFunctions = Var("CommonGraphFunctions")

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local smallButtonTextSize = 0.5
local skillsetButtonsMaxWidth = 100
local buttonHoverAlpha = 0.6
--the idea is to have each midgrade take up the same physical space on the graph


local minWife = 0.93
local maxWife = 1
local minFoundWife = 1
local maxFoundWife = 0

local plotAlpha = 0.5
local maxSkillsetButtonsPerColumn = 4

local XaxisLabelsScale = 4
local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelLineAlpha = 0.3
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
local YaxisLabelsCount = (commonGraphFunctions.GetGradeNum(minFoundWife, useMidGrades) - commonGraphFunctions.GetGradeNum(maxFoundWife, useMidGrades)) + 2


local t = Def.ActorFrame{
    Name = "AccuracyOverMSDGraphContainer",
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
                setValues(values, skillset_)
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
    end
}

for i=1, #ms.SkillSets do
    sbc[#sbc + 1] = makeSkillsetButton(ms.SkillSets[i], math.floor((i-1)/ maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsHorizontalSpacing, ((i-1) % maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsVerticalSpacing)
end

t[#t + 1] = sbc


--make graph

--ts is a pain to make
t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Yfunc = function(params) 
        return commonGraphFunctions.CoordFuncAcc(params, useMidGrades)
    end,

    YvalueFunc = function(params)
        return commonGraphFunctions.ValueFuncAcc(params, useMidGrades)
    end,

    ColorFunc = function(params) return colorByGrade(GetGradeFromPercent(params.yValue)) end,
    XvalueToStringFunc = commonGraphFunctions.ValueToStringFuncIntegerOr2DP,

    YvalueToStringFunc = commonGraphFunctions.ValueToStringFuncAcc,

    MinYvalueFunc = function(params)
        return commonGraphFunctions.MinValueFuncAcc(params, useMidGrades)
    end,

    MaxYvalueFunc = function(params)
        return commonGraphFunctions.MaxValueFuncAcc(params, useMidGrades)
    end,

    
    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return commonGraphFunctions.AxisLabelColorFuncAcc(params, yAxisLabelLineAlpha)
    end,

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