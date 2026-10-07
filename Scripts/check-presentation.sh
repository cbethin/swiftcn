#!/usr/bin/env bash
set -euo pipefail

if [[ "${CI:-}" == "true" ]]; then
  swiftcn_keyboard_mode="$(defaults read -g AppleKeyboardUIMode 2>/dev/null || true)"
  restore_keyboard_mode() {
    if [[ -n "$swiftcn_keyboard_mode" ]]; then
      defaults write -g AppleKeyboardUIMode -int "$swiftcn_keyboard_mode"
    else
      defaults delete -g AppleKeyboardUIMode
    fi
  }
  trap restore_keyboard_mode EXIT
  defaults write -g AppleKeyboardUIMode -int 3
fi

swift test --filter PresentationAndScrollingTests
