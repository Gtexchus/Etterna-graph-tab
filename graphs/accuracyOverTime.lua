local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    YaxisLabelOffset = 5 / 1920,
}


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH
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
        return tonumber(GetGradeFromPercent(wife):sub(11, 12))
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


local minWife = 0.93
local maxWife = 1
local minFoundWife = 1
local maxFoundWife = 0

local plotAlpha = 0.5

local smallButtonTextSize = 0.5
local buttonHoverAlpha = 0.6
local XaxisLabelsCount = 5
local yAxisLabelLineAlpha = 0.3
local xAxisLabelInnerLineColor = color("#52525280")

local yAxisLabelTextSize = 0.5
local yAxisLabelTextMaxWidth = ((45 / 1920) * SCREEN_WIDTH) / yAxisLabelTextSize --ok trust me this just works

SCOREMAN:SortRecentScoresForGame()
local function setValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local wife = score:GetWifeScore()
            local grade = score:GetWifeGrade()
            local dateText = score:GetDate()
            if dateText ~= nil and wife >= (minWife) and wife <= (maxWife) and grade ~= "Failed" and grade ~= "Grade_Failed" then
                local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                local index = #values + 1
                values[index] = {}
                values[index][1] = date
                values[index][2] = wife
                minFoundWife = math.min(minFoundWife, wife)
                maxFoundWife = math.max(maxFoundWife, wife)
            end
        end
    end
end


local values = {}
setValues(values)
local YaxisLabelsCount = (getGradeNum(minFoundWife) - getGradeNum(maxFoundWife)) + 2

local t = Def.ActorFrame{
    Name = "AccuracyOverTimeGraphContainer",
}


t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    Yfunc = function(params) --i fucking hate this
        local wife = params.value
        local gradeTier = getGradeNum(wife)
        local minGradeTier = getGradeNum(params.minValue)
        local maxGradeTier = getGradeNum(params.maxValue)
        if params.maxValue == 1 then
            maxGradeTier = 0
        end

        local lowerWifeBound = getLowerGradeBoundary(params.value)
        local upperWifeBound
        if gradeTier > 1 then --if its not an AAAAA
            upperWifeBound = getUpperGradeBoundary(params.value)
        else
            upperWifeBound = 1
        end
        local numberOfSections = (minGradeTier - maxGradeTier)
        local sectionNumber = minGradeTier - gradeTier --if this is 0 then its the bottom section
        local sectionHeight = params.GraphLength / numberOfSections --39.4

        local progressIntoSection = (wife - lowerWifeBound) / (upperWifeBound - lowerWifeBound) --0

        local y =  ((sectionNumber * sectionHeight) + (sectionHeight * progressIntoSection))
        return y
    end,
    ColorFunc = function(params) return colorByGrade(GetGradeFromPercent(params.yValue)) end,

    XvalueToStringFunc = function(params)
        local dateTable = os.date("*t", params.value)
        local day = tostring(dateTable["day"])
        local month = tostring(dateTable["month"])
        local year = tostring(dateTable["year"])
        if string.len(day) == 1 then --e.g. if its 1 then make it 01
            day = 0 .. day
        end
        if string.len(month) == 1 then
            month = 0 .. month
        end
        return string.format("%s-%s-%s", year, month, day)
    end,

    YvalueFunc = function(params) --i fucking hate this too
        --here, a "section" is one square on the graph, e.g. gap between AA. and AA:

        --i could use the values of minGrade and maxGrade that are defined in this file,
        --but it feels cleaner to calculate them here using params
        local stupidY = math.max(params.GraphLength - params.coord, 0) --cant be bothered to remake this function cleanly so fuck you
        local minGrade = getGradeNum(params.minValue)
        local maxGrade = getGradeNum(params.maxValue)
        if params.maxValue == 1 then --special case for 100%, because we want a label for 100%
            maxGrade = 0
        end
        local numberOfSections = minGrade - maxGrade --how many sections there are in total
        local yPercent = stupidY / params.GraphLength
        local sectionNumber = notShit.floor(yPercent * numberOfSections) --section we are in, top section is 0
        local upperSectionBound = ((sectionNumber) / numberOfSections) * params.GraphLength
        local lowerSectionBound = ((sectionNumber+1) / numberOfSections) * params.GraphLength
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
        local acc = params.value
        if acc == 1 then --special case for 100%
            return tostring(acc * 100) .. "%"
        elseif gradeBoundaries[acc] then --if the acc is EXACTLY a grade boundary, so the y axis labels are labeled with the grade instead of the acc
            --this assumes that the y axis labels lie exactly on the grade boundaries, which should be the case if i've done everything right
            return THEME:GetString("Grade", ToEnumShortString(GetGradeFromPercent(params.value)))
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
        return math.min(params.minValue, getLowerGradeBoundary(params.value))
    end,

    MaxYvalueFunc = function(params)
        --same as minYvalue, except round up
        return math.max(params.maxValue, getUpperGradeBoundary(params.value))
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
        local color = colorByGrade(GetGradeFromPercent(params.value))
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = yAxisLabelLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end,

    XaxisLabelCount= XaxisLabelsCount,
    YaxisLabelCount = YaxisLabelsCount,
    XaxisLabelInnerLineColor =xAxisLabelInnerLineColor,
    YaxisLabelInnerLineColor = yAxisLabelInnerLineColor,
    PlotAlpha = plotAlpha,
    Xunits = "Date",
    Yunits = "Accuracy",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    YaxisLabelTextSize = yAxisLabelTextSize,
    YaxisLabelTextMaxWidth = yAxisLabelTextMaxWidth
})

return t