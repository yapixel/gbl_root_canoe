/* SPDX-License-Identifier: BSD-3-Clause */
#include <Uefi.h>
#include <Library/BaseLib.h>
#include <Library/UefiRuntimeServicesTableLib.h>

#include "AtReboot.h"

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(a)  (sizeof (a) / sizeof ((a)[0]))
#endif

VOID
AtRebootDevice (
  IN UINT8 Reason
  )
{
  AT_RESET_DATA ResetData;
  EFI_STATUS    Status;

  Status = (Reason == NORMAL_MODE) ? EFI_SUCCESS : EFI_INVALID_PARAMETER;

  StrnCpyS (ResetData.DataBuffer, ARRAY_SIZE (ResetData.DataBuffer),
            (CONST CHAR16 *)AT_RESET_PARAM, ARRAY_SIZE (AT_RESET_PARAM) - 1);
  ResetData.Bdata = Reason;

  gRT->ResetSystem (EfiResetCold, Status, sizeof (ResetData), &ResetData);
}
