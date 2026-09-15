# Etterna Graph Tab
Visualise your Etterna savefile with 23 different graphs

## Installation
### Pre-installed
1. Download the Rebirth-graphtab.zip file and extract into Etterna/Themes.
2. Head to Main Menu -> Options -> Display Options -> Appearance Options -> Change theme to Rebirth-graphtab.

### Manual installation [REBIRTH ONLY]
1. Download the Source Code zip, and extract the contents into **Etterna/Themes/[ThemeName]/BGAnimations/ScreenSelectMusic decorations/generalPages**, making sure to keep all files that were there previously. The generalPages folder should look like this: <img width="646" height="317" alt="image" src="https://github.com/user-attachments/assets/3af29965-cfe8-4abd-bf63-345778b41407" />

2. #### [ThemeName]/Scripts/10 ScuffManager.lua
   * line 13: change **SCUFF.generaltabcount = 6** to **SCUFF.generaltabcount = 7**
   * line 20: add **SCUFF.graphstabindex = 7**
3. #### [ThemeName]/BGAnimations/ScreenSelectMusic decorations/generalBox.lua
   * line 41: add **"Graphs"** to the end of choiceNames (make sure to add a comma to the end of the previous line!)
   * line 237: add **actorLoader(SCUFF.graphstabindex, "generalPages/graphs.lua")** to the end of the "Container" ActorFrame (don't forget the comma on the end of the previous line)

