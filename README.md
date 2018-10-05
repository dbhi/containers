# Dynamic Binary Hardware Injection (DBHI)

This repository contains containerized open and free development tools for decoupled functional hardware-software co-design on SoCs with FPGA, through injection of compiled HDL designs using binary modification.

---

[docker/cli#954](https://github.com/docker/cli/issues/954):

``` bash
docker push aptman/dbhi:bionic-dr-amd64
docker manifest push --purge aptman/dbhi:bionic-dr
docker manifest create -a aptman/dbhi:bionic-dr aptman/dbhi:bionic-dr-amd64
```

``` bash
docker push aptman/dbhi:bionic-aarch64
docker manifest push --purge aptman/dbhi:bionic
docker manifest create -a aptman/dbhi:bionic aptman/dbhi:bionic-amd64 aptman/dbhi:bionic-aarch64

docker push aptman/dbhi:bionic-mambo-aarch64
docker manifest push --purge aptman/dbhi:bionic-mambo
docker manifest create -a aptman/dbhi:bionic-mambo aptman/dbhi:bionic-mambo-aarch64
```
