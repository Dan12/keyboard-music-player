# install necessary packages not found by depext
sudo apt-get update
sudo apt-get install libxext-dev libffi-dev

# go to downloads folder
cd ~/Downloads
# download sdl 2.0.5
wget https://www.libsdl.org/release/SDL2-2.0.5.tar.gz
# unpack it
tar -zxvf SDL2-2.0.5.tar.gz

# in the source folder
cd SDL2-2.0.5
# configure with flag to avoid linking errors
./configure --enable-mir-shared=no
# make to compile all files
make
# install the library
sudo make install

# clean up
cd ..
rm SDL2-2.0.5.tar.gz
rm -rf SDL2-2.0.5

# install tsdl
opam install tsdl

# init alsa driver
alsactl init

# install ttf
opam depext tsdl-ttf.0.2
opam install tsdl-ttf