local ratios = {
    Width = 780 / 1920, -- width of the box taken from the loading file default.lua
    Height = 612 / 1080,
    BarSpacing = 10 / 1920,
    SkillsetButtonsX = 590 / 1920,
    SkillsetButtonsY = -80 / 1080,
    SkillsetButtonsHorizontalSpacing = 80 / 1920,
    SkillsetButtonsVerticalSpacing = 20 / 1080,
}

local actuals = {
    BarSpacing = ratios.BarSpacing * SCREEN_WIDTH,
    SkillsetButtonsX = ratios.SkillsetButtonsX * SCREEN_WIDTH,
    SkillsetButtonsY = ratios.SkillsetButtonsY * SCREEN_HEIGHT,
    SkillsetButtonsHorizontalSpacing = ratios.SkillsetButtonsHorizontalSpacing * SCREEN_WIDTH,
    SkillsetButtonsVerticalSpacing  =ratios.SkillsetButtonsVerticalSpacing * SCREEN_HEIGHT,
}

local smallButtonTextSize = 0.5
local skillsetButtonsMaxWidth = 100
local buttonHoverAlpha = 0.6
local maxSkillsetButtonsPerColumn = 4
local XaxisScale = 1 --make this either an integer or a fractional power of 2 otherwise it will break due to floating point BS
local minMSD = 0
local maxMSD = 4


local function setMSDcounts(msdCounts, skillset)
    for i=1, #msdCounts do
        msdCounts[i] = 0
    end
    local offset = minMSD - 1 --offset to shift all the indexes so [index of minMSD]= 1
    for i = 1, SCOREMAN:GetTotalNumberOfScores() do
        local score = SCOREMAN:GetRecentScoreForGame(i)
        if score ~= nil then
            if score:GetSkillsetSSR(skillset) ~= 0 then
                local msd = notShit.floor(((score:GetSkillsetSSR(skillset) + (XaxisScale/2)) / XaxisScale)) * XaxisScale
                local index = notShit.floor((msd / XaxisScale) - offset)

                if msdCounts[index] ~= nil then
                    msdCounts[index] = msdCounts[index] + 1
                else
                    msdCounts[index] = 1
                end
            end
        end
    end
end

local function getMSDfromi(i)
    return (i + (minMSD - 1)) * XaxisScale
end

SCOREMAN:SortRecentScoresForGame()


--find max msd
for i = 1, SCOREMAN:GetTotalNumberOfScores() do
    local score = SCOREMAN:GetRecentScoreForGame(SCOREMAN:GetTotalNumberOfScores() - i)
    if score ~= nil then
        if score:GetSkillsetSSR("overall") > maxMSD then
            maxMSD = score:GetSkillsetSSR("overall")
        end
    end
end


local msdCounts = {}
for i=1, (notShit.floor((maxMSD - minMSD) / XaxisScale) + 2) do --set everything we need to 0 (i dont really know why its +2 here, it looks like it should be +1 but that breaks)
    msdCounts[i] = 0
end
setMSDcounts(msdCounts, "overall")


t = Def.ActorFrame{
    Name = "MSDdistributionContainer",
}


local function makeSkillsetButton(skillset_, x, y)
    return UIElements.TextButton(1, 1, "Common Normal") .. {
        Name = skillset_ .. "Button",
        InitCommand = function(self)
            local txt = self:GetChild("Text")
            local bg = self:GetChild("BG")
            self:xy(x, y)
            bg:zoomto(actuals.SkillsetButtonsHorizontalSpacing, actuals.SkillsetButtonsVerticalSpacing)
            txt:zoom(smallButtonTextSize)
            txt:diffusealpha(1)
            txt:settext(ms.SkillSetsTranslatedByName[skillset_])
            txt:maxwidth(skillsetButtonsMaxWidth)
            self:playcommand("Update", {skillset = "Overall"}) --so overall is highlighted when the graph is first loaded
        end,

        UpdateCommand = function(self, params)
            local txt = self:GetChild("Text")
            if params.skillset == skillset_ then
                txt:strokecolor(color("#A400FF"))
            else
                txt:strokecolor(color("0,0,0,0"))
            end
        end,

        ClickCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "OnMouseDown" then
                local graphContainer = self:GetParent():GetParent()
                local plots = graphContainer:GetChild("Graph"):GetChild("Plots")
                local sbc = graphContainer:GetChild("SkillsetButtonsContainer")
                local labelsContainer = self:GetParent():GetParent():GetChild("Graph"):GetChild("LabelsContainer")
                local skillsetButtons = sbc:GetChildren()
                --update everything
                setMSDcounts(msdCounts, skillset_)
                plots:playcommand("Set") --this needs to be run first because setMSDcounts is run there
                sbc:PlayCommandsOnChildren("Update", {skillset = skillset_})
                labelsContainer:PlayCommandsOnChildren("Set")
            end
        end,

        RolloverUpdateCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "in" then
                self:diffusealpha(buttonHoverAlpha)
            else
                self:diffusealpha(1)
            end
        end
    }
end

--make skillset buttons

local sbc = Def.ActorFrame{
    Name = "SkillsetButtonsContainer",

    InitCommand = function(self)
        self:xy(actuals.SkillsetButtonsX, actuals.SkillsetButtonsY)
    end
}

for i=1, #ms.SkillSets do
    sbc[#sbc + 1] = makeSkillsetButton(ms.SkillSets[i], math.floor((i-1)/ maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsHorizontalSpacing, ((i-1) % maxSkillsetButtonsPerColumn) * actuals.SkillsetButtonsVerticalSpacing)
end

t[#t + 1] = sbc



t[#t + 1] = LoadActorWithParams("templates/barGraph.lua", {
    Values = msdCounts,
    Yfunc = function(params)
        return params.GraphHeight - ((params.GraphHeight * (params.value/ params.maxValue)))
    end,
    ColorFunc = function(params) return colorByMSD(getMSDfromi(params.barNum)) end,
    BarNumToStringFunc = function(params) return getMSDfromi(params.barNum) end,
    BarSpacing = actuals.BarSpacing,
    TopLabelDefaultAlpha = 0
})

return t
