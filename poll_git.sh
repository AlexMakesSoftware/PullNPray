#!/bin/bash

# Set your variables
project=your_project
github_repo="your github address for the project"
local_clone_dir="$HOME/projects/$project"
deployment_script="$HOME/poller/$project/deploy.sh"
notification_dir="$HOME/poller/$project/notifications/"
rollback_dir="$HOME/poller/$project/rollback/"
lock_file="/tmp/poll.$project.lock"

# Check if the lock file exists
if [ -e "$lock_file" ]; then
    echo "Lock file already exists. Exiting."    
    echo "lockfile is: $lock_file"
    exit 1
fi

# Create the lock file
touch "$lock_file"

# Clone or update the repository
if [ -d "$local_clone_dir/.git" ]; then
    echo "local repository located."
else
    echo "The target doesn't seem to be a git repository."
    echo "Did you forget to clone it?"
    echo "Try: git clone $github_repo $local_clone_dir"
    exit 1
fi

cd "$local_clone_dir"

#Check for differences.
echo "## comparing local copy with remote ##"
if [ -n "$(git fetch --dry-run 2>&1)" ]; then
    echo "Updating the project..."
    #Update main locally with the upstream origin.
    git fetch origin
    git reset --hard origin/main

    # Run the deployment script
    if [ -f "$deployment_script" ]; then
        "$deployment_script" > "$notification_dir/deployment_output.txt" 2>&1
        #TODO: we could add version notes, maybe append them to that file?

        # Generate a rollback script
        echo "#!/bin/bash" > "$rollback_dir/rollback_script.sh"
        echo "cd $local_clone_dir" >> "$rollback_dir/rollback_script.sh"
        echo "git reset --hard HEAD^" >> "$rollback_dir/rollback_script.sh"
        chmod +x "$rollback_dir/rollback_script.sh"
        echo "Rollback script generated."
    else
        echo "Deployment script not found. Cannot proceed."
        exit 1
    fi
else
    echo "No updates found."
fi

# Remove the lock file (only if the script didn't error).
rm "$lock_file"
