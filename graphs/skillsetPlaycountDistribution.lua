local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    GraphY = 100 / 1080, 
    GraphX = 50 / 1920, 
    BarWidth = 50 / 1920,
}
ratios.GraphTitleX = ratios.Width / 2
ratios.GraphTitleY = 20 / 1080

local actuals = {
    GraphX = ratios.GraphX * SCREEN_WIDTH,
    GraphY = ratios.GraphY * SCREEN_HEIGHT,
    BarWidth = ratios.BarWidth * SCREEN_WIDTH,
    GraphTitleX = ratios.GraphTitleX * SCREEN_WIDTH,
    GraphTitleY = ratios.GraphTitleY * SCREEN_HEIGHT,
}

local headerTextSize = 1
local skillsetColors = {color("#ffffff"), color("#3399ff"), color("#ff3333"), color("#ff9933"), color("#9966cc"), color("#00cccc"), color("#66ff66"),  color("#ffff66")}


SCOREMAN:SortRecentScoresForGame()


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
