--in order to properly add the graph tab:
    --10 ScuffManager.lua:
        --line 20: SCUFF.graphstabindex = 7

    --ScreenSelectMusic decorations / generalBox.lua:
        --line 41: "Graphs" (add to choiceNames)
        --line 237: actorLoader(SCUFF.graphstabindex, "generalPages/graphs.lua")

--uuh i hope you havent heavily modified any of these files so the line numbers are different
--if you have modified the files im sure you can figure out what you need to do to add them
--that should be it i hope


local focused = false
local t = Def.ActorFrame {
    Name = "GraphPageFile",
    InitCommand = function(self)
        -- hide all general box tabs on startup
        self:diffusealpha(0)
    end,
    GeneralTabSetMessageCommand = function(self, params)
        if params and params.tab ~= nil then
            if params.tab == SCUFF.graphstabindex then
                self:z(200)
                self:smooth(0.2)
                self:diffusealpha(1)
                focused = true
            else
                self:z(-100)
                self:smooth(0.2)
                self:diffusealpha(0)
                focused = false
            end
        end
    end
}

----------------------------------------------------------------- common graph functions -----------------------------------------------------------------

--this is a table of functions that are used often for making graphs
--e.g. CoordFuncAcc is used in AccuracyOverMSD, AccuracyOverTime etc.
--this is so I don't have to copy and paste these every time
--I really hate how this looks
local commonGraphFunctions = {}
do --create a new scope for all this
    --------------------------------------- misc functions ---------------------------------------

    commonGraphFunctions.GetGradeNum = function(wife, useMidGrades) 
        --returns the grade tier number for a given wife%, but if useMidGrades = false, then it pretends that midgrades don't exist
        --this means that if useMidGrades = false, getGradeNum(96.5) returns 4, even though 96.5% is Grade_Tier09
        if useMidGrades == nil then 
            useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
        end
        local function getGradeTierNumber(wife) --e.g. returns 3 from Grade_Tier03
            return tonumber(GetGradeFromPercent(wife):sub(11, 12))
        end

        local midGradeNumToGradeNum = {
            [0] = 0,
            [1] = 1,
            [2] = 2,
            [3] = 2,
            [4] = 2,
            [5] = 3,
            [6] = 3,
            [7] = 3,
            [8] = 4,
            [9] = 4,
            [10] = 4,
            [11] = 5,
            [12] = 5,
            [13] = 5,
            [14] = 6,
            [15] = 6,
            [16] = 8,
            [17] = 9,
        }
        if useMidGrades then
            return getGradeTierNumber(wife)
        end
        return midGradeNumToGradeNum[getGradeTierNumber(wife)]
    end

    --all the bullshit needed for acc graphs

    local function gradeTierToWife(n, useMidGrades)
        if useMidGrades == nil then 
            useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
        end
        --afaik there isnt a function to convert from 
        --grade tier to wife (there isnt an inverse of GetGradeFromPercent())
        --so this table will have to do
        local toWife = { 
            [0] = 1, --not technically a grade but its here for convenience
            0.999935, --AAAAA
            0.9998,
            0.9997,
            0.99955, --AAAA
            0.999,
            0.998,
            0.997, --AAA
            0.99,
            0.965,
            0.93, --AA
            0.9,
            0.85,
            0.8, --A
            0.7, --B
            0.6 --C
        }

        local toWifeNoMidGrades = { 
            [0] = 1, --not technically a grade but its here for convenience
            0.999935, --AAAAA
            0.99955, --AAAA
            0.997, --AAA
            0.93, --AA
            0.8, --A
            0.7, --B
            0.6 --C
        }

        if useMidGrades then
            return toWife[n]
        end
        return toWifeNoMidGrades[n]
    end


    local function getLowerGradeBoundary(wife, useMidGrades)
        if useMidGrades == nil then 
            useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
        end
        return gradeTierToWife(commonGraphFunctions.GetGradeNum(wife, useMidGrades), useMidGrades)
    end

    local function getUpperGradeBoundary(wife, useMidGrades)
        if useMidGrades == nil then 
            useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
        end
        if wife == 1 then
            return 1
        end
        return gradeTierToWife(commonGraphFunctions.GetGradeNum(wife, useMidGrades) - 1, useMidGrades)
    end


    local function asinh(x)
        return math.log(x + math.sqrt(x * x + 1))
    end

    --------------------------------------- params for graphs ---------------------------------------

    --coord funcs

    commonGraphFunctions.CoordFuncAsinh = function(params, scaleDivisor)
        scaleDivisor = scaleDivisor or 50
        --make it an asinh graph because it squishes big values like a log graph but works nicely for negatives and 0
        local scale = math.max(math.abs(params.minValue), math.abs(params.maxValue)) / scaleDivisor
        --higher scale means the graph starts squishing at a higher y value
        --e.g. scale = 0.5 may begin to squish the graph at yValue = 5, but scale = 5 may begin to squish the graph at yValue = 50
        local shit = asinh(params.value / scale) - asinh(params.minValue / scale)
        local fatShit = asinh(params.maxValue / scale) - asinh(params.minValue / scale)
        return params.GraphLength * (shit / fatShit)
    end

    commonGraphFunctions.CoordFuncLog = function(params, base)
        local hi = math.log(params.value, base) - math.log(params.minValue, base)
        local bye = math.log(params.maxValue, base) - math.log(params.minValue, base)
        return params.GraphLength * (hi / bye)
    end

    commonGraphFunctions.CoordFuncAcc = function(params, useMidGrades) --i fucking hate this
        if useMidGrades == nil then 
            useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
        end
        local wife = params.value
        local gradeTier = commonGraphFunctions.GetGradeNum(wife, useMidGrades)
        local minGradeTier = commonGraphFunctions.GetGradeNum(params.minValue, useMidGrades)
        local maxGradeTier = commonGraphFunctions.GetGradeNum(params.maxValue, useMidGrades)
        if params.maxValue == 1 then
            maxGradeTier = 0
        end

        local lowerWifeBound = getLowerGradeBoundary(params.value, useMidGrades)
        local upperWifeBound
        if gradeTier > 1 then --if its not an AAAAA
            upperWifeBound = getUpperGradeBoundary(params.value, useMidGrades)
        else
            upperWifeBound = 1
        end
        local numberOfSections = (minGradeTier - maxGradeTier)
        local sectionNumber = minGradeTier - gradeTier --if this is 0 then its the bottom section
        local sectionHeight = params.GraphLength / numberOfSections --39.4

        local progressIntoSection = (wife - lowerWifeBound) / (upperWifeBound - lowerWifeBound) --0

        local y =  ((sectionNumber * sectionHeight) + (sectionHeight * progressIntoSection))
        return y
    end



    --value funcs

    commonGraphFunctions.ValueFuncAsinh = function(params, scaleDivisor)
        local scale = math.max(math.abs(params.minValue), math.abs(params.maxValue)) / scaleDivisor
        local fatShit = asinh(params.maxValue / scale) - asinh(params.minValue / scale)
        local wetFart = params.coord / params.GraphLength
        return math.sinh((fatShit * wetFart) + asinh(params.minValue / scale)) * scale
    end

    commonGraphFunctions.ValueFuncLog = function(params, base)
        local bye = math.log(params.maxValue, base) - math.log(params.minValue, base)
        local why = params.coord / params.GraphLength
        return base^((why * bye) + math.log(params.minValue, base))
    end

    commonGraphFunctions.ValueFuncAcc = function(params, useMidGrades) --i fucking hate this too
        --here, a "section" is one square on the graph, e.g. gap between AA. and AA:
        if useMidGrades == nil then 
            useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
        end
        local stupidY = math.max(params.GraphLength - params.coord, 0) --cant be bothered to remake this function cleanly so fuck you
        local minGrade = commonGraphFunctions.GetGradeNum(params.minValue, useMidGrades)
        local maxGrade = commonGraphFunctions.GetGradeNum(params.maxValue, useMidGrades)
        if params.maxValue == 1 then --special case for 100%, because we want a label for 100%
            maxGrade = 0
        end
        local numberOfSections = minGrade - maxGrade --how many sections there are in total
        local yPercent = stupidY / params.GraphLength
        local sectionNumber = notShit.floor(yPercent * numberOfSections) --section we are in, top section is 0
        local upperSectionBound = ((sectionNumber) / numberOfSections) * params.GraphLength
        local lowerSectionBound = ((sectionNumber+1) / numberOfSections) * params.GraphLength
        --[[about upper and lowerSectionBound:
        these are the y coordinates of the top and bottom acc "lines" that make up a section
        upperSectionBound is the one that is higher on the screen, but because positive y is down, upperSectionBound < lowerSectionBound]]
        local progressIntoSection = ((lowerSectionBound - stupidY) / (lowerSectionBound - upperSectionBound))
        local lowerWifeBound = gradeTierToWife((minGrade - (numberOfSections - sectionNumber)) + 1, useMidGrades)
        local upperWifeBound = gradeTierToWife(minGrade - (numberOfSections - sectionNumber), useMidGrades)
        local acc = (lowerWifeBound + ((upperWifeBound - lowerWifeBound) * progressIntoSection))
        return acc
    end



    --value toString funcs

    commonGraphFunctions.ValueToStringFuncIntegerOr2DP = function(params)
        if string.format("%5.2f", params.value) == string.format("%5.2f", notShit.floor(params.value + 0.0001)) then 
            -- if the first two decimal points are 00
            -- +0.0001 because of floating point nonsense
            return params.value
        else
            return string.format("%5.2f", params.value)
        end
    end

    commonGraphFunctions.ValueToStringFuncTime = function(params)
        local dateTable = os.date("*t", params.value)
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
    end

    commonGraphFunctions.ValueToStringFuncAcc = function(params)
        local gradeBoundaries = { --stores all grade boundaries for grades
            [1] = true,
            [0.999935] = true,
            [0.9998] = true,
            [0.9997] = true,
            [0.99955] = true,
            [0.999] = true,
            [0.998] = true,
            [0.997] = true,
            [0.99] = true,
            [0.965] = true,
            [0.93] = true,
            [0.9] = true,
            [0.85] = true,
            [0.8] = true,
            [0.7] = true,
            [0.6] = true
        }
        local acc = params.value
        if acc == 1 then --special case for 100%
            return tostring(acc * 100) .. "%"
        elseif gradeBoundaries[acc] then 
            --if the acc is EXACTLY a grade boundary, 
            --so the y axis labels are labeled with the grade instead of the acc
            --this assumes that the y axis labels lie exactly on the grade boundaries, 
            --which should be the case if i've done everything right
            return THEME:GetString("Grade", ToEnumShortString(GetGradeFromPercent(params.value)))
        elseif acc > 0.99 then
            return string.format("%7.4f%s", acc * 100, "%")
        else
            return string.format("%7.2f%s", acc * 100, "%")
        end
    end



    --axis label color funcs

    commonGraphFunctions.AxisLabelColorFuncMSD = function(params, innerLineAlpha)
        innerLineAlpha = innerLineAlpha or 0.5
        local color = colorByMSD(params.value)
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = innerLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end

    commonGraphFunctions.AxisLabelColorFuncAcc = function(params, innerLineAlpha)
        innerLineAlpha = innerLineAlpha or 0.3
        local color = colorByGrade(GetGradeFromPercent(params.value))
        local innerLineColor = {}
        for k, v in pairs(color) do
            innerLineColor[k] = v
        end
        innerLineColor[4] = innerLineAlpha
        return {text = color, outerLine = color, innerLine = innerLineColor}
    end



    --min/max value funcs

    commonGraphFunctions.MinValueFuncAcc = function(params, useMidGrades)
        if useMidGrades == nil then 
            useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
        end
        --compare minValue with the lower grade boundary of value
        --e.g. if yValue = 0.932 (93.2%) then minYvalue is compared with 0.93
        --this is so minYvalue ends up being a grade boundary
        return math.min(params.minValue, getLowerGradeBoundary(params.value, useMidGrades))
    end

    commonGraphFunctions.MaxValueFuncAcc = function(params, useMidGrades)
        if useMidGrades == nil then 
            useMidGrades = PREFSMAN:GetPreference("UseMidGrades")
        end
        --same as MinValueFuncAcc, except round up
        return math.max(params.maxValue, getUpperGradeBoundary(params.value, useMidGrades))
    end

    -----------------------------------------------------------------------------------------------------------------------
end

--[[
table of {
{{actorName1, fileName1, buttonText1}, {actorName2, fileName2, buttonText2}},
{{actorName3, fileName3, buttonText3}, {actorName4, fileName4, buttonText4}},
}
The above table defines two sections with two buttons each.
Each button displays text defined by buttonText, and loads actor named acctorName from fileName
--]]
local buttons = {
    --Bar graphs
    {
        {graphActorName = "GradeDistributionGraphContainer", graphFileName = "gradeDistribution", graphButtonText = "Grades"},
        {graphActorName = "JudgementDistributionGraphContainer", graphFileName = "judgementDistribution", graphButtonText = "Judgements"},
        {graphActorName = "SkillsetPlaycountDistributionContainer", graphFileName = "skillsetPlaycountDistribution", graphButtonText = "Skillset playcounts"}, 
        {graphActorName = "MSDdistributionContainer", graphFileName = "msdDistribution", graphButtonText = "MSD distribution"},
        {graphActorName = "CleartypeDistributionContainer", graphFileName = "cleartypeDistribution", graphButtonText = "Cleartypes"},
        {graphActorName = "ChartPlaycountDistributionContainer", graphFileName = "chartPlaycountDistribution", graphButtonText = "Chart playcounts"},
    },

    --scatter graphs
    {
        {graphActorName = "MSDoverTimeGraphContainer", graphFileName = "MSDoverTime", graphButtonText = "MSD over time"},
        {graphActorName = "AccuracyOverMSDGraphContainer", graphFileName = "AccuracyOverMSD", graphButtonText = "Accuracy over MSD"}, 
        {graphActorName = "AccuracyOverTimeGraphContainer", graphFileName = "accuracyOverTime", graphButtonText = "Accuracy Over Time"},
        {graphActorName = "MAoverMSDGraphContainer", graphFileName = "MAoverMSD", graphButtonText = "MA over MSD"},
        {graphActorName = "MAoverTimeGraphContainer", graphFileName = "MAoverTime", graphButtonText = "MA over Time"},
        {graphActorName = "MAoverAccuracyGraphContainer", graphFileName = "MAoverAccuracy", graphButtonText = "MA over Accuracy"},
        {graphActorName = "ChartLengthOverTimeGraphContainer", graphFileName = "chartLengthOverTime", graphButtonText = "Chart length over Time"},
        {graphActorName = "ChartLengthOverMSDGraphContainer", graphFileName = "chartLengthOverMSD", graphButtonText = "Chart length over MSD"},
        {graphActorName = "ChartLengthOverAccuracyGraphContainer", graphFileName = "chartLengthOverAccuracy", graphButtonText = "Chart length over Accuracy"},
    },

    --line graphs
    {
        {graphActorName = "playerRatingOverTimeGraphContainer", graphFileName = "playerRatingOverTime", graphButtonText = "Player rating over time"},
    },

    --intensive graphs
    {
        {graphActorName = "MeanOverMSDGraphContainer", graphFileName = "meanOverMSD", graphButtonText = "Mean over MSD"},
        {graphActorName = "MeanOverTimeGraphContainer", graphFileName = "meanOverTime", graphButtonText = "Mean over time"},
        {graphActorName = "MeanOverAccuracyGraphContainer", graphFileName = "meanOverAccuracy", graphButtonText = "Mean over accuracy"},
    }
}

local sectionNames = {"Bar graphs", "Scatter graphs", "Line graphs", "Intensive graphs"}

local ratios = {
    GraphButtonVerticalSpacing = 30 / 1080,
    GraphButtonHorizontalPadding = 10 / 1920,
    GraphButtonVerticalPadding = 90 / 1080,
    BackButtonHorizontalPadding = 10 / 1920,
    BackButtonVerticalPadding = 10 / 1080,
    VerticalDividerHeight = 500 / 1080,
    GraphX = 50 / 1920,
    GraphY = 100 / 1080,
}

local actuals = {
    GraphButtonVerticalSpacing = ratios.GraphButtonVerticalSpacing * SCREEN_HEIGHT,
    GraphButtonHorizontalPadding = ratios.GraphButtonHorizontalPadding * SCREEN_WIDTH,
    GraphButtonVerticalPadding = ratios.GraphButtonVerticalPadding * SCREEN_HEIGHT,
    BackButtonHorizontalPadding = ratios.BackButtonHorizontalPadding * SCREEN_WIDTH,
    BackButtonVerticalPadding = ratios.BackButtonVerticalPadding * SCREEN_HEIGHT,
    VerticalDividerHeight = ratios.VerticalDividerHeight * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
}
-- scoping magic
do
    -- copying the provided ratios and actuals tables to have access to the sizing for the overall frame
    local rt = Var("ratios")
    for k,v in pairs(rt) do
        ratios[k] = v
    end
    local at = Var("actuals")
    for k,v in pairs(at) do
        actuals[k] = v
    end
end

ratios.GraphButtonMaxWidth = (ratios.Width - ((ratios.GraphButtonHorizontalPadding*2) * (#buttons + 1))) / #buttons
ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 30 / 1080

actuals.GraphButtonMaxWidth = ratios.GraphButtonMaxWidth * SCREEN_WIDTH
actuals.GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH
actuals.GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT

local titleTextSize = 1
local buttonTextSize = 0.7
local headerTextSize = 0.9
local buttonHoverAlpha = 0.6
local fadeTime = 0.2

local function createGraphContainer()
    local t = Def.ActorFrame{
        Name = "GraphContainer",

        InitCommand = function(self)
            self:z(-1)
        end,

        FocusGraphCommand = function(self, params)
            if not self:GetChild(params.graphActorName) then --if the graph doesnt exist then load it
                self:playcommand("LoadGraph", {graphFileName = params.graphFileName, graphActorName = params.graphActorName})
            end
            local graph = self:GetChild(params.graphActorName)
            local title = self:GetChild("Title")
            local back = self:GetChild("Back")
            local buttonContainer = self:GetParent():GetChild("ButtonContainer")
            graph:smooth(fadeTime)
            title:smooth(fadeTime)
            back:smooth(fadeTime)
            buttonContainer:smooth(fadeTime)
            graph:diffusealpha(1)--make the graph visible
            graph:z(1)
            graph:playcommand("Focus") --play the graph's focus command (if it has one)
            buttonContainer:diffusealpha(0) --set graph buttons to invisible
            back:diffusealpha(1) --make the back button visible
            title:playcommand("Update", {graphTitle = params.graphTitle}) --update title
            title:diffusealpha(1) --make title visible
        end,

        LoadGraphCommand = function(self, params)
            if params.graphFileName ~= nil then
                --local beforeTime = os.clock()
                self:AddChild(LoadActorWithParams("graphs/" .. params.graphFileName, {CommonGraphFunctions = commonGraphFunctions}))
                self:GetChild(params.graphActorName):xy(actuals.GraphX, actuals.GraphY) --set x and y
                BUTTON:RefreshCurrentButtons("ScreenSelectMusic") 
                --print(string.format("%s %s %s %.3f%s", "Loading", params.graphFileName, "took:", os.clock() - beforeTime, "ms"))
            end
        end,

        LoadFont("Common Normal") .. {
            Name = "Title",
            InitCommand = function(self)
                self:xy(actuals.GraphTitleX, actuals.GraphTitleY)
                self:diffusealpha(0)
                self:zoom(titleTextSize)
            end,

            UpdateCommand = function(self, params)
                if params.graphTitle ~= nil then
                    self:settext(params.graphTitle)
                end
            end
        },

        UIElements.TextButton(1, 1, "Common Normal") .. { --back button
            Name = "Back",
            InitCommand = function(self)
                local txt = self:GetChild("Text")
                local bg = self:GetChild("BG")
                self:xy(actuals.BackButtonHorizontalPadding, actuals.BackButtonVerticalPadding)
                self:diffusealpha(0)
                txt:halign(0):valign(0)
                txt:zoom(buttonTextSize)
                txt:settext("Back")
                bg:halign(0):valign(0)
                bg:zoomto(txt:GetZoomedWidth() + actuals.BackButtonHorizontalPadding, txt:GetZoomedHeight() + actuals.BackButtonVerticalPadding)
                bg:xy(-actuals.BackButtonHorizontalPadding/2, -actuals.BackButtonVerticalPadding/2)
                registerActorToColorConfigElement(txt, "main", "PrimaryText")
            end,

            ClickCommand = function(self, params)
                if self:IsInvisible() then return end
                if params.update == "OnMouseDown" then
                    local c = self:GetParent():GetChildren()
                    local thisIsntAGraph = {Back = true, Title = true} --children of GraphContainer that arent graphs (this is probably a sign of bad design choice)
                    for _, v in pairs(c) do --set all children of GraphContainer to invisible
                        v:smooth(fadeTime)
                        v:diffusealpha(0)
                        if thisIsntAGraph[v:GetName()] == nil then --do this if it is a graph
                            v:z(-1)
                            v:playcommand("Unfocus")--play the graph's unfocus command (if it has one)
                        end
                    end
                    local buttonContainer = self:GetParent():GetParent():GetChild("ButtonContainer")
                    buttonContainer:smooth(fadeTime)
                    buttonContainer:diffusealpha(1) --set graph buttons to visible
                    --ensure the buttons get unmoused over correctly
                    --probably shouldn't run this command manually but who cares
                    buttonContainer:PlayCommandsOnChildren("RolloverUpdate", {update = "out"})
                    self:GetParent():z(-1)
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
    }
    return t
end

--lmao good luck reading this
local function createGraphButtonContainer()
    local function createGraphButtonSection(j)
        local function createGraphButton(i, j)
            return UIElements.TextButton(1, 1, "Common Normal") .. {
                InitCommand = function(self)
                    local txt = self:GetChild("Text")
                    local bg = self:GetChild("BG")
                    --todo: make the logic for vertical spacing less shit
                    self:y(actuals.GraphButtonVerticalPadding + (actuals.GraphButtonVerticalSpacing * (i-1)))
                    self:diffusealpha(1)
                    txt:valign(0)
                    bg:valign(0)
                    txt:zoom(buttonTextSize)
                    bg:zoomto(actuals.GraphButtonMaxWidth, actuals.GraphButtonVerticalSpacing)
                    txt:maxwidth(actuals.GraphButtonMaxWidth / buttonTextSize)
                    -- divide by buttonTextSize bc maxWidth also scales with zoom
                    registerActorToColorConfigElement(txt, "main", "PrimaryText")
                    txt:settext(buttons[j][i].graphButtonText)
                end,

                ClickCommand = function(self, params)
                    if self:IsInvisible() then return end
                    if params.update == "OnMouseDown" then
                        local graphContainer = self:GetParent():GetParent():GetParent():GetChild("GraphContainer")
                        graphContainer:playcommand("FocusGraph", {graphActorName = buttons[j][i].graphActorName, graphFileName = buttons[j][i].graphFileName, graphTitle = buttons[j][i].graphButtonText})
                        graphContainer:z(1) 
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

        local t = Def.ActorFrame{
            Name = "GraphButtons",
            InitCommand = function(self)
                self:x(actuals.Width * (j/(#buttons)) - (actuals.Width / (#buttons*2)))
            end,

            Def.Quad{
                Name = "Divider",
                InitCommand = function(self)
                    registerActorToColorConfigElement(self, "main", "SeparationDivider")
                    self:zoomto(1, actuals.VerticalDividerHeight)
                    self:xy((actuals.GraphButtonMaxWidth/2) + actuals.GraphButtonHorizontalPadding, (actuals.Height - actuals.LowerLipHeight) / 2)
                    if j == #buttons then
                        self:diffusealpha(0)
                    end
                end
            },
            LoadFont("Common Normal") .. {
                Name = "Title",
                InitCommand = function(self)
                    registerActorToColorConfigElement(self, "main", "PrimaryText")
                    self:zoom(headerTextSize)
                    self:settext(sectionNames[j])
                    self:y(actuals.GraphButtonVerticalPadding/2)
                    self:maxwidth(actuals.GraphButtonMaxWidth / headerTextSize)
                end
            }
        }
        for i=1, #buttons[j] do
            t[#t + 1] = createGraphButton(i, j)
        end
        return t
    end

    local t = Def.ActorFrame{
        Name = "ButtonContainer"
    }
    for i = 1, #buttons do
        t[#t+1] = createGraphButtonSection(i)
    end
    return t
end

t[#t + 1] = createGraphContainer()
t[#t + 1] = createGraphButtonContainer()

return t