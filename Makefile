# Shortcuts. Run `make` on its own to see this list.

.PHONY: help check train export verify all clean

help:
	@echo ""
	@echo "  make check    check the dataset before training"
	@echo "  make train    step 3 - train the model (takes hours)"
	@echo "  make export   step 4 - make the phone file"
	@echo "  make verify   run the three checks"
	@echo "  make all      train, export and verify"
	@echo ""

check:
	@echo "Check not needed. Make sure your classes.txt matches data_custom.yaml"

train:
	python scripts/1_train.py

export:
	python scripts/3_export_tflite.py

verify:
	python scripts/2_predict.py

all: train export verify

clean:
	rm -rf runs scripts/best_saved_model
