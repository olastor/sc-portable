#!/bin/bash

set -e

export COSMO_GIT_REF=$(cat .redbean-version)
git clone https://github.com/jart/cosmopolitan.git
cd cosmopolitan
git checkout $COSMO_GIT_REF
# enable FTS5
sed -i 's/^THIRD_PARTY_SQLITE3_FLAGS =/THIRD_PARTY_SQLITE3_FLAGS = -DSQLITE_ENABLE_FTS5/g' third_party/sqlite3/sqlite3.mk
sudo sh -c "echo ':APE:M::MZqFpD::/bin/sh:' >/proc/sys/fs/binfmt_misc/register"
make -j8 o//tool/net/redbean.com >> build.log 2>&1
mv build.log ..
mv o/tool/net ../binaries
