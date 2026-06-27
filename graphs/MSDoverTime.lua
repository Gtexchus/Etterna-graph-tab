local smallButtonTextSize = 0.5
local headerTextSize = 1
local skillsetButtonsMaxWidth = 50
local bgAlpha = 0.7
local bgColour = color("#000000")
local xAxisLabelLineColor = color("#52525280")
local yAxisLabelLineColor = color("#52525280")
local buttonHoverAlpha = 0.6
local XaxisLabelsCount = 5
local YaxisLabelsScale = 4
local XaxisLabelsSize = 0.5
local YaxisLabelsSize = 0.5

local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    X = 1 - (780 / 1920), --x and y of the box
    Y = 1 - (612 / 1080), 
    GraphYPadding = 100 / 1080,
    GraphXPadding = 50 / 1920,
    SkillsetButtonsX = 660 / 1920,
    SkillsetButtonsY = 20 / 1080,
    SkillsetButtonsHorizontalSpacing = 60 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
    XaxisLabelsYpadding = 20 / 1080,
    YaxisLabelsXpadding = 8 / 1920,
    XaxisLabelLineWidth = 1 / 1920,
    YaxisLabelLineHeight = 1 / 1080
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
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
    X = ratios.X * SCREEN_WIDTH,
    Y = ratios.Y * SCREEN_HEIGHT,
    XaxisLabelsYpadding = ratios.XaxisLabelsYpadding * SCREEN_HEIGHT,
    YaxisLabelsXpadding = ratios.YaxisLabelsXpadding * SCREEN_WIDTH,
    XaxisLabelLineWidth = ratios.XaxisLabelLineWidth * SCREEN_WIDTH,
    YaxisLabelLineHeight = ratios.YaxisLabelLineHeight * SCREEN_HEIGHT
}

local plotWidth = (3 / 1920) * SCREEN_WIDTH
local plotHeight = (3 / 1080) * SCREEN_HEIGHT
local plotAlpha = 0.5
local plotAnimationSeconds = 1
local maxSkillsetButtonsPerColumn = 4

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


local function makeSkillsetButton(skillset_, x, y)
    return UIElements.TextToolTip(1, 1, "Common Normal") .. {
        Name = skillset_ .. "Button",
        InitCommand = function(self)
            self:xy(x, y)
            self:zoom(smallButtonTextSize)
            self:diffusealpha(1)
            self:settext(ms.SkillSetsTranslatedByName[skillset_])
            self:maxwidth(skillsetButtonsMaxWidth)

        end,

        MouseDownCommand = function(self)
            local graphContainer = self:GetParent():GetParent()
            if graphContainer.focused then
                local plots = graphContainer:GetChild("Graph"):GetChild("Plots")
                plots:playcommand("SetSkillset", {skillset = skillset_})
                plots:playcommand("Plot")
                graphContainer:GetChild("Title"):settext(skillset_ .. " MSD over time")
            end
        end,

        MouseOverCommand = genericButtonCommands["MouseOver"],
        MouseOutCommand = genericButtonCommands["MouseOut"]
    }
end



SCOREMAN:SortRecentScoresForGame()

local minDate
local maxDate
local minMSD = 0
local maxMSD = 4

--i get errors if i dont do this which is annoying
--loop through scores from earliest until latest until we find a valid date, then break the loop
local minDateText = nil
for i = 1, SCOREMAN:GetTotalNumberOfScores() do
    local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i)
    if score ~= nil then
        if score:GetDate() ~= nil and minDateText == nil then
            minDateText = score:GetDate()
        end
        if score:GetSkillsetSSR("overall") > maxMSD then
            maxMSD = score:GetSkillsetSSR("overall")
        end
    end
end


--round maxMSD up to the nearest y axis label
maxMSD = (math.floor(maxMSD / YaxisLabelsScale) + 1) * YaxisLabelsScale

if minDateText ~= nil then
    minDate = os.time({year=minDateText:sub(1, 4), month=minDateText:sub(6, 7), day=minDateText:sub(9, 10)}) --mindate in ms
else
    minDate = os.time(os.date("!*t")) --if we dont have a mindate then today is the mindate
end

maxDate = os.time(os.date("!*t")) --current time
    


local t = Def.ActorFrame{
    Name = "MSDoverTimeGraphContainer",
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
            self:xy(actuals.GraphTitleCenterX, actuals.GraphTitleCenterY)
            self:settext("Overall MSD over time")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end
    },
}

--make skillset buttons

local sbc = Def.ActorFrame{
    Name = "SkillsetButtonsContainer",

    InitCommand = function(self)
        self:xy(actuals.SkillsetButtonsX, actuals.SkillsetButtonsY)
    end
}

for i=1, #ms.SkillSets do
    sbc[#sbc + 1] = makeSkillsetButton(ms.SkillSets[i], math.floor((i-1)/ maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsHorizontalSpacing, ((i-1) % maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsVerticalSpacing)
end

t[#t + 1] = sbc


--make graph

local graph = Def.ActorFrame{
    Name = "Graph",

    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end,

    Def.Quad{
        Name = "BG", 
        InitCommand = function(self)
            self:halign(0):valign(0)
            self:diffuse(bgColour)
            self:diffusealpha(bgAlpha)
            self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
        end
    },

    Def.ActorMultiVertex{
        Name = "Plots",
        
        InitCommand = function(self)
            self.skillset = "Overall"
            self:diffusealpha(plotAlpha)
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
                        local x = actuals.GraphWidth * ((date - minDate) / (maxDate - minDate))
                        --because positive y is downwards, we work out the y coord as we would normally, then subtract that from GraphHeight
                        --if we didnt do this then the graph would be drawn upside down
                        local y = actuals.GraphHeight - (actuals.GraphHeight * ((ssr - minMSD) / (maxMSD - minMSD)))
                        
                        
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
    },


    UIElements.TextToolTip(1, 1, "Common Normal") .. {
        Name = "DisplayXY",
        InitCommand = function(self)
            local mouseOver = false
            self:halign(0):valign(0)
            self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
            self:diffusealpha(1)
            
        end,

        MouseOverCommand = function(self)
            if self:GetParent():GetParent().focused and not self:IsInvisible() then
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

                local mouseX = absoluteMouseX - self:GetTrueX()
                local mouseY = absoluteMouseY - self:GetTrueY()
                mouseX = math.floor(mouseX+0.5) --round down
                mouseY = math.floor(mouseY + 0.5)

                local date = ((mouseX / actuals.GraphWidth) * (maxDate - minDate)) + minDate --date in ms
                local date = ((mouseX / actuals.GraphWidth) * (maxDate - minDate)) + minDate --date in ms
                local day = os.date("%d", date) 
                local month = os.date("%m", date)
                local year = os.date("%Y", date)
                local dateString = string.format("%s-%s-%s", year, month, day)

                local msd = maxMSD - ((mouseY / actuals.GraphHeight) * (maxMSD - minMSD))
                msd = tostring(msd):sub(1, 5) --stop long ass decimals

                TOOLTIP:SetText("Date: " .. dateString .. "\nMSD: " .. msd)
                TOOLTIP:Show()
                self:sleep(0.05)
                self:queuecommand("DisplayMouseCoords")
            end
        end
    }
}


--axis labels

local XaxisLabelsContainer = Def.ActorFrame{
    Name = "XaxisLabelsContainer",
    InitCommand = function(self)
        self:y(actuals.GraphHeight + actuals.XaxisLabelsYpadding)
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






local YaxisLabelsContainer = Def.ActorFrame{
    Name = "YaxisLabelsContainer",
    InitCommand = function(self)
        self:xy(-actuals.YaxisLabelsXpadding, actuals.GraphHeight)
    end
}

local YaxisLabelsCount = ((maxMSD) / YaxisLabelsScale) + 1

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
                local msd = (((i-1)/(YaxisLabelsCount-1)) * (maxMSD - minMSD)) + minMSD
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

graph[#graph + 1] = XaxisLabelsContainer
graph[#graph + 1] = YaxisLabelsContainer

t[#t + 1] = graph

return t