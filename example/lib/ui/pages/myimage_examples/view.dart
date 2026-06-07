import 'dart:io';
import 'dart:convert';

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
                  controller: pickImageController,

                  // imageBuilder: (context, image, index) {
                  //   if (image.link.trim().isNotEmpty &&
                  //       Uri.tryParse(image.link)?.hasAbsolutePath == true) {
                  //     return ClipOval(
                  //       child: Image.network(
                  //         image.link,
                  //         width: 120,
                  //         height: 120,
                  //         fit: BoxFit.cover,
                  //       ),
                  //     );
                  //   }
                  //   if (image.path.trim().isNotEmpty) {
                  //     return ClipOval(
                  //       child: Image.file(
                  //         File(image.path),
                  //         width: 120,
                  //         height: 120,
                  //         fit: BoxFit.cover,
                  //       ),
                  //     );
                  //   }
                  //   return Container(
                  //     width: 120,
                  //     height: 120,
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey.shade300,
                  //       shape: BoxShape.circle,
                  //     ),
                  //     child: const Column(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Icon(Icons.person, size: 60, color: Colors.grey),
                  //         Icon(Icons.camera_alt,
                  //             size: 24, color: Colors.black54),
                  //       ],
                  //     ),
                  //   );
                  // },
                  // maxImages: 1,
                  showDesc: true,
                  descriptionField: 'description',
                  showUploadResultDialog: false,
                  isDirectUpload: true,
                  // uploadFileFieldName: 'file',
                  // uploadIncludeReqType: false,
                  allowedImageSources: [MyImageSource.camera],
                  uploadUrl:
                      'https://app.smartsafetee.com/mobile-api/api/HseFormData/SaveAttachment',
                  uploadToken:
                      "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9zaWQiOiIzYTg4NGZjMy1iMDZjLTQzYjAtYWQwYi03Yjk3ZTliZTVjM2QiLCJVc2VyTmFtZSI6Im9iaXRlc3R1c2VyQG1haWwuY29tIiwiU3Vic2NyaXB0aW9uSWQiOiJjYzlkMWJmNC1kOThiLTQ3MjYtODcwYS05OTk2ZWI0MzM3ZWYiLCJDb21wYW55TmFtZSI6Ind3dmUiLCJuYmYiOjE3ODA4MjI2MTYsImV4cCI6MTc4MDg2NTgxNiwiaWF0IjoxNzgwODIyNjE2fQ.ScZ4i-21ey7yhVbXt-vZvU1axEGmln1dFnPm4m2KIsU",
                  uploadTokenRefresher: () async {
                    // Example refresher: simulate network call to obtain
                    // a fresh token. Replace with real auth logic in apps.
                    logger.i('Example: refreshing upload token...');
                    await Future<void>.delayed(const Duration(seconds: 1));
                    final newToken =
                        'Bearer EXAMPLE_REFRESHED_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
                    logger.i('Example: refreshed token=$newToken');
                    return newToken;
                  },
                  onUploadAuthExpired: () {
                    logger.w('Example: upload auth expired; prompt user');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Upload auth expired — please re-login'),
                      ),
                    );
                  },
                  // uploadFileFieldName: 'file',
                  // uploadIncludeReqType: false,
                  onImageChanged: (image) {
                    logger.i('Image changed: ${image.toString()}');
                  },
                  onImagesChanged: (results) {
                    logger.i('Image with desc changed:');
                    for (var r in results) {
                      logger.i(r.toString());
                    }
                  },

                  onFailDirectUploadPayload:
                      (List<DirectUploadPayload> payloads) {
                    // Payloads here are typed `DirectUploadPayload` objects.
                    // Convert to the older nested map format expected by the
                    // example app's persistence layer and retry logic.
                    logger.w('payloads attached to failed images');

                    try {
                      final persisted = payloads.map((p) {
                        return {
                          'url': p.url,
                          'headers': p.headers,
                          'fields': p.fields,
                          'file': {
                            'path': p.filePath,
                            'fileName': p.fileName,
                            'base64': p.base64 ?? ''
                          },
                          'uploadFileUrlKey': 'fileUrl',
                          'uploadImageIdKey': 'imageId',
                          'uploadCorrelationId': p.uploadCorrelationId,
                        };
                      }).toList();
                      if (persisted.isNotEmpty) {
                        viewModel.handleDirectUploadPayload(persisted);
                      }
                    } catch (e) {
                      logger.e('Failed to enqueue offline payloads: $e');
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (viewModel.offlineQueueCount > 0) ...[
                  Text('Offline Queue (${viewModel.offlineQueueCount})',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: viewModel.offlinePreviews.length,
                      itemBuilder: (context, idx) {
                        final p = viewModel.offlinePreviews[idx];
                        if (p.path != null &&
                            p.path!.isNotEmpty &&
                            File(p.path!).existsSync()) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(p.path!),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }
                        if (p.base64 != null && p.base64!.isNotEmpty) {
                          try {
                            final bytes = base64Decode(p.base64!);
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  bytes,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          } catch (_) {
                            // fallthrough to placeholder
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => viewModel.retryOfflineUploads(context),
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Retry Uploads'),
                      ),
                    ],
                  ),
                ],
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
                Text(
                  'Contoh direct upload single image: controller sudah sinkron sebelum onImageChanged/onRemoveImage.',
                  style: TextStyle(color: Colors.indigo.shade400),
                ),
                const SizedBox(height: 6),
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
                      final hasLink = image.link.trim().isNotEmpty;
                      final shownValue = hasLink
                          ? image.link
                          : (image.path.isNotEmpty
                              ? image.path
                              : '(empty result)');
                      final controllerCount = profileController.images.length;
                      singleImageLog =
                          'onImageChanged (${hasLink ? 'uploaded link' : 'local fallback'}): $shownValue | controller.images=$controllerCount';
                    });
                  },
                  onRemoveImage: (idx, image) {
                    setState(() {
                      final controllerCount = profileController.images.length;
                      singleRemoveLog =
                          'onRemoveImage: index=$idx, path=${image.path} | controller.images=$controllerCount';
                    });
                  },
                  allowedImageSources: [MyImageSource.doc],
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
                      '{\n  "controller": "profileController",\n  "maxImages": 1,\n  "allowedImageSources": ["doc"],\n  "isDirectUpload": true,\n  "uploadUrl": "https://catbox.moe/user/api.php",\n  "onImagesChanged": "(results) => { setState(() {}); ... }",\n  "onImageChanged": "(image) => print(image.link)",\n  "onRemoveImage": "(idx, image) => setState(() { singleRemoveLog = ... })"\n}',
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
                  Text(
                    'Link: ${profileController.images[0].link.isNotEmpty ? profileController.images[0].link : '(belum ada link dari response upload)'}',
                  ),
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
                  allowedImageSources: [MyImageSource.doc],
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
                      '{\n  "controller": "customsController",\n  "maxImages": 1,\n  "allowedImageSources": ["doc"],\n  "plusBuilder": "(context) => Container(width: 100, ...)",\n  "imageBuilder": "(context, image, index) => ClipRRect(...)",\n  "removeIconBuilder": "(context, idx, image) => Container(...)",\n  "onImagesChanged": "(results) => setState(() {})",\n  "onImageChanged": "(image) => setState(() { ... })",\n  "onRemoveImage": "(idx, image) => setState(() { ... })"\n}',
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
                  // uploadUrl: 'https://catbox.moe/user/api.php',
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
                      '{\n  "controller": "multiController",\n  "onImagesChanged": "(results) => setState(() {})",\n  "uploadToken": ""\n}',
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

                // ── Allowed Sources Examples ───────────────────────────────
                _buildSectionTitle('Allowed Sources', Colors.green.shade700,
                    Colors.green.shade400),
                _buildFieldTitle(
                    'Camera + Gallery (explicit)', Colors.green.shade600),
                FormFieldsMyImage(
                  controller: FormFieldsMyImageController(),
                  maxImages: 1,
                  allowedImageSources: [
                    MyImageSource.camera,
                    MyImageSource.gallery,
                  ],
                  onImageChanged: (image) => setState(() {}),
                ),
                const SizedBox(height: 8),
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
                      '{\n  "allowedImageSources": ["camera", "gallery"]\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),

                _buildFieldTitle(
                    'Camera + Gallery + Doc', Colors.green.shade600),
                FormFieldsMyImage(
                  controller: FormFieldsMyImageController(),
                  maxImages: 1,
                  allowedImageSources: [
                    MyImageSource.camera,
                    MyImageSource.gallery,
                    MyImageSource.doc,
                  ],
                  onImageChanged: (image) => setState(() {}),
                ),
                const SizedBox(height: 8),
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
                      '{\n  "allowedImageSources": ["camera", "gallery", "doc"]\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),

                _buildFieldTitle('Camera Only', Colors.green.shade600),
                FormFieldsMyImage(
                  controller: FormFieldsMyImageController(),
                  maxImages: 1,
                  allowedImageSources: [MyImageSource.camera],
                  onImageChanged: (image) => setState(() {}),
                ),
                const SizedBox(height: 8),
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
                      '{\n  "allowedImageSources": ["camera"]\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),

                _buildFieldTitle('Gallery Only', Colors.green.shade600),
                FormFieldsMyImage(
                  controller: FormFieldsMyImageController(),
                  maxImages: 1,
                  allowedImageSources: [MyImageSource.gallery],
                  onImageChanged: (image) => setState(() {}),
                ),
                const SizedBox(height: 8),
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
                      '{\n  "allowedImageSources": ["gallery"]\n}',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),

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

                // ── Validation & Label ─────────────────────────────────────
                _buildSectionTitle('Validation & Label',
                    Colors.deepPurple.shade700, Colors.deepPurple.shade400),

                // Label top + isRequired
                _buildFieldTitle(
                    'Label Top + isRequired', Colors.deepPurple.shade600),
                FormFieldsMyImage(
                  label: 'Proof of Identity',
                  labelPosition: LabelPosition.top,
                  isRequired: true,
                  maxImages: 1,
                  autovalidateMode: AutovalidateMode.always,
                  onImagesChanged: (_) {},
                ),
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
                      'FormFieldsMyImage(\n'
                      '  label: \'Proof of Identity\',\n'
                      '  labelPosition: LabelPosition.top,\n'
                      '  isRequired: true,\n'
                      '  maxImages: 1,\n'
                      '  autovalidateMode: AutovalidateMode.always,\n'
                      ')',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),

                // Label left + custom validator
                _buildFieldTitle('Label Left + Custom Validator',
                    Colors.deepPurple.shade600),
                FormFieldsMyImage(
                  label: 'Photo',
                  labelPosition: LabelPosition.left,
                  isRequired: true,
                  maxImages: 3,
                  validator: (images) {
                    if (images == null || images.isEmpty) {
                      return 'Please add at least one photo';
                    }
                    if (images.length < 2) {
                      return 'Please add at least 2 photos';
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.always,
                  onImagesChanged: (_) {},
                ),
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
                      'FormFieldsMyImage(\n'
                      '  label: \'Photo\',\n'
                      '  labelPosition: LabelPosition.left,\n'
                      '  isRequired: true,\n'
                      '  maxImages: 3,\n'
                      '  validator: (images) {\n'
                      '    if (images == null || images.isEmpty)\n'
                      '      return \'Please add at least one photo\';\n'
                      '    if (images.length < 2)\n'
                      '      return \'Please add at least 2 photos\';\n'
                      '    return null;\n'
                      '  },\n'
                      ')',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),

                // External error text
                _buildFieldTitle('externalErrorText (server-side error)',
                    Colors.deepPurple.shade600),
                FormFieldsMyImage(
                  label: 'Attachment',
                  labelPosition: LabelPosition.top,
                  maxImages: 1,
                  externalErrorText:
                      'Server rejected the file. Please try again.',
                  onImagesChanged: (_) {},
                ),
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
                      'FormFieldsMyImage(\n'
                      '  label: \'Attachment\',\n'
                      '  labelPosition: LabelPosition.top,\n'
                      '  maxImages: 1,\n'
                      '  externalErrorText: \'Server rejected the file.\',\n'
                      ')',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF333333)),
                    ),
                  ),
                ),

                // Form-level validation with GlobalKey<FormState>
                _buildFieldTitle('Form-level Validation (GlobalKey<FormState>)',
                    Colors.deepPurple.shade600),
                _ValidationFormExample(),
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

// ── Standalone form-level validation example ──────────────────────────────────

class _ValidationFormExample extends StatefulWidget {
  const _ValidationFormExample();

  @override
  State<_ValidationFormExample> createState() => _ValidationFormExampleState();
}

class _ValidationFormExampleState extends State<_ValidationFormExample> {
  final _formKey = GlobalKey<FormState>();
  final _photoController = FormFieldsMyImageController();
  bool _submitted = false;

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: .15)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormFieldsMyImage(
              controller: _photoController,
              label: 'Supporting Document',
              labelPosition: LabelPosition.top,
              isRequired: true,
              // maxImages: 2,1
              autovalidateMode: _submitted
                  ? AutovalidateMode.always
                  : AutovalidateMode.onUserInteraction,
              onImagesChanged: (_) {},
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() => _submitted = true);
                // Debug: show controller image count to diagnose validation timing
                if (_formKey.currentState?.validate() ?? false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Form submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Submit Form'),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
