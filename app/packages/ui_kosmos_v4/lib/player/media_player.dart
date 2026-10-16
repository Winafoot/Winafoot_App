import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class MediaPreviewerPage extends ConsumerStatefulWidget {
  final List<AssetEntity>? assets;
  final List<MediaModel>? media;
  final void Function(BuildContext)? onReturn;

  /// Theme
  final String? buttonThemeName;

  const MediaPreviewerPage({
    super.key,

    /// Core
    this.assets,
    this.media,
    this.onReturn,

    /// Theme
    this.buttonThemeName,
    // this.theme,
  }) : assert(
            (assets != null && assets.length > 0) ||
                (media != null && media.length > 0),
            "MediaPreviewerPage: assets or media must not be null or empty");

  @override
  ConsumerState<MediaPreviewerPage> createState() => _MediaPreviewerPageState();
}

class _MediaPreviewerPageState extends ConsumerState<MediaPreviewerPage> {
  final PageController _pageController = PageController();

  late final bool isSingleMedia =
      (widget.assets != null && widget.assets!.length == 1) ||
          (widget.media != null && widget.media!.length == 1);
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final KosmosButtonThemeData? _themeData = loadThemeData(
      null,
      widget.buttonThemeName ?? "image_previewer_back",
      () => KosmosButtonThemeData(
          iconColor: Colors.white,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(.65),
          )),
      isDark: ref.watch(isDarkModeProvider).isDarkMode,
    );
    if (!isSingleMedia) {
      return _listOfMedia(context);
    }

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                children: [
                  ...(widget.assets ?? widget.media ?? []).map((e) =>
                      _buildViewer(
                          asset: e is AssetEntity ? e : null,
                          media: e is MediaModel ? e : null))
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + formatWidth(4),
              left: formatWidth(15),
              child: ButtonBack(
                theme: _themeData,
                size: formatWidth(22),
                // padding: pwh(0, 6),
                onTap: () => widget.onReturn ?? Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer({AssetEntity? asset, MediaModel? media}) {
    Widget child = const SizedBox.shrink();

    if (asset != null) {
      if (asset.type == AssetType.image) {
        child = PhotoView(
          imageProvider: AssetEntityImageProvider(asset),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          initialScale: PhotoViewComputedScale.contained,
          loadingBuilder: (_, __) =>
              const Center(child: LoaderClassique(activeColor: Colors.white)),
        );
      } else if (asset.type == AssetType.video) {
        child = VideoApp(futureFile: asset.file);
      }
    } else {
      if (media!.mediaType == AssetType.video) {
        child = VideoApp(url: media.mediaUrl);
      } else if (media.mediaType == AssetType.image) {
        child = PhotoView(
          imageProvider: CachedNetworkImageProvider(media.mediaUrl!),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          initialScale: PhotoViewComputedScale.contained,
          loadingBuilder: (_, __) =>
              const Center(child: LoaderClassique(activeColor: Colors.white)),
        );
      }
    }

    return Container(
      child: child,
    );
  }

  Widget _listOfMedia(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: InkWell(
            onTap: () => widget.onReturn ?? Navigator.of(context).pop(),
            child: SizedBox(
              width: formatWidth(38),
              height: formatHeight(38),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),
        ),
        body: Scrollbar(
          controller: _controller,
          child: ListView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            children: [
              ...(widget.assets ?? widget.media ?? []).map((e) => Padding(
                    padding: EdgeInsets.only(bottom: formatHeight(8)),
                    child: InkWell(
                      onTap: () {
                        AutoRouter.of(context).pushWidget(
                          MediaPreviewerPage(
                            media: e is MediaModel ? [e] : null,
                            assets: e is AssetEntity ? [e] : null,
                          ),
                        );
                      },
                      child: _buildPreview(context, e),
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, Object e) {
    if (e is AssetEntity) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: formatHeight(200),
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder(
                future: e.file,
                builder: (context, snap) {
                  if (snap.data != null) {
                    return Image.file(snap.data as File, fit: BoxFit.cover);
                  }
                  return const Center(
                      child: LoaderClassique(activeColor: Colors.white));
                },
              ),
            ),
            if (e.type == AssetType.video) ...[
              Center(
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: formatWidth(42))),
            ],
          ],
        ),
      );
    } else {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: formatHeight(200),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: () {
                  MediaModel media = (e as MediaModel);
                  return media.mediaType == AssetType.image
                      ? media.mediaUrl ?? ""
                      : media.videoThumbnail ?? "";
                }.call(),
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                    child: LoaderClassique(activeColor: Colors.white)),
              ),
            ),
            if ((e as MediaModel).mediaType == AssetType.video) ...[
              Center(
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: formatWidth(42))),
            ],
          ],
        ),
      );
    }
  }
}
