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

is_user_exist() {
    local username="$1"

    id "$username" &>/dev/null
    return $?
}
