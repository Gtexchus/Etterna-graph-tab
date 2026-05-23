local smallButtonTextSize = 0.5
local gradeTextSize = 0.5
local buttonTextSize = 0.7
local headerTextSize = 1
local skillsetButtonsMaxWidth = 50
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6
local minWife = 93 --if you dont put minwife and maxwife as the same value as a midgrade it will break
local maxWife = 100
local minMSD = 0
local maxMSD = 40
local plotAlpha = 1
local plotAnimationSeconds = 1




local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    XaxisYPadding = 100 / 1080, --distance from x axis to bottom of container
    YaxisXPadding = 50 / 1920, --distance from y axis to left of container
    XaxisHeight = 2 / 1920,
    YaxisWidth = 2 / 1920,
    BarWidth = 50 / 1920,
    GradeCountVerticalOffset = 25 / 1080,
    GradeTextVerticalOffset = 10 / 1080
}
ratios.XaxisWidth = ratios.Width + ratios.YaxisWidth - (ratios.YaxisXPadding * 2)
ratios.YaxisHeight = ratios.Height + ratios.XaxisHeight - (ratios.XaxisYPadding * 2)


ratios.XaxisX = ratios.YaxisXPadding + ratios.YaxisWidth
ratios.XaxisY = ratios.Height - ratios.XaxisYPadding


ratios.YaxisX = ratios.YaxisXPadding
ratios.YaxisY = ratios.XaxisYPadding


ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 20 / 1080




local actuals = {
    XaxisYPadding = ratios.XaxisYPadding * SCREEN_HEIGHT,
    YaxisXPadding = ratios.YaxisXPadding * SCREEN_WIDTH,
    XaxisHeight = ratios.XaxisHeight * SCREEN_WIDTH,
    YaxisWidth = ratios.YaxisWidth * SCREEN_WIDTH,
    XaxisWidth = ratios.XaxisWidth * SCREEN_WIDTH,
    YaxisHeight = ratios.YaxisHeight * SCREEN_HEIGHT,
    XaxisX = ratios.XaxisX * SCREEN_WIDTH,
    XaxisY = ratios.XaxisY * SCREEN_HEIGHT,
    YaxisX = ratios.YaxisX * SCREEN_WIDTH,
    YaxisY = ratios.YaxisY * SCREEN_HEIGHT,
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
    GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH,
    GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT,
    GradeCountVerticalOffset = ratios.GradeCountVerticalOffset * SCREEN_HEIGHT,
    GradeTextVerticalOffset = ratios.GradeTextVerticalOffset * SCREEN_HEIGHT
   
}


local function placeBarVerticesTopLeftAnchor(vertList, x, y, w, h, color)
    vertList[#vertList + 1] = {{x, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y, 0}, color}
    vertList[#vertList + 1] = {{x, y, 0}, color}
   
   
end




local function gradeDistribution()
    SCOREMAN:SortRecentScoresForGame()


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
            Name = "Xaxis",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:diffusealpha(0)
                self:zoomto(actuals.XaxisWidth, actuals.XaxisHeight)
                self:xy(actuals.XaxisX, actuals.XaxisY)
                registerActorToColorConfigElement(self, "main", "SeparationDivider")
            end
        },
        Def.Quad{
            Name = "Yaxis",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:diffusealpha(0)
                self:zoomto(actuals.YaxisWidth, actuals.YaxisHeight)
                self:xy(actuals.YaxisX, actuals.YaxisY)
                registerActorToColorConfigElement(self, "main", "SeparationDivider")
            end
        },


        Def.Quad{
            Name = "BG",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:diffuse(bgColour)
                self:diffusealpha(bgAlpha)
                self:xy(actuals.YaxisX + actuals.YaxisWidth, actuals.YaxisY)
                self:zoomto(actuals.XaxisWidth, actuals.YaxisHeight - actuals.XaxisHeight)
            end
        },
    }


    local gradeCounts = {WHEELDATA:GetTotalClearsByGrade("Grade_Tier01"), --AAAAA
    WHEELDATA:GetTotalClearsByGrade("Grade_Tier02") + WHEELDATA:GetTotalClearsByGrade("Grade_Tier03") + WHEELDATA:GetTotalClearsByGrade("Grade_Tier04"), --AAAA
    WHEELDATA:GetTotalClearsByGrade("Grade_Tier05") + WHEELDATA:GetTotalClearsByGrade("Grade_Tier06") + WHEELDATA:GetTotalClearsByGrade("Grade_Tier07"), --AAA
    WHEELDATA:GetTotalClearsByGrade("Grade_Tier08") + WHEELDATA:GetTotalClearsByGrade("Grade_Tier09") + WHEELDATA:GetTotalClearsByGrade("Grade_Tier10"), --AA
    WHEELDATA:GetTotalClearsByGrade("Grade_Tier11") + WHEELDATA:GetTotalClearsByGrade("Grade_Tier12") + WHEELDATA:GetTotalClearsByGrade("Grade_Tier13"), --A
    WHEELDATA:GetTotalClearsByGrade("Grade_Tier14"), --B
    WHEELDATA:GetTotalClearsByGrade("Grade_Tier15"), --C
    WHEELDATA:GetTotalClearsByGrade("Grade_Tier16"), --D
    WHEELDATA:GetTotalClearsByGrade("Grade_Failed") + WHEELDATA:GetTotalClearsByGrade("Failed")} --F
   
    local grades = {GetGradeFromPercent(100 / 100),
    GetGradeFromPercent(99.955 / 100),
    GetGradeFromPercent(99.7 / 100),
    GetGradeFromPercent(93 / 100),
    GetGradeFromPercent(80 / 100),
    GetGradeFromPercent(70 / 100),
    GetGradeFromPercent(60 / 100),
    GetGradeFromPercent(50 / 100),
    "Grade_Failed"}
   
    --this counts every set score, e.g. if you get an AA on the same file twice it will coujnt it both times
    --if you want to have this instead of top grades only then set gradeCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0} before this
    --[[
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
    ]]--


    --find highest grade count
    local maxGrade = 0
    for i = 1, #grades do
        maxGrade = math.max(maxGrade, gradeCounts[i])
    end


    barCoords = {}


    t[#t + 1] = Def.ActorMultiVertex{
        Name = "Plots",
       
        InitCommand = function(self)
            self:diffusealpha(plotAlpha)
            self:xy(actuals.YaxisX + actuals.YaxisWidth, actuals.YaxisY)
            self:playcommand("Plot")
        end,


        PlotCommand = function(self)
            local vertices = {}
            local barSpacing = (actuals.XaxisWidth - (#gradeCounts * actuals.BarWidth)) / (#gradeCounts - 1)


            for i = 1, #gradeCounts do
                local x = (i - 1) * (actuals.BarWidth + barSpacing)
                local y = actuals.YaxisHeight - ((actuals.YaxisHeight * (gradeCounts[i] / maxGrade)))
                barCoords[#barCoords + 1] = {x, y}
               
                local height = (actuals.YaxisHeight * (gradeCounts[i] / maxGrade))


                placeBarVerticesTopLeftAnchor(vertices, x, y, actuals.BarWidth, height, colorByGrade(grades[i]))
            end




            if self:GetNumVertices() ~= 0 then
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
            end
            self:SetVertices(vertices)
            self:SetDrawState {Mode = "DrawMode_Quads", First = 1, Num = #vertices}


        end
    }


    for i = 1, #grades do
        t[#t + 1] = LoadFont("Common Normal") .. {
            Name = "GradeCount",
            InitCommand = function(self)
                self:zoom(gradeTextSize)
                self:playcommand("Set")
                
            end,
            SetCommand = function(self)
                local totalNumberOfScores = 0
                for i = 1, #gradeCounts do
                    totalNumberOfScores = totalNumberOfScores + gradeCounts[i]
                end
                self:xy(self:GetParent():GetChild("Plots"):GetX() + barCoords[i][1] + (actuals.BarWidth / 2), self:GetParent():GetChild("Plots"):GetY() + barCoords[i][2] - actuals.GradeCountVerticalOffset)
                self:settextf("%s \n (%4.2f%s)",gradeCounts[i], (gradeCounts[i] / totalNumberOfScores) * 100, "%")
            end
        }


        t[#t + 1] = LoadFont("Common Normal") .. {
            Name = "GradeText",
            InitCommand = function(self)
                self:zoom(gradeTextSize)
                self:valign(0)
                self:xy(self:GetParent():GetChild("Plots"):GetX() + barCoords[i][1] + (actuals.BarWidth / 2), self:GetParent():GetChild("Plots"):GetY() + actuals.YaxisHeight + actuals.GradeTextVerticalOffset)
                self:settext(getGradeStrings(grades[i])) --THEME:GetString("Grade", ToEnumShortString(grades[i]))
                self:diffuse(colorByGrade(grades[i]))
            end
        }
    end
    --


    return t


end




return gradeDistribution()

