#!/bin/bash

# complie bochs
./configure --prefix=/home/bochs --enable-debugger --enable-disasm --enable-iodebug --enable-x86-debugger --with-x --with-x11 LDFLAGS='-pthread'

# install bochs
make
make install
