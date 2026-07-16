local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphY = 100 / 1080, --distance from x axis to bottom of container
    GraphX = 50 / 1920, --distance from y axis to left of container
    BarWidth = 50 / 1920,
}
ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 20 / 1080

local actuals = {
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
    GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH,
    GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT,
}

local headerTextSize = 1

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
    ColorFunc = function(params) 
        local timingScale =  ms.JudgeScalers[4]
        return colorByTapOffset(ms.getLowerWindowForJudgment(judgements[params.barNum], timingScale)+0.01, timingScale)
    end,

    BarNumToStringFunc = function(params) return getJudgeStrings(judgements[params.barNum]) end,
    BarWidth = actuals.BarWidth
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t
