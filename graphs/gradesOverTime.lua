local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")
local gradeUtils = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.gradeUtils")

local ratios = {
    GraphWidth = 680 / 1920,
    GraphHeight = 412 / 1080,
    YaxisLabelOffset = 5 / 1920,
    LayerLabelsHorizontalPadding = 5 / 1920,
    LayerLabelsVerticalPadding = 10 / 1080,
}

ratios.LayerLabelsContainerWidth = ratios.GraphWidth / 5
ratios.LayerLabelsContainerHeight = ratios.GraphHeight / 1.5

local actuals = {
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    YaxisLabelOffset = ratios.YaxisLabelOffset * SCREEN_WIDTH,
    LayerLabelsContainerWidth = ratios.LayerLabelsContainerWidth * SCREEN_WIDTH,
    LayerLabelsContainerHeight  =ratios.LayerLabelsContainerHeight * SCREEN_HEIGHT,
    LayerLabelsHorizontalPadding = ratios.LayerLabelsHorizontalPadding * SCREEN_WIDTH,
    LayerLabelsVerticalPadding = ratios.LayerLabelsVerticalPadding * SCREEN_HEIGHT
}

local buttonHoverAlpha = 0.6
local layerLabelSize = 0.6
local bgColour = color("#000000")

local xAxisLabelInnerLineColor = color("#52525280")
local yAxisLabelInnerLineColor = color("#52525280")
local plotAnimationSeconds = 0.5


SCOREMAN:SortRecentScoresForGame()

local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")

local samplerate = 7 * 24 * 60 * 60 --time between each sample for the line, in seconds
--lower samplerate makes the line more accurate, but uses more vertices

local minGradeTier = 13 --confusing name because lower acc means higher GradeTier
local maxGradeTier = 1

local function getGradeNumGivenAGradeTier(gradeTier, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    if useMidGrades then return gradeTier end
    return gradeUtils.midGradeNumToGradeNum[gradeTier]
end


local function setValues(values, useMidGrades)
    if useMidGrades == nil then 
        useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
    end
    --initialise values
    for i = 1, #values do 
        table.remove(values, 1)
    end
    local count = (getGradeNumGivenAGradeTier(minGradeTier, useMidGrades) - getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades)) + 1
    for i=1, count do
        values[#values + 1] = {}
    end

    local i = 0
    while i <= SCOREMAN:GetTotalNumberOfScores() do --for every saved score
        local dt = 0 --chnage in time of scores since we started this sample
        local minTime = -1 --time of the first score in the sample

        while minTime < 0 and i <= SCOREMAN:GetTotalNumberOfScores() do --get the next valid time
            local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i)
            if score ~= nil then
                local dateText = score:GetDate()
                if dateText ~= nil then
                    minTime = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                    break --make sure to break so we dont skip over a score
                end
            end
            i = i + 1
        end

        local gradeCountsForThisLoop = {} -- count up all grades of scores we find within this sample
        for i = 1, count do --initialise
            gradeCountsForThisLoop[i] = 0
        end
        --while we are still within the time bounds for this sample
        while dt < samplerate and i <= SCOREMAN:GetTotalNumberOfScores() do
            local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i) --loop through scores backwards (most recent is last)
            if score ~= nil then
                local grade = score:GetWifeGrade()
                local wife = score:GetWifeScore()
                local gradeTierNumber = tonumber(GetGradeFromPercent(wife):sub(11, 12))
                local dateText = score:GetDate()
                if dateText ~= nil and gradeTierNumber ~= nil and gradeTierNumber <= minGradeTier and gradeTierNumber >= maxGradeTier then
                    local date = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                    dt = date - minTime --update dt with the new change in time
                    if dt > samplerate then break end --too much time has passed, end the sample!
                    --relative to maxGradeTier
                    --e.g. if gradeTierNumber = 5 and maxGradeTier = 5, then relativeGradeNum = 1
                    local relativeGradeNum = getGradeNumGivenAGradeTier(gradeTierNumber, useMidGrades) - (getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades) - 1)
                    --incrament the grade count by one
                    gradeCountsForThisLoop[relativeGradeNum] = gradeCountsForThisLoop[relativeGradeNum] + 1
                end
            end
            i = i + 1
        end
        for i=1, #values do --add all of gradeCountsForThisLoop to values
            if gradeCountsForThisLoop[i] > 0 then
                local index = #values[i] + 1
                local prev
                if index > 1 then
                    prev = values[i][index - 1][2]
                else
                    prev = 0
                end
                values[i][index] = {}
                values[i][index][1] = minTime + samplerate
                values[i][index][2] = prev + gradeCountsForThisLoop[i]
            end
        end
    end

    for i=1, #values do --make sure there are no empty lines, otherwise there will be errors out the ass
        if #values[i] == 0 then --if the line is empty
            values[i][1] = {os.time(os.date("!*t")), 0} --add a single point at today's date
        end
    end
end

local values = {} --values[1] is the highest acc
setValues(values, useMidGrades)


local wholeGrades = { --stupid fucking midgrade preference
    THEME:GetString("Grade", "Tier01"), -- AAAAA
    THEME:GetString("Grade", "Tier04"), -- AAAA
    THEME:GetString("Grade", "Tier07"), -- AAA
    THEME:GetString("Grade", "Tier10"), -- AA
    THEME:GetString("Grade", "Tier13"), -- A
    THEME:GetString("Grade", "Tier14"), -- B
	THEME:GetString("Grade", "Tier15"), -- C
	THEME:GetString("Grade", "Tier16"),
	THEME:GetString("Grade", "Failed")
}
local layerNames = {}

for i=1, #values do
    local gradeNum = getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades) + (i-1)
    if useMidGrades then
        local gradenumStr
        if gradeNum < 10 then
            gradeNumStr = 0 .. tostring(gradeNum)
        else
            gradeNumStr = tostring(gradeNum)
        end
        layerNames[i] = getGradeStrings("Grade_Tier" .. gradeNumStr)
    else
        layerNames[i] = wholeGrades[gradeNum]
    end
end

local t = Def.ActorFrame{
    Name = "GradesOverTimeGraphContainer",
}


t[#t + 1] = LoadActorWithParams("templates/lineGraph.lua", {
    Values = values,

    YvalueToStringFunc = function(params)
        return tostring(notShit.floor(params.value))
    end,

    ColorFunc = function(params) 
        local gradeNum = params.layer + (getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades) - 1)
        return gradeUtils.GetMidGradeColor(gradeNum, useMidGrades)
    end,

    XaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = xAxisLabelInnerLineColor}
    end,

    YaxisLabelColorFunc = function(params)
        return{text = color("#ffffff"), outerLine = color("#ffffff"), innerLine = yAxisLabelInnerLineColor}
    end,

    LayerNames = layerNames,

    XvalueToStringFunc = cgf.ValueToStringFuncTime,
    
    XaxisLabelCount = 5,
    YaxisLabelScale = 200,
    Xunits = "Date", 
    Yunits = "",
    YaxisLabelOffset = actuals.YaxisLabelOffset,
    TooltipTextSize = 0.3,
    ExtendLinesToEndOfGraph = true,
    PlotAnimationSeconds = plotAnimationSeconds,
})


local function makeLayerLabelsContainer()
    local clicked = {}
    for i=1, #values do
        clicked[i] = false
    end
    local function makeLayerLabel(i)
        local profile = GetPlayerOrMachineProfile(PLAYER_1)
        local p = ((i-1)/(#values-1))
        return Def.ActorFrame{
            Name = "Grade",
            InitCommand = function(self)
                self:y(p * actuals.LayerLabelsContainerHeight + ((0.5-p) * actuals.LayerLabelsVerticalPadding))
            end,

            UIElements.TextButton(1, 1, "Common Normal") .. {
                Name = "LayerStr",
                InitCommand = function(self)
                    self:x(actuals.LayerLabelsHorizontalPadding)
                    local txt = self:GetChild("Text")
                    local bg = self:GetChild("BG")
                    bg:halign(0):valign(p)
                    txt:halign(0):valign(p)
                    bg:zoomto(actuals.LayerLabelsContainerWidth - (actuals.LayerLabelsHorizontalPadding * 2), actuals.LayerLabelsContainerHeight / #values)
                    txt:zoom(layerLabelSize)
                    txt:settext(layerNames[i])
                    local gradeNum = i + (getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades) - 1)
                    txt:diffuse(gradeUtils.GetMidGradeColor(gradeNum, useMidGrades))
                    txt:diffusealpha(1)
                end,
                ClickCommand = function(self, params)
                    if self:IsInvisible() then return end
                    if params.update == "OnMouseDown" then
                        local txt = self:GetChild("Text")
                        clicked[i] = not clicked[i]
                        if clicked[i] then
                            local gradeNum = i + (getGradeNumGivenAGradeTier(maxGradeTier, useMidGrades) - 1)
                            local c = gradeUtils.GetMidGradeColor(gradeNum, useMidGrades)
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
                            local a = {} for i = 1, #values do a[i] = true end
                            self:GetParent():GetParent():GetParent():GetChild("Graph"):playcommand("SetFocusedLayers", a)
                        else
                            self:GetParent():GetParent():GetParent():GetChild("Graph"):playcommand("SetFocusedLayers", clicked)
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
            },

            LoadFont("Common Normal") .. {
                Name = "LayerValueStr",
                InitCommand = function(self)
                    self:halign(1):valign(p)
                    self:zoom(layerLabelSize)
                    self:x(actuals.LayerLabelsContainerWidth - actuals.LayerLabelsHorizontalPadding)
                    local value = values[i][#values[i]][2]
                    self:settext(tostring(value))
                    self:diffusealpha(1)
                end
            }
        }
    end
    local t = Def.ActorFrame{
        Name = "LayerLabelsContainer",
        InitCommand = function(self)
            self:diffusealpha(1)
            --self:xy(actuals.GraphWidth - actuals.LayerLabelsContainerWidth, actuals.GraphHeight - actuals.LayerLabelsContainerHeight)
        end,
        Def.Quad{
            Name = "BG",
            InitCommand = function(self)
                self:zoomto(actuals.LayerLabelsContainerWidth, actuals.LayerLabelsContainerHeight)
                self:diffuse(bgColour)
                self:halign(0):valign(0)
                self:xy(0, 0) 
            end
        },
    }
    --make the layer labels box
    for i=1, #values do
        t[#t +1 ] = makeLayerLabel(i)
    end
    return t
end


t[#t+1] = makeLayerLabelsContainer()



return t