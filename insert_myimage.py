from pathlib import Path

p = Path('example/lib/ui/pages/myimage_examples/view.dart')
lines = p.read_text(encoding='utf-8').splitlines()

indent = '                '

jsons = [
    # 1: MyImage with Description (showDesc)
    '{\n  "controller": "FormFieldsMyImageController()",\n  "maxImages": 1,\n  "showDesc": true,\n  "descriptionField": "description",\n  "isDirectUpload": true,\n  "uploadUrl": "https://catbox.moe/user/api.php",\n  "onImagesChanged": "(results) => { ... }"\n}',
    # 2: MyImage with 2 Default Network Images
    '{\n  "controller": "networkImagesController",\n  "maxImages": 5,\n  "allow": false,\n  "imageBuilder": "(context, image, index) => Image.network(image.link)",\n  "onRemoveImage": "(index, image) => logger.i(...)",\n  "onImagesChanged": "(images) => logger.i(...)"\n}',
    # 3: MyImage with 2 Default Asset Images
    '{\n  "controller": "assetImagesController",\n  "maxImages": 5,\n  "onRemoveImage": "(index, image) => logger.i(...)",\n  "onImagesChanged": "(images) => { setState(() {}); logger.i(...) }"\n}',
    # 4: Single Profile Image
    '{\n  "controller": "profileController",\n  "maxImages": 1,\n  "isDoc": true,\n  "isDirectUpload": true,\n  "uploadUrl": "https://catbox.moe/user/api.php",\n  "onImagesChanged": "(results) => { setState(() {}); ... }",\n  "onImageChanged": "(image) => setState(() { singleImageLog = ... })",\n  "onRemoveImage": "(idx, image) => setState(() { singleRemoveLog = ... })"\n}',
    # 5: Single Image Picker (Custom Builder)
    '{\n  "controller": "customsController",\n  "maxImages": 1,\n  "isDoc": true,\n  "plusBuilder": "(context) => Container(width: 100, ...)",\n  "imageBuilder": "(context, image, index) => ClipRRect(...)",\n  "removeIconBuilder": "(context, idx, image) => Container(...)",\n  "onImagesChanged": "(results) => setState(() {})",\n  "onImageChanged": "(image) => setState(() { ... })",\n  "onRemoveImage": "(idx, image) => setState(() { ... })"\n}',
    # 6: Multi Image Picker
    '{\n  "controller": "multiController",\n  "onImagesChanged": "(results) => setState(() {})",\n  "uploadUrl": "https://catbox.moe/user/api.php",\n  "uploadToken": ""\n}',
    # 7: Multi Image Picker (Custom Builder)
    '{\n  "controller": "customController",\n  "maxImages": null,\n  "plusBuilder": "(context) => Container(width: 100, ...)",\n  "removeIconBuilder": "(context, idx, image) => Container(...)",\n  "onImagesChanged": "(results) => setState(() {})"\n}',
]

def dart_string(json_text):
    escaped = json_text.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n').replace('$', '\\$')
    return "'" + escaped + "'"

def find_call_end(lines, start_idx, end_limit):
    depth = 0
    for j in range(start_idx, end_limit):
        for ch in lines[j]:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    return j
    return start_idx

def make_block(json_text):
    s = dart_string(json_text)
    return (
        f"{indent}const SizedBox(height: 8),\n"
        f"{indent}Text('Contoh Pengisian (JSON):',\n"
        f"{indent}    style: TextStyle(fontWeight: FontWeight.w600)),\n"
        f"{indent}const SizedBox(height: 4),\n"
        f"{indent}Container(\n"
        f"{indent}  width: double.infinity,\n"
        f"{indent}  margin: const EdgeInsets.only(bottom: 16),\n"
        f"{indent}  padding: const EdgeInsets.symmetric(\n"
        f"{indent}      horizontal: 12, vertical: 10),\n"
        f"{indent}  decoration: BoxDecoration(\n"
        f"{indent}    color: Color(0xFFF5F5F7),\n"
        f"{indent}    borderRadius: BorderRadius.circular(10),\n"
        f"{indent}    border: Border.all(color: Color(0xFFE0E0E0)),\n"
        f"{indent}  ),\n"
        f"{indent}  child: SingleChildScrollView(\n"
        f"{indent}    scrollDirection: Axis.horizontal,\n"
        f"{indent}    child: SelectableText(\n"
        f"{indent}      {s},\n"
        f"{indent}      style: TextStyle(\n"
        f"{indent}          fontFamily: 'monospace',\n"
        f"{indent}          fontSize: 12,\n"
        f"{indent}          color: Color(0xFF333333)),\n"
        f"{indent}    ),\n"
        f"{indent}  ),\n"
        f"{indent}),"
    )

# Find all FormFieldsMyImage( call start lines
call_starts = [i for i, l in enumerate(lines) if 'FormFieldsMyImage(' in l]

insertions = []
for sec_idx, start in enumerate(call_starts):
    end_line = find_call_end(lines, start, min(start + 200, len(lines)))
    json_raw = jsons[sec_idx] if sec_idx < len(jsons) else '{\n  "onImagesChanged": "(results) => ..."\n}'
    insertions.append((end_line, make_block(json_raw)))

insertions.sort(key=lambda x: x[0], reverse=True)
for end_line, block in insertions:
    lines.insert(end_line + 1, block)

p.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'Inserted {len(insertions)} blocks')
