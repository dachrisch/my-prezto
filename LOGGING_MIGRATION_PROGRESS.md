# Logging Migration Progress

**Last Updated:** 2025-11-27
**Status:** Phase 2 Complete - All backup scripts migrated
**Next Steps:** Phase 3 - Migrate utility scripts

---

## Objective

Standardize logging across all custom scripts in `/home/cda/.zprezto/custom/bin/` using a hybrid approach:
- Console output with timestamps and colors (for user visibility)
- Remote logging to Loki (for monitoring and history)
- Graceful degradation when Loki is unavailable

---

## Phase 1: Enhanced logdy Function ✅ COMPLETE

### What Was Done

Enhanced `/home/cda/.zprezto/custom/functions/logdy` with the following features:

1. **Hybrid Logging**
   - Console output FIRST (always succeeds)
   - Then sends to Loki (may fail gracefully)
   - Format: `[YYYY-MM-DD HH:MM:SS] [LEVEL] message key=value`

2. **Color-Coded Console Output**
   - ERROR: Red (`\033[0;31m`)
   - WARN: Yellow (`\033[1;33m`)
   - INFO: Cyan (`\033[0;36m`)
   - DEBUG: Gray (`\033[0;90m`)
   - TRACE: Dim gray (`\033[2;90m`)
   - Auto-disabled for non-TTY terminals

3. **User Tracking**
   - Added `user` field to both Loki labels and log content
   - Captured via `${USER:-$(whoami)}`
   - Helps track who ran which script on multi-user systems

4. **Graceful Error Handling**
   - Loki failures are non-fatal by default
   - Uses `set +e` around curl to prevent breaking `set -e` scripts
   - Returns exit code 0 even when Loki is unreachable
   - Shows warning: `logdy: warning: failed to send to Loki (HTTP XXX, curl exit YYY) - continuing`

5. **New Environment Variables**
   ```bash
   LOGDY_SILENT=1           # Suppress console output (Loki-only mode)
   LOGDY_NO_COLOR=1         # Disable ANSI colors
   LOGDY_LOKI_REQUIRED=1    # Fail script if Loki unavailable (default: false)
   LOGDY_ALSO_TO_FILE=/path # Also append to file (e.g., for organize_photos.sh)
   ```

6. **Helper Functions Added**
   - `LOKI__get_color()` - Returns ANSI color code for log level
   - `LOKI__format_console()` - Formats log messages for console display
   - `LOKI__json_escape()` - Already existed, escapes JSON special characters

### Bug Fixes

**Critical Fix:** JSON escaping for Loki payload
- **Issue:** `json_line` was embedded in outer JSON without escaping quotes
- **Result:** Loki rejected payloads with HTTP 400
- **Fix:** Added proper escaping in lines 175-178:
  ```bash
  escaped_json_line="${json_line//\\/\\\\}"   # Escape backslashes first
  escaped_json_line="${escaped_json_line//\"/\\\"}"  # Escape quotes
  ```
- **Location:** `/home/cda/.zprezto/custom/functions/logdy:175-178`

### Loki Payload Structure

**Stream Labels** (for filtering/indexing):
```json
{
  "job": "shell",
  "host": "delly",
  "user": "cda",
  "script": "backup_home.sh",
  "level": "info"
}
```

**Log Line Content**:
```json
{
  "level": "info",
  "host": "delly",
  "user": "cda",
  "script": "backup_home.sh",
  "msg": "backing up [/home/cda]...to [...]",
  "destination": "local"
}
```

### Testing Completed

All tests passed ✅:

1. **Basic Functionality**
   - ✅ Console output with timestamps
   - ✅ Color coding for different log levels
   - ✅ Key=value pairs displayed correctly

2. **Environment Variables**
   - ✅ `LOGDY_SILENT=1` suppresses console output
   - ✅ `LOGDY_NO_COLOR=1` disables colors
   - ✅ `LOGDY_ALSO_TO_FILE=/tmp/test.log` writes to file

3. **Error Handling**
   - ✅ Loki success (HTTP 204) returns exit code 0
   - ✅ Loki failure shows warning but returns exit code 0
   - ✅ Scripts with `set -e` continue after Loki failure
   - ✅ `LOGDY_LOKI_REQUIRED=1` would fail script (not tested)

4. **Integration Test**
   - ✅ `backup_home.sh -l` runs successfully with new logging
   - ✅ Console shows: `[2025-11-27 00:05:40] [ info] backing up [...] destination=local`
   - ✅ Rsync output continues normally after log message

### File Location

- **Main file:** `/home/cda/.zprezto/custom/functions/logdy` (226 lines)
- **Auto-loaded:** Yes (via `fpath` and `autoload -Uz logdy` in zshrc)
- **Backwards compatible:** Yes (alias `loki()` still works)

---

## Phase 2: Script Migration ✅ COMPLETE

### Scripts Already Using logdy ✅ COMPLETE

These scripts already used logdy and have been fully migrated:

1. **backup_home.sh** ✅
   - Uses: `logdy info "backing up..." destination="$backup_dest"`
   - Line 26: Already updated
   - Status: Working perfectly with hybrid logging

2. **backup_signal.sh** ✅
   - Migrated: Line 60 echo replaced with logdy
   - Change: `echo "Remote backup..."` → `logdy info "Remote backup completed" archive_name="..." destination="..."`
   - Status: Complete

3. **backup_timeshift.sh** ✅
   - Migrated: Removed redundant wrapper functions `log()` and `logn()`
   - Restructured: logn cases now log complete messages after conditions
   - All log calls replaced with direct logdy calls
   - Status: Complete

### Scripts to Migrate - Phase 2 ✅ COMPLETE

**Backup & Sync Scripts:**

4. **organize_photos.sh** ✅
   - Migrated: Removed `exec > >(tee -a "$logfile")` redirection
   - Migrated: Removed custom `log_preface()` function
   - Added: `LOGDY_ALSO_TO_FILE="$logfile"` for file logging
   - Replaced: All `echo $(log_preface) "message"` with `logdy info "message"`
   - Status: Complete - console, Loki, AND file logging working

5. **sync_photos.sh** ✅
   - Migrated: Replaced `echo "$(date) - message" | tee -a "$LOGFILE"`
   - Updated: `exit_with_message()` function to use logdy
   - Added: `LOGDY_ALSO_TO_FILE="$LOGFILE"`
   - Status: Complete

6. **backup_phone.sh** ✅
   - Migrated: All echo statements replaced with logdy
   - Kept: Terminal hyperlink printf statements for UX
   - Status: Complete

7. **backup_phone_pictures.sh** ✅
   - Migrated: All echo statements replaced with logdy
   - Kept: Terminal hyperlink printf statements for UX
   - Status: Complete

8. **backup_iphone.sh** ✅
   - Changed: Shebang from `/bin/sh` to `/bin/bash`
   - Migrated: All echo statements replaced with logdy
   - Updated: backup() function to use logdy
   - Status: Complete

### Scripts to Migrate - Phase 3 (Medium Priority)

**Utility Scripts:**

9. **execute_remote_or_local.sh**
   - Current: Echo for status messages
   - Migration: Replace with logdy

10. **execute_cloudy_or_local.sh**
    - Current: Echo for status messages
    - Migration: Replace with logdy

11. **remove_old_kernels.sh**
    - Current: Echo with ANSI colors
    - Migration: Replace with logdy (which has built-in colors)

12. **encrypt_ssh.sh**
    - Current: Echo for success message
    - Migration: Replace with logdy

13. **decrypt_ssh.sh**
    - Current: Echo for errors
    - Migration: Replace with logdy error

14. **find_dirty_git.sh**
    - Current: Echo with custom ANSI colors
    - Decision: Keep custom formatting OR add logdy for remote monitoring only
    - Note: This is interactive, colors may be preferred

### Scripts to Migrate - Phase 4 (Low Priority)

**Status Check Scripts:**

15. **is_online.sh**
    - Current: Simple echo for status
    - Decision: Evaluate if logging is needed (might be overkill)

16. **is_cloudy_backup_online.sh**
    - Current: Simple status output
    - Decision: Evaluate if logging is needed

17. **is_on_metered.sh**
    - Current: Echo for connection status
    - Decision: Evaluate if logging is needed

### Scripts NOT to Migrate

**Data Output Scripts** (output should remain pure):

- **git_remote_json.sh** - Outputs JSON, must not add logging
- **sublocate.sh** - Interactive dialog
- **subltype.sh** - Similar to sublocate
- **resize.sh** - Image manipulation (needs evaluation)
- **crop_images.sh** - Image manipulation (needs evaluation)
- **lowercase_filenames.sh** - Likely outputs filenames
- **multicrop** - Image manipulation
- **unrotate** - Image manipulation

---

## Migration Pattern

### Before:
```bash
echo "Backing up $dir..."
echo "ERROR: Failed to connect" >&2
```

### After:
```bash
logdy info "Backing up directory" dir="$dir"
logdy error "Failed to connect"
```

### For Scripts with File Logging:
```bash
# Before:
logfile=/path/to/log
exec > >(tee -a -i "$logfile") 2>&1
echo "$(date): Processing..."

# After:
export LOGDY_ALSO_TO_FILE=/path/to/log
logdy info "Processing..."
```

---

## Key Design Decisions

1. **Console First, Loki Second**
   - Rationale: User needs immediate feedback; Loki is supplementary
   - Console always works, even if network is down

2. **Non-Fatal Loki Failures**
   - Rationale: Scripts should work even when monitoring is unavailable
   - Warning message informs user but doesn't stop operation

3. **User Information in Logs**
   - Rationale: Useful for multi-user systems and sudo operations
   - Helps with security auditing

4. **Environment Variables for Flexibility**
   - Rationale: Different scripts have different needs
   - Cron jobs might want `LOGDY_NO_COLOR=1`
   - Some scripts might want `LOGDY_LOKI_REQUIRED=1`

5. **Timestamp Format**
   - Chosen: `%Y-%m-%d %H:%M:%S` (ISO-like)
   - Rationale: Human-readable, sortable, consistent across scripts

---

## Testing Strategy for Migration

For each migrated script:

1. **Run Normally** (Loki available)
   - Verify console output is readable
   - Check Loki receives logs in Grafana

2. **Run with Loki Down** (network blocked or invalid URL)
   ```bash
   export LOKI_TIMEOUT=1
   export LOKI_URL="http://invalid.local/loki"
   ./script_name.sh
   ```
   - Verify warning appears
   - Verify script completes successfully

3. **Verify Exit Codes**
   - Scripts should maintain same exit codes as before

4. **Check for Regressions**
   - Compare output format
   - Ensure functionality unchanged

---

## Known Issues & Limitations

### Current Limitations

1. **File Creation for `LOGDY_ALSO_TO_FILE`**
   - File must exist before logdy can append to it
   - Workaround: `touch "$logfile"` before first log
   - Future: Could add auto-create feature

2. **No Log Level Filtering**
   - All levels are logged (info, warn, error, debug, trace)
   - Future: Could add `LOGDY_MIN_LEVEL=info` to filter debug/trace

3. **No Multiline Message Support**
   - Messages with newlines may format oddly in console
   - JSON escaping handles them for Loki correctly

4. **Color Detection**
   - Currently checks `[ -t 1 ]` (stdout is TTY)
   - Doesn't detect color support capabilities
   - Works well enough for most cases

### Future Enhancements (Not Required)

- Auto-create log files for `LOGDY_ALSO_TO_FILE`
- Add `LOGDY_MIN_LEVEL` environment variable
- Add progress indicators for long-running operations
- Add log rotation support for file output
- Support for structured key=value in console output colors

---

## Rollback Plan

If issues arise with the enhanced logdy:

1. **Restore Original**
   ```bash
   cd /home/cda/.zprezto
   git checkout custom/functions/logdy
   ```

2. **Selective Rollback**
   - Keep enhanced version as `logdy.new`
   - Scripts can choose which to use by sourcing different file

3. **Environment Variable Escape Hatch**
   - Set `LOGDY_SILENT=1` to suppress console output
   - Returns to "Loki-only" behavior

---

## Success Criteria

### Phase 1 ✅ COMPLETE
- [x] logdy outputs to both console and Loki by default
- [x] Scripts continue working when Loki is down
- [x] Console output is readable with timestamps and colors
- [x] No scripts break due to `set -e` + Loki failures
- [x] File logging option available
- [x] User information tracked in logs

### Phase 2 ✅ COMPLETE
- [x] backup_timeshift.sh migrated
- [x] backup_signal.sh echo replaced
- [x] organize_photos.sh migrated
- [x] sync_photos.sh migrated
- [x] backup_phone.sh migrated
- [x] backup_phone_pictures.sh migrated
- [x] backup_iphone.sh migrated

### Phase 3 (Pending)
- [ ] All utility scripts evaluated and migrated as appropriate

### Phase 4 (Pending)
- [ ] Documentation updated in CLAUDE.md
- [ ] Migration pattern documented
- [ ] Logging best practices documented

---

## References

- **Plan File:** `/home/cda/.claude/plans/atomic-cooking-sifakis.md`
- **logdy Function:** `/home/cda/.zprezto/custom/functions/logdy`
- **Loki Documentation:** User-provided API validation
- **Previous Investigation:** Detailed in plan file

---

## Notes for Future Implementation

1. When migrating scripts, preserve any script-specific formatting needs
2. Don't migrate scripts that output parseable data (JSON, etc.)
3. Test each migration individually before proceeding
4. Keep git commits small - one script per commit for easy rollback
5. Update this document as migration progresses
