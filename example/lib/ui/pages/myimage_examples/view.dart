import 'dart:io';

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'view_model.dart';

final logger = Logger();

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FormFieldsExamplesViewModel(),
      child: Consumer<FormFieldsExamplesViewModel>(
        builder: (context, viewModel, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                    'Basic Usage', Colors.teal.shade700, Colors.teal.shade400),
                _buildFieldTitle(
                    'With Description (showDesc)', Colors.teal.shade600),
                FormFieldsMyImage(
                  controller: FormFieldsMyImageController(),
                  maxImages: 1,
                  showDesc: true,
                  descriptionField: 'description',
                  isDirectUpload: true,
                  uploadUrl: 'https://catbox.moe/user/api.php',
                  onImagesChanged: (results) {
                    logger.i('Image with desc changed:');
                    for (var r in results) {
                      logger.i(r.toString());
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text('Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      '{\n  "controller": "FormFieldsMyImageController()",\n  "maxImages": 1,\n  "showDesc": true,\n  "descriptionField": "description",\n  "isDirectUpload": true,\n  "uploadUrl": "https://catbox.moe/user/api.php",\n  "onImagesChanged": "(results) => { ... }"\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildFieldTitle(
                    'With Default Network Images', Colors.teal.shade600),
                FormFieldsMyImage(
                  controller: networkImagesController,
                  maxImages: 5,
                  allow: false,
                  imageBuilder: (context, image, index) {
                    return (image.link.trim().isNotEmpty &&
                            Uri.tryParse(image.link)?.hasAbsolutePath == true)
                        ? Image.network(
                            image.link,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          )
                        : (image.path.trim().isNotEmpty
                            ? Image.file(
                                File(image.path),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ));
                  },
                  onRemoveImage: (index, image) => logger.i(
                    'Removed image at index $index: ${image.link.isNotEmpty ? image.link : image.path}',
                  ),
                  onImagesChanged: (images) => logger.i(
                    'Images changed: ${images.map((image) => image.link.isNotEmpty ? image.link : image.path).join(', ')}',
                  ),
                ),
                const SizedBox(height: 8),
                Text('Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      '{\n  "controller": "networkImagesController",\n  "maxImages": 5,\n  "allow": false,\n  "imageBuilder": "(context, image, index) => Image.network(image.link)",\n  "onRemoveImage": "(index, image) => logger.i(...)",\n  "onImagesChanged": "(images) => logger.i(...)"\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: networkImagesController,
                  builder: (context, _) {
                    if (networkImagesController.images.isEmpty) {
                      return SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text('Default network images:'),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: networkImagesController.images.length,
                            itemBuilder: (context, idx) {
                              final result =
                                  networkImagesController.images[idx];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (result.link.trim().isNotEmpty &&
                                          Uri.tryParse(
                                                result.link,
                                              )?.hasAbsolutePath ==
                                              true)
                                      ? Image.network(
                                          result.link,
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : (result.path.trim().isNotEmpty
                                          ? Image.file(
                                              File(result.path),
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                            )),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                _buildSectionTitle('Default Images', Colors.blue.shade700,
                    Colors.blue.shade400),
                _buildFieldTitle(
                    'With Default Asset Images', Colors.blue.shade600),
                FormFieldsMyImage(
                  controller: assetImagesController,
                  maxImages: 5,
                  onRemoveImage: (index, image) => logger.i(
                    'Removed image at index $index: ${image.link.isNotEmpty ? image.link : image.path}',
                  ),
                  onImagesChanged: (images) {
                    setState(() {});
                    logger.i(
                      'Images changed: ${images.map((image) => image.link.isNotEmpty ? image.link : image.path).join(', ')}',
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text('Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      '{\n  "controller": "assetImagesController",\n  "maxImages": 5,\n  "onRemoveImage": "(index, image) => logger.i(...)",\n  "onImagesChanged": "(images) => { setState(() {}); logger.i(...) }"\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),
                if (assetImagesController.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Default images:'),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: assetImagesController.images.length,
                      itemBuilder: (context, idx) {
                        final result = assetImagesController.images[idx];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (result.link).isNotEmpty
                                ? Image.network(
                                    result.link,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                : (result.path.isNotEmpty
                                    ? (result.path.startsWith('/') ||
                                            result.path.startsWith('file://')
                                        ? Image.file(
                                            File(result.path),
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            result.path,
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ))
                                    : Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      )),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                _buildSectionTitle('Single Image', Colors.indigo.shade700,
                    Colors.indigo.shade400),
                _buildFieldTitle(
                    'Profile Image (with Upload)', Colors.indigo.shade600),
                FormFieldsMyImage(
                  controller: profileController,
                  maxImages: 1,
                  onImagesChanged: (results) {
                    setState(() {});
                    logger.i('Profile image changed:');
                    for (var r in results) {
                      logger.i(r.toString());
                    }
                  },
                  onImageChanged: (image) {
                    setState(() {
                      singleImageLog =
                          'onImageChanged: ${image.path.isNotEmpty ? image.path : image.link}';
                    });
                  },
                  onRemoveImage: (idx, image) {
                    setState(() {
                      singleRemoveLog =
                          'onRemoveImage: index=$idx, path=${image.path}';
                    });
                  },
                  isDoc: true,
                  isDirectUpload: true,
                  uploadUrl: 'https://catbox.moe/user/api.php',
                ),
                const SizedBox(height: 8),
                Text('Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      '{\n  "controller": "profileController",\n  "maxImages": 1,\n  "isDoc": true,\n  "isDirectUpload": true,\n  "uploadUrl": "https://catbox.moe/user/api.php",\n  "onImagesChanged": "(results) => { setState(() {}); ... }",\n  "onImageChanged": "(image) => setState(() { singleImageLog = ... })",\n  "onRemoveImage": "(idx, image) => setState(() { singleRemoveLog = ... })"\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),
                if (singleImageLog != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Text(
                      singleImageLog!,
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                if (singleRemoveLog != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      singleRemoveLog!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (profileController.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Selected profile image:'),
                  profileController.images[0].path.isNotEmpty
                      ? Image.file(
                          File(profileController.images[0].path),
                          height: 100,
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                  Text(
                    'Base64: ${profileController.images[0].base64.substring(0, 20)}...',
                  ),
                  Text('Link: ${profileController.images[0].link}...'),
                ],
                _buildFieldTitle('Single Image Picker (Custom Builder)',
                    Colors.indigo.shade600),
                FormFieldsMyImage(
                  controller: customsController,
                  onImagesChanged: (results) {
                    setState(() {});
                  },
                  onImageChanged: (image) {
                    setState(() {
                      singleImageLog =
                          'onImageChanged: ${image.path.isNotEmpty ? image.path : image.link}';
                    });
                  },
                  onRemoveImage: (idx, image) {
                    setState(() {
                      singleRemoveLog =
                          'onRemoveImage: index=$idx, path=${image.path}';
                    });
                  },
                  isDoc: true,
                  maxImages: 1,
                  plusBuilder: (context) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.yellow[100],
                    ),
                    child: const Center(
                      child: Icon(Icons.star, color: Colors.red, size: 40),
                    ),
                  ),
                  imageBuilder: (context, image, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (image.link.trim().isNotEmpty &&
                              Uri.tryParse(image.link)?.hasAbsolutePath == true)
                          ? Image.network(
                              image.link,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                          : (image.path.trim().isNotEmpty
                              ? Image.file(
                                  File(image.path),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                )),
                    );
                  },
                  removeIconBuilder: (context, idx, image) {
                    final isValidNetwork = image.link.trim().isNotEmpty &&
                        Uri.tryParse(image.link)?.hasAbsolutePath == true;
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${idx + 1}',
                              style: TextStyle(color: Colors.red)),
                          SizedBox(width: 4),
                          isValidNetwork
                              ? Image.network(image.link, width: 24, height: 24)
                              : Icon(Icons.close, color: Colors.red),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text('Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      '{\n  "controller": "customsController",\n  "maxImages": 1,\n  "isDoc": true,\n  "plusBuilder": "(context) => Container(width: 100, ...)",\n  "imageBuilder": "(context, image, index) => ClipRRect(...)",\n  "removeIconBuilder": "(context, idx, image) => Container(...)",\n  "onImagesChanged": "(results) => setState(() {})",\n  "onImageChanged": "(image) => setState(() { ... })",\n  "onRemoveImage": "(idx, image) => setState(() { ... })"\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),
                if (singleImageLog != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Text(
                      singleImageLog!,
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                if (singleRemoveLog != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      singleRemoveLog!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (customsController.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Selected images:'),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: customsController.images.length,
                      itemBuilder: (context, idx) {
                        final result = customsController.images[idx];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: result.path.isNotEmpty
                                ? Image.file(
                                    File(result.path),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                _buildSectionTitle('Multi Image', Colors.purple.shade700,
                    Colors.purple.shade400),
                _buildFieldTitle('Multi Image Picker', Colors.purple.shade600),
                FormFieldsMyImage(
                  controller: multiController,
                  onImagesChanged: (results) {
                    setState(() {});
                  },
                  uploadUrl: 'https://catbox.moe/user/api.php',
                  uploadToken: '',
                ),
                const SizedBox(height: 8),
                Text('Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      '{\n  "controller": "multiController",\n  "onImagesChanged": "(results) => setState(() {})",\n  "uploadUrl": "https://catbox.moe/user/api.php",\n  "uploadToken": ""\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),
                if (multiController.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Selected images:'),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: multiController.images.length,
                      itemBuilder: (context, idx) {
                        final result = multiController.images[idx];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: result.path.trim().isNotEmpty
                                ? Image.file(
                                    File(result.path),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _buildFieldTitle('Multi Image Picker (Custom Builder)',
                    Colors.purple.shade600),
                FormFieldsMyImage(
                  controller: customController,
                  onImagesChanged: (results) {
                    setState(() {});
                  },
                  maxImages: null, // unlimited
                  plusBuilder: (context) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.yellow[100],
                    ),
                    child: const Center(
                      child: Icon(Icons.star, color: Colors.orange, size: 40),
                    ),
                  ),
                  removeIconBuilder: (context, idx, image) {
                    final isValidNetwork = image.link.trim().isNotEmpty &&
                        Uri.tryParse(image.link)?.hasAbsolutePath == true;
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${idx + 1}',
                              style: TextStyle(color: Colors.red)),
                          SizedBox(width: 4),
                          isValidNetwork
                              ? Image.network(image.link, width: 24, height: 24)
                              : Icon(Icons.close, color: Colors.red),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text('Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      '{\n  "controller": "customController",\n  "maxImages": null,\n  "plusBuilder": "(context) => Container(width: 100, ...)",\n  "removeIconBuilder": "(context, idx, image) => Container(...)",\n  "onImagesChanged": "(results) => setState(() {})"\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),
                if (customController.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Selected images:'),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: customController.images.length,
                      itemBuilder: (context, idx) {
                        final result = customController.images[idx];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(result.path),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // ── Controller.pickImage() ─────────────────────────────────
                _buildSectionTitle('Controller.pickImage()',
                    Colors.orange.shade700, Colors.orange.shade400),
                _buildFieldTitle(
                    'Trigger Picker from Controller', Colors.orange.shade600),
                FormFieldsMyImage(
                  controller: pickImageController,
                  maxImages: 5,
                  onImagesChanged: (results) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => pickImageController.pickImage(),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pick (choose)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            pickImageController.pickImage(source: 'camera'),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            pickImageController.pickImage(source: 'gallery'),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                if (pickImageController.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Selected images:'),
                  SizedBox(
                    height: 120,
                    child: AnimatedBuilder(
                      animation: pickImageController,
                      builder: (context, _) => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pickImageController.images.length,
                        itemBuilder: (context, idx) {
                          final result = pickImageController.images[idx];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(result.path),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color1, Color color2) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildFieldTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 18,
              color: color,
              margin: const EdgeInsets.only(right: 8)),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15, color: color)),
        ],
      ),
    );
  }
}
