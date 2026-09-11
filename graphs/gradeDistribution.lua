local gradeUtils = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.gradeUtils")

--credit to martzi for the idea for this graph
local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    BarSpacing = 20 / 1920,
    GraphTypeButtonX = 650 / 1920,
    GraphTypeButtonY = -80 / 1080,
    GraphButtonPaddingWidth = 20 / 1920,
    GraphButtonPaddingHeight = 20 / 1080
}

local actuals = {
    BarSpacing = ratios.BarSpacing * SCREEN_WIDTH,
    GraphTypeButtonX = ratios.GraphTypeButtonX * SCREEN_WIDTH,
    GraphTypeButtonY = ratios.GraphTypeButtonY * SCREEN_HEIGHT,
    GraphButtonPaddingWidth = ratios.GraphButtonPaddingWidth * SCREEN_WIDTH,
    GraphButtonPaddingHeight = ratios.GraphButtonPaddingHeight * SCREEN_HEIGHT
}

local bottomLabelTextSize = 0.4
local smallButtonTextSize = 0.5
local buttonHoverAlpha = 0.6
local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")


local function initialise(gradeCounts)
    for i = 1, #gradeCounts do
        table.remove(gradeCounts, 1)
    end
    for i = 1, 17 do
        --AAAAA, AAAA:, AAAA., AAAA, AAA:, AAA., AAA, AA:, AA., AA, A:, A., A, B, C, D, F
        gradeCounts[i] = 0
    end
end

local function squish(gradeCounts) --squishes all midgrades in gradecounts to their full grades
    local newGradeCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0}
    for i=1, #gradeCounts do
        local j = gradeUtils.midGradeNumToGradeNum[i]
        newGradeCounts[j] = newGradeCounts[j] + gradeCounts[i]
    end
    --set gradeCounts = newGradeCounts byValue
    for i=1, #gradeCounts do
        table.remove(gradeCounts, 1)
    end
    for i=1, #newGradeCounts do
        gradeCounts[i] = newGradeCounts[i]
    end
end

local function setGradeCounts(gradeCounts, usingEverySetScore) --todo: clean this up
    --this is so we can easily update the gradeCounts from anywhere
    initialise(gradeCounts)
    if usingEverySetScore then
        for i = 1, SCOREMAN:GetTotalNumberOfScores() do --get grade count
            local score = SCOREMAN:GetRecentScoreForGame(i)
            if score ~= nil then
                local grade = score:GetWifeGrade()
               
                if grade == "Failed" or grade == "Grade_Failed" then --F
                    gradeCounts[17] = gradeCounts[17] + 1
                else
                    local i = tonumber(grade:sub(11, 12))
                    gradeCounts[i] = gradeCounts[i] + 1
                end
            end
        end
    else
        --copied from WheelDataManager.lua
        --this is basically WHEELDATA:GetTotalClearsByGrade but including D's and F's
        --it loops through every song installed, very inefficient i know
        --this is different to the rebirth stats screen because 
        --if you have the same song installed twice rebirth counts it both times, this only counts it once
        local allSongs = SONGMAN:GetAllSongs()
        local countedSongs = {} --table of k = chartkey, v = boolean, to keep track of which charts we have counted
                                --this is so if the same song is installed multiple times we only count it once
        for _, song in ipairs(allSongs) do --for every song on the songwheel
            local foundgrade = nil -- highest grade of at least rate 1.0
            for __, chart in ipairs(WHEELDATA:GetChartsMatchingFilter(song)) do --for every difficulty
                foundgrade = nil
                if countedSongs[chart:GetChartKey()] == nil then --if we havent seen this chart before
                    countedSongs[chart:GetChartKey()] = true
                    local scorestack = SCOREMAN:GetScoresByKey(chart:GetChartKey())
                    -- scorestack is nil if no scores on the chart
                    -- skip if the chart has negbpms: these scores are always invalid for now and ruin lamps
                    if scorestack ~= nil then
                        -- the scores are in lists for each rate
                        -- find the highest
                        for ___, l in pairs(scorestack) do
                            local scoresatrate = l:GetScores()
                            for ____, s in ipairs(scoresatrate) do
                                local grade = s:GetWifeGrade()     
                                if foundgrade == nil then
                                    foundgrade = grade
                                else
                                    -- this returns true if score grade is higher than foundgrade
                                    -- (looking for highest grade in this file)
                                    if compareGrades(grade, foundgrade) then
                                        foundgrade = grade
                                    end
                                end
                            end
                        end 
                    end
                end
                --this is within the chart loop instead of the song loop
                --so one song with multiple difficulties is counted for each difficulty
                if foundgrade == "Failed" or foundgrade == "Grade_Failed" then --F
                    gradeCounts[17] = gradeCounts[17] + 1
                elseif foundgrade ~= nil then
                    local i = tonumber(foundgrade:sub(11, 12))
                    gradeCounts[i] = gradeCounts[i] + 1
                end
            end
        end 
    end
    if not useMidGrades then --if the player is weird
        squish(gradeCounts)
    end
end

SCOREMAN:SortRecentScoresForGame()

local gradeCounts = {}

setGradeCounts(gradeCounts, false)

t = Def.ActorFrame{
    Name = "GradeDistributionGraphContainer",

    UIElements.TextButton(1, 1, "Common Normal") .. {
        Name = "GraphTypeButton",
        InitCommand = function(self)
            self.usingEverySetScore = false
            local txt = self:GetChild("Text")
            local bg = self:GetChild("BG")
            self:xy(actuals.GraphTypeButtonX, actuals.GraphTypeButtonY)
            txt:zoom(smallButtonTextSize)
            txt:settext("Using only top scores")
            bg:zoomto(txt:GetZoomedWidth() + actuals.GraphButtonPaddingWidth, txt:GetZoomedHeight() + actuals.GraphButtonPaddingHeight)
        end,

        ToggleCommand = function(self)
            self.usingEverySetScore = not self.usingEverySetScore
        end,

        ClickCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "OnMouseDown" then
                local txt = self:GetChild("Text")
                local bg = self:GetChild("BG")
                local plots = self:GetParent():GetChild("Graph"):GetChild("Plots")
                local labels = self:GetParent():GetChild("Graph"):GetChild("LabelsContainer")

                self:playcommand("Toggle")
                setGradeCounts(gradeCounts, self.usingEverySetScore)
                plots:playcommand("Set")
                labels:PlayCommandsOnChildren("Set")
                if self.usingEverySetScore then
                    txt:settext("Using every set score")
                else
                    txt:settext("Using only top scores")
                end
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
}

t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = gradeCounts,
    ColorFunc = function(params) 
        return gradeUtils.GetMidGradeColor(params.barNum, useMidGrades)
    end,

    BarNumToStringFunc = function(params) 
        local grades
        --this is bullshit
        if useMidGrades then
            grades = {"Grade_Tier01",
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
            "Grade_Failed"}
        else
            grades = {"Grade_Tier01",
            "Grade_Tier04",
            "Grade_Tier07",
            "Grade_Tier10",
            "Grade_Tier13",
            "Grade_Tier14",
            "Grade_Tier15",
            "Grade_Tier16",
            "Grade_Failed"}
        end


        return getGradeStrings(grades[params.barNum]) 
    end,

    BarSpacing = actuals.BarSpacing,
    BottomLabelTextSize = bottomLabelTextSize,
    TopLabelDefaultAlpha = 0
})

return t

