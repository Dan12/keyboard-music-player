echo "=================================================="
echo "If there is no error during installation, ignore this message:"
echo "If installation fails because of libffi, you may need to install 'libffi' manually"
echo "If you have homebrew: 'brew install libffi'"
echo "=================================================="

opam depext conf-sdl2.1
opam install tsdl

opam depext tsdl-ttf.0.2
opam install tsdl-ttf
