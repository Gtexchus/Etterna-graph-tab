local ratios = {
    BarWidth = 50 / 1920,
}

local actuals = {
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
}

local skillsetColors = {color("#ffffff"), color("#3399ff"), color("#ff3333"), color("#ff9933"), color("#9966cc"), color("#00cccc"), color("#66ff66"),  color("#ffff66")}


SCOREMAN:SortRecentScoresForGame()


local playsbyskillset = SCOREMAN:GetPlaycountPerSkillset(GetPlayerOrMachineProfile(PLAYER_1))
table.remove(playsbyskillset, 1) --for some reason "overall" is included in the table but the count is 0
--the documentation lied to me



local t = Def.ActorFrame{
    Name = "SkillsetPlaycountDistributionGraphContainer",
}


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = playsbyskillset,
    Yfunc = function(params)
        return params.GraphHeight - ((params.GraphHeight * (params.value/ params.maxValue)))
    end,
    ColorFunc = function(params) return skillsetColors[params.barNum + 1] end,
    BarNumToStringFunc = function(params) return ms.SkillSetsTranslatedByName[ms.SkillSets[params.barNum + 1]] end,
    BarWidth = actuals.BarWidth
})

return t
