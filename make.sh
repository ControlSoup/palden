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

cp palden /home/jowilson/palden_sshfs/mount/home/palden/
echo "Copied to /home/jowilson/palden_sshfs/mount/home/palden/"

if [ ! -f "/home/jowilson/palden_sshfs/mount/home/palden/install_deps.sh" ]; then
    cp install_deps.sh /home/jowilson/palden_sshfs/mount/home/palden/
    echo "Copied install_deps.sh"
fi

mkdir -p /home/jowilson/palden_sshfs/mount/home/palden/config
mkdir -p /home/jowilson/palden_sshfs/mount/home/palden/data
cp -n config/data_info.json /home/jowilson/palden_sshfs/mount/home/palden/config/ 2>/dev/null || true
