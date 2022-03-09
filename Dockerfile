##
FROM centos:7 as builder

RUN yum install -y \
	automake libtool flex bison pkgconfig gcc-c++ \
	boost-devel libevent-devel zliyub-devel python-devel ruby-devel openssl-devel \
	wget make git

RUN cd /tmp && \
	wget http://archive.apache.org/dist/thrift/0.8.0/thrift-0.8.0.tar.gz && \
	tar zxvf thrift-0.8.0.tar.gz && \
	cd thrift-0.8.0 && \
	./configure && \
	make

RUN cd /tmp/thrift-0.8.0 && \
	make install

RUN cd /tmp/thrift-0.8.0/contrib/fb303 && \
	./bootstrap.sh && \
	./configure CPPFLAGS="-DHAVE_INTTYPES_H -DHAVE_NETINET_IN_H" && \
	make

RUN cd /tmp/thrift-0.8.0/contrib/fb303 && \
	make install

RUN cd /tmp && \
	git clone https://github.com/facebook/scribe && \
	cd /tmp/scribe && \
	./bootstrap.sh --with-boost-system=boost_system-mt --with-boost-filesystem=boost_filesystem-mt && \
	./configure --with-boost-system=boost_system-mt --with-boost-filesystem=boost_filesystem-mt CPPFLAGS="-DHAVE_INTTYPES_H -DHAVE_NETINET_IN_H" && \
	make

RUN cd /tmp/scribe && \
	make install

RUN cp /tmp/scribe/examples/scribe_* /usr/local/bin/

##
FROM centos:7

RUN yum install -y \
	boost-system boost-filesystem libevent

COPY --from=builder /usr/lib64/python2.7/site-packages/thrift /usr/lib64/python2.7/site-packages/thrift
COPY --from=builder /usr/lib64/python2.7/site-packages/thrift-* /usr/lib64/python2.7/site-packages/
COPY --from=builder /usr/lib/python2.7/site-packages/fb303 /usr/lib/python2.7/site-packages/fb303
COPY --from=builder /usr/lib/python2.7/site-packages/fb303_scripts /usr/lib/python2.7/site-packages/fb303_scripts
COPY --from=builder /usr/lib/python2.7/site-packages/fb303-* /usr/lib/python2.7/site-packages/
COPY --from=builder /usr/lib/python2.7/site-packages/scribe /usr/lib/python2.7/site-packages/scribe
COPY --from=builder /usr/lib/python2.7/site-packages/scribe-* /usr/lib/python2.7/site-packages/
COPY --from=builder /usr/local/bin/* /usr/local/bin/
COPY --from=builder /usr/local/lib/* /usr/local/lib/
RUN cd /usr/local/lib/ && \
	rm libthriftnb.so libthrift.so libthriftz.so && \
	ln -s libthriftnb-0.8.0.so libthriftnb.so && \
	ln -s libthrift-0.8.0.so libthrift.so && \
	ln -s libthriftz-0.8.0.so libthriftz.so
COPY --from=builder /tmp/scribe/examples/scribe_* /usr/local/bin/

RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/scribed.conf && \
	ldconfig

ADD default.conf /etc/scribe/default.conf
RUN mkdir -p /data/lib/scribe/default_primary
RUN mkdir -p /data/lib/scribe/default_secondary

CMD ["/usr/local/bin/scribed", "-c", "/etc/scribe/default.conf"]
