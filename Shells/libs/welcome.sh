#!/bin/bash

# for fileName in /etc/update-motd.d/*; do
#     if [ "$fileName" != "/etc/update-motd.d/98-fsck-at-reboot" ] && [ -x "$fileName" ]; then
#         $fileName
#     fi
# done

sudo run-parts /etc/update-motd.d/
