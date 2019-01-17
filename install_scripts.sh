#!/bin/bash

cd `dirname $0`
path=`pwd`

installscript(){
    ln -s $path/$1.sh /usr/bin/$1 
}

installscript send_window

