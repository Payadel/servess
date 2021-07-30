if [ ! -f /opt/shell-libs/colors.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh

exit_if_operation_failed() {
    local code="$1"
    local message="$2"

    if [ "$code" != "0" ]; then
        if [ ! -z "$message" ]; then
            echo -e "$message" >&2
        else
            echo_error "Operation failed with code $code."
        fi
        exit "$code"
    fi
}

show_warning_if_operation_failed() {
    local code="$1"
    local message="$2"

    if [ "$code" != "0" ]; then
        if [ ! -z "$message" ]; then
            echo -e "$message" >&2
        else
            echo_warning "Operation failed with code $code."
        fi
    fi
}

show_error_if_operation_failed() {
    local code="$1"
    local message="$2"

    if [ "$code" != "0" ]; then
        if [ ! -z "$message" ]; then
            echo -e "$message" >&2
        else
            echo_error "Operation failed with code $code."
        fi
    fi
}

is_user_exist() {
    local username="$1"

    id "$username" &>/dev/null
    return $?
}

delete_user_if_operation_failed() {
    local code="$1"

    if [ "$code" != "0" ]; then
        echo_error "Operation failed."
        printf "Do you want delete user? (y/n): "
        read delete_user

        if [ "$delete_user" = "y" ] || [ "$delete_user" = "Y" ]; then
            /opt/shell-libs/user-delete.sh "$delete_user"
        fi
    fi
}

user_must_exist() {
    local username="$1"

    is_user_exist "$username"
    if [ "$?" != 0 ]; then
        echo_error "User is not exist"
        exit "$?"
    fi
}

user_task() {
    message="$1"
    printf "Task: $message. Press enter to continue..."
    read temp
}
