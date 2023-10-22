FROM golang:1.21 as build

WORKDIR /go/src/app

RUN git clone --depth=1 https://github.com/golang/pkgsite.git . && \
    mkdir -p bin

ENV CGO_ENABLED=0

RUN GOBIN=/go/src/app/bin go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

RUN go build -o bin/frontend ./cmd/frontend/main.go && \
    go build -o bin/seeddb ./devtools/cmd/seeddb/main.go && \
    go build -o bin/db ./devtools/cmd/db/main.go

RUN apt-get update && apt-get install git

RUN mv `git --exec-path` /git-exec

RUN mv /usr/bin/git* ./bin


# for development purposes: find location of git dynamically linked
# dependencies
# RUN ldd bin/git
# RUN ldd /git-exec/git-remote-https | grep -Po '(/lib/x86_64[^ ]+)'

# debug distroless includes busybox shell. Currently required to interpolate
# database connection string from secret when running migrations.
FROM gcr.io/distroless/base-debian12:debug
#FROM golang:1.21

WORKDIR /app

COPY --from=build /go/src/app/ /app

# git sub programs
COPY --from=build /git-exec /git-exec

ENV GIT_EXEC_PATH=/git-exec

COPY --from=build /usr/share/git-core /usr/share/git-core

# git & git-remote-https dynamic libs
COPY --from=build \
    /lib/x86_64-linux-gnu/libcurl-gnutls.so.4 \ 
    /lib/x86_64-linux-gnu/libpcre2-8.so.0 \ 
    /lib/x86_64-linux-gnu/libz.so.1 \ 
    /lib/x86_64-linux-gnu/libc.so.6 \ 
    /lib/x86_64-linux-gnu/libnghttp2.so.14 \ 
    /lib/x86_64-linux-gnu/libidn2.so.0 \ 
    /lib/x86_64-linux-gnu/librtmp.so.1 \ 
    /lib/x86_64-linux-gnu/libssh2.so.1 \ 
    /lib/x86_64-linux-gnu/libpsl.so.5 \ 
    /lib/x86_64-linux-gnu/libnettle.so.8 \ 
    /lib/x86_64-linux-gnu/libgnutls.so.30 \ 
    /lib/x86_64-linux-gnu/libgssapi_krb5.so.2 \ 
    /lib/x86_64-linux-gnu/libldap-2.5.so.0 \ 
    /lib/x86_64-linux-gnu/liblber-2.5.so.0 \ 
    /lib/x86_64-linux-gnu/libzstd.so.1 \ 
    /lib/x86_64-linux-gnu/libbrotlidec.so.1 \ 
    /lib/x86_64-linux-gnu/libunistring.so.2 \ 
    /lib/x86_64-linux-gnu/libhogweed.so.6 \ 
    /lib/x86_64-linux-gnu/libgmp.so.10 \ 
    /lib/x86_64-linux-gnu/libcrypto.so.3 \ 
    /lib/x86_64-linux-gnu/libp11-kit.so.0 \ 
    /lib/x86_64-linux-gnu/libtasn1.so.6 \ 
    /lib/x86_64-linux-gnu/libkrb5.so.3 \ 
    /lib/x86_64-linux-gnu/libk5crypto.so.3 \ 
    /lib/x86_64-linux-gnu/libcom_err.so.2 \ 
    /lib/x86_64-linux-gnu/libkrb5support.so.0 \ 
    /lib/x86_64-linux-gnu/libsasl2.so.2 \ 
    /lib/x86_64-linux-gnu/libbrotlicommon.so.1 \ 
    /lib/x86_64-linux-gnu/libffi.so.8 \ 
    /lib/x86_64-linux-gnu/libkeyutils.so.1 \ 
    /lib/x86_64-linux-gnu/libresolv.so.2 \ 
    /lib/x86_64-linux-gnu

ENV PATH="${PATH}:/app/bin"

ENTRYPOINT ["frontend"]



