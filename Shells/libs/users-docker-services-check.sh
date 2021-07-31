#!/bin/bash

if [ ! -f /opt/shell-libs/colors.sh ]; then
    echo "Can't find /opt/shell-libs/colors.sh" >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh

process_must_ok() {
    local data="$1"

    if [ -z "$data" ]; then
        echo_warning "No container found!"
        return 1
    fi

    local code=0

    local restarting=$(echo "$data" | grep 'restarting')
    if [ ! -z "$restarting" ]; then
        echo_warning "One or more containers are restarting."
        code=1
    fi

    local removing=$(echo "$data" | grep 'removing')
    if [ ! -z "$removing" ]; then
        echo_warning "One or more containers are removing."
        code=1
    fi

    local paused=$(echo "$data" | grep 'paused')
    if [ ! -z "$paused" ]; then
        echo_error "One or more containers are paused."
        code=1
    fi

    local exited=$(echo "$data" | grep 'exited')
    if [ ! -z "$exited" ]; then
        echo_error "One or more containers are exited."
        code=1
    fi

    local dead=$(echo "$data" | grep 'dead')
    if [ ! -z "$dead" ]; then
        echo_error "One or more containers are dead."
        code=1
    fi

    local starting=$(echo "$data" | grep 'starting')
    if [ ! -z "$starting" ]; then
        echo_warning "One or more containers are starting."
        code=1
    fi

    return $code
}

for directory in /run/user/*; do
    processes=$(sudo docker --host "unix://$directory/docker.sock" ps --format "{{.ID}}\t{{.Image}}\t{{.Status}}" 2>/dev/null)
    code="$?"

    user=$(ls -ld $directory | awk '{print $3}')
    printf "$user: "

    if [ "$code" != 0 ]; then
        if [ "$code" = 1 ]; then
            echo -e "${BOLD_YELLOW}Docker is not active.${ENDCOLOR}"
        else
            echo_error "Unexpected code : $code"
        fi
    else
        echo -e "${BOLD_GREEN}Docker is active.${ENDCOLOR}"
        process_must_ok "$processes"
        if [ "$?" = 0 ]; then
            echo -e "$OK_COLORIZED - Everything looks good."
        fi
    fi
    echo_info "For more information use this command: sudo docker --host unix://$directory/docker.sock ps"
    echo ""
done
