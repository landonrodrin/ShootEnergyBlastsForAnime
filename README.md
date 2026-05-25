# ShootWalls

Rojo project for the Roblox Studio place.

## Folder Layout

- `src/features`: feature-owned code organized by current game systems.
  - `anime`: anime spawning, carry, placement, animation, viewports, and configs.
  - `bases`: base claiming, slots, prompts, economy, leveling, and base resources.
  - `players`: lifecycle, persistence, stats, inventory, tools, admin commands, and player controllers.
  - `shop`: shop-facing UI and upgrade/rebirth configs.
  - `ui`: cross-feature HUD, announcements, index, unlock, and UI animation modules.
  - `walls`: shooting, wall debris, wall gameplay, ladder nudges, and wall config.
- `src/shared`: shared packages, network packets, utilities, constants, and server-only shared helpers.
- `src/client`: client bootstrap synced as `StarterPlayerScripts.Main`.
- `src/server`: server bootstrap synced as `ServerScriptService.Main`.
- `src/ReplicatedStorage`, `src/ServerStorage`, `src/ServerScriptService`, and `src/StarterPlayer`: compatibility shims and service-specific mounts for existing runtime paths.
- `Packages`: Wally third-party packages synced into `ReplicatedStorage.Packages`.
- `assets`: source art/audio/mesh/reference files that are not synced by Rojo.

Workspace/map parts and most UI are intentionally managed in Roblox Studio, not Rojo.
Only move build assets into Rojo when you are ready for the folder to become the source of truth for those objects.

## Rojo

Run or keep running:

```powershell
rojo.cmd serve default.project.json --port 34872
```

In Roblox Studio, connect the Rojo plugin to `localhost:34872`.
