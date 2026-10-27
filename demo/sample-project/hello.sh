#!/usr/bin/env bash
# The "project". It isn't the point.
echo "Hello from $(where-am-i 2>/dev/null || echo 'a container with no dotfiles')"
