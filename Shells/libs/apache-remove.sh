#!/bin/bash

if service apache2 status; then
    echo "Apache is installed. This can disrupt the Nginx service."
    printf "Do you wand delete it? (y/n): "
    read -r delete
    if [ "$delete" = "y" ] || [ "$delete" = "Y" ]; then
        sudo service apache2 stop
        sudo apt-get purge apache2 apache2-utils apache2.2-bin apache2-common
        sudo apt-get autoremove --purge
        sudo rm -Rf /etc/apache2 /usr/lib/apache2 /usr/include/apache2
    fi
fi
