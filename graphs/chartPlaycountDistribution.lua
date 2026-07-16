local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphY = 100 / 1080, 
    GraphX = 50 / 1920, 
}
ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 20 / 1080


local actuals = {
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH,
    GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT,
}


local bottomLabelTextSize = 0.3
local headerTextSize = 1

local function setPlaycounts(playcounts)
    for i=1, #playcounts do
        playcounts[i] = 0
    end
    local maxPlaycount = 0
    local countedSongs = {} --songs we have seen
    local allSongs = SONGMAN:GetAllSongs()
    for _, song in ipairs(allSongs) do
        for __, chart in ipairs(WHEELDATA:GetChartsMatchingFilter(song)) do
            if countedSongs[chart:GetChartKey()] == nil then --if we havent seen this chart before
                countedSongs[chart:GetChartKey()] = true --we have now seen it
                local scorestack = SCOREMAN:GetScoresByKey(chart:GetChartKey())
                if scorestack ~= nil then
                    local playcount = 0
                    for ___, l in pairs(scorestack) do
                        local scoresatrate = l:GetScores()
                        for ____, _____ in ipairs(scoresatrate) do
                            playcount = playcount + 1
                        end
                    end
                    if playcounts[playcount] == nil then
                        playcounts[playcount] = 0
                    end
                    playcounts[playcount] = playcounts[playcount] + 1
                    maxPlaycount = math.max(maxPlaycount, playcount)
                end
            end
        end
    end
    for i=1, maxPlaycount do
        if playcounts[i] == nil then
            playcounts[i] = 0
        end
    end
end
SCOREMAN:SortRecentScoresForGame()

local playcounts = {0}
setPlaycounts(playcounts)

t = Def.ActorFrame{
    Name = "ChartPlaycountDistributionContainer",
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
            self:settext("Chart playcount distribution")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end,
    },

}



t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = playcounts,
    ColorFunc = function(params) return colorByMSD((params.barNum/#playcounts)*40) end, --i dont really know a better color scheme
    BarSpacing = 1,
    TopLabelDefaultAlpha = 0,
    BottomLabelTextSize = bottomLabelTextSize
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t
