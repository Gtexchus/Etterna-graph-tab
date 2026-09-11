--helper functions for grade stuff
local gradeUtils = {}

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

gradeUtils.midGradeNumToGradeNum = {
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

gradeUtils.WifeToGradeNum = function(wife, useMidGrades) 
    --returns the grade tier number for a given wife%, but if useMidGrades = false, then it pretends that midgrades don't exist
    --this means that if useMidGrades = false, getGradeNum(96.5) returns 4, even though 96.5% is Grade_Tier09
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    local function getGradeTierNumber(wife) --e.g. returns 3 from Grade_Tier03
        return tonumber(GetGradeFromPercent(wife):sub(11, 12))
    end

    if useMidGrades then
        return getGradeTierNumber(wife)
    end
    return gradeUtils.midGradeNumToGradeNum[getGradeTierNumber(wife)]
end


gradeUtils.GradeNumToWife = function(gradeNum, useMidGrades)
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
        return toWife[gradeNum]
    end
    return toWifeNoMidGrades[gradeNum]
end

gradeUtils.GradeNumToGradeTier = function(gradeNum, useMidGrades)
    local grades
    --this is bullshit
    if useMidGrades then
        grades = {
            [0] = "Grade_Tier01", --should this even be here???
            "Grade_Tier01",
            "Grade_Tier02",
            "Grade_Tier03",
            "Grade_Tier04",
            "Grade_Tier05",
            "Grade_Tier06",
            "Grade_Tier07",
            "Grade_Tier08",
            "Grade_Tier09",
            "Grade_Tier10",
            "Grade_Tier11",
            "Grade_Tier12",
            "Grade_Tier13",
            "Grade_Tier14",
            "Grade_Tier15",
            "Grade_Tier16",
            "Grade_Failed"
        }
    else
        grades = {
            [0] = "Grade_Tier01", --should this even be here???
            "Grade_Tier01",
            "Grade_Tier04",
            "Grade_Tier07",
            "Grade_Tier10",
            "Grade_Tier13",
            "Grade_Tier14",
            "Grade_Tier15",
            "Grade_Tier16",
            "Grade_Failed"
        }
    end
    return grades[gradeNum]
end

gradeUtils.GradeTierToGradeNum = function(gradeTier, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    if useMidGrades then return gradeTier end
    return gradeUtils.midGradeNumToGradeNum[gradeTier]
end


gradeUtils.GetLowerGradeBoundary = function(wife, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    return gradeUtils.GradeNumToWife(gradeUtils.WifeToGradeNum(wife, useMidGrades), useMidGrades)
end

gradeUtils.GetUpperGradeBoundary = function(wife, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    if wife == 1 then
        return 1
    end
    return gradeUtils.GradeNumToWife(gradeUtils.WifeToGradeNum(wife, useMidGrades) - 1, useMidGrades)
end

--given a gradeNum, returns the color corresponding to that grade
--if the gradeNum is a midGrade, the color returned is somewhere 
--between the midGrade's whole grade and the next whole grade
--differenceFactor is used to determine how close to the next color it should be
--e.g. if gradeNum corresponds to an AA., 
--with differenceFactor = 1, the color will be 33% between AA and AAA
--with differenceFactor = 2, the color will be 16.5% between AA and AAA
--its basically a gradient ok
gradeUtils.GetMidGradeColor = function(gradeNum, useMidGrades, differenceFactor)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    local differenceFactor = differenceFactor or 3
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
    local baseColor = colorByGrade(grades[gradeUtils.midGradeNumToGradeNum[gradeNum]])
    if diff == 0 then 
        return baseColor 
    end
    local nextColor = colorByGrade(grades[gradeUtils.midGradeNumToGradeNum[gradeNum] - 1])
    local color = {}
    for j=1, 4 do
        color[j] = ((nextColor[j] - baseColor[j]) * (diff/(3 * differenceFactor))) + baseColor[j]
    end
    return color
end

return gradeUtils