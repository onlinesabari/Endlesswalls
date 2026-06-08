from flask import Flask, send_file, request
from PIL import Image, ImageDraw
import numpy as np
from scipy.spatial import Voronoi
from perlin_noise import PerlinNoise
import random
import io
import colorsys

app = Flask(__name__)

# --- Color Theory Engine ---
def generate_harmonious_palette(num_colors=4, base_hue=None):
    """Generates a palette. If base_hue is provided (0.0 to 1.0), it uses it!"""
    if base_hue is None:
        base_hue = random.random()
        
    palette = []
    for i in range(num_colors):
        hue = (base_hue + (i * 0.15)) % 1.0
        sat = random.uniform(0.6, 1.0)
        val = random.uniform(0.8, 1.0)
        r, g, b = colorsys.hsv_to_rgb(hue, sat, val)
        palette.append((int(r * 255), int(g * 255), int(b * 255)))
    return palette

# --- Generative Algorithms ---

def generate_wave_interference(width, height, base_hue=None):
    y, x = np.mgrid[0:height, 0:width]
    f1, f2, f3 = random.uniform(0.01, 0.05), random.uniform(0.01, 0.05), random.uniform(0.005, 0.02)
    z = np.sin(x * f1) + np.cos(y * f2) + np.sin(np.sqrt(x**2 + y**2) * f3)
    z = (z - z.min()) / (z.max() - z.min())
    
    palette = generate_harmonious_palette(2, base_hue)
    c1, c2 = np.array(palette[0]), np.array(palette[1])
    
    z_expanded = z[..., np.newaxis]
    img_array = (c1 * (1 - z_expanded) + c2 * z_expanded).astype(np.uint8)
    return Image.fromarray(img_array, 'RGB')

def generate_truchet_tiles(width, height, base_hue=None):
    image = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(image)
    
    palette = generate_harmonious_palette(3, base_hue)
    bg_color, line_color, accent_color = palette
    
    draw.rectangle([0, 0, width, height], fill=bg_color)
    tile_size = random.choice([80, 120, 160])
    line_width = tile_size // 4
    
    for y in range(0, height, tile_size):
        for x in range(0, width, tile_size):
            if random.random() > 0.5:
                draw.line([x, y, x + tile_size, y + tile_size], fill=line_color, width=line_width)
            else:
                draw.line([x + tile_size, y, x, y + tile_size], fill=accent_color, width=line_width)
    return image

def generate_liquid_perlin(width, height, base_hue=None):
    scale_down = 10
    small_w, small_h = width // scale_down, height // scale_down
    noise1 = PerlinNoise(octaves=random.uniform(1.5, 3.0))
    noise2 = PerlinNoise(octaves=random.uniform(3.0, 5.0))
    img_array = np.zeros((small_h, small_w, 3), dtype=np.uint8)
    
    palette = generate_harmonious_palette(2, base_hue)
    color_start, color_end = np.array(palette[0]), np.array(palette[1])
    
    for y in range(small_h):
        for x in range(small_w):
            val = noise1([x/small_w, y/small_h]) + 0.5 * noise2([x/small_w, y/small_h])
            val = max(0, min(1, (val + 1.5) / 3.0))
            img_array[y, x] = color_start * (1 - val) + color_end * val
            
    small_img = Image.fromarray(img_array, 'RGB')
    return small_img.resize((width, height), Image.Resampling.BICUBIC)

def generate_crystal_voronoi(width, height, base_hue=None):
    image = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(image)
    points = np.random.rand(150, 2) * [width, height]
    dummy_points = np.array([[-width, -height], [width*2, -height], [-width, height*2], [width*2, height*2]])
    points = np.vstack((points, dummy_points))
    vor = Voronoi(points)
    
    # If a color is requested, calculate it! Otherwise pick a random monochrome
    if base_hue is not None:
        r, g, b = colorsys.hsv_to_rgb(base_hue, random.uniform(0.3, 0.7), random.uniform(0.2, 0.8))
        base_color = (int(r*255), int(g*255), int(b*255))
    else:
        base_color = random.choice([(20, 20, 25), (240, 245, 250), (10, 40, 30)])
        
    for region_index in vor.point_region:
        region = vor.regions[region_index]
        if not -1 in region and len(region) > 0:
            polygon = [tuple(vor.vertices[i]) for i in region]
            shade = random.randint(-20, 20)
            color = tuple(max(0, min(255, c + shade)) for c in base_color)
            draw.polygon(polygon, fill=color, outline=(100, 100, 100))
    return image

def generate_psychedelic_julia(width, height, base_hue=None):
    y, x = np.mgrid[-1.5:1.5:complex(0, height), -1.0:1.0:complex(0, width)]
    z = x + 1j * y
    c = complex(random.uniform(-0.8, 0.4), random.uniform(-0.6, 0.6))
    escape_time = np.zeros(z.shape, dtype=int)
    for i in range(40):
        mask = np.abs(z) < 2
        z[mask] = z[mask]**2 + c
        escape_time[mask] += 1
        
    img_array = np.zeros((height, width, 3), dtype=np.uint8)
    
    # Shift the fractal colors if a hue is provided
    phase_shift = (base_hue * 2 * np.pi) if base_hue is not None else 0
    
    img_array[:, :, 0] = (np.sin(escape_time * 0.1 + phase_shift) * 127 + 128).astype(np.uint8)
    img_array[:, :, 1] = (np.cos(escape_time * 0.2 + phase_shift) * 127 + 128).astype(np.uint8)
    img_array[:, :, 2] = (np.sin(escape_time * 0.3 + phase_shift) * 127 + 128).astype(np.uint8)
    
    return Image.fromarray(img_array, 'RGB')

# --- API Endpoint ---

# --- Helper to parse Hex to RGB ---
def parse_hex_colors(hex_string):
    """Converts a string like 'FF0000,00FF00' into a list of RGB tuples."""
    colors = []
    for hex_code in hex_string.split(','):
        hex_code = hex_code.strip('#')
        if len(hex_code) == 6:
            colors.append(tuple(int(hex_code[i:i+2], 16) for i in (0, 2, 4)))
    return colors

@app.route('/api/wallpaper/premium', methods=['GET'])
def premium_wallpaper():
    width, height = 1080, 1920
    
    style = request.args.get('style', 'waves')
    colors_str = request.args.get('colors')
    
    # If the app sends a custom palette, parse it!
    custom_palette = parse_hex_colors(colors_str) if colors_str else None

    # We temporarily override the palette generator if a custom one is provided
    global generate_harmonious_palette
    original_palette_func = generate_harmonious_palette
    
    if custom_palette:
        # Trick the math functions into using our custom palette
        generate_harmonious_palette = lambda num_colors, hue=None: (custom_palette * (num_colors // len(custom_palette) + 1))[:num_colors]

    # Generate the requested image
    if style == 'waves':
        image = generate_wave_interference(width, height)
    elif style == 'truchet':
        image = generate_truchet_tiles(width, height)
    elif style == 'liquid':
        image = generate_liquid_perlin(width, height)
    elif style == 'crystal':
        image = generate_crystal_voronoi(width, height)
    elif style == 'fractal':
        image = generate_psychedelic_julia(width, height)
    else:
        image = generate_liquid_perlin(width, height)

    # Restore the original function just in case
    generate_harmonious_palette = original_palette_func

    img_io = io.BytesIO()
    image.save(img_io, 'JPEG', quality=85)
    img_io.seek(0)
    
    return send_file(img_io, mimetype='image/jpeg')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)