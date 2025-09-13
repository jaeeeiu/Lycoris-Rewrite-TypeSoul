# Type://Soul Rewrite

**Module diff vs. previous snapshot: +1/-0/~2 (added/removed/changed)**
```diff
+ (added) MuraQuincy
+ (changed) Blossom
+ (changed) FingerCero
```

**Timing diff vs. previous snapshot: no changes detected.**

**New features?**
```diff
- (bug fix) Added Xeno to the shitsploit list for the hitbox check so now it should work properly
- (bug fix) Mod detector error detection retry fixed for all exploits relying on Lua returns instead of error & protected calls
- (bug fix) Mobile support for color picker context menu is now fixed
- (bug fix) Aim lock should no longer interfere with character AutoRotate (people were being able to turn while knocked)
- (bug fix) Fixed 3/4 (except for Failure Rate) "Allow Failure" options and their limitation checks to prevent it completely messing up AP
- (bug fix) Fixed "Can Dodge?" check to return a proper result (dodge fallbacks are now fixed aswell)
- (bug fix) Fixed ESP position bugs
- (removed) Anti AA Gun (it was simply not effective, interfered with PlatformStand)
+ (optimization) Optimized player position history tracking
+ (optimization) Optimized hitbox removals & how they are created
+ (addition) Added an AP filter which checked whether you were last knocked (250ms) too quickly
+ (addition) Aim lock sticky targets
+ (addition) Silent mode now auto-hides all other windows (freezes still show, but you can use this in SS now, assuming you hide visuals)
+ (addition) Script no longer sets any default features (+ watermark, keybind list) on upon execution
+ (addition) Auto Timing Prompt (Snake M2) <@333181876023984128>
```
*Organized prediction + hitbox code (+ new builder feature which allows facing angles to be predicted) with the newest update although that's irrelevant to you guys*
*Pink / grey -- predicted hitboxes*
*Green / red -- current state hitbox check*
*Lime / purple (per-timing) -- past hitbox check*
*Cyan / yellow (per-timing) -- predicted facing hitbox check, based on conditions to force a hitbox facing you*

Your commit ID should == "99e897" when the update is fully pushed to you.

**This is not the full (final-for-a-while) update.**
**1. This update log is mainly features & bug fixes. Yes, there is no AP updates due to burn-out. But, I myself am going to work on them this weekend.**

**2. There will be five features that I myself will be working on and then I'm completely done with Type Soul.**
- ESP Health Bars & Boxes & Customization Around That
- Easy Whitelist And Blacklist System
- Ignore Allies Rework (to optionally include your race, party members, and add a tooltip)
- CTU Update (more data on user elo & position on leaderboard & how close they are to reaching leaderboard)
- Mobile UI Button

**3. I plan on to unite the Type Soul and Deepwoken codebases because they share code and they have to be updated specifically for each one.**
**Then, I will start working on Deepwoken and sneak peaks there, for those who were waiting on Rewrite.**

**The expected release date for Testers on Deepwoken is the 20th of September.**
**The expected release date for Buyers on Deepwoken is the 27-30th of September.**

@Updates