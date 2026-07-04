local smallButtonTextSize = 0.5
local labelTextSize = 0.5
local headerTextSize = 1
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6
local plotAlpha = 1
local plotAnimationSeconds = 1


local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphYPadding = 100 / 1080, --distance from x axis to bottom of container
    GraphXPadding = 50 / 1920, --distance from y axis to left of container
    BarWidth = 50 / 1920,
    LabelAboveBarVerticalOffset = 25 / 1080,
    LabelBelowBarVerticalOffset = 10 / 1080,
}
ratios.GraphX = ratios.GraphXPadding
ratios.GraphY = ratios.GraphYPadding
ratios.GraphWidth = ratios.Width - (ratios.GraphXPadding * 2)
ratios.GraphHeight = ratios.Height - (ratios.GraphYPadding * 2)
ratios.GraphBottom = ratios.GraphY + ratios.GraphHeight

ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 20 / 1080


local actuals = {
    GraphYPadding = ratios.GraphYPadding * SCREEN_HEIGHT,
    GraphXPadding = ratios.GraphXPadding * SCREEN_WIDTH,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
    GraphBottom = ratios.GraphBottom * SCREEN_HEIGHT,
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
    GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH,
    GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT,
    LabelAboveBarVerticalOffset = ratios.LabelAboveBarVerticalOffset * SCREEN_HEIGHT,
    LabelBelowBarVerticalOffset = ratios.LabelBelowBarVerticalOffset * SCREEN_HEIGHT,
}

local genericButtonCommands = { --so i dont have to write these a billion times
    MouseOver = function(self)
        self:diffusealpha(buttonHoverAlpha)
    end,

    MouseOut = function(self)
        self:diffusealpha(1)
    end
}


local function placeBarVerticesTopLeftAnchor(vertList, x, y, w, h, color)
    vertList[#vertList + 1] = {{x, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y, 0}, color}
    vertList[#vertList + 1] = {{x, y, 0}, color}
   
   
end



SCOREMAN:SortRecentScoresForGame()


local judgements = {
    "TapNoteScore_W1",
    "TapNoteScore_W2",
    "TapNoteScore_W3",
    "TapNoteScore_W4",
    "TapNoteScore_W5",
    "TapNoteScore_Miss"
}



local judgementCounts = {0, 0, 0, 0, 0, 0}
--local judgeSetting = (PREFSMAN:GetPreference("SortBySSRNormPercent") and 4 or GetTimingDifficulty())


local function getJudgementCounts(judgementCounts, f)
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do 
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            for i = 1, #judgementCounts do
                --if u want to see all ur judgements in a specific judge then use this but be warned its REALLY slow
                --local replay = score:GetReplay()
                --replay:LoadAllData()
                --judgementCounts[i] = judgementCounts[i] + getRescoredJudge(replay:GetOffsetVector(), judgeSetting, i)
                judgementCounts[i] = judgementCounts[i] + score[f](score, judgements[i])
                --score[f](score, judgements[i]) is basically score:f(judgements[i]), but you cant do the latter
            end
        end
    end
end



if PREFSMAN:GetPreference("SortBySSRNormPercent") then
    getJudgementCounts(judgementCounts, "GetTNSNormalized")
else
    getJudgementCounts(judgementCounts, "GetTapNoteScore")
end




--table of {x, y} values, storing the top left corner of each bar
--this is so we can easily draw the text above each bar
local barCoords = {}


t = Def.ActorFrame{
    Name = "JudgementDistributionGraphContainer",
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
            self:xy(actuals.GraphTitleX, actuals.GraphTitleY)
            self:settext("Judgement Distribution")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end
    },
}


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = judgementCounts,
    Yfunc = function(params)
        return params.GraphHeight - ((params.GraphHeight * (params.value/ params.maxY)))
    end,

    ColorFunc = function(i, _) 
        local timingScale =  ms.JudgeScalers[4]
        return colorByTapOffset(ms.getLowerWindowForJudgment(judgements[i], timingScale )+0.01, timingScale)
    end,

    BarLabelStrFunc = function(i) return getJudgeStrings(judgements[i]) end,
    BarWidth = actuals.BarWidth
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t
