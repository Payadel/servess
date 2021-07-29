#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

removeDirIfIsExist() {
    dir=$1

    if [ -d "$dir" ]; then
        sudo rm -r "$dir"
    fi
}

installAndBuild() {
    dir=$1
    env_file=$2

    cd "$dir" && sudo npm install
    if [ $? != 0 ]; then
        echo_error "Install failed."
        return 1
    fi

    cd "$dir" && sudo npm run build
    if [ $? != 0 ]; then
        echo_error "Build failed."
        return 1
    fi

    sudo cp "$env_file" "$dir/dist/"
}

cloneProject() {
    path=$1
    userName=$2
    password=$3
    branch=$4
    github_sub_url=$5

    removeDirIfIsExist "$path"
    sudo git clone --branch "$branch" https://"$username":"$password""@github.com/$github_sub_url" "$path"

    if [ $? != 0 ]; then
        echo_error "Clone project failed."
        return 1
    fi
}

getUpdatedProject() {
    path_main=$1
    path_temp=$2
    username=$3
    password=$4
    branch=$5
    github_sub_url=$6
    work_dir=$7

    if [ -d "$path_main" ]; then

        echo_info "Updating project with pull..."
        pull_result=$(cd "$path_main/$work_dir" && sudo git pull origin)

        if [ $? == 0 ]; then
            # Exit program when project already up to date.
            if [ "$pull_result" = "Already up to date." ]; then
                echo_success "Project already up to date."
                exit 0
            fi

            echo "Get Copy..."
            removeDirIfIsExist "$path_temp"
            sudo cp -r "$path_main" "$path_temp"
            exit_if_operation_failed "$?"

            printf "Done.\n\n"
        else
            echo_info "Pull request failed."
            echo_info "Try update project with clone..."

            cloneProject "$path_temp" "$username" "$password" "$branch" "$github_sub_url"
            exit_if_operation_failed "$?"
        fi
        printf "Done.\n\n"

    else
        echo_info "Update project with clone..."
        cloneProject "$path_temp" "$username" "$password" "$branch" "$github_sub_url"
        exit_if_operation_failed "$?"

        printf "Done.\n\n"
    fi
}
