--helper functions for grade stuff
local gradeUtils = {}

gradeUtils.GetGradeNum = function(wife, useMidGrades) 
    --returns the grade tier number for a given wife%, but if useMidGrades = false, then it pretends that midgrades don't exist
    --this means that if useMidGrades = false, getGradeNum(96.5) returns 4, even though 96.5% is Grade_Tier09
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
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
        [15] = 7,
        [16] = 8,
        [17] = 9,
    }
    if useMidGrades then
        return getGradeTierNumber(wife)
    end
    return midGradeNumToGradeNum[getGradeTierNumber(wife)]
end


gradeUtils.gradeTierToWife = function(n, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
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
        0.6, --C
        0 --D ????
    }

    local toWifeNoMidGrades = { 
        [0] = 1, --not technically a grade but its here for convenience
        0.999935, --AAAAA
        0.99955, --AAAA
        0.997, --AAA
        0.93, --AA
        0.8, --A
        0.7, --B
        0.6, --C
        0 --D ????
    }

    if useMidGrades then
        return toWife[n]
    end
    return toWifeNoMidGrades[n]
end


gradeUtils.getLowerGradeBoundary = function(wife, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    return gradeUtils.gradeTierToWife(gradeUtils.GetGradeNum(wife, useMidGrades), useMidGrades)
end

gradeUtils.getUpperGradeBoundary = function(wife, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    if wife == 1 then
        return 1
    end
    return gradeUtils.gradeTierToWife(gradeUtils.GetGradeNum(wife, useMidGrades) - 1, useMidGrades)
end

return gradeUtils