import struct, sys

path = r'C:\Windows\Minidump\080626-5812-01.dmp'
data = open(path, 'rb').read()

sig, ver = struct.unpack_from('<II', data, 0)
print(f'Signature: {sig} (magic {"MDMP" if sig == 0x504d444d else "??"})  Version: {ver >> 16}.{ver & 0xFFFF}')

nstreams, sdir_rva = struct.unpack_from('<II', data, 8)
print(f'Streams: {nstreams}  DirRVA: 0x{sdir_rva:X}')
print(f'TimeDateStamp: {struct.unpack_from("<I", data, 0x18)[0]}  Flags: 0x{struct.unpack_from("<I", data, 0x1C)[0]:x}')

strname = {
    0: 'UnusedStream', 1: 'ReservedStream0', 2: 'ReservedStream1', 3: 'ThreadListStream',
    4: 'ModuleListStream', 5: 'MemoryListStream', 6: 'ExceptionStream', 7: 'SystemInfoStream',
    8: 'ThreadExListStream', 9: 'Memory64ListStream', 10: 'CommentStreamA', 11: 'CommentStreamW',
    12: 'HandleDataStream', 13: 'FunctionTableStream', 14: 'UnloadedModuleListStream',
    15: 'MiscInfoStream', 16: 'MemoryInfoListStream', 17: 'ThreadInfoListStream',
    0x405: 'PhysicalMemory', 0xC0: 'KernelCrashData', 0x3E: 'LastReservedStream',
}

for i in range(nstreams):
    typ, size, rva = struct.unpack_from('<III', data, sdir_rva + i*12)
    label = strname.get(typ, f'0x{typ:x}')
    extra = ''
    if typ == 6:  # ExceptionStream -> ExceptionCode offset
        code = struct.unpack_from('<I', data, rva + 24)[0]
        extra = f' BUGCHECK=0x{code:08X}'
        # ExceptionAddress at rva+16
        addr = struct.unpack_from('<Q', data, rva + 32)[0]
        extra += f' Addr=0x{addr:X}'
    if typ == 7:  # SystemInfo
        proc_arch = struct.unpack_from('<H', data, rva)[0]
        extra = f' arch={proc_arch}'
    print(f'  [{i}] {label}: size=0x{size:X} rva=0x{rva:X}{extra}')