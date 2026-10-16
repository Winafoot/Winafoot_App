import 'dart:io';

import 'package:core_kosmos/core_kosmos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_kosmos_v4/_deprecated/cta/cta.dart';

@Deprecated("deprecated from 2.0.0")
abstract class Alert {
  static showWebDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String defaultActionText,
    VoidCallback? onClickAction,
    String? cancelActionText,
    bool forceToUseIosStyle = false,
    bool forceToUseMaterialStyle = false,
    bool useSafeArea = false,
    EdgeInsets contentPadding = EdgeInsets.zero,
    EdgeInsets actionsPadding = const EdgeInsets.only(bottom: 12),
    EdgeInsets insetPadding = const EdgeInsets.symmetric(horizontal: 47),
    Color? barrierColor,
    double radius = 10,
    Icon? backIcon,
    Color clair = Colors.white,
    Color fonce = const Color(0xFF02132B),
    TextStyle? descStyle,
    List<Widget>? actionButton,
  }) async {
    await showGeneralDialog(
        context: context,
        pageBuilder: (_, __, ___) {
          return StatefulBuilder(builder: (__, StateSetter newState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: AlertDialog(
                  contentPadding: contentPadding,
                  actionsPadding: actionsPadding,
                  insetPadding: insetPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(radius)),
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 11),
                            child: InkWell(
                              onTap: () => Navigator.of(_).pop(true),
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                  height: 44,
                                  width: 44,
                                  child: backIcon ??
                                      Icon(
                                        Icons.clear,
                                        color: const Color(0xFF02132B)
                                            .withOpacity(0.15),
                                      )),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: sp(19),
                            fontWeight: FontWeight.w600,
                            color: fonce,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 31.5)
                            .copyWith(top: 5),
                        child: Text(
                          content,
                          textAlign: TextAlign.center,
                          style: descStyle ??
                              TextStyle(
                                fontSize: sp(14),
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFA7ADB5),
                              ),
                        ),
                      ),
                      const SizedBox(height: 26),
                    ],
                  ),
                  actions: <Widget>[
                    if (actionButton != null)
                      ...actionButton
                    else
                      CTA.primary(
                        width: 140,
                        textButton: defaultActionText,
                        radius: 7,
                        onTap: onClickAction ?? () => Navigator.pop(_),
                      ),
                  ],
                ),
              ),
            );
          });
        });
  }

  static show({
    required BuildContext context,
    required String title,
    required String content,
    required String defaultActionText,
    VoidCallback? onClickAction,
    String? cancelActionText,
    bool forceToUseIosStyle = false,
    bool forceToUseMaterialStyle = false,
    bool useSafeArea = false,
    EdgeInsets contentPadding = EdgeInsets.zero,
    EdgeInsets actionsPadding = const EdgeInsets.only(bottom: 12),
    EdgeInsets insetPadding = const EdgeInsets.symmetric(horizontal: 47),
    Color? barrierColor,
    double radius = 10,
    Icon? backIcon,
    Color clair = Colors.white,
    Color fonce = const Color(0xFF02132B),
    TextStyle? descStyle,
    Widget? actionButton,
  }) async {
    if ((!Platform.isIOS && !forceToUseIosStyle) || forceToUseMaterialStyle) {
      return showDialog(
        barrierColor: barrierColor ?? Colors.black.withOpacity(0.66),
        useSafeArea: useSafeArea,
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: contentPadding,
          actionsPadding: actionsPadding,
          insetPadding: insetPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
          ),
          backgroundColor:
              MediaQuery.of(context).platformBrightness == Brightness.dark
                  ? fonce
                  : clair,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 11),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(true),
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                          height: 44,
                          width: 44,
                          child: backIcon ??
                              Icon(
                                Icons.clear,
                                color:
                                    const Color(0xFF02132B).withOpacity(0.15),
                              )),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? clair
                          : fonce),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 31.5)
                    .copyWith(top: 5),
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: descStyle ??
                      TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark
                              ? Colors.white.withOpacity(0.4)
                              : const Color(0xFFA7ADB5)),
                ),
              ),
              const SizedBox(height: 26),
            ],
          ),
          actions: <Widget>[
            Center(
              child: actionButton ??
                  CTA.primary(
                    width: 140,
                    textButton: defaultActionText,
                    radius: 7,
                    onTap: onClickAction ?? () => Navigator.pop(context),
                  ),
            ),
          ],
        ),
      );
    }

    return showCupertinoDialog(
      context: context,
      builder: (context) => Theme(
        data: MediaQuery.of(context).platformBrightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light(),
        child: CupertinoAlertDialog(
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Icon(
                        Icons.clear,
                        size: 24,
                        color: MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? const Color(0XFF838383)
                            : const Color(0XFFD8D8D8),
                      )),
                ],
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 14,
              ),
              Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? Colors.white.withOpacity(0.4)
                        : const Color(0XFF0E0E0E).withOpacity(0.3)),
              ),
              const SizedBox(
                height: 30,
              ),
            ],
          ),
          actions: <Widget>[
            if (cancelActionText != null)
              CupertinoDialogAction(
                onPressed:
                    onClickAction ?? () => Navigator.of(context).pop(true),
                child: Text(
                  cancelActionText,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            CupertinoDialogAction(
              onPressed: onClickAction ?? () => Navigator.of(context).pop(true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  defaultActionText,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
