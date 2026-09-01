"""
Extract Gitlab metadata from the Environment Variables and write them into the
flatpak repository metadata file.
"""

import argparse
import os

from gi.repository import GLib

VARIABLES_ALWAYS_AVAILABLE = [
    "CI_API_V4_URL",
    "CI_COMMIT_BRANCH",
    "CI_COMMIT_DESCRIPTION",
    "CI_COMMIT_MESSAGE_IS_TRUNCATED",
    "CI_COMMIT_MESSAGE",
    "CI_COMMIT_SHA",
    "CI_COMMIT_TAG",
    "CI_COMMIT_TIMESTAMP",
    "CI_COMMIT_TITLE",
    "CI_JOB_STARTED_AT",
    "CI_JOB_URL",
    "CI_PIPELINE_ID",
    "CI_PIPELINE_IID",
    "CI_PIPELINE_URL",
    "CI_PROJECT_ID",
    "CI_PROJECT_NAME",
    "CI_PROJECT_TITLE",
    "CI_PROJECT_URL",
    "GITLAB_USER_ID",
    "GITLAB_USER_NAME",
]

VARIABLES_MR = [
    "CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED",
    "CI_MERGE_REQUEST_DESCRIPTION",
    "CI_MERGE_REQUEST_DRAFT",
    "CI_MERGE_REQUEST_ID",
    "CI_MERGE_REQUEST_IID",
    "CI_MERGE_REQUEST_LABELS",
    "CI_MERGE_REQUEST_MILESTONE",
    "CI_MERGE_REQUEST_PROJECT_ID",
    "CI_MERGE_REQUEST_PROJECT_PATH",
    "CI_MERGE_REQUEST_PROJECT_URL",
    "CI_MERGE_REQUEST_SOURCE_BRANCH_NAME",
    "CI_MERGE_REQUEST_SOURCE_BRANCH_SHA",
    "CI_MERGE_REQUEST_SOURCE_PROJECT_ID",
    "CI_MERGE_REQUEST_SOURCE_PROJECT_PATH",
    "CI_MERGE_REQUEST_SOURCE_PROJECT_URL",
    "CI_MERGE_REQUEST_TARGET_BRANCH_NAME",
    "CI_MERGE_REQUEST_TARGET_BRANCH_SHA",
    "CI_MERGE_REQUEST_TITLE",
]


def write_metadata(file: str):
    try:
        open(file, "x", encoding="utf-8")  # noqa: SIM115
    except FileExistsError:
        pass

    keyfile = GLib.KeyFile.new()
    keyfile.load_from_file(file, GLib.KeyFileFlags.NONE)

    for var in VARIABLES_ALWAYS_AVAILABLE:
        value = os.environ.get(var, "")
        keyfile.set_string("X-com.gitlab.CI", var, value)

    if os.environ.get("CI_MERGE_REQUEST_ID") is not None:
        for var in VARIABLES_MR:
            value = os.environ.get(var, "")
            keyfile.set_string("X-com.gitlab.CI.MergeRequest", var, value)

    keyfile.save_to_file(file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("file", help="Path to the flatpak metadata file")
    args = parser.parse_args()

    write_metadata(args.file)
