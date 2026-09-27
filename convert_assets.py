import os
import subprocess
import shutil
import xml.etree.ElementTree as ET
import math
import json

try:
    from PIL import Image
    HAS_PILLOW = True
except ImportError:
    HAS_PILLOW = False
    print("WARNING: Pillow not found. Install it via 'pip install Pillow' to fix texture dimension errors.")

def get_tool_path(tool_name: str) -> str:
    tool_path = shutil.which(tool_name)
    if tool_path: return tool_path
    linux_path = f"/opt/devkitpro/tools/bin/{tool_name}"
    if os.path.exists(linux_path): return linux_path
    win_path = f"C:\\devkitPro\\tools\\bin\\{tool_name}.exe"
    if os.path.exists(win_path): return win_path
    return tool_name

def next_power_of_2(n: int) -> int:
    return 1 if n == 0 else 2**(math.ceil(math.log2(n)))

def convert_animate_atlas(root, files, tex3ds_path):
    """Converts AnimateAtlas (Texture Atlas) folders to .cea + .t3x"""
    if "Animation.json" in files and "spritemap.json" in files and "spritemap.png" in files:
        anim_json = os.path.join(root, "Animation.json")
        sprite_json = os.path.join(root, "spritemap.json")
        png_path = os.path.join(root, "spritemap.png")
        t3x_path = os.path.join(root, "spritemap.t3x")
        cea_path = os.path.join(root, "Animation.cea")

        print(f"  [AnimateAtlas] Converting {root}...")

        png_to_convert = png_path
        if HAS_PILLOW:
            try:
                img = Image.open(png_path)
                width, height = img.size
                new_width = next_power_of_2(width)
                new_height = next_power_of_2(height)
                if new_width != width or new_height != height:
                    print(f"    [!] Padding {png_path} to {new_width}x{new_height}")
                    new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
                    new_img.paste(img, (0, 0))
                    png_to_convert = os.path.join(root, "spritemap_padded.png")
                    new_img.save(png_to_convert)
            except Exception as e:
                print(f"    WARNING: Could not pad image: {e}")

        try:
            subprocess.run([tex3ds_path, png_to_convert, "-o", t3x_path, "-f", "rgba8"], 
                          check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"    ERROR: tex3ds failed on {png_to_convert}. ({e})")
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            return

        try:
            with open(sprite_json, 'r', encoding='utf-8') as f:
                atlas_data = json.load(f)
            with open(anim_json, 'r', encoding='utf-8-sig') as f: 
                anim_data = json.load(f)
        except Exception as e:
            print(f"    ERROR: Failed to parse AnimateAtlas JSONs. ({e})")
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            return

        sprite_coords = {}
        if "ATLAS" in atlas_data and "SPRITES" in atlas_data["ATLAS"]:
            for s in atlas_data["ATLAS"]["SPRITES"]:
                spr = s["SPRITE"]
                sprite_coords[spr["name"]] = spr

        cea_lines = []
        
        if "SYMBOL_DICTIONARY" in anim_data and "Symbols" in anim_data["SYMBOL_DICTIONARY"]:
            for symbol in anim_data["SYMBOL_DICTIONARY"]["Symbols"]:
                sym_name = symbol.get("SYMBOL_name", "unknown")
                
                if "TIMELINE" in symbol and "LAYERS" in symbol["TIMELINE"]:
                    for layer in symbol["TIMELINE"]["LAYERS"]:
                        for frame in layer.get("Frames", []):
                            frame_name = frame.get("name", sym_name)
                            
                            sprite_name = None
                            if "elements" in frame and len(frame["elements"]) > 0:
                                elem = frame["elements"][0]
                                if "ATLAS_SPRITE_instance" in elem:
                                    sprite_name = elem["ATLAS_SPRITE_instance"].get("name")
                            
                            if sprite_name and sprite_name in sprite_coords:
                                coord = sprite_coords[sprite_name]
                                cea_line = f"spritemap.t3x?{coord['x']}?{coord['y']}?{coord['w']}?{coord['h']}?0?0?{coord['w']}?{coord['h']}?{frame_name}"
                                cea_lines.append(cea_line)

        if cea_lines:
            with open(cea_path, 'w', encoding='utf-8') as f:
                f.write("\n".join(cea_lines) + "\n")
            print(f"    SUCCESS: Generated Animation.cea and spritemap.t3x")
            
            os.remove(anim_json)
            os.remove(sprite_json)
            os.remove(png_path)
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
        else:
            print(f"    WARNING: No valid frames found in {root}")

def main():
    os.makedirs("assets/romfs/haxe3ds", exist_ok=True)
    with open("assets/romfs/haxe3ds/version", "w") as f: 
        f.write("")

    if not os.path.exists("assets"):
        print("No 'assets' directory found. Skipping conversion.")
        return

    excluded_files = {
        os.path.normpath("assets/resources/audio.wav"),
        os.path.normpath("assets/romfs/resources/audio.wav"),
        os.path.normpath("resources/audio.wav"),
        os.path.normpath("audio.wav")
    }
    looped_files = { os.path.normpath("assets/sounds/home.ogg") }

    tex3ds_path = get_tool_path("tex3ds")
    cwavtool_path = get_tool_path("cwavtool")
    
    print(f"Using tex3ds at: {tex3ds_path}")
    print(f"Using cwavtool at: {cwavtool_path}")

    sprite_sheets = []
    other_files = []

    for root, dirs, files in os.walk("assets"):
        convert_animate_atlas(root, files, tex3ds_path)

        for file in files:
            file_path = os.path.join(root, file)
            name, ext = os.path.splitext(file)
            ext = ext.lower()
            
            if ext == ".xml":
                png_path = os.path.join(root, name + ".png")
                if os.path.exists(png_path):
                    sprite_sheets.append((root, name, file_path, png_path))
                else:
                    print(f"Warning: Found {file_path} but no corresponding {name}.png")
            else:
                other_files.append((root, name, ext, file_path))

    for root, name, xml_path, png_path in sprite_sheets:
        t3x_name = name + ".t3x"
        t3x_path = os.path.join(root, t3x_name)
        cea_path = os.path.join(root, name + ".cea")
        
        print(f"\nProcessing sprite sheet: {name}")
        
        png_to_convert = png_path
        if HAS_PILLOW:
            try:
                img = Image.open(png_path)
                width, height = img.size
                new_width = next_power_of_2(width)
                new_height = next_power_of_2(height)
                
                if new_width != width or new_height != height:
                    print(f"  [!] Padding {name} from {width}x{height} to {new_width}x{new_height} (3DS requires Power of 2)")
                    new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
                    new_img.paste(img, (0, 0))
                    png_to_convert = os.path.join(root, name + "_padded.png")
                    new_img.save(png_to_convert)
            except Exception as e:
                print(f"  WARNING: Could not check/Pad image with Pillow: {e}")

        print(f"  [1/3] Converting to {t3x_path} using tex3ds...")
        try:
            subprocess.run([tex3ds_path, png_to_convert, "-o", t3x_path, "-f", "rgba8"], check=True, env=os.environ, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"  ERROR: tex3ds failed on {png_to_convert}. Skipping. ({e})")
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            continue

        print(f"  [2/3] Generating 10-column {cea_path} from {xml_path}...")
        try:
            tree = ET.parse(xml_path)
            root_elem = tree.getroot()
            cea_lines = []
            
            for subtex in root_elem.findall(".//SubTexture"):
                frame_name = subtex.get("name")
                x = subtex.get("x", "0")
                y = subtex.get("y", "0")
                width = subtex.get("width", "0")
                height = subtex.get("height", "0")
                
                frameX = subtex.get("frameX", "0")
                frameY = subtex.get("frameY", "0")
                frameWidth = subtex.get("frameWidth", width)
                frameHeight = subtex.get("frameHeight", height)
                
                if not frame_name:
                    continue
                    
                if "_" in frame_name and frame_name.split("_")[-1].isdigit():
                    parts = frame_name.rsplit("_", 1)
                    anim_name = parts[0]
                    frame_idx = int(parts[1]) // 10000
                    cea_line = f"{t3x_name}?{x}?{y}?{width}?{height}?{frameX}?{frameY}?{frameWidth}?{frameHeight}?{anim_name}-{frame_idx}"
                elif frame_name.isdigit():
                    cea_line = f"{t3x_name}?{x}?{y}?{width}?{height}?{frameX}?{frameY}?{frameWidth}?{frameHeight}?{name}-{int(frame_name)}"
                else:
                    cea_line = f"{t3x_name}?{x}?{y}?{width}?{height}?{frameX}?{frameY}?{frameWidth}?{frameHeight}?{frame_name}"
                    
                cea_lines.append(cea_line)
            
            with open(cea_path, "w", encoding="utf-8") as f:
                f.write("\n".join(cea_lines) + "\n")
                
        except Exception as e:
            print(f"  ERROR: Failed to parse XML {xml_path}: {e}")
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            continue

        print(f"  [3/3] Cleaning up original files...")
        try:
            os.remove(png_path)
            os.remove(xml_path)
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            print(f"  SUCCESS: {name} converted to CEA and cleaned up.")
        except Exception as e:
            print(f"  WARNING: Could not delete original files for {name}: {e}")

    for root, name, ext, file_path in other_files:
        if not os.path.exists(file_path): continue
        
        if ext == ".png":
            t3x_path = os.path.join(root, name + ".t3x")
            print(f"Converting standalone image {name}.png to .t3x...")
            try:
                png_to_convert = file_path
                if HAS_PILLOW:
                    try:
                        img = Image.open(file_path)
                        width, height = img.size
                        new_width = next_power_of_2(width)
                        new_height = next_power_of_2(height)
                        if new_width != width or new_height != height:
                            print(f"  [!] Padding {name}.png to {new_width}x{new_height}")
                            new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
                            new_img.paste(img, (0, 0))
                            png_to_convert = os.path.join(root, name + "_padded.png")
                            new_img.save(png_to_convert)
                    except Exception as e:
                        print(f"  WARNING: Could not pad image: {e}")

                subprocess.run([tex3ds_path, png_to_convert, "-o", t3x_path, "-f", "rgba8"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                os.remove(file_path)
                if png_to_convert != file_path and os.path.exists(png_to_convert):
                    os.remove(png_to_convert)
                print(f"  SUCCESS: {name} converted to .t3x")
            except Exception as e:
                print(f"  ERROR converting {file_path} to .t3x: {e}")

        elif ext == ".mp3" and os.path.normpath(file_path) not in excluded_files:
            out_path = os.path.join(root, name + ".ogg")
            try:
                print(f"Converting {name}.mp3 to .ogg...")
                subprocess.run(["ffmpeg", "-y", "-i", file_path, "-q:a", "4", out_path], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                os.remove(file_path)
            except Exception as e: 
                print(f"Error converting {file_path} to OGG: {e}")
                
        elif ext in [".wav", ".ogg"] and os.path.normpath(file_path) not in excluded_files:
            out_path = os.path.join(root, name + ".cwav")
            try:
                is_music = "music" in root.lower() or "song" in root.lower() or "voices" in root.lower() or "inst" in root.lower()
                channels = 2 if is_music else 1
                
                temp_wav = os.path.join(root, name + "_temp.wav")
                print(f"  Normalizing {name}{ext} to {channels}ch, 32kHz WAV for 3DS...")
                
                subprocess.run([
                    "ffmpeg", "-y", "-i", file_path, 
                    "-ar", "32000", "-ac", str(channels), "-c:a", "pcm_s16le", 
                    temp_wav
                ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                print(f"  Converting to CWAV...")
                cmd = [cwavtool_path, "-i", temp_wav, "-o", out_path]
                if os.path.normpath(file_path) in looped_files: 
                    cmd.extend(["-ls", "0", "-le", "end"])
                subprocess.run(cmd, check=True, env=os.environ, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                os.remove(temp_wav)
                os.remove(file_path)
                print(f"  SUCCESS: {name} converted to CWAV.")
                
            except Exception as e: 
                print(f"  ERROR converting {file_path} to CWAV: {e}")
                if os.path.exists(temp_wav):
                    os.remove(temp_wav)

if __name__ == "__main__":
    main()
