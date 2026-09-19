local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")
local gradeUtils = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.gradeUtils")

local ratios = {
    YaxisLabelOffset = 5 / 1920,
    LayerLabelWidth = 70 / 1920
}

local actuals = {
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH,
    LayerLabelWidth = ratios.LayerLabelWidth * SCREEN_WIDTH,
}

local plotAnimationSeconds = 0.5


SCOREMAN:SortRecentScoresForGame()

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local samplerate = 3 * 24 * 60 * 60 --time between each sample for the line, in seconds
--lower samplerate makes the line more accurate, but uses more vertices

local minGradeTier = 13 --confusing name because lower acc means higher GradeTier
local maxGradeTier = 1



local function setValues(values, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    --initialise values
    for i = 1, #values do 
        table.remove(values, 1)
    end
    local count = (gradeUtils.GradeTierToGradeNum(minGradeTier, useMidGrades) - gradeUtils.GradeTierToGradeNum(maxGradeTier, useMidGrades)) + 1
    for i=1, count do
        values[#values + 1] = {}
    end

    local i = 0
    while i <= SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local dt = 0 --chnage in time of scores since we started this sample
        local minTime = -1 --time of the first score in the sample

        while minTime < 0 and i <= SCOREMAN:GetTotalNumberOfScores() do --get the next valid time
            local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - (i-1))
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
            local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - (i-1)) --loop through scores backwards (most recent is last)
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
                    local relativeGradeNum = gradeUtils.GradeTierToGradeNum(gradeTierNumber, useMidGrades) - (gradeUtils.GradeTierToGradeNum(maxGradeTier, useMidGrades) - 1)
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

    for i=1, #values do --make sure there are no empty lines, otherwise there will be errors out the ass
        if #values[i] == 0 then --if the line is empty
            values[i][1] = {os.time(os.date("!*t")), 0} --add a single point at today's date
        end
    end
end

local values = {} --values[1] is the highest acc
setValues(values, useMidGrades)


local layerNames = {}

for i=1, #values do
    local gradeNum = gradeUtils.GradeTierToGradeNum(maxGradeTier, useMidGrades) + (i-1)
    layerNames[i] = getGradeStrings(gradeUtils.GradeNumToGradeTier(gradeNum, useMidGrades))
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
        local gradeNum = params.layer + (gradeUtils.GradeTierToGradeNum(maxGradeTier, useMidGrades) - 1)
        return gradeUtils.GetMidGradeColor(gradeNum, useMidGrades)
    end,
    LayerLabelWidth = actuals.LayerLabelWidth,

    LayerNames = layerNames,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,
    
    XaxisLabelCount = 5,
    YaxisLabelRound = 100,
    Xunits = "Date", 
    Yunits = "",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    TooltipTextSize = 0.3,
    ExtendLinesToEndOfGraph = true,
    PlotAnimationSeconds = plotAnimationSeconds,
})

return t