3D FPS survival horror "THE_LAST_STREETLIGHT" for Android.
Engine: Godot 4.7.stable, Mobile renderer, GDScript with strict typing.
Camera: first-person (FPS).

Core mechanics:
- Player: CharacterBody3D, WASD + mouse on PC, virtual joysticks + touch buttons on Android
- Weapons: hitscan shooting via RayCast3D, reload system, ammo inventory
- Enemies: AI with states (Idle, Patrol, Chase, Attack, Dead), NavigationAgent3D
- Atmosphere: dark urban environment, player flashlight (SpotLight3D), fog
- Health/damage system: HealthComponent attached to player and enemies
- Levels: procedurally placed street blocks or handcrafted blocks

Project structure:
- scenes/player/ — player scene, camera, weapons
- scenes/enemies/ — enemy types
- scenes/levels/ — level chunks
- scenes/ui/ — HUD, menus, touch controls
- scripts/autoload/ — GameState, SaveManager, AudioManager
- scripts/components/ — Health, Damage, Interactable
- assets/models/, assets/textures/, assets/audio/

Android requirements:
- TouchScreenButton for movement and camera
- Export preset: Android, min SDK 29, target 34
- 3D scaling 0.85 for weak devices, 60 FPS cap
- Pause on minimize, autosave

Code style:
- Strict GDScript typing: var name: Type
- @export for editable parameters
- class_name for reusable components
- Signals for decoupled architecture

Do NOT use:
- Physical bullets (rigid bodies) for shooting
- Compatibility renderer
- Untyped variables
