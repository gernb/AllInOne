FROM swift:slim

ADD .build/aarch64-swift-linux-musl/release/server /
ADD public /public

ENTRYPOINT ["/server"]