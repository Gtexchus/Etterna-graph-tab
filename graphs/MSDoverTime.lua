local smallButtonTextSize = 0.5
local headerTextSize = 1
local skillsetButtonsMaxWidth = 100
local bgAlpha = 0.7
local bgColour = color("#000000")
local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelInnerLineColor = color("#52525280")
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
    SkillsetButtonsX = 640 / 1920,
    SkillsetButtonsY = 20 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
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

SCOREMAN:SortRecentScoresForGame()

-- 4 xyz coordinates are given to make up the 4 corners of a quad to draw
local function placeDotVertices(vertList, x, y, color)
    vertList[#vertList + 1] = {{x - (plotWidth/2), y + (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x + (plotWidth/2), y + (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x + (plotWidth/2), y - (plotHeight/2), 0}, color}
    vertList[#vertList + 1] = {{x - (plotWidth/2), y - (plotHeight/2), 0}, color}
end


local function setValues(values, skillset)
    for i = 1, #values do
        table.remove(values, 1)
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local dateText = score:GetDate()
            local ssr = score:GetSkillsetSSR(skillset)
            if dateText ~= nil then
                local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                values[i] = {}
                values[i][1] = date
                values[i][2] = ssr
            end
        end
    end
end

local values = {}
setValues(values, "overall")





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
        end,

        UpdateCommand = function(self, params)
            self:settext(params.skillset .. " MSD over time")
        end
    },
}

--make skillset buttons


local function makeSkillsetButton(skillset_, x, y)
    return UIElements.TextButton(1, 1, "Common Normal") .. {
        Name = skillset_ .. "Button",
        InitCommand = function(self)
            local txt = self:GetChild("Text")
            local bg = self:GetChild("BG")
            self:xy(x, y)
            bg:zoomto(actuals.SkillsetButtonsHorizontalSpacing, actuals.SkillsetButtonsVerticalSpacing)
            txt:zoom(smallButtonTextSize)
            txt:diffusealpha(1)
            txt:settext(ms.SkillSetsTranslatedByName[skillset_])
            txt:maxwidth(skillsetButtonsMaxWidth)
            self:playcommand("Update", {skillset = "Overall"}) --so overall is highlighted when the graph is first loaded
        end,

        UpdateCommand = function(self, params)
            local txt = self:GetChild("Text")
            if params.skillset == skillset_ then
                txt:strokecolor(Brightness(COLORS:getMainColor("PrimaryText"), 0.7))
            else
                txt:strokecolor(color("0,0,0,0"))
            end
        end,

        ClickCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "OnMouseDown" then
                local graphContainer = self:GetParent():GetParent()
                local plots = graphContainer:GetChild("Graph"):GetChild("Plots")
                local sbc = graphContainer:GetChild("SkillsetButtonsContainer")
                local title = graphContainer:GetChild("Title")
                local labelsContainer = self:GetParent():GetParent():GetChild("Graph"):GetChild("LabelsContainer")
                local skillsetButtons = sbc:GetChildren()
                --update everything
                setValues(values, skillset_)
                plots:playcommand("Set") --this needs to be run first because setMSDcounts is run there
                sbc:PlayCommandsOnChildren("Update", {skillset = skillset_})
                title:playcommand("Update", {skillset = skillset_})
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
end


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



t[#t + 1] = LoadActorWithParams("templates/scatterGraph.lua", {
    Values = values,
    ColorFunc = function(params) return colorByMSD(params.yValue) end,
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
        if string.format("%5.2f", params.yValue) == string.format("%5.2f", math.floor(params.yValue)) then
            return params.yValue
        else
            return string.format("%5.2f", params.yValue)
        end
    end,
    XaxisLabelCount = 5,
    YaxisLabelScale = YaxisLabelsScale,
    XaxisLabelInnerLineColor =xAxisLabelInnerLineColor,
    YaxisLabelInnerLineColor = yAxisLabelInnerLineColor,
    PlotAlpha = plotAlpha,
    Xunits = "Date",
    Yunits = "MSD"
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t