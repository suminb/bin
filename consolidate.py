"""This script consolidates dashboard cam videos by dates and category (front,
rear).
"""


from datetime import datetime
import glob
import os
import subprocess

from typing import List


def parse_datetime(filename):
    """
    Example of filename: REC_2023_10_24_19_13_00_F.MP4
    """
    return datetime.strptime(filename[4:-6], "%Y_%m_%d_%H_%M_%S")


def consolidate_by_date_and_category(paths: List[str]) -> dict:
    consolidated = {}
    for path in paths:
        filename = os.path.basename(path)
        dt = parse_datetime(filename)
        date_str = dt.strftime("%Y%m%d")
        category = filename[-len("F.mp4")]

        key = (date_str, category)

        consolidated.setdefault(key, [])
        consolidated[key].append(path)

    for key, value in consolidated.items():
        consolidated[key] = sorted(consolidated[key])

    return consolidated


def generate_concat_file(paths: List[str], concat_file_path: str):
    """
    Given a text file `mylist.txt` containing file names as follows,

    file '/path/to/file1.mp4'
    file '/path/to/file2.mp4'
    file '/path/to/file3.mp4'

    we may execute the following command to consolidate media files:

    ffmpeg -f concat -safe 0 -i mylist.txt -c copy output.mp4
    """
    with open(concat_file_path, "w") as fout:
        for path in paths:
            path = os.path.abspath(path)
            fout.write(f"file '{path}'\n")


if __name__ == "__main__":
    base_path = "/Volumes/archive/Others/아이나비/Driving"
    consolidated = consolidate_by_date_and_category(
        glob.glob(os.path.join(base_path, "*.MP4"))
    )
    for key, value in consolidated.items():
        date, category = key

        concat_filename = f"/tmp/concat_{date}_{category}.txt"
        generate_concat_file(value, concat_filename)

        output_filename = os.path.join(base_path, f"{date}_{category}.mp4")
        command = (
            f"ffmpeg -f concat -safe -0 -i {concat_filename} -c copy {output_filename}"
        )
        exit_code = os.system(command)
        if exit_code:
            raise RuntimeError(f"Failed with {exit_code}: {command}")
