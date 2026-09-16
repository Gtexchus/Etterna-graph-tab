--a group of buttons where only one can be selected at once
--this assumes that the graph is in the same parent actor
--e.g. t = {graph, buttonContainer}
--this is so the graph can be updated
--I should probably use messageman for this...

local ratios = {}

local actuals = {}


local values = Var("Values") --table of values that we want to mutate when clicking a button

--function that is run when each button is clicked
--takes the form of onClick(values, buttonValues[i])
--this function should mutate values (that's the entire purpose of this actor...)
local onClick = Var("OnClick") 

local buttonNames = Var("ButtonNames") --1 indexed array, what the text on the button says
local buttonValues = Var("ButtonValues") --1 indexed array, param that is passed into onClick when the button is clicked

local x = Var("X") or 0
local y = Var("Y") or 0
local maxButtonsPerColumn = Var("MaxButtonsPerColumn") or 4 --I wonder what this does
local buttonWidth = Var("ButtonWidth") or ((80 / 1920) * SCREEN_WIDTH)
local buttonHeight = Var("ButtonHeight") or ((20 / 1080) * SCREEN_HEIGHT)
local textSize = Var("TextSize") or 0.5
local hoverAlpha = Var("HoverAlpha") or 0.6
local selectedColor = Var("SelectedColor") or color("#ffffff")

local graphName = Var("GraphName") or "Graph"

local function makeButton(i)
    return UIElements.TextButton(1, 1, "Common Normal") .. {
        Name = buttonNames[i] .. "Button",
        InitCommand = function(self)
            local txt = self:GetChild("Text")
            local bg = self:GetChild("BG")
            self:x(math.floor((i-1)/ maxButtonsPerColumn) * buttonWidth)
            self:y(((i-1) % maxButtonsPerColumn) * buttonHeight)
            bg:zoomto(buttonWidth, buttonHeight)
            txt:zoom(textSize)
            txt:diffusealpha(1)
            txt:settext(buttonNames[i])
            txt:maxwidth(buttonWidth / textSize)
            --so the first button is highlighted upon initialisation
            self:playcommand("Update", {selected = buttonNames[1]})
        end,

        UpdateCommand = function(self, params)
            local txt = self:GetChild("Text")
            if params.selected == buttonNames[i] then --if this is the selected button
                txt:strokecolor(selectedColor)
            else --if some other button is selected
                txt:strokecolor(color("0,0,0,0"))
            end
        end,

        ClickCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "OnMouseDown" then
                local graphContainer = self:GetParent():GetParent()
                local plots = graphContainer:GetChild(graphName):GetChild("Plots")
                local buttonContainer = self:GetParent()
                --update everything
                onClick(values, buttonValues[i])
                plots:playcommand("Set")
                buttonContainer:PlayCommandsOnChildren("Update", {selected = buttonNames[i]})
            end
        end,

        RolloverUpdateCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "in" then
                self:diffusealpha(hoverAlpha)
            else
                self:diffusealpha(1)
            end
        end
    }
end


local t = Def.ActorFrame{
    Name = "SingleSelectButtonContainer",

    InitCommand = function(self)
        self:xy(x, y)
    end
}

for i=1, #buttonNames do
    t[#t + 1] = makeButton(i)
end

return t