/* SPDX-License-Identifier: BSD-3-Clause */
#ifndef __AT_REBOOT_LIB_H__
#define __AT_REBOOT_LIB_H__

#include <Uefi.h>

VOID
AtRebootDevice (
  IN UINT8 Reason
  );

#endif
