# Word-report embedded image archive

This folder contains the figures extracted from the Word documents found in:

- `任务8/task8_nature_output/`
- `有限元/`

The extraction covered 23 valid `.docx` files, 295 embedded image occurrences and 128 content-unique images. Repeated figures across formula-corrected and two-column report revisions were deduplicated by SHA-256 while preserving every source occurrence in [`REPORT_IMAGE_MANIFEST.csv`](REPORT_IMAGE_MANIFEST.csv).

The full visual index is available at [`report-gallery.html`](report-gallery.html). The JSON index used by that page is [`report-image-index.json`](report-image-index.json).

The images are copied from the Word package media streams (`word/media/`). They are not newly generated illustrations. Their source document and original embedded name are recorded in the manifest.

