# Tower Defense Game - Terminus

Classic tower defense game with few twist AI features. Made with Godot game engine.

## Description

Terminus is a standard tower defense game with an AI-driven twist. It uses Firebase for both database management and authentication, requiring players to sign in with a Google account to save progress, though the game can also be played in a test mode without signing in. Players can choose between three game modes: Standard, a classic wave-based mode; Endless, where a single wave continues indefinitely with gradually increasing difficulty; and AI Mode, where an LLM dynamically generates enemy waves designed to counter the player’s strategy. AI is also present in Standard mode, where players can request strategic advice before each wave, with the full game state and additional rules sent to the model to generate responses (results may vary due to the use of a free API model). 

The core gameplay revolves around strategic tower placement to prevent enemies from reaching the base. There are three enemy types—troops, tanks, and planes—each countered by a specific tower type: turrets, cannons, and missiles respectively. A fourth tower type, Support, does not attack but gradually generates coins and restores health. Towers have two upgrade tiers, while enemies have three tiers for added variety. The game ends if the base’s health reaches zero. When players sign in with a Google account, a profile is created to track statistics and progression across game modes.

### Dependencies

**If using exported executable:**
* Internet connection (required for Firebase and AI features)
**If running the project in Godot:**
* Godot Engine (version 4.5)
* Internet connection (required for Firebase and AI features)

### Installing

* Download exported executable (100 mb) from Google Drive:
```
https://drive.google.com/drive/folders/1BA1RBSU9d0wfDwFfZPpJTUTFVr471Qox
```

### Executing program

* Run downloaded executable:

## Help

Once in the main menu there is section called "Game Info" which has 5 sections of info going into dept about each aspect.
