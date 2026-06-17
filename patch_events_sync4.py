import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

# Let's cleanly remove the "Today's Events (Top)" section and its variables
# The variables first:
start_idx_vars = content.find("    // Top Section logic")
end_idx_vars = content.find("    // Bottom Section logic", start_idx_vars)
if start_idx_vars != -1 and end_idx_vars != -1:
    content = content[:start_idx_vars] + content[end_idx_vars:]

# Now the block itself
start_idx_block = content.find("          // Today's Events (Top)")
end_idx_block = content.find("          // Calendar Grid", start_idx_block)
if start_idx_block != -1 and end_idx_block != -1:
    content = content[:start_idx_block] + content[end_idx_block:]

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
