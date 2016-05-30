#!/bin/bash

packages=(
  'pm:fortune-mod'
)

install() {
    fortune

    return 0;
}
