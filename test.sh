# Env vars might or might not be necessary on your system, but mine is a little janky and this worked
# worked without jankifying the source code.
C_INCLUDE_PATH=/usr/local/include/libxml2 LD_LIBRARY_PATH=/usr/local/lib zig build
