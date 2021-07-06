for fileName in /etc/update-motd.d/*; do
    if [ -x "$fileName" ]; then
        $fileName
    fi
done
