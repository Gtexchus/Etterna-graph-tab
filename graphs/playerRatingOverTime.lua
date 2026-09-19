local cgf = require(THEME:GetCurrentThemeDirectory() .. "BGAnimations.ScreenSelectMusic decorations.generalPages.graphs.utils.cgf")

local ratios = {
    GraphWidth = 680 / 1920,
    GraphHeight = 412 / 1080,
}


local actuals = {
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphHeight = ratios.GraphHeight * SCREEN_HEIGHT,
}


local tooltipTextSize = 0.3
local skillsetColors = {color("#ffffff"), color("#3399ff80"), color("#ff333380"), color("#ff993380"), color("#9966cc80"), color("#00cccc80"), color("#66ff6680"),  color("#ffff6680")}
local XaxisLabelCount = 5
local YaxisLabelScale = 2

local plotAnimationSeconds = 0.5


SCOREMAN:SortRecentScoresForGame()

local function setValues(values)
    local playerRatingOverTime = SCOREMAN:GetPlayerRatingOverTime()
    --sort by date
    --this is needed beacause SCOREMAN:GetPlayerRatingOverTime() is sometimes out of order
    local dates = {}
    for k, _ in pairs(playerRatingOverTime) do
        dates[#dates+1] = k
    end
    --sort the dates
    table.sort(dates, function(a,b) return a:gsub("-", "") < b:gsub("-", "") end)
    for i=1, #dates do
        local dateString = dates[i]
        local date = os.time({year=dateString:sub(1, 4), month=dateString:sub(6, 7), day=dateString:sub(9, 10)}) --date in ms
        for j=1, #ms.SkillSets do
            values[j][i] = {}
            values[j][i][1] = date
            values[j][i][2] = playerRatingOverTime[dateString][j]
        end
    end
end
local values = {}
for i=1, #ms.SkillSets do
    values[i] = {}
end
setValues(values)


local t = Def.ActorFrame{
    Name = "PlayerRatingOverTimeGraphContainer",
}



t[#t+1] = LoadActorWithParams("templates/lineGraph.lua",{
    Values = values,
    XvalueToStringFunc = function(params)
        local dateTable = os.date("*t", params.value)
        local day = tostring(dateTable["day"])
        local month = tostring(dateTable["month"])
        local year = tostring(dateTable["year"])
        if string.len(day) == 1 then --e.g. if its 1 then make it 01
            day = 0 .. day
        end
        if string.len(month) == 1 then
            month = 0 .. month
        end
        return string.format("%s-%s-%s", year, month, day)
    end,
    YvalueToStringFunc = function(params)
        if string.format("%5.2f", params.value) == string.format("%5.2f", notShit.floor(params.value + 0.0001)) then -- if the first two decimal points are 00
            --this is so the y axis labels are integers and arent 12.00, for example
            -- +0.0001 because of floating point nonsense
            return notShit.floor(params.value + 0.0001)
        else
            return string.format("%5.2f", params.value)
        end
    end,
    YaxisLabelColorFunc = cgf.AxisLabelColorFuncMSD,
    ColorFunc = function(params)
        return skillsetColors[params.layer]
    end,
    GraphWidth = actuals.GraphWidth,
    GraphHeight = actuals.GraphHeight,
    LayerNames = ms.SkillSets,
    Xunits = "Date",
    Yunits = "MSD",
    XaxisLabelCount = XaxisLabelCount,
    YaxisLabelScale = YaxisLabelScale,
    PlotAnimationSeconds = plotAnimationSeconds,
    TooltipTextSize = tooltipTextSize,
    LayerLabelsContainerHalign = 1,
    LayerLabelsContainerValign = 1,
    LayerLabelsContainerX = actuals.GraphWidth,
    LayerLabelsContainerY = actuals.GraphHeight
})

return t