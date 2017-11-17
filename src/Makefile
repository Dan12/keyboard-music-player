main:
	ocamlbuild -use-ocamlfind main.byte && ./main.byte

test:
	ocamlbuild -use-ocamlfind test.byte && ./test.byte

clean:
	rm -rf _build/
	rm *.byte

mli:
	zip mli.zip *.mli