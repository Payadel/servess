#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

ufw-mailu() {
    if ! ufw_loc="$(type -p "ufw")" || [ -z "$ufw_loc" ]; then
        echo_error "UFW is not installed yet."
    elif [ "$1" = "enable" ]; then
        echo_info "ufw allow 25,80,443,110,143,465,587,993,995/tcp"
        sudo ufw allow 25,80,443,110,143,465,587,993,995/tcp
        exit_if_operation_failed "$?"

        echo_info "ufw allow out from any to any port 2500,1100,1430,4650,5870,9930,9950 proto tcp"
        sudo ufw allow out from any to any port 2500,1100,1430,4650,5870,9930,9950 proto tcp
        code="$?"
        if [ "$code" != 0 ]; then
            echo_error "Operation failed with code $?"
            sudo ufw delete allow 25,80,443,110,143,465,587,993,995/tcp
            show_warning_if_operation_failed $?
            exit $code
        fi
        echo ""
        sudo ufw reload
        show_error_if_operation_failed "$?"
        echo ""
        sudo ufw status numbered
    elif [ "$1" = "disable" ]; then
        sudo ufw delete allow 25,80,443,110,143,465,587,993,995/tcp
        show_error_if_operation_failed "$?"

        sudo ufw delete allow out from any to any port 2500,1100,1430,4650,5870,9930,9950 proto tcp
        show_error_if_operation_failed "$?"

        echo ""
        sudo ufw reload
        show_error_if_operation_failed "$?"
        echo ""
        sudo ufw status numbered
    else
        echo ""
        sudo ufw status numbered
        printf "Use 'enable' or 'disable' in input.\n\n"
    fi
}
export -f ufw-mailu

#Uncomment this lines if you want use ufw-mailu enable/disable in your terminal (don't forget update path if changed)
# if [ -f /opt/shell-libs/ufw-mailu.sh ]; then
#     echo ". /opt/shell-libs/ufw-mailu.sh" >>~/.bashrc
# fi
