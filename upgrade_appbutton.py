from pathlib import Path
import re

p = Path('example/lib/ui/pages/app_button_examples/view.dart')
text = p.read_text(encoding='utf-8')

IND = '                  '  # 18 spaces (ListView child level)


def make_block(json_val):
    i, i2, i3 = IND, IND + '  ', IND + '    '
    return (
        f"{i}Text('Contoh Pengisian (JSON):', style: TextStyle(fontWeight: FontWeight.w600)),\n"
        f"{i}const SizedBox(height: 4),\n"
        f"{i}Container(\n"
        f"{i2}width: double.infinity,\n"
        f"{i2}margin: const EdgeInsets.only(bottom: 16),\n"
        f"{i2}padding: const EdgeInsets.symmetric(\n"
        f"{i2}    horizontal: 12, vertical: 10),\n"
        f"{i2}decoration: BoxDecoration(\n"
        f"{i3}color: Color(0xFFF5F5F7),\n"
        f"{i3}borderRadius: BorderRadius.circular(10),\n"
        f"{i3}border: Border.all(color: Color(0xFFE0E0E0)),\n"
        f"{i2}),\n"
        f"{i2}child: SingleChildScrollView(\n"
        f"{i3}scrollDirection: Axis.horizontal,\n"
        f"{i3}child: SelectableText(\n"
        f"{i3}  {json_val},\n"
        f"{i3}  style: TextStyle(\n"
        f"{i3}      fontFamily: 'monospace',\n"
        f"{i3}      fontSize: 12,\n"
        f"{i3}      color: Color(0xFF333333)),\n"
        f"{i3}),\n"
        f"{i2}),\n"
        f"{i}),\n"
    )


# ── Step 1: Upgrade existing plain SelectableText(monospace) blocks ──────────
# Matches: optional comment + optional SizedBox(4) + optional Text label + optional SizedBox(2) + SelectableText(...)
pattern = re.compile(
    r'(?:[ \t]+// Property JSON[^\n]*\n)?'
    r'(?:' + re.escape(f'{IND}const SizedBox(height: 4),\n') + r')?'
    r"(?:[ \t]+Text\('(?:Property JSON|Contoh penggunaan JSON):?'\),\n)?"
    r'(?:' + re.escape(f'{IND}const SizedBox(height: 2),\n') + r')?'
    r'[ \t]+SelectableText\(\n'
    r"([ \t]+'(?:[^'\\]|\\.)*'),\n"
    r"[ \t]+style: TextStyle\(fontFamily: 'monospace', fontSize: 13\),\n"
    r'[ \t]+\),\n'
)


def replacer(m):
    json_val = m.group(1).strip()
    return make_block(json_val)


before = text
text = pattern.sub(replacer, text)
upgraded = len(pattern.findall(before))
print(f'Upgraded blocks: {upgraded}')

# ── Step 2: Add missing block after AppButtonGroup ───────────────────────────
json_appbuttongroup = (
    "'{\\n"
    '  \\"widget\\": \\"AppButtonGroup\\",\\n'
    '  \\"spacing\\": 10,\\n'
    '  \\"runSpacing\\": 10,\\n'
    '  \\"children\\": \\"[SizedBox(width:170, child: AppButton(...)), ...]\\",\\n'
    '  \\"note\\": \\"Wraps multiple AppButtons in a Wrap layout\\"\\n'
    "}'"
)
anchor_group = (
    '                  ),\n'
    '                  const SizedBox(height: 12),\n'
    '                  SizedBox(\n'
    '                    width: 220,\n'
)
replacement_group = (
    '                  ),\n'
    + make_block(json_appbuttongroup)
    + '                  const SizedBox(height: 12),\n'
    '                  SizedBox(\n'
    '                    width: 220,\n'
)
if anchor_group in text:
    text = text.replace(anchor_group, replacement_group, 1)
    print('Added: AppButtonGroup block')
else:
    print('WARNING: AppButtonGroup anchor not found')

# ── Step 3: Add missing block after Disabled AppButton ───────────────────────
json_disabled = (
    "'{\\n"
    '  \\"type\\": \\"AppButtonType.filled\\",\\n'
    '  \\"text\\": \\"Disabled\\",\\n'
    '  \\"icon\\": \\"Icons.block_outlined\\",\\n'
    '  \\"onPressed\\": null\\n'
    "}'"
)
anchor_disabled = (
    '                      onPressed: null,\n'
    '                    ),\n'
    '                  ),\n'
    '                  const SizedBox(height: 16),\n'
    '                  Text(\n'
    "                    'Button Groups',\n"
)
replacement_disabled = (
    '                      onPressed: null,\n'
    '                    ),\n'
    '                  ),\n'
    + make_block(json_disabled)
    + '                  const SizedBox(height: 16),\n'
    '                  Text(\n'
    "                    'Button Groups',\n"
)
if anchor_disabled in text:
    text = text.replace(anchor_disabled, replacement_disabled, 1)
    print('Added: Disabled AppButton block')
else:
    print('WARNING: Disabled AppButton anchor not found')

# ── Step 4: Add missing block after AppSplitButton ───────────────────────────
json_split = (
    "'{\\n"
    '  \\"widget\\": \\"AppSplitButton<String>\\",\\n'
    '  \\"size\\": \\"AppButtonSize.large\\",\\n'
    '  \\"text\\": \\"Add to cart\\",\\n'
    '  \\"icon\\": \\"Icons.shopping_cart_outlined\\",\\n'
    '  \\"onPressed\\": \\"() { setState(() { _lastSplitAction = default; }) }\\",\\n'
    '  \\"items\\": \\"[AppSplitButtonItem(save, wishlist, gift)]\\",\\n'
    '  \\"onSelected\\": \\"(value) { setState(() { _lastSplitAction = value; }) }\\"\\n'
    "}'"
)
anchor_split = (
    '                    },\n'
    '                  ),\n'
    '                  const SizedBox(height: 6),\n'
    "                  Text('Last split action: $_lastSplitAction'),\n"
)
replacement_split = (
    '                    },\n'
    '                  ),\n'
    + make_block(json_split)
    + '                  const SizedBox(height: 6),\n'
    "                  Text('Last split action: \$_lastSplitAction'),\n"
)
if anchor_split in text:
    text = text.replace(anchor_split, replacement_split, 1)
    print('Added: AppSplitButton block')
else:
    print('WARNING: AppSplitButton anchor not found')

# ── Step 5: Add missing block after AppFabMenu ───────────────────────────────
json_fabmenu = (
    "'{\\n"
    '  \\"widget\\": \\"AppFabMenu\\",\\n'
    '  \\"size\\": \\"AppButtonSize.small\\",\\n'
    '  \\"items\\": \\"[AppFabMenuItem(First, Second, Third)]\\",\\n'
    '  \\"note\\": \\"Expandable FAB with labeled action items\\"\\n'
    "}'"
)
anchor_fabmenu = (
    '                  ),\n'
    '                  const SizedBox(height: 120),\n'
)
replacement_fabmenu = (
    '                  ),\n'
    + make_block(json_fabmenu)
    + '                  const SizedBox(height: 120),\n'
)
# Use rfind to target the last occurrence (the Align closing before SizedBox(120))
idx = text.rfind(anchor_fabmenu)
if idx != -1:
    text = text[:idx] + replacement_fabmenu + text[idx + len(anchor_fabmenu):]
    print('Added: AppFabMenu block')
else:
    print('WARNING: AppFabMenu anchor not found')

p.write_text(text, encoding='utf-8')
print('Done.')
