#!/bin/sh

CC='gcc -std=c11'
CXX='g++ -std=c++11'
FLAGS='-I.  -I./examples -D_WIN32_WINNT=0x0601 -DBOOST_THREAD_USE_LIB -DBOOST_ALL_NO_LIB -DBOOST_USE_WINDOWS_H -DWIN32_LEAN_AND_MEAN -DNOMINMAX -ffast-math -fomit-frame-pointer -flto -flto-partition=none -fno-devirtualize -ftree-vectorize -fgraphite -fgraphite-identity -fPIC'
LDFLAGS="-static -pthread -lboost_thread -lboost_date_time -lboost_system"
if [ "x${DEBUG}" = "x1" ]; then
	FLAGS="${FLAGS} -Og -g3 -ggdb -gdwarf-3 -fno-omit-frame-pointer -fvar-tracking-assignments"
else
	FLAGS="${FLAGS} -O3 -DNDEBUG"
	LDFLAGS="${LDFLAGS} -s"
fi

function error()
{
	echo "Error: $*" >&2
	exit 1
}

function vExec()
{
	echo "$@"
	eval "$@"
	return $?
}

scripts/build-info.sh >build-info.h || error 'Failed creating build-info.h.'
for target in ivybridge haswell knl cannonlake icelake-client znver4
do
	vExec $CC $FLAGS -mtune=${target} -march=${target} -c -o ggml.o ggml.c || error 'Failed compiling ggml.c.'
	vExec $CXX $FLAGS -mtune=${target} -march=${target} -c -o llama.o llama.cpp || error 'Failed compiling llama.cpp.'
	vExec $CXX $FLAGS -mtune=${target} -march=${target} -c -o common.o examples/common.cpp || error 'Failed compiling common.cpp.'
	vExec $CXX $FLAGS -mtune=${target} -march=${target} -c -o main.o examples/main/main.cpp || error 'Failed compiling main.cpp.'
	vExec $CXX $FLAGS -mtune=${target} -march=${target} -o chat-${target}.exe main.o common.o llama.o ggml.o $LDFLAGS || error 'Failed linking chat-${target}.exe.'
done
exit 0
