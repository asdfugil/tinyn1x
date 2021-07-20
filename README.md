# tinyn1x
Tiny (< 10 MB) checkra1n boot disk (WIP).

# Bulding
Debian:
1. Inatall dependencies

```
sudo apt build-dep linux-source
sudo apt install mkisofs syslinux-utils wget
```

2. Modify variables at top of build.sh if needed.
3. Build!

```
sudo build.sh
```

The generated boot image is at `boot.iso`
