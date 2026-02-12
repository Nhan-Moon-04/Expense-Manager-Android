"""Generate a simple admin app icon - indigo/dark blue background with shield + gear icon"""
from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Background - rounded square with gradient-like effect (indigo)
# Main background
bg_color = (55, 71, 133)  # Indigo/dark blue
accent_color = (99, 120, 255)  # Lighter indigo accent

# Draw rounded rectangle background
radius = 200
draw.rounded_rectangle([0, 0, SIZE-1, SIZE-1], radius=radius, fill=bg_color)

# Draw a subtle lighter circle in center for depth
center = SIZE // 2
draw.ellipse([center-380, center-380, center+380, center+380], fill=(65, 82, 148))
draw.ellipse([center-300, center-300, center+300, center+300], fill=(75, 92, 158))

# Draw shield shape
shield_top = 180
shield_bottom = 760
shield_width = 280
shield_cx = center

# Shield outline points
shield_points = [
    (shield_cx - shield_width, shield_top),
    (shield_cx + shield_width, shield_top),
    (shield_cx + shield_width, shield_top + 300),
    (shield_cx, shield_bottom),
    (shield_cx - shield_width, shield_top + 300),
]
draw.polygon(shield_points, fill=(255, 255, 255, 50))

# Inner shield (white, slightly smaller)
inner_offset = 25
inner_points = [
    (shield_cx - shield_width + inner_offset, shield_top + inner_offset),
    (shield_cx + shield_width - inner_offset, shield_top + inner_offset),
    (shield_cx + shield_width - inner_offset, shield_top + 285),
    (shield_cx, shield_bottom - 30),
    (shield_cx - shield_width + inner_offset, shield_top + 285),
]
draw.polygon(inner_points, fill=(255, 255, 255, 40))

# Draw gear/cog symbol in center of shield
gear_cx, gear_cy = center, center + 40
gear_outer = 160
gear_inner = 110
teeth = 8

# Draw gear teeth
for i in range(teeth):
    angle = (2 * math.pi * i) / teeth
    angle2 = angle + math.pi / teeth * 0.6
    angle1 = angle - math.pi / teeth * 0.6
    
    x1 = gear_cx + gear_inner * math.cos(angle1)
    y1 = gear_cy + gear_inner * math.sin(angle1)
    x2 = gear_cx + gear_outer * math.cos(angle1)
    y2 = gear_cy + gear_outer * math.sin(angle1)
    x3 = gear_cx + gear_outer * math.cos(angle2)
    y3 = gear_cy + gear_outer * math.sin(angle2)
    x4 = gear_cx + gear_inner * math.cos(angle2)
    y4 = gear_cy + gear_inner * math.sin(angle2)
    
    draw.polygon([(x1,y1),(x2,y2),(x3,y3),(x4,y4)], fill='white')

# Gear body circle
draw.ellipse([gear_cx-gear_inner, gear_cy-gear_inner, gear_cx+gear_inner, gear_cy+gear_inner], fill='white')
# Gear center hole
draw.ellipse([gear_cx-55, gear_cy-55, gear_cx+55, gear_cy+55], fill=bg_color)
# Inner dot
draw.ellipse([gear_cx-20, gear_cy-20, gear_cx+20, gear_cy+20], fill='white')

# Draw "A" letter on top of shield
try:
    font = ImageFont.truetype("arial.ttf", 140)
except:
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 140)
    except:
        font = ImageFont.load_default()

# "A" above the gear
bbox = draw.textbbox((0, 0), "A", font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
draw.text((center - tw//2, shield_top + 20), "A", fill='white', font=font)

# Save
img.save("d:/Expense Manager Android/expense_manager_android/Admin/admin/assets/icon/app_icon.png")
print("Icon generated!")
