. /opt/shell-libs/selectEditor.sh
if [ $? != 0 ]; then
    echo "Can not find library files." >&2
    exit $?
fi
editor=($getEditor $1)

file=~/.ssh/authorized_keys

echo "#Replace this with your public key." >>$file
sudo chmod 600 $file
sudo $editor $file
