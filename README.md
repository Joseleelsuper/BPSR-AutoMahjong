# BPSR-AutoMahjong

Automates the Leader and Players button flow for Mahjong in Blue Protocol: Star Resonance.

## What it does

- The Leader presses **F** every 500 ms until pixel `#E8E8E8` appears at `(1485, 1015)`, then clicks that point.
- Players wait for pixel `#CCCCCC` at `(1675, 1025)`, then click that point.
- Both roles wait one minute, click `(925, 1000)` when it matches `#E8E8E8`, then click `(910, 1000)` when it matches the same color.
- After the shared steps, the script waits five seconds and repeats the selected role flow.
- Color checks allow a per-channel tolerance of 10 to account for minor rendering variation.

## Quick start

1. Download and run **BPSR-AutoMahjong.exe** from the [latest release](https://github.com/Joseleelsuper/BPSR-AutoMahjong/releases/latest).
2. Open the game and leave its window active.
3. The default role is **Players**. Press **F8** to switch to **Leader**.
4. Press **F9** to start or pause automation. Press **F10** to exit.

## Hotkeys

- **F8**: switch between Players and Leader. Changing role while running restarts the role-specific flow.
- **F9**: start or pause automation.
- **F10**: exit the script.

## Requirements and compatibility

- Windows and AutoHotkey v2.0.19 or newer.
- Use a 16:9 game client. Coordinates are scaled from a 1920x1080 reference.
- Keep the game window active while automation runs.
- When using Steam or the official launcher, run the script with administrator privileges.

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).

## Support

Join the [DaoPalace Discord server](https://discord.gg/brwaAZktrn) and find Joseleelsuper.
