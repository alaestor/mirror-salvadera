import argparse
import re
import sys
from pathlib import Path


# ============================================================================
# Configuration
# ============================================================================

DEFAULT_HEADER_LEVEL = 3

# One indentation level:
# - four spaces OR
# - one tab
INDENT_PATTERN = r"(?:    |\t)"

HEADER_TEXT = "---\ninclude_toc: true\n---\n"
FOOTER_TEXT = ""


# ============================================================================
# Regexes
# ============================================================================

DOCSTRING_SINGLE_RE = re.compile(r"^(\s*)---(?!-)(.*)$")
DOCSTRING_MULTI_START_RE = re.compile(r"^(\s*)--\[\[\{$")
DOCSTRING_MULTI_END_RE = re.compile(r"^\s*--\}\]\]\s*$")
RETURN_DOC_RE = re.compile(r"^(.*[A-Za-z0-9_].*?)\s*-->\s*(.+?)\s*$")

ALNUM_RE = re.compile(r"[A-Za-z0-9_]")
COMMENT_LINE_RE = re.compile(r"^\s*--")


# ============================================================================
# Helpers
# ============================================================================

def count_indent_levels(indent: str) -> int:
    token_re = re.compile(INDENT_PATTERN)

    pos = 0
    levels = 0

    while True:
        m = token_re.match(indent, pos)
        if not m:
            break

        levels += 1
        pos = m.end()

    return levels


def trim_multiline_indentation(lines, base_levels):
    """
    Remove:
      (base indentation level + 1 extra indentation token)
    from each line if present.
    """

    remove_levels = base_levels + 1
    token_re = re.compile(INDENT_PATTERN)

    trimmed = []

    for line in lines:
        pos = 0
        removed = 0

        while removed < remove_levels:
            m = token_re.match(line, pos)
            if not m:
                break

            pos = m.end()
            removed += 1

        trimmed.append(line[pos:])

    # normalize leading/trailing whitespace-only lines
    while trimmed and trimmed[0].strip() == "":
        trimmed.pop(0)

    while trimmed and trimmed[-1].strip() == "":
        trimmed.pop()

    return "\n".join(trimmed)


def is_standalone(previous_line: str) -> bool:
    return not ALNUM_RE.search(previous_line)


def strip_inline_comment(line: str) -> str:
    idx = line.find("--")

    if idx == -1:
        return line.rstrip()

    return line[:idx].rstrip()


def make_header(text: str, level: int) -> str:
    return f'{"#" * level} {text.strip()}'


def format_return_doc(text: str) -> str:
    if ":" in text:
        before, after = text.split(":", 1)
        before = before.strip()
        after = after.strip()

        if after:
            return (
                f"> **Returns:** {before}\n>\n> {after}"
            )

    return f"> **Returns:** {text.strip()}"


def append_block(out_blocks, text):
    text = text.strip()

    if text:
        out_blocks.append(text)

def add_header_footer(text):
    head = HEADER_TEXT.strip()
    foot = FOOTER_TEXT.strip()
    if head:
        head = head + '\n'
    return head + text + foot + '\n'


# ============================================================================
# Parsing
# ============================================================================

def parse_lua(source: str, base_header_level: int):
    lines = source.splitlines()

    out_blocks = []

    i = 0
    previous_line = ""

    while i < len(lines):
        line = lines[i]

        # --------------------------------------------------------------------
        # multiline docstring
        # --------------------------------------------------------------------

        multi_match = DOCSTRING_MULTI_START_RE.match(line)

        if multi_match:
            indent = multi_match.group(1)
            indent_levels = count_indent_levels(indent)

            content_lines = []

            i += 1

            while i < len(lines):
                if DOCSTRING_MULTI_END_RE.match(lines[i]):
                    break

                content_lines.append(lines[i])
                i += 1

            content = trim_multiline_indentation(
                content_lines,
                indent_levels
            )

            next_line = lines[i + 1] if i + 1 < len(lines) else ""

            attached = (
                next_line.strip()
                and not COMMENT_LINE_RE.match(next_line)
                and ALNUM_RE.search(next_line)
            )

            if attached:
                header_level = base_header_level + indent_levels
                code = strip_inline_comment(next_line)

                append_block(
                    out_blocks,
                    make_header(code, header_level)
                )

                append_block(out_blocks, content)

                ret_match = RETURN_DOC_RE.match(next_line)

                if ret_match:
                    append_block(
                        out_blocks,
                        format_return_doc(ret_match.group(2))
                    )

            else:
                append_block(out_blocks, content)

            previous_line = lines[i]
            i += 1
            if attached:
                i += 1
            continue

        # --------------------------------------------------------------------
        # single-line docstring
        # --------------------------------------------------------------------

        single_match = DOCSTRING_SINGLE_RE.match(line)

        if single_match:
            indent = single_match.group(1)
            content = single_match.group(2).lstrip()

            indent_levels = count_indent_levels(indent)

            next_line = lines[i + 1] if i + 1 < len(lines) else ""

            attached = (
                next_line.strip()
                and not COMMENT_LINE_RE.match(next_line)
                and ALNUM_RE.search(next_line)
            )

            if attached:
                header_level = base_header_level + indent_levels
                code = strip_inline_comment(next_line)

                append_block(
                    out_blocks,
                    make_header(code, header_level)
                )

                append_block(out_blocks, content)

                ret_match = RETURN_DOC_RE.match(next_line)

                if ret_match:
                    append_block(
                        out_blocks,
                        format_return_doc(ret_match.group(2))
                    )

            else:
                append_block(out_blocks, content)

            previous_line = line
            i += 1
            if attached:
                i += 1
            continue

        # --------------------------------------------------------------------
        # return-type docstring on its own
        # --------------------------------------------------------------------

        ret_match = RETURN_DOC_RE.match(line)

        if ret_match:
            code = strip_inline_comment(ret_match.group(1))

            if not COMMENT_LINE_RE.match(code):
                header = make_header(code, base_header_level)

                append_block(out_blocks, header)

                append_block(
                    out_blocks,
                    format_return_doc(ret_match.group(2))
                )

            previous_line = line
            i += 1
            continue

        previous_line = line
        i += 1

    blocks = []

    #if HEADER_TEXT.strip():
    #    blocks.append(HEADER_TEXT.strip())

    blocks.extend(out_blocks)

    #if FOOTER_TEXT.strip():
    #    blocks.append(FOOTER_TEXT.strip())

    #return "\n\n".join(blocks).strip() + "\n"
    return add_header_footer("\n\n".join(blocks).strip())


# ============================================================================
# Tests
# ============================================================================

TEST_INPUT = r'''
--- standalone singleline

--[[{
standalone
multiline

~~~lua
with some embedded codeblock
~~~
--}]]

-- ignored
--- standalone singleline followed by a comment (`--+`)
------ ignored

--- attached
x = 1

function f1() --> returntype
function f2() --> returntype: optional description

--- attached
function f3() --> with a returntype: and description

--[[{
multiline
attached to a table
--}]]
tbl = {

	--[[{
		multiline

			attached one level deep with internal indentation
	--}]]
	y = 5

	tbl2 = {
		--- attached level two
		x = y
		--- indented singleline standalone followed by non-alphanumeric characters
	}
}

--- # with a hash in the string
'''.strip("\n")


EXPECTED_OUTPUT = r'''
standalone singleline

standalone
multiline

~~~lua
with some embedded codeblock
~~~

standalone singleline followed by a comment (`--+`)

## x = 1

attached

## function f1()

> **Returns:** returntype

## function f2()

> **Returns:** returntype
>
> optional description

## function f3()

attached

> **Returns:** with a returntype
>
> and description

## tbl = {

multiline
attached to a table

### y = 5

multiline

	attached one level deep with internal indentation

#### x = y

attached level two

indented singleline standalone followed by non-alphanumeric characters

# with a hash in the string
'''.strip("\n")


def run_tests():
    result = parse_lua(TEST_INPUT, 2)

    expected = add_header_footer(EXPECTED_OUTPUT)

    assert result == expected, (
        "\n\n\n=== EXPECTED ===\n\n\n```\n"
        + expected
        + "\n```\n\n\n=== GOT ===\n\n\n```\n"
        + result
        + "\n```"
    )

    print("All tests passed.")


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Generate markdown documentation from bespoke Lua docstrings."
    )

    parser.add_argument(
        "input",
        nargs="?",
        help="Input Lua file"
    )

    parser.add_argument(
        "output",
        nargs="?",
        help="Optional output markdown file"
    )

    parser.add_argument(
        "-l",
        "--level",
        type=int,
        default=DEFAULT_HEADER_LEVEL,
        help="Starting markdown header level"
    )

    parser.add_argument(
        "--test",
        action="store_true",
        help="Run self-tests"
    )

    args = parser.parse_args()

    if args.test:
        run_tests()
        return

    if not args.input:
        parser.error("missing input file")

    input_path = Path(args.input)

    source = input_path.read_text(encoding="utf-8")

    output = parse_lua(source, args.level)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
    else:
        sys.stdout.write(output)


if __name__ == "__main__":
    main()
