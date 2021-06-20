getEditor() {
    if [ -z "$1" ]; then
        editor="nano"
    else
        editor=$1
    fi
    return editor
}
