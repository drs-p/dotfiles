#!/bin/bash

fullname=$(realpath $0)
filename=$(basename $fullname)
pathname=${fullname/$filename/}
pathname=${pathname/%\//}

CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

for name in $pathname/generic/*; do
    bname=$(basename $name)
    echo "Installing .$bname"
    rm -f $HOME/.$bname
    ln -s $name $HOME/.$bname
done

if [ -e $HOME/.bashrc ]; then
    echo "Not clobbering your existing .bashrc"
else
    echo "Installing .bashrc"
    rm -f $HOME/.bashrc
    ln -s $pathname/special/bashrc $HOME/.bashrc
fi

echo "Populating .vim/"
if [ ! -d $HOME/.vim/pack/packages/start ]; then
    mkdir -p $HOME/.vim/pack/packages/{start,opt}
    (
        cd $HOME/.vim/pack/packages/start
        git clone https://github.com/arcticicestudio/nord-vim.git
        git clone https://github.com/jiangmiao/auto-pairs.git
        git clone https://github.com/tpope/vim-surround.git
        git clone https://github.com/tpope/vim-commentary.git
        git clone https://github.com/christoomey/vim-tmux-navigator.git
        git clone https://github.com/itchyny/lightline.vim.git
        git clone https://github.com/itchyny/vim-gitbranch.git
        git clone https://github.com/Vimjas/vim-python-pep8-indent.git
        git clone https://github.com/tpope/vim-fugitive.git
    )
    (
        cd $HOME/.vim/pack/packages/opt
        git clone https://github.com/edkolev/promptline.vim
        git clone https://github.com/edkolev/tmuxline.vim.git
        git clone https://github.com/dhruvasagar/vim-table-mode.git
    )
fi

echo "Installing init.vim"
NVIM_CONFIGDIR=$CONFIG_HOME/nvim
mkdir -p $NVIM_CONFIGDIR
rm -f $NVIM_CONFIGDIR/init.vim
ln -s $pathname/special/init.vim $NVIM_CONFIGDIR/init.vim
vim -c "helptags ALL" -c q

echo "installing texdoc.cnf"
texdocdir="$HOME"/texmf/texdoc
mkdir -p "$texdocdir"
rm -f "$texdocdir"/texdoc.cnf
ln -s "$pathname"/special/texdoc.cnf "$texdocdir"/texdoc.cnf

echo "Updating ipython_config.py"
if command -v ipython >&/dev/null; then
    ipython profile create
    IPYTHON_PROFILE=$(ipython profile locate)/ipython_config.py
    sed -i "s:# c.InteractiveShell.colors = 'Neutral':c.InteractiveShell.colors = 'Linux':g" $IPYTHON_PROFILE
    sed -i "s:# c.TerminalInteractiveShell.confirm_exit = True:c.TerminalInteractiveShell.confirm_exit = False:" $IPYTHON_PROFILE
fi
if command -v sage >&/dev/null; then
    (
        sage -ipython profile create
        SAGE_IPYTHON_PROFILE=$(sage -ipython profile locate)/ipython_config.py
        sed -i "s:# c.InteractiveShell.colors = 'Neutral':c.InteractiveShell.colors = 'Linux':g" $SAGE_IPYTHON_PROFILE
        sed -i "s:# c.TerminalInteractiveShell.confirm_exit = True:c.TerminalInteractiveShell.confirm_exit = False:" $SAGE_IPYTHON_PROFILE
    )
fi

echo "Installing fonts.conf"
FONTCONFIG_DIR=$CONFIG_HOME/fontconfig
mkdir -p $FONTCONFIG_DIR
rm -f $FONTCONFIG_DIR/fonts.conf
ln -s $pathname/special/fonts.conf $FONTCONFIG_DIR/fonts.conf

MIRROR=$HOME/mirror
mkdir -p $MIRROR
(
    cd $MIRROR
    if [ ! -d Nordic ]; then
        git clone https://github.com/EliverLara/Nordic
        (cd Nordic; git switch --track origin/standard-buttons)
    fi
    if [ ! -d firefox-nordic-theme ]; then
        git clone https://github.com/EliverLara/firefox-nordic-theme
    fi
    for repo in dircolors gedit gnome-terminal vim; do
        if [ ! -d nord-$repo ]; then
            git clone https://github.com/nordtheme/$repo nord-$repo
        fi
    done
)
echo "Installing Nordic theme for Gnome"
(
    mkdir -p $HOME/.themes
    rm -f $HOME/.themes/Nordic
    ln -s $MIRROR/Nordic $HOME/.themes/Nordic
    gsettings set org.gnome.desktop.interface gtk-theme "Nordic"
    gsettings set org.gnome.desktop.wm.preferences theme "Nordic"
    mkdir -p $HOME/.config
    rm -rf $HOME/.config/gtk-[34].0/gtk{,-dark}.css $HOME/.config/assets
    # ln -s $MIRROR/Nordic/gtk-3.0/gtk.css $HOME/.config/gtk-3.0/gtk.css
    # ln -s $MIRROR/Nordic/gtk-3.0/gtk-dark.css $HOME/.config/gtk-3.0/gtk-dark.css
    ln -s $MIRROR/Nordic/gtk-4.0/gtk.css $HOME/.config/gtk-4.0/gtk.css
    ln -s $MIRROR/Nordic/gtk-4.0/gtk-dark.css $HOME/.config/gtk-4.0/gtk-dark.css
    # ln -s $MIRROR/Nordic/assets $HOME/.config/assets
)
echo "Installing Nordic theme for Firefox"
(
    cd $HOME/.mozilla/firefox/*.default
    mkdir -p chrome
    rm -f chrome/firefox-nordic-theme user.js
    ln -s $MIRROR/firefox-nordic-theme $PWD/chrome/firefox-nordic-theme
    ln -s $MIRROR/firefox-nordic-theme/configuration/user.js $PWD/user.js
    echo '@import "firefox-nordic-theme/userChrome.css";' >chrome/userChrome.css
)
echo "Installing Nord theme for Dircolors"
rm -f $HOME/.dircolors
ln -s $MIRROR/nord-dircolors/src/dir_colors $HOME/.dircolors
echo "Installing Nord theme for Gedit"
(cd $MIRROR/nord-gedit; bash install.sh)
echo "Installing Nord theme for Gnome Terminal"
(cd $MIRROR/nord-gnome-terminal/src; bash nord.sh --profile=Nord || bash nord.sh)

echo "Done"
