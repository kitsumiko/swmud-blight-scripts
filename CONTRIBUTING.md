# Contributing to SWMud Blight Scripts

Thank you for your interest in contributing! This document provides guidelines and information for contributing to the project.

## Table of Contents

- [Codebase Structure](#codebase-structure)
- [Getting Started](#getting-started)
- [Module Organization](#module-organization)
- [Coding Standards](#coding-standards)
- [Adding New Features](#adding-new-features)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)

## Codebase Structure

The codebase is organized into focused modules with clear responsibilities:

```
swmud/
├── core/              # Core functionality (config, state, init)
├── utils/             # Pure utility functions
├── ui/                # User interface components
├── commands/          # Command handling (aliases, nicknames)
├── parsers/           # Input parsing (prompt, score, delays, etc.)
├── services/          # Business logic (status, skills, DPR, etc.)
├── models/            # Data models (combat, character, etc.)
└── data/              # Data files (experience tables, etc.)
```

### Module Responsibilities

- **core/**: Configuration, state management, initialization
- **utils/**: Pure utility functions with no side effects
- **ui/**: Rendering and display logic
- **commands/**: User command handling (aliases, nicknames)
- **parsers/**: Parse MUD output and commands
- **services/**: Business logic and processing
- **models/**: Data structures and state models
- **data/**: Static data files

## Getting Started

### Prerequisites

- Docker Desktop installed
- Git installed
- Basic knowledge of Lua

### Development Setup

1. Clone the repository:
```bash
git clone https://github.com/mikotaichou/swmud-blight-scripts.git
cd swmud-blight-scripts
```

2. Run the development environment:
```bash
docker run -it \
    -v swmud:/home/miko/.config/blightmud/ \
    -v .:/home/miko/.config/blightmud \
    docker.io/mikotaichou/swblight:dev
```

3. Test your changes by reloading scripts in-game:
```
/reload_scripts
```

## Module Organization

### Where Should My Code Go?

**Parsers** (`parsers/`):
- Parse MUD output or commands
- Extract data from text
- Return structured data
- Example: `score_parser.lua` parses the `score` command output

**Services** (`services/`):
- Business logic
- Process data
- Update state
- Coordinate between modules
- Example: `dpr_calculator.lua` calculates damage per round

**Models** (`models/`):
- Data structures
- State management for specific domains
- Example: `combat.lua` defines combat-related data structures

**UI** (`ui/`):
- Rendering logic
- Display formatting
- Status line updates
- Example: `status_renderer.lua` renders the status lines

**Utils** (`utils/`):
- Pure functions
- No side effects
- Reusable across modules
- Example: `string_utils.lua` provides string manipulation functions

**Commands** (`commands/`):
- User command handling
- Alias definitions
- Command processing
- Example: `aliases.lua` defines command aliases

### Module Template

When creating a new module, use this template:

```lua
-- Brief description of what this module does

local ModuleName = {}

function ModuleName.some_function()
  -- Implementation
end

-- Export as global for script.load() compatibility
ModuleName = ModuleName

return ModuleName
```

## Coding Standards

### Naming Conventions

- **Modules**: `snake_case.lua` (e.g., `skill_tracker.lua`)
- **Functions**: `snake_case` (e.g., `update_character_status()`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `STATUS_SEP`)
- **Global State**: `UPPER_SNAKE_CASE` (e.g., `PROMPT_INFO`)

### Code Style

1. **Use local variables** when possible
2. **Export explicitly** - Only export what's needed
3. **Add comments** for complex logic
4. **Keep functions focused** - One responsibility per function
5. **Limit file size** - Aim for 50-200 lines per module

### Example

```lua
-- Good: Clear, focused function
local function calculate_dpr(damage, rounds)
  if rounds == 0 then
    return 0
  end
  return ROUND_FLOAT(damage / rounds, 2)
end

-- Bad: Too many responsibilities
local function process_everything()
  -- 100 lines of mixed logic
end
```

### Global State Access

- Access global state through the state module when possible
- Use `PROMPT_INFO`, `CHAR_DATA`, etc. for backward compatibility
- Avoid creating new global variables - add them to `core/state.lua` instead

## Adding New Features

### Step 1: Plan Your Feature

1. Identify which module(s) need changes
2. Determine if you need a new module
3. Check dependencies and load order

### Step 2: Create or Modify Modules

**Adding a new parser:**
1. Create `parsers/your_parser.lua`
2. Export the parser as a global
3. Add to `core/init.lua` in the correct load order

**Adding a new service:**
1. Create `services/your_service.lua`
2. Export functions as globals if needed
3. Add to `core/init.lua` after dependencies

**Adding a new skill:**
1. Add skill definition to `services/skill_definitions.lua`
2. Use `create_skill()` or `create_status_skill()`

### Step 3: Update Load Order

If your module has dependencies, update `core/init.lua`:

```lua
-- Load dependencies first
script.load('~/.config/blightmud/swmud/dependency.lua')

-- Then load your module
script.load('~/.config/blightmud/swmud/your_module.lua')
```

### Step 4: Test

1. Test in the development environment
2. Verify no errors on load
3. Test functionality
4. Check for side effects

## Common Tasks

### Adding a New Skill

Edit `services/skill_definitions.lua`:

```lua
create_skill("skill_name", 
  "^You (success message)",  -- Success regex
  "^You (fail message)",      -- Failure regex
  4,                          -- Success delay (seconds)
  4,                          -- Failure delay (seconds)
  nil,                        -- Check last command (optional)
  nil)                        -- Miss regex (optional)
```

### Adding a New Parser

Create `parsers/your_parser.lua`:

```lua
local YourParser = {}

function YourParser.process(line)
  local matches = regex:match(line:line())
  if matches then
    -- Process matches
  end
end

YourParser = YourParser
return YourParser
```

### Adding a New Trigger

Edit `services/triggers.lua`:

```lua
trigger.add("^Your regex pattern$", {gag = 1}, function (m)
  -- Handle trigger
end)
```

### Modifying Configuration

Edit `core/config.lua`:

```lua
Config.YOUR_SETTING = "value"
```

### Modifying State

Edit `core/state.lua`:

```lua
State.your_module = {
  field1 = "default",
  field2 = 0,
}
```

## Testing

### Manual Testing

1. Load scripts in development environment
2. Test the specific feature
3. Check for errors in output
4. Verify no regressions

### Testing Checklist

- [ ] Scripts load without errors
- [ ] Feature works as expected
- [ ] No side effects on other features
- [ ] Status displays correctly
- [ ] Commands work correctly

### Common Issues

**Module not found:**
- Check file path in `core/init.lua`
- Verify file exists in correct directory

**Function not defined:**
- Check load order in `core/init.lua`
- Ensure module is loaded before use

**State not updating:**
- Verify state is accessed correctly
- Check if state is initialized in `core/state.lua`

## Pull Request Process

### Before Submitting

1. **Test thoroughly** - Ensure your changes work
2. **Check load order** - Verify dependencies are correct
3. **Update documentation** - Add comments for complex logic
4. **Follow naming conventions** - Use consistent naming

### PR Guidelines

1. **Clear title** - Describe what the PR does
2. **Description** - Explain the changes and why
3. **Small changes** - Keep PRs focused and manageable
4. **Test results** - Mention what you tested

### PR Template

```markdown
## Description
Brief description of changes

## Changes
- Added/modified/removed X
- Updated Y

## Testing
- Tested in development environment
- Verified feature works
- No regressions found

## Dependencies
- Requires: module X
- Load order: After module Y
```

## Module Dependencies

Understanding load order is important. Modules are loaded in this order:

1. Core (config, module loader)
2. Utils (table, string, math, time)
3. UI (colors)
4. State
5. Commands
6. Skills
7. Combat models
8. DPR calculator
9. Damage parser
10. Parsers
11. Services
12. UI (status renderer)
13. Prompt service
14. Data loader

**Rule**: Dependencies must be loaded before the modules that use them.

## Code Review Guidelines

### What Reviewers Look For

- **Correctness** - Does it work?
- **Organization** - Is it in the right module?
- **Dependencies** - Are dependencies correct?
- **Style** - Follows coding standards?
- **Documentation** - Is complex logic explained?

### Review Checklist

- [ ] Code is in the correct module
- [ ] Follows naming conventions
- [ ] Dependencies are correct
- [ ] Load order is correct
- [ ] No unnecessary globals
- [ ] Comments for complex logic

## Getting Help

- **Issues**: Open an issue on GitHub
- **Questions**: Ask in PR comments
- **Documentation**: Check existing modules for examples

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing! Your efforts help make this project better for everyone.

