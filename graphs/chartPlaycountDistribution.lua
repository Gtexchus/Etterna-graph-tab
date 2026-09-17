local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
}

local actuals = {
}

local barColor = color("#9c6dd1")

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

local t = Def.ActorFrame{
    Name = "ChartPlaycountDistributionContainer",
}



t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = playcounts,
    ColorFunc = function(params) return barColor end,
    BarSpacing = 1,
    TopLabelDefaultAlpha = 0,
    BottomLabelDefaultAlpha = 0,
})

return t
