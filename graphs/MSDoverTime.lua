local smallButtonTextSize = 0.5
local headerTextSize = 1
local skillsetButtonsMaxWidth = 50
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6

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

ratios.GraphWidth = ratios.Width - (ratios.GraphXPadding * 2)



ratios.GraphHeight = ratios.Height - (ratios.GraphYPadding * 2) 


ratios.GraphBottom = ratios.Height - ratios.GraphYPadding

ratios.GraphLeft = ratios.GraphXPadding
ratios.GraphTop = ratios.GraphYPadding

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
    GraphLeft = ratios.GraphLeft * SCREEN_WIDTH,
    GraphTop = ratios.GraphTop * SCREEN_HEIGHT,
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



local function MSDoverTime() --returns an actorframe of the graph

    SCOREMAN:SortRecentScoresForGame()


    --i get errors if i dont do this which is annoying
    --loop through scores from earliest until latest until we find a valid date, then break the loop
    local minDateText = nil
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do
        local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i)
        if score ~= nil then
            if score:GetDate() ~= nil then
                minDateText = score:GetDate()
                break
            end
        end
    end


    local minDate
    local maxDate

    if minDateText ~= nil then
        minDate = os.time({year=minDateText:sub(1, 4), month=minDateText:sub(6, 7), day=minDateText:sub(9, 10)}) --mindate in ms
    else
        minDate = os.time(os.date("!*t")) --if we dont have a mindate then today is the mindate
    end

    maxDate = os.time(os.date("!*t")) --current time
        
    
    
    local minMSD = 0
    local maxMSD = 40
    --SCOREMAN:GetRecentScoreForGame
    --SCOREMAN:GetTotalNumberOfScores
    --score:GetSkillsetSSR("Overall")
    --score:GetDate()

    local t = Def.ActorFrame{
        Name = "MSDoverTimeGraph",
        focused = false,

        InitCommand = function(self)
            self:diffusealpha(0)
            --create all graph points here
        end,

        FocusCommand = function(self)
            self:diffusealpha(1)
            self.focused = true
            self:z(1)
            --graphButtonsSetAlpha(self:GetParent():GetParent(), 0) --set graph buttons to invisible
            --removechild
        end,

        UnfocusCommand = function(self)
            self:diffusealpha(0)
            self.focused = false
            self:z(-1)
            --graphButtonsSetAlpha(self:GetParent():GetParent(), 1) --set graph buttons to invisible
        end,


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

        LoadFont("Common Normal") .. {
            Name = "Title",
            InitCommand = function(self)
                self:valign(0)
                self:zoom(headerTextSize)
                self:xy(actuals.GraphTitleCenterX, actuals.GraphTitleCenterY)
                self:settext("Overall MSD over time")
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
                    self:GetParent():GetChild("Title"):settext("Overall MSD over time")
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
                    self:GetParent():GetChild("Title"):settext("Stream MSD over time")
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
                    self:GetParent():GetChild("Title"):settext("Jumpstream MSD over time")
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
                    self:GetParent():GetChild("Title"):settext("Handstream MSD over time")
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
                    self:GetParent():GetChild("Title"):settext("Stamina MSD over time")
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
                    self:GetParent():GetChild("Title"):settext("Jackspeed MSD over time")
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
                    self:GetParent():GetChild("Title"):settext("Chordjack MSD over time")
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
                    self:GetParent():GetChild("Title"):settext("Technical MSD over time")
                end
            end,
            MouseOverCommand = genericButtonCommands["MouseOver"],
            MouseOutCommand = genericButtonCommands["MouseOut"]
        },


        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "DisplayXY",
            InitCommand = function(self)
                local mouseOver = false
                self:halign(0):valign(0)
                self:xy(actuals.GraphLeft, actuals.GraphTop)
                self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
                self:diffusealpha(1)
                
            end,

            MouseOverCommand = function(self)
                if self:GetParent().focused then
                    self.mouseOver = true
                    self:queuecommand("DisplayMouseCoords")
                end
                
            end,

            MouseOutCommand = function(self)
                self.mouseOver = false
                TOOLTIP:Hide()
            end,

            DisplayMouseCoordsCommand = function(self, params)
                if self.mouseOver then
                    local absoluteMouseX = INPUTFILTER:GetMouseX()
                    local absoluteMouseY = INPUTFILTER:GetMouseY()

                    local mouseX = absoluteMouseX - (actuals.X + self.GetX(self))
                    local mouseY = absoluteMouseY - (actuals.Y + self.GetY(self))
                    mouseX = math.floor(mouseX+0.5) --round down
                    mouseY = math.floor(mouseY + 0.5)

                    local date = ((mouseX / actuals.GraphWidth) * (maxDate - minDate)) + minDate --date in ms
                    local dateString = os.date("%x", date) --%x gives the date as a string in mm/dd/yy

                    local msd = maxMSD - ((mouseY / actuals.GraphHeight) * (maxMSD - minMSD))
                    msd = tostring(msd):sub(1, 5) --stop long ass decimals

                    TOOLTIP:SetText("Date: " .. dateString .. " MSD: " .. msd)
                    TOOLTIP:Show()
                    self:sleep(0.05)
                    self:queuecommand("DisplayMouseCoords")
                end
            end


        }


        

    }

    t[#t + 1] = Def.ActorMultiVertex{
        Name = "Plots",
        
        InitCommand = function(self)
            self.skillset = "Overall"
            self:diffusealpha(plotAlpha)
            self:xy(actuals.GraphLeft, actuals.GraphTop)
            self:playcommand("Plot")
        end,

        PlotCommand = function(self) --plots the points on the graph
            local vertices = {}
            for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
                local score = SCOREMAN:GetRecentScoreForGame(i)
                if score ~= nil then
                    local dateText = score:GetDate()
                    local ssr = score:GetSkillsetSSR(self.skillset)
                    if dateText ~= nil and ssr >= minMSD and ssr <= maxMSD then
                        local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                        --the plots would ideally be plotted central to the point, however this causes annoying problems with the plos being drawn inside the x and y axis
                        --this is because if the plot wants to be drawn at x=0, and the plot is central to x=0, then half the plot would go inside the y axis which looks ugly
                        --to fix this i add (plotWidth / 2) to the pos of the plot, so the plot is drawn with the data point at the top left of the plot
                        --if you really care, delete (plotWidth / 2) and (plotHeight / 2). it shouldnt matter, its literally 2 pixels difference
                        local x = (plotWidth / 2) + (actuals.GraphWidth * ((date - minDate) / (maxDate - minDate)))
                        --because positive y is downwards, we work out the y coord as we would normally, then subtract that from GraphHeight
                        --if we didnt do this then the graph would be drawn upside down
                        local y = actuals.GraphHeight - ((plotHeight / 2) + (actuals.GraphHeight * ((ssr - minMSD) / (maxMSD - minMSD))))
                        
                        
                        placeDotVertices(vertices, x, y, colorByMSD(ssr))
                        
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

    --[[
    --very bad code, delete this entire for loop if you dont want tooltips
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local dateText = score:GetDate()
            if dateText ~= nil then
                local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                local x = (actuals.GraphLeft + (plotWidth)) + (actuals.GraphWidth * ((date - minDate) / (maxDate - minDate)))
                local y = (actuals.GraphBottom - (plotHeight)) - (actuals.GraphHeight * ((score:GetSkillsetSSR("Overall") - minMSD) / (maxMSD - minMSD)))


                t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Normal") .. {
                    Name = "plotTooltip",
                    InitCommand = function(self)
                        self:xy(x, y)
                        self:zoomto(plotWidth, plotHeight)
                        self:diffuse(COLORS:getMainColor("PrimaryText"))
                        self:diffusealpha(1)
                    end,

                    MouseOverCommand = function(self)
                        if self:GetParent().focused then
                        
                            TOOLTIP:SetText((tostring(score:GetSkillsetSSR("Overall")):sub(1, 5)) .. "   " .. 
                            SONGMAN:GetSongByChartKey(score:GetChartKey()):GetDisplayMainTitle() .. "   " .. 
                            score:GetDate():sub(1, 10) .. "   " .. 
                            string.format("%.2f", score:GetMusicRate()):gsub("%.?0+$", "") .. "x   " .. 
                            checkWifeStr(score:GetWifeScore()))
                            
                            
                            TOOLTIP:Show()
                        end
                    end,
                    
                    MouseOutCommand = function(self)
                        TOOLTIP:Hide()
                    end,

                    MouseDownCommand = function(self) --click to go to the song
                        if self:GetParent().focused then
                            local w = SCREENMAN:GetTopScreen():GetChild("WheelFile")
                            if w ~= nil then
                                local ck = score:GetChartKey()
                                if ck ~= nil then
                                    w:playcommand("FindSong", {chartkey = ck})
                                end
                            end
                        end
                    end
                }

            end
        end
    end
    ]]--
    

    return t
end











return MSDoverTime()