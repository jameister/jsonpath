all:
	ocamlbuild -pkgs yojson,core_kernel main.native

clean:
	ocamlbuild -clean; echo
