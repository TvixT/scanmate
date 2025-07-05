#!/usr/bin/env python3
"""
Generate placeholder images for ScanMate branding
This script creates simple colored placeholder images for app icon and splash screens.
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon(size=1024, output_path="assets/icons/app_icon.png"):
    """Create a simple app icon placeholder"""
    # Create image with blue gradient background
    img = Image.new('RGB', (size, size), '#2563EB')
    draw = ImageDraw.Draw(img)
    
    # Draw a simple scanner frame
    margin = size // 8
    draw.rectangle([margin, margin, size-margin, size-margin], 
                  outline='white', width=size//32)
    
    # Draw inner rectangle (business card)
    inner_margin = size // 4
    draw.rectangle([inner_margin, inner_margin*2, size-inner_margin, size-inner_margin], 
                  outline='white', width=size//64)
    
    # Draw some text lines
    line_height = size // 32
    for i in range(3):
        y = inner_margin*2 + line_height + i * line_height * 2
        draw.rectangle([inner_margin + line_height, y, 
                       size - inner_margin - line_height, y + line_height//2], 
                      fill='white')
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created app icon: {output_path}")

def create_splash_icon(size=512, output_path="assets/icons/splash_icon.png"):
    """Create a simple splash screen icon"""
    # Create transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw white scanner icon
    margin = size // 6
    draw.rectangle([margin, margin, size-margin, size-margin], 
                  outline='white', width=size//16)
    
    # Draw inner elements
    inner_margin = size // 3
    draw.rectangle([inner_margin, inner_margin*1.5, size-inner_margin, size-inner_margin*0.7], 
                  outline='white', width=size//32)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created splash icon: {output_path}")

def create_logo(width=300, height=80, output_path="assets/images/scanmate_logo.png"):
    """Create a simple text logo"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Try to use a font, fallback to default
    try:
        font = ImageFont.truetype("arial.ttf", 32)
    except:
        font = ImageFont.load_default()
    
    # Draw text
    text = "ScanMate"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    draw.text((x, y), text, fill='white', font=font)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"Created logo: {output_path}")

if __name__ == "__main__":
    print("Generating ScanMate placeholder branding assets...")
    
    # Create all required assets
    create_app_icon()
    create_splash_icon()
    create_splash_icon(output_path="assets/icons/splash_icon_dark.png")  # Same for dark mode
    create_logo()
    create_logo(output_path="assets/images/scanmate_logo_dark.png")  # Same for dark mode
    
    print("\nPlaceholder assets created successfully!")
    print("In production, replace these with professionally designed graphics.")
