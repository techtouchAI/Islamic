def create_icon_svg():
    gold = "#D4AF37"
    bg = "#1A1A1A"
    return f"""<svg width="512" height="512" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <rect width="100" height="100" rx="20" fill="{bg}"/>
      <path d="M20,65 Q50,15 80,65 L80,85 L20,85 Z" fill="{gold}"/>
      <rect x="47" y="12" width="6" height="15" fill="{gold}"/>
      <circle cx="50" cy="8" r="4" fill="{gold}"/>
      <path d="M40,45 Q50,35 60,45" stroke="{gold}" fill="none" stroke-width="2"/>
    </svg>"""

with open("religious_icon.svg", "w") as f:
    f.write(create_icon_svg())
print("Generated religious_icon.svg")
