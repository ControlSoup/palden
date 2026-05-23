#!/bin/bash
clear

# Copy wiringPi library if not present
if [ ! -f "libwiringPi.so" ]; then
    echo "Copying libwiringPi.so..."
    cp /home/jowilson/palden_sshfs/mount/usr/lib/libwiringPi.so .
fi

case "$1" in
    debug|-d)
        zig build && mv zig-out/bin/palden . && rm -rf zig-out/
        ;;
    safe|-s)
        zig build --release=safe && mv zig-out/bin/palden . && rm -rf zig-out/
        ;;
    small|-z)
        zig build --release=small && mv zig-out/bin/palden . && rm -rf zig-out/
        ;;
    *)
        zig build --release=fast && mv zig-out/bin/palden . && rm -rf zig-out/
        ;;
esac
