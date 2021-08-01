#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/nginx-restart.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

nginx_dir="/etc/nginx"

while true; do
  if [ ! -d "$nginx_dir" ]; then
    echo_error "Can not find nginx directory in $nginx_dir"
    printf "Input nginx directory path: "
    read -r nginx_dir
  else
    break
  fi
done

nginx_config_file="$nginx_dir/nginx.conf"

remove_old_tls() {
  tls_1=$(cat $nginx_config_file | grep ssl_protocols | grep -P '(^|\s)\TLSv1(?=\s|$)')
  tls_1_1=$(cat $nginx_config_file | grep ssl_protocols | grep "TLSv1.1")

  if [ -n "$tls_1" ] || [ -n "$tls_1_1" ]; then
    user_task "Remove old TLS versions like TLSv1, TLSv1.1"
  fi
}

hide_nginx_server_version() {
  is_server_tokens_comment=$(cat $nginx_config_file | grep "# server_tokens off;")
  if [ -n "$is_server_tokens_comment" ]; then
    user_task "Uncomment # server_tokens off; to hide nginx version."
  else
    is_server_tokens_exist=$(cat $nginx_config_file | grep "server_tokens off;")
    if [ -z "$is_server_tokens_exist" ]; then
      user_task "Add server_tokens off; to http section."
    fi
  fi
}

add_security_headers() {
  sameOrigin=$(cat $nginx_config_file | grep 'add_header X-Frame-Options "SAMEORIGIN";')
  if [ -z "$sameOrigin" ]; then
    user_task "Add add_header X-Frame-Options \"SAMEORIGIN\"; to http section."
  fi

  xss_protection=$(cat $nginx_config_file | grep 'add_header X-XSS-Protection "1; mode=block";')
  if [ -z "$xss_protection" ]; then
    user_task 'Add add_header X-XSS-Protection "1; mode=block"; to http section.'
  fi

  strict_transport=$(cat $nginx_config_file | grep "add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload';")
  if [ -z "$strict_transport" ]; then
    user_task 'Add add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"; to http section.'
  fi

  xContent=$(cat $nginx_config_file | grep 'add_header X-Content-Type-Options nosniff;')
  if [ -z "$xContent" ]; then
    user_task 'Add add_header X-Content-Type-Options nosniff; to http section.'
  fi

  permitted_cross_domain=$(cat $nginx_config_file | grep 'add_header X-Permitted-Cross-Domain-Policies master-only;')
  if [ -z "$permitted_cross_domain" ]; then
    user_task 'Add add_header X-Permitted-Cross-Domain-Policies master-only; to http section.'
  fi

  referrer_policy=$(cat $nginx_config_file | grep 'add_header Referrer-Policy same-origin;')
  if [ -z "$referrer_policy" ]; then
    user_task 'Add add_header Referrer-Policy same-origin; to http section.'
  fi
}

add_buffer_limit() {
  body_buffer=$(cat $nginx_config_file | grep 'client_body_buffer_size  1K;')
  if [ -z "$body_buffer" ]; then
    user_task 'Add client_body_buffer_size  1K; to http section.'
  fi

  header_buffer=$(cat $nginx_config_file | grep 'client_header_buffer_size 1k;')
  if [ -z "$header_buffer" ]; then
    user_task 'Add client_header_buffer_size 1k; to http section.'
  fi

  max_body_size=$(cat $nginx_config_file | grep 'client_max_body_size 1k;')
  if [ -z "$max_body_size" ]; then
    user_task 'Add client_max_body_size 1k; to http section.'
  fi

  large_client_header_buffers=$(cat $nginx_config_file | grep 'large_client_header_buffers 2 1k;')
  if [ -z "$large_client_header_buffers" ]; then
    user_task 'Add large_client_header_buffers 2 1k; to http section.'
  fi
}

check_with_gixy() {
  echo_info "Check config file with gixy..."
  check_pip=$(pip -v)
  if [ "$?" != 0 ]; then
    echo_info "Installing python3-pip..."
    apt install python3-pip
    if [ "$?" != 0 ]; then
      local code=$?
      show_error_if_operation_failed "$code"
      return $code
    fi
  fi

  check_gixy=$(gixy -v)
  if [ "$?" != 0 ]; then
    echo_info "Installing gixy..."
    pip install gixy
    if [ "$?" != 0 ]; then
      local code=$?
      show_error_if_operation_failed "$code"
      return $code
    fi
  fi

  gixy "$nginx_config_file"
  show_error_if_operation_failed "$code"

  user_task ""
}

check_with_gixy
echo ""

remove_old_tls
echo ""

hide_nginx_server_version
echo ""

add_security_headers

add_buffer_limit

echo_info "Restarting nginx..."
/opt/shell-libs/nginx-restart.sh
