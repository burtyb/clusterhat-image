# Cluster HAT

Scripts and files used to build Cluster HAT images from Raspbian.

## Building Cluster HAT Images

The build script is located in the build directory.

The following is normally ran as root on a fresh Raspbian images.

```
git clone https://github.com/burtyb/clusterhat-image
cd clusterhat-image/build/
# Edit config-local.sh (based on config.sh) to override file locations
./create 2017-09-07
```

## Cluster HAT Files

The files/ directory contains the files extracted into the root filesystem of a Cluster HAT image.

For support contact: https://secure.8086.net/billing/submitticket.php?step=2&deptid=1

