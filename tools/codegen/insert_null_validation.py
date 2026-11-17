from pathlib import Path

p = Path('example/lib/ui/pages/null_non_null_validation_examples/view.dart')
lines = p.read_text(encoding='utf-8').splitlines()

indent = '                  '

jsons = [
    # 1: String Non-Nullable Required (ffFullName)
    '{\n  "type": "FormFields<String>",\n  "label": "Nama Lengkap",\n  "formType": "FormType.string",\n  "isRequired": true,\n  "currentValue": "",\n  "onChanged": "viewModel.setStringNonNullRequired"\n}',
    # 2: String Non-Nullable Optional (ffMiddleName)
    '{\n  "type": "FormFields<String>",\n  "label": "Nama Tengah",\n  "formType": "FormType.string",\n  "isRequired": false,\n  "currentValue": "",\n  "onChanged": "viewModel.setStringNonNullOptional"\n}',
    # 3: String Nullable Required (ffLastName)
    '{\n  "type": "FormFields<String?>",\n  "label": "Nama Belakang",\n  "formType": "FormType.string",\n  "isRequired": true,\n  "currentValue": null,\n  "onChanged": "viewModel.setStringNullRequired"\n}',
    # 4: String Nullable Optional (valNickname)
    '{\n  "type": "FormFields<String?>",\n  "label": "Panggilan",\n  "formType": "FormType.string",\n  "isRequired": false,\n  "currentValue": null,\n  "onChanged": "viewModel.setStringNullOptional"\n}',
    # 5: Int Non-Nullable Required (ffAge)
    '{\n  "type": "FormFields<int>",\n  "label": "Umur",\n  "formType": "FormType.string",\n  "isRequired": true,\n  "currentValue": 0,\n  "onChanged": "viewModel.setIntNonNullRequired"\n}',
    # 6: Int Non-Nullable Optional (valPhoneExtension)
    '{\n  "type": "FormFields<int>",\n  "label": "Ekstensi Telepon",\n  "formType": "FormType.string",\n  "isRequired": false,\n  "currentValue": 0,\n  "onChanged": "viewModel.setIntNonNullOptional"\n}',
    # 7: Int Nullable Required (ffQuantity)
    '{\n  "type": "FormFields<int?>",\n  "label": "Kuantitas",\n  "formType": "FormType.string",\n  "isRequired": true,\n  "currentValue": null,\n  "onChanged": "viewModel.setIntNullRequired"\n}',
    # 8: Int Nullable Optional (valEmployeeId)
    '{\n  "type": "FormFields<int?>",\n  "label": "ID Karyawan",\n  "formType": "FormType.string",\n  "isRequired": false,\n  "currentValue": null,\n  "onChanged": "viewModel.setIntNullOptional"\n}',
    # 9: Double Non-Nullable Required (ffProductPrice)
    '{\n  "type": "FormFields<double>",\n  "label": "Harga Produk",\n  "formType": "FormType.string",\n  "isRequired": true,\n  "currentValue": 0.0,\n  "prefix": "Text(\'$\')",\n  "onChanged": "viewModel.setDoubleNonNullRequired"\n}',
    # 10: Double Non-Nullable Optional (valShippingCost)
    '{\n  "type": "FormFields<double>",\n  "label": "Biaya Pengiriman",\n  "formType": "FormType.string",\n  "isRequired": false,\n  "currentValue": 0.0,\n  "prefix": "Text(\'$\')",\n  "onChanged": "viewModel.setDoubleNonNullOptional"\n}',
    # 11: Double Nullable Required (valDiscountRate)
    '{\n  "type": "FormFields<double?>",\n  "label": "Diskon (%)",\n  "formType": "FormType.string",\n  "isRequired": true,\n  "currentValue": null,\n  "suffix": "Text(\'%\')",\n  "onChanged": "viewModel.setDoubleNullRequired"\n}',
    # 12: Double Nullable Optional (valCommissionAmount)
    '{\n  "type": "FormFields<double?>",\n  "label": "Komisi",\n  "formType": "FormType.string",\n  "isRequired": false,\n  "currentValue": null,\n  "prefix": "Text(\'$\')",\n  "onChanged": "viewModel.setDoubleNullOptional"\n}',
    # 13: Custom Validation 1 (username)
    '{\n  "type": "FormFields<String>",\n  "label": "Username",\n  "formType": "FormType.string",\n  "isRequired": true,\n  "currentValue": "",\n  "validator": "(value) { min 3, max 20, only alphanumeric+underscore }",\n  "onChanged": "viewModel.setUsernameCustom"\n}',
    # 14: Custom Validation 2 (email)
    '{\n  "type": "FormFields<String?>",\n  "label": "Email",\n  "formType": "FormType.email",\n  "isRequired": false,\n  "currentValue": null,\n  "validator": "(value) { must be @company.com domain }",\n  "onChanged": "viewModel.setEmailCustom"\n}',
    # 15: Custom Validation 3 (age)
    '{\n  "type": "FormFields<int>",\n  "label": "Umur",\n  "formType": "FormType.string",\n  "isRequired": true,\n  "currentValue": 0,\n  "validator": "(value) { min 18, max 65 }",\n  "onChanged": "viewModel.setAgeCustom"\n}',
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

field_idxs = [i for i, l in enumerate(lines) if 'buildFieldTitle(' in l]
# Exclude the helper method definition at the end
field_idxs = [i for i in field_idxs if i < 530]
field_idxs.append(len(lines))

# Find where helper methods start (to avoid inserting inside them)
helper_start = next((i for i, l in enumerate(lines) if '  Widget buildFieldTitle(' in l or '  Widget buildResultDisplay(' in l), len(lines))

insertions = []
for sec_idx, (s, e) in enumerate(zip(field_idxs[:-1], field_idxs[1:])):
    rd_lines = [i for i in range(s, min(e, helper_start)) if 'buildResultDisplay(' in lines[i]]
    if not rd_lines:
        continue
    last_rd = rd_lines[-1]
    end_line = find_call_end(lines, last_rd, min(last_rd + 10, e))
    json_raw = jsons[sec_idx] if sec_idx < len(jsons) else '{\n  "onChanged": "(value) => ..."\n}'
    insertions.append((end_line, make_block(json_raw)))

insertions.sort(key=lambda x: x[0], reverse=True)
for end_line, block in insertions:
    lines.insert(end_line + 1, block)

p.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'Inserted {len(insertions)} blocks')
