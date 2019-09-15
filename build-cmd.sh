#!/usr/bin/env bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

DISCORD_SOURCE_DIR="discord-rpc-3.4.0"

if [ -z "$AUTOBUILD" ] ; then
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

top="$(pwd)"
build="$(pwd)/build"
stage="$(pwd)/stage"

mkdir -p $build

# load autobuild provided shell functions and variables
source_environment_tempfile="$build/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"


pushd "$build"
    case "$AUTOBUILD_PLATFORM" in

        windows*)
            load_vsvars

            abspath="$(cygpath -aw $(pwd))" # Current absolute path in Windows format
			
			rm -rf *
			
			mkdir -p "$stage/lib/release"
			cmake $abspath/../$DISCORD_SOURCE_DIR -G "${AUTOBUILD_WIN_CMAKE_GEN}"
			cmake --build . --config Release
			cp -a "src/Release/discord-rpc.lib" "$stage/lib/release/discord-rpc.lib"
        ;;

        darwin64)
			rm -rf *
			mkdir -p "$stage/lib/release"
			cmake $top/$DISCORD_SOURCE_DIR
			cmake --build . --config Release
			cp -a "src/libdiscord-rpc.a" "$stage/lib/release/libdiscord-rpc.a"
        ;;

        linux64)
			rm -rf *
			mkdir -p "$stage/lib/release"
			cmake $top/$DISCORD_SOURCE_DIR
			cmake --build . --config Release
			cp -a "src/libdiscord-rpc.a" "$stage/lib/release/libdiscord-rpc.a"
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp $top/$DISCORD_SOURCE_DIR/LICENSE "$stage/LICENSES/discord-rpc.txt"

    mkdir -p "$stage/include/discord-rpc"
    cp -a "$top/$DISCORD_SOURCE_DIR/include/"*.h "$stage/include/discord-rpc"
popd

cp $top/VERSION.txt $stage/VERSION.txt
