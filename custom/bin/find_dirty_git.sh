#!/usr/bin/env zsh

# Function to display help
display_help() {
    echo "Usage: $0 [-v] [--untracked] [-h] <directory>"
    echo
    echo "Options:"
    echo "  -v            Display detailed information about changes"
    echo "  --untracked   Include untracked files in the output"
    echo "  -h            Display this help message"
    exit 0
}

# Function to check if a directory is a dirty Git repository with uncommitted or unpushed changes
# Usage: check_git_status <repo_path> <verbose> <include_untracked>
check_git_status() {
    local repo_path="$1"
    local verbose="$2"
    local include_untracked="$3"
    local modified_count=0
    local untracked_count=0
    local unpushed_count=0

    # Check if the directory is a Git repository
    if [[ -d "$repo_path/.git" ]]; then
        # Check for modified files
        modified_count=$(git -C "$repo_path" status --porcelain | grep '^ M' | wc -l)

        # Check for untracked files if the option is set
        if [[ "$include_untracked" == "true" ]]; then
            untracked_count=$(git -C "$repo_path" status --porcelain | grep '^??' | wc -l)
        fi

        # Check for unpushed commits
        unpushed_count=$(git -C "$repo_path" log --branches --not --remotes --simplify-by-decoration --oneline | wc -l)

        if (( modified_count > 0 || untracked_count > 0 || unpushed_count > 0 )); then
            echo -n "$repo_path: "
            if (( modified_count > 0 )); then
                echo -n "\e[33m!${modified_count}\e[0m "  # Yellow for modified files
            fi
            if (( untracked_count > 0 )); then
                echo -n "\e[94m?${untracked_count}\e[0m "  # Bright blue for untracked files
            fi
            if (( unpushed_count > 0 )); then
                echo -n "\e[32m⇡${unpushed_count}\e[0m"  # Green for unpushed commits
            fi
            echo

            # Display detailed status if verbose is true
            if [[ "$verbose" == "true" ]]; then
                git -C "$repo_path" status --short
                echo
            fi
        fi
    fi
}

# Parse command line options
if [[ "$#" -lt 1 ]]; then
    display_help
fi

verbose=false
include_untracked=false
directory=""

# Process options and arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v)
            verbose=true
            shift
            ;;
        --untracked)
            include_untracked=true
            shift
            ;;
        -h)
            display_help
            ;;
        *)
            directory="$1"
            shift
            ;;
    esac
done

# Check if the directory exists
if [[ ! -d "$directory" ]]; then
    echo "Directory $directory does not exist."
    exit 1
fi

# Find all directories and pass each one to the check_git_status function
find "$directory" -type d | while IFS= read -r dir; do
    check_git_status "$dir" "$verbose" "$include_untracked"
done
