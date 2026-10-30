#!/bin/sh
set -eu
test_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_tmp=$(mktemp -d)
trap 'rm -f "$test_tmp/menu_input_test" "$test_tmp/fastboot_input.inc" "$test_tmp/tools_input.inc" "$test_tmp/sfb_entries.inc" "$test_tmp/sfb_menu.inc" "$test_tmp/sfb_fat.inc"; rmdir "$test_tmp"' EXIT HUP INT TERM
awk '
  /^FastbootPollActionKey \(/ { print "STATIC FB_ACTION"; emit = 1 }
  emit { print }
  /^}/ { emit = 0 }
' "$test_root/edk2/QcomModulePkg/Library/FastbootLib/FastbootMain.c" > "$test_tmp/fastboot_input.inc"
awk '
  /^AtUiWaitForKey \(/ { print "AT_KEY"; emit = 1 }
  emit { print }
  /^}/ { emit = 0 }
' "$test_root/edk2/AndroidToolsPkg/Library/AndroidToolsUi/AndroidToolsUi.c" > "$test_tmp/tools_input.inc"
awk '
  /^SfbAppendBuiltIn \(/ { print "STATIC VOID"; emit = 1 }
  /^SfbBuildMenu \(/ { print "VOID"; emit = 1 }
  emit { print }
  /^}/ { emit = 0 }
' "$test_root/edk2/QcomModulePkg/Application/LinuxLoader/SuperFbEntries.c" > "$test_tmp/sfb_entries.inc"
awk '
  /^SfbWaitForKey \(/ { print "SFB_KEY"; emit = 1 }
  /^SfbMoveCursor \(/ { print "VOID"; emit = 1 }
  /^SfbRunBootMenu \(/ { print "BOOLEAN"; emit = 1 }
  emit { print }
  /^}/ { emit = 0 }
' "$test_root/edk2/QcomModulePkg/Application/LinuxLoader/SuperFbMenu.c" > "$test_tmp/sfb_menu.inc"
awk '
  /^STATIC EFI_GUID mSfbDriverTagGuid/ { emit = 1 }
  /^STATIC BOOLEAN mSfbFatStackStarted/ { print; next }
  /^SfbCreateDriverHandle \(/ { print "STATIC EFI_STATUS"; emit = 1 }
  /^SfbFatStackAlreadyPresent \(/ { print "BOOLEAN"; emit = 1 }
  /^SfbStartFatStack \(/ { print "EFI_STATUS"; emit = 1 }
  emit { print }
  /^};$/ || /^}$/ { emit = 0 }
' "$test_root/edk2/QcomModulePkg/Application/LinuxLoader/SuperFbFat.c" > "$test_tmp/sfb_fat.inc"
case $(uname -m) in
  arm64|aarch64) test_arch=AArch64 ;;
  x86_64) test_arch=X64 ;;
  *) echo 'Unsupported host architecture' >&2; exit 1 ;;
esac
"${CC:-clang}" -fshort-wchar -DNO_MSABI_VA_FUNCS -Wall -Wextra -Werror \
  -Wno-unused-parameter -fsanitize=address,undefined -O1 \
  -I "$test_root/edk2/MdePkg/Include" \
  -I "$test_root/edk2/MdePkg/Include/$test_arch" \
  -I "$test_root/edk2/AndroidToolsPkg/Include" \
  -I "$test_root/edk2/QcomModulePkg/Application/LinuxLoader" \
  -I "$test_tmp" \
  "$test_root/tests/menu_input_test.c" -o "$test_tmp/menu_input_test"
"$test_tmp/menu_input_test"
