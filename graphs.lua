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
        {graphActorName = "MSDdistributionContainer", graphFileName = "msdDistribution", graphButtonText = "MSD Distribution"},
        {graphActorName = "GradeDistributionGraphContainer", graphFileName = "gradeDistribution", graphButtonText = "Grades"},
        {graphActorName = "JudgementDistributionGraphContainer", graphFileName = "judgementDistribution", graphButtonText = "Judgements"},
        {graphActorName = "CleartypeDistributionContainer", graphFileName = "cleartypeDistribution", graphButtonText = "Cleartypes"},
        {graphActorName = "SkillsetPlaycountDistributionContainer", graphFileName = "skillsetPlaycountDistribution", graphButtonText = "Skillset Playcounts"}, 
        {graphActorName = "ChartPlaycountDistributionContainer", graphFileName = "chartPlaycountDistribution", graphButtonText = "Chart Playcounts"},
        {graphActorName = "PlaycountPerHourDistributionContainer", graphFileName = "playcountPerHourDistribution", graphButtonText = "Playcount per Hour of Day"},
        {graphActorName = "PlaycountPerDayDistributionContainer", graphFileName = "playcountPerDayDistribution", graphButtonText = "Playcount per Day of Week"},
        {graphActorName = "PlaycountPerMonthDistributionContainer", graphFileName = "playcountPerMonthDistribution", graphButtonText = "Playcount per Month"},
    },

    --scatter graphs
    {
        {graphActorName = "MSDoverTimeGraphContainer", graphFileName = "MSDoverTime", graphButtonText = "MSD over Time"},
        {graphActorName = "AccuracyOverMSDGraphContainer", graphFileName = "AccuracyOverMSD", graphButtonText = "Accuracy over MSD"}, 
        {graphActorName = "AccuracyOverTimeGraphContainer", graphFileName = "accuracyOverTime", graphButtonText = "Accuracy over Time"},
        {graphActorName = "MAoverMSDGraphContainer", graphFileName = "MAoverMSD", graphButtonText = "MA over MSD"},
        {graphActorName = "MAoverTimeGraphContainer", graphFileName = "MAoverTime", graphButtonText = "MA over Time"},
        {graphActorName = "MAoverAccuracyGraphContainer", graphFileName = "MAoverAccuracy", graphButtonText = "MA over Accuracy"},
        {graphActorName = "MSDoverChartLengthGraphContainer", graphFileName = "MSDoverChartLength", graphButtonText = "MSD over Chart Length"},
        {graphActorName = "ChartLengthOverTimeGraphContainer", graphFileName = "chartLengthOverTime", graphButtonText = "Chart Length over Time"},
        {graphActorName = "AccuracyOverChartLengthGraphContainer", graphFileName = "accuracyOverChartLength", graphButtonText = "Accuracy over Chart Length"},
    },

    --line graphs
    {
        {graphActorName = "playerRatingOverTimeGraphContainer", graphFileName = "playerRatingOverTime", graphButtonText = "Player Rating over Time"},
        {graphActorName = "GradesOverTimeGraphContainer", graphFileName = "gradesOverTime", graphButtonText = "Grades over Time"},
    },

    --intensive graphs
    {
        {graphActorName = "MeanOverMSDGraphContainer", graphFileName = "meanOverMSD", graphButtonText = "Mean over MSD"},
        {graphActorName = "MeanOverTimeGraphContainer", graphFileName = "meanOverTime", graphButtonText = "Mean over Time"},
        {graphActorName = "MeanOverAccuracyGraphContainer", graphFileName = "meanOverAccuracy", graphButtonText = "Mean over Accuracy"},
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
                self:AddChildFromPath(THEME:GetPathB("", "ScreenSelectMusic decorations/generalPages/graphs/" .. params.graphFileName))
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