def create_svg(size):
    gold = "#D4AF37"
    bg = "#141414"
    svg = f"""<svg width="{size}" height="{size}" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <rect width="100" height="100" fill="{bg}"/>
      <path d="M20,60 Q50,20 80,60 L80,85 L20,85 Z" fill="{gold}"/>
      <rect x="47" y="10" width="6" height="20" fill="{gold}"/>
      <circle cx="50" cy="10" r="4" fill="{gold}"/>
    </svg>"""
    return svg

# Just for documentation or if needed as drawable-v24
print(create_svg(512))
