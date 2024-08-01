#!/bin/bash

# Redirect all output to log file
exec > >(tee "upload.log") 2>&1

# Load the JSON file
json_file="projects.json"
src_dir="$HOME/SourceControl/Personal/Infrastructure"
dst_dir="$HOME/SourceControl/Public/.TemporaryUpload"

# wiki function
# instead of copying all files and removing, it is better to have a list of paths to copy
# starting with a root, copy all files in the list
# find all strings loganmancuso_personal and replace with loganmancuso_public
function wiki() {
  echo -e "START:\twiki"
  local src=$1
  local dst=$2
  files_to_copy=(
    "README.md"
    "index.md"
    "Mentions.md"
    # Applications
    "Applications/Vault.md"
    # assets
    "assets/diagrams/overview.svg"
    "assets/images/noodle.ico"
    "assets/images/noodle.svg"
    # Development
    "Development/Proxmox Dev.md"
    "Development/Local Infrastructure.md"
    # Infrastructure
    "Infrastructure/Datacenter.md"
    "Infrastructure/Global Secrets.md"
    "Infrastructure/Module LXC.md"
    "Infrastructure/Module Machine.md"
    "Infrastructure/Template LXC.md"
    "Infrastructure/Template Machine.md"
    "Infrastructure/Instances/Sandbox.md"
    # HowTo
    "How-To/Start.md"
    "How-To/Dependencies.md"
    "How-To/Deployment.md"
    "How-To/IaC.md"
    "How-To/Tooling.md"
    "How-To/Workflow.md"
    # Standards
    "Standards/Instances.md"
    "Standards/Projects.md"
    "Standards/Secrets.md"
  )
  # Remove old files from destination directory
  echo "Removing Old Files"
  find "$dst" -type f \( -name '*.md' \) ! -path '*/.git/*' -exec sh -c 'rm -rf $1 --verbose' sh {} "$dst" \;
  # Iterate over files to copy
  for file in "${files_to_copy[@]}"; do
    # Get the directory of the file
    file_dir="$(dirname "$file")"
    echo $file_dir
    # Create parent directories in destination if they don't exist
    mkdir -p "$dst/$file_dir" --verbose
    # Copy the file to destination
    cp -R "$src/$file" "$dst/$file" --verbose
  done
  echo -e "END:\twiki"
}

# Function to clone repositories and copy files
function clone() {
  echo -e "START:\tclone\t$1"
  local project_name=$1
  local clone_url=$2
  local local_path=$3

  echo "Processing project: $project_name"

  # Clone the repository if it doesn't already exist
  if [ ! -d "$dst_dir/$local_path/.git" ]; then
    mkdir -p "$dst_dir"
    echo -e "Cloning Project\t$project_name"
    git clone "$clone_url" "$dst_dir/$local_path"
    # Copy Files to the target cloned folder
    echo -e "Copying Project\t$project_name"
    # if not wiki project then copy this way
    if [ $project_name == "proxmox-wiki" ]; then
      wiki "$src_dir/../obsidian/Proxmox/Wiki" "$dst_dir/$local_path/Wiki"
    else 
      # Copy only necessary files
      echo "Removing Old Files"
      find "$dst_dir/$local_path" -type f \( -name '*.tf' -o -name '.gitignore' -o -name '*.yml' -o -name 'README.md' \) ! -path '*/.git/*' -exec sh -c 'rm -rf $1 --verbose' sh {} "$dst_dir/$local_path" \;
      echo "Copying New Files"
      find "$src_dir/$local_path" -type f \( -name '*.tf' -o -name '.gitignore' -o -name '*.yml' -o -name 'README.md' \) ! -name '*.tfvars' ! -path '*/.terraform/*' -exec sh -c 'src="$1"; dst="$2${1#$3}"; cp "$src" "$dst" --verbose; ' sh {} "$dst_dir/$local_path" "$src_dir/$local_path" \;
      # Add License File
      cp LICENSE.md "$dst_dir/$local_path"
    fi
    # sanitize the copied files
    find "$dst_dir/$local_path" -type f -exec sed -i 's|loganmancuso_personal.gitlab.io/obsidian|loganmancuso_public.gitlab.io/proxmox-wiki|g' {} + ;
    find "$dst_dir/$local_path" -type f -exec sed -i 's|loganmancuso_personal.gitlab.io|loganmancuso_public.gitlab.io|g' {} + ;
    find "$dst_dir/$local_path" -type f -exec sed -i 's|loganmancuso_personal|loganmancuso_public|g' {} + ;
    find "$dst_dir/$local_path" -type f -exec sed -i 's|projects/[0-9]\{8\}/terraform|projects/XXXXXXXX/terraform|g' {} + ;
    echo -e "Entering Project\t$project_name\n"
    pushd "$dst_dir/$local_path"
    echo -e "Git Changes\t$project_name\n"
    # git branch -D feature/publish
    git checkout -b feature/publish
    git add .
    #  Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD --; then
      echo "Changes detected in these file(s):"
      git log --oneline -n 5
      git status -s
      echo -e "Changes:"
      if [ $dryrun == false ]; then
        git commit -m "$message"
        git checkout main
        git pull
        git merge feature/publish
        git push
        git branch -D feature/publish
        rm -rf "$dst_dir/$local_path"
      fi
    else
      git checkout main
      git branch -D feature/publish
      echo "Repository is up to date. No uncommitted changes detected."
      rm -rf "$dst_dir/$local_path"
    fi
    popd
  else
    echo "Repository already exists: $local_path"
    rm -rf "$dst_dir/$local_path"
  fi
  echo -e "END:\tclone\t$1"
}

# Main function
function main() {
  echo -e "START:\tmain"
  dryrun=true
  while getopts ":d:m:" opt; do
    case $opt in
      d) dryrun=$OPTARG
      ;;
      m) message=$OPTARG
      ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done
  # Iterate over the JSON object
  jq -c 'to_entries[]' "$json_file" | while read -r entry; do
    project_name=$(echo "$entry" | jq -r '.key')
    clone_url=$(echo "$entry" | jq -r '.value.clone_url')
    local_path=$(echo "$entry" | jq -r '.value.local_path')
    clone "$project_name" "$clone_url" "$local_path"
  done
  echo -e "END:\tmain"
}

# Start the script
main "$@"
