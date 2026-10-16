import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:video_player/video_player.dart';

class VideoApp extends StatefulWidget {
  final File? file;
  final Future<File?>? futureFile;
  final String? url;

  const VideoApp({
    Key? key,
    this.file,
    this.futureFile,
    this.url,
  }) : super(key: key);

  @override
  State<VideoApp> createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  VideoPlayerController? _controller;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (widget.file != null) {
      _controller = VideoPlayerController.file(widget.file!);
      await _controller!.initialize();
      _setupChewieController();
    } else if (widget.url != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
      await _controller!.initialize();
      _setupChewieController(autoPlay: true);
    } else if (widget.futureFile != null) {
      final file = await widget.futureFile!;
      if (file != null && mounted) {
        _controller = VideoPlayerController.file(file);
        await _controller!.initialize();
        _setupChewieController();
      }
    }
  }

  void _setupChewieController({bool autoPlay = false}) {
    if (_controller != null && mounted) {
      setState(() {
        chewieController = ChewieController(
          videoPlayerController: _controller!,
          autoPlay: autoPlay,
          customControls: CupertinoControls(
            backgroundColor: Colors.black.withOpacity(.5),
            iconColor: Colors.white,
          ),
          allowPlaybackSpeedChanging: false,
          draggableProgressBar: true,
          showControlsOnInitialize: false,
          allowMuting: false,
          showOptions: false,
          allowFullScreen: false,
          deviceOrientationsAfterFullScreen: [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          widget.url == null && widget.file == null && widget.futureFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LoaderClassique(activeColor: Colors.white),
                    sh(10),
                    Text(
                      "utils.loading".tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                )
              : _controller != null &&
                      _controller!.value.isInitialized &&
                      chewieController != null
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: Chewie(controller: chewieController!),
                    )
                  : const LoaderClassique(activeColor: Colors.white),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    chewieController?.dispose();
    super.dispose();
  }
}
