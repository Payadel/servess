#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

username="$1"
if [ -z "$username" ]; then
  printf "Username: "
  read -r username
fi
user_must_exist "$username"

getent passwd "$username" | cut -d: -f6
