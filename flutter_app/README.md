# Leaf Scanner — the Flutter app

Points the phone camera at a leaf and says **HEALTHY** or **NOT HEALTHY**, live,
with no internet connection.

Android only. Built on the official
[`ultralytics_yolo`](https://pub.dev/packages/ultralytics_yolo) plugin (`^0.6.11`).

---

## Run it in three commands

```bash
cd flutter_app
bash bootstrap.sh          # creates android/, sets minSdk 23, adds camera permission
flutter run --release
```

`bootstrap.sh` is safe to run twice. It only adds what is missing.

> **Use `--release`, not debug.** A debug build runs the model several times
> slower. Every "why is it so laggy" question after a demo traces back to this.

---

## Where your model goes

```
flutter_app/assets/models/leaf.tflite
```

Rename the `model_int8.tflite` that came out of
`scripts/3_export_tflite.py` (or the Colab notebook) to `leaf.tflite` and drop
it there. Then:

```bash
flutter clean && flutter pub get && flutter run --release
```

### There is no model in the repo on purpose

The app still starts without one. It falls back to a general-purpose model that
the plugin downloads and caches on first launch, and it puts an amber banner
across the screen saying **DEMO MODEL — detects everyday objects, not leaves**.

That fallback exists so a live demo cannot fail in front of an audience. It is
not a leaf detector and the app never pretends otherwise.

---

## What each file does

| File | What it is for |
|---|---|
| `lib/main.dart` | Entry point. Locks portrait so nothing rotates mid-demo. |
| `lib/app.dart` | Theme. Same greens as the slides. |
| `lib/model_source.dart` | Decides which model to load, and handles "there isn't one". |
| `lib/verdict.dart` | Turns detections into one word. **Edit this when you add classes.** |
| `lib/screens/scan_screen.dart` | The camera screen and all the controls. |
| `lib/widgets/verdict_banner.dart` | The big coloured HEALTHY / NOT HEALTHY panel. |
| `lib/widgets/stats_bar.dart` | Live ms-per-frame and FPS readout. |
| `lib/widgets/notice.dart` | The demo-model warning and the model-failed screen. |

### The one file you will need to edit

`lib/verdict.dart`. It holds the rule that decides which class names count as a
problem. If you retrain with four disease classes, add their names to
`_unhealthyWords`.

It deliberately defaults to **NOT HEALTHY** for any name it doesn't recognise.
Better to send someone to look at a healthy plant than to tell them a diseased
one is fine.

---

## The controls

| Control | What it does | Why it's there |
|---|---|---|
| **Hold** | Freezes the camera | Lets you talk about a detection instead of chasing it |
| **Light** | Torch on / off | Conference rooms are dark; so are 6am field checks |
| **Snap** | Saves the frame with boxes drawn on | Evidence, and slides for next time |
| **Flip** | Front / back camera | |
| **Sensitivity** | Confidence threshold | Drag it live to show what a threshold actually does |

The **ms per frame** readout in the corner is there for the talk: point at it
and say *"that number is why we put the model on the phone."*

---

## Demo day checklist

Do all of this the day **before**, not on the morning.

- [ ] Build in `--release` and install on the phone you will actually use
- [ ] Airplane mode on, then open the app — confirm it still detects
- [ ] Print 3–4 leaf photos on paper (glossy screens reflect stage lights)
- [ ] Test under the actual room lighting if you can
- [ ] Set screen brightness to maximum and screen timeout to 10 minutes
- [ ] Charge to 100% — detection uses roughly 20% an hour
- [ ] Have the **Snap** screenshots ready as a backup if the camera misbehaves
- [ ] Know where the **Hold** button is without looking

---

## Troubleshooting

**`MissingPluginException`** — `flutter clean && flutter pub get && flutter run`.

**App opens to a black rectangle** — camera permission was denied. Android
Settings → Apps → Leaf Scanner → Permissions → Camera.

**"The model would not load"** — the screen lists what to check, in order. The
most common cause is the file not being named exactly `leaf.tflite`.

**Boxes appear but every label is wrong** — the class order in your export does
not match what you trained. Re-run `scripts/1_check_dataset.py`.

**It runs but slowly** — you are in a debug build. Use `--release`.

**Detects nothing at all** — drag Sensitivity down to about 0.25. If it then
detects everything everywhere, your model is undertrained; go back to step 3.

---

## Licence note

`ultralytics_yolo` is **AGPL-3.0**. Fine for internal use, research and
teaching. If this ever ships as a commercial product, talk to Ultralytics about
an enterprise licence first.
