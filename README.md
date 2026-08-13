# YOLO on a Phone — Starter Kit

Train a crop-problem detector and get it running on an Android phone.
Written for people who have **never done machine learning before**.

There are four steps. Nothing else.

```
 1. Collect photos  →  2. Label them  →  3. Train  →  4. Convert for the phone
    (you, outdoors)     (Label Studio)    (1 command)   (1 command)
```

---

## Before you start

You need:

- A computer with Python 3.9 or newer (a GPU makes training faster, but it works without one)
- [Label Studio](https://labelstud.io) for drawing boxes on photos
- Photos of your crop

Set the project up once:

```bash
git clone <this-repo-url>
cd yolo-phone-starter
pip install -r requirements.txt
```

---

## Want a working model today, without collecting anything?

Use free public data first, to learn the pipeline. You get a **healthy vs
unhealthy leaf** detector in about 40 minutes.

### Easiest: the Colab notebook (free GPU, nothing to install)

Open [`notebooks/train_healthy_vs_unhealthy.ipynb`](notebooks/train_healthy_vs_unhealthy.ipynb)
in [Google Colab](https://colab.research.google.com), set
`Runtime -> Change runtime type -> T4 GPU`, and run every cell.

It downloads PlantVillage (about 54,000 public leaf photos), converts it to two
classes, trains, shows you the accuracy, exports `model_int8.tflite`, checks the
conversion, and downloads the files.

### Or on your own machine

```bash
# 1. get the data (free Kaggle account needed)
pip install kagglehub
python -c "import kagglehub; print(kagglehub.dataset_download('abdallahalidev/plantvillage-dataset'))"

# 2. turn it into a healthy / unhealthy detection dataset
python scripts/setup_dataset.py --src <the path it printed>

# 3. onwards as normal
python scripts/1_train.py
python scripts/3_export_tflite.py
python scripts/2_predict.py
```

`setup_dataset.py` works with **any** folder of class sub-folders:
anything with *healthy* in the folder name becomes class 0, everything else
becomes class 1. It balances the two classes and generates the boxes.

> ### Be honest about what this model is
>
> PlantVillage photos are single leaves on a plain background, taken in a lab.
> The boxes were generated, not drawn by a person.
>
> The model will look impressive on photos that look the same. It will do badly
> on a real canopy shot with dew, shadows and overlapping leaves.
>
> That is not a flaw - it is the whole lesson. **Public data gets you a working
> demo in an afternoon. Your own field photos, labelled in Label Studio, are
> what make it work in the field.**
>
> Learn the pipeline on public data, then replace the data and run it again.

---

## Step 1 — Collect photos

Take pictures of the crop. Healthy ones **and** unhealthy ones.

**Do this**

- Use the same phones your field team actually carries
- Shoot in the morning, at midday, and in the evening — not just at noon
- Include messy photos: dew, shadows, other leaves in the background
- Aim for **at least 300 examples of every problem** you want to find

**Don't do this**

- Only clean, perfect close-ups from a good camera
- All photos taken on one sunny afternoon
- 900 photos of healthy plants and 40 of the disease

> **The rule:** the photos you train with should look like the photos your team
> will actually take in the field. If they don't, nothing else you do will save it.

Put your photos anywhere for now — Label Studio will import them.

---

## Step 2 — Label them in Label Studio

1. Start Label Studio and create a new project
2. Go to **Settings → Labeling Interface → Code** and paste in
   [`configs/label_studio_config.xml`](configs/label_studio_config.xml)
   (edit the class names to match your crop)
3. Import your photos
4. For each photo: drag a box around the problem, pick the name, click next

When you have finished labelling:

**Export → YOLO**

Unzip the export into the `data/` folder so it looks like this:

```
data/
├── images/
│   ├── train/        put ~80% of your photos here
│   └── val/          put ~20% here
├── labels/
│   ├── train/        the matching .txt files
│   └── val/
└── classes.txt       the class names Label Studio gave you
```

Then open [`scripts/data_custom.yaml`](scripts/data_custom.yaml) and make the class list
match `classes.txt` **exactly, in the same order**.

> ⚠️ **The one mistake that ruins everything.** If the order of names in
> `classes.txt` and `scripts/data_custom.yaml` disagree, every label is shifted — the model
> learns "healthy" when you meant "diseased". Nothing errors. Always double-check this before training.

---

## Step 3 — Train

```bash
python scripts/1_train.py
```

This takes a few hours. Start it in the evening and check in the morning.

What the settings mean:

| Setting | Meaning |
|---|---|
| `yolov8n.pt` | the **n**ano model — the small one that fits on a phone |
| `epochs=100` | how many times it re-reads all your photos |
| `imgsz=640` | photos are resized to 640×640 before study |

When it finishes you get **`runs/detect/train/weights/best.pt`**.
That is your trained model. It **cannot go on a phone yet**.

> Always start with nano. Bigger models score better on paper and are unusable
> on a phone — slow, and they flatten the battery.

---

## Step 4 — Convert it into a phone file

```bash
python scripts/3_export_tflite.py
```

This produces:

- `scripts/best_saved_model/best_float16.tflite` — about 6 MB. **This is the file the app uses.**
- `scripts/best_saved_model/best_float32.tflite` — a larger, unoptimized version.

TFLite (TensorFlow Lite) is just the file format phones understand. Think of it
like saving a document as a PDF so anything can open it.

The `float16` version stores the numbers more roughly — half precision. The file gets 
about 2× smaller and runs much faster on mobile hardware, with almost zero 
noticeable drop in accuracy in practice.

---

## Before you give it to anyone — check it works

```bash
python scripts/2_predict.py
```

Converting a file **never shows an error**, even when something has gone wrong.
So you must check by hand. The script runs all three checks:

1. **Does it still find the same things?** Compares the phone file against the
   original on the same photos.
2. **How often is it right?** Scores it on photos it has never seen.
3. **Is it fast enough?** Times it, repeatedly, so you can see it slow down.

If all three look good, it is ready for the field. If not, go back a step —
don't ship it and hope.

---

## Putting it on the phone

There is a working Flutter app in [`flutter_app/`](flutter_app/).

```bash
cd flutter_app
bash bootstrap.sh           # sets up Android, permissions, SDK levels
# copy scripts/best_saved_model/best_float16.tflite to assets/models/leaf.tflite
flutter run --release
```

Points the camera at a leaf, says **HEALTHY** or **NOT HEALTHY**, shows the
milliseconds per frame, works with no internet. Built on the official
`ultralytics_yolo` plugin.

It runs even before you have a model - it falls back to a general-purpose model
and says so on screen, so a live demo cannot fail. See
[`flutter_app/README.md`](flutter_app/README.md).

Presenting this? [`docs/RUN_OF_SHOW.md`](docs/RUN_OF_SHOW.md) has the timing and
the checklists; [`docs/SCRIPT.md`](docs/SCRIPT.md) is the word-for-word script
with stage directions and the demo run-through.

Building your own app instead, natively? [`android/README.md`](android/README.md)
covers the plain Android/Kotlin route and the settings that matter.

Either way: never type the class names into the app code. Read them from the
model or the manifest, or a future retrain will mislabel everything.

---

## Shortcuts

```bash
make check      # check the dataset
make train      # step 3
make export     # step 4
make verify     # the three checks
make all        # train, export, verify
```

---

## Five mistakes to avoid

1. **Testing on the training photos.** Gives a wonderful score that means nothing. Keep a set aside the model never sees.
2. **Name list in the wrong order.** Always manually check `classes.txt` and `scripts/data_custom.yaml` match exactly.
3. **Squashing the photo to fit.** The camera gives a rectangle, the model wants a square. Pad it with grey — never stretch it.
4. **Trusting your laptop's speed.** Always time it on a real field phone.
5. **Picking a bigger model "to be safe".** Start with nano, always.

---

## When something breaks

See [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## Licence

MIT — see [LICENSE](LICENSE).

---

## Putting this on GitHub

```bash
cd yolo-phone-starter
git init
git add .
git commit -m "YOLO on a phone - starter kit"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

Photos, labels and trained models are excluded by `.gitignore` on purpose —
they are too big for GitHub. Share those through the team drive.
