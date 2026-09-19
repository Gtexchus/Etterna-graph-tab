local ratios = {
    BarWidth = 50/1920
}

local actuals = {
    BarWidth = ratios.BarWidth * SCREEN_WIDTH
}

local barColor = color("#9c6dd1")

SCOREMAN:SortRecentScoresForGame()

local function initialiseValues(values)
    for i = 1, #values do
        table.remove(values, 1)
    end
    for i=1, 7 do
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
                local time = os.time({year=dateText:sub(1, 4), month=dateText:sub(6, 7), day=dateText:sub(9, 10)})
                local dateTable = os.date("*t", time)
                local wday = dateTable.wday --sunday is 1
                values[wday] = values[wday] + 1
            end
        end
    end
end

local values = {}
setValues(values)

local t = Def.ActorFrame{
    Name = "PlaycountPerDayDistributionGraphContainer",
}


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = values,
    BarWidth = actuals.BarWidth,
    BarNumToStringFunc = function(params)
        local days = { --i'm not writing translations for ts
            "Sunday",
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday"
        }
        return days[params.barNum]
    end,
    ColorFunc = function(params) return barColor end,
})

return t