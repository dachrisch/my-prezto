# Source default restic environment if available
# This enables running restic commands without manually setting environment variables
if [ -f "$HOME/.config/restic/env" ]; then
    source "$HOME/.config/restic/env"
fi