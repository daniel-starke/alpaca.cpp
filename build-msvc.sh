#!/bin/sh
# https://quasar.ugent.be/files/doc/cuda-msvc-compatibility.html

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

CC='clang --target=x86_64-pc-windows-msvc -fms-runtime-lib=static'
CXX='clang++ --target=x86_64-pc-windows-msvc -fms-runtime-lib=static'
FLAGS="-I. -I./examples -D_WIN32_WINNT=0x0601 -D_WIN32_WINNT_WIN8=0x0602 -DBOOST_THREAD_USE_LIB -DBOOST_ALL_NO_LIB -DBOOST_USE_WINDOWS_H -D_CRT_SECURE_NO_WARNINGS -DWIN32_LEAN_AND_MEAN -DNOMINMAX -Dsnprintf=_snprintf -ffast-math"
LDFLAGS="-fuse-ld=lld -llibboost_thread -llibboost_date_time -llibboost_system"
if [ "x${CUBLAS}" = "x1" ]; then
	cd "${CUDA_PATH}" || error "CUDA_PATH not found."
	CUDA_PATH2=$(pwd -L)
	cd -
	FLAGS="${FLAGS} -DGGML_USE_CUBLAS -DGGML_CUDA_DMMV_X=32 -DGGML_CUDA_DMMV_Y=1"
	NVCC="${CUDA_PATH2}/bin/nvcc.exe"
	LDFLAGS="${LDFLAGS} '-L${CUDA_PATH2}/lib/x64' -lcudart_static -lcublas"
fi
if [ "x${DEBUG}" = "x1" ]; then
	FLAGS="${FLAGS} -O0 -DNDEBUG -g -gcodeview -gno-column-info -fno-omit-frame-pointer"
else
	FLAGS="${FLAGS} -O3 -DNDEBUG -fomit-frame-pointer"
fi

scripts/build-info.sh >build-info.h || error 'Failed creating build-info.h.'
for target in ivybridge haswell
do
	if [ "x${CUBLAS}" = "x1" ]; then
		vExec "'$NVCC'" -ccbin "'D:\Program Files\Microsoft Visual Studio 10.0\VC\bin\amd64\cl.exe'" -Xcompiler -wd4819 -use_fast_math -m64 -O3 -arch=compute_61 -I. -c -o ggml-cuda.o ggml-cuda.cu || error 'Failed compiling ggml-cuda.cu.'
	fi
	vExec $CC -std=c11 $FLAGS -mtune=${target} -march=${target} -c -o ggml.o ggml.c || error 'Failed compiling ggml.c.'
	vExec $CXX -std=c++11 $FLAGS -mtune=${target} -march=${target} -c -o llama.o llama.cpp || error 'Failed compiling llama.cpp.'
	vExec $CXX -std=c++11 $FLAGS -mtune=${target} -march=${target} -c -o common.o examples/common.cpp || error 'Failed compiling common.cpp.'
	vExec $CXX -std=c++11 $FLAGS -mtune=${target} -march=${target} -c -o main.o examples/main/main.cpp || error 'Failed compiling main.cpp.'
	if [ "x${CUBLAS}" = "x1" ]; then
		vExec $CXX $FLAGS -mtune=${target} -march=${target} -o chat-${target}-msvc-cublas.exe main.o common.o llama.o ggml.o ggml-cuda.o $LDFLAGS || error 'Failed linking chat-${target}-msvc-cublas.exe.'
	else
		vExec $CXX $FLAGS -mtune=${target} -march=${target} -o chat-${target}-msvc.exe main.o common.o llama.o ggml.o $LDFLAGS || error 'Failed linking chat-${target}-msvc.exe.'
	fi
done
exit 0
