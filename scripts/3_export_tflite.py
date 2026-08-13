# Step 1: Install the required packages (if you haven't already)
# pip install ultralytics tensorflow

import os
from ultralytics import YOLO

print("--- Starting Conversion ---")

# Step 1: Load your trained PyTorch model
model_path = 'scripts/best.pt'
if not os.path.exists(model_path):
    print(f"Error: Could not find {model_path}")
    exit(1)

model = YOLO(model_path)

# Step 2: Export to ONNX first
print("--- Exporting to ONNX ---")
exported_path = model.export(format='onnx', imgsz=640)

# Step 3: Convert ONNX to TFLite using onnx2tf (since LiteRT export fails on Windows)
print("--- Converting ONNX to TFLite ---")
os.system(f"onnx2tf -i {exported_path} -o scripts/best_saved_model")

print(f"--- Export Finished! Folder created at: scripts/best_saved_model ---")