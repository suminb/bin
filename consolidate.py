"""This script consolidates dashboard cam videos by dates and category (front,
rear).
"""

from datetime import datetime
import glob
import os
import shutil
import subprocess
import sys

from typing import List


def parse_datetime(filename):
    """
    Example of filename: REC_2023_10_24_19_13_00_F.MP4
    """
    return datetime.strptime(filename[4:-6], "%Y_%m_%d_%H_%M_%S")


def consolidate_by_date_and_direction(paths: List[str]) -> dict:
    consolidated = {}
    for path in paths:
        filename = os.path.basename(path)
        dt = parse_datetime(filename)
        date_str = dt.strftime("%Y%m%d")
        direction = filename[-len("F.mp4")]

        key = (date_str, direction)

        consolidated.setdefault(key, [])
        consolidated[key].append(path)

    for key, value in consolidated.items():
        consolidated[key] = sorted(consolidated[key])

    return consolidated


# TODO: Calculate the actual time difference
def is_consecutive(prev_min, curr_min):
    return 0 <= (curr_min - prev_min) <= 2 or prev_min + 1 == curr_min + 60


def split_non_consecutive_filenames(consolidated: dict):
    splitted = {}
    for key, value in consolidated.items():
        date, direction = key
        sequence = 0

        key = (date, direction, sequence)
        splitted.setdefault(key, [])

        for prev, curr in zip([None] + value[:-1], value):
            if prev is not None:
                prev_dt = parse_datetime(os.path.basename(prev))
                curr_dt = parse_datetime(os.path.basename(curr))

                if not is_consecutive(prev_dt.minute, curr_dt.minute):
                    sequence += 1
                    key = (date, direction, sequence)
                    splitted.setdefault(key, [])

            splitted[key].append(curr)

    return splitted


def add_null_sequence_number(consolidated: dict):
    with_seq = {}
    for (date, direction), value in consolidated.items():
        key = (date, direction, 0)
        with_seq[key] = value
    return with_seq


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
    # Rule of thumb: split non-consecutive footages for driving;
    # no split for parking footages
    # base_path = "/Volumes/archive/Others/inavi/Driving"
    base_path = sys.argv[1]
    trash_path = sys.argv[2] # temporary
    consolidated = consolidate_by_date_and_direction(
        glob.glob(os.path.join(base_path, "*.MP4"))
    )
    split_non_consecutive = bool(int(sys.argv[3]))

    if split_non_consecutive:
        consolidated = split_non_consecutive_filenames(consolidated)
    else:
        consolidated = add_null_sequence_number(consolidated)

    for key, value in consolidated.items():
        date, direction, sequence = key

        concat_filename = f"/tmp/concat_{date}_{direction}_{sequence}.txt"
        generate_concat_file(value, concat_filename)

        output_filename = os.path.join(base_path, f"{date}_{direction}_{sequence}.mp4")
        if os.path.exists(output_filename):
            print(f"{output_filename} already exists. Skipping...")
            continue

        command = (
            f'ffmpeg -f concat -safe -0 -i "{concat_filename}" -c copy "{output_filename}"'
        )
        exit_code = os.system(command)
        if exit_code:
            raise RuntimeError(f"Failed with {exit_code}: {command}")
        # TODO: Adjust creation and modification dates https://improveandrepeat.com/2022/04/python-friday-120-modify-the-create-date-of-a-file/

        for path in value:
            print(f"Deleting {path}...")
            shutil.move(path, trash_path)
