--in order to properly add the graph tab:
    --10 ScuffManager.lua:
        --line 20: SCUFF.graphstabindex = 7

    --ScreenSelectMusic decorations / generalBox.lua:
        --line 41: "Graphs" (add to choiceNames)
        --line 214: LoadActorWithParams("generalPages/graphs.lua", {ratios = ratios, actuals = actuals})

    --ScreenSelectMusic decorations / _chartPreview.lua
        --line 514: self:z(100)
        --line 515: BUTTON:RefreshCurrentButtons("ScreenSelectMusic")
            --this sets the z value of the chord density graph to 100, and refreshes the buttons on ScreenSelectMusic
            --if you dont do this then the chord density graph will sometimes break on song preview, after loading a graph
            --i wish i knew what i added here that breaks the chord density graph. everything i have added here is nowhere near the graph so it SHOULD have no effect...
            --i dont like this fix as i dont know if it messes anything else up.
            --if you figure out what the fuck ive done to break the chord density graph lmk

--uuh i hope you havent heavily modified any of these files so the line numbers are different
--if you have modified the files im sure you can figure out what you need to do to add them
--that should be it i hope




--find out what this does when trying to make a line graph:
--self:SetDrawState {Mode = "DrawMode_LineStrip", First = 1, Num = #v}
--where self is an actorMultiVertex



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
                --simulates pressing the back button when tabbing out of the graph tab
                --this is to fix the bug of graph tooltips being shown when not tabbed into the graph tab
                --probably not the best fix but i cba to think of a better one
                --self:GetChild("GraphContainer"):GetChild("Back"):playcommand("MouseDown") 

                self:z(-100)
                self:smooth(0.2)
                self:diffusealpha(0)
                focused = false
            end
        end
    end
}



local buttonTextSize = 0.7
local headerTextSize = 1

local ratios = {
    Width = Var("widthRatio"), -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    --X = 1 - Var("widthRatio"),
    --Y = 1 - 612 / 1080, 
    GraphButtonMaxWidth = 780 / 1920
}



local actuals = {
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    GraphButtonMaxWidth = ratios.GraphButtonMaxWidth * SCREEN_WIDTH
}

local graphNames = {{graphActorName = "MSDoverTimeGraph", graphFileName = "MSDoverTime", graphButtonName = "MSDoverTimeButton", graphButtonText = "MSD over time"}, --table of {graphActorName, graphFileName, graphButtonName, graphButtonText}
{graphActorName = "AccuracyOverMSDGraphContainer", graphFileName = "AccuracyOverMSD", graphButtonName = "AccuracyOverMSDButton", graphButtonText = "Accuracy over MSD"}, 
{graphActorName = "playerRatingOverTimeGraph", graphFileName = "playerRatingOverTime", graphButtonName = "playerRatingOverTimeButton", graphButtonText = "Player rating over time"}, 
{graphActorName = "GradeDistributionGraphContainer", graphFileName = "gradeDistribution", graphButtonName = "GradeDistributionButton", graphButtonText = "Grade distribution"}, 
{graphActorName = "JudgementDistributionGraphContainer", graphFileName = "judgementDistribution", graphButtonName = "JudgementDistributionButton", graphButtonText = "Judgement distribution"}} 



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



local function graphButtonsSetAlpha(t, alpha)
    for i = 1, #graphNames do
        t:GetChild(graphNames[i].graphButtonName):diffusealpha(alpha)
    end

end
        


local function createGraphContainer()
    local t = Def.ActorFrame{
        Name = "GraphContainer",
        FocusedGraph = "",

        InitCommand = function(self)
            self:z(-1)
        end,

        LoadGraphCommand = function(self, params)
            --params.graphFileName
            --params.graphActorName
            if not self:GetChild(params.graphActorName) then --if the graph doesnt exist then make it
                self:AddChildFromPath(THEME:GetPathB("", "ScreenSelectMusic decorations/generalPages/graphs/" .. params.graphFileName))
                BUTTON:RefreshCurrentButtons("ScreenSelectMusic") 
            end

            self:GetChild(params.graphActorName):playcommand("Focus") --focus the graph
            graphButtonsSetAlpha(self:GetParent():GetChild("GraphButtons"), 0) --set graph buttons to invisible
            self.FocusedGraph = params.graphActorName --set focused graph
            self:GetChild("Back"):diffusealpha(1) --make the back button visible
        end,

        UIElements.TextToolTip(1, 1, "Common Normal") .. { --back button
            Name = "Back",
            InitCommand = function(self)
                self:xy(0,0)
                self:diffusealpha(0)
                self:halign(0):valign(0)
                self:zoom(buttonTextSize)
                self:maxwidth(200)
                registerActorToColorConfigElement(self, "main", "PrimaryText")
                self:settext("Back")
            end,

            MouseDownCommand = function(self, params)
                if self:IsInvisible() then return end

                local graph = self:GetParent():GetChild(self:GetParent().FocusedGraph)
                graph:playcommand("Unfocus") --unfocus the graph
                graphButtonsSetAlpha(self:GetParent():GetParent():GetChild("GraphButtons"), 1) --set graph buttons to visible
                self:diffusealpha(0) --set back button to invisible
                self:GetParent().FocusedGraph = "" --there is no focused graph anymore
                self:GetParent():z(-1)
            end
            },

    }
    return t
end

local function createGraphButton(i)
    return UIElements.TextToolTip(1, 1, "Common Normal") .. {
        Name = graphNames[i].graphButtonName,
        InitCommand = function(self)
                self:xy(10, 10 + (20*i))
                self:diffusealpha(1)
                self:halign(0):valign(0)
                self:zoom(buttonTextSize)
                self:maxwidth(actuals.GraphButtonMaxWidth / buttonTextSize)
                -- divide by buttonTextSize bc maxWidth also scales with zoom
                registerActorToColorConfigElement(self, "main", "PrimaryText")
                self:settext(graphNames[i].graphButtonText)
            end,

            MouseDownCommand = function(self, params)
                if self:IsInvisible() then return end
                local graphContainer = self:GetParent():GetParent():GetChild("GraphContainer")
                graphContainer:playcommand("LoadGraph", {graphActorName = graphNames[i].graphActorName, graphFileName = graphNames[i].graphFileName})
                graphContainer:z(1) --this is so the skillset buttons on the graph dont interfere with the graph buttons
            end, 
    }
end



local graphButtons = Def.ActorFrame{
    Name = "GraphButtons",
}

for i=1, #graphNames do
    graphButtons[#graphButtons + 1] = createGraphButton(i)
end



t[#t + 1] = createGraphContainer()
t[#t + 1] = graphButtons



return t