import glob
import os
import re

import yt_dlp


def _progress_from_hook(data):
    total = data.get("total_bytes") or data.get("total_bytes_estimate") or 0
    downloaded = data.get("downloaded_bytes") or 0
    if total > 0:
        return max(0, min(100, int(downloaded * 100 / total)))

    percent = data.get("_percent_str") or ""
    match = re.search(r"(\d+(?:\.\d+)?)%", percent)
    if match:
        return max(0, min(100, int(float(match.group(1)))))
    return None


def download(url, fmt, output_template, work_dir, callback):
    os.makedirs(work_dir, exist_ok=True)

    def hook(data):
        status = data.get("status", "")
        if status == "downloading":
            progress = _progress_from_hook(data)
            if progress is not None:
                callback.onProgress(progress, "Downloading %d%%" % progress)
        elif status == "finished":
            callback.onProgress(99, "Processing media")

    options = {
        "format": fmt,
        "outtmpl": output_template,
        "noplaylist": True,
        "restrictfilenames": True,
        "progress_hooks": [hook],
        "quiet": True,
        "no_warnings": False,
    }

    with yt_dlp.YoutubeDL(options) as ydl:
        ydl.download([url])

    files = [path for path in glob.glob(os.path.join(work_dir, "*")) if os.path.isfile(path)]
    if not files:
        raise RuntimeError("yt-dlp finished but no output file was created")
    return max(files, key=os.path.getmtime)
