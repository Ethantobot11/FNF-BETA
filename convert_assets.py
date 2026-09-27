import os
import subprocess
import shutil
import xml.etree.ElementTree as ET
import math

try:
    from PIL import Image
    HAS_PILLOW = True
except ImportError:
    HAS_PILLOW = False
    print("\nWARNING: Pillow not found. Install via 'pip install Pillow'\n")

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

MAX_3DS_SAFE_SIZE = 1024

excluded_files = {
    os.path.normpath("assets/resources/audio.wav"),
    os.path.normpath("assets/resources/banner.png"),
    os.path.normpath("assets/resources/icon.png")
}

def fix_xml_escapes(file_path):
    """Safely fixes unescaped '&' characters in XML without breaking existing entities."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        parts = content.split('&')
        new_content = parts[0]
        for part in parts[1:]:
            if part.startswith(('amp;', 'lt;', 'gt;', 'quot;', 'apos;', '#')):
                new_content += '&' + part
            else:
                new_content += '&amp;' + part
        
        if new_content != content:
            print(f"  [!] Fixed unescaped '&' in {os.path.basename(file_path)}")
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
        return False
    except Exception as e:
        print(f"  [!] Error fixing XML: {e}")
        return False

def process_image_for_3ds(file_path, root, name):
    if not HAS_PILLOW:
        return file_path
    try:
        img = Image.open(file_path)
        width, height = img.size
        
        if width > MAX_3DS_SAFE_SIZE or height > MAX_3DS_SAFE_SIZE:
            print(f"  [!] Resizing {name} from {width}x{height} to fit 3DS safe limit")
            scale = MAX_3DS_SAFE_SIZE / max(width, height)
            new_width = int(width * scale)
            new_height = int(height * scale)
            img = img.resize((new_width, new_height), Image.Resampling.LANCZOS if hasattr(Image, 'Resampling') else Image.ANTIALIAS)
            width, height = new_width, new_height

        p2_width = next_power_of_2(width)
        p2_height = next_power_of_2(height)

        if p2_width != width or p2_height != height:
            print(f"  [!] Padding {name} to {p2_width}x{p2_height}")
            new_img = Image.new("RGBA", (p2_width, p2_height), (0, 0, 0, 0))
            new_img.paste(img, (0, 0))
            out_path = os.path.join(root, name + "_processed.png")
            new_img.save(out_path)
            return out_path
        return file_path
    except Exception as e:
        print(f"  [!] ERROR processing image {name}: {e}")
        return file_path

def main():
    os.makedirs("assets/romfs/haxe3ds", exist_ok=True)
    with open("assets/romfs/haxe3ds/version", "w") as f: 
        f.write("")

    if not os.path.exists("assets"):
        print("No 'assets' directory found.")
        return

    tex3ds_path = get_tool_path("tex3ds")
    cwavtool_path = get_tool_path("cwavtool")
    looped_files = { os.path.normpath("assets/sounds/home.ogg") }
    
    print(f"Using tex3ds at: {tex3ds_path}")
    print(f"Using cwavtool at: {cwavtool_path}\n")

    sprite_sheets = []

    for root, dirs, files in os.walk("assets"):
        for file in files:
            file_path = os.path.join(root, file)
            name, ext = os.path.splitext(file)
            if ext.lower() == ".xml":
                if os.path.normpath(file_path) in excluded_files:
                    continue
                png_path = os.path.join(root, name + ".png")
                if os.path.exists(png_path):
                    sprite_sheets.append((root, name, file_path, png_path))

    print(f"Found {len(sprite_sheets)} sprite sheets to convert\n")

    for root, name, xml_path, png_path in sprite_sheets:
        t3x_name = name + ".t3x"
        t3x_path = os.path.join(root, t3x_name)
        cea_path = os.path.join(root, name + ".cea")
        
        print(f"Processing: {name}")
        
        png_to_convert = process_image_for_3ds(png_path, root, name)
        
        print(f"  [1/3] Converting PNG to T3X...")
        try:
            subprocess.run([tex3ds_path, png_to_convert, "-o", t3x_path, "-f", "rgba8"], 
                          check=True, env=os.environ, capture_output=True, text=True)
            print(f"      SUCCESS: Created {t3x_name}")
        except subprocess.CalledProcessError as e:
            print(f"      FAILED: tex3ds error")
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            continue

        print(f"  [2/3] Parsing XML and generating CEA...")
 
        fix_xml_escapes(xml_path)
        
        try:
            tree = ET.parse(xml_path)
            root_elem = tree.getroot()
            
            subtextures = root_elem.findall(".//SubTexture")
            print(f"      Found {len(subtextures)} SubTexture elements")
            
            cea_lines = []
            for i, subtex in enumerate(subtextures):
                frame_name = subtex.get("name")
                if not frame_name: 
                    continue
                
                x = subtex.get("x", "0")
                y = subtex.get("y", "0")
                width = subtex.get("width", "0")
                height = subtex.get("height", "0")
                frameX = subtex.get("frameX", "0")
                frameY = subtex.get("frameY", "0")
                frameWidth = subtex.get("frameWidth", width)
                frameHeight = subtex.get("frameHeight", height)
                
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
            
            print(f"      Generated {len(cea_lines)} CEA lines")
            
            if cea_lines:
                with open(cea_path, "w", encoding="utf-8") as f:
                    f.write("\n".join(cea_lines) + "\n")
                print(f"      SUCCESS: Created {name}.cea")
            else:
                print(f"      WARNING: No CEA lines generated!")
                
        except ET.ParseError as e:
            print(f"      FAILED: XML parsing error at line {e.lineno}, column {e.offset}")
            print(f"      Error: {e.msg}")
            print(f"      Skipping CEA generation for {name}")
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            continue
        except Exception as e:
            print(f"      FAILED: {e}")
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            continue

        print(f"  [3/3] Cleaning up...")
        try:
            os.remove(png_path)
            os.remove(xml_path)
            if png_to_convert != png_path and os.path.exists(png_to_convert):
                os.remove(png_to_convert)
            print(f"      Deleted original files")
        except Exception as e:
            print(f"      WARNING: Could not delete files: {e}")
        
        print(f"  DONE: {name}\n")

    for root, dirs, files in os.walk("assets"):
        for file in files:
            file_path = os.path.join(root, file)
            name, ext = os.path.splitext(file)
            ext = ext.lower()
            
            if os.path.normpath(file_path) in excluded_files:
                continue
            
            if ext == ".mp3":
                print(f"Converting {name}.mp3 to .ogg...")
                try:
                    subprocess.run(["ffmpeg", "-y", "-i", file_path, "-q:a", "4", os.path.join(root, name + ".ogg")], 
                                  check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    os.remove(file_path)
                except: pass
            elif ext in [".wav", ".ogg"]:
                print(f"Converting {name}{ext} to .cwav...")
                try:
                    is_music = "music" in root.lower() or "song" in root.lower()
                    channels = 2 if is_music else 1
                    temp_wav = os.path.join(root, name + "_temp.wav")
                    subprocess.run(["ffmpeg", "-y", "-i", file_path, "-ar", "32000", "-ac", str(channels), "-c:a", "pcm_s16le", temp_wav], 
                                  check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    cmd = [cwavtool_path, "-i", temp_wav, "-o", os.path.join(root, name + ".cwav")]
                    if os.path.normpath(file_path) in looped_files: cmd.extend(["-ls", "0", "-le", "end"])
                    subprocess.run(cmd, check=True, env=os.environ, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    os.remove(temp_wav)
                    os.remove(file_path)
                except Exception as e: 
                    print(f"  Error: {e}")
                    if os.path.exists(temp_wav): os.remove(temp_wav)

if __name__ == "__main__":
    main()
