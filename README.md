DockerGrader
============

A docker-based grading system. To build it, you'll need:

- [ocaml-docker] which needs to be manually installed for now
- Other dependencies are available on OPAM (see the _oasis file)
- Docker on Ubuntu 14.04 
- (Optional) Support for [memory limits]

See the examples/ directory for a sample assignment. Both submissions
are trying to circumvent the sandbox in some way.

TODO
====

- Enforce time and memory limits
- Copy outputs to submission directory
- Save/display warnings for debugging
- Handle exit-codes properly

[ocaml-docker]: https://github.com/arjunguha/ocaml-docker
[memory limits]: http://docs.docker.io/installation/ubuntulinux/#memory-and-swap-accounting