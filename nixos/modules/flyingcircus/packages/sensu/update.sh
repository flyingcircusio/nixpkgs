#!/bin/sh
rm -f Gemfile.lock
rm -rf /tmp/bundix
nix-shell -p git -p stdenv -p cacert -p bundler -p openssl --command "bundler package --no-install --path /tmp/bundix/bundle"
nix-shell -p bundix --command bundix