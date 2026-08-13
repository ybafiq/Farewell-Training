import os
import sys
import zipfile
import shutil
import glob
import yaml

def get_long_path(path):
    r"""Convert path to Windows Extended-Length Path prefix \\?\ to bypass MAX_PATH (260 char limit)."""
    abs_path = os.path.abspath(path)
    if sys.platform == "win32" and not abs_path.startswith("\\\\?\\"):
        return "\\\\?\\" + abs_path
    return abs_path

DATA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data"))
SCRIPTS_DIR = os.path.abspath(os.path.dirname(__file__))
YAML_PATH = os.path.join(SCRIPTS_DIR, "data_custom.yaml")

def find_zip_file(user_path=None):
    if user_path and os.path.exists(user_path):
        return user_path
    
    downloads = os.path.expanduser("~/Downloads")
    zips = glob.glob(os.path.join(downloads, "*.zip"))
    if zips:
        zips.sort(key=os.path.getmtime, reverse=True)
        return zips[0]
    return None

def setup_dataset(zip_path):
    print(f"Extracting dataset from: {zip_path}")
    
    # Use short temp dir or long path prefix to prevent Windows MAX_PATH error
    temp_dir_raw = os.path.join(DATA_DIR, "_temp_extract")
    temp_dir = get_long_path(temp_dir_raw)
    
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir, ignore_errors=True)
    os.makedirs(temp_dir, exist_ok=True)
    
    # Extract members manually with long path handling
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        for member in zip_ref.infolist():
            # Resolve target path with \\?\ prefix
            target_path = get_long_path(os.path.join(temp_dir_raw, member.filename))
            if member.is_dir():
                os.makedirs(target_path, exist_ok=True)
            else:
                os.makedirs(os.path.dirname(target_path), exist_ok=True)
                with zip_ref.open(member) as source, open(target_path, "wb") as target:
                    shutil.copyfileobj(source, target)
                    
    print("Extract completed successfully!")
    print("Organizing into data/ directory...")
    
    target_data_dir = get_long_path(DATA_DIR)
    
    # Search for train directory or data.yaml
    yaml_files = []
    train_folders = []
    
    for root, dirs, files in os.walk(temp_dir):
        if "data.yaml" in files:
            yaml_files.append(os.path.join(root, "data.yaml"))
        if "train" in dirs:
            train_folders.append(root)

    source_root = temp_dir
    if train_folders:
        source_root = train_folders[0]
        
    subfolders = ["train", "val", "valid", "test"]
    for folder in subfolders:
        src_path = os.path.join(source_root, folder)
        if os.path.exists(src_path):
            target_name = "val" if folder == "valid" else folder
            dest_path = os.path.join(target_data_dir, target_name)
            if os.path.exists(dest_path):
                shutil.rmtree(dest_path, ignore_errors=True)
            shutil.move(src_path, dest_path)
            print(f" -> Moved {folder} to data/{target_name}")

    # Process data.yaml if exists
    found_yaml = yaml_files[0] if yaml_files else os.path.join(temp_dir, "data.yaml")
    if os.path.exists(found_yaml):
        with open(found_yaml, 'r') as f:
            yaml_data = yaml.safe_load(f)
            
        nc = yaml_data.get("nc", len(yaml_data.get("names", [])))
        names = yaml_data.get("names", ["healthy", "unhealthy"])
        
        custom_config = {
            "train": os.path.join(DATA_DIR, "train"),
            "val": os.path.join(DATA_DIR, "val"),
            "nc": nc,
            "names": names
        }
        with open(YAML_PATH, 'w') as f:
            yaml.dump(custom_config, f, default_flow_style=False)
        print(f"Updated data_custom.yaml: nc={nc}, classes={names}")
    
    # Clean up temp extract directory
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir, ignore_errors=True)
        
    print(f"\nDataset successfully set up in: {DATA_DIR}")
    print("You can now run: .\\venv\\Scripts\\python.exe scripts/1_train.py")

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else find_zip_file()
    if not path:
        print("Usage: python scripts/setup_dataset.py <path_to_zip_file>")
        sys.exit(1)
    
    setup_dataset(path)

