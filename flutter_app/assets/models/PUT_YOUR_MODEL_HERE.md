# Put your trained model in this folder

Two files, exactly these names:

    leaf.tflite        <- rename your model_int8.tflite to this
    leaf_manifest.json <- optional, copy of manifest.json

Then:

    flutter run --release

## No model yet?

The app still runs. It falls back to a general-purpose model that Ultralytics
downloads on first launch (needs wifi once), and shows an amber DEMO MODEL
banner so nobody in the room is misled.

That fallback detects everyday objects — people, cups, chairs — not leaves.
It is there to prove the camera pipeline works, nothing more.

## Where the model comes from

    notebooks/train_healthy_vs_unhealthy.ipynb   (Colab, free GPU)
        or
    python scripts/3_export_tflite.py            (your own machine)

Both produce export/model_int8.tflite. That is the file. Rename and drop it here.
