#!/bin/bash

if [ ! -f /opt/shell-libs/colors.sh ]; then
  echo "Can't find /opt/shell-libs/colors.sh" >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh

validate_proxy_pass() {
  local proxy_pass=$1
  local fileName=$2

  curl_result=$(curl -s -I --insecure "$proxy_pass")
  if [ -z "$curl_result" ]; then
    echo -e "$fileName: $ERROR_COLORIZED - We have trouble with $proxy_pass"
  else
    echo -e "$fileName: $OK_COLORIZED - $proxy_pass looks good."
  fi
}

validate_root_dir() {
  local root_dir=$1
  local fileName=$2

  if [ -d "$root_dir" ]; then
    echo -e "$fileName: $OK_COLORIZED - Root dir found. ($root_dir)"
  else
    echo -e "$fileName: $ERROR_COLORIZED - Can't find Root dir. ($root_dir)"
  fi
}

validate_nginx_file() {
  local fileName=$1

  proxy_pass=$(awk -F ' ' -v key="proxy_pass" '$1==key {print $2}' "$fileName")
  if [ -z "$proxy_pass" ]; then
    root_dir=$(awk -F ' ' -v key="root" '$1==key {print $2}' "$fileName")
    if [ -z "$root_dir" ]; then
      echo -e "$fileName: $ERROR_COLORIZED - Can't find proxy_pass or root in this file."
    else
      root_dir=${root_dir::-1} #Removes execc ; char in string
      validate_root_dir "$root_dir" "$fileName"
    fi
  else
    proxy_pass=${proxy_pass::-1} #Removes execc ; char in string
    validate_proxy_pass "$proxy_pass" "$fileName"
  fi
}

nginx_status=$(systemctl status nginx 2>/dev/null | grep "Active: ")
if [ -z "$nginx_status" ]; then
  #Can't find Nginx service
  exit 0
else
  if [ "$(systemctl is-active nginx)" = "active" ]; then
    echo -e "Nginx: $OK_COLORIZED - ${nginx_status:13}"
  else
    echo -e "Nginx: $ERROR_COLORIZED - ${nginx_status:13}"
  fi
fi
echo ""

#Check sites-enabled files
if [ -d "/etc/nginx/sites-enabled" ]; then
  for fileName in /etc/nginx/sites-enabled/*; do
    validate_nginx_file "$fileName"
  done
fi
echo ""
