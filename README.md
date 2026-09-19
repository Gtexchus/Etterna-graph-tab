# Etterna Graph Tab
Visualise your Etterna savefile with 23 different graphs.

## Installation
### Pre-installed
1. Download the `Rebirth-graphtab.zip` file and extract into Etterna/Themes.
2. Head to Main Menu -> Options -> Display Options -> Appearance Options -> Change theme to `Rebirth-graphtab`.

### Manual installation [REBIRTH ONLY]

1. Make a backup of your theme folder
   
3.  Download the Source Code zip, and extract the contents into the following directory, making sure to keep all files that were there previously:

  `Etterna/Themes/[ThemeName]/BGAnimations/ScreenSelectMusic decorations/generalPages`
  
 The generalPages folder should look like this:
  
   <img width="627" height="330" alt="image" src="https://github.com/user-attachments/assets/ca3af518-22db-4b1e-9d7e-8d11df00e911" />


3. #### [ThemeName]/Scripts/10 ScuffManager.lua
   * line 13: change `SCUFF.generaltabcount = 6` to the following:
   
     `SCUFF.generaltabcount = 7`
     
   * line 20: add the following line:

     `SCUFF.graphstabindex = 7`
     
4. #### [ThemeName]/BGAnimations/ScreenSelectMusic decorations/generalBox.lua
   * line 41: add the following line to the end of choiceNames (make sure there is a comma at the end of the previous line!):
     
       `"Graphs"`
     
   * line 237: add the following line to the end of the "Container" ActorFrame (make sure there is a comma at the end of the previous line!):
     
       `actorLoader(SCUFF.graphstabindex, "generalPages/graphs.lua")`


## Midgrades

Every graph respects the midgrade preference.

**It is strongly advised to enable the midgrade preference when viewing graphs**, as they were designed to be viewed with midgrades on. ***This will still work even if you have set all of your scores with midgrades off.***

The midgrade preference is purely visual, and won't affect your save file.

**If you wish to view a certain graph without midgrades, but still wish to view other graphs with midgrades:**
1. Enable the midgrade preference
2. Navigate to the graph file, found in `generalPages/graphs`
3. Locate the line that says `local useMidGrades = PREFSMAN:GetPreference("UseMidGrades")`
4. Underneath this, add `useMidGrades = false`

This will only work if you want to set the graph to not use midgrades. Setting `useMidGrades = true` and disabling the preference will break the graph.


## Intensive graphs

The Intensive graphs section houses graphs that take very long to load. This is because those graphs require every replay to be loaded, which is very slow. 

When loading these graphs, a progress bar will appear to display how many replays out of the total have been loaded.

The game may freeze for extended periods during loading.

**Leaving the Select Music screen while a graph is loading will cancel the process.**

For a profile with 4000 scores, loading takes approximately 2 minutes. ***Time will vary based on hardware specs and number of scores on the profile***.


## Supported preferences

All graphs currently repsect the following preferences:
* Mid Grades
* SSRNorm Sort

The following preferences are not yet fully supported:
* Color config
* Translations


# Screenshots

## Main graph tab

<img width="783" height="603" alt="image" src="https://github.com/user-attachments/assets/c3172f8f-f212-45ad-ba5e-a11c7ab7ef3c" />

## Bar graphs

<img width="775" height="599" alt="image" src="https://github.com/user-attachments/assets/28efde39-a361-4fb2-9124-d3a9672bb6b6" />
<img width="775" height="599" alt="image" src="https://github.com/user-attachments/assets/302f2e72-eaa2-4c3e-80a3-134eebf294d3" />
<img width="772" height="608" alt="image" src="https://github.com/user-attachments/assets/cf608b9f-cbf3-4229-8b00-c43c803a3631" />
<img width="771" height="611" alt="image" src="https://github.com/user-attachments/assets/1aae292c-04f6-4f5d-b8d6-ae12f3f95b65" />
<img width="771" height="606" alt="image" src="https://github.com/user-attachments/assets/bb5d0a06-058c-4aef-8d66-69964f820618" />
<img width="774" height="603" alt="image" src="https://github.com/user-attachments/assets/d0d2dc3f-7608-40ed-b065-d5eb283e4494" />
<img width="770" height="605" alt="image" src="https://github.com/user-attachments/assets/a4b460eb-7cbd-43e6-a86e-bb5b657b2e0b" />
<img width="771" height="604" alt="image" src="https://github.com/user-attachments/assets/5c8eaee3-95fe-4ffa-9a7e-26539b511056" />
<img width="771" height="602" alt="image" src="https://github.com/user-attachments/assets/b4c42058-dcb5-43c4-b392-15966a66f50b" />

## Scatter graphs

<img width="772" height="611" alt="image" src="https://github.com/user-attachments/assets/5bf5edf4-82ae-4438-95c1-7ac6a8433031" />
<img width="771" height="605" alt="image" src="https://github.com/user-attachments/assets/49858cd9-f1ee-487d-a1d0-7f437cc4f8e2" />
<img width="775" height="607" alt="image" src="https://github.com/user-attachments/assets/6c5578aa-82bb-49b4-9ad0-33cdc03023d0" />
<img width="778" height="608" alt="image" src="https://github.com/user-attachments/assets/3d759f55-83fa-4e8f-b681-9b4f1bfd24e0" />
<img width="785" height="611" alt="image" src="https://github.com/user-attachments/assets/df6b2356-1f48-4291-b430-562733fc777d" />
<img width="776" height="611" alt="image" src="https://github.com/user-attachments/assets/5f913600-9e3c-4b8f-a3eb-4f53c50848f5" />
<img width="774" height="606" alt="image" src="https://github.com/user-attachments/assets/f8fd664b-acb3-42e0-b5f8-115733906d59" />
<img width="781" height="602" alt="image" src="https://github.com/user-attachments/assets/fa047f65-3ee1-4067-a765-65d5e76bab5d" />
<img width="781" height="607" alt="image" src="https://github.com/user-attachments/assets/903be2ed-e284-47f0-9fc1-29e075338e5c" />

## Line graphs

<img width="773" height="602" alt="image" src="https://github.com/user-attachments/assets/30af643b-4591-43a3-b3d0-7d58b4002267" />
<img width="775" height="601" alt="image" src="https://github.com/user-attachments/assets/71aecb7a-a8af-46e3-85fb-949b8925baae" />

## Intensive graphs

<img width="779" height="606" alt="image" src="https://github.com/user-attachments/assets/8dfd0e81-ba47-44ac-8b5d-f1a088faf83d" />
<img width="779" height="605" alt="image" src="https://github.com/user-attachments/assets/f2c83957-aa9e-4887-98b4-87da7a403ad1" />
<img width="781" height="604" alt="image" src="https://github.com/user-attachments/assets/51da4701-ef7c-43a0-bfed-51532b2b9ae3" />
