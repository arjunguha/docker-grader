FROM ubuntu:14.04
MAINTAINER Arjun Guha <arjun@cs.umass.edu>

# Do not remove
ADD _build/dockergrader/DockerGrader.native /usr/bin/DockerGrader

# Do not override WORKDIR
WORKDIR /root

# Do not override ENTRYPOINT
ENTRYPOINT [ "/usr/bin/DockerGrader", "in-container" ]

# Consider running assignments as the user "unprivileged".
RUN adduser --disabled-password --gecos "" unprivileged