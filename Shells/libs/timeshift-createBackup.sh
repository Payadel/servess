#!/bin/bash

comment=$1
if [ -z "$comment" ]; then
    printf "Enter a comment: "
    read -r comment
fi

sudo timeshift --create --comments "$comment"
