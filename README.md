# SWMud Blight Scripts

A comprehensive, modular Lua scripting system for [SWMud](http://swmud.org) using the [Blightmud](https://blightmud.github.io/) client.

## Features

- **Advanced Status Display**: Real-time character vitals, experience tracking, and combat statistics
- **Damage Per Round (DPR) Tracking**: Detailed combat analytics with damage calculations
- **Skill Tracking**: Automatic skill delay tracking and status monitoring
- **Smart Aliases**: Flexible alias system with nickname support
- **Prompt Parsing**: Automatic extraction of character information from game prompts
- **Combat Analytics**: Target health estimation, DPR calculations, and combat summaries
- **Experience Tracking**: Guild level tracking and experience requirements

## Project Structure

The codebase is organized into focused, modular components:

```
swmud/
├── core/              # Core functionality (config, state, initialization)
├── utils/             # Utility functions (table, string, math, time)
├── ui/                # User interface (colors, status rendering)
├── commands/          # Command handling (aliases, nicknames)
├── parsers/           # Input parsing (prompt, score, delays, damage, room)
├── services/          # Business logic (status, skills, DPR, data loading)
├── models/            # Data models (combat structures)
└── data/              # Data files (experience tables)
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed information about the codebase structure and how to contribute.

## Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Cygwin](https://www.cygwin.com/) (if running on Windows)

### Using the Published Version

The simplest way to use the scripts:

```bash
docker run -it docker.io/mikotaichou/swblight:latest
```

### With Logs

To save logs to your local machine:

```bash
docker run -it \
    -v <LOCAL LOG PATH>:/home/miko/.local/share/blightmud/logs \
    docker.io/mikotaichou/swblight:latest
```

### With Custom Character Scripts

To use your own character-specific scripts:

```bash
docker run -it \
    -v <LOCAL SCRIPT DIR>:/home/miko/.config/blightmud/private \
    docker.io/mikotaichou/swblight:latest
```

**Note**: Your character script must be named `020_character.lua` in the mounted directory.

## Development Setup

### Clone the Repository

```bash
git clone https://github.com/mikotaichou/swmud-blight-scripts.git
cd swmud-blight-scripts
```

### Run Development Environment

**Without custom character scripts:**
```bash
docker run -it \
    -v swmud:/home/miko/.config/blightmud/ \
    -v .:/home/miko/.config/blightmud \
    docker.io/mikotaichou/swblight:dev
```

**With custom character scripts:**
```bash
docker run -it \
    -v swmud:/home/miko/.config/blightmud/ \
    -v .:/home/miko/.config/blightmud \
    -v <LOCAL SCRIPT DIR>:/home/miko/.config/blightmud/private \
    docker.io/mikotaichou/swblight:dev
```

### Reload Scripts

After making changes, reload scripts in-game:
```
/reload_scripts
```

## How It Works

### Script Loading

1. Blightmud auto-loads `000_connect.lua` on startup (alphabetical order)
2. `000_connect.lua` connects to SWMud and loads `core/init.lua`
3. `core/init.lua` loads all modules in the correct dependency order
4. Modules are loaded via `script.load()` calls

### Module Organization

- **Core**: Configuration, state management, initialization
- **Utils**: Pure utility functions (no side effects)
- **UI**: Rendering and display logic
- **Commands**: User command handling
- **Parsers**: Parse MUD output and commands
- **Services**: Business logic and processing
- **Models**: Data structures
- **Data**: Static data files

### Key Components

- **Status Display**: 4-line status bar showing vitals, experience, skills, combat info
- **Prompt Parser**: Extracts HP, SP, experience, credits, alignment from game prompts
- **DPR Calculator**: Tracks damage per round for you and assists
- **Skill Tracker**: Monitors skill delays and status effects
- **Target Tracking**: Estimates target health and tracks combat statistics

## Usage

### Commands

- `/reload_scripts` - Reload all scripts
- `/reconnect` - Reconnect to SWMud
- `reprompt` - Refresh character information
- `set_move <command>` - Set move command prefix (e.g., `set_move sneak`)

### Aliases

The system includes a flexible alias system. See `commands/aliases.lua` for examples.

### Customization

Create a `private/020_character.lua` file for character-specific customizations. This file is automatically loaded if present.

## Configuration

Main configuration is in `swmud/core/config.lua`:
- MUD connection settings
- File paths
- Constants and settings

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Code structure guidelines
- How to add new features
- Coding standards
- Pull request process

## Module Overview

### Core Modules
- `core/config.lua` - Centralized configuration
- `core/state.lua` - Centralized state management
- `core/init.lua` - Module loading and initialization

### Parsers
- `parsers/prompt_parser.lua` - Parse game prompts
- `parsers/score_parser.lua` - Parse score command
- `parsers/delays_parser.lua` - Parse skill delays
- `parsers/damage_parser.lua` - Parse damage messages
- `parsers/room_parser.lua` - Parse room information

### Services
- `services/prompt_service.lua` - Main prompt processing
- `services/status_updater.lua` - Update status information
- `services/skill_tracker.lua` - Track skill usage
- `services/dpr_calculator.lua` - Calculate damage per round
- `services/data_loader.lua` - Load data files

### UI
- `ui/status_renderer.lua` - Render status lines
- `ui/colors.lua` - Color utilities

## Troubleshooting

### Scripts Not Loading

1. Check that `000_connect.lua` exists in the root directory
2. Verify Docker volume mounts are correct
3. Check for Lua syntax errors in modules

### Module Not Found

1. Verify the file exists in the correct directory
2. Check the path in `core/init.lua`
3. Ensure load order is correct (dependencies first)

### State Not Updating

1. Verify state is accessed correctly
2. Check if state is initialized in `core/state.lua`
3. Ensure modules are loaded in correct order

## License

See [LICENSE](LICENSE) file for details.

## Author

Created by Miko (kishimiko@gmail.com)

## Support

For issues, questions, or contributions, please open an issue or pull request on GitHub.
