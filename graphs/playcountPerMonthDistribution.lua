local ratios = {
    BarSpacing = 10/1920
}

local actuals = {
    BarSpacing = ratios.BarSpacing * SCREEN_WIDTH
}

local barColor = color("#9c6dd1")

SCOREMAN:SortRecentScoresForGame()

local minMonth
local minYear

local function setValues(values)
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do
        --loop through scores backwards so minMonth/Year can be set correctly
        local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - (i-1))
        if score ~= nil then
            local dateText = score:GetDate()
            if dateText ~= nil then
                local month = tonumber(dateText:sub(6, 7))
                local year = tonumber(dateText:sub(1, 4))
                if minMonth == nil or minYear == nil then
                    minMonth = month
                    minYear = year
                end
                local barNum = (month - minMonth) + ((year - minYear) * 12) + 1
                values[barNum] = (values[barNum] or 0) + 1
            end
        end
    end
end

local values = {}
setValues(values)

local t = Def.ActorFrame{
    Name = "PlaycountPerMonthDistributionContainer",
}


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = values,
    BarSpacing = actuals.BarSpacing,
    BarNumToStringFunc = function(params)
        --format:: yyyy-mm
        local cheese = params.barNum - 1
        local month = (cheese + minMonth) % 12
        if month == 0 then month = 12 end
        --why the fuck is there a -1 here
        local year = (notShit.floor((cheese + minMonth - 1) / 12)) + minYear
        return string.format("%04d-%02d", year, month)
    end,
    ColorFunc = function(params) return barColor end,
    TopLabelDefaultAlpha = 0,
    BottomLabelDefaultAlpha = 0
})

return t