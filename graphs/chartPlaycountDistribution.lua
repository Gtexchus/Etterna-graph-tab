local smallButtonTextSize = 0.5
local labelTextSize = 0.4
local headerTextSize = 1
local skillsetButtonsMaxWidth = 100
local bgAlpha = 0.7
local bgColour = color("#000000")
local buttonHoverAlpha = 0.6
local plotAlpha = 1
local plotAnimationSeconds = 1
local maxSkillsetButtonsPerColumn = 4
local XaxisScale = 1 --make this either an integer or a fractional power of 2 otherwise it will break due to floating point BS


local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphYPadding = 100 / 1080, --distance from x axis to bottom of container
    GraphXPadding = 50 / 1920, --distance from y axis to left of container
    BarWidth = 30 / 1920,
    LabelAboveBarVerticalOffset = 25 / 1080,
    LabelBelowBarVerticalOffset = 10 / 1080,
    SkillsetButtonsX = 640 / 1920,
    SkillsetButtonsY = 20 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
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
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
}



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



--table of {x, y} values, storing the top left corner of each bar
--this is so we can easily draw the text above each bar
local barCoords = {}



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
    Yfunc = function(params)
        return params.GraphHeight - ((params.GraphHeight * (params.value/ params.maxValue)))
    end,
    ColorFunc = function(i, v) return colorByMSD((i/#playcounts)*40) end, --i dont really know a better color scheme
    BarSpacing = 1,
    TopLabelDefaultAlpha = 0,
    BottomLabelTextSize = 0.3
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t
