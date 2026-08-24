local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphY = 100 / 1080,
    GraphX = 50 / 1920,
    SkillsetButtonsX = 640 / 1920,
    SkillsetButtonsY = 20 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
}
ratios.GraphTitleCenterX = ratios.Width / 2
ratios.GraphTitleCenterY = 20 / 1080

local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    GraphTitleCenterX = ratios.GraphTitleCenterX * SCREEN_WIDTH,
    GraphTitleCenterY = ratios.GraphTitleCenterY * SCREEN_HEIGHT,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
}

--afaik there isnt a function to convert from 
--grade tier to wife (there isnt an inverse of GetGradeFromPercent())
--so this table will have to do
local gradeTierToWife = { 
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

local function getGradeTierNumber(wife) --e.g. returns 3 from Grade_Tier03
    if wife == 1 then
        return 0
    else
        return tonumber(GetGradeFromPercent(wife):sub(11, 12))
    end
end

local function getLowerGradeBoundary(wife)
    return gradeTierToWife[getGradeTierNumber(wife)]
end

local function getUpperGradeBoundary(wife)
    if wife == 1 then
        return 1
    else
        return gradeTierToWife[getGradeTierNumber(wife) - 1]
    end
end


local smallButtonTextSize = 0.5
local headerTextSize = 1
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
local XaxisLabelCount = (getGradeTierNumber(minWife) - getGradeTierNumber(maxWife)) + 1

SCOREMAN:SortRecentScoresForGame()

local function asinh(x)
    return math.log(x + math.sqrt(x * x + 1))
end

local function setValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
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
            end
        end
    end
end

local values = {}
setValues(values)


local t = Def.ActorFrame{
    Name = "MeanOverAccuracyGraphContainer",
    focused = false,

    InitCommand = function(self)
        self:diffusealpha(0)
    end,

    FocusCommand = function(self)
        self:diffusealpha(1)
        self.focused = true
        self:z(1)
    end,

    UnfocusCommand = function(self)
        self:diffusealpha(0)
        self.focused = false
        self:z(-1)
    end,

    LoadFont("Common Normal") .. {
        Name = "Title",
        InitCommand = function(self)
            self:valign(0)
            self:zoom(headerTextSize)
            self:xy(actuals.GraphTitleCenterX, actuals.GraphTitleCenterY)
            self:settext("Mean over Accuracy")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end,

        UpdateCommand = function(self, params)
            self:settext("Mean over " .. params.skillset .. " MSD")
        end
    },
}

t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Xfunc = function(params) --i fucking hate this
        local wife = params.xValue
        local gradeTier = getGradeTierNumber(wife)
        local minGradeTier = getGradeTierNumber(params.minXvalue)
        local maxGradeTier = getGradeTierNumber(params.maxXvalue)
        if params.maxXvalue == 1 then
            maxGradeTier = 0
        end

        local lowerWifeBound = getLowerGradeBoundary(params.xValue)
        local upperWifeBound
        if gradeTier > 1 then --if its not an AAAAA
            upperWifeBound = getUpperGradeBoundary(params.xValue)
        else
            upperWifeBound = 1
        end
        local numberOfSections = (minGradeTier - maxGradeTier)
        local sectionNumber = minGradeTier - gradeTier --if this is 0 then its the bottom section  3
        local sectionWidth = params.GraphWidth / numberOfSections --39.4

        local progressIntoSection = (wife - lowerWifeBound) / (upperWifeBound - lowerWifeBound) --0

        local y =  ((sectionNumber * sectionWidth) + (sectionWidth * progressIntoSection))
        print(y)
        return y
    end,
    Yfunc = function(params)
        --make it an asinh graph because it squishes big values like a log graph but works nicely for negatives and 0
        local scale = math.max(math.abs(params.minYvalue), math.abs(params.maxYvalue)) / 10
        --higher scale means the graph starts squishing at a higher y value
        --e.g. scale = 0.5 may begin to squish the graph at yValue = 5, but scale = 5 may begin to squish the graph at yValue = 50
        local shit = asinh(params.yValue / scale) - asinh(params.minYvalue / scale)
        local fatShit = asinh(params.maxYvalue / scale) - asinh(params.minYvalue / scale)
        return params.GraphHeight * (1 - (shit / fatShit))
    end,
    XvalueFunc = function(params) --i fucking hate this too
        local stupidX = params.GraphWidth - params.x --cant be bothered to remake this function cleanly so fuck you
        local minGrade = getGradeTierNumber(params.minXvalue)
        local maxGrade = getGradeTierNumber(params.maxXvalue)
        if params.maxXvalue == 1 then --special case for 100%, because we want a label for 100%
            maxGrade = 0
        end
        local numberOfSections = minGrade - maxGrade --how many sections there are in total
        local xPercent = stupidX / params.GraphWidth
        local sectionNumber = notShit.floor(xPercent * numberOfSections)
        local upperSectionBound = ((sectionNumber) / numberOfSections) * params.GraphWidth
        local lowerSectionBound = ((sectionNumber+1) / numberOfSections) * params.GraphWidth
        local progressIntoSection = ((lowerSectionBound - stupidX ) / (lowerSectionBound - upperSectionBound))
        local lowerWifeBound = gradeTierToWife[(minGrade - (numberOfSections - sectionNumber)) + 1]
        local upperWifeBound = gradeTierToWife[minGrade - (numberOfSections - sectionNumber)]
        local acc = (lowerWifeBound + ((upperWifeBound - lowerWifeBound) * progressIntoSection))
        return acc
    end,
    YvalueFunc = function(params)
        local scale = math.max(math.abs(params.minYvalue), math.abs(params.maxYvalue)) / 10
        local fatShit = asinh(params.maxYvalue / scale) - asinh(params.minYvalue / scale)
        local wetFart = 1 - (params.y / params.GraphHeight)
        return math.sinh((fatShit * wetFart) + asinh(params.minYvalue / scale)) * scale
    end,
    XvalueToStringFunc = function(params)
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
        local acc = params.xValue
        if acc == 1 then --special case for 100%
            return tostring(acc * 100) .. "%"
        elseif gradeBoundaries[acc] then --if the acc is EXACTLY a grade boundary, so the y axis labels are labeled with the grade instead of the acc
            --this assumes that the y axis labels lie exactly on the grade boundaries, which should be the case if i've done everything right
            return THEME:GetString("Grade", ToEnumShortString(GetGradeFromPercent(params.xValue)))
        elseif acc > 0.99 then
            return string.format("%7.4f%s", acc * 100, "%")
        else
            return string.format("%7.2f%s", acc * 100, "%")
        end
    end,
    YvalueToStringFunc = function(params)
        return string.format("%5.2f", params.yValue)
    end,
    MinXvalueFunc = function(params)
        return math.min(params.minXvalue, getLowerGradeBoundary(params.xValue))
    end,

    MaxXvalueFunc = function(params)
        return math.max(params.maxXvalue, getUpperGradeBoundary(params.xValue))
    end,
    ColorFunc = function(params) return colorByGrade(GetGradeFromPercent(params.xValue)) end,

    XaxisLabelColorFunc = function(params)
        local color = colorByGrade(GetGradeFromPercent(params.xValue))
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = xAxisLabelInnerLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,
    PlotAlpha = plotAlpha,
    XaxisLabelCount = XaxisLabelCount,
    YaxisLabelCount = YaxisLabelCount,
    YoriginCentered = true,
    Xunits = "Accuracy",
    Yunits = "Mean"
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t