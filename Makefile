all: build
	docker build -t arjunguha/docker-grader .

J=4

setup.ml: _oasis
	oasis setup

setup.data: setup.ml
	ocaml setup.ml -configure

build: setup.data setup.ml
	cd dockergrader && atdgen -t DockerGrader.atd
	cd dockergrader && atdgen -j -j-std DockerGrader.atd
	ocaml setup.ml -build -j $(J)

install: setup.data setup.ml
	ocaml setup.ml -install

reinstall: setup.ml
	ocaml setup.ml -reinstall

clean:
	ocamlbuild -clean
	rm -f setup.data setup.log

distclean:
	ocaml setup.ml -distclean
	rm -f setup.data setup.log