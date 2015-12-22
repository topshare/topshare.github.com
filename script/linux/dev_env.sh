#!/bin/bash

sudo mount 192.168.234.1:/Users/kevin/code /home/kevin/code
exec /usr/bin/ssh-agent $SHELL


# delete pyc file in openstack dev
#find and delete *.pyc
find . -iname *.pyc
find . -iname *.pyc -exec rm -rf {} \;


# CentOS bash completion
yum install bash-comppletion
chown -R stack.root /etc/bash_completion.d



# git config
git config --global user.name "Zhang Jinnan"
git config --global user.email "zhang.jinnan@99cloud.net"
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global color.ui true


# vim config

cat << EOF > .vimrc
" enable syntax highlighting
syntax enable

" show line numbers
set number

" set tabs to have 4 spaces
set ts=4

" indent when moving to the next line while writing code
set autoindent

" expand tabs into spaces
set expandtab

" when using the >> or << commands, shift lines by 4 spaces
set shiftwidth=4

" show a visual line under the cursor's current line 
set cursorline

" show the matching part of the pair for [] {} and ()
set showmatch

" enable all Python syntax highlighting features
let python_highlight_all = 1
EOF



exit 0