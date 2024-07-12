#!/usr/bin/env zsh

# Function to check if a directory is a dirty Git repository with uncommitted or unpushed changes
# Usage: check_git_status <repo_path> <verbose>
check_git_status() {
    local repo_path="$1"
    local verbose="$2"
    local uncommitted_count=0
    local unpushed_count=0

    # Check if the directory is a Git repository
    if [[ -d "$repo_path/.git" ]]; then
        # Check for uncommitted changes
        uncommitted_count=$(git -C "$repo_path" status --porcelain | wc -l)
        
        # Check for unpushed commits
        unpushed_count=$(git -C "$repo_path" log --branches --not --remotes --simplify-by-decoration --oneline | wc -l)

        if (( uncommitted_count > 0 || unpushed_count > 0 )); then
            echo -n "$repo_path: "
            if (( uncommitted_count > 0 )); then
                echo -n "\e[33m!${uncommitted_count}\e[0m "  # Yellow for uncommitted files
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
    echo "Usage: $0 [-v] <directory>"
    exit 1
fi

verbose=false
directory=""

# Process options and arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v)
            verbose=true
            shift
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
    check_git_status "$dir" "$verbose"
done
