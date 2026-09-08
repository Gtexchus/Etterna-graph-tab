local values = Var("Values")
local setValues = Var("SetValues")

local initialiseValues = Var("InitialiseValues") or function() return end

local setValuesParams = Var("SetValuesParams") or {}

local numOfValuesToLoad = Var("NumOfValuesToLoad") or 1
local increments = Var("Increments") or 10

local x = Var("X") or 0
local y = Var("Y") or 0
local width = Var("Width") or ((400 / 1920) * SCREEN_WIDTH)
local height = Var("Height") or ((200 / 1080) * SCREEN_HEIGHT)

local bgAlpha = 0.7
local progressBarBGAlpha = 0.5

local actuals = {
    ProgressTextY = height * (1/4),
    ProgressCounterY = height * (2/4),
    ProgressBarY = height * (3/4),
    ProgressBarWidth = width * (2/3),
    ProgressBarHeight = height * (1/6)
}

initialiseValues(values)

local sleepTime = 0
local loadedCount = 0

local t = Def.ActorFrame{
    Name = "LoadingHandler",

    InitCommand = function(self)  
        self:xy(x, y)
        self:playcommand("Loop")
    end,

    SetValuesCommand = function(self)
        for i = 1, #values do
            table.remove(values, 1)
        end
    end,

    SleepCommand = function(self)
       self:sleep(sleepTime)
    end,

    LoopCommand = function(self)
        if loadedCount >= numOfValuesToLoad then
            self:queuecommand("Finish") 
        else
            self:queuecommand("Increment")
            self:queuecommand("Sleep")
            self:GetChild("ProgressCounter"):playcommand("Set")
            self:GetChild("ProgressBar"):playcommand("Set")
            self:queuecommand("Loop")
        end
    end,

    IncrementCommand = function(self)
        local startTime = os.clock()
        for i=1, increments do
            setValues(values, loadedCount + i, setValuesParams)
        end
        loadedCount = loadedCount + increments
        sleepTime = (os.clock() - startTime)
    end,

    FinishCommand = function(self)
        --do stuff first idk
        self:GetParent():playcommand("FinishedLoading")
        self:diffusealpha(0)
        BUTTON:RefreshCurrentButtons("ScreenSelectMusic") 
        --delete itself once loading is finished, for efficiency
        --nvm this causes the entire game to shit itself for some reason
        --self:GetParent():RemoveChild("LoadingHandler")
    end,

    Def.Quad{
        Name = "BG",
        InitCommand = function(self)
            self:zoomto(width, height)
            registerActorToColorConfigElement(self, "main", "PrimaryBackground")
            self:diffusealpha(bgAlpha)
        end,
    },

    LoadFont("Common Normal") .. {
        Name = "ProgressText",
        InitCommand = function(self)
            self:y(actuals.ProgressTextY - (height / 2))
            self:settext("Progress:")
        end
    },

    LoadFont("Common Normal") .. {
        Name = "ProgressCounter",
        InitCommand = function(self)
            self:y(actuals.ProgressCounterY - (height / 2))
            self:playcommand("Set")
        end,
        SetCommand = function(self, params)
            self:settext(loadedCount .. " / " .. numOfValuesToLoad)
        end
    },

    Def.Quad{
        Name = "ProgressBarBG",
        InitCommand = function(self)
            self:y(actuals.ProgressBarY - (height / 2))
            registerActorToColorConfigElement(self, "main", "ProgressBarBackground")
            self:diffusealpha(progressBarBGAlpha)
            self:zoomto(actuals.ProgressBarWidth, actuals.ProgressBarHeight)
        end
    },

    Def.Quad{
        Name = "ProgressBar",
        InitCommand = function(self)
            self:halign(0)
            self:xy(-(actuals.ProgressBarWidth / 2), actuals.ProgressBarY - (height / 2))
            registerActorToColorConfigElement(self, "main", "ProgressBarFill")
            self:zoomtoheight(actuals.ProgressBarHeight)
            self:playcommand("Set")
        end,
        SetCommand = function(self)
            self:zoomtowidth(actuals.ProgressBarWidth * (loadedCount / numOfValuesToLoad))
        end 
    }
}

return t

