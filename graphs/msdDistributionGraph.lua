local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    BarSpacing = 10 / 1920,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
}

local actuals = {
    BarSpacing = ratios.BarSpacing * SCREEN_WIDTH,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
}

local selectedColor = color("#A400FF")
local XaxisScale = 1 --make this either an integer or a fractional power of 2 otherwise it will break due to floating point BS
local minMSD = 0
local maxMSD = 4


local function setMSDcounts(msdCounts, skillset)
    for i=1, #msdCounts do
        msdCounts[i] = 0
    end
    local offset = minMSD - 1 --offset to shift all the indexes so [index of minMSD]= 1
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            if score:GetSkillsetSSR(skillset) ~= 0 then
                local msd = notShit.floor(((score:GetSkillsetSSR(skillset) + (XaxisScale/2)) / XaxisScale)) * XaxisScale
                local index = notShit.floor((msd / XaxisScale) - offset)

                if msdCounts[index] ~= nil then
                    msdCounts[index] = msdCounts[index] + 1
                else
                    msdCounts[index] = 1
                end
            end
        end
    end
end

local function getMSDfromi(i)
    return (i + (minMSD - 1)) * XaxisScale
end

SCOREMAN:SortRecentScoresForGame()


--find max msd
for i = 1, SCOREMAN:GetTotalNumberOfScores() do
    local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - (i-1))
    if score ~= nil then
        if score:GetSkillsetSSR("overall") > maxMSD then
            maxMSD = score:GetSkillsetSSR("overall")
        end
    end
end


local msdCounts = {}
for i=1, (notShit.floor((maxMSD - minMSD) / XaxisScale) + 2) do --set everything we need to 0 (i dont really know why its +2 here, it looks like it should be +1 but that breaks)
    msdCounts[i] = 0
end
setMSDcounts(msdCounts, "overall")


local t = Def.ActorFrame{
    Name = "MSDdistributionContainer",
}


t[#t + 1] = LoadActorWithParams("commonActors/singleSelectButtons.lua", {
    Values = msdCounts,
    OnClick = setMSDcounts,
    ButtonNames = ms.SkillSets,
    ButtonValues = ms.SkillSets,
    X = actuals.SkillsetButtonsX,
    Y = actuals.SkillsetButtonsY,
    SelectedColor = selectedColor
})


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = msdCounts,
    Yfunc = function(params)
        return params.GraphHeight - ((params.GraphHeight * (params.value/ params.maxValue)))
    end,
    ColorFunc = function(params) return colorByMSD(getMSDfromi(params.barNum)) end,
    BarNumToStringFunc = function(params) return getMSDfromi(params.barNum) end,
    BarSpacing = actuals.BarSpacing,
    TopLabelDefaultAlpha = 0
})

return t
