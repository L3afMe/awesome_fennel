# AwesomeWM Fennel Config

Default AwesomeWM config rewritten in [Fennel](https://github.com/bakpakin/Fennel/)

# How to use

## Prerequisites

- [Fennel](https://github.com/bakpakin/Fennel/)
- [AwesomeWM](https://awesomewm.org)

## Steps

1) Backup current config (optional)
```sh
mv $XDG_CONFIG_DIRS/awesome/ $XDG_CONFIG_DIRS/awesome.bak/
```

2) Compile and move fennel
```sh
mkdir $XDG_CONFIG_DIRS/awesome/
fennel --compile ./rc.fnl > $XDG_CONFIG_DIRS/awesome/rc.lua
```

3) Make your own config written in this cool language :D

