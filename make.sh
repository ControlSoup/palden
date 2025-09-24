#!/bin/bash
clear && zig build --release=fast && mv zig-out/bin/palden . && rm -rf zig-out/
