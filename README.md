# 🎮 Godot MCP Bridge

[![Godot 4.5+](https://img.shields.io/badge/Godot-4.5%2B-blue?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-yellow?logo=python&logoColor=white)](https://python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Control the Godot Editor with AI.** A powerful MCP (Model Context Protocol) bridge that lets AI assistants like Claude directly manipulate the Godot game engine.

<p align="center">
  <img src="https://raw.githubusercontent.com/godotengine/godot/master/icon.svg" width="120" alt="Godot Logo">
</p>

---

## ✨ Features

| Category | Capabilities |
|----------|-------------|
| **Scene Management** | Create, open, save, duplicate scenes |
| **Node Operations** | Add, delete, move, rename any node |
| **Properties** | Get/set any node property dynamically |
| **Scripting** | Create, edit, attach GDScript files |
| **Shaders** | Create and apply custom shaders |
| **Animation** | Create animations, control playback |
| **Audio** | Create audio players, control playback |
| **Physics** | Full collision layer/mask control |
| **Screenshots** | Capture editor or running game |

### 🎨 One-Click Presets

| Tool | Presets |
|------|---------|
| **Particles** | `fire`, `smoke`, `sparks`, `explosion`, `magic`, `rain`, `snow`, `dust`, `leaves`, `blood` |
| **Lighting** | `sunny`, `overcast`, `sunset`, `night`, `indoor` |
| **Primitives** | `box`, `sphere`, `cylinder`, `capsule`, `plane`, `prism`, `torus` |
| **UI Templates** | `main_menu`, `pause_menu`, `hud`, `dialogue_box`, `inventory_grid` |
| **Terrain** | Procedural mesh + `height_blend`, `slope_blend`, `triplanar`, `full` shaders |

---

## 🚀 Quick Start

### Prerequisites

- **Godot 4.5+** ([Download](https://godotengine.org/download))
- **Python 3.10+** ([Download](https://python.org/downloads))
- **Cursor IDE** with Claude ([Download](https://cursor.sh))

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/nutshot2000/godot-matrix.git
cd godot-matrix
```

#### 2. Install Python Dependencies

```bash
cd mcp_server
pip install -r requirements.txt
```

#### 3. Open Godot Project

1. Open Godot Engine
2. Click **Import** → Navigate to `godot_project/` → Select `project.godot`
3. Open the project

#### 4. Enable the Plugin

1. In Godot: **Project** → **Project Settings** → **Plugins** tab
2. Find **MCP Bridge** and set to **Enabled** ✅
3. You should see: `MCP Bridge: Plugin initialized and server started`

#### 5. Configure Cursor MCP

Add to your Cursor MCP settings (`~/.cursor/mcp.json` or Settings → MCP):

```json
{
  "mcpServers": {
    "Godot": {
      "command": "python",
      "args": ["C:/path/to/godot-matrix/mcp_server/server.py"]
    }
  }
}
```

> **Windows Users:** Use forward slashes `/` or escaped backslashes `\\` in paths.

#### 6. Test Connection

In Cursor, ask Claude:
```
Check if Godot is connected
```

You should see: `"result": "pong"`

---

## 📖 Usage Examples

### Create a 3D Scene with Lighting

```
Create a new 3D scene with sunny lighting and add a red box with collision
```

### Build a Main Menu

```
Create a main menu UI template with Play, Options, and Quit buttons
```

### Add Particle Effects

```
Add a fire particle effect named "Torch" at position 0,2,0
```

### Generate Terrain

```
Generate a terrain mesh with size 64 and height scale 10, then apply a full terrain material
```

### Save Game Data

```
Save the player's score and level to a JSON file
```

---

## 🛠️ Available Tools (72 Total)

<details>
<summary><b>Scene Management (12)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_status` | Check connection |
| `godot_get_scene_tree` | Get scene hierarchy |
| `godot_save_scene` | Save current scene |
| `godot_new_scene` | Create new scene |
| `godot_open_scene` | Open existing scene |
| `godot_get_scene_file_content` | Get .tscn raw content |
| `godot_delete_scene` | Delete scene file |
| `godot_duplicate_scene` | Copy scene file |
| `godot_rename_scene` | Rename scene file |
| `godot_replace_resource_in_scene` | Swap resources |
| `godot_get_project_info` | Get project settings |
| `godot_get_state` | Debug editor state |

</details>

<details>
<summary><b>Node Operations (12)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_add_node` | Create new node |
| `godot_delete_node` | Remove node |
| `godot_get_node_details` | Inspect properties |
| `godot_set_property` | Modify property |
| `godot_rename_node` | Rename node |
| `godot_duplicate_node` | Clone node |
| `godot_reparent_node` | Move in hierarchy |
| `godot_instantiate_scene` | Instance .tscn |
| `godot_focus_node` | Select in editor |
| `godot_get_selection` | Get selected nodes |
| `godot_find_nodes_by_type` | Search by class |
| `godot_find_nodes_by_group` | Search by group |

</details>

<details>
<summary><b>High-Level Builders (12)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_lighting_preset` | Setup scene lighting |
| `godot_create_primitive` | Create 3D shapes with collision |
| `godot_create_ui_template` | Generate UI layouts |
| `godot_create_particle_effect` | Add particle systems |
| `godot_generate_terrain_mesh` | Procedural terrain |
| `godot_create_terrain_material` | Terrain shaders |
| `godot_spawn_fps_controller` | FPS player with collision |
| `godot_create_health_bar_ui` | Health bar widget |
| `godot_spawn_spinning_pickup` | Complete collectible item |
| `godot_create_trigger_area` | Area3D with collision (triggers) |
| `godot_create_rigidbody` | RigidBody3D with collision+mesh |
| `godot_set_anchor_preset` | UI anchoring |

</details>

<details>
<summary><b>Animation & Audio (6)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_list_animations` | List available anims |
| `godot_animation` | Play/stop/seek |
| `godot_create_simple_animation` | Create value animation |
| `godot_create_audio_player` | Add audio node |
| `godot_audio` | Play/stop audio |
| `godot_set_bus_volume` | Adjust volume |

</details>

<details>
<summary><b>Scripts & Shaders (7)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_create_script` | Create .gd file |
| `godot_read_script` | Read script content |
| `godot_attach_script` | Attach to node |
| `godot_execute_code` | Run GDScript |
| `godot_create_shader` | Create .gdshader |
| `godot_apply_shader` | Apply to mesh |
| `godot_edit_file` | Find/replace in file |

</details>

<details>
<summary><b>Signals & Groups (4)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_signal` | Connect/disconnect |
| `godot_list_signal_connections` | View connections |
| `godot_list_signals` | List node signals |
| `godot_group` | Add/remove/get groups |

</details>

<details>
<summary><b>Game Control & Save/Load (6)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_game` | Play/stop game |
| `godot_save_game_data` | Save JSON to user:// |
| `godot_load_game_data` | Load JSON |
| `godot_setup_input_map` | Configure inputs |
| `godot_set_project_setting` | Modify settings |
| `godot_get_errors` | Get recent errors |

</details>

<details>
<summary><b>📚 Documentation Lookup (2)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_docs` | Look up class documentation (e.g., "MeshInstance3D") |
| `godot_docs_search` | Search docs for a topic (e.g., "collision layers") |

</details>

<details>
<summary><b>Screenshots & Utils (11)</b></summary>

| Tool | Description |
|------|-------------|
| `godot_get_editor_screenshot` | Capture editor |
| `godot_get_game_screenshot` | Capture game |
| `godot_list_resources` | Browse res:// |
| `godot_create_folder` | Create directory |
| `godot_search_files` | Find files |
| `godot_uid` | Convert UID↔path |
| `godot_add_resource` | Add resource to node |
| `godot_set_anchor_values` | Set UI anchors |
| `godot_get_open_scripts` | List open scripts |
| `godot_clear_output` | Clear output panel |
| `godot_list_methods` | List node methods |

</details>

---

## 📚 Documentation

The `godot_project/AI_GUIDELINES.md` file contains **3300+ lines** of comprehensive documentation covering:

- ✅ All Godot 4 node types and their usage
- ✅ Physics system and collision layers
- ✅ GDScript 2.0 syntax (signals, exports, etc.)
- ✅ Common pitfalls and fixes
- ✅ 2D and 3D game templates
- ✅ Navigation and AI pathfinding
- ✅ Save/load systems
- ✅ And much more!

**AI models should read this file** before making changes to ensure Godot 4 compatibility.

---

## ⚠️ Godot 4 vs Godot 3

This project is for **Godot 4.5+** only. Key syntax differences:

```gdscript
# ❌ Godot 3 (WRONG)
var x = cond ? "a" : "b"
connect("signal", self, "method")

# ✅ Godot 4 (CORRECT)  
var x = "a" if cond else "b"
signal_name.connect(method)
```

---

## 🏗️ Project Structure

```
godot-matrix/
├── README.md                 # This file
├── LICENSE                   # MIT License
├── .gitignore               # Git ignore rules
├── .cursorrules             # AI assistant rules
│
├── godot_project/           # Godot 4.5+ project
│   ├── project.godot        # Project config
│   ├── .cursorrules         # Godot-specific AI rules
│   ├── AI_GUIDELINES.md     # Comprehensive AI docs (3300+ lines)
│   └── addons/
│       └── mcp_bridge/      # The MCP plugin
│           ├── plugin.cfg   # Plugin config
│           ├── mcp_bridge.gd # Plugin entry point
│           └── server.gd    # TCP server (2800+ lines)
│
└── mcp_server/              # Python MCP server
    ├── server.py            # FastMCP server (1100+ lines)
    └── requirements.txt     # Python dependencies
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Godot Engine](https://godotengine.org/) - The amazing open-source game engine
- [Anthropic](https://anthropic.com/) - For Claude and the MCP protocol
- [Cursor](https://cursor.sh/) - The AI-first code editor

---

<p align="center">
  Made with ❤️ for the Godot community
</p>
