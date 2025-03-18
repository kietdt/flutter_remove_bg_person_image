import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_remove_bg_person/feature/remove_bg_person_image/logic/remove_bg_person_notifier.dart';

class RemoveBgPersonImage extends StatefulWidget {
  const RemoveBgPersonImage({
    super.key,
    required this.url,
  });

  final Uri url;

  @override
  State<RemoveBgPersonImage> createState() => _RemoveBgPersonImageState();
}

class _RemoveBgPersonImageState extends State<RemoveBgPersonImage> {
  final RemoveBgPersonNotifier removeBgPersonNotifier =
      RemoveBgPersonNotifier();

  @override
  void initState() {
    super.initState();
    removeBgPersonNotifier.removeBackgroundFromUrl(widget.url);
  }

  @override
  void dispose() {
    removeBgPersonNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: removeBgPersonNotifier,
        builder: (BuildContext context, Widget? child) {
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _buildImage(removeBgPersonNotifier.removedBgImage ??
                        removeBgPersonNotifier.orgImage),
                  ),
                  // Expanded(
                  //   child: _buildImage(removeBgPersonNotifier.orgImage),
                  // ),
                  // Expanded(
                  //   child: _buildImage(removeBgPersonNotifier.removedBgImage),
                  // ),
                ],
              ),
              if (removeBgPersonNotifier.isLoading) ...[
                _buildLoading(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: Colors.black.withOpacity(.1),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildImage(Uint8List? bytes) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: bytes != null
          ? Image.memory(
              bytes,
            )
          : const SizedBox(
              width: double.infinity,
            ),
    );
  }
}
