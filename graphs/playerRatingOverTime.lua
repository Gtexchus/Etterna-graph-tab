local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphYPadding = 100 / 1080, --distance from x axis to bottom of container
    GraphXPadding = 50 / 1920, --distance from x axis to left of container
    XaxisLabelsYpadding = 20 / 1080,
    YaxisLabelsXpadding = 8 / 1920,
    XaxisLabelLineWidth = 1 / 1920,
    YaxisLabelLineHeight = 1 / 1080,
    SkillsetLabelsHorizontalPadding = 5 / 1920,
    SkillsetLabelsVerticalPadding = 10 / 1080,
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
    YaxisLabelLineHeight = ratios.YaxisLabelLineHeight * SCREEN_HEIGHT,
    SkillsetLabelsHorizontalPadding = ratios.SkillsetLabelsHorizontalPadding * SCREEN_WIDTH,
    SkillsetLabelsVerticalPadding = ratios.SkillsetLabelsVerticalPadding * SCREEN_HEIGHT
}

--SCOREMAN:GetPlayerRatingOverTime()
--find out what this does when trying to make a line graph:
--self:SetDrawState {Mode = "DrawMode_LineStrip", First = 1, Num = #v}
--where self is an actorMultiVertex

local skillsetLabelsSize = 0.7
local headerTextSize = 1
local tooltipTextSize = 0.3
local bgAlpha = 0.7
local bgColour = color("#000000")
local skillsetColors = {color("#ffffff"), color("#3399ff80"), color("#ff333380"), color("#ff993380"), color("#9966cc80"), color("#00cccc80"), color("#66ff6680"),  color("#ffff6680")}
local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelInnerLineColor = color("#52525280")
local buttonHoverAlpha = 0.6
local XaxisLabelCount = 5
local YaxisLabelScale = 2

local lineThickness = (1.5 / 1080) * SCREEN_HEIGHT
local plotAlpha = 1
local plotAnimationSeconds = 0.5


SCOREMAN:SortRecentScoresForGame()

local function setValues(values)
    local playerRatingOverTime = SCOREMAN:GetPlayerRatingOverTime()
    --sort by date
    --this is needed beacause SCOREMAN:GetPlayerRatingOverTime() is sometimes out of order
    local dates = {}
    for k, _ in pairs(playerRatingOverTime) do
        dates[#dates+1] = k
    end
    --sort the dates
    table.sort(dates, function(a,b) return a:gsub("-", "") < b:gsub("-", "") end)
    for i=1, #dates do
        local dateString = dates[i]
        local date = os.time({year=dateString:sub(1, 4), month=dateString:sub(6, 7), day=dateString:sub(9, 10)}) --date in ms
        for j=1, #ms.SkillSets do
            values[j][i] = {}
            values[j][i][1] = date
            values[j][i][2] = playerRatingOverTime[dateString][j]
        end
    end
end
local values = {}
for i=1, #ms.SkillSets do
    values[i] = {}
end
setValues(values)


local t = Def.ActorFrame{
    Name = "playerRatingOverTimeGraphContainer",
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
            self:settext("Player rating over time")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end
    },
}






t[#t+1] = LoadActorWithParams("templates/lineGraph.lua",{
    Values = values,
    XvalueToStringFunc = function(params)
        local dateTable = os.date("*t", params.xValue)
        local day = tostring(dateTable["day"])
        local month = tostring(dateTable["month"])
        local year = tostring(dateTable["year"])
        if string.len(day) == 1 then --e.g. if its 1 then make it 01
            day = 0 .. day
        end
        if string.len(month) == 1 then
            month = 0 .. month
        end
        return string.format("%s-%s-%s", year, month, day)
    end,
    YvalueToStringFunc = function(params)
        if string.format("%5.2f", params.yValue) == string.format("%5.2f", notShit.floor(params.yValue + 0.0001)) then -- if the first two decimal points are 00
            --this is so the y axis labels are integers and arent 12.00, for example
            -- +0.0001 because of floating point nonsense
            return params.yValue
        else
            return string.format("%5.2f", params.yValue)
        end
    end,
    ColorFunc = function(params)
        return skillsetColors[params.layer]
    end,
    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,
    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,
    X = actuals.GraphX,
    Y = actuals.GraphY,
    LayerNames = ms.SkillSets,
    Xunits = "Date",
    Yunits = "MSD",
    XaxisLabelCount = XaxisLabelCount,
    YaxisLabelScale = YaxisLabelScale,
    PlotAnimationSeconds = plotAnimationSeconds,
    TooltipTextSize = tooltipTextSize
})





local function makeSkillsetLabelsContainer()
    local clicked = {}
    for i=1, #ms.SkillSets do
        clicked[i] = false
    end
    local function makeSkillsetLabel(i)
        local profile = GetPlayerOrMachineProfile(PLAYER_1)
        local p = ((i-1)/(#ms.SkillSets-1))
        return Def.ActorFrame{
            Name = "skillset",
            InitCommand = function(self)
                self:y(p * actuals.SkillsetLabelsContainerHeight + ((0.5-p) * actuals.SkillsetLabelsVerticalPadding))
            end,

            UIElements.TextButton(1, 1, "Common Normal") .. {
                Name = "SkillsetStr",
                InitCommand = function(self)
                    self:x(actuals.SkillsetLabelsHorizontalPadding)
                    local txt = self:GetChild("Text")
                    local bg = self:GetChild("BG")
                    bg:halign(0):valign(p)
                    txt:halign(0):valign(p)
                    bg:zoomto(actuals.SkillsetLabelsContainerWidth - (actuals.SkillsetLabelsHorizontalPadding * 2), actuals.SkillsetLabelsContainerHeight / #ms.SkillSets)
                    txt:zoom(skillsetLabelsSize)
                    txt:settext(ms.SkillSetsTranslatedByName[ms.SkillSets[i]])
                    txt:diffuse(skillsetColors[i])
                    txt:diffusealpha(1)
                end,
                ClickCommand = function(self, params)
                    if self:IsInvisible() then return end
                    if params.update == "OnMouseDown" then
                        local txt = self:GetChild("Text")
                        clicked[i] = not clicked[i]
                        if clicked[i] then
                            local c = skillsetColors[i]
                            c[4] = 0.8
                            txt:strokecolor(c)
                        else
                            txt:strokecolor(color("#00000000"))
                        end
                        local allNotClicked = true
                        for j=1, #clicked do
                            if clicked[j] then
                                allNotClicked = false
                                break
                            end
                        end
                        if allNotClicked then
                            local a = {} for i = 1, #ms.SkillSets do a[i] = true end
                            self:GetParent():GetParent():GetParent():GetChild("Graph"):playcommand("SetFocusedLayers", a)
                        else
                            self:GetParent():GetParent():GetParent():GetChild("Graph"):playcommand("SetFocusedLayers", clicked)
                        end
                    end
                end
            },

            LoadFont("Common Normal") .. {
                Name = "SsrStr",
                InitCommand = function(self)
                    self:halign(1):valign(p)
                    self:zoom(skillsetLabelsSize)
                    self:x(actuals.SkillsetLabelsContainerWidth - actuals.SkillsetLabelsHorizontalPadding)
                    local ssr = profile:GetPlayerSkillsetRating(ms.SkillSets[i])
                    self:settextf("%5.2f", ssr)
                    self:diffuse(colorByMSD(ssr))
                    self:diffusealpha(1)
                end
            }
        }
    end
    local t = Def.ActorFrame{
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
    for i=1, #ms.SkillSets do
        t[#t +1 ] = makeSkillsetLabel(i)
    end
    return t
end


t[#t+1] = makeSkillsetLabelsContainer()


return t