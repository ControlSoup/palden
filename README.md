# Pre-Reqs

### I2C
```
sudo apt-get install i2c-tools
```

Get i2c address info
```
sudo i2cdetect -y 1
```

### Zig
All the source code is written in zig, using existing kernel libraries with C interop to interface with gpio
I used version
```
https://ziglang.org/learn/getting-started/#direct
```



