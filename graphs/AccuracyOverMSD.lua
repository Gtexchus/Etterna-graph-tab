local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
}


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
}

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local function gradeTierToWife(n)
    --afaik there isnt a function to convert from 
    --grade tier to wife (there isnt an inverse of GetGradeFromPercent())
    --so this table will have to do
    local toWife = { 
        [0] = 1, --not technically a grade but its here for convenience
        0.999935, --AAAAA
        0.9998,
        0.9997,
        0.99955, --AAAA
        0.999,
        0.998,
        0.997, --AAA
        0.99,
        0.965,
        0.93, --AA
        0.9,
        0.85,
        0.8, --A
        0.7, --B
        0.6 --C
    }

    local toWifeNoMidGrades = { 
        [0] = 1, --not technically a grade but its here for convenience
        0.999935, --AAAAA
        0.99955, --AAAA
        0.997, --AAA
        0.93, --AA
        0.8, --A
        0.7, --B
        0.6 --C
    }

    if useMidGrades then
        return toWife[n]
    end
    return toWifeNoMidGrades[n]
end

local function getGradeNum(wife) --returns the grade tier number for a given wife%, but if useMidGrades = false, then it pretends that midgrades don't exist
    --this means that if useMidGrades = false, getGradeNum(96.5) returns 4, even though 96.5% is Grade_Tier09
    local function getGradeTierNumber(wife) --e.g. returns 3 from Grade_Tier03
        if wife == 1 then
            return 0
        else
            return tonumber(GetGradeFromPercent(wife):sub(11, 12))
        end
    end

    local midGradeNumToGradeNum = {
        [0] = 0,
        [1] = 1,
        [2] = 2,
        [3] = 2,
        [4] = 2,
        [5] = 3,
        [6] = 3,
        [7] = 3,
        [8] = 4,
        [9] = 4,
        [10] = 4,
        [11] = 5,
        [12] = 5,
        [13] = 5,
        [14] = 6,
        [15] = 6,
        [16] = 8,
        [17] = 9,
    }
    if useMidGrades then
        return getGradeTierNumber(wife)
    end
    return midGradeNumToGradeNum[getGradeTierNumber(wife)]
end

local function getLowerGradeBoundary(wife)
    return gradeTierToWife(getGradeNum(wife))
end

local function getUpperGradeBoundary(wife)
    if wife == 1 then
        return 1
    end
    return gradeTierToWife(getGradeNum(wife) - 1)
end

local smallButtonTextSize = 0.5
local skillsetButtonsMaxWidth = 100
local buttonHoverAlpha = 0.6
--the idea is to have each midgrade take up the same physical space on the graph


local minWife = 0.93
local maxWife = 1

local plotAlpha = 0.5
local maxSkillsetButtonsPerColumn = 4

local XaxisLabelsScale = 4
local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelLineAlpha = 0.3
local YaxisLabelsCount = (getGradeNum(minWife) - getGradeNum(maxWife)) + 1

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
            end
        end
    end
end

local values = {}
setValues(values, "overall")


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
    Yfunc = function(params) --i fucking hate this
        local wife = params.yValue
        local gradeTier = getGradeNum(wife)
        local minGradeTier = getGradeNum(params.minYvalue)
        local maxGradeTier = getGradeNum(params.maxYvalue)
        if params.maxYvalue == 1 then
            maxGradeTier = 0
        end

        local lowerWifeBound = getLowerGradeBoundary(params.yValue)
        local upperWifeBound
        if gradeTier > 1 then --if its not an AAAAA
            upperWifeBound = getUpperGradeBoundary(params.yValue)
        else
            upperWifeBound = 1
        end
        local numberOfSections = (minGradeTier - maxGradeTier)
        local sectionNumber = minGradeTier - gradeTier --if this is 0 then its the bottom section
        local sectionHeight = params.GraphHeight / numberOfSections --39.4

        local progressIntoSection = (wife - lowerWifeBound) / (upperWifeBound - lowerWifeBound) --0

        local y =  ((sectionNumber * sectionHeight) + (sectionHeight * progressIntoSection))
        return y
    end,
    ColorFunc = function(params) return colorByGrade(GetGradeFromPercent(params.yValue)) end,
    XvalueToStringFunc = function(params)
        if string.format("%5.2f", params.xValue) == string.format("%5.2f", notShit.floor(params.xValue + 0.0001)) then -- if the first two decimal points are 00
            --this is so the x axis labels are integers and arent 12.00, for example
            -- +0.0001 because of floating point nonsense
            return tostring(params.xValue)
        else
            return string.format("%5.2f", params.xValue)
        end
    end,


    YvalueFunc = function(params) --i fucking hate this too
        --here, a "section" is one square on the graph, e.g. gap between AA. and AA:

        --i could use the values of minGrade and maxGrade that are defined in this file,
        --but it feels cleaner to calculate them here using params
        local stupidY = params.GraphHeight - params.y --cant be bothered to remake this function cleanly so fuck you
        local minGrade = getGradeNum(params.minYvalue)
        local maxGrade = getGradeNum(params.maxYvalue)
        if params.maxYvalue == 1 then --special case for 100%, because we want a label for 100%
            maxGrade = 0
        end
        local numberOfSections = minGrade - maxGrade --how many sections there are in total
        local yPercent = stupidY / params.GraphHeight
        local sectionNumber = notShit.floor(yPercent * numberOfSections) --section we are in, top section is 0
        local upperSectionBound = ((sectionNumber) / numberOfSections) * params.GraphHeight
        local lowerSectionBound = ((sectionNumber+1) / numberOfSections) * params.GraphHeight
        --[[about upper and lowerSectionBound:
        these are the y coordinates of the top and bottom acc "lines" that make up a section
        upperSectionBound is the one that is higher on the screen, but because positive y is down, upperSectionBound < lowerSectionBound]]
        local progressIntoSection = ((lowerSectionBound - stupidY) / (lowerSectionBound - upperSectionBound))
        local lowerWifeBound = gradeTierToWife((minGrade - (numberOfSections - sectionNumber)) + 1)
        local upperWifeBound = gradeTierToWife(minGrade - (numberOfSections - sectionNumber))
        local acc = (lowerWifeBound + ((upperWifeBound - lowerWifeBound) * progressIntoSection))
        return acc
    end,

    YvalueToStringFunc = function(params)
        local gradeBoundaries = { --stores all grade boundaries for grades
            [1] = true,
            [0.999935] = true,
            [0.9998] = true,
            [0.9997] = true,
            [0.99955] = true,
            [0.999] = true,
            [0.998] = true,
            [0.997] = true,
            [0.99] = true,
            [0.965] = true,
            [0.93] = true,
            [0.9] = true,
            [0.85] = true,
            [0.8] = true,
            [0.7] = true,
            [0.6] = true
        }
        local acc = params.yValue
        if acc == 1 then --special case for 100%
            return tostring(acc * 100) .. "%"
        elseif gradeBoundaries[acc] then --if the acc is EXACTLY a grade boundary, so the y axis labels are labeled with the grade instead of the acc
            --this assumes that the y axis labels lie exactly on the grade boundaries, which should be the case if i've done everything right
            return THEME:GetString("Grade", ToEnumShortString(GetGradeFromPercent(params.yValue)))
        elseif acc > 0.99 then
            return string.format("%7.4f%s", acc * 100, "%")
        else
            return string.format("%7.2f%s", acc * 100, "%")
        end
    end,

    
    MinYvalueFunc = function(params)
        --compare minYvalue with the lower grade boundary of yValue
        --e.g. if yValue = 0.932 (93.2%) then minYvalue is compared with 0.93
        --this is so minYvalue ends up being a grade boundary
        return math.min(params.minYvalue, getLowerGradeBoundary(params.yValue))
    end,

    MaxYvalueFunc = function(params)
        --same as minYvalue, except round up
        return math.max(params.maxYvalue, getUpperGradeBoundary(params.yValue))
    end,

    
    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,
    
    --use this if you want the x axis labels to be colored by msd
    --[[
    XaxisLabelColorFunc = function(params)
        local alpha = 1
        if params.section == "innerLine" then
            alpha = xAxisLabelLineAlpha
        end
        local color = colorByMSD(params.xValue)

        color[4] = alpha
        return color
    end,
    ]]

    YaxisLabelColorFunc = function(params)
        local color = colorByGrade(GetGradeFromPercent(params.yValue))
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = yAxisLabelLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end,

    XaxisLabelScale = XaxisLabelsScale,
    YaxisLabelCount = YaxisLabelsCount,
    PlotAlpha = plotAlpha,
    Xunits = "MSD",
    Yunits = "Accuracy"
})

return t