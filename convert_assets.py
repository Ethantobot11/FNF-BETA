import os
import subprocess
import shutil
import xml.etree.ElementTree as ET

def get_tool_path(tool_name: str) -> str:
    tool_path = shutil.which(tool_name)
    if tool_path: return tool_path
    linux_path = f"/opt/devkitpro/tools/bin/{tool_name}"
    if os.path.exists(linux_path): return linux_path
    win_path = f"C:\\devkitPro\\tools\\bin\\{tool_name}.exe"
    if os.path.exists(win_path): return win_path
    return tool_name

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
        
        print(f"  [1/3] Converting {png_path} to {t3x_path} using tex3ds...")
        try:
            subprocess.run([tex3ds_path, png_path, "-o", t3x_path, "-f", "rgba8"], check=True, env=os.environ)
        except Exception as e:
            print(f"  ERROR: tex3ds failed on {png_path}. Skipping. ({e})")
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
                
                if "_" in frame_name and frame_name.split("_")[-1].isdigit():
                    parts = frame_name.rsplit("_", 1)
                    anim_name = parts[0]
                    frame_idx = int(parts[1]) // 10000
                    cea_line = f"{t3x_name}?{x}?{y}?{width}?{height}?{frameX}?{frameY}?{frameWidth}?{frameHeight}?{anim_name}-{frame_idx}"
                elif frame_name and frame_name.isdigit():
                    cea_line = f"{t3x_name}?{x}?{y}?{width}?{height}?{frameX}?{frameY}?{frameWidth}?{frameHeight}?{name}-{int(frame_name)}"
                elif not frame_name:
                    continue
                else:
                    cea_line = f"{t3x_name}?{x}?{y}?{width}?{height}?{frameX}?{frameY}?{frameWidth}?{frameHeight}?{frame_name}"
                    
                cea_lines.append(cea_line)
            
            with open(cea_path, "w", encoding="utf-8") as f:
                f.write("\n".join(cea_lines) + "\n")
                
        except Exception as e:
            print(f"  ERROR: Failed to parse XML {xml_path}: {e}")
            continue

        print(f"  [3/3] Cleaning up original {name}.png and {name}.xml...")
        try:
            os.remove(png_path)
            os.remove(xml_path)
            print(f"  SUCCESS: {name} converted to 10-column CEA and cleaned up.")
        except Exception as e:
            print(f"  WARNING: Could not delete original files for {name}: {e}")

    for root, name, ext, file_path in other_files:
        if not os.path.exists(file_path): continue
        if ext == ".mp3" and os.path.normpath(file_path) not in excluded_files:
            out_path = os.path.join(root, name + ".ogg")
            try:
                subprocess.run(["ffmpeg", "-y", "-i", file_path, "-q:a", "4", out_path], check=True)
                os.remove(file_path)
            except Exception as e: print(f"Error converting {file_path} to OGG: {e}")
        elif ext in [".wav", ".ogg"] and os.path.normpath(file_path) not in excluded_files:
            out_path = os.path.join(root, name + ".cwav")
            try:
                cmd = [cwavtool_path, "-i", file_path, "-o", out_path]
                if os.path.normpath(file_path) in looped_files: cmd.extend(["-ls", "0", "-le", "end"])
                subprocess.run(cmd, check=True, env=os.environ)
                if ext == ".wav": os.remove(file_path)
            except Exception as e: print(f"Error converting {file_path} to CWAV: {e}")

if __name__ == "__main__":
    main()