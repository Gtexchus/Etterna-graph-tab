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

local function setCleartypeCounts(cleartypeCounts)
    for i=1, #cleartypeCounts do
        cleartypeCounts[i] = 0
    end

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local txt = getClearTypeFromScore(score, 0)
            local index = getClearTypeIndexFromValue(txt)
            cleartypeCounts[index] = cleartypeCounts[index] + 1
        end
    end
end
SCOREMAN:SortRecentScoresForGame()

local cleartypeCounts = {}
for i=1, 11 do --excludes "Invalid", "No Play" and "--" (wtf even is --)
    cleartypeCounts[i] = 0
end
setCleartypeCounts(cleartypeCounts)



t = Def.ActorFrame{
    Name = "CleartypeDistributionContainer",
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
            self:settext("Cleartype distribution")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end,
    },
}


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = cleartypeCounts,
    ColorFunc = function(params) return getClearTypeColor(params.barNum) end,
    BarNumToStringFunc = function(params) return getClearTypeText(params.barNum) end,
    BarWidth = actuals.BarWidth
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t
