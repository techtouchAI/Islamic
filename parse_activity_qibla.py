import sys

def parse_strings(file_path):
    with open(file_path, "rb") as f:
        data = f.read()
    strings = []
    current_str = []
    for byte in data:
        if byte >= 32 and byte <= 126:
            current_str.append(chr(byte))
        else:
            if len(current_str) >= 4:
                strings.append("".join(current_str))
            current_str = []
    for s in strings:
        print(s)

parse_strings("/tmp/source_repo/حقيبة المؤمن/res/layout/activity_qibla.xml")
