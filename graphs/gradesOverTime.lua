local ratios = {

}

local actuals = {

}

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
    [15] = 6,
    [16] = 8,
    [17] = 9,
}
SCOREMAN:SortRecentScoresForGame()
local cgf = Var("cgf")

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local samplerate = 7 * 24 * 60 * 60 --time between each sample for the line, in seconds
--lower samplerate makes the line more accurate, but uses more vertices

local minGradeTier = 10 --confusing name because lower acc means higher GradeTier
local maxGradeTier = 1

local function getGradeNumGivenAGradeTier(gradeTier, useMidGrades)
    if useMidGrades then return gradeTier end
    return midGradeNumToGradeNum[gradeTier]
end

local function setValues(values, useMidGrades)
    for i = 1, #values do
        table.remove(values, 1)
    end
    local count = (getGradeNumGivenAGradeTier(minGradeTier, useMidGrades) - getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades)) + 1
    for i=1, count do
        values[#values + 1] = {}
    end
    local i = 0
    while i <= SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local dt = 0
        local minTime = -1

        while minTime < 0 do
            local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i)
            if score ~= nil then
                local dateText = score:GetDate()
                if dateText ~= nil then
                    minTime = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                end
            end
            i = i + 1
        end
        local gradeCountsForThisLoop = {}
        for i = 1, count do
            gradeCountsForThisLoop[i] = 0
        end
        while dt < samplerate and i <= SCOREMAN:GetTotalNumberOfScores() do
            
            local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i) --loop through scores backwards (most recent is last)
            if score ~= nil then
                local grade = score:GetWifeGrade()
                local wife = score:GetWifeScore()
                local gradeTierNumber = tonumber(GetGradeFromPercent(wife):sub(11, 12))
                local dateText = score:GetDate()
                if dateText ~= nil and gradeTierNumber ~= nil and gradeTierNumber <= minGradeTier and gradeTierNumber >= maxGradeTier then
                    local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                    dt = date - minTime --if date > samplerate then break end
                    local relativeGradeNum = getGradeNumGivenAGradeTier(gradeTierNumber, useMidGrades) - (getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades) - 1)

                    gradeCountsForThisLoop[relativeGradeNum] = gradeCountsForThisLoop[relativeGradeNum] + 1
                    ms.ok("inner: " .. relativeGradeNum .. " : " .. gradeCountsForThisLoop[relativeGradeNum])
                end
            end
            i = i + 1
        end
        ms.ok("========================================= END OF LOOP")
        for i=1, #values do
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
            --ms.ok(i .. " : " .. gradeCountsForThisLoop[i])
        end
    end
end

local values = {}
setValues(values, useMidGrades)


local t = Def.ActorFrame{
    Name = "GradesOverTimeGraphContainer",
}


t[#t + 1] = LoadActorWithParams("templates/lineGraph.lua", {
    Values = values,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,
    
    XaxisLabelCount = 5,
    YaxisLabelCount = 5
})

return t