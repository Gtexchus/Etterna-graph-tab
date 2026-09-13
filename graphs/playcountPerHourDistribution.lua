local ratios = {
    BarSpacing = 10/1920
}

local actuals = {
    BarSpacing = ratios.BarSpacing * SCREEN_WIDTH
}

local barColor = color("#9c6dd1")

SCOREMAN:SortRecentScoresForGame()

local function initialiseValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end
    for i=1, 24 do
        values[i] = 0
    end
end

local function setValues(values)
    initialiseValues(values)

    for i = 1, SCOREMAN:GetTotalNumberOfScores() do
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            local dateText = score:GetDate()
            if dateText ~= nil then
                local hour = tonumber(dateText:sub(12, 13)) + 1
                --midnight is 00
                -- +1 because we need the first bar to be at index 1
                values[hour] = values[hour] + 1
            end
        end
    end
end

local values = {}
setValues(values)

local t = Def.ActorFrame{
    Name = "PlaycountPerHourDistributionContainer",
}


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = values,
    BarSpacing = actuals.BarSpacing,
    BarNumToStringFunc = function(params)
        -- subtract 1 because of what we did in setValues
        return string.format("%02d", params.barNum - 1)
    end,
    ColorFunc = function(params) return barColor end,
    TopLabelDefaultAlpha = 0
})

return t