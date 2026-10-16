import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

abstract class ShimmerBuilder {
  static Widget buildContactShimmer(
    BuildContext context, {
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? DefaultColor.lightGrey,
      highlightColor: highlightColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(width: formatWidth(44), height: formatWidth(44), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
          sw(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: formatWidth(100),
                height: formatWidth(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
              ),
              sh(4),
              Container(
                width: formatWidth(200),
                height: formatWidth(12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildActualityShimmer(
    BuildContext context, {
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? DefaultColor.lightGrey,
      highlightColor: highlightColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(width: formatWidth(44), height: formatWidth(44), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
          sw(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: formatWidth(100),
                height: formatWidth(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
              ),
              sh(4),
              Container(
                width: formatWidth(220),
                height: formatWidth(12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
              ),
              sh(4),
              Container(
                width: formatWidth(170),
                height: formatWidth(12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildCardShimmer(
    BuildContext context,
    Size cardSize, {
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? DefaultColor.lightGrey,
      highlightColor: highlightColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        width: cardSize.width,
        height: cardSize.height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
      ),
    );
  }

  static Widget buildListItemShimmer(
    BuildContext context,
    Size cardSize,
    int length, {
    Color? baseColor,
    Color? highlightColor,
    double? itemSpacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < length; i++)
          Shimmer.fromColors(
            baseColor: baseColor ?? DefaultColor.lightGrey,
            highlightColor: highlightColor ?? Theme.of(context).scaffoldBackgroundColor,
            child: Container(
              width: cardSize.width,
              height: cardSize.height,
              margin: EdgeInsets.only(bottom: i == length - 1 ? 0 : itemSpacing ?? formatHeight(6)),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
            ),
          ),
      ],
    );
  }
}
