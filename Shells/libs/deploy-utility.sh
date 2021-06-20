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
        echo "Install failed."
        return 1
    fi

    cd "$dir" && sudo npm run build
    if [ $? != 0 ]; then
        echo "Build failed."
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
        echo "Clone project failed."
        return 1
    fi
}

getUpdatedProject(){
    path_main=$1
    path_temp=$2
    username=$3
    password=$4
    branch=$5
    github_sub_url=$6
    work_dir=$7
    

    if [ -d "$path_main" ]; then

        echo "Updating project with pull..."
        pull_result=$(cd "$path_main/$work_dir" && sudo git pull origin)

        if [ $? == 0 ]; then
            # Exit program when project already up to date.
            if [ "$pull_result" = "Already up to date." ]; then
                echo "Project already up to date."
                exit 0
            fi

            echo "Get Copy..."
            removeDirIfIsExist "$path_temp"
            sudo cp -r "$path_main" "$path_temp"
            if [ $? != 0 ]; then
                echo "Operation failed."
                exit 1
            fi
            printf "Done.\n\n"
        else
            echo "Pull request failed."
            echo "Try update project with clone..."

            cloneProject "$path_temp" "$username" "$password" "$branch" "$github_sub_url"
            if [ $? != 0 ]; then
                echo "Clone failed."
                exit 1
            fi
        fi
        printf "Done.\n\n"

    else
        echo "Update project with clone..."
        cloneProject "$path_temp" "$username" "$password" "$branch" "$github_sub_url"
        if [ $? != 0 ]; then
            echo "Operation failed."
            exit 1
        fi
        printf "Done.\n\n"
    fi
}