getBackup() {
  target=$1
  backupDir=$2
  backupName=$3

  #Target must be dir or file
  isDir="false"
  if [ ! -f "$target" ]; then
    if [ ! -d "$target" ]; then
      echo "Target must be dir or file."
      return 1
    fi
    isDir="true"
  fi

  #Create directory for backup if is not exist
  if [ ! -d "$backupDir" ]; then
    sudo mkdir -p "$backupDir"
  fi
  chmod 750 "$backupDir"

  #Init git if is not exist
  if [ ! -d "$backupDir/.git" ]; then
    sudo git init "$backupDir"
  fi

  # cd $backupDir && git checkout -b "$backupName"
  contentDir_name="contents"
  if [ -d "$backupDir/$contentDir_name" ]; then
    sudo rm -r "$backupDir/$contentDir_name"
  fi

  mkdir -p "$backupDir/$contentDir_name/"
  if [ "$isDir" = "true" ]; then
    cp -r "$target" "$backupDir/$contentDir_name/"
  else
    cp "$target" "$backupDir/$contentDir_name/"
  fi

  cd "$backupDir" && git add --all
  commit_result=$(cd "$backupDir" && git commit -am "$backupName")
  echo "$commit_result"
}

if [ "$1" != "source-only" ]; then
  getBackup "$1" "$2" "$3"
fi
