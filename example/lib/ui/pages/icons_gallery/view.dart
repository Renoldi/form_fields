import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'material_icons_all.dart';

class IconsGalleryPage extends StatefulWidget {
  const IconsGalleryPage({super.key});

  @override
  State<IconsGalleryPage> createState() => _IconsGalleryPageState();
}

class _IconsGalleryPageState extends State<IconsGalleryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  double _iconSize = 64;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = kAllMaterialIcons.entries.where((entry) {
      return entry.key.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Icons Gallery'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Icon',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Preview size'),
                Expanded(
                  child: Slider(
                    min: 40,
                    max: 100,
                    divisions: 14,
                    value: _iconSize,
                    label: _iconSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _iconSize = value;
                      });
                    },
                  ),
                ),
                Text('${_iconSize.round()}'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // crossAxisSpacing: 8,
                // mainAxisSpacing: 8,
                // childAspectRatio: 1,
              ),
              itemCount: filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = filteredEntries[index];
                return GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: entry.key));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied: ${entry.key}')),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(entry.value, size: _iconSize),
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Icons.${entry.key}',
                          style: const TextStyle(
                              fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
