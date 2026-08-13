# Putting the model in the Android app

You do not need to understand the app code to swap in a new model.

## Swapping in a new model

1. Copy both files into the app:

   ```
   app/src/main/assets/model_int8.tflite
   app/src/main/assets/manifest.json
   ```

2. Rebuild the app. That is it — no code changes.

The app reads the class names and the input size **from `manifest.json`**.
This matters: if you type the names into the app code instead, then the day
someone retrains with the classes in a different order, the app will
confidently label every disease wrongly and nobody will notice for a week.

## Dependencies (already in the reference app)

```gradle
implementation "org.tensorflow:tensorflow-lite:2.17.0"
implementation "org.tensorflow:tensorflow-lite-support:0.4.4"
implementation "androidx.camera:camera-camera2:1.3.4"
implementation "androidx.camera:camera-lifecycle:1.3.4"
implementation "androidx.camera:camera-view:1.3.4"
```

## The four things the app does per frame

1. Take the camera frame and turn it into a bitmap
2. **Pad** it to a square 640×640 — grey bars, never stretch
3. Run it through the model
4. Read the output, drop low-confidence boxes, remove overlapping duplicates,
   and draw what is left

## Settings worth knowing

| Setting | Sensible value | Why |
|---|---|---|
| Confidence threshold | 0.45 | lower = more boxes, more false alarms |
| Overlap threshold | 0.50 | how aggressively duplicates are merged |
| Frames per second | 5 while scouting | full speed flattens the battery in ~4 hours |
| Accelerator | NNAPI, fall back to GPU, then CPU | not every phone supports NNAPI |

## Field behaviour we agreed on

- Only run at full speed while the user holds the scan button
- Pause completely when the app goes to the background
- If the frame is too dark or too blurry, say "please retake" — do not guess
- Save the frames where the model was unsure; they are next season's training data
