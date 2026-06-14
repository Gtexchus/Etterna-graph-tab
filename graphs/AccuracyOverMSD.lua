local smallButtonTextSize = 0.5
local headerTextSize = 1
local skillsetButtonsMaxWidth = 50
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6
local minWife = 93 --if you dont put minwife and maxwife as the same value as a midgrade it will break
local maxWife = 100
local minMSD = 0
local maxMSD = 40
--the idea is to have each midgrade take up the same physical space on the graph
local gradeTiers = { --GetGradeFromPercent
    [100] = 0,
    [99.9935] = 1,
    [99.98] = 2,
    [99.97] = 3,
    [99.955] = 4,
    [99.9] = 5,
    [99.8] = 6,
    [99.7] = 7,
    [99] = 8,
    [96.5] = 9,
    [93] = 10,
    [90] = 11,
    [85] = 12,
    [80] = 13,
    [70] = 14,
    [60] = 15
}
local gradeBoundaries = {
    99.9935, --AAAAA
    99.98,
    99.97,
    99.955, --AAAA
    99.9,
    99.8,
    99.7, --AAA
    99,
    96.5,
    93, --AA
    90,
    85,
    80, --A
    70, --B
    60 --C
}


local gradeBoundariesInverted = {} --so i can easily find that 99.9 is the 5th grade, etc
for k, v in pairs(gradeBoundaries) do
    gradeBoundariesInverted[v] = k
end


local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    X = 1 - (780 / 1920), --x and y of the box
    Y = 1 - (612 / 1080), 
    
    GraphYPadding = 100 / 1080,
    GraphXPadding = 50 / 1920,

    SkillsetButtonsCol1 = 660 / 1920,
    SkillsetButtonsCol2 = 720 / 1920,

    SkillsetButtonsRow1 = 20 / 1080,
    SkillsetButtonsRow2 = 40 / 1080,
    SkillsetButtonsRow3 = 60 / 1080,
    SkillsetButtonsRow4 = 80 / 1080

}

--for some fuckass reason you cant reference values in tables during initialisation so they must be done after the fact
ratios.GraphX = ratios.GraphXPadding
ratios.GraphY = ratios.GraphYPadding
ratios.GraphWidth = ratios.Width - (ratios.GraphXPadding * 2)
ratios.GraphHeight = ratios.Height - (ratios.GraphYPadding * 2) 
ratios.GraphBottom = ratios.GraphY + ratios.GraphHeight
ratios.GraphTitleCenterX = ratios.Width / 2
ratios.GraphTitleCenterY = 20 / 1080


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphYPadding = ratios.GraphYPadding * SCREEN_HEIGHT,
    GraphXPadding = ratios.GraphXPadding * SCREEN_WIDTH,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    GraphBottom = ratios.GraphBottom * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    GraphTitleCenterX = ratios.GraphTitleCenterX * SCREEN_WIDTH,
    GraphTitleCenterY = ratios.GraphTitleCenterY * SCREEN_HEIGHT,
    SkillsetButtonsCol1 = ratios.SkillsetButtonsCol1 * SCREEN_WIDTH,
    SkillsetButtonsCol2 = ratios.SkillsetButtonsCol2 * SCREEN_WIDTH,
    SkillsetButtonsRow1 = ratios.SkillsetButtonsRow1 * SCREEN_HEIGHT,
    SkillsetButtonsRow2 = ratios.SkillsetButtonsRow2 * SCREEN_HEIGHT,
    SkillsetButtonsRow3 = ratios.SkillsetButtonsRow3 * SCREEN_HEIGHT,
    SkillsetButtonsRow4 = ratios.SkillsetButtonsRow4 * SCREEN_HEIGHT,
    X = ratios.X * SCREEN_WIDTH,
    Y = ratios.Y * SCREEN_HEIGHT,

}

local plotWidth = (3 / 1920) * SCREEN_WIDTH
local plotHeight = (3 / 1080) * SCREEN_HEIGHT
local plotAlpha = 0.5
local plotAnimationSeconds = 1

local genericButtonCommands = { --so i dont have to write these a billion times
    MouseOver = function(self)
        self:diffusealpha(buttonHoverAlpha)
    end,

    MouseOut = function(self)
        self:diffusealpha(1)
    end
}



-- 4 xyz coordinates are given to make up the 4 corners of a quad to draw
local function placeDotVertices(vertList, x, y, color)
    vertList[#vertList + 1] = {{x - (plotWidth/2), y + (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x + (plotWidth/2), y + (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x + (plotWidth/2), y - (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x - (plotWidth/2), y - (plotHeight/2), 0}, color}
end



local function AccuracyOverMSD() --returns an actorframe of the graph


    SCOREMAN:SortRecentScoresForGame()

    local t = Def.ActorFrame{
        Name = "AccuracyOverMSDGraph",
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


        Def.Quad{
            Name = "BG", 
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:diffuse(bgColour)
                self:diffusealpha(bgAlpha)
                self:xy(actuals.GraphX, actuals.GraphY)
                self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
            end
        },

        LoadFont("Common Normal") .. {
            Name = "Title",
            InitCommand = function(self)
                self:valign(0)
                self:zoom(headerTextSize)
                self:xy(actuals.GraphTitleCenterX, actuals.GraphTitleCenterY)
                self:settext("Accuracy over Overall MSD")
                registerActorToColorConfigElement(self, "main", "PrimaryText")
            end
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "OverallButton",
            InitCommand = function(self)
                self:xy(actuals.SkillsetButtonsCol1, actuals.SkillsetButtonsRow1)
                self:zoom(smallButtonTextSize)
                self:diffusealpha(1)
                self:settext("Overall")
                self:maxwidth(skillsetButtonsMaxWidth)

            end,

            MouseDownCommand = function(self)
                if self:GetParent().focused then
                    local plots = self:GetParent():GetChild("Plots")
                    plots:playcommand("SetSkillset", {skillset = "Overall"})
                    plots:playcommand("Plot")
                    self:GetParent():GetChild("Title"):settext("Accuracy over Overall MSD")
                end
            end,

            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "StreamButton",
            InitCommand = function(self)
                self:xy(actuals.SkillsetButtonsCol1, actuals.SkillsetButtonsRow2)
                self:zoom(smallButtonTextSize)
                self:diffusealpha(1)
                self:settext("Stream")
                self:maxwidth(skillsetButtonsMaxWidth)

            end,

            MouseDownCommand = function(self)
                if self:GetParent().focused then
                    local plots = self:GetParent():GetChild("Plots")
                    plots:playcommand("SetSkillset", {skillset = "Stream"})
                    plots:playcommand("Plot")
                    self:GetParent():GetChild("Title"):settext("Accuracy over Stream MSD")
                end
            end,
            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "JumpstreamButton",
            InitCommand = function(self)
                self:xy(actuals.SkillsetButtonsCol1, actuals.SkillsetButtonsRow3)
                self:zoom(smallButtonTextSize)
                self:diffusealpha(1)
                self:settext("Jumpstream")
                self:maxwidth(skillsetButtonsMaxWidth)

            end,

            MouseDownCommand = function(self)
                if self:GetParent().focused then
                    local plots = self:GetParent():GetChild("Plots")
                    plots:playcommand("SetSkillset", {skillset = "Jumpstream"})
                    plots:playcommand("Plot")
                    self:GetParent():GetChild("Title"):settext("Accuracy over Jumpstream MSD")
                end
            end,
            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "HandstreamButton",
            InitCommand = function(self)
                self:xy(actuals.SkillsetButtonsCol1, actuals.SkillsetButtonsRow4)
                self:zoom(smallButtonTextSize)
                self:diffusealpha(1)
                self:settext("Handstream")
                self:maxwidth(skillsetButtonsMaxWidth)

            end,

            MouseDownCommand = function(self)
                if self:GetParent().focused then
                    local plots = self:GetParent():GetChild("Plots")
                    plots:playcommand("SetSkillset", {skillset = "Handstream"})
                    plots:playcommand("Plot")
                    self:GetParent():GetChild("Title"):settext("Accuracy over Handstream MSD")
                end
            end,
            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "StaminaButton",
            InitCommand = function(self)
                self:xy(actuals.SkillsetButtonsCol2, actuals.SkillsetButtonsRow1)
                self:zoom(smallButtonTextSize)
                self:diffusealpha(1)
                self:settext("Stamina")
                self:maxwidth(skillsetButtonsMaxWidth)

            end,

            MouseDownCommand = function(self)
                if self:GetParent().focused then
                    local plots = self:GetParent():GetChild("Plots")
                    plots:playcommand("SetSkillset", {skillset = "Stamina"})
                    plots:playcommand("Plot")
                    self:GetParent():GetChild("Title"):settext("Accuracy over Stamina MSD")
                end
            end,
            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "JackspeedButton",
            InitCommand = function(self)
                self:xy(actuals.SkillsetButtonsCol2, actuals.SkillsetButtonsRow2)
                self:zoom(smallButtonTextSize)
                self:diffusealpha(1)
                self:settext("Jackspeed")
                self:maxwidth(skillsetButtonsMaxWidth)

            end,

            MouseDownCommand = function(self)
                if self:GetParent().focused then
                    local plots = self:GetParent():GetChild("Plots")
                    plots:playcommand("SetSkillset", {skillset = "Jackspeed"})
                    plots:playcommand("Plot")
                    self:GetParent():GetChild("Title"):settext("Accuracy over Jackspeed MSD")
                end
            end,
            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "ChordjackButton",
            InitCommand = function(self)
                self:xy(actuals.SkillsetButtonsCol2, actuals.SkillsetButtonsRow3)
                self:zoom(smallButtonTextSize)
                self:diffusealpha(1)
                self:settext("Chordjack")
                self:maxwidth(skillsetButtonsMaxWidth)

            end,

            MouseDownCommand = function(self)
                if self:GetParent().focused then
                    local plots = self:GetParent():GetChild("Plots")
                    plots:playcommand("SetSkillset", {skillset = "Chordjack"})
                    plots:playcommand("Plot")
                    self:GetParent():GetChild("Title"):settext("Accuracy over Chordjack MSD")
                end
            end,
            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "TechnicalButton",
            InitCommand = function(self)
                self:xy(actuals.SkillsetButtonsCol2, actuals.SkillsetButtonsRow4)
                self:zoom(smallButtonTextSize)
                self:diffusealpha(1)
                self:settext("Technical")
                self:maxwidth(skillsetButtonsMaxWidth)

            end,

            MouseDownCommand = function(self)
                if self:GetParent().focused then
                    local plots = self:GetParent():GetChild("Plots")
                    plots:playcommand("SetSkillset", {skillset = "Technical"})
                    plots:playcommand("Plot")
                    self:GetParent():GetChild("Title"):settext("Accuracy over Technical MSD")
                end
            end,
            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },



        

    }

    t[#t + 1] = Def.ActorMultiVertex{
        Name = "Plots",
        
        InitCommand = function(self)
            self.skillset = "Overall"
            self:diffusealpha(plotAlpha)
            self:xy(actuals.GraphX, actuals.GraphY)
            self:playcommand("Plot")
        end,

        PlotCommand = function(self) --plots the points on the graph
            local vertices = {}
            for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
                local score = SCOREMAN:GetRecentScoreForGame(i)
                if score ~= nil then
                    local wife = score:GetWifeScore() * 100
                    local grade = score:GetWifeGrade()
                    local msd = score:GetSkillsetSSR(self.skillset)
                    if wife >= minWife and wife <= maxWife and grade ~= "Failed" and grade ~= "Grade_Failed" and msd >= minMSD and msd <= maxMSD then
                        
                        
                        local gradeNumber = tonumber(grade:sub(11, 12))
                        local lowerWifeBound = gradeBoundaries[gradeNumber]
                        local upperWifeBound
                        if gradeNumber > 1 then --if its not an AAAAA
                            upperWifeBound = gradeBoundaries[gradeNumber - 1]
                        else
                            upperWifeBound = 100
                        end
                        local numberOfSections = gradeTiers[minWife] - gradeTiers[maxWife] --13
                        local sectionNumber = gradeTiers[minWife] - gradeNumber --if this is 0 then its the bottom section  3
                        local sectionHeight = actuals.GraphHeight / numberOfSections --39.4

                        local progressIntoSection = (wife - lowerWifeBound) / (upperWifeBound - lowerWifeBound) --0

                        local x =  (plotWidth / 2) + (actuals.GraphWidth * ((msd - minMSD) / (maxMSD - minMSD)))
                        local y =  actuals.GraphHeight - ((plotHeight / 2) + (((sectionNumber * sectionHeight) + (sectionHeight * progressIntoSection))))
                        placeDotVertices(vertices, x, y, colorByGrade(score:GetWifeGrade())) 
                        
                    end
                    

                end
            end


            if self:GetNumVertices() ~= 0 then
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
            end
            self:SetVertices(vertices)
            self:SetDrawState {Mode = "DrawMode_Quads", First = 1, Num = #vertices}
        end,

        SetSkillsetCommand = function(self, params)
            self.skillset = params.skillset
        end


    }

    return t
end



return AccuracyOverMSD()