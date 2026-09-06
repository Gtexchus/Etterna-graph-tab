local ratios = {

}

local actuals = {

}

--slightly confusing terminology used for this; wtf is a gradeNum????
--a gradeNum is basically the end number of a Grade_Tier, e.g. the gradeNum for Grade_Tier08 would be 8
--however, if midgrades are turned off, then gradeNum is the end number of the Grade_Tier if midgrades never existed in the first place
--"What the fuck does this even mean????"
--If midgrades are turned off, then the gradeNum for Grade_Tier08 would be 4
--"Why the fuck does an 8 turn into a 4???"
--Grade_Tier08 corresponds to the midgrade AA: (the : is part of the midgrade)
--the 'whole grade' for AA: is AA
--AA is the 4th grade if you dont include midgrades, as it goes AAAAA, AAAA, AAA, AA, ...
--hence, if midgrades didnt exist, then Grade_Tier08 would actually be Grade_Tier04

local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelInnerLineColor = color("#52525280")

local midGradeNumToGradeNum = {
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
    [15] = 7,
    [16] = 8,
    [17] = 9,
}

SCOREMAN:SortRecentScoresForGame()
local cgf = Var("cgf")

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local samplerate = 7 * 24 * 60 * 60 --time between each sample for the line, in seconds
--lower samplerate makes the line more accurate, but uses more vertices

local minGradeTier = 13 --confusing name because lower acc means higher GradeTier
local maxGradeTier = 1

local function getGradeNumGivenAGradeTier(gradeTier, useMidGrades)
    if useMidGrades then return gradeTier end
    return midGradeNumToGradeNum[gradeTier]
end

--given a gradeNum, returns the color corresponding to that grade
--if the gradeNum is a midGrade, the color returned is somewhere 
--between the midGrade's whole grade and the next whole grade
--differenceFactor is used to determine how close to the next color it should be
--e.g. if gradeNum corresponds to an AA., 
--with differenceFactor = 1, the color will be 33% between AA and AAA
--with differenceFactor = 2, the color will be 16.5% between AA and AAA
--its basically a gradient ok
local function getMidGradeColor(gradeNum, useMidGrades)
    local differenceFactor = 3
    local grades = {"Grade_Tier01",
    "Grade_Tier04",
    "Grade_Tier07",
    "Grade_Tier10",
    "Grade_Tier13",
    "Grade_Tier14",
    "Grade_Tier15",
    "Grade_Tier16",
    "Grade_Failed"}
    if not useMidGrades then
        return colorByGrade(grades[gradeNum])
    end
    local gradeTierStr = tostring(gradeNum)
    if gradeNum < 10 then
        gradeTierStr = "0" .. gradeTierStr
    end
    local gradeFamily = getGradeFamilyForMidGrade("Grade_Tier" .. gradeTierStr):sub(11, 12)
    local diff = gradeFamily - gradeNum
    local baseColor = colorByGrade(grades[midGradeNumToGradeNum[gradeNum]])
    if diff == 0 then 
        return baseColor 
    end
    local nextColor = colorByGrade(grades[midGradeNumToGradeNum[gradeNum] - 1])
    local color = {}
    for j=1, 4 do
        color[j] = ((nextColor[j] - baseColor[j]) * (diff/(3 * differenceFactor))) + baseColor[j]
    end
    return color
end

local function setValues(values, useMidGrades)
    --initialise values
    for i = 1, #values do 
        table.remove(values, 1)
    end
    local count = (getGradeNumGivenAGradeTier(minGradeTier, useMidGrades) - getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades)) + 1
    for i=1, count do
        values[#values + 1] = {}
    end

    local i = 0
    while i <= SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local dt = 0 --chnage in time of scores since we started this sample
        local minTime = -1 --time of the first score in the sample

        while minTime < 0 do --get the next valid time
            local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i)
            if score ~= nil then
                local dateText = score:GetDate()
                if dateText ~= nil then
                    minTime = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                    break --make sure to break so we dont skip over a score
                end
            end
            i = i + 1
        end

        local gradeCountsForThisLoop = {} -- count up all grades of scores we find within this sample
        for i = 1, count do --initialise
            gradeCountsForThisLoop[i] = 0
        end
        --while we are still within the time bounds for this sample
        while dt < samplerate and i <= SCOREMAN:GetTotalNumberOfScores() do
            local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i) --loop through scores backwards (most recent is last)
            if score ~= nil then
                local grade = score:GetWifeGrade()
                local wife = score:GetWifeScore()
                local gradeTierNumber = tonumber(GetGradeFromPercent(wife):sub(11, 12))
                local dateText = score:GetDate()
                if dateText ~= nil and gradeTierNumber ~= nil and gradeTierNumber <= minGradeTier and gradeTierNumber >= maxGradeTier then
                    local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                    dt = date - minTime --update dt with the new change in time
                    if dt > samplerate then break end --too much time has passed, end the sample!
                    --relative to maxGradeTier
                    --e.g. if gradeTierNumber = 5 and maxGradeTier = 5, then relativeGradeNum = 1
                    local relativeGradeNum = getGradeNumGivenAGradeTier(gradeTierNumber, useMidGrades) - (getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades) - 1)
                    --incrament the grade count by one
                    gradeCountsForThisLoop[relativeGradeNum] = gradeCountsForThisLoop[relativeGradeNum] + 1
                end
            end
            i = i + 1
        end
        for i=1, #values do --add all of gradeCountsForThisLoop to values
            if gradeCountsForThisLoop[i] > 0 then
                local index = #values[i] + 1
                local prev
                if index > 1 then
                    prev = values[i][index - 1][2]
                else
                    prev = 0
                end
                values[i][index] = {}
                values[i][index][1] = minTime + samplerate
                values[i][index][2] = prev + gradeCountsForThisLoop[i]
            end
        end
    end
end

local values = {} --values[1] is the highest acc
setValues(values, useMidGrades)


local layerNames = {}

for i=1, #values do
    local gradeNum = maxGradeTier + (i-1)
    if gradeNum < 10 then
        gradeNum = 0 .. tostring(gradeNum)
    else
        gradeNum = tostring(gradeNum)
    end
    layerNames[i] = getGradeStrings("Grade_Tier" .. gradeNum)
end

local t = Def.ActorFrame{
    Name = "GradesOverTimeGraphContainer",
}


t[#t + 1] = LoadActorWithParams("templates/lineGraph.lua", {
    Values = values,

    YvalueToStringFunc = function(params)
        return tostring(notShit.floor(params.value))
    end,

    ColorFunc = function(params) 
        local gradeNum = params.layer + (getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades) - 1)
        return getMidGradeColor(gradeNum, useMidGrades)
    end,

    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,

    LayerNames = layerNames,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,
    
    XaxisLabelCount = 5,
    YaxisLabelScale = 200,
    Xunits = "Date", 
    Yunits = "",
    TooltipTextSize = 0.3,
    ExtendLinesToEndOfGraph = true
})

return t