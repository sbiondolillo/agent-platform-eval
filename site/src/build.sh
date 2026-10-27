#!/bin/sh
# Build site/index.html from site/src/report.src.html and the
# "## Report cells" section of each probes/<row>/finding.md.
# The footnotes on platform cells come from <template id="footnotes"> in the template.
# Run from any directory: sh site/src/build.sh
set -eu

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
export ROOT

python3 - <<'PY'
import html
import os
import re
import sys

root = os.environ["ROOT"]
src = os.path.join(root, "site", "src", "report.src.html")
out = os.path.join(root, "site", "index.html")
blob = "https://github.com/sbiondolillo/agent-platform-eval/blob/main/probes/%s/finding.md"

# The table order.
rows = [
    "cloud-logging", "substrate", "model-credential", "forge-credential",
    "vault-secret", "egress", "tool-model-policy", "run-history",
    "spend-attribution", "audit-record", "github-start", "crash-resume",
    "subagent-record", "toolchain", "branch-protection", "setup-cost",
]


def fail(msg):
    sys.stderr.write("build.sh: %s\n" % msg)
    sys.exit(1)


def cells(row):
    path = os.path.join(root, "probes", row, "finding.md")
    if not os.path.isfile(path):
        fail("%s: no finding.md" % row)
    text = open(path, encoding="utf-8").read()
    marker = "\n## Report cells\n"
    if text.count(marker) != 1:
        fail("%s: expected one '## Report cells' heading, found %d" % (row, text.count(marker)))
    section = text.split(marker, 1)[1]
    lines = [l for l in section.split("\n") if l.strip()]
    if any(l.startswith("#") for l in lines):
        fail("%s: '## Report cells' is not the last section" % row)
    cloud = [l[len("Cloud: "):] for l in lines if l.startswith("Cloud: ")]
    plat = [l[len("Platform: "):] for l in lines if l.startswith("Platform: ")]
    ma = [l[len("Managed Agents: "):] for l in lines if l.startswith("Managed Agents: ")]
    if len(cloud) != 1 or len(plat) != 1 or len(ma) != 1 or len(lines) != 3:
        fail("%s: expected one Cloud line, one Platform line and one Managed Agents line, found %d lines" % (row, len(lines)))
    for c in (cloud[0], plat[0], ma[0]):
        if "](" in c:
            fail("%s: a cell holds a Markdown link; the whole cell is already a link" % row)
        if c.count("`") % 2:
            fail("%s: unbalanced backtick in a cell" % row)
    return cloud[0], plat[0], ma[0]


def inline(text):
    # Escape, then render `code` spans. No other Markdown is allowed in a cell.
    parts = html.escape(text, quote=False).split("`")
    return "".join(p if i % 2 == 0 else "<code>%s</code>" % p for i, p in enumerate(parts))


template = open(src, encoding="utf-8").read()

# Footnotes on platform cells live in the template, in <template id="footnotes">.
# Each <li data-row="<row>"> says what an enterprise component changes in that row.
blocks = re.findall(r'\n[ \t]*<template id="footnotes">(.*?)</template>[ \t]*\n', template, re.S)
if len(blocks) != 1:
    fail("expected one <template id=\"footnotes\"> block in the template, found %d" % len(blocks))
items = re.findall(r'<li data-row="([^"]+)">(.*?)</li>', blocks[0], re.S)
if not items:
    fail("the footnotes block holds no <li data-row> item")
if blocks[0].count("<li") != len(items):
    fail("a footnote item has no data-row attribute")
notes = {}
for row, text in items:
    if row not in rows:
        fail("footnote data-row %r names no table row" % row)
    if row in notes:
        fail("%s: the row has two footnotes" % row)
    if not text.strip():
        fail("%s: the footnote is empty" % row)
    notes[row] = " ".join(text.split())
template = re.sub(r'\n[ \t]*<template id="footnotes">.*?</template>[ \t]*\n', "\n", template, flags=re.S)

# Number the footnotes in table order.
number = {}
for row in rows:
    if row in notes:
        number[row] = len(number) + 1

body = []
for row in rows:
    cloud, plat, ma = cells(row)
    href = blob % row
    mark = ""
    if row in number:
        mark = '<sup><a href="#fn-%d" id="fnref-%d">%d</a></sup>' % (number[row], number[row], number[row])
    body.append(
        '      <tr>\n'
        '        <th scope="row"><a href="%s">%s</a></th>\n'
        '        <td data-label="Cloud Sessions"><a class="cell" href="%s">%s</a></td>\n'
        '        <td data-label="Platform"><a class="cell" href="%s">%s</a>%s</td>\n'
        '        <td data-label="Managed Agents"><a class="cell" href="%s">%s</a></td>\n'
        '      </tr>' % (href, row, href, inline(cloud), href, inline(plat), mark, href, inline(ma))
    )

table = (
    '<table class="cells">\n'
    '    <thead>\n'
    '      <tr><th scope="col">row</th><th scope="col">Cloud Sessions</th><th scope="col">Platform</th><th scope="col">Managed Agents</th></tr>\n'
    '    </thead>\n'
    '    <tbody>\n' + "\n".join(body) + '\n'
    '    </tbody>\n'
    '  </table>'
)

# Check the rendered table: 16 rows, and each of the 48 cells links its own finding.
trs = re.findall(r"<tr>\s*<th scope=\"row\">.*?</tr>", table, re.S)
if len(trs) != 16:
    fail("expected 16 table rows, rendered %d" % len(trs))
proof = 0
for row, tr in zip(rows, trs):
    links = re.findall(r'<td data-label="[^"]+"><a class="cell" href="([^"]+)">', tr)
    if links != [blob % row] * 3:
        fail("%s: the three cells do not all link the finding" % row)
    proof += len(links)
if proof != 48:
    fail("expected 48 proof links, found %d" % proof)

refs = re.findall(r'<td data-label="Platform">[^\n]*<sup><a href="#fn-(\d+)" id="fnref-(\d+)">(\d+)</a></sup></td>', table)
if len(refs) != len(notes) or any(a != b or b != c for a, b, c in refs):
    fail("expected %d footnote marks in Platform cells, found %d" % (len(notes), len(refs)))
if table.count("<sup>") != len(notes):
    fail("a footnote mark sits outside a Platform cell")

fn_items = []
for row in rows:
    if row in number:
        n = number[row]
        fn_items.append(
            '    <li id="fn-%d"><strong>%s.</strong> %s <a href="#fnref-%d" aria-label="Back to the %s row">back</a></li>'
            % (n, row, notes[row], n, row))
footnotes = '<ol class="footnotes">\n' + "\n".join(fn_items) + '\n  </ol>'

if template.count("__TABLE__") != 1:
    fail("expected one __TABLE__ placeholder in the template, found %d" % template.count("__TABLE__"))
if template.count("__FOOTNOTES__") != 1:
    fail("expected one __FOOTNOTES__ placeholder in the template, found %d" % template.count("__FOOTNOTES__"))
page = template.replace("__TABLE__", table).replace("__FOOTNOTES__", footnotes)
if "__FOOTNOTES__" in page:
    fail("__FOOTNOTES__ was not replaced")
left = re.findall(r"__[A-Z][A-Z_]*__", page)
if left:
    fail("placeholder left in the output: %s" % ", ".join(sorted(set(left))))

header = ("<!-- generated by site/src/build.sh from site/src/report.src.html "
          "and probes/*/finding.md. Do not edit. -->\n")
data = (header + page).encode("utf-8")
with open(out, "wb") as f:
    f.write(data)
print("site/index.html: %d rows, %d proof links, %d footnotes, %d bytes" % (len(trs), proof, len(notes), len(data)))
PY
