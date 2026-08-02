// IOCTL codes + struct layouts shared with the Rust userland.
// MUST match ../../user/src/ioctl.rs byte-for-byte.
// Both sides use fixed-layout (repr(C) / #pragma pack) -- no padding surprises.

#pragma once

#include <ntddk.h>

//
// CTL_CODE(DeviceType, Function, Method, Access):
//   (DeviceType << 16) | (Access << 14) | (Function << 2) | Method
//
// DeviceType = FILE_DEVICE_UNKNOWN (0x22), Method = METHOD_BUFFERED (0), Access = FILE_ANY_ACCESS (0).
//

#define IOCTL_KFM_ATTACH        CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_KFM_READ          CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_KFM_WRITE         CTL_CODE(FILE_DEVICE_UNKNOWN, 0x802, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_KFM_MODULE_BASE   CTL_CODE(FILE_DEVICE_UNKNOWN, 0x803, METHOD_BUFFERED, FILE_ANY_ACCESS)

#pragma pack(push, 1)

typedef struct _KFM_ATTACH_IN {
    ULONG pid;
} KFM_ATTACH_IN, *PKFM_ATTACH_IN;

typedef struct _KFM_READ_IN {
    ULONG64 addr;
    ULONG   size;
    ULONG   _pad;   // matches Rust's explicit _pad for stable 16-byte layout
} KFM_READ_IN, *PKFM_READ_IN;
// output = `size` bytes of raw data.

typedef struct _KFM_WRITE_IN {
    ULONG64 addr;
    ULONG   size;
    ULONG   _pad;
    // followed by `size` bytes of raw data in the SAME input buffer.
} KFM_WRITE_IN, *PKFM_WRITE_IN;

typedef struct _KFM_MODULE_IN {
    CHAR name[64];   // ASCII, NUL-terminated. case-insensitive match.
} KFM_MODULE_IN, *PKFM_MODULE_IN;

typedef struct _KFM_MODULE_OUT {
    ULONG64 base;
    ULONG64 size;
} KFM_MODULE_OUT, *PKFM_MODULE_OUT;

#pragma pack(pop)
