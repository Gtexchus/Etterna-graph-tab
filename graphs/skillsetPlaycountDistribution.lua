local smallButtonTextSize = 0.5
local labelTextSize = 0.5
local headerTextSize = 1
local bgAlpha = 0.7
local bgColour = color("#000000")
local skillsetColors = {color("#ffffff"), color("#3399ff"), color("#ff3333"), color("#ff9933"), color("#9966cc"), color("#00cccc"), color("#66ff66"),  color("#ffff66")}
local buttonHoverAlpha = 0.6
local plotAlpha = 1
local plotAnimationSeconds = 1


local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphYPadding = 100 / 1080, --distance from x axis to bottom of container
    GraphXPadding = 50 / 1920, --distance from y axis to left of container
    BarWidth = 50 / 1920,
    LabelAboveBarVerticalOffset = 25 / 1080,
    LabelBelowBarVerticalOffset = 10 / 1080,
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
}



SCOREMAN:SortRecentScoresForGame()



--table of {x, y} values, storing the top left corner of each bar
--this is so we can easily draw the text above each bar
local barCoords = {}
local playsbyskillset = SCOREMAN:GetPlaycountPerSkillset(GetPlayerOrMachineProfile(PLAYER_1))
table.remove(playsbyskillset, 1) --for some reason "overall" is included in the table but the count is 0
--the documentation lied to me



t = Def.ActorFrame{
    Name = "SkillsetPlaycountDistributionContainer",
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
            self:settext("Skillset Playcount Distribution")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end
    },

}


t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = playsbyskillset,
    Yfunc = function(params)
        return params.GraphHeight - ((params.GraphHeight * (params.value/ params.maxValue)))
    end,
    ColorFunc = function(params) return skillsetColors[params.barNum + 1] end,
    BarNumToStringFunc = function(params) return ms.SkillSetsTranslatedByName[ms.SkillSets[params.barNum + 1]] end,
    BarWidth = actuals.BarWidth
}) .. {
    InitCommand = function(self)
        self:xy(actuals.GraphX, actuals.GraphY)
    end
}

return t
