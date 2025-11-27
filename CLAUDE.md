# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a customized Prezto (Zsh configuration framework) installation. Prezto enriches the Zsh command line interface with sane defaults, aliases, functions, auto-completion, and prompt themes.

**Base Framework**: [sorin-ionescu/prezto](https://github.com/sorin-ionescu/prezto)

## Key Directories

- **runcoms/** - Zsh runtime configuration files (zshrc, zshenv, zpreztorc, etc.)
- **custom/** - User customizations layered on top of Prezto
  - **custom/bin/** - Custom shell scripts and utilities
  - **custom/functions/** - Zsh autoloadable functions
  - **custom/completions/** - Custom completion scripts
- **modules/** - Prezto modules (mostly from upstream, includes git submodules)

## Configuration Architecture

### Load Order
1. `runcoms/zshenv` - Environment variables (loaded for all shells)
2. `runcoms/zprofile` - Login shell configuration
3. `runcoms/zshrc` - Interactive shell configuration
   - Sources Prezto init (`init.zsh`)
   - Sources `custom/path.zsh` for custom PATH setup
   - Sources `runcoms/alias.zsh` for aliases
   - Loads Powerlevel10k theme config
   - Initializes atuin (shell history sync)
   - Initializes pyenv if present
   - Loads nvm (Node Version Manager)
   - Autoloads custom functions from `custom/functions/`

### Active Prezto Modules (in load order)
See `runcoms/zpreztorc:32-47` for the complete list. Key modules:
- environment, terminal, editor, history, directory
- python (with auto-switch virtualenv enabled)
- git, completion
- history-substring-search
- prompt (using powerlevel10k theme)
- zsh-z (directory jumper)
- autosuggestions

## Custom Functionality

### Custom PATH Setup
Defined in `custom/path.zsh:3-9`:
- `$HOME/Documents/Dropbox/scripts/bash` - Dropbox-synced scripts
- `$HOME/.zprezto/custom/bin` - Custom utility scripts
- `$HOME/.local/bin` - Python pip binaries
- Ruby gems, Flutter SDK, Android SDK paths

### Custom Functions

**logdy** (`custom/functions/logdy`) - Hybrid logging function (console + Loki remote monitoring)

**Overview:**
- Outputs to console with timestamps and colors (immediate user feedback)
- Sends structured JSON logs to Loki (remote monitoring and history)
- Gracefully degrades when Loki is unavailable (scripts continue running)
- Enhanced 2025-11-27 with hybrid logging capabilities

**Usage:**
```bash
logdy [level] [message] [key=value ...]
logdy info "Backup started" destination="/mnt/backup"
logdy error "Connection failed" host="192.168.1.1"
cat file.log | logdy warn -  # Read from stdin
```

**Log Levels:** `info`, `warn`, `error`, `debug`, `trace`

**Console Output Format:**
```
[2025-11-27 00:05:40] [ info] backing up directory destination=local
[2025-11-27 00:05:41] [error] connection failed host=192.168.1.1
```

**Environment Variables:**
- Required:
  - `LOKI_URL` - Loki push endpoint (e.g., `https://monitor.lehel.xyz/loki/api/v1/push`)
  - `LOKI_API_KEY` - Tenant ID for multi-tenant Loki (X-Scope-OrgID header)

- Optional:
  - `LOGDY_SILENT=1` - Suppress console output (Loki-only mode)
  - `LOGDY_NO_COLOR=1` - Disable ANSI colors
  - `LOGDY_LOKI_REQUIRED=1` - Fail script if Loki unavailable (default: continue)
  - `LOGDY_ALSO_TO_FILE=/path` - Also append to log file
  - `LOKI_INSECURE=1` - Allow self-signed certs (default: 1)
  - `LOKI_TIMEOUT=N` - Curl timeout in seconds (default: 5)
  - `LOKI_DRY_RUN=1` - Print payload without sending

**Loki Metadata:**
- Labels: `job=shell, host=<hostname>, user=<username>, script=<scriptname>, level=<level>`
- Log content: JSON with level, host, user, script, msg, and any key=value pairs

**Error Handling:**
- Console output happens FIRST (always succeeds)
- Loki failures show warning but return exit code 0
- Scripts with `set -e` won't break if Loki is unreachable
- Example: `logdy: warning: failed to send to Loki (HTTP 400, curl exit 28) - continuing`

**Use Cases:**
- Backup scripts: Track execution, errors, and completion
- Cron jobs: Silent operation with remote monitoring (`LOGDY_SILENT=1`)
- Interactive scripts: Colored console output for user feedback
- File + remote: Long-running processes (`LOGDY_ALSO_TO_FILE=/var/log/script.log`)

**Scripts Currently Using logdy:**
- `backup_home.sh` - Home directory backups
- `backup_signal.sh` - Signal app backups
- `backup_timeshift.sh` - Timeshift backups (with custom wrappers)

**Migration Status:**
See `LOGGING_MIGRATION_PROGRESS.md` for detailed migration plan for remaining scripts.

### Important Aliases
See `runcoms/alias.zsh`:
- `ll` - ls -al
- `apt-upgrade` / `au` - Full system update including kernel modules
- `update-all` / `ua` - Updates apt, snap, and flatpak packages
- `sys` - systemctl --user shorthand
- `dc` - docker compose
- `aicommits` - AI-powered commit message generator (Node.js script)

### Custom Utility Scripts
Located in `custom/bin/`:
- Backup scripts: `backup_home.sh`, `backup_phone.sh`, `backup_iphone.sh`, etc.
- Network utilities: `is_online.sh`, `is_cloudy_backup_online.sh`, `is_on_metered.sh`
- Git utilities: `find_dirty_git.sh`, `git_remote_json.sh`
- Image processing: `organize_photos.sh`, `crop_images.sh`, `resize.sh`, `multicrop`, `unrotate`
- System utilities: `remove_old_kernels.sh`, `list_swap_usage.sh`
- SSH encryption: `encrypt_ssh.sh`, `decrypt_ssh.sh`

## Environment Variables

**WARNING**: `runcoms/zshenv` contains sensitive API keys and tokens that should NEVER be committed or shared. When modifying this file, ensure no secrets are exposed.

Key environment setup:
- Python: virtualenvwrapper configured with auto-switch
- AI services: GROQ, OpenAI, Gemini, DeepSeek API keys
- Loki: Remote logging endpoint and API key
- Hetzner: Cloud API key

## Updating Prezto

Use the built-in command:
```zsh
zprezto-update
```

Or manually:
```zsh
cd ~/.zprezto
git pull
git submodule sync --recursive
git submodule update --init --recursive
```

## Development Practices

### When Modifying Configuration Files

1. **runcoms/** files are symlinked to `~/.*` - changes affect active shell immediately
2. Test changes in a new shell before committing: `zsh`
3. For Prezto module configuration, edit `runcoms/zpreztorc`
4. For custom aliases, edit `runcoms/alias.zsh`
5. For PATH modifications, edit `custom/path.zsh`

### Adding Custom Utilities

1. Scripts go in `custom/bin/` - automatically in PATH
2. Zsh functions go in `custom/functions/` - use `autoload -Uz function_name` in zshrc
3. Completions go in `custom/completions/` - loaded via fpath

### Working with Submodules

Many Prezto modules are git submodules (external/). When updating:
```zsh
git submodule update --init --recursive
```

## Theme Configuration

Uses **Powerlevel10k** theme with instant prompt enabled.
- Config: `~/.p10k.zsh` (loaded from `custom/p10k.zsh`)
- Reconfigure: run `p10k configure`
- Instant prompt cache: `~/.cache/p10k-instant-prompt-*.zsh`
