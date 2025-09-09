# Type://Soul Rewrite

**Module diff vs. previous snapshot: no changes detected.**

**Timing diff vs. previous snapshot: no changes detected.**

**New features?**
```diff
- (bug fix) Added Xeno to the shitsploit list for the hitbox check so now it should work properly
- (bug fix) Mod detector error detection retry fixed for all exploits relying on Lua returns instead of error & protected calls
- (bug fix) Mobile support for color picker context menu is now fixed
- (bug fix) Aim lock should no longer interfere with character AutoRotate (people were being able to turn while knocked)
- (bug fix) Fixed 3/4 (except for Failure Rate) "Allow Failure" options and their limitation checks to prevent it completely messing up AP
- (bug fix) Fixed dodge check to return a proper result (dodge fallbacks are now fixed aswell)
- (bug fix) Fixed ESP position bugs
- (removed) Anti AA Gun (it was simply not effective, interfered with PlatformStand)
+ (optimization) Optimized player position history tracking
+ (optimization) Optimized hitbox removals & how they are created
+ (addition) Added an AP filter which checked whether you were last knocked (250ms) too quickly
+ (addition) Aim lock sticky targets
+ (addition) Silent mode now auto-hides all other windows (freezes still show, but you can use this in SS now, assuming you hide visuals)
+ (addition) Script no longer sets any default features (+ watermark, keybind list) on upon execution
+ (addition) Auto Timing Prompt (Snake M2) <@333181876023984128>
+ (addition) CTU update to better track ranked
+ (addition) Re-designed ESP w/ ESP boxes + health bar
```
*Organized prediction + hitbox code (+ new builder feature which allows facing angles to be predicted) with the newest update although that's irrelevant to you guys*
*Pink / grey -- predicted hitboxes*
*Green / red -- current state hitbox check*
*Lime / purple -- past hitbox check*
*Cyan / yellow -- predicted facing hitbox check, based on conditions to force a hitbox facing you*

Your commit ID should == "ccfc72a" when the update is fully pushed to you.
@Updates