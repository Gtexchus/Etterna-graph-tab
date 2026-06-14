--credit to martzi for the idea for this graph
local smallButtonTextSize = 0.5
local gradeTextSize = 0.5
local headerTextSize = 1
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6
local plotAlpha = 1
local plotAnimationSeconds = 1




local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphYPadding = 100 / 1080, --distance from x axis to bottom of container
    GraphXPadding = 50 / 1920, --distance from y axis to left of container
    BarWidth = 50 / 1920,
    GradeCountVerticalOffset = 25 / 1080,
    GradeTextVerticalOffset = 10 / 1080,
    GraphTypeButtonX = 700 / 1920,
    GraphTypeButtonY = 20 / 1080
}
ratios.GraphWidth = ratios.Width - (ratios.GraphXPadding * 2)
ratios.GraphHeight = ratios.Height - (ratios.GraphYPadding * 2)
ratios.GraphBottom = ratios.Height - ratios.GraphYPadding
ratios.GraphLeft = ratios.GraphXPadding
ratios.GraphTop = ratios.GraphYPadding
ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 20 / 1080




local actuals = {
    GraphYPadding = ratios.GraphYPadding * SCREEN_HEIGHT,
    GraphXPadding = ratios.GraphXPadding * SCREEN_WIDTH,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    GraphBottom = ratios.GraphBottom * SCREEN_HEIGHT,
    GraphLeft = ratios.GraphLeft * SCREEN_WIDTH,
    GraphTop = ratios.GraphTop * SCREEN_HEIGHT,
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
    GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH,
    GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT,
    GradeCountVerticalOffset = ratios.GradeCountVerticalOffset * SCREEN_HEIGHT,
    GradeTextVerticalOffset = ratios.GradeTextVerticalOffset * SCREEN_HEIGHT,
    GraphTypeButtonX = ratios.GraphTypeButtonX * SCREEN_WIDTH,
    GraphTypeButtonY = ratios.GraphTypeButtonY * SCREEN_HEIGHT
   
}

local genericButtonCommands = { --so i dont have to write these a billion times
    MouseOver = function(self)
        self:diffusealpha(buttonHoverAlpha)
    end,

    MouseOut = function(self)
        self:diffusealpha(1)
    end
}


local function placeBarVerticesTopLeftAnchor(vertList, x, y, w, h, color)
    vertList[#vertList + 1] = {{x, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y, 0}, color}
    vertList[#vertList + 1] = {{x, y, 0}, color}
   
   
end




local function setGradeCounts(gradeCounts, usingEverySetScore)
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


        --this is differnt to the rebirth stats screen because if you have the same song installed twice rebirth counts it both times

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

local grades = {GetGradeFromPercent(100 / 100),
GetGradeFromPercent(99.955 / 100),
GetGradeFromPercent(99.7 / 100),
GetGradeFromPercent(93 / 100),
GetGradeFromPercent(80 / 100),
GetGradeFromPercent(70 / 100),
GetGradeFromPercent(60 / 100),
GetGradeFromPercent(50 / 100),
"Grade_Failed"}

--table of {x, y} values, storing the top left corner of each bar
--this is so we can easily draw the text above each bar
barCoords = {}


t = Def.ActorFrame{
    Name = "GradeDistributionGraph",
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



    Def.Quad{
        Name = "BG",
        InitCommand = function(self)
            self:halign(0):valign(0)
            self:diffuse(bgColour)
            self:diffusealpha(bgAlpha)
            self:xy(actuals.GraphLeft, actuals.GraphTop)
            self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
        end
    },


    UIElements.TextToolTip(1, 1, "Common Normal") .. {
        Name = "GraphTypeButton",
        InitCommand = function(self)
            self:xy(actuals.GraphTypeButtonX, actuals.GraphTypeButtonY)
            self:zoom(smallButtonTextSize)
            self:settext("Using only top scores")
        end,

        MouseDownCommand = function(self)
            local plots = self:GetParent():GetChild("Plots")
            local gradeCount = self:GetParent():GetChild("GradeCount")
            plots:playcommand("ToggleUsingEverySetScore")
            setGradeCounts(gradeCounts, plots.usingEverySetScore)
            plots:playcommand("Plot")
            for i = 1, #gradeCount do
                gradeCount[i]:playcommand("Set")
            end
            if plots.usingEverySetScore then
                self:settext("Using every set score")
            else
                self:settext("Using only top scores")
            end
        end,

        MouseOverCommand = genericButtonCommands["MouseOver"],
        MouseOutCommand = genericButtonCommands["MouseOut"]
    }
}





t[#t + 1] = Def.ActorMultiVertex{
    Name = "Plots",
    
    InitCommand = function(self)
        self.usingEverySetScore = false
        self:diffusealpha(plotAlpha)
        self:xy(actuals.GraphLeft, actuals.GraphTop)
        self:playcommand("Plot")
    end,


    PlotCommand = function(self)
        local vertices = {}
        local barSpacing = (actuals.GraphWidth - (#gradeCounts * actuals.BarWidth)) / (#gradeCounts - 1)

        local maxGrade = 0

        --we cant just do barcoords = {0, 0 etc. due to how lua works
        for i = 1, #barCoords do
            table.remove(barCoords, 1)
        end

        for i = 1, #gradeCounts do
            maxGrade = math.max(maxGrade, gradeCounts[i])
        end

        for i = 1, #gradeCounts do
            local x = (i - 1) * (actuals.BarWidth + barSpacing)
            local y = actuals.GraphHeight - ((actuals.GraphHeight * (gradeCounts[i] / maxGrade)))
            barCoords[#barCoords + 1] = {x, y}
            
            local height = (actuals.GraphHeight * (gradeCounts[i] / maxGrade))
            placeBarVerticesTopLeftAnchor(vertices, x, y, actuals.BarWidth, height, colorByGrade(grades[i]))
        end

        if self:GetNumVertices() ~= 0 then
            self:finishtweening()
            self:smooth(plotAnimationSeconds)
        end
        self:SetVertices(vertices)
        self:SetDrawState {Mode = "DrawMode_Quads", First = 1, Num = #vertices}
    end,

    ToggleUsingEverySetScoreCommand = function(self)
        self.usingEverySetScore = not self.usingEverySetScore
    end
}


for i = 1, #grades do --make the graph labels
    t[#t + 1] = LoadFont("Common Normal") .. {
        --scorecount for each grade and percentage that goes above each bar
        Name = "GradeCount",
        InitCommand = function(self)
            self:zoom(gradeTextSize)
            --we need to set the xy here so it doesnt tween in from (0,0) and look weird
            self:xy(self:GetParent():GetChild("Plots"):GetX() + barCoords[i][1] + (actuals.BarWidth / 2), self:GetParent():GetChild("Plots"):GetY() + barCoords[i][2] - actuals.GradeCountVerticalOffset)
            self:playcommand("Set")
        end,

        SetCommand = function(self)
            self:finishtweening()
            self:smooth(plotAnimationSeconds)
            local totalNumberOfScores = 0
            for i = 1, #gradeCounts do
                totalNumberOfScores = totalNumberOfScores + gradeCounts[i]
            end
            self:xy(self:GetParent():GetChild("Plots"):GetX() + barCoords[i][1] + (actuals.BarWidth / 2), self:GetParent():GetChild("Plots"):GetY() + barCoords[i][2] - actuals.GradeCountVerticalOffset)
            self:settextf("%s \n (%4.2f%s)",gradeCounts[i], (gradeCounts[i] / totalNumberOfScores) * 100, "%")
        end
    }

    t[#t + 1] = LoadFont("Common Normal") .. {
        --grade text that goes under the bar
        Name = "GradeText",
        InitCommand = function(self)
            self:zoom(gradeTextSize)
            self:valign(0)
            self:xy(self:GetParent():GetChild("Plots"):GetX() + barCoords[i][1] + (actuals.BarWidth / 2), self:GetParent():GetChild("Plots"):GetY() + actuals.GraphHeight + actuals.GradeTextVerticalOffset)
            self:settext(getGradeStrings(grades[i])) --THEME:GetString("Grade", ToEnumShortString(grades[i]))
            self:diffuse(colorByGrade(grades[i]))
        end
    }
end

return t

