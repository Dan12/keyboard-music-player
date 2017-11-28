test:
	ocamlbuild -use-ocamlfind test.byte && ./test.byte

simple:
	ocamlfind ocamlc -g -package lablgtk2 -linkpkg simple.ml -o simple
	./simple

clean:
	rm -rf _build/
	rm *.byte

clean_simple:
	rm *.cmi
	rm *.cmo
	rm Simple
