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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 40, thickness: 2),
                const Text(
                  'MyImage with Description (showDesc)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                MyImage(
                  controller: MyImageController(),
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
                const SizedBox(height: 24),
                const Text(
                  'MyImage with 2 Default Network Images',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                MyImage(
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
                const Divider(height: 40, thickness: 2),
                const Text(
                  'MyImage with 2 Default Asset Images',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                MyImage(
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
                                    ? Image.asset(
                                        result.path,
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
                Text(
                  'Single Profile Image',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                MyImage(
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
                const Divider(height: 40, thickness: 2),
                Text(
                  'single Image Picker (Custom Builder)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                MyImage(
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
                const SizedBox(height: 32),
                const Divider(height: 40, thickness: 2),
                Text(
                  'Multi Image Picker',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                MyImage(
                  controller: multiController,
                  onImagesChanged: (results) {
                    setState(() {});
                  },
                  uploadUrl: 'https://catbox.moe/user/api.php',
                  uploadToken: '',
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
                const SizedBox(height: 32), // Extra space to prevent overflow
                const Divider(height: 40, thickness: 2),
                Text(
                  'start Multi Image Picker (Custom Builder)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                MyImage(
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

                // Extra space to prevent overflow
              ],
            ),
          );
        },
      ),
    );
  }
}
