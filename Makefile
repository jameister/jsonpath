all:
	ocamlbuild -use-menhir -pkgs yojson,core_kernel main.native
	cp -L main.native jsonpath

clean:
	rm -f jsonpath
	ocamlbuild -clean; echo
