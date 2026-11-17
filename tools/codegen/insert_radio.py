from pathlib import Path

p = Path('example/lib/ui/pages/radio_button_examples/view.dart')
lines = p.read_text(encoding='utf-8').splitlines()

indent = '                  '

jsons = [
    # 1: Basic Vertical Radio Button (gender)
    '{\n  "label": "Jenis Kelamin",\n  "isRequired": true,\n  "direction": "vertical",\n  "items": ["Laki-laki", "Perempuan", "Lainnya"],\n  "onChanged": "(value) => setRadio1(value ?? \'\')"\n}',
    # 2: Horizontal Radio Button (marital status)
    '{\n  "label": "Status Pernikahan",\n  "isRequired": true,\n  "direction": "horizontal",\n  "horizontalSideBySide": true,\n  "items": ["Belum Menikah", "Menikah", "Cerai"],\n  "onChanged": "(value) => setRadio2(value ?? \'\')"\n}',
    # 3: Custom Border & Colors (subscription plan)
    '{\n  "label": "Paket Berlangganan",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.purple",\n  "activeColor": "Colors.purple",\n  "radius": 15,\n  "items": ["Gratis", "Basic", "Premium", "Enterprise"],\n  "onChanged": "(value) => setRadio3(value ?? \'\')"\n}',
    # 4: Custom Item Spacing & Padding (delivery option)
    '{\n  "label": "Opsi Pengiriman",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.orange",\n  "activeColor": "Colors.orange",\n  "itemPadding": "EdgeInsets.symmetric(vertical: 12, horizontal: 8)",\n  "items": ["Ambil Sendiri", "Reguler", "Ekspres"],\n  "onChanged": "(value) => setRadio4(value ?? \'\')"\n}',
    # 5: Horizontal with Fill Items (rating)
    '{\n  "label": "Rating",\n  "isRequired": true,\n  "direction": "horizontal",\n  "horizontalSideBySide": true,\n  "borderColor": "Colors.amber",\n  "activeColor": "Colors.amber",\n  "items": ["⭐", "⭐⭐", "⭐⭐⭐", "⭐⭐⭐⭐", "⭐⭐⭐⭐⭐"],\n  "onChanged": "(value) => setRadio5(value ?? \'\')"\n}',
    # 6: Label Position Left (priority)
    '{\n  "label": "Prioritas",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.red",\n  "activeColor": "Colors.red",\n  "items": ["Rendah", "Sedang", "Tinggi"],\n  "onChanged": "(value) => setRadio6(value ?? \'\')"\n}',
    # 7: Custom Validation (payment method)
    '{\n  "label": "Metode Pembayaran",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.teal",\n  "activeColor": "Colors.teal",\n  "items": ["Kartu Kredit", "Kartu Debit", "PayPal", "COD"],\n  "validator": "(value) { if (value == null) return \'Pilih metode\'; if (value == \'COD\') return \'COD tidak tersedia\'; return null; }",\n  "onChanged": "(value) => setRadio7(value ?? \'\')"\n}',
    # 8: Custom Icon Size / newsletter frequency
    '{\n  "label": "Frekuensi Newsletter",\n  "isRequired": false,\n  "direction": "vertical",\n  "borderColor": "Colors.indigo",\n  "activeColor": "Colors.indigo",\n  "indicatorVerticalAlignment": "IndicatorVerticalAlignment.bottom",\n  "itemPadding": "EdgeInsets.symmetric(vertical: 10, horizontal: 4)",\n  "items": ["Harian", "Mingguan", "Bulanan", "Tidak Pernah"],\n  "onChanged": "(value) => setRadio8(value ?? \'\')"\n}',
    # 9: Label Position Bottom (communication method)
    '{\n  "label": "Metode Komunikasi",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.cyan",\n  "activeColor": "Colors.cyan",\n  "labelPosition": "LabelPosition.bottom",\n  "items": ["Email", "Telepon", "SMS", "Push Notification"],\n  "onChanged": "(value) => setRadio9(value ?? \'\')"\n}',
    # 10: Label Position Top (theme)
    '{\n  "label": "Tema",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.lime",\n  "activeColor": "Colors.lime",\n  "labelPosition": "LabelPosition.top",\n  "items": ["Terang", "Gelap", "Sistem"],\n  "onChanged": "(value) => setRadio10(value ?? \'\')"\n}',
    # 11: Label Position Left (accessibility)
    '{\n  "label": "Aksesibilitas",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.pink",\n  "activeColor": "Colors.pink",\n  "labelPosition": "LabelPosition.left",\n  "items": ["Aktif", "Nonaktif"],\n  "onChanged": "(value) => setRadio11(value ?? \'\')"\n}',
    # 12: Label Position Right (visibility)
    '{\n  "label": "Visibilitas",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.deepOrange",\n  "activeColor": "Colors.deepOrange",\n  "labelPosition": "LabelPosition.right",\n  "items": ["Publik", "Privat", "Terbatas"],\n  "onChanged": "(value) => setRadio12(value ?? \'\')"\n}',
    # 13: Label Position InBorder (verification status)
    '{\n  "label": "Status Verifikasi",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.green",\n  "activeColor": "Colors.green",\n  "labelPosition": "LabelPosition.inBorder",\n  "items": ["Terverifikasi", "Menunggu", "Belum Terverifikasi"],\n  "onChanged": "(value) => setRadio13(value ?? \'\')"\n}',
    # 14: Label Position None (notification preference)
    '{\n  "label": "Preferensi Notifikasi",\n  "isRequired": true,\n  "direction": "vertical",\n  "borderColor": "Colors.blue",\n  "activeColor": "Colors.blue",\n  "labelPosition": "LabelPosition.none",\n  "items": ["Aktif", "Nonaktif", "Senyap"],\n  "onChanged": "(value) => setRadio14(value ?? \'\')"\n}',
]

def dart_string(json_text):
    escaped = json_text.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
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
field_idxs.append(len(lines))

insertions = []
for sec_idx, (s, e) in enumerate(zip(field_idxs[:-1], field_idxs[1:])):
    rd_lines = [i for i in range(s, e) if 'buildResultDisplay(' in lines[i]]
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
