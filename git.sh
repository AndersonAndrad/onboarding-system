#!/bin/bash

set -e

echo "⚙️ Configuring global Git..."

# permit git work on wsl
sudo chown -R $USER:$USER .git

# User info
git config --global user.name "Anderson Andrade"
git config --global user.email "anderson_andrade_@outlook.com"

# Aliases
git config --global alias.cm "commit -m"
git config --global alias.po "push origin"
git config --global alias.pom "push origin main"
git config --global alias.ch "checkout"
git config --global alias.chm "checkout master"
git config --global alias.chd "checkout develop"
git config --global alias.cha "checkout dev_anderson"
git config --global alias.del "branch -D"
git config --global alias.rollback "reset --hard"
git config --global alias.chb "checkout -b"
git config --global alias.s "status -sb"
git config --global alias.ad "add ."
git config --global alias.upgrade "!git fetch --all && git remote update origin --prune"
git config --global alias.upstream "remote add upstream"
git config --global alias.sv "remote -v"
git config --global alias.fat "fetch --all"
git config --global alias.c "commit -m"

git config --global alias.l "!git log --graph --abbrev-commit --decorate=no --date=format:'%Y-%m-%d %H:%M:%S' --format=format:'%C(03)%>|(15)%h%C(reset)  %C(04)%ad%C(reset)  %C(green)%<(25,trunc)%an%C(reset)  %C(bold 1)%d%C(reset) %C(bold 0)%>|(1)%s%C(reset)' -n 10"

git config --global alias.b "!git branch -r --sort=-committerdate --format='%(color:magenta)%(authorname)%(color:reset)|%(HEAD)%(color:yellow)%(refname:short)|%(color:bold green)%(committerdate:relative)|%(color:blue)%(subject)|' --color=always | column -ts '|'"

echo "✅ Git configured successfully"