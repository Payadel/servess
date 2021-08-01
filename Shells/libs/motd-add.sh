if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
  echo "Can't find libs" >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

motd_directory="/etc/update-motd.d"

add_file_to_motd() {
  local file_dir="$1"
  local fileName="$2"
  local next_number="$3"

  local output="$motd_directory/$next_number-${fileName::-3}"

  echo_info "Creating shortcut from $file_dir/$fileName to $output."
  sudo ln -s "$file_dir/$fileName" "$output"
}

file_dir="$1"
if [ -z "$file_dir" ]; then
  printf "file directory: "
  read -r file_dir
fi
if [ ! -d "$file_dir" ]; then
  echo_error "The directory is not exist: $file_dir"
  exit 1
fi

fileName="$2"
if [ -z "$fileName" ]; then
  printf "fileName: "
  read -r fileName
fi
if [ ! -f "$file_dir/$fileName" ]; then
  echo_error "The file is not exist: $file_dir/$fileName"
  exit 1
fi

#Check directory
if [ ! -d "$motd_directory" ]; then
  echo_warning "Directory $motd_directory isn't exist."
  echo_info "Creating directory..."
  sudo mkdir -p "$motd_directory"
fi

#Get last number
last_file_number=$(ls $motd_directory | sort -V | tail -n 1 | grep -o "^[0-9]*")
last_number_length=${#last_file_number}

#Get new number
next_number=$((last_file_number + 1))
next_number_length=${#next_number}

if [ "$last_number_length" == "$next_number_length" ]; then
  # last number: 98 --> new number: 99
  add_file_to_motd "$file_dir" "$fileName" "$next_number"
else
  # last number: 99 --> new number: 900
  new_number="9"
  for ((i = 0; i < last_number_length; i++)); do
    new_number="${new_number}0"
  done
  add_file_to_motd "$file_dir" "$fileName" "$new_number"
fi
