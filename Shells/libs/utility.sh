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
            echo -e "$ERROR_COLORIZED: Operation failed with code $code." >&2
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
            echo -e "$WARNING_COLORIZED: Operation failed with code $code." >&2
        fi
    fi
}
