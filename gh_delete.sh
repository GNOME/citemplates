#!/bin/bash

# Variables
ORG=$1  # Replace with your GitHub username or organization name
PACKAGE_GLOB=$2  # Glob pattern for package names passed as an argument (e.g., "package*" to match all)

set -eux

# Function to delete a package version
delete_package_version() {
    name=${1//\//%2F}
    echo "deleting package with name: $name"
    gh api -X DELETE "/orgs/${ORG}/packages/container/$name" --silent
}

# Fetch the list of all available packages for the user/organization
echo "Fetching packages matching the glob pattern '$PACKAGE_GLOB'..."

# Fetch all package names and filter with globbing
ALL_PACKAGES=$(gh api  -H "Accept: application/vnd.github+json"  -H "X-GitHub-Api-Version: 2022-11-28" "/orgs/$ORG/packages?package_type=container" --jq '.[].name' --paginate)
MATCHED_PACKAGES=$(echo "$ALL_PACKAGES" | grep "$PACKAGE_GLOB")
if [[ -z "$MATCHED_PACKAGES" ]]; then
    echo "No packages found matching the pattern '$PACKAGE_GLOB'."
    exit 1
fi

# echo "Deleting the following packages: ${MATCHED_PACKAGES}"

# Loop through matched packages and delete them
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
packages=($MATCHED_PACKAGES) # split the `names` string into an array by the same name
IFS=$SAVEIFS   # Restore original IFS

for (( i=0; i<${#packages[@]}; i++ ))
do
    delete_package_version "${packages[$i]}"
done

echo "All matching packages deleted!"
