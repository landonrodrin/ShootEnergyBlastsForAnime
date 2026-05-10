# ShootWalls

Rojo project for the Roblox Studio place.

## Folder Layout

- `src/ReplicatedStorage/Shared`: shared modules used by client and server.
- `src/ReplicatedStorage/Packages`: third-party packages.
- `src/ReplicatedStorage/Remotes`: remote events/functions.
- `src/ServerScriptService`: server entry point and services.
- `src/StarterPlayer/StarterPlayerScripts`: client entry point and controllers.
- `assets`: source art/audio/mesh/reference files that are not synced by Rojo.

Workspace/map parts and most UI are intentionally managed in Roblox Studio, not Rojo.
Only move build assets into Rojo when you are ready for the folder to become the source of truth for those objects.

## Rojo

Run or keep running:

```powershell
rojo.cmd serve default.project.json --port 34872
```

In Roblox Studio, connect the Rojo plugin to `localhost:34872`.
