local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    BarWidth = 50 / 1920,
}

local actuals = {
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
}


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
}


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = cleartypeCounts,
    ColorFunc = function(params) return getClearTypeColor(params.barNum) end,
    BarNumToStringFunc = function(params) return getClearTypeText(params.barNum) end,
    BarWidth = actuals.BarWidth
})

return t
