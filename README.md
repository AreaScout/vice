Versatile Commodore Emulator (VICE)
====

VICE Emulator port for limadriver

$ git clone https://github.com/AreaScout/vice.git

$ cd vice

$ sudo apt-get install flex bison autogen automake libsdl1.2-dev texinfo

$ ./autogen.sh

$ ./configure --enable-lima --enable-sdlui

$ make

$ sudo make install
