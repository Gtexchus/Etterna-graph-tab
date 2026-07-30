local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphYPadding = 100 / 1080, --distance from x axis to bottom of container
    GraphXPadding = 50 / 1920, --distance from x axis to left of container
    XaxisLabelsYpadding = 20 / 1080,
    YaxisLabelsXpadding = 8 / 1920,
    XaxisLabelLineWidth = 1 / 1920,
    YaxisLabelLineHeight = 1 / 1080
}

--for some fuckass reason you cant reference values in tables during initialisation so they must be done after the fact
ratios.GraphX = ratios.GraphXPadding
ratios.GraphY = ratios.GraphYPadding
ratios.GraphWidth = ratios.Width  - (ratios.GraphXPadding * 2)
ratios.GraphHeight = ratios.Height - (ratios.GraphYPadding * 2) 
ratios.GraphBottom = ratios.GraphY + ratios.GraphHeight

ratios.GraphTitleCenterX = ratios.Width / 2
ratios.GraphTitleCenterY = 20 / 1080
ratios.SkillsetLabelsContainerWidth = ratios.GraphWidth / 3
ratios.SkillsetLabelsContainerHeight = ratios.GraphHeight / 2


local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphYPadding = ratios.GraphYPadding * SCREEN_HEIGHT,
    GraphXPadding = ratios.GraphXPadding * SCREEN_WIDTH,
    GraphYPadding = ratios.GraphYPadding * SCREEN_HEIGHT,
    GraphXPadding = ratios.GraphXPadding * SCREEN_WIDTH,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    GraphBottom = ratios.GraphBottom * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    GraphTitleCenterX = ratios.GraphTitleCenterX * SCREEN_WIDTH,
    GraphTitleCenterY = ratios.GraphTitleCenterY * SCREEN_HEIGHT,
    SkillsetLabelsContainerWidth = ratios.SkillsetLabelsContainerWidth * SCREEN_WIDTH,
    SkillsetLabelsContainerHeight  =ratios.SkillsetLabelsContainerHeight * SCREEN_HEIGHT,
    XaxisLabelsYpadding = ratios.XaxisLabelsYpadding * SCREEN_HEIGHT,
    YaxisLabelsXpadding = ratios.YaxisLabelsXpadding * SCREEN_WIDTH,
    XaxisLabelLineWidth = ratios.XaxisLabelLineWidth * SCREEN_WIDTH,
    YaxisLabelLineHeight = ratios.YaxisLabelLineHeight * SCREEN_HEIGHT
}

--SCOREMAN:GetPlayerRatingOverTime()
--find out what this does when trying to make a line graph:
--self:SetDrawState {Mode = "DrawMode_LineStrip", First = 1, Num = #v}
--where self is an actorMultiVertex

local skillsetLabelsSize = 0.7
local headerTextSize = 1
local bgAlpha = 0.7
local bgColour = color("#000000")
local skillsetColors = {color("#ffffff"), color("#3399ff80"), color("#ff333380"), color("#ff993380"), color("#9966cc80"), color("#00cccc80"), color("#66ff6680"),  color("#ffff6680")}
local xAxisLabelLineColor = color("#52525280")
local yAxisLabelLineColor = color("#52525280")
local buttonHoverAlpha = 0.6
local XaxisLabelsCount = 5
local YaxisLabelsScale = 2
local XaxisLabelsSize = 0.5
local YaxisLabelsSize = 0.5

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




local function placeLineVertices(vertList, x, y, color)
    vertList[#vertList + 1] = {{x - (lineThickness / 2), y - (lineThickness / 2), 0}, color}
    vertList[#vertList + 1] = {{x + (lineThickness / 2), y + (lineThickness / 2), 0}, color}
end

local function placeLineVerticesNoDiagonal(vertList, x, y, color)
    --this is only used to make the line extend to the edge of the graph
    vertList[#vertList + 1] = {{x, y - (lineThickness / 2), 0}, color}
    vertList[#vertList + 1] = {{x, y + (lineThickness / 2), 0}, color}
end



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



local playerRatingOverTime = SCOREMAN:GetPlayerRatingOverTime()

--sort by date
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

--round up to nearest y axis label
maxSSR = (math.floor(maxSSR / YaxisLabelsScale) + 1) * YaxisLabelsScale

local t = Def.ActorFrame{
    Name = "playerRatingOverTimeGraph",
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
            self:settext("Player rating over time")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end
    },

    UIElements.TextToolTip(1, 1, "Common Normal") .. {
        Name = "DisplayXY",
        InitCommand = function(self)
            local mouseOver = false
            self:halign(0):valign(0)
            self:xy(actuals.GraphX, actuals.GraphY)
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
        end


    }
}


--axis labels


local XaxisLabelsContainer = Def.ActorFrame{
    Name = "XaxisLabelsContainer",
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphBottom + actuals.XaxisLabelsYpadding)
    end
}

for i=1, (XaxisLabelsCount) do
    XaxisLabelsContainer[#XaxisLabelsContainer+1] = Def.ActorFrame{
        Name = "XaxisLabel",
        InitCommand = function(self)
            self:x((((i-1)/(XaxisLabelsCount-1)) * actuals.GraphWidth))
        end,

        LoadFont("Common Normal") .. {
            Name = "XaxisLabelStr",
            InitCommand = function(self)
                --self:x(((i-1)/(XaxisLabelsCount-1)) * actuals.GraphWidth)
                self:valign(0)
                self:zoom(XaxisLabelsSize)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local date = (((i-1)/(XaxisLabelsCount-1)) * (maxDate - minDate)) + minDate
                local dateTable = os.date("*t", date)
                local day = tostring(dateTable["day"])
                local month = tostring(dateTable["month"])
                local year = tostring(dateTable["year"])
                if string.len(day) == 1 then --e.g. if its 1 then make it 01
                    day = 0 .. day
                end
                if string.len(month) == 1 then
                    month = 0 .. month
                end
                self:settextf("%s-%s-%s", year, month, day)
            end
        },

        Def.Quad{
            Name = "XaxisLabelLineThatsOutsideOfTheGraph",
            InitCommand = function(self)
                self:valign(0)
                self:y(-actuals.XaxisLabelsYpadding)
                self:zoomto(actuals.XaxisLabelLineWidth, actuals.XaxisLabelsYpadding)
                registerActorToColorConfigElement(self, "main", "SeparationDivider")
            end
        },

        Def.Quad{
            Name = "XaxisLabelLineThatsInsideTheGraph",
            InitCommand = function(self)
                self:valign(0)
                self:y(-(actuals.XaxisLabelsYpadding + actuals.GraphHeight))
                self:zoomto(actuals.XaxisLabelLineWidth, actuals.GraphHeight)
                self:diffuse(xAxisLabelLineColor)
            end
        }
    }
end

t[#t + 1] = XaxisLabelsContainer




local YaxisLabelsContainer = Def.ActorFrame{
    Name = "YaxisLabelsContainer",
    InitCommand = function(self)
        self:xy(actuals.GraphX - actuals.YaxisLabelsXpadding, actuals.GraphBottom)
    end
}

local YaxisLabelsCount = ((maxSSR) / YaxisLabelsScale) + 1

for i=1, (YaxisLabelsCount) do
    YaxisLabelsContainer[#YaxisLabelsContainer+1] = Def.ActorFrame{
        Name = "YaxisLabel",
        InitCommand = function(self)
            self:y(-((i-1)/(YaxisLabelsCount-1)) * actuals.GraphHeight)
        end,

        LoadFont("Common Normal") .. {
            Name = "YaxisLabelStr",
            InitCommand = function(self)
                self:halign(1)
                self:zoom(YaxisLabelsSize)
                self:playcommand("Set")
            end,

            SetCommand = function(self)
                local minSSR = 0
                local msd = (((i-1)/(YaxisLabelsCount-1)) * (maxSSR - minSSR)) + minSSR
                self:settextf("%s", msd)
            end
        },

        Def.Quad{
            Name = "YaxisLabelLineThatsOutsideOfTheGraph",
            InitCommand = function(self)
                self:halign(0)
                self:x(0)
                self:zoomto(actuals.YaxisLabelsXpadding, actuals.YaxisLabelLineHeight)
                registerActorToColorConfigElement(self, "main", "SeparationDivider")
            end
        },

        Def.Quad{
            Name = "YaxisLabelLineThatsInsideTheGraph",
            InitCommand = function(self)
                self:halign(0)
                self:x(actuals.YaxisLabelsXpadding)
                self:zoomto(actuals.GraphWidth, actuals.YaxisLabelLineHeight)
                self:diffuse(xAxisLabelLineColor)
            end
        }
    }
end

t[#t + 1] = YaxisLabelsContainer



--plots

t[#t + 1] = Def.ActorMultiVertex{
    Name = "Plots",
    
    InitCommand = function(self)
        self:diffusealpha(plotAlpha)
        self:xy(actuals.GraphX, actuals.GraphY)
        self:playcommand("Plot")
    end,

    PlotCommand = function(self) --plots the points on the graph
        local vertices = {}
        

        for i = 1, #skillsetColors do --for every skillset
            local x
            local y
            --this can definitely be optimised
            for j=1, #dates do
                --dateString = yyyy-mm-dd
                local dateString = dates[j]
                local ssr = playerRatingOverTime[dateString][i]
                local date = os.time({year=dateString:sub(1, 4), month=dateString:sub(6, 7), day=dateString:sub(9, 10)}) --date in ms

                x = ((date - minDate) / (maxDate - minDate)) * actuals.GraphWidth

                y = actuals.GraphHeight - ((ssr / maxSSR) * actuals.GraphHeight)

                if j == 1 then --this is a very hacky solution to allow all skillsets to be drawn in the same amv
                    placeLineVertices(vertices, x, y, color("#00000000"))
                end
                placeLineVertices(vertices, x, y, skillsetColors[i])
                    

            end
            

            if x ~= nil and y ~= nil then --need this nil check incase the player has no scores and the inner for loop is skipped
                x = actuals.GraphWidth --so we can extend the line to the end of the graph
                placeLineVerticesNoDiagonal(vertices, x, y, skillsetColors[i]) --make the line extend to the end of the graph
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




--skillset box



local skillsetLabelsContainer = Def.ActorFrame{
    Name = "SkillsetLabelsContainer",

    InitCommand = function(self)
        self:diffusealpha(1)
        self:xy(actuals.GraphX + actuals.GraphWidth - actuals.SkillsetLabelsContainerWidth, actuals.GraphY + actuals.GraphHeight - actuals.SkillsetLabelsContainerHeight)
    end,

    Def.Quad{
        Name = "BG",
        InitCommand = function(self)
            self:zoomto(actuals.SkillsetLabelsContainerWidth, actuals.SkillsetLabelsContainerHeight)
            self:diffuse(bgColour)
            self:halign(0):valign(0)
            self:xy(0, 0) 
        end
    },


}


--make the skillset labels box
local profile = GetPlayerOrMachineProfile(PLAYER_1)
for i=1, #ms.SkillSets do
    skillsetLabelsContainer[#skillsetLabelsContainer+1] = Def.ActorFrame{
        Name = "skillset",
        InitCommand = function(self)
            self:y(((i-1)/#ms.SkillSets) * actuals.SkillsetLabelsContainerHeight)
        end,

        LoadFont("Common Normal") .. {
            Name = "SkillsetStr",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:zoom(skillsetLabelsSize)
                self:x(0)
                self:settext(ms.SkillSetsTranslatedByName[ms.SkillSets[i]])
                self:diffuse(skillsetColors[i])
                self:diffusealpha(1)
            end
        },

        LoadFont("Common Normal") .. {
            Name = "SsrStr",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:zoom(skillsetLabelsSize)
                self:x(actuals.SkillsetLabelsContainerWidth/(3/2))
                local ssr = profile:GetPlayerSkillsetRating(ms.SkillSets[i])
                self:settextf("%5.2f", ssr)
                self:diffuse(colorByMSD(ssr))
                self:diffusealpha(1)
            end
        }
    }
end


t[#t+1] = skillsetLabelsContainer






return t