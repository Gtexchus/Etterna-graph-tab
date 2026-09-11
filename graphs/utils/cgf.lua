--cgf stands for common graph functions
--this is a table of functions that are used often for making graphs
--e.g. CoordFuncAcc is used in AccuracyOverMSD, AccuracyOverTime etc.
local cgf = {}
--------------------------------------- misc functions ---------------------------------------

cgf.GetGradeNum = function(wife, useMidGrades) 
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

--all the bullshit needed for acc graphs

local function gradeTierToWife(n, useMidGrades)
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


local function getLowerGradeBoundary(wife, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    return gradeTierToWife(cgf.GetGradeNum(wife, useMidGrades), useMidGrades)
end

local function getUpperGradeBoundary(wife, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    if wife == 1 then
        return 1
    end
    return gradeTierToWife(cgf.GetGradeNum(wife, useMidGrades) - 1, useMidGrades)
end


local function asinh(x)
    return math.log(x + math.sqrt(x * x + 1))
end

--------------------------------------- params for graphs ---------------------------------------

--coord funcs

--these functions take in a value as an input and output a screen space coordinate on the graph
--these functions are the inverse of ValueFuncs

cgf.CoordFuncAsinh = function(params, scaleDivisor)
    --an asinh graph squishes big values like a log graph but works nicely for negatives and 0
    scaleDivisor = scaleDivisor or 50
    local scale = math.max(math.abs(params.minValue), math.abs(params.maxValue)) / scaleDivisor
    --higher scale means the graph starts squishing at a higher value
    --e.g. scale = 0.5 may begin to squish the graph at value = 5, but scale = 5 may begin to squish the graph at value = 50
    local shit = asinh(params.value / scale) - asinh(params.minValue / scale)
    local fatShit = asinh(params.maxValue / scale) - asinh(params.minValue / scale)
    return params.GraphLength * (shit / fatShit)
end

cgf.CoordFuncLog = function(params, base)
    --a log graph squishes big numbers but doesnt work for values <= 0
    local hi = math.log(params.value, base) - math.log(params.minValue, base)
    local bye = math.log(params.maxValue, base) - math.log(params.minValue, base)
    return params.GraphLength * (hi / bye)
end

cgf.CoordFuncAcc = function(params, useMidGrades) --i fucking hate this
    --this takes in a wife% (e.g. 0.93)
    --each grade between minValue and maxValue is given a section
    --all sections are equally sized
    --the value is then linearly placed inside the section it belongs in
    --e.g., if minValue = 0.93 and maxValue = 0.997, and midgrades are on
    --then there would be 3 sections: one section for AA, one for AA., and one for AA:
    --in this case, if we input 0.95 into this function,
    --it would need to be placed somewhere in the first section, because 0.95 is between 0.93 (AA) and 0.965 (AA.)
    --we use a linear scale to find out where in the first section 0.95 belongs
    --(0.965-0.95)/(0.965-0.93) = 0.43, so the point corresponding to 0.95 is placed 43% between 0.93 and 0.965
    --that is to say, the point corresponding to 0.95 is placed 43% into the first section of the graph
    --since the graph has 3 sections total, 43% / 3 = 14%, so the point is placed 14% along the graph
    --I hope that makes sense

    --this function also treats the gap between AAAAA and 100% as a section, hence why 100% is referred to as having a grade tier of 0
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    local wife = params.value
    local gradeTier = cgf.GetGradeNum(wife, useMidGrades)
    local minGradeTier = cgf.GetGradeNum(params.minValue, useMidGrades)
    local maxGradeTier = cgf.GetGradeNum(params.maxValue, useMidGrades)
    if params.maxValue == 1 then
        maxGradeTier = 0
    end

    local lowerWifeBound = getLowerGradeBoundary(params.value, useMidGrades)
    local upperWifeBound
    if gradeTier > 1 then --if its not an AAAAA
        upperWifeBound = getUpperGradeBoundary(params.value, useMidGrades)
    else
        upperWifeBound = 1
    end
    local numberOfSections = (minGradeTier - maxGradeTier)
    local sectionNumber = minGradeTier - gradeTier --if this is 0 then its the bottom section
    local sectionHeight = params.GraphLength / numberOfSections

    local progressIntoSection = (wife - lowerWifeBound) / (upperWifeBound - lowerWifeBound)

    local y =  ((sectionNumber * sectionHeight) + (sectionHeight * progressIntoSection))
    return y
end



--value funcs

--these functions take in a screen space coordinate and output the corresponding value
--these functions are the inverse of CoordFuncs

cgf.ValueFuncAsinh = function(params, scaleDivisor)
    local scale = math.max(math.abs(params.minValue), math.abs(params.maxValue)) / scaleDivisor
    local fatShit = asinh(params.maxValue / scale) - asinh(params.minValue / scale)
    local wetFart = params.coord / params.GraphLength
    return math.sinh((fatShit * wetFart) + asinh(params.minValue / scale)) * scale
end

cgf.ValueFuncLog = function(params, base)
    local bye = math.log(params.maxValue, base) - math.log(params.minValue, base)
    local why = params.coord / params.GraphLength
    return base^((why * bye) + math.log(params.minValue, base))
end

cgf.ValueFuncAcc = function(params, useMidGrades) --i fucking hate this too
    --here, a "section" is one square on the graph, e.g. gap between AA. and AA:
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    local stupidY = math.max(params.GraphLength - params.coord, 0) --cant be bothered to remake this function cleanly so fuck you
    local minGrade = cgf.GetGradeNum(params.minValue, useMidGrades)
    local maxGrade = cgf.GetGradeNum(params.maxValue, useMidGrades)
    if params.maxValue == 1 then --special case for 100%, because we want a label for 100%
        maxGrade = 0
    end
    local numberOfSections = minGrade - maxGrade --how many sections there are in total
    local yPercent = stupidY / params.GraphLength
    local sectionNumber = notShit.floor(yPercent * numberOfSections) --section we are in, top section is 0
    local upperSectionBound = ((sectionNumber) / numberOfSections) * params.GraphLength
    local lowerSectionBound = ((sectionNumber+1) / numberOfSections) * params.GraphLength
    local progressIntoSection = ((lowerSectionBound - stupidY) / (lowerSectionBound - upperSectionBound))
    local lowerWifeBound = gradeTierToWife((minGrade - (numberOfSections - sectionNumber)) + 1, useMidGrades)
    local upperWifeBound = gradeTierToWife(minGrade - (numberOfSections - sectionNumber), useMidGrades)
    local acc = (lowerWifeBound + ((upperWifeBound - lowerWifeBound) * progressIntoSection))
    return acc
end



--value toString funcs

--these turn a value into a nice readable string format

cgf.ValueToStringFuncIntegerOr2DP = function(params)
    if string.format("%5.2f", params.value) == string.format("%5.2f", notShit.floor(params.value + 0.0001)) then 
        -- if the first two decimal points are 00
        -- +0.0001 because of floating point nonsense
        return params.value
    else
        return string.format("%5.2f", params.value)
    end
end

cgf.ValueToStringFuncTime = function(params)
    --turns milliseconds since the epoch into yyyy/mm/dd
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
end

cgf.ValueToStringFuncAcc = function(params)
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
    elseif gradeBoundaries[acc] then 
        --if the acc is EXACTLY a grade boundary, 
        --so the y axis labels are labeled with the grade instead of the acc
        --this assumes that the y axis labels lie exactly on the grade boundaries, 
        --which should be the case if i've done everything right
        return THEME:GetString("Grade", ToEnumShortString(GetGradeFromPercent(params.value)))
    elseif acc > 0.99 then
        return string.format("%7.4f%s", acc * 100, "%")
    else
        return string.format("%7.2f%s", acc * 100, "%")
    end
end



--axis label color funcs

cgf.AxisLabelColorFuncMSD = function(params, innerLineAlpha)
    innerLineAlpha = innerLineAlpha or 0.3
    local color = colorByMSD(params.value)
    local innerLineColor = {}
    for k, v in pairs(color) do
        innerLineColor[k] = v
    end
    innerLineColor[4] = innerLineAlpha
    return {text = color, outerLine = color, innerLine = innerLineColor}
end

cgf.AxisLabelColorFuncAcc = function(params, innerLineAlpha)
    innerLineAlpha = innerLineAlpha or 0.3
    local color = colorByGrade(GetGradeFromPercent(params.value))
    local innerLineColor = {}
    for k, v in pairs(color) do
        innerLineColor[k] = v
    end
    innerLineColor[4] = innerLineAlpha
    return {text = color, outerLine = color, innerLine = innerLineColor}
end



--min/max value funcs

cgf.MinValueFuncAcc = function(params, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    --compare minValue with the lower grade boundary of value
    --e.g. if yValue = 0.932 (93.2%) then minYvalue is compared with 0.93
    --this is so minYvalue ends up being a grade boundary
    return math.min(params.minValue, getLowerGradeBoundary(params.value, useMidGrades))
end

cgf.MaxValueFuncAcc = function(params, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    --same as MinValueFuncAcc, except round up
    return math.max(params.maxValue, getUpperGradeBoundary(params.value, useMidGrades))
end

return cgf