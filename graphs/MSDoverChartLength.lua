local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
}

local actuals = {
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
}


local smallButtonTextSize = 0.5
local skillsetButtonsMaxWidth = 100
local buttonHoverAlpha = 0.6
local maxSkillsetButtonsPerColumn = 4
local plotAlpha = 0.5
local yAxisLabelScale = 4
local xAxisLabelCount = 10
local yAxisLabelInnerLineAlpha = 0.3
local xAxisLabelInnerLineColor = color("#52525280")

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