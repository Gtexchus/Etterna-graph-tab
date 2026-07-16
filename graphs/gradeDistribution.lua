--credit to martzi for the idea for this graph
local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphY = 100 / 1080, --distance from x axis to bottom of container
    GraphX = 50 / 1920, --distance from y axis to left of container
    BarWidth = 50 / 1920,
    GraphTypeButtonX = 700 / 1920,
    GraphTypeButtonY = 20 / 1080,
    GraphButtonPaddingWidth = 20 / 1920,
    GraphButtonPaddingHeight = 20 / 1080
}
ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 20 / 1080

local actuals = {
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
    GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH,
    GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT,
    GraphTypeButtonX = ratios.GraphTypeButtonX * SCREEN_WIDTH,
    GraphTypeButtonY = ratios.GraphTypeButtonY * SCREEN_HEIGHT,
    GraphButtonPaddingWidth = ratios.GraphButtonPaddingWidth * SCREEN_WIDTH,
    GraphButtonPaddingHeight = ratios.GraphButtonPaddingHeight * SCREEN_HEIGHT
}

local smallButtonTextSize = 0.5
local headerTextSize = 1
local buttonHoverAlpha = 0.6

local function setGradeCounts(gradeCounts, usingEverySetScore) --todo: clean this up
    --this is so we can easily update the gradeCounts from anywhere
    for i = 1, #gradeCounts do
        gradeCounts[i] = 0
    end
    if usingEverySetScore then
        for i = 1, SCOREMAN:GetTotalNumberOfScores() do --get grade count
            local score = SCOREMAN:GetRecentScoreForGame(i)
            if score ~= nil then
                local grade = score:GetWifeGrade()
               
                if grade == "Grade_Tier01" then --AAAAA
                    gradeCounts[1] = gradeCounts[1] + 1
                elseif grade == "Grade_Tier02" or grade == "Grade_Tier03" or grade == "Grade_Tier04" then --AAAA
                    gradeCounts[2] = gradeCounts[2] + 1
                elseif grade == "Grade_Tier05" or grade == "Grade_Tier06" or grade == "Grade_Tier07" then --AAA
                    gradeCounts[3] = gradeCounts[3] + 1
                elseif grade == "Grade_Tier08" or grade == "Grade_Tier09" or grade == "Grade_Tier10" then --AA
                    gradeCounts[4] = gradeCounts[4] + 1
                elseif grade == "Grade_Tier11" or grade == "Grade_Tier12" or grade == "Grade_Tier13" then --A
                    gradeCounts[5] = gradeCounts[5] + 1
                elseif grade == "Grade_Tier14" then --B
                    gradeCounts[6] = gradeCounts[6] + 1
                elseif grade == "Grade_Tier15" then --C
                    gradeCounts[7] = gradeCounts[7] + 1
                elseif grade == "Grade_Tier16" then --D
                    gradeCounts[8] = gradeCounts[8] + 1
                elseif grade == "Failed" or grade == "Grade_Failed" then --F
                    gradeCounts[9] = gradeCounts[9] + 1
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
                if foundgrade == "Grade_Tier01" then
                    gradeCounts[1] = gradeCounts[1] + 1
                elseif foundgrade == "Grade_Tier02" or foundgrade == "Grade_Tier03" or foundgrade == "Grade_Tier04" then
                    gradeCounts[2] = gradeCounts[2] + 1
                elseif foundgrade == "Grade_Tier05" or foundgrade == "Grade_Tier06" or foundgrade == "Grade_Tier07" then
                    gradeCounts[3] = gradeCounts[3] + 1
                elseif foundgrade == "Grade_Tier08" or foundgrade == "Grade_Tier09" or foundgrade == "Grade_Tier10" then
                    gradeCounts[4] = gradeCounts[4] + 1
                elseif foundgrade == "Grade_Tier11" or foundgrade == "Grade_Tier12" or foundgrade == "Grade_Tier13" then
                    gradeCounts[5] = gradeCounts[5] + 1
                elseif foundgrade == "Grade_Tier14" then
                    gradeCounts[6] = gradeCounts[6] + 1
                elseif foundgrade == "Grade_Tier15" then
                    gradeCounts[7] = gradeCounts[7] + 1
                elseif foundgrade == "Grade_Tier16" then
                    gradeCounts[8] = gradeCounts[8] + 1
                elseif foundgrade == "Grade_Failed" or foundgrade == "Failed" then
                    gradeCounts[9] = gradeCounts[9] + 1
                end
            end
            
        end
        
    end


end



SCOREMAN:SortRecentScoresForGame()

local gradeCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0}

setGradeCounts(gradeCounts, false)

t = Def.ActorFrame{
    Name = "GradeDistributionGraphContainer",
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
            self:xy(actuals.GraphTitleX, actuals.GraphTitleY)
            self:settext("Grade Distribution")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end
    },

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
        local grades = {GetGradeFromPercent(100 / 100),
        GetGradeFromPercent(99.955 / 100),
        GetGradeFromPercent(99.7 / 100),
        GetGradeFromPercent(93 / 100),
        GetGradeFromPercent(80 / 100),
        GetGradeFromPercent(70 / 100),
        GetGradeFromPercent(60 / 100),
        GetGradeFromPercent(50 / 100),
        "Grade_Failed"}

        return colorByGrade(grades[params.barNum])
    end,

    BarNumToStringFunc = function(params) 
        local grades = {GetGradeFromPercent(100 / 100),
        GetGradeFromPercent(99.955 / 100),
        GetGradeFromPercent(99.7 / 100),
        GetGradeFromPercent(93 / 100),
        GetGradeFromPercent(80 / 100),
        GetGradeFromPercent(70 / 100),
        GetGradeFromPercent(60 / 100),
        GetGradeFromPercent(50 / 100),
        "Grade_Failed"}

        return getGradeStrings(grades[params.barNum]) 
    end,

    BarWidth = actuals.BarWidth
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t

