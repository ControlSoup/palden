#!/bin/bash
clear && zig build && mv zig-out/bin/palden run/ && rm -rf zig-out/
