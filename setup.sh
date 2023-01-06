#!/usr/bin/env bash

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# We still need this.
windows() { [[ -n "$WINDIR" ]]; }

# Cross-platform symlink function. With one parameter, it will check
# whether the parameter is a symlink. With two parameters, it will create
# a symlink to a file or directory, with syntax: link $linkname $target
link() {
    if [[ -z "$2" ]]; then
        # Link-checking mode.
        if windows; then
            fsutil reparsepoint query "$1" > /dev/null
        else
            [[ -h "$1" ]]
        fi
    else
        # Link-creation mode.
        if windows; then
            # Windows needs to be told if it's a directory or not. Infer that.
            # Also: note that we convert `/` to `\`. In this case it's necessary.
            if [[ -d "$2" ]]; then
                cmd <<< "mklink /D \"$(cygpath -w $1)\" \"$(cygpath -w $2)\"" > /dev/null
            else
                cmd <<< "mklink \"$(cygpath -w $1)\" \"$(cygpath -w $2)\"" > /dev/null
            fi
        else
            # You know what? I think ln's parameters are backwards.
            ln -s "$2" "$1"
        fi
    fi
}

# Remove a link, cross-platform.
rmlink() {
    if windows; then
        # Again, Windows needs to be told if it's a file or directory.
        if [[ -d "$1" ]]; then
            rmdir "$1";
        else
            rm "$1"
        fi
    else
        rm "$1"
    fi
}

# Start with vim/vimrc install
rm -rf $HOME/.vim
link $HOME/.vim $DIR/.vim
rm -rf $HOME/.vimrc
link $HOME/.vimrc $DIR/.vimrc

rm -rf $HOME/.alacritty.yml
if windows; then
    link $HOME/.alacritty.yml $DIR/.alacritty_windows.yml
    rm -rf $APPDATA/alacritty/alacritty.yml
    link $APPDATA/alacritty/alacritty.yml $DIR/.alacritty_windows.yml
else
    link $HOME/.alacritty.yml $DIR/.alacritty.yml
fi