# Last Stand: Three Fronts

Godot 4.6 project skeleton based on `Nazev.docx`. This version uses GDScript so it can run in the regular Steam build of Godot.

The project is structured for a 2D pixel-art single-player RTS/RPG/auto-battler:

- three combat lanes between player and enemy bases;
- selectable hero with four abilities;
- allied and enemy lane waves;
- neutral jungle camps;
- gold, experience and a basic shop upgrade loop;
- menu, hero select, in-game HUD and shop scenes.

Prototype controls:

- `WASD` or arrow keys: move hero;
- `1-4`: cast hero abilities toward the mouse cursor;
- `B`: toggle shop.

Hero respawn is enabled: the player hero respawns at base after 8 seconds, and the enemy hero after 12 seconds. Each selectable hero has the four abilities listed in the design document.

Open `project.godot` in the regular Godot 4.6 Steam build.

The previous C# version was moved to `legacy_csharp/` and hidden from Godot with `.gdignore`.
