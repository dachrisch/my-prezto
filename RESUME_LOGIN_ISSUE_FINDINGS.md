# Diagnostic Report: Double Login after Resume

## Issue Summary
After resuming from standby, the user is frequently presented with two consecutive login prompts. This is caused by a system-wide hang during the suspend/resume cycle that triggers a cascading failure in session management.

## Root Cause Analysis

### 1. Persistent Process Hang (Kernel Level)
Even after the initial suspected application (Beeper) was removed, the kernel continued to fail to freeze user space processes.
- **Symptom**: `udisksd` (PID 4390) was stuck in state `D` (uninterruptible sleep) for multiple suspend cycles.
- **Trigger**: A stale FUSE request (originally from the Beeper AppImage mount) remained active in the kernel's queue.
- **New Finding**: A graphics driver thread `[kworker/u33:0+i915_flip]` was also observed in state `D` during resume, indicating instability in the Intel graphics subsystem.

### 2. Cascading Service Failure
When the system resumes, the delay caused by the process hang leads to multiple timeouts:
- **Watchdog Timeout**: `rtkit-daemon` detects the lockup ("Recovering from system lockup") and restricts real-time threads.
- **D-Bus Deadlock**: The active GNOME session (`gnome-shell`) loses communication with `gsd-xsettings` and other critical daemons.
- **Assertion Failures**: GNOME Shell (PID 8174) reports multiple `G_IS_SETTINGS` assertion failures, suggesting it has lost access to the settings backend.
- **GDM Intervention**: GDM (the display manager) observes that the current user session is unresponsive. It incorrectly assumes the seat is vacant and spawns a new greeter session on VT1.

### 3. The "Double Login" Sequence
1. **First Login**: You interact with the **new GDM greeter** spawned because your original session was hung.
2. **Second Login**: Once GDM processes your credentials, it switches focus back to your **original session** (VT2). That session has recovered from the hang but remains locked by GNOME Shell's internal lock screen, requiring a second authentication.

## Suspects & Contributing Factors

| Suspect | Status | Evidence |
| :--- | :--- | :--- |
| **Beeper AppImage** | **REMOVED** | Stale mount point `/tmp/.mount_Beeper...` was blocking `udisksd`. |
| **Intel Graphics (i915)** | **ACTIVE** | `i915_flip` worker stuck in uninterruptible sleep during resume. |
| **GNOME Extensions** | **ACTIVE** | `auto-power-profile` and `nightthemeswitcher` are active during settings-related crashes. |
| **HID Sensor Hub** | **HARDWARE** | `hid-sensor-hub` timeout waiting for ISHTP device (light/accelerometer). |

## Actions Taken
- Terminated Beeper and all associated processes.
- Removed Beeper AppImage and configuration data.
- Cleared stale FUSE mounts in `/tmp`.
- Force-restarted `udisksd` to clear the uninterruptible sleep hang.

## Recommendations
1. **Full Reboot**: Essential to clear kernel buffers and reset the graphics driver.
2. **Disable Power Extensions**: If the issue persists, disable `auto-power-profile` and `nightthemeswitcher` to test if they are causing the settings daemon crashes.
3. **Monitor Hardware**: Watch for recurring `hid-sensor-hub` errors, which may require a BIOS/firmware update.
