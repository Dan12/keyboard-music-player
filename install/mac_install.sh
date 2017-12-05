echo "=================================================="
echo "You may need to install 'libffi' before continuing"
echo "If you have homebrew: 'brew install libffi'"
echo "=================================================="

opam depext conf-sdl2.1
opam install tsdl

opam depext tsdl-ttf.0.2
opam install tsdl-ttf