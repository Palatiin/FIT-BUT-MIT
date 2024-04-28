# KRY - Project 2 - MAC Using SHA-256 & Length Extension Attack

---
**Author**: Matúš Remeň (xremen01@stud.fit.vutbr.cz)\
**Academic year**: 2023/2024
---

## Description

This project implements SHA-256 algorithm according to the [NIST FIPS 180-4 standard](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf).
Accordingly, it provides options to use it for calculating hash of a message, calculating simple MAC (Message
Authentication Code) of a message, verifying MAC of a message, and executing length extension attack.

## Usage
Compilation:
```bash
make
```

Run, and print usage options:
```
./kry

Usage:
  ./kry [OPTIONS]

Description:
  All outputs are printed on STDOUT.

  Available options:
  -c      Calculate, and print SHA-256 checksum of a message on STDIN.
  -s      Calculate, and print MAC of a message on STDIN. Requires -k KEY.
  -v      Verify MAC of a message on STDIN. Requires -k KEY, and -m CHS.
  -e      Execute length extension attack. Requires -m CHS, -n NUM, -a MSG.

  Additional options:
  -k KEY  Specify private key for MAC calculation.
  -m CHS  Specify MAC of an input message.
  -n NUM  Specify length of private key.
  -a MSG  Specify length extension of an input message.
```

## Directory structure

- `README.md`
- `Makefile` - compilation, and packing
- `kry.cpp` - main, argument parsing, validation, and execution of the functions
- `sha256.cpp` - implementation of SHA-256 algorithm, and message block parsing/padding
- `sha256.hpp` - header file for SHA-256 implementation

## Other
Tested on docker image `ubuntu:jammy` with this additional setup:
```bash
apt update -yqq && apt upgrade -yqq
apt install -yqq build-essential
```
Although, sanitizers sometimes raise `AddressSanitizer:DEADLYSIGNAL` errors, cca every 5th run.

Testing on the school server `merlin` without sanitizers was without any issues.
