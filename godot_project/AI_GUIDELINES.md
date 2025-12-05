# Godot Project AI Guidelines

This document provides comprehensive context and best practices for AI agents working on this Godot 4.5.1 project. Read this BEFORE making changes.

---

## Table of Contents
1. [Project Context](#project-context)
2. [Node Types Reference](#node-types-reference)
3. [Physics System](#physics-system)
4. [Collision Layers & Masks](#collision-layers--masks)
5. [Input Handling](#input-handling)
6. [CharacterBody3D Movement](#characterbody3d-movement)
7. [Signals & Connections](#signals--connections)
8. [Animation System](#animation-system)
9. [Materials & Shaders](#materials--shaders)
10. [UI & Control Nodes](#ui--control-nodes)
11. [Scene Structure & Instancing](#scene-structure--instancing)
12. [GDScript 2.0 Syntax](#gdscript-20-syntax)
13. [Common Pitfalls & Fixes](#common-pitfalls--fixes)
14. [Step-by-Step: Building a Game Scene](#step-by-step-building-a-game-scene)
15. [MCP Bridge Tooling](#mcp-bridge-tooling)
16. [Debugging Guide](#debugging-guide)
17. [Autoloads (Singletons)](#autoloads-singletons)
18. [Tweens (Smooth Animations)](#tweens-smooth-animations)
19. [Timers & Delays](#timers--delays)
20. [Groups](#groups)
21. [Scene Transitions](#scene-transitions)
22. [Resource Loading](#resource-loading)
23. [Raycasting](#raycasting)
24. [Node Lifecycle](#node-lifecycle)
25. [@export Variations](#export-variations)
26. [State Machines](#state-machines)
27. [Saving & Loading](#saving--loading)
28. [Audio System](#audio-system)
29. [Particles (GPUParticles3D)](#particles-gpuparticles3d)
30. [Navigation & AI Pathfinding](#navigation--ai-pathfinding)
31. [Custom Shaders](#custom-shaders)
32. [Quick Start Templates](#quick-start-templates)
33. [RigidBody3D (Physics Objects)](#rigidbody3d-physics-objects)
34. [2D Node Types Reference](#2d-node-types-reference)
35. [CharacterBody2D (Platformers)](#characterbody2d-platformers)
36. [TileMap & TileSet](#tilemap--tileset)
37. [Camera2D](#camera2d)
38. [AnimatedSprite2D](#animatedsprite2d)
39. [Area2D (2D Triggers)](#area2d-2d-triggers--pickups)
40. [RigidBody2D (Physics Puzzles)](#rigidbody2d-physics-puzzles)
41. [2D Mouse Input & Point-and-Click](#2d-mouse-input--point-and-click)
42. [2D Raycasting](#2d-raycasting)
43. [2D Platformer Template](#2d-platformer-template)
44. [Puzzle Game Patterns](#puzzle-game-patterns)
45. [2D Navigation (Point-and-Click)](#2d-navigation-point-and-click)
46. [ParallaxBackground (Scrolling)](#parallaxbackground-scrolling)
47. [Terrain & Landscapes](#terrain--landscapes-3d)
48. [Lighting Presets](#lighting-presets)
49. [Primitive Meshes](#primitive-meshes)
50. [UI Templates](#ui-templates)
51. [Save/Load System](#saveload-system)

---

## Project Context

| Property | Value |
|----------|-------|
| Engine Version | Godot 4.5.1 (Stable) |
| Language | GDScript 2.0 |
| Project Path | `godot_project/` |
| MCP Bridge Port | TCP 42069 |
| Plugin Location | `addons/mcp_bridge/` |

---

## Node Types Reference

### 3D Physics Bodies

| Node Type | Purpose | Use Case |
|-----------|---------|----------|
| `StaticBody3D` | Immovable solid | Floors, walls, platforms that don't move |
| `RigidBody3D` | Physics-driven movement | Crates, balls, anything affected by gravity/forces |
| `CharacterBody3D` | Script-controlled movement | Player characters, NPCs, enemies |
| `Area3D` | Detection zone (no collision response) | Triggers, pickups, damage zones |

### 3D Visual Nodes

| Node Type | Purpose |
|-----------|---------|
| `MeshInstance3D` | Displays a 3D mesh |
| `Camera3D` | Player viewpoint |
| `DirectionalLight3D` | Sun/moon light |
| `OmniLight3D` | Point light (bulb) |
| `SpotLight3D` | Cone light (flashlight) |
| `WorldEnvironment` | Sky, fog, ambient light |

### Collision Shapes

| Shape Type | Use Case |
|------------|----------|
| `BoxShape3D` | Crates, walls, floors |
| `SphereShape3D` | Balls, simple characters |
| `CapsuleShape3D` | Humanoid characters (best for players) |
| `CylinderShape3D` | Coins, pillars |
| `ConvexPolygonShape3D` | Complex convex objects |
| `ConcavePolygonShape3D` | Complex concave objects (static only) |

### UI Nodes

| Node Type | Purpose |
|-----------|---------|
| `Control` | Base UI container |
| `Label` | Text display |
| `Button` | Clickable button |
| `ProgressBar` | Health bars, loading bars |
| `TextureRect` | Image display |
| `Panel` | Background container |
| `CanvasLayer` | Separate rendering layer for UI |

---

## Physics System

### Body Hierarchy (CRITICAL)
A physics body MUST have a child `CollisionShape3D` with a valid `shape` resource to participate in physics.

```
✅ CORRECT:
Player (CharacterBody3D)
├── Camera3D
└── CollisionShape3D (with CapsuleShape3D)

❌ WRONG:
Player (CharacterBody3D)
└── Camera3D
    # No collision shape = no physics!
```

### Area3D for Detection
Use `Area3D` for triggers that detect overlaps but don't physically block:

```gdscript
extends Area3D

func _ready():
	# CRITICAL: Enable monitoring
	monitoring = true
	monitorable = true
	
	# Connect signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body.name == "Player":
		print("Player entered!")
		queue_free()  # Remove this node
```

### Signal Types for Area3D
| Signal | Fires When |
|--------|------------|
| `body_entered(body)` | A `CharacterBody3D`, `RigidBody3D`, or `StaticBody3D` enters |
| `body_exited(body)` | A physics body exits |
| `area_entered(area)` | Another `Area3D` enters |
| `area_exited(area)` | Another `Area3D` exits |

---

## Collision Layers & Masks

### Concept
- **Layer**: "I exist on these layers" (what I AM)
- **Mask**: "I detect things on these layers" (what I SEE)

### Default Setup
By default, everything is on Layer 1 and Masks Layer 1, so everything collides with everything.

### Recommended Layer Assignment
| Layer | Name | Used By |
|-------|------|---------|
| 1 | World | Floors, walls, static geometry |
| 2 | Player | Player character |
| 3 | Enemies | Enemy characters |
| 4 | Pickups | Coins, powerups |
| 5 | Projectiles | Bullets, arrows |

### Setting Layers via Code
```gdscript
# Method 1: Set entire bitmask (binary)
collision_layer = 0b0010  # Layer 2 only
collision_mask = 0b0101   # Detects layers 1 and 3

# Method 2: Set individual bits (cleaner)
set_collision_layer_value(1, false)  # Not on layer 1
set_collision_layer_value(2, true)   # On layer 2
set_collision_mask_value(1, true)    # Detect layer 1
set_collision_mask_value(4, true)    # Detect layer 4
```

### Common Mistake
```gdscript
# ❌ Player and Coin both on Layer 1, but:
# - Player masks Layer 1 ✓
# - Coin does NOT mask Layer 1 (or vice versa)
# Result: No detection!

# ✅ Fix: Ensure BOTH objects can "see" each other
# Player: Layer 2, Mask 1,4
# Coin (Area3D): Layer 4, Mask 2
```

---

## Input Handling

### Input Map (Project Settings)
Define actions in **Project > Project Settings > Input Map**:
```
move_forward  → W, Up Arrow
move_back     → S, Down Arrow  
move_left     → A, Left Arrow
move_right    → D, Right Arrow
jump          → Space
```

### Polling Input (in `_process` or `_physics_process`)
```gdscript
func _physics_process(delta):
	if Input.is_action_pressed("move_forward"):
		velocity.z = -SPEED
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_FORCE
```

### Event-Based Input (in `_input` or `_unhandled_input`)
```gdscript
func _unhandled_input(event):
	if event.is_action_pressed("jump"):
		velocity.y = JUMP_FORCE
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
```

### Mouse Capture (FPS Games)
```gdscript
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
```

### Getting Movement Direction
```gdscript
# 2D vector from 4 directional inputs
var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

# Convert to 3D world direction (respecting rotation)
var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
```

---

## CharacterBody3D Movement

### Complete FPS Controller Template
```gdscript
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.005

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
```

### Key Methods
| Method | Returns | Description |
|--------|---------|-------------|
| `move_and_slide()` | `bool` | Moves body, handles collisions, returns true if moved |
| `is_on_floor()` | `bool` | True if standing on ground |
| `is_on_wall()` | `bool` | True if touching a wall |
| `is_on_ceiling()` | `bool` | True if head hit ceiling |
| `get_floor_normal()` | `Vector3` | Normal of the floor surface |
| `get_slide_collision_count()` | `int` | Number of collisions this frame |

---

## Signals & Connections

### Connecting in Code (Godot 4 Style)
```gdscript
# Method 1: Direct connection
button.pressed.connect(_on_button_pressed)

# Method 2: With Callable (for methods with different names)
area.body_entered.connect(Callable(self, "_on_body_entered"))

# Method 3: Defensive connection (won't error if already connected)
if not area.is_connected("body_entered", Callable(self, "_on_body_entered")):
    area.connect("body_entered", Callable(self, "_on_body_entered"))
```

### Disconnecting
```gdscript
button.pressed.disconnect(_on_button_pressed)
```

### Custom Signals
```gdscript
# Define signal at top of script
signal health_changed(new_health)
signal died

# Emit signal
health_changed.emit(current_health)
died.emit()

# Connect from another script
player.health_changed.connect(_on_player_health_changed)
```

---

## Animation System

### Godot 4 AnimationLibrary System
In Godot 4, animations are stored in `AnimationLibrary` objects, not directly on `AnimationPlayer`.

```gdscript
# ❌ WRONG (Godot 3 style, will fail)
animation_player.add_animation("walk", anim)

# ✅ CORRECT (Godot 4 style)
var lib = animation_player.get_animation_library("")
if not lib:
    lib = AnimationLibrary.new()
    animation_player.add_animation_library("", lib)
lib.add_animation("walk", anim)
```

### Creating Animation via Code
```gdscript
var anim = Animation.new()
anim.length = 2.0

# Add a track
var track_idx = anim.add_track(Animation.TYPE_VALUE)
anim.track_set_path(track_idx, "Coin:position")  # Relative path from AnimationPlayer
anim.track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
anim.track_insert_key(track_idx, 2.0, Vector3(0, 2, 0))

# Add to library
var lib = animation_player.get_animation_library("")
lib.add_animation("float_up", anim)
```

### Playing Animations
```gdscript
animation_player.play("walk")
animation_player.play("attack", -1, 2.0)  # Custom blend, 2x speed
animation_player.stop()
animation_player.seek(0.5, true)  # Jump to 0.5 seconds
```

---

## Materials & Shaders

### StandardMaterial3D (Basic Colors)
```gdscript
var mat = StandardMaterial3D.new()
mat.albedo_color = Color(1.0, 0.8, 0.0)  # Gold
mat.metallic = 1.0
mat.roughness = 0.2
mat.emission_enabled = true
mat.emission = Color(0.2, 0.1, 0.0)

# Apply to mesh resource
mesh.material = mat

# OR apply to MeshInstance3D (overrides mesh material)
mesh_instance.material_override = mat
```

### ShaderMaterial (Custom Effects)
```gdscript
# Create shader file (res://my_shader.gdshader):
# shader_type spatial;
# void fragment() {
#     ALBEDO = vec3(1.0, 0.0, 0.0);
# }

var shader = load("res://my_shader.gdshader")
var mat = ShaderMaterial.new()
mat.shader = shader
mat.set_shader_parameter("my_param", 1.5)
```

### Common Material Properties
| Property | Type | Description |
|----------|------|-------------|
| `albedo_color` | Color | Base color |
| `metallic` | float (0-1) | Metal look |
| `roughness` | float (0-1) | Surface roughness |
| `emission` | Color | Glow color |
| `transparency` | enum | DISABLED, ALPHA, ALPHA_SCISSOR |

---

## UI & Control Nodes

### Anchor Presets
```gdscript
# Position control in corner/edge
control.set_anchors_preset(Control.PRESET_TOP_LEFT)
control.set_anchors_preset(Control.PRESET_CENTER)
control.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill parent
```

### Available Presets
| Preset | Position |
|--------|----------|
| `PRESET_TOP_LEFT` | Top-left corner |
| `PRESET_TOP_RIGHT` | Top-right corner |
| `PRESET_BOTTOM_LEFT` | Bottom-left corner |
| `PRESET_BOTTOM_RIGHT` | Bottom-right corner |
| `PRESET_CENTER` | Center of parent |
| `PRESET_FULL_RECT` | Fill entire parent |
| `PRESET_LEFT_WIDE` | Left edge, full height |
| `PRESET_TOP_WIDE` | Top edge, full width |

### Offsets (Position Relative to Anchors)
```gdscript
control.offset_left = 20    # 20px from left anchor
control.offset_top = 20     # 20px from top anchor
control.offset_right = -20  # 20px from right anchor (negative = inward)
control.offset_bottom = -20
```

### CanvasLayer for HUD
```
Main (Node3D)
├── Player
├── WorldEnv
└── CanvasLayer        # Renders on top of 3D
    └── HUD (Control)
        ├── HealthBar
        └── ScoreLabel
```

---

## Scene Structure & Instancing

### Resource Uniqueness (CRITICAL)
When duplicating nodes via code, resources are **shared by default**.

```gdscript
# ❌ WRONG: All coins share same mesh, changing one changes all
var coin2 = coin1.duplicate()

# ✅ CORRECT: Create new resources for each instance
for coin in coins:
    var mesh = CylinderMesh.new()
    mesh.height = 0.1
    mesh.top_radius = 0.4
    coin.get_node("Visual").mesh = mesh
```

### PackedScene Instancing
```gdscript
# Load once, instance many times
var coin_scene = preload("res://coin.tscn")

func spawn_coin(pos: Vector3):
    var coin = coin_scene.instantiate()
    coin.position = pos
    add_child(coin)
    coin.owner = self  # Important for saving!
```

### Node Ownership (for Saving Scenes)
```gdscript
# When adding nodes dynamically, set owner to scene root
new_node.owner = get_tree().edited_scene_root  # In editor
new_node.owner = self  # At runtime (if self is root)
```

---

## GDScript 2.0 Syntax

### Type Hints
```gdscript
var health: int = 100
var speed: float = 5.0
var player_name: String = "Hero"
var items: Array[String] = []
var position: Vector3 = Vector3.ZERO

func take_damage(amount: int) -> bool:
    health -= amount
    return health <= 0
```

### Annotations
```gdscript
@tool                           # Run in editor
@export var speed: float = 5.0  # Show in Inspector
@export_range(0, 100) var health: int = 100
@export_enum("Sword", "Bow", "Staff") var weapon: int
@onready var camera = $Camera3D # Initialize after _ready
```

### No Ternary Operator!
```gdscript
# ❌ WRONG (C-style, causes parse error)
var x = condition ? "yes" : "no"

# ✅ CORRECT (Python-style)
var x = "yes" if condition else "no"
```

### Match Statement (Switch)
```gdscript
match state:
    State.IDLE:
        play_idle_animation()
    State.WALKING:
        play_walk_animation()
    _:
        print("Unknown state")
```

### Lambdas
```gdscript
var double = func(x): return x * 2
print(double.call(5))  # 10

# With signals
button.pressed.connect(func(): print("Pressed!"))
```

---

## Common Pitfalls & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Grey untextured mesh | No material assigned | Create and assign `StandardMaterial3D` |
| Signal not firing | `monitoring = false` or not connected | Enable monitoring, connect in `_ready()` |
| Node not found | Wrong path or scene renamed | Use `get_node_or_null()`, verify root name |
| `@` parse error | Stray `@@` or typo | Check for doubled `@` symbols |
| `?` parse error | C-style ternary operator | Use `x if cond else y` |
| Animation not added | Godot 3 style `add_animation` | Use `AnimationLibrary` |
| Player falls through floor | Missing `CollisionShape3D` | Add collision shape to both player AND floor |
| Area3D not detecting | Different collision layers | Ensure layers/masks overlap |
| Duplicated nodes all change together | Shared resources | Create new resource instances |
| Changes not saving | `owner` not set | Set `node.owner = root` |
| Script changes not applying | Editor caching | Reload scene or toggle plugin |
| **Shader params not working** | **Using `material_override` (null)** | **Use `get_surface_override_material(0)`** |
| **NoiseTexture2D is white/blank** | **Texture generates async** | **Use `await texture.changed`** |
| **Terrain/mesh stays white** | **Textures not ready** | **Wait for async generation** |

### ⚠️ CRITICAL: NoiseTexture2D Generates Asynchronously

`NoiseTexture2D` generates its data on a **background thread**. If you assign it immediately, it will be **blank/white** until generation completes!

#### ❌ WRONG - Texture will be white:
```gdscript
var tex = NoiseTexture2D.new()
tex.noise = FastNoiseLite.new()
material.set_shader_parameter("texture", tex)  # WHITE - not ready yet!
```

#### ✅ CORRECT - Wait for generation:
```gdscript
var tex = NoiseTexture2D.new()
tex.noise = FastNoiseLite.new()
await tex.changed  # WAIT for background thread to finish
material.set_shader_parameter("texture", tex)  # Now it has data!
```

#### In MCP `execute_code` Context:
Since `execute_code` doesn't support `await`, NoiseTexture2D textures assigned via MCP may appear white for a few seconds until generation completes. **This is expected behavior** - the texture will appear once the background thread finishes.

**Workaround:** If immediate visual feedback is needed:
1. Create and save textures as `.tres` files first
2. Or use pre-made placeholder textures
3. Or accept the brief white flash while textures generate

---

## Step-by-Step: Building a Game Scene

### 1. Create Main Scene
```gdscript
# Node hierarchy:
Main (Node3D)
├── WorldEnvironment (with sky)
├── DirectionalLight3D (sun)
├── Floor (StaticBody3D)
│   ├── MeshInstance3D (BoxMesh)
│   └── CollisionShape3D (BoxShape3D)
├── Player (CharacterBody3D)
│   ├── Camera3D
│   └── CollisionShape3D (CapsuleShape3D)
└── HUD (CanvasLayer)
    └── Control
        ├── HealthBar (ProgressBar)
        └── ScoreLabel (Label)
```

### 2. Environment Setup
```gdscript
# WorldEnvironment
var env = Environment.new()
env.background_mode = Environment.BG_SKY
var sky = Sky.new()
sky.sky_material = ProceduralSkyMaterial.new()
env.sky = sky
env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
world_env_node.environment = env

# DirectionalLight3D
sun.rotation_degrees = Vector3(-45, 45, 0)
sun.shadow_enabled = true
```

### 3. Floor Setup
```gdscript
var mesh = BoxMesh.new()
mesh.size = Vector3(20, 1, 20)
floor_mesh.mesh = mesh

var shape = BoxShape3D.new()
shape.size = Vector3(20, 1, 20)
floor_col.shape = shape

floor.position = Vector3(0, -0.5, 0)  # Top surface at y=0
```

### 4. Player Setup
```gdscript
# Position
player.position = Vector3(0, 1, 0)  # Above floor

# Collision
var capsule = CapsuleShape3D.new()
capsule.height = 1.8
capsule.radius = 0.4
player_col.shape = capsule
player_col.position = Vector3(0, 0.9, 0)  # Center capsule

# Camera at eye level
camera.position = Vector3(0, 1.6, 0)
```

### 5. Pickup Item Setup
```gdscript
# Create as separate scene: coin.tscn
# Root: Area3D (with script)
#   ├── MeshInstance3D (CylinderMesh, height=0.1)
#   └── CollisionShape3D (CylinderShape3D, height=0.1)

# Coin script:
extends Area3D

func _ready():
    monitoring = true
    body_entered.connect(_on_body_entered)

func _process(delta):
    rotate_y(2.0 * delta)

func _on_body_entered(body):
    if body.name == "Player":
        var main = get_node_or_null("/root/Main")
        if main and main.has_method("add_score"):
            main.add_score(10)
        queue_free()
```

---

## MCP Bridge Tooling

### 📚 Documentation Lookup Tools (USE THESE FIRST!)
The MCP server includes built-in Godot documentation lookup. **Always check docs before implementing features!**

| Tool | Usage | Example |
|------|-------|---------|
| `godot_docs` | Look up a specific class | `godot_docs("MeshInstance3D")` |
| `godot_docs_search` | Search docs for a topic | `godot_docs_search("collision layers")` |

**When to use:**
- Before using any unfamiliar class
- When something isn't working as expected
- To check for async behavior (like `NoiseTexture2D.changed`)
- To verify Godot 4 vs Godot 3 API differences
- To find correct signal names and parameters

### Overview
The `server.gd` plugin in `addons/mcp_bridge/` enables external tools to control Godot via TCP.

### Full Command Reference

| Method | Parameters | Description |
|--------|------------|-------------|
| `ping` | none | Test connection |
| `get_scene_tree` | none | Get current scene hierarchy |
| `add_node` | type, name, parent_path | Create new node |
| `delete_node` | path | Remove node |
| `set_property` | path, property, value | Set node property |
| `get_node_details` | path | Get all properties |
| `save_scene` | path | Save scene to disk |
| `open_scene` | path | Open existing scene |
| `new_scene` | root_type, name | Create new empty scene |
| `instantiate_scene` | path, parent_path | Add .tscn as child |
| `execute_script` | code | Run arbitrary GDScript |
| `create_script` | path, content | Create .gd file |
| `attach_script` | node_path, script_path | Attach script to node |
| `connect_signal` | source, signal, target, method | Connect signal |
| `create_simple_animation` | player_path, animation_name, ... | Create animation |
| `play_animation` | path, animation | Play animation |
| `add_resource` | node_path, property, resource_type | Add resource |
| `find_nodes_by_type` | type | Search scene |
| `get_editor_screenshot` | none | Capture editor |
| `generate_terrain_mesh` | size, height, seed | Create 3D terrain mesh |
| `create_terrain_material` | path, type | Generate terrain shader |
| `create_particle_effect` | preset, is_3d | Create particle system |
| `lighting_preset` | preset | Setup scene lighting |
| `create_primitive` | shape, size, color | Create 3D mesh |
| `create_ui_template` | template | Create UI layout |
| `save_game_data` | filename, data | Save JSON to user:// |
| `load_game_data` | filename | Load JSON from user:// |

### Best Practices for MCP
1. **Always save** after making changes: Call `save_scene` to persist.
2. **Delete and recreate** broken nodes rather than patching.
3. **Use `execute_script`** for complex multi-step operations.
4. **Reload plugin** if script changes don't apply.
5. **Check paths** before operations - use `get_scene_tree` to verify structure.

---

## Debugging Guide

### Print Debugging
```gdscript
print("Value: ", some_var)
print("Node path: ", get_path())
print("Node class: ", get_class())
print("Children: ", get_children())
```

### Check Node Existence
```gdscript
var node = get_node_or_null("SomePath")
if node:
	print("Found: ", node.name)
else:
	print("Not found!")
```

### Inspect Physics State
```gdscript
# In _physics_process
print("On floor: ", is_on_floor())
print("Velocity: ", velocity)
print("Collision count: ", get_slide_collision_count())
```

### Signal Debugging
```gdscript
func _ready():
	# List all signals on this node
	for sig in get_signal_list():
		print(sig.name)
	
	# Check if connected
	print("Connected: ", is_connected("body_entered", Callable(self, "_on_body_entered")))
```

### Common Error Messages

| Error | Meaning | Fix |
|-------|---------|-----|
| `Invalid get index 'name' (on base: 'null')` | Node doesn't exist | Check path, use `get_node_or_null` |
| `Cannot call method 'X' on a null value` | Variable is null | Initialize variable, check existence |
| `Parse Error: Expected...` | Syntax error | Check line for typos |
| `Identifier not declared` | Variable/function doesn't exist | Check spelling, scope |
| `Signal 'X' is already connected` | Duplicate connection | Use defensive connection pattern |

---

## Quick Reference Card

### Creating Common Objects

```gdscript
# Gold Coin
var mesh = CylinderMesh.new()
mesh.height = 0.1
mesh.top_radius = 0.4
mesh.bottom_radius = 0.4
var mat = StandardMaterial3D.new()
mat.albedo_color = Color(1, 0.8, 0)
mat.metallic = 1.0
mesh.material = mat

# Capsule Collision for Player
var shape = CapsuleShape3D.new()
shape.height = 1.8
shape.radius = 0.4

# Box for Floor
var floor_mesh = BoxMesh.new()
floor_mesh.size = Vector3(20, 1, 20)
var floor_shape = BoxShape3D.new()
floor_shape.size = Vector3(20, 1, 20)
```

### Essential Checks Before Running

- [ ] Player has `CollisionShape3D` with valid shape
- [ ] Floor has `CollisionShape3D` with valid shape
- [ ] Area3D has `monitoring = true`
- [ ] Signals are connected
- [ ] Collision layers/masks overlap
- [ ] Scene is saved
- [ ] Scripts have no errors

---

## Autoloads (Singletons)

Autoloads are scripts/scenes loaded automatically at game start, accessible from anywhere.

### Setting Up Autoloads
In **Project > Project Settings > Globals > Autoload**, add scripts:

| Name | Path | Use Case |
|------|------|----------|
| `GameManager` | `res://game_manager.gd` | Score, lives, game state |
| `AudioManager` | `res://audio_manager.tscn` | Music, SFX |
| `SaveManager` | `res://save_manager.gd` | Save/load data |

### Creating an Autoload
```gdscript
# game_manager.gd
extends Node

var score: int = 0
var current_level: int = 1

func add_score(amount: int):
	score += amount

func reset_game():
	score = 0
	current_level = 1
```

### Using from Any Script
```gdscript
# From any script in the project:
GameManager.add_score(100)
print(GameManager.score)
```

---

## Tweens (Smooth Animations)

Tweens interpolate values over time - perfect for UI animations, smooth movement, and effects.

### Basic Tween Usage
```gdscript
func _ready():
	var tween = create_tween()
	
	# Move node to position over 1 second
	tween.tween_property(self, "position", Vector3(10, 0, 0), 1.0)
	
	# Chain animations (runs after previous finishes)
	tween.tween_property(self, "rotation_degrees", Vector3(0, 180, 0), 0.5)

func fade_out():
	var tween = create_tween()
	tween.tween_property($Sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)  # Delete after fade
```

### Transition & Easing Types
```gdscript
var tween = create_tween()
tween.tween_property(self, "position", target_pos, 1.0) \
	.set_trans(Tween.TRANS_BOUNCE) \
	.set_ease(Tween.EASE_OUT)
```

| Transition | Effect |
|------------|--------|
| `TRANS_LINEAR` | Constant speed |
| `TRANS_SINE` | Smooth wave |
| `TRANS_BOUNCE` | Bouncy |
| `TRANS_ELASTIC` | Springy overshoot |
| `TRANS_BACK` | Slight overshoot |

| Easing | Effect |
|--------|--------|
| `EASE_IN` | Start slow, end fast |
| `EASE_OUT` | Start fast, end slow |
| `EASE_IN_OUT` | Smooth both ends |

### Parallel Tweens
```gdscript
var tween = create_tween()
tween.set_parallel(true)  # Run simultaneously
tween.tween_property(self, "position:x", 10.0, 1.0)
tween.tween_property(self, "rotation:y", PI, 1.0)
```

### Looping Tweens
```gdscript
var tween = create_tween()
tween.set_loops()  # Infinite loop
tween.tween_property($Coin, "rotation:y", TAU, 2.0).from(0.0)
```

---

## Timers & Delays

### One-Shot Timer (await)
```gdscript
func spawn_enemy():
	print("Spawning in 2 seconds...")
	await get_tree().create_timer(2.0).timeout
	print("Spawned!")
	# Continue code here after delay
```

### Timer Node
```gdscript
# Add Timer node as child, then:
func _ready():
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.wait_time = 1.0
	$Timer.one_shot = false  # Repeating
	$Timer.start()

func _on_timer_timeout():
	spawn_enemy()
```

### Creating Timer in Code
```gdscript
var timer = Timer.new()
timer.wait_time = 3.0
timer.one_shot = true
timer.timeout.connect(func(): print("Done!"))
add_child(timer)
timer.start()
```

---

## Groups

Groups let you organize nodes and perform batch operations.

### Adding to Groups
```gdscript
# In script
func _ready():
	add_to_group("enemies")
	add_to_group("damageable")

# Or in editor: Node > Groups tab
```

### Querying Groups
```gdscript
# Get all nodes in group
var enemies = get_tree().get_nodes_in_group("enemies")
for enemy in enemies:
	enemy.take_damage(10)

# Get first node in group
var player = get_tree().get_first_node_in_group("player")

# Call method on all nodes in group
get_tree().call_group("enemies", "alert")

# Check if in group
if is_in_group("enemies"):
	print("I'm an enemy!")
```

### Common Group Uses
| Group | Use Case |
|-------|----------|
| `"player"` | Find player easily |
| `"enemies"` | Mass destroy, count |
| `"persist"` | Nodes to save |
| `"damageable"` | Things that take damage |
| `"interactable"` | Things player can use |

---

## Scene Transitions

### Change Scene by Path
```gdscript
func go_to_level(level_num: int):
	get_tree().change_scene_to_file("res://levels/level_%d.tscn" % level_num)
```

### Change Scene by PackedScene
```gdscript
var next_level = preload("res://levels/level_2.tscn")

func load_next_level():
	get_tree().change_scene_to_packed(next_level)
```

### Reload Current Scene
```gdscript
func restart_level():
	get_tree().reload_current_scene()
```

### Fade Transition
```gdscript
# With autoload SceneManager:
func change_with_fade(new_scene_path: String):
	var tween = create_tween()
	tween.tween_property($FadeRect, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(new_scene_path)
	tween = create_tween()
	tween.tween_property($FadeRect, "modulate:a", 0.0, 0.5)
```

---

## Resource Loading

### Preload (Compile Time)
```gdscript
# Loaded when script compiles - use for always-needed resources
var coin_scene = preload("res://coin.tscn")
var player_texture = preload("res://player.png")
```

### Load (Runtime)
```gdscript
# Loaded when line executes - use for conditional/dynamic loading
func spawn_enemy(type: String):
	var scene = load("res://enemies/%s.tscn" % type)
	var enemy = scene.instantiate()
	add_child(enemy)
```

### Check Resource Exists
```gdscript
if ResourceLoader.exists("res://levels/level_5.tscn"):
	get_tree().change_scene_to_file("res://levels/level_5.tscn")
else:
	print("Level not found!")
```

### Background Loading (Large Resources)
```gdscript
var loading_path = "res://huge_level.tscn"

func start_loading():
	ResourceLoader.load_threaded_request(loading_path)

func _process(delta):
	var status = ResourceLoader.load_threaded_get_status(loading_path)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var progress = []
			ResourceLoader.load_threaded_get_status(loading_path, progress)
			print("Loading: %d%%" % (progress[0] * 100))
		ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(loading_path)
			get_tree().change_scene_to_packed(resource)
```

---

## Raycasting

### RayCast3D Node
```gdscript
@onready var raycast = $RayCast3D

func _physics_process(delta):
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var point = raycast.get_collision_point()
		var normal = raycast.get_collision_normal()
		print("Hit: ", collider.name, " at ", point)
```

### Code-Based Raycast
```gdscript
func shoot():
	var space_state = get_world_3d().direct_space_state
	var origin = camera.global_position
	var end = origin + camera.global_transform.basis.z * -100
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]  # Don't hit yourself
    query.collision_mask = 0b0011  # Only layers 1 and 2
    
    var result = space_state.intersect_ray(query)
    if result:
        print("Hit: ", result.collider.name)
        print("Position: ", result.position)
        print("Normal: ", result.normal)
```

### Common Raycast Uses
| Use Case | Setup |
|----------|-------|
| Ground check | Ray pointing down |
| Wall check | Ray pointing forward |
| Line of sight | Ray to target, check if blocked |
| Shooting | Ray from camera forward |
| Mouse picking | Ray from camera through mouse |

---

## Node Lifecycle

### Callback Order
```
1. _init()           # Constructor, runs first
2. _enter_tree()     # Added to scene tree
3. _ready()          # All children ready
4. _process(delta)   # Every frame (repeating)
5. _physics_process(delta)  # Every physics tick (repeating)
6. _exit_tree()      # Removed from tree
7. _notification()   # For specific events
```

### Important Notes
```gdscript
func _ready():
    # Children are ready here
    # @onready vars are set
    # Safe to access child nodes
    pass

func _process(delta):
    # Called every RENDER frame
    # delta = time since last frame
    # Use for: animations, UI, input
    pass

func _physics_process(delta):
    # Called every PHYSICS tick (default 60/sec)
    # delta = fixed timestep (usually 1/60)
    # Use for: movement, physics, collision response
    pass
```

### Controlling Processing
```gdscript
# Disable _process
set_process(false)

# Disable _physics_process
set_physics_process(false)

# Disable input
set_process_input(false)
```

---

## @export Variations

### Basic Exports
```gdscript
@export var health: int = 100
@export var speed: float = 5.0
@export var player_name: String = "Hero"
```

### Range Exports
```gdscript
@export_range(0, 100) var percentage: int = 50
@export_range(0.0, 1.0, 0.1) var opacity: float = 1.0  # With step
@export_range(0, 100, 1, "or_greater") var damage: int  # Allow > max
```

### Enum Exports
```gdscript
enum Weapon { SWORD, BOW, STAFF }
@export var weapon: Weapon = Weapon.SWORD

# Or inline
@export_enum("Easy", "Normal", "Hard") var difficulty: int = 1
```

### File/Folder Exports
```gdscript
@export_file var config_path: String
@export_file("*.json") var data_file: String  # Filter
@export_dir var save_folder: String
```

### Node/Resource Exports
```gdscript
@export var target: Node3D
@export var bullet_scene: PackedScene
@export var player_texture: Texture2D
```

### Grouped Exports
```gdscript
@export_group("Movement")
@export var speed: float = 5.0
@export var jump_force: float = 10.0

@export_group("Combat")
@export var damage: int = 10
@export var attack_range: float = 2.0

@export_subgroup("Advanced")
@export var crit_chance: float = 0.1
```

---

## State Machines

### Simple Enum-Based State Machine
```gdscript
extends CharacterBody3D

enum State { IDLE, WALKING, JUMPING, ATTACKING }
var current_state: State = State.IDLE

func _physics_process(delta):
    match current_state:
        State.IDLE:
            _idle_state(delta)
        State.WALKING:
            _walking_state(delta)
        State.JUMPING:
            _jumping_state(delta)
        State.ATTACKING:
            _attacking_state(delta)

func _idle_state(delta):
    if Input.is_action_pressed("move_forward"):
        change_state(State.WALKING)
    if Input.is_action_just_pressed("jump"):
        change_state(State.JUMPING)

func change_state(new_state: State):
    # Exit current state
    match current_state:
        State.ATTACKING:
            $AnimationPlayer.stop()
    
    current_state = new_state
    
    # Enter new state
    match new_state:
        State.JUMPING:
            velocity.y = JUMP_VELOCITY
        State.ATTACKING:
            $AnimationPlayer.play("attack")
```

---

## Saving & Loading

### ConfigFile (Simple Settings)
Best for: Settings, preferences, simple key-value data.

```gdscript
# Saving settings
func save_settings():
    var config = ConfigFile.new()
    config.set_value("audio", "master_volume", 0.8)
    config.set_value("audio", "sfx_volume", 1.0)
    config.set_value("video", "fullscreen", true)
    config.set_value("video", "resolution", "1920x1080")
    config.save("user://settings.cfg")

# Loading settings
func load_settings():
    var config = ConfigFile.new()
    var err = config.load("user://settings.cfg")
    if err != OK:
		return  # File doesn't exist yet
	
	var volume = config.get_value("audio", "master_volume", 0.8)
	var fullscreen = config.get_value("video", "fullscreen", false)
```

### JSON (Game Saves)
Best for: Complex save data, interoperability.

```gdscript
# Save game to JSON
func save_game():
	var save_data = {
		"player": {
			"position": {"x": player.position.x, "y": player.position.y, "z": player.position.z},
			"health": player.health,
			"inventory": player.inventory
		},
		"level": current_level,
		"score": score
	}
	
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))  # Pretty print

# Load game from JSON
func load_game():
	if not FileAccess.file_exists("user://savegame.json"):
		return false
	
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error != OK:
		print("JSON parse error: ", json.get_error_message())
		return false
	
	var data = json.data
	player.position = Vector3(data.player.position.x, data.player.position.y, data.player.position.z)
	player.health = data.player.health
	return true
```

### FileAccess (Raw Files)
```gdscript
# Write text file
func write_text(path: String, content: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)

# Read text file
func read_text(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	return file.get_as_text()

# Check if file exists
if FileAccess.file_exists("user://savegame.json"):
	print("Save exists!")
```

### Save Paths
| Path | Location | Use |
|------|----------|-----|
| `user://` | User data folder | Saves, settings |
| `res://` | Project folder | Game assets (read-only in export) |

---

## Audio System

### Audio Nodes
| Node | Use Case |
|------|----------|
| `AudioStreamPlayer` | 2D/UI sounds, music |
| `AudioStreamPlayer2D` | Positional 2D audio |
| `AudioStreamPlayer3D` | Positional 3D audio |

### Basic Audio Playback
```gdscript
# Play sound effect
func play_sound(sound: AudioStream):
	var player = AudioStreamPlayer.new()
	player.stream = sound
	player.bus = "SFX"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)  # Auto-cleanup

# Preloaded sound
@onready var jump_sound = preload("res://sounds/jump.ogg")

func jump():
	$JumpSFX.play()  # If AudioStreamPlayer child exists
```

### Audio Buses
Set up in **Project > Project Settings > Audio > Buses** or edit `default_bus_layout.tres`.

```gdscript
# Set bus volume (in dB)
AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -10.0)

# Mute a bus
AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), true)

# Get current volume
var volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
```

### 3D Positional Audio
```gdscript
# AudioStreamPlayer3D properties
@onready var audio_3d = $AudioStreamPlayer3D

func _ready():
	audio_3d.unit_size = 10.0        # Distance for full volume
	audio_3d.max_distance = 100.0    # Distance where sound is silent
	audio_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
```

### Common Audio Buses Setup
```
Master (output)
├── Music (background music, lower volume)
├── SFX (sound effects)
└── Voice (dialogue, always audible)
```

---

## Particles (GPUParticles3D)

### Basic Particle Setup
```gdscript
var particles = GPUParticles3D.new()
particles.amount = 100
particles.lifetime = 2.0
particles.one_shot = false
particles.emitting = true

# Process material (controls particle behavior)
var mat = ParticleProcessMaterial.new()
mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
mat.emission_sphere_radius = 1.0
mat.direction = Vector3(0, 1, 0)
mat.spread = 45.0
mat.initial_velocity_min = 5.0
mat.initial_velocity_max = 10.0
mat.gravity = Vector3(0, -9.8, 0)
particles.process_material = mat

# Draw pass (what particles look like)
var mesh = QuadMesh.new()
mesh.size = Vector2(0.2, 0.2)
particles.draw_pass_1 = mesh

add_child(particles)
```

### Common Particle Properties
```gdscript
# ParticleProcessMaterial settings
mat.color = Color(1, 0.5, 0, 1)  # Orange
mat.scale_min = 0.5
mat.scale_max = 1.5
mat.hue_variation_min = -0.1
mat.hue_variation_max = 0.1
mat.damping_min = 1.0
mat.damping_max = 5.0
```

### Emission Shapes
| Shape | Use Case |
|-------|----------|
| `EMISSION_SHAPE_POINT` | Single point (default) |
| `EMISSION_SHAPE_SPHERE` | Round area |
| `EMISSION_SHAPE_BOX` | Rectangular area |
| `EMISSION_SHAPE_RING` | Circle edge |

### One-Shot Particles (Explosions)
```gdscript
func spawn_explosion(pos: Vector3):
	var particles = preload("res://effects/explosion.tscn").instantiate()
	particles.position = pos
	particles.one_shot = true
	particles.emitting = true
	add_child(particles)
	
	# Auto-cleanup after particles finish
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()
```

### MCP Tool: Create Particle Effect
The `create_particle_effect` tool creates ready-to-use particle systems with presets:

| Preset | Description |
|--------|-------------|
| `fire` | Flames with orange/yellow gradient |
| `smoke` | Gray billowing smoke |
| `sparks` | Flying bright sparks |
| `explosion` | One-shot burst (auto one_shot) |
| `magic` | Purple/blue swirling particles |
| `rain` | Falling rain drops |
| `snow` | Gently falling snowflakes |
| `dust` | Ground dust/debris |
| `leaves` | Falling autumn leaves |
| `blood` | Blood splatter (one-shot) |

**Usage:**
```
godot_create_particle_effect(preset="fire", name="TorchFlame")
godot_create_particle_effect(preset="explosion", name="Boom", one_shot=true)
godot_create_particle_effect(preset="rain", is_3d=true, name="Weather")
```

---

## Navigation & AI Pathfinding

### Setup Requirements
1. Add `NavigationRegion3D` to scene
2. Assign a `NavigationMesh` resource
3. Bake the navigation mesh (in editor)
4. Add `NavigationAgent3D` to AI characters

### Scene Structure
```
World (Node3D)
├── NavigationRegion3D
│   └── NavigationMesh (resource)
├── Floor (StaticBody3D)
├── Walls (StaticBody3D)
└── Enemy (CharacterBody3D)
	└── NavigationAgent3D
```

### Basic AI Movement
```gdscript
extends CharacterBody3D

@export var speed: float = 5.0
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
	# Configure agent
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5

func set_target(target_pos: Vector3):
	nav_agent.target_position = target_pos

func _physics_process(delta):
	if nav_agent.is_navigation_finished():
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()
```

### Following the Player
```gdscript
@export var chase_speed: float = 4.0
var player: Node3D

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player:
		nav_agent.target_position = player.global_position
	
	if not nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		velocity = direction * chase_speed
		
		# Face movement direction
		if direction.length() > 0.1:
			look_at(global_position + direction)
		
		move_and_slide()
```

### NavigationAgent3D Key Properties
| Property | Default | Description |
|----------|---------|-------------|
| `path_desired_distance` | 1.0 | How close to waypoints before moving to next |
| `target_desired_distance` | 1.0 | How close to target to consider "arrived" |
| `avoidance_enabled` | false | Enable dynamic obstacle avoidance |
| `max_speed` | 10.0 | For avoidance calculations |

### Signals
```gdscript
nav_agent.navigation_finished.connect(_on_navigation_finished)
nav_agent.velocity_computed.connect(_on_velocity_computed)  # For avoidance
nav_agent.path_changed.connect(_on_path_changed)
```

---

## Custom Shaders

### Shader Types
| Type | Use |
|------|-----|
| `spatial` | 3D objects |
| `canvas_item` | 2D objects, UI |
| `particles` | Particle systems |
| `sky` | Sky rendering |
| `fog` | Volumetric fog |

### Basic Spatial Shader
```glsl
// res://shaders/basic.gdshader
shader_type spatial;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	ALBEDO = albedo_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
```

### Shader with Texture
```glsl
shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform vec4 tint_color : source_color = vec4(1.0);

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);
	ALBEDO = tex_color.rgb * tint_color.rgb;
	ALPHA = tex_color.a * tint_color.a;
}
```

### Vertex Displacement
```glsl
shader_type spatial;

uniform float wave_height = 0.5;
uniform float wave_speed = 2.0;
uniform float wave_frequency = 3.0;

void vertex() {
	float wave = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_height;
	VERTEX.y += wave;
}
```

### Applying Shaders
```gdscript
# Method 1: In editor - assign .gdshader to ShaderMaterial

# Method 2: Via code
var shader = load("res://shaders/my_shader.gdshader")
var material = ShaderMaterial.new()
material.shader = shader
material.set_shader_parameter("albedo_color", Color.RED)
$MeshInstance3D.material_override = material
```

### Common Shader Uniforms
```glsl
// Colors
uniform vec4 color : source_color = vec4(1.0);

// Textures
uniform sampler2D my_texture : source_color;
uniform sampler2D normal_map : hint_normal;

// Numbers with ranges
uniform float speed : hint_range(0.0, 10.0) = 1.0;

// Built-in variables (available in fragment)
// UV - texture coordinates
// TIME - elapsed time
// ALBEDO - output color
// NORMAL - surface normal
// METALLIC, ROUGHNESS, EMISSION - PBR properties
```

### Canvas Item Shader (2D)
```glsl
shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = mix(tex_color, flash_color, flash_intensity);
}
```

### ⚠️ CRITICAL: material_override vs surface_material_override

When applying shaders via MCP tools or code, **there are TWO places materials can be assigned**:

| Property | How to Access | When Used |
|----------|---------------|-----------|
| `material_override` | `mesh_instance.material_override` | Overrides ALL surfaces |
| `surface_material_override/N` | `mesh_instance.get_surface_override_material(N)` | Per-surface override |

**The MCP `godot_apply_shader` tool uses `surface_material_override/0`**, not `material_override`.

#### ❌ WRONG - Will return null:
```gdscript
var mat = mesh_instance.material_override  # NULL!
mat.set_shader_parameter("color", Color.RED)  # ERROR!
```

#### ✅ CORRECT - Use surface override:
```gdscript
var mat = mesh_instance.get_surface_override_material(0)  # Gets the actual material
mat.set_shader_parameter("color", Color.RED)  # Works!
```

#### How to Check Which is Used:
Use `godot_get_node_details` and look for:
- `material_override`: `<Object#null>` means NOT used
- `surface_material_override/0`: `<ShaderMaterial#...>` means THIS is the material

#### Setting Shader Parameters After Applying Shader:
```gdscript
# After godot_apply_shader(), always use:
var root = EditorInterface.get_edited_scene_root()
var mesh = root.get_node("MyNode/Mesh")
var mat = mesh.get_surface_override_material(0)  # NOT material_override!

# Now you can set parameters
mat.set_shader_parameter("texture_grass", my_texture)
mat.set_shader_parameter("height_threshold", 0.5)
```

---

## Quick Start Templates

### FPS Game Scene Template
```
Main (Node3D)
├── WorldEnvironment
│   └── Environment (ProceduralSkyMaterial)
├── DirectionalLight3D (shadows enabled)
├── NavigationRegion3D
│   └── NavigationMesh
├── Floor (StaticBody3D)
│   ├── MeshInstance3D (BoxMesh 50x1x50)
│   └── CollisionShape3D (BoxShape3D 50x1x50)
├── Player (CharacterBody3D) [player.gd]
│   ├── Camera3D (position: 0, 1.6, 0)
│   ├── CollisionShape3D (CapsuleShape3D h:1.8, r:0.4)
│   └── RayCast3D (for interactions)
├── Enemies (Node3D)
│   └── Enemy (CharacterBody3D) [enemy.gd]
│       ├── MeshInstance3D
│       ├── CollisionShape3D
│       └── NavigationAgent3D
├── Pickups (Node3D)
│   └── Coin (Area3D) [coin.gd]
│       ├── MeshInstance3D
│       └── CollisionShape3D
└── UI (CanvasLayer)
	└── HUD (Control)
		├── HealthBar (ProgressBar)
		├── AmmoLabel (Label)
		└── Crosshair (TextureRect)
```

### Minimal Player Script
```gdscript
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.003

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var camera = $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera.rotate_x(-event.relative.y * MOUSE_SENS)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.x = direction.x * SPEED if direction else move_toward(velocity.x, 0, SPEED)
	velocity.z = direction.z * SPEED if direction else move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
```

### Minimal Enemy AI Script
```gdscript
extends CharacterBody3D

@export var speed: float = 3.0
@export var chase_range: float = 15.0

@onready var nav_agent = $NavigationAgent3D
var player: Node3D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	nav_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta):
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	if distance < chase_range:
		nav_agent.target_position = player.global_position
		
		if not nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var direction = (next_pos - global_position).normalized()
			velocity = direction * speed
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	else:
		velocity = Vector3.ZERO
	
	move_and_slide()

func _on_velocity_computed(safe_velocity):
	velocity = safe_velocity
```

### Minimal Pickup Script
```gdscript
extends Area3D

@export var value: int = 10
@export var spin_speed: float = 2.0

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta):
	rotate_y(spin_speed * delta)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("add_score"):
			body.add_score(value)
		queue_free()
```

### Minimal Game Manager (Autoload)
```gdscript
# game_manager.gd - Add as Autoload named "GameManager"
extends Node

signal score_changed(new_score)
signal health_changed(new_health)
signal game_over

var score: int = 0
var health: int = 100
var max_health: int = 100

func add_score(amount: int):
	score += amount
	score_changed.emit(score)

func take_damage(amount: int):
	health = max(0, health - amount)
	health_changed.emit(health)
	if health <= 0:
		game_over.emit()

func heal(amount: int):
	health = min(max_health, health + amount)
	health_changed.emit(health)

func reset():
	score = 0
	health = max_health
	score_changed.emit(score)
	health_changed.emit(health)
```

---

## RigidBody3D (Physics Objects)

### When to Use RigidBody3D
| Object Type | Use RigidBody3D? |
|-------------|------------------|
| Crates, barrels | ✅ Yes |
| Balls, rolling objects | ✅ Yes |
| Ragdolls | ✅ Yes |
| Debris, particles | ✅ Yes |
| Player character | ❌ Use CharacterBody3D |
| Walls, floors | ❌ Use StaticBody3D |
| Triggers, pickups | ❌ Use Area3D |

### Basic RigidBody3D Setup
```gdscript
extends RigidBody3D

func _ready():
	# Basic properties
	mass = 10.0              # Weight in kg
	gravity_scale = 1.0      # Multiplier for gravity
	
	# Damping (slows down over time)
	linear_damp = 0.1        # Slows linear movement
	angular_damp = 0.1       # Slows rotation
	
	# Freeze modes
	freeze = false           # If true, stops all physics
	# freeze_mode options:
	# FREEZE_MODE_STATIC - Acts like StaticBody3D
	# FREEZE_MODE_KINEMATIC - Acts like AnimatableBody3D
```

### Scene Structure
```
Crate (RigidBody3D)
├── MeshInstance3D (BoxMesh)
└── CollisionShape3D (BoxShape3D)
```

### Applying Forces & Impulses

**Force** = Continuous push (apply every frame)
**Impulse** = Instant push (apply once)

```gdscript
extends RigidBody3D

func _physics_process(delta):
	# Continuous force (like a rocket thruster)
	if Input.is_action_pressed("thrust"):
		apply_central_force(Vector3(0, 100, 0))

func hit_by_explosion(direction: Vector3, power: float):
	# One-time impulse (like an explosion)
	apply_central_impulse(direction * power)

func hit_at_point(position: Vector3, impulse: Vector3):
	# Impulse at specific point (causes spin)
	apply_impulse(impulse, position - global_position)
```

### Force vs Impulse Reference
| Method | Effect | Use Case |
|--------|--------|----------|
| `apply_central_force(force)` | Continuous push | Thrusters, wind |
| `apply_force(force, position)` | Continuous push at point | Off-center thrust |
| `apply_central_impulse(impulse)` | Instant push | Explosions, jumps |
| `apply_impulse(impulse, position)` | Instant push at point | Bullets, impacts |
| `apply_torque(torque)` | Continuous spin | Motors |
| `apply_torque_impulse(impulse)` | Instant spin | Impacts |

### Physics Materials (Bounce & Friction)
```gdscript
# Create bouncy material
var bouncy_mat = PhysicsMaterial.new()
bouncy_mat.bounce = 0.8      # 0 = no bounce, 1 = full bounce
bouncy_mat.friction = 0.3    # 0 = ice, 1 = rubber

# Apply to body
rigid_body.physics_material_override = bouncy_mat
```

### Common Physics Material Presets
| Material | Bounce | Friction | Use |
|----------|--------|----------|-----|
| Rubber Ball | 0.8 | 0.8 | Bouncy balls |
| Metal | 0.3 | 0.4 | Crates, barrels |
| Ice | 0.1 | 0.05 | Sliding objects |
| Wood | 0.2 | 0.6 | Furniture |
| Super Bouncy | 1.0 | 0.1 | Pinball |

### Detecting Collisions
```gdscript
extends RigidBody3D

func _ready():
	# Enable contact monitoring
	contact_monitor = true
	max_contacts_reported = 4
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node):
	print("Hit: ", body.name)
	
	# Check what we hit
	if body is StaticBody3D:
		print("Hit ground/wall")
	elif body is RigidBody3D:
		print("Hit another physics object")

func _on_body_exited(body: Node):
	print("No longer touching: ", body.name)
```

### _integrate_forces (Advanced Control)
For precise physics control, use `_integrate_forces()`:

```gdscript
extends RigidBody3D

func _integrate_forces(state: PhysicsDirectBodyState3D):
	# Get current velocity
	var vel = state.linear_velocity
	
	# Clamp max speed
	if vel.length() > 20.0:
		state.linear_velocity = vel.normalized() * 20.0
	
	# Custom gravity
	state.add_constant_central_force(Vector3(0, -20, 0))
	
	# Check contacts
	for i in state.get_contact_count():
		var contact_pos = state.get_contact_local_position(i)
		var contact_normal = state.get_contact_local_normal(i)
```

### Freeze Modes
```gdscript
# Completely stop physics (still visible)
rigid_body.freeze = true
rigid_body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

# Make kinematic (can be moved by animation)
rigid_body.freeze = true
rigid_body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

# Resume physics
rigid_body.freeze = false
```

### Sleeping & Waking
```gdscript
# Bodies "sleep" when stationary to save performance
rigid_body.sleeping = true   # Force sleep
rigid_body.sleeping = false  # Wake up

# Prevent sleeping (always active)
rigid_body.can_sleep = false

# Check if sleeping
if rigid_body.sleeping:
	print("Body is at rest")
```

### Picking Up Objects
```gdscript
# Player script
var held_object: RigidBody3D = null
@onready var hold_position = $Camera3D/HoldPosition

func pickup(object: RigidBody3D):
	held_object = object
	held_object.freeze = true  # Stop physics while holding

func drop():
	if held_object:
		held_object.freeze = false
		held_object.global_position = hold_position.global_position
		held_object = null

func throw(power: float):
	if held_object:
		held_object.freeze = false
		held_object.global_position = hold_position.global_position
		held_object.apply_central_impulse(-camera.global_transform.basis.z * power)
		held_object = null
```

### Explosive Crate Example
```gdscript
extends RigidBody3D

@export var explosion_force: float = 500.0
@export var explosion_radius: float = 5.0
var health: int = 3

func take_damage():
	health -= 1
	if health <= 0:
		explode()

func explode():
	# Find nearby bodies
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = SphereShape3D.new()
	query.shape.radius = explosion_radius
	query.transform = global_transform
	
	var results = space.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body is RigidBody3D and body != self:
			var direction = (body.global_position - global_position).normalized()
			var distance = global_position.distance_to(body.global_position)
			var falloff = 1.0 - (distance / explosion_radius)
			body.apply_central_impulse(direction * explosion_force * falloff)
	
	# Spawn particles, play sound, etc.
	queue_free()
```

---

## 2D Node Types Reference

### 2D Physics Bodies
| Node Type | Purpose | Use Case |
|-----------|---------|----------|
| `StaticBody2D` | Immovable solid | Floors, walls, platforms |
| `RigidBody2D` | Physics-driven | Crates, balls, ragdolls |
| `CharacterBody2D` | Script-controlled | Player, NPCs, enemies |
| `Area2D` | Detection zone | Triggers, pickups, hitboxes |

### 2D Visual Nodes
| Node Type | Purpose |
|-----------|---------|
| `Sprite2D` | Static image |
| `AnimatedSprite2D` | Sprite sheet animations |
| `TileMapLayer` | Tile-based levels |
| `Camera2D` | 2D viewport camera |
| `CanvasLayer` | UI layer (HUD) |
| `ParallaxBackground` | Scrolling backgrounds |
| `Line2D` | Drawing lines |
| `Polygon2D` | Drawing shapes |

### 2D Collision Shapes
| Shape Type | Use Case |
|------------|----------|
| `RectangleShape2D` | Boxes, platforms |
| `CircleShape2D` | Balls, coins |
| `CapsuleShape2D` | Characters |
| `SegmentShape2D` | Thin lines |
| `ConvexPolygonShape2D` | Complex convex |
| `ConcavePolygonShape2D` | Complex concave |

---

## CharacterBody2D (Platformers)

### Basic Platformer Controller
```gdscript
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
```

### Advanced Platformer (Coyote Time, Jump Buffer)
```gdscript
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const COYOTE_TIME = 0.15      # Time to jump after leaving platform
const JUMP_BUFFER_TIME = 0.1  # Time to buffer jump before landing

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false

func _physics_process(delta):
	# Track coyote time
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
	
	# Track jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta
	
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Jump (with coyote time and buffer)
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	
	# Variable jump height (release to fall faster)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	# Movement
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED if direction else move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	was_on_floor = is_on_floor()
```

### Sprite Flipping
```gdscript
@onready var sprite = $AnimatedSprite2D

func _physics_process(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip sprite based on direction
	if direction > 0:
		sprite.flip_h = false
	elif direction < 0:
		sprite.flip_h = true
```

### Wall Jump
```gdscript
const WALL_JUMP_VELOCITY = Vector2(300, -350)

func _physics_process(delta):
	# ... normal movement code ...
	
	# Wall jump
	if Input.is_action_just_pressed("jump") and is_on_wall() and not is_on_floor():
		var wall_normal = get_wall_normal()
		velocity = Vector2(wall_normal.x * WALL_JUMP_VELOCITY.x, WALL_JUMP_VELOCITY.y)
```

---

## TileMap & TileSet

### TileMap Structure (Godot 4)
In Godot 4, TileMaps use **TileMapLayer** nodes:
```
Level (Node2D)
├── TileMapLayer (terrain/ground)
├── TileMapLayer (decorations)
├── TileMapLayer (foreground)
└── Player
```

### Setting Tiles via Code
```gdscript
@onready var tilemap = $TileMapLayer

func _ready():
	# Set a tile at position (5, 3)
	# Parameters: coords, source_id, atlas_coords, alternative_tile
	tilemap.set_cell(Vector2i(5, 3), 0, Vector2i(0, 0))
	
	# Remove a tile
	tilemap.erase_cell(Vector2i(5, 3))
	
	# Get tile at position
	var source_id = tilemap.get_cell_source_id(Vector2i(5, 3))
	var atlas_coords = tilemap.get_cell_atlas_coords(Vector2i(5, 3))

func world_to_tile(world_pos: Vector2) -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(world_pos))

func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(tile_pos))
```

### Detecting Tile Collisions
```gdscript
func get_tile_at_player():
	var tile_pos = tilemap.local_to_map(tilemap.to_local(player.global_position))
	var tile_data = tilemap.get_cell_tile_data(tile_pos)
	
	if tile_data:
		# Check custom data layers set in TileSet
		var is_hazard = tile_data.get_custom_data("is_hazard")
		var damage = tile_data.get_custom_data("damage")
```

### TileSet Custom Data
In the TileSet editor, you can add custom data layers:
1. Select TileSet resource
2. Go to "Custom Data Layers" tab
3. Add layers like "is_hazard" (bool), "damage" (int)
4. Paint values onto individual tiles

---

## Camera2D

### Basic Camera Setup
```gdscript
# As child of Player:
# Player (CharacterBody2D)
# └── Camera2D

# Camera2D properties in editor or code:
@onready var camera = $Camera2D

func _ready():
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
```

### Camera Limits (Don't Go Past Level Bounds)
```gdscript
func _ready():
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 1920  # Level width
    camera.limit_bottom = 1080  # Level height
    camera.limit_smoothed = true
```

### Camera Shake
```gdscript
extends Camera2D

var shake_amount: float = 0.0
var shake_decay: float = 5.0

func _process(delta):
    if shake_amount > 0:
        offset = Vector2(
            randf_range(-shake_amount, shake_amount),
            randf_range(-shake_amount, shake_amount)
        )
        shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
    else:
        offset = Vector2.ZERO

func shake(amount: float):
    shake_amount = amount
```

### Camera Zoom
```gdscript
func zoom_in():
    var tween = create_tween()
    tween.tween_property(camera, "zoom", Vector2(2, 2), 0.3)

func zoom_out():
    var tween = create_tween()
    tween.tween_property(camera, "zoom", Vector2(1, 1), 0.3)
```

---

## AnimatedSprite2D

### Setup
```
Player (CharacterBody2D)
├── AnimatedSprite2D
│   └── SpriteFrames (resource with animations)
└── CollisionShape2D
```

### Playing Animations
```gdscript
@onready var anim = $AnimatedSprite2D

func _physics_process(delta):
    # Play based on state
    if not is_on_floor():
        anim.play("jump")
    elif velocity.x != 0:
        anim.play("run")
    else:
        anim.play("idle")
    
    # Flip based on direction
    if velocity.x > 0:
        anim.flip_h = false
    elif velocity.x < 0:
        anim.flip_h = true

func attack():
    anim.play("attack")
    await anim.animation_finished
    # Attack animation done, resume normal
```

### Creating SpriteFrames via Code
```gdscript
func create_animation():
    var frames = SpriteFrames.new()
    
    # Add animation
    frames.add_animation("walk")
    frames.set_animation_speed("walk", 10)  # FPS
    frames.set_animation_loop("walk", true)
    
    # Add frames (from sprite sheet)
    var texture = load("res://player_sheet.png")
    for i in range(4):
        var atlas = AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = Rect2(i * 32, 0, 32, 32)
        frames.add_frame("walk", atlas)
    
    $AnimatedSprite2D.sprite_frames = frames
```

---

## Area2D (2D Triggers & Pickups)

### Basic Pickup
```gdscript
extends Area2D

@export var value: int = 10

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.name == "Player" or body.is_in_group("player"):
        if body.has_method("add_coins"):
            body.add_coins(value)
        queue_free()
```

### Damage Zone
```gdscript
extends Area2D

@export var damage: int = 10
@export var knockback_force: float = 200.0

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.has_method("take_damage"):
        var knockback_dir = (body.global_position - global_position).normalized()
        body.take_damage(damage, knockback_dir * knockback_force)
```

### Kill Zone (Falling Off Map)
```gdscript
extends Area2D

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.name == "Player":
        # Respawn or game over
        body.die()
```

### Ladder/Climb Zone
```gdscript
# Player script
var in_ladder: bool = false
var ladder_top: float = 0.0

func _on_ladder_area_entered(area):
    in_ladder = true
    ladder_top = area.global_position.y - area.get_node("CollisionShape2D").shape.size.y / 2

func _on_ladder_area_exited(area):
    in_ladder = false

func _physics_process(delta):
    if in_ladder:
        # Disable gravity, allow up/down movement
        var climb_dir = Input.get_axis("move_up", "move_down")
        velocity.y = climb_dir * CLIMB_SPEED
        velocity.x = 0
    else:
        # Normal movement...
```

---

## RigidBody2D (Physics Puzzles)

### Basic Setup
```gdscript
extends RigidBody2D

func _ready():
    mass = 1.0
    gravity_scale = 1.0
    
    # Physics material
    var mat = PhysicsMaterial.new()
    mat.bounce = 0.5
    mat.friction = 0.8
    physics_material_override = mat
```

### Push/Pull Objects
```gdscript
# Player can push RigidBody2D objects automatically
# Just ensure collision layers are set correctly

# For explicit control:
func push_object(object: RigidBody2D, direction: Vector2, force: float):
    object.apply_central_impulse(direction * force)
```

### Breakable Object
```gdscript
extends RigidBody2D

@export var break_velocity: float = 300.0

func _ready():
    body_entered.connect(_on_body_entered)
    contact_monitor = true
    max_contacts_reported = 1

func _on_body_entered(body):
    if linear_velocity.length() > break_velocity:
        # Spawn break particles
        # Play sound
        queue_free()
```

### Seesaw/Balance
```gdscript
extends RigidBody2D

func _ready():
    # Pin to a point (requires PinJoint2D or code)
    lock_rotation = false
    
    # Or use a PinJoint2D node pointing to a StaticBody2D anchor
```

---

## 2D Mouse Input & Point-and-Click

### Getting Mouse Position
```gdscript
func _process(delta):
    # Screen position
    var screen_pos = get_viewport().get_mouse_position()
    
    # World position (accounting for camera)
    var world_pos = get_global_mouse_position()
    
    # Local position relative to this node
    var local_pos = get_local_mouse_position()
```

### Click Detection
```gdscript
func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            var click_pos = get_global_mouse_position()
            move_to(click_pos)
        elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            interact_at(get_global_mouse_position())
```

### Point-and-Click Movement
```gdscript
extends CharacterBody2D

var target_position: Vector2
var moving: bool = false
const SPEED = 200.0
const ARRIVAL_DISTANCE = 5.0

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            target_position = get_global_mouse_position()
            moving = true

func _physics_process(delta):
    if moving:
        var direction = (target_position - global_position).normalized()
        var distance = global_position.distance_to(target_position)
        
        if distance > ARRIVAL_DISTANCE:
            velocity = direction * SPEED
            
            # Face movement direction
            if direction.x > 0:
                $Sprite2D.flip_h = false
            else:
                $Sprite2D.flip_h = true
        else:
            velocity = Vector2.ZERO
            moving = false
        
        move_and_slide()
```

### Clickable Objects (Point-and-Click Adventure)
```gdscript
extends Area2D

signal clicked

@export var hover_cursor: Texture2D
@export var interaction_name: String = "Look at"

func _ready():
    input_event.connect(_on_input_event)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func _on_input_event(viewport, event, shape_idx):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            clicked.emit()

func _on_mouse_entered():
    Input.set_custom_mouse_cursor(hover_cursor)

func _on_mouse_exited():
    Input.set_custom_mouse_cursor(null)
```

### Cursor Management
```gdscript
# Autoload: CursorManager.gd
extends Node

var cursor_default = preload("res://cursors/default.png")
var cursor_interact = preload("res://cursors/interact.png")
var cursor_talk = preload("res://cursors/talk.png")

func set_cursor(type: String):
    match type:
        "default":
            Input.set_custom_mouse_cursor(cursor_default)
        "interact":
            Input.set_custom_mouse_cursor(cursor_interact)
        "talk":
            Input.set_custom_mouse_cursor(cursor_talk)
```

---

## 2D Raycasting

### RayCast2D Node
```gdscript
@onready var raycast = $RayCast2D

func _physics_process(delta):
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        var point = raycast.get_collision_point()
        var normal = raycast.get_collision_normal()
```

### Code-Based Raycast
```gdscript
func raycast_from_mouse():
    var space = get_world_2d().direct_space_state
    var mouse_pos = get_global_mouse_position()
    
    var query = PhysicsRayQueryParameters2D.create(
        global_position,  # From
        mouse_pos         # To
    )
    query.exclude = [self]
    query.collision_mask = 0b0001  # Layer 1 only
    
    var result = space.intersect_ray(query)
    if result:
        print("Hit: ", result.collider.name)
        print("At: ", result.position)
```

### Ground Check (Platformer)
```gdscript
# Add RayCast2D pointing down as child of player
@onready var ground_check = $GroundCheck

func is_grounded() -> bool:
    return ground_check.is_colliding()

# Or check slightly ahead for edge detection
@onready var edge_check_left = $EdgeCheckLeft
@onready var edge_check_right = $EdgeCheckRight

func near_edge() -> bool:
    var moving_right = velocity.x > 0
    if moving_right:
        return not edge_check_right.is_colliding()
    else:
        return not edge_check_left.is_colliding()
```

---

## 2D Platformer Template

### Complete Scene Structure
```
Level (Node2D)
├── TileMapLayer (terrain)
├── TileMapLayer (background)
├── Player (CharacterBody2D)
│   ├── Sprite2D or AnimatedSprite2D
│   ├── CollisionShape2D
│   ├── Camera2D
│   └── RayCast2D (ground check)
├── Enemies (Node2D)
│   └── Enemy (CharacterBody2D)
├── Pickups (Node2D)
│   └── Coin (Area2D)
├── Hazards (Node2D)
│   └── Spikes (Area2D)
└── UI (CanvasLayer)
    └── HUD (Control)
```

### Complete Player Script
```gdscript
extends CharacterBody2D

# Movement
const SPEED = 300.0
const ACCELERATION = 2000.0
const FRICTION = 1500.0
const JUMP_VELOCITY = -450.0
const COYOTE_TIME = 0.12
const JUMP_BUFFER = 0.1

# State
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@onready var sprite = $AnimatedSprite2D
@onready var coyote = $CoyoteTimer
@onready var jump_buffer = $JumpBufferTimer

func _physics_process(delta):
    apply_gravity(delta)
    handle_jump()
    handle_movement(delta)
    update_animation()
    move_and_slide()

func apply_gravity(delta):
    if not is_on_floor():
        velocity.y += gravity * delta
        coyote_timer -= delta
    else:
        coyote_timer = COYOTE_TIME

func handle_jump():
    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer = JUMP_BUFFER
    else:
        jump_buffer_timer -= get_physics_process_delta_time()
    
    if jump_buffer_timer > 0 and coyote_timer > 0:
        velocity.y = JUMP_VELOCITY
        coyote_timer = 0
        jump_buffer_timer = 0
    
    # Variable jump height
    if Input.is_action_just_released("jump") and velocity.y < 0:
        velocity.y *= 0.5

func handle_movement(delta):
    var direction = Input.get_axis("move_left", "move_right")
    
    if direction:
        velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func update_animation():
    if velocity.x > 0:
        sprite.flip_h = false
    elif velocity.x < 0:
        sprite.flip_h = true
    
    if not is_on_floor():
        sprite.play("jump")
    elif abs(velocity.x) > 10:
        sprite.play("run")
    else:
        sprite.play("idle")

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO):
    # Handle damage
    velocity = knockback
```

---

## Puzzle Game Patterns

### Drag and Drop
```gdscript
extends Sprite2D

var dragging: bool = false
var drag_offset: Vector2

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed and get_rect().has_point(to_local(event.position)):
                dragging = true
                drag_offset = global_position - get_global_mouse_position()
            else:
                dragging = false
                check_drop_zone()
    
    elif event is InputEventMouseMotion and dragging:
        global_position = get_global_mouse_position() + drag_offset

func check_drop_zone():
    # Check if dropped in valid zone
    var zones = get_tree().get_nodes_in_group("drop_zones")
    for zone in zones:
        if zone.get_rect().has_point(global_position):
            snap_to_zone(zone)
            return

func snap_to_zone(zone: Node2D):
    global_position = zone.global_position
    # Emit signal or call method
```

### Grid-Based Movement (Puzzle)
```gdscript
extends Node2D

const TILE_SIZE = 64
var grid_position: Vector2i = Vector2i.ZERO
var is_moving: bool = false

func _input(event):
    if is_moving:
        return
    
    if Input.is_action_just_pressed("move_up"):
        try_move(Vector2i(0, -1))
    elif Input.is_action_just_pressed("move_down"):
        try_move(Vector2i(0, 1))
    elif Input.is_action_just_pressed("move_left"):
        try_move(Vector2i(-1, 0))
    elif Input.is_action_just_pressed("move_right"):
        try_move(Vector2i(1, 0))

func try_move(direction: Vector2i):
    var new_pos = grid_position + direction
    if is_valid_position(new_pos):
        grid_position = new_pos
        move_to_grid_position()

func is_valid_position(pos: Vector2i) -> bool:
    # Check bounds, obstacles, etc.
    return true

func move_to_grid_position():
    is_moving = true
    var target = Vector2(grid_position) * TILE_SIZE
    var tween = create_tween()
    tween.tween_property(self, "position", target, 0.15)
    tween.tween_callback(func(): is_moving = false)
```

### Match-3 Pattern
```gdscript
var grid: Array[Array] = []
const GRID_WIDTH = 8
const GRID_HEIGHT = 8

func _ready():
    initialize_grid()

func initialize_grid():
    for x in GRID_WIDTH:
        grid.append([])
        for y in GRID_HEIGHT:
            grid[x].append(create_random_piece(x, y))

func check_matches() -> Array:
    var matches = []
    
    # Check horizontal
    for y in GRID_HEIGHT:
        var count = 1
        var current_type = -1
        for x in GRID_WIDTH:
            if grid[x][y].type == current_type:
                count += 1
            else:
                if count >= 3:
                    for i in range(count):
                        matches.append(Vector2i(x - i - 1, y))
                count = 1
                current_type = grid[x][y].type
    
    # Check vertical (similar logic)
    # ...
    
    return matches
```

---

## 2D Navigation (Point-and-Click)

### Setup
```
Level (Node2D)
├── NavigationRegion2D
│   └── NavigationPolygon (draw walkable area)
├── Player (CharacterBody2D)
│   └── NavigationAgent2D
└── Obstacles
```

### Agent Movement
```gdscript
extends CharacterBody2D

@onready var nav_agent = $NavigationAgent2D
const SPEED = 200.0

func _ready():
    nav_agent.path_desired_distance = 4.0
    nav_agent.target_desired_distance = 4.0

func set_target(target_pos: Vector2):
    nav_agent.target_position = target_pos

func _physics_process(delta):
    if nav_agent.is_navigation_finished():
        return
    
    var next_pos = nav_agent.get_next_path_position()
    var direction = (next_pos - global_position).normalized()
    
    velocity = direction * SPEED
    move_and_slide()
    
    # Face movement direction
    if velocity.x > 0:
        $Sprite2D.flip_h = false
    elif velocity.x < 0:
        $Sprite2D.flip_h = true
```

---

## ParallaxBackground (Scrolling)

### Setup
```
Level (Node2D)
├── ParallaxBackground
│   ├── ParallaxLayer (far - slow)
│   │   └── Sprite2D
│   ├── ParallaxLayer (mid)
│   │   └── Sprite2D
│   └── ParallaxLayer (near - fast)
│       └── Sprite2D
├── TileMapLayer
└── Player
    └── Camera2D
```

### Configuration
```gdscript
# ParallaxLayer properties:
# motion_scale = Vector2(0.5, 0.5)  # 50% camera speed (far away)
# motion_scale = Vector2(1.0, 1.0)  # Same speed as camera
# motion_scale = Vector2(1.5, 1.5)  # Faster than camera (foreground)

# For infinite scrolling:
# motion_mirroring = Vector2(1920, 0)  # Repeat after 1920 pixels
```

---

## Terrain & Landscapes (3D)

### HeightMapShape3D (Physics)
For collisions on terrain, use `HeightMapShape3D`.
It requires an array of floats (heights) and width/depth.

```gdscript
var shape = HeightMapShape3D.new()
shape.map_width = 32
shape.map_depth = 32
var data = PackedFloat32Array()
# Fill data...
shape.map_data = data
collision_shape.shape = shape
```

### Visual Terrain (MeshInstance3D)
Godot 4 doesn't have a built-in "Terrain" node.
Use a `MeshInstance3D` with a `PlaneMesh` and a `ShaderMaterial`, or generate an `ArrayMesh` via code (SurfaceTool).

### Using FastNoiseLite
```gdscript
var noise = FastNoiseLite.new()
noise.seed = randi()
noise.frequency = 0.01

# Get height at position
var height = noise.get_noise_2d(x, z) * height_scale
```

### MCP Tool: Generate Terrain
The MCP tool `generate_terrain_mesh` creates a complete terrain setup:
1. `StaticBody3D` (Physics Body)
2. `MeshInstance3D` (Visuals)
3. `CollisionShape3D` (Collision)

It uses `SurfaceTool` to bake the mesh, ensuring visuals match physics exactly.

### MCP Tool: Create Terrain Material
The MCP tool `create_terrain_material` generates sophisticated terrain shaders:

| Type | Description |
|------|-------------|
| `height_blend` | Blends 4 textures by height (grass → dirt → rock → snow) |
| `slope_blend` | Blends flat vs steep textures (grass on flat, rock on cliffs) |
| `triplanar` | Projects textures from 3 axes to avoid stretching on cliffs |
| `full` | Combines all: height + slope + triplanar projection |

**Usage:**
```
1. Call `create_terrain_material` with type="full"
2. Creates .gdshader file
3. In Godot: Create ShaderMaterial, assign the shader
4. Assign textures to uniforms (texture_grass, texture_rock, etc.)
5. Apply material to terrain MeshInstance3D
```

### Terrain Shader Uniforms (Full Shader)
After creating a terrain material, these uniforms are available:

**Textures (assign in editor):**
- `texture_grass`, `texture_dirt`, `texture_rock`, `texture_snow`, `texture_cliff`
- `normal_grass`, `normal_rock`, `normal_cliff`

**Parameters:**
- `texture_scale` (0.01-1.0): UV tiling scale
- `blend_sharpness` (0.1-10.0): Transition sharpness
- `height_grass/dirt/rock/snow` (0.0-1.0): Height thresholds
- `max_terrain_height`: Maximum terrain Y value
- `slope_threshold` (0.0-1.0): When cliff texture kicks in
- `roughness_base`: PBR roughness

### Manual Terrain Shader Example
```glsl
shader_type spatial;

uniform sampler2D texture_grass : source_color;
uniform sampler2D texture_rock : source_color;
uniform float slope_threshold = 0.5;

void fragment() {
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float slope = 1.0 - abs(world_normal.y);
	
	vec3 grass = texture(texture_grass, UV * 10.0).rgb;
	vec3 rock = texture(texture_rock, UV * 10.0).rgb;
	
	float blend = smoothstep(slope_threshold - 0.1, slope_threshold + 0.1, slope);
	ALBEDO = mix(grass, rock, blend);
}
```

---

## Lighting Presets

### MCP Tool: Lighting Preset
Create complete scene lighting with one call:

```
godot_lighting_preset(preset="sunny")
godot_lighting_preset(preset="sunset", parent_path=".")
```

### Available Presets

| Preset | Description |
|--------|-------------|
| `sunny` | Bright daylight, blue sky, shadows enabled |
| `overcast` | Cloudy day, muted colors, fog enabled |
| `sunset` | Warm orange/red lighting, dramatic sky |
| `night` | Dark blue moonlight, glow enabled |
| `indoor` | Soft ambient, no sky, SSAO enabled |

### What Gets Created
Each preset creates:
1. **DirectionalLight3D** ("Sun") - Main light source
2. **WorldEnvironment** - Sky, ambient light, effects

### Manual Lighting Setup (Code)
```gdscript
# Create sun light
var sun = DirectionalLight3D.new()
sun.rotation_degrees = Vector3(-45, -30, 0)
sun.light_energy = 1.2
sun.shadow_enabled = true
add_child(sun)

# Create environment
var world_env = WorldEnvironment.new()
var env = Environment.new()
env.background_mode = Environment.BG_SKY

var sky = Sky.new()
var sky_mat = ProceduralSkyMaterial.new()
sky_mat.sky_top_color = Color(0.35, 0.55, 0.9)
sky.sky_material = sky_mat
env.sky = sky

world_env.environment = env
add_child(world_env)
```

---

## Primitive Meshes

### MCP Tool: Create Primitive
Create 3D shapes with optional collision:

```
godot_create_primitive(shape="box", size=2.0, color="1.0,0.0,0.0")
godot_create_primitive(shape="sphere", collision=true)
godot_create_primitive(shape="cylinder", name="Pillar", size=3.0)
```

### Available Shapes

| Shape | Description |
|-------|-------------|
| `box` | Cube/rectangular box |
| `sphere` | Sphere |
| `cylinder` | Cylinder |
| `capsule` | Capsule (pill shape) |
| `plane` | Flat plane |
| `prism` | Triangular prism |
| `torus` | Donut/ring shape |

### Parameters
- `shape`: Shape type (see table above)
- `size`: Scale factor (default 1.0)
- `color`: RGB as "r,g,b" (0-1 range)
- `collision`: If true, wraps in StaticBody3D with CollisionShape3D

### Manual Primitive Creation (Code)
```gdscript
# Create sphere with material
var mesh_inst = MeshInstance3D.new()
var sphere = SphereMesh.new()
sphere.radius = 0.5
sphere.height = 1.0
mesh_inst.mesh = sphere

var mat = StandardMaterial3D.new()
mat.albedo_color = Color(1.0, 0.5, 0.0)  # Orange
mesh_inst.material_override = mat

add_child(mesh_inst)
```

---

## UI Templates

### MCP Tool: Create UI Template
Generate complete UI layouts instantly:

```
godot_create_ui_template(template="main_menu")
godot_create_ui_template(template="hud", name="GameHUD")
godot_create_ui_template(template="inventory_grid")
```

### Available Templates

| Template | Description |
|----------|-------------|
| `main_menu` | Title + Play/Options/Quit buttons |
| `pause_menu` | Semi-transparent overlay, Resume/Quit |
| `hud` | Health bar, score, ammo, crosshair |
| `dialogue_box` | RPG-style dialogue with speaker name |
| `inventory_grid` | 5x4 grid of item slots |

### Template Structure

**main_menu:**
```
CanvasLayer (MainMenu)
└── PanelContainer
	└── CenterContainer
		└── VBoxContainer
			├── Label (Title)
			├── Button (PlayButton)
			├── Button (OptionsButton)
			└── Button (QuitButton)
```

**hud:**
```
CanvasLayer (HUD)
└── Control (Container)
	├── HBoxContainer (HealthContainer)
	│   ├── Label (HealthIcon)
	│   └── ProgressBar (HealthBar)
	├── Label (ScoreLabel)
	├── Label (AmmoLabel)
	└── Label (Crosshair)
```

**inventory_grid:**
```
CanvasLayer (Inventory)
├── ColorRect (Background)
└── CenterContainer
	└── PanelContainer
		└── VBoxContainer
			├── Label (Title)
			├── GridContainer (ItemGrid) [20 slots]
			└── Button (CloseButton)
```

### Connecting UI Signals
```gdscript
# After creating template, connect buttons
var play_btn = get_node("MainMenu/Panel/Center/VBox/PlayButton")
play_btn.pressed.connect(_on_play_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://game.tscn")
```

---

## Save/Load System

### MCP Tools: Save & Load Game Data
Simple JSON-based save system:

```
# Save data
godot_save_game_data(filename="save1.json", data='{"level": 5, "score": 1000, "player_name": "Hero"}')

# Load data
godot_load_game_data(filename="save1.json")
```

### Save Location
Files are saved to `user://` directory:
- **Windows**: `%APPDATA%\Godot\app_userdata\[project_name]\`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/[project_name]/`
- **Linux**: `~/.local/share/godot/app_userdata/[project_name]/`

### Manual Save/Load (Code)
```gdscript
# Save game
func save_game():
	var save_data = {
		"player": {
			"position": {"x": player.position.x, "y": player.position.y, "z": player.position.z},
			"health": player.health,
			"inventory": player.inventory
		},
		"level": current_level,
		"score": score,
		"playtime": playtime
	}
	
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

# Load game
func load_game():
	if not FileAccess.file_exists("user://save.json"):
		return false
	
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	
	var data = json.data
	player.position = Vector3(data.player.position.x, data.player.position.y, data.player.position.z)
	player.health = data.player.health
	current_level = data.level
	score = data.score
	return true
```

### Best Practices
1. **Always check if file exists** before loading
2. **Use meaningful filenames**: `save_slot1.json`, `settings.json`
3. **Include version number** in save data for migration
4. **Don't save sensitive data** - saves are plain text JSON

---

*Last Updated: December 2024*
*Engine: Godot 4.5.1*
