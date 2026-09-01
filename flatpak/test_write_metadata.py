import os
from pathlib import Path

import pytest
from gi.repository import GLib
from write_metadata import write_metadata

MULTILINE_STRING = r"""We don't have to wrap the main view in an AdwToolbarView, as the window already
defines one.

hello this is after a newline



    and here is a tab	here another

" one double quote

' one single quote
🎉 complex emoji 🧑‍🧑‍🧒‍🧒👩🏾‍❤️‍💋‍👨🏼
\n one escaped newline

\t one escaped tab

\\\\  look at this \\ some random \$§&)=()§$=)$§?=(

$(execute me)"""

MULTILINE_STRING_2 = r"""
This is a commit title

and this a description
with $ and `` and "quotes"
even with a couple \backs\slashes
and maybe some codeblocks
```
#!/bin/bash

# a comment
test="Hello World"

# another comment
echo $test
```

Hopefully it works
"""


EXISTING_FILE_CONTENTS = r"""[Application]
name=org.gnome.font-viewerDevel
runtime=org.gnome.Platform/x86_64/master
sdk=org.gnome.Sdk/x86_64/master
tags=nightly;
"""

FINAL_FILE_CONTENTS = r"""[X-com.gitlab.CI]
CI_API_V4_URL=
CI_COMMIT_BRANCH=
CI_COMMIT_DESCRIPTION=We don't have to wrap the main view in an AdwToolbarView, as the window already\ndefines one.\n\nhello this is after a newline\n\n\n\n    and here is a tab	here another\n\n" one double quote\n\n' one single quote\n🎉 complex emoji 🧑‍🧑‍🧒‍🧒👩🏾‍❤️‍💋‍👨🏼\n\\n one escaped newline\n\n\\t one escaped tab\n\n\\\\\\\\  look at this \\\\ some random \\$§&)=()§$=)$§?=(\n\n$(execute me)
CI_COMMIT_MESSAGE_IS_TRUNCATED=
CI_COMMIT_MESSAGE=\nThis is a commit title\n\nand this a description\nwith $ and `` and "quotes"\neven with a couple \\backs\\slashes\nand maybe some codeblocks\n```\n#!/bin/bash\n\n# a comment\ntest="Hello World"\n\n# another comment\necho $test\n```\n\nHopefully it works\n
CI_COMMIT_SHA=
CI_COMMIT_TAG=
CI_COMMIT_TIMESTAMP=
CI_COMMIT_TITLE=
CI_JOB_STARTED_AT=
CI_JOB_URL=
CI_PIPELINE_ID=
CI_PIPELINE_IID=
CI_PIPELINE_URL=
CI_PROJECT_ID=
CI_PROJECT_NAME=
CI_PROJECT_TITLE=
CI_PROJECT_URL=
GITLAB_USER_ID=
GITLAB_USER_NAME=
"""


@pytest.fixture
def test_file_path(tmp_path):
    directory = tmp_path / "testdir"
    directory.mkdir()
    return str(directory / "metadata")


def test_write_metadata_new_file(test_file_path):
    write_metadata(test_file_path)
    assert Path(test_file_path).exists()

    keyfile = GLib.KeyFile.new()
    assert keyfile.load_from_file(test_file_path, GLib.KeyFileFlags.NONE)
    assert keyfile.get_string("X-com.gitlab.CI", "CI_PROJECT_NAME") == ""


def test_write_metadata_multiline(test_file_path):
    os.environ["CI_COMMIT_DESCRIPTION"] = MULTILINE_STRING
    os.environ["CI_COMMIT_MESSAGE"] = MULTILINE_STRING_2
    write_metadata(test_file_path)
    del os.environ["CI_COMMIT_DESCRIPTION"]
    del os.environ["CI_COMMIT_MESSAGE"]

    assert Path(test_file_path).exists()

    keyfile = GLib.KeyFile.new()
    assert keyfile.load_from_file(test_file_path, GLib.KeyFileFlags.NONE)
    assert (
        keyfile.get_string("X-com.gitlab.CI", "CI_COMMIT_DESCRIPTION")
        == MULTILINE_STRING
    )
    assert (
        keyfile.get_string("X-com.gitlab.CI", "CI_COMMIT_MESSAGE") == MULTILINE_STRING_2
    )
    del keyfile

    with open(test_file_path, "r", encoding="utf-8") as f:
        assert f.read() == FINAL_FILE_CONTENTS


def test_write_metadata_existing_file(test_file_path):
    with open(test_file_path, "w", encoding="utf-8") as f:
        f.write(EXISTING_FILE_CONTENTS)

    write_metadata(test_file_path)
    assert Path(test_file_path).exists()

    keyfile = GLib.KeyFile.new()
    assert keyfile.load_from_file(test_file_path, GLib.KeyFileFlags.NONE)
    assert keyfile.get_string("X-com.gitlab.CI", "CI_PROJECT_NAME") == ""
    assert keyfile.get_string("Application", "name") == "org.gnome.font-viewerDevel"
    assert (
        keyfile.get_string("Application", "runtime")
        == "org.gnome.Platform/x86_64/master"
    )


def test_write_metadata_mr(test_file_path):
    os.environ["CI_MERGE_REQUEST_ID"] = "1"
    write_metadata(test_file_path)
    del os.environ["CI_MERGE_REQUEST_ID"]

    assert Path(test_file_path).exists()

    keyfile = GLib.KeyFile.new()
    assert keyfile.load_from_file(test_file_path, GLib.KeyFileFlags.NONE)
    assert keyfile.get_string("X-com.gitlab.CI", "CI_PROJECT_NAME") == ""
    assert (
        keyfile.get_string("X-com.gitlab.CI.MergeRequest", "CI_MERGE_REQUEST_ID") == "1"
    )
    assert (
        keyfile.get_string(
            "X-com.gitlab.CI.MergeRequest", "CI_MERGE_REQUEST_PROJECT_URL"
        )
        == ""
    )
