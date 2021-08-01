pass_length=30
if [ -n "$1" ]; then
  pass_length="$1"
fi

openssl rand -base64 $pass_length
