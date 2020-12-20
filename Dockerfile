ARG     BASE_IMG=alpine:latest
ARG	FINAL_IMG=busybox:latest

FROM    $BASE_IMG AS base

RUN     apk --update --no-cache upgrade



FROM    base as mdevd

RUN	apk -U --no-cache add \
	build-base \
	skalibs-dev \
	linux-headers \
	git

WORKDIR	/mdevd

RUN	git clone https://github.com/skarnet/mdevd /mdevd

RUN	./configure

RUN	make strip

RUN	make

RUN     strip /mdevd/mdevd-coldplug
RUN     strip /mdevd/mdevd

RUN	mkdir -p /mnt/usr/local/sbin /mnt/lib

RUN	cp -a /mdevd/mdevd /mdevd/mdevd-coldplug /mnt/usr/local/sbin/

RUN	cp -a /lib/libskarnet* /mnt/lib/



FROM    base AS mdev-like-a-boss

RUN	apk -U --no-cache add \
	git

RUN	git clone https://github.com/slashbeast/mdev-like-a-boss.git /mdev-like-a-boss

RUN	mkdir -p /mnt/opt/mdev /mnt/etc 

RUN	cp -a /mdev-like-a-boss/helpers /mnt/opt/mdev

RUN	cp -a /mdev-like-a-boss/mdev.conf /mnt/etc/

### fix mdevd helper readonly filesystem
RUN	sed -i 's|-SUBSYSTEM=net;DEVPATH=.*/net/.*;.*     root:root 600 @/opt/mdev/helpers/settle-nics --write-mactab|-SUBSYSTEM=net;DEVPATH=.*/net/.*;.*     root:root 600 @/opt/mdev/helpers/settle-nics|' /mnt/etc/mdev.conf
RUN	sed -i 's|sleep 1|break|' /mnt/opt/mdev/helpers/settle-nics
#RUN	sed -i 's|/etc/mactab.settle-nics_lockfile|/run/mactab.settle-nics_lockfile|g' /mnt/opt/mdev/helpers/settle-nics
#RUN	sed -i 's|/etc/mactab.settle-nics_tmpfile|/run/mactab.settle-nics_tmpfile|g' /mnt/opt/mdev/helpers/settle-nics
#RUN	sed -i '55 s/.*/touch $lockfile/' /mnt/opt/mdev/helpers/settle-nics
#RUN	sed -i '56,61 s/.*//' /mnt/opt/mdev/helpers/settle-nics


FROM    base

COPY	--from=mdevd /mnt/ /
COPY	--from=mdev-like-a-boss /mnt/ /
COPY	files/ /

ENTRYPOINT	[ "/usr/local/sbin/mdev.sh" ]

# docker run --name mdevd -dti --privileged -v /dev:/dev -v /lib/modules:/lib/modules -v /lib/firmware:/lib/firmware dengleros/mdevd
