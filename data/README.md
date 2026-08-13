# Put your photos here

Unzip your Label Studio YOLO export so it looks like this:

```
data/
├── train/
│   ├── images/     about 80% of your photos
│   └── labels/      
├── val/
│   ├── images/     about 20% - photos the model
│   └── labels/
must NEVER train on
└── testimages/   images for testing
```

