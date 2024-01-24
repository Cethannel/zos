#!/bin/bash

if grub-file --is-x86-multiboot zig-out/bin/zig-os; then
  echo multiboot confirmed
else
  echo the file is not multiboot
fi
