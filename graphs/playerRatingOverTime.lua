--SCOREMAN:GetPlayerRatingOverTime()
--find out what this does when trying to make a line graph:
--self:SetDrawState {Mode = "DrawMode_LineStrip", First = 1, Num = #v}
--where self is an actorMultiVertex


local smallButtonTextSize = 0.5
local buttonTextSize = 0.7
local headerTextSize = 1
local skillsetButtonsMaxWidth = 50
local bgAlpha = 0.7
local bgColour = color("#000000")
local skillsetColors = {color("#ffffff"), color("#3399ff80"), color("#ff333380"), color("#ff993380"), color("#9966cc80"), color("#00cccc80"), color("#66ff6680"),  color("#ffff6680")}
local buttonHoverAlpha = 0.6

local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    X = 1 - (780 / 1920), --x and y of the box
    Y = 1 - (612 / 1080), 
    
    XaxisYPadding = 100 / 1080, --distance from x axis to bottom of container
    XaxisXPadding = 50 / 1920, --distance from x axis to left of container

    YaxisYPadding = 100 / 1080,
    YaxisXPadding = 50 / 1920,

    SkillsetButtonsCol1 = 660 / 1920,
    SkillsetButtonsCol2 = 720 / 1920,

    SkillsetButtonsRow1 = 20 / 1080,
    SkillsetButtonsRow2 = 40 / 1080,
    SkillsetButtonsRow3 = 60 / 1080,
    SkillsetButtonsRow4 = 80 / 1080

}

--for some fuckass reason you cant reference values in tables during initialisation so they must be done after the fact
ratios.YaxisWidth = 2 / 1920

ratios.XaxisWidth = ratios.Width + ratios.YaxisWidth - (ratios.YaxisXPadding * 2)
ratios.XaxisHeight = 2 / 1920


ratios.YaxisHeight = ratios.Height + ratios.XaxisHeight - (ratios.XaxisYPadding * 2) 

ratios.XaxisX = ratios.XaxisXPadding + ratios.YaxisWidth
ratios.XaxisY = ratios.Height - ratios.XaxisYPadding

ratios.YaxisX = ratios.YaxisXPadding
ratios.YaxisY = ratios.YaxisYPadding

ratios.GraphTitleCenterX = ratios.Width / 2
ratios.GraphTitleCenterY = 20 / 1080


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    XaxisYPadding = ratios.XaxisYPadding * SCREEN_HEIGHT,
    XaxisXPadding = ratios.XaxisXPadding * SCREEN_WIDTH,
    YaxisYPadding = ratios.YaxisYPadding * SCREEN_HEIGHT,
    YaxisXPadding = ratios.YaxisXPadding * SCREEN_WIDTH,
    XaxisWidth = ratios.XaxisWidth * SCREEN_WIDTH,
    XaxisHeight = ratios.XaxisHeight * SCREEN_HEIGHT,
    YaxisWidth = ratios.YaxisWidth * SCREEN_WIDTH,
    YaxisHeight = ratios.YaxisHeight * SCREEN_HEIGHT,
    XaxisX = ratios.XaxisX * SCREEN_WIDTH,
    XaxisY = ratios.XaxisY * SCREEN_HEIGHT,
    YaxisX = ratios.YaxisX * SCREEN_WIDTH,
    YaxisY = ratios.YaxisY * SCREEN_HEIGHT,
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
local lineThickness = (1.5 / 1080) * SCREEN_HEIGHT
local plotAlpha = 1
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


local function placeLineVertices(vertList, x, y, color)
    vertList[#vertList + 1] = {{x - (lineThickness / 2), y - (lineThickness / 2), 0}, color}
    vertList[#vertList + 1] = {{x + (lineThickness / 2), y + (lineThickness / 2), 0}, color}
end



local function playerRatingOverTime() --returns an actorframe of the graph


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


    local t = Def.ActorFrame{
        Name = "playerRatingOverTimeGraph",
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
            Name = "Xaxis",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:diffusealpha(1)
                self:zoomto(actuals.XaxisWidth, actuals.XaxisHeight)
                self:xy(actuals.XaxisX, actuals.XaxisY)
                registerActorToColorConfigElement(self, "main", "SeparationDivider")
            end
        },
        Def.Quad{
            Name = "Yaxis",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:diffusealpha(1)
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

        LoadFont("Common Normal") .. {
            Name = "Title",
            InitCommand = function(self)
                self:valign(0)
                self:zoom(headerTextSize)
                self:xy(actuals.GraphTitleCenterX, actuals.GraphTitleCenterY)
                self:settext("Player rating over time")
                registerActorToColorConfigElement(self, "main", "PrimaryText")
            end
        },

        UIElements.TextToolTip(1, 1, "Common Normal") .. {
            Name = "DisplayXY",
            InitCommand = function(self)
                local mouseOver = false
                self:halign(0):valign(0)
                self:xy(actuals.YaxisX + actuals.YaxisWidth, actuals.YaxisY)
                self:zoomto(actuals.XaxisWidth, actuals.YaxisHeight - actuals.XaxisHeight)
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
            end


        }
    }

    t[#t + 1] = Def.ActorMultiVertex{
        Name = "Plots",
        
        InitCommand = function(self)
            self:diffusealpha(plotAlpha)
            self:xy(actuals.YaxisX + actuals.YaxisWidth, actuals.YaxisY)
            self:playcommand("Plot")
        end,

        PlotCommand = function(self) --plots the points on the graph
            local vertices = {}
            local playerRatingOverTime = SCOREMAN:GetPlayerRatingOverTime()

            --this is needed beacause SCOREMAN:GetPlayerRatingOverTime() is sometimes out of order
            local dates = {}
            for k, _ in pairs(playerRatingOverTime) do
                dates[#dates+1] = k
            end
            --sort the dates
            table.sort(dates, function(a,b) return a:gsub("-", "") < b:gsub("-", "") end)
            local maxSSR = 1
            --find max ssr (this assumes current ssr is the highest its ever been)
            local latest = playerRatingOverTime[dates[#dates]]
            if latest ~= nil then
                for i = 1, #latest do
                    if latest[i] > maxSSR then
                        maxSSR = latest[i]
                    end
                end
            end
            maxSSR = math.floor(maxSSR + 1) --round up

            for i = 1, #skillsetColors do --for every skillset
                local x
                local y
                --this can definitely be optimised
                for j=1, #dates do
                    --dateString = yyyy-mm-dd
                    local dateString = dates[j]
                    local ssr = playerRatingOverTime[dateString][i]
                    local date = os.time({year=dateString:sub(1, 4), month=dateString:sub(6, 7), day=dateString:sub(9, 10)}) --date in ms

                    x = ((date - minDate) / (maxDate - minDate)) * actuals.XaxisWidth

                    y = actuals.YaxisHeight - ((ssr / maxSSR) * actuals.YaxisHeight)

                    if j == 1 then --this is a very hacky solution to allow all skillsets to be drawn in the same amv
                        placeLineVertices(vertices, x, y, color("#00000000"))
                    end
                    placeLineVertices(vertices, x, y, skillsetColors[i])
                        

                end
                
                if x ~= nil and y ~= nil then --need this nil check incase the player has no scores and the inner for loop is skipped
                    placeLineVertices(vertices, x, y, color("#00000000")) --hacky solution part 2
                end
                --basically this hacky solution makes the line that would normally be drawn from the end of one line to the start of another invisible
                --if you are wondering why i needed to do this delete them and see what happens
                --maybe it would have been better to put each skillset in a separate amv
                
            end

            if self:GetNumVertices() ~= 0 then
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
            end
            self:SetVertices(vertices)
            self:SetDrawState {Mode = "DrawMode_QuadStrip", First = 1, Num = #vertices}
        end
    }

    return t
end



return playerRatingOverTime()