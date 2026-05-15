import re

with open("/tmp/source_repo/حقيبة المؤمن/res/drawable/qibla_background.xml", "rb") as f:
    content = f.read()

# Since the xml is compiled binary xml, we look for colors.
# But it's easier to use aapt dump xmltree
