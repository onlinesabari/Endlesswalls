from flask import Flask, send_file, request
from PIL import Image, ImageFont
from pilmoji import Pilmoji
import random
import io

app = Flask(__name__)

def get_font(size):
    """Fetches a standard system font to help pilmoji scale the emojis."""
    try:
        # Standard font available on almost all Ubuntu servers
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except:
        return ImageFont.load_default()

def draw_rotated_emoji(base_img, emoji_char, x, y, size, rotation_style):
    """Draws a single emoji with random scaling and rotation."""
    font = get_font(size)
    
    # 1. Create a transparent temporary box for the emoji
    box_size = int(size * 2.5)
    temp_img = Image.new('RGBA', (box_size, box_size), (0, 0, 0, 0))
    
    # 2. Draw the emoji in the center of the box
    with Pilmoji(temp_img) as pilmoji:
        pilmoji.text((size // 2, size // 2), emoji_char.strip(), fill=(0,0,0), font=font)
        
    # 3. Apply the rotation logic
    angle = 0
    if rotation_style == 'subtle':
        angle = random.randint(-25, 25)
    elif rotation_style == 'crazy':
        angle = random.randint(0, 360)
        
    if angle != 0:
        # Rotate and expand the box so the emoji doesn't get cut off
        temp_img = temp_img.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
        
    # 4. Paste the rotated emoji onto the main wallpaper
    paste_x = x - temp_img.width // 2
    paste_y = y - temp_img.height // 2
    base_img.paste(temp_img, (paste_x, paste_y), temp_img)

@app.route('/api/wallpaper/doodle', methods=['GET'])
def doodle_wallpaper():
    width, height = 1080, 1920
    
    # --- 1. Read the custom blueprint from the Flutter App ---
    # Default to a rocket and stars if the user leaves it blank
    emojis_str = request.args.get('emojis', '🚀,✨,🔥')
    emoji_list = [e for e in emojis_str.split(',') if e]
    
    bg_hex = request.args.get('bg', '0F2027').strip('#')
    density = int(request.args.get('density', 80))
    base_size = int(request.args.get('size', 120))
    rotation_style = request.args.get('rotation', 'crazy')
    
    # --- 2. Create the Canvas ---
    try:
        bg_color = tuple(int(bg_hex[i:i+2], 16) for i in (0, 2, 4))
    except:
        bg_color = (15, 32, 39) # Fallback dark color
        
    image = Image.new("RGB", (width, height), bg_color)
    
    # --- 3. The Scattering Engine ---
    for _ in range(density):
        e = random.choice(emoji_list)
        
        # Allow emojis to slightly bleed off the edge of the screen
        x = random.randint(-50, width + 50)
        y = random.randint(-50, height + 50)
        
        # Randomize size per emoji (some big, some small) for a dynamic look
        size = random.randint(int(base_size * 0.6), int(base_size * 1.4))
        
        draw_rotated_emoji(image, e, x, y, size, rotation_style)

    # --- 4. Send back to the phone ---
    img_io = io.BytesIO()
    image.save(img_io, 'JPEG', quality=85)
    img_io.seek(0)
    
    return send_file(img_io, mimetype='image/jpeg')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)