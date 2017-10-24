# go to downloads folder
cd ~/Downloads
# download sdl-ttf 2.0.14
wget https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.14.tar.gz
# unpack it
tar -zxvf SDL2_ttf-2.0.14.tar.gz

# in the source folder
cd SDL2_ttf-2.0.14
./configure
make
sudo make install

# clean up
cd ..
rm SDL2_ttf-2.0.14.tar.gz
rm -rf SDL2_ttf-2.0.14