local smallButtonTextSize = 0.5
local labelTextSize = 0.5
local headerTextSize = 1
local bgAlpha = 0.7
local bgColour = color("#000000")
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

local genericButtonCommands = { --so i dont have to write these a billion times
    MouseOver = function(self)
        self:diffusealpha(buttonHoverAlpha)
    end,

    MouseOut = function(self)
        self:diffusealpha(1)
    end
}


local function placeBarVerticesTopLeftAnchor(vertList, x, y, w, h, color)
    vertList[#vertList + 1] = {{x, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y + h, 0}, color}
    vertList[#vertList + 1] = {{x + w, y, 0}, color}
    vertList[#vertList + 1] = {{x, y, 0}, color}
   
   
end



SCOREMAN:SortRecentScoresForGame()


local judgements = {
    "TapNoteScore_W1",
    "TapNoteScore_W2",
    "TapNoteScore_W3",
    "TapNoteScore_W4",
    "TapNoteScore_W5",
    "TapNoteScore_Miss"
}



local judgementCounts = {0, 0, 0, 0, 0, 0}
--local judgeSetting = (PREFSMAN:GetPreference("SortBySSRNormPercent") and 4 or GetTimingDifficulty())


local function getJudgementCounts(judgementCounts, f)
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do 
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            for i = 1, #judgementCounts do
                --if u want to see all ur judgements in a specific judge then use this but be warned its REALLY slow
                --local replay = score:GetReplay()
                --replay:LoadAllData()
                --judgementCounts[i] = judgementCounts[i] + getRescoredJudge(replay:GetOffsetVector(), judgeSetting, i)
                judgementCounts[i] = judgementCounts[i] + score[f](score, judgements[i])
                --score[f](score, judgements[i]) is basically score:f(judgements[i]), but you cant do the latter
            end
        end
    end
end



if PREFSMAN:GetPreference("SortBySSRNormPercent") then
    getJudgementCounts(judgementCounts, "GetTNSNormalized")
else
    getJudgementCounts(judgementCounts, "GetTapNoteScore")
end




--table of {x, y} values, storing the top left corner of each bar
--this is so we can easily draw the text above each bar
local barCoords = {}


t = Def.ActorFrame{
    Name = "JudgementDistributionGraphContainer",
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
            self:settext("Judgement Distribution")
            registerActorToColorConfigElement(self, "main", "PrimaryText")
        end
    },

}

local graph = Def.ActorFrame{
    Name = "Graph",
    Def.Quad{
        Name = "BG",
        InitCommand = function(self)
            self:halign(0):valign(0)
            self:diffuse(bgColour)
            self:diffusealpha(bgAlpha)
            self:xy(actuals.GraphX, actuals.GraphY)
            self:zoomto(actuals.GraphWidth, actuals.GraphHeight)
        end
    },

    Def.ActorMultiVertex{
        Name = "Plots",
        InitCommand = function(self)
            self.usingEverySetScore = false
            self:diffusealpha(plotAlpha)
            self:xy(actuals.GraphX, actuals.GraphY)
            self:playcommand("Plot")
        end,

        PlotCommand = function(self)
            local vertices = {}
            local barSpacing = (actuals.GraphWidth - (#judgementCounts * actuals.BarWidth)) / (#judgementCounts - 1)

            local maxJudgement = 0

            --we cant just do barcoords = {0, 0} etc. due to how lua works
            for i = 1, #barCoords do
                table.remove(barCoords, 1)
            end

            for i = 1, #judgementCounts do
                maxJudgement = math.max(maxJudgement, judgementCounts[i])
            end

            for i = 1, #judgementCounts do
                local x = (i - 1) * (actuals.BarWidth + barSpacing)
                local y = actuals.GraphHeight - ((actuals.GraphHeight * (judgementCounts[i] / maxJudgement)))
                barCoords[#barCoords + 1] = {x, y}
                
                local height = (actuals.GraphHeight * (judgementCounts[i] / maxJudgement))
                local timingScale =  ms.JudgeScalers[4]
                local color = colorByTapOffset(ms.getLowerWindowForJudgment(judgements[i], timingScale )+0.01, timingScale)
                --+0.01 because the judge window isnt inclusive
                --ms.JudgeScalers[4] to get the judge 4 window, because colorByTapOffset uses judge 4 by default
                placeBarVerticesTopLeftAnchor(vertices, x, y, actuals.BarWidth, height, color)
            end

            if self:GetNumVertices() ~= 0 then
                self:finishtweening()
                self:smooth(plotAnimationSeconds)
            end
            self:SetVertices(vertices)
            self:SetDrawState {Mode = "DrawMode_Quads", First = 1, Num = #vertices}
        end,

        ToggleUsingEverySetScoreCommand = function(self)
            self.usingEverySetScore = not self.usingEverySetScore
        end
    }
}
    

local labels = Def.ActorFrame{
    Name = "LabelsContainer"
}

for i = 1, #judgementCounts do --make the graph labels

    labels[#labels + 1] = LoadFont("Common Normal") .. {
        --scorecount for each grade and percentage that goes above each bar
        Name = "LabelAboveBar",
        InitCommand = function(self)
            self:zoom(labelTextSize)
            local plots = self:GetParent():GetParent():GetChild("Plots")
            --we need to set the xy here so it doesnt tween in from (0,0) and look weird
            self:xy(plots:GetX() + barCoords[i][1] + (actuals.BarWidth / 2), plots:GetY() + barCoords[i][2] - actuals.LabelAboveBarVerticalOffset)
            self:playcommand("Set")
        end,

        SetCommand = function(self)
            self:finishtweening()
            self:smooth(plotAnimationSeconds)
            local totalNumberOfHits = 0
            for i = 1, #judgementCounts do
                totalNumberOfHits = totalNumberOfHits + judgementCounts[i]
            end
            local plots = self:GetParent():GetParent():GetChild("Plots")
            self:xy(plots:GetX() + barCoords[i][1] + (actuals.BarWidth / 2), plots:GetY() + barCoords[i][2] - actuals.LabelAboveBarVerticalOffset)
            self:settextf("%s \n (%4.2f%s)",judgementCounts[i], (judgementCounts[i] / totalNumberOfHits) * 100, "%")
        end
    }

    labels[#labels + 1] = LoadFont("Common Normal") .. {
        --grade text that goes under the bar
        Name = "LabelBelowBar",
        InitCommand = function(self)
            self:zoom(labelTextSize)
            self:valign(0)
            local plots = self:GetParent():GetParent():GetChild("Plots")
            self:xy(plots:GetX() + barCoords[i][1] + (actuals.BarWidth / 2), plots:GetY() + actuals.GraphHeight + actuals.LabelBelowBarVerticalOffset)
            self:settext(getJudgeStrings(judgements[i])) 
            registerActorToColorConfigElement(self, "judgment", judgements[i])
        end
    }
end

graph[#graph + 1] = labels
t[#t + 1] = graph

return t
