import sys
import struct

def parse_res(file_path):
    with open(file_path, "rb") as f:
        data = f.read()

    colors = []
    for i in range(len(data) - 4):
        # look for AARRGGBB pattern where AA is FF usually
        val = struct.unpack('<I', data[i:i+4])[0]
        if val >= 0xFF000000 and val <= 0xFFFFFFFF:
            colors.append(hex(val))
    print(set(colors))

parse_res("/tmp/source_repo/حقيبة المؤمن/res/drawable/qibla_background.xml")
