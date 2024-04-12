import 'dart:developer';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:pretty_diff_text/src/diff_cleanup_type.dart';

class PrettyDiffText extends StatelessWidget {
  /// The original text which is going to be compared with [newText].
  final String oldText;

  /// Edited text which is going to be compared with [oldText].
  final String newText;

  /// Default text style of RichText. Mainly will be used for the text which did not change.
  /// [addedTextStyle] and [deletedTextStyle] will inherit styles from it.
  final TextStyle defaultTextStyle;

  /// Text style of text which was added.
  final TextStyle addedTextStyle;

  /// Text style of text which was deleted.
  final TextStyle deletedTextStyle;

  /// See [DiffCleanupType] for types.
  final DiffCleanupType diffCleanupType;

  /// If the mapping phase of the diff computation takes longer than this,
  /// then the computation is truncated and the best solution to date is
  /// returned. While guaranteed to be correct, it may not be optimal.
  /// A timeout of '0' allows for unlimited computation.
  /// The default value is 1.0.
  final double diffTimeout;

  final DisplayType displayType;

  /// Cost of an empty edit operation in terms of edit characters.
  /// This value is used when [DiffCleanupType] is selected as [DiffCleanupType.EFFICIENCY]
  /// The larger the edit cost, the more aggressive the cleanup.
  /// The default value is 4.
  final int diffEditCost;

  /// !!! DERIVED PROPERTIES FROM FLUTTER'S [RichText] IN ORDER TO ALLOW CUSTOMIZABILITY !!!
  /// See [RichText] for documentation.
  ///
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final double textScaleFactor;
  final int? maxLines;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const PrettyDiffText({
    Key? key,
    required this.oldText,
    required this.newText,
    this.defaultTextStyle = const TextStyle(color: Colors.black),
    this.addedTextStyle = const TextStyle(color: Colors.green
        // backgroundColor: Color.fromARGB(255, 139, 197, 139),
        ),
    this.deletedTextStyle = const TextStyle(
      color: Colors.red,
      // backgroundColor: Color.fromARGB(255, 255, 129, 129),
      decoration: TextDecoration.lineThrough,
    ),
    this.diffTimeout = 1.0,
    this.diffCleanupType = DiffCleanupType.SEMANTIC,
    this.diffEditCost = 4,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.displayType = DisplayType.INLINE,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DiffMatchPatch dmp = DiffMatchPatch();
    dmp.diffTimeout = diffTimeout;
    dmp.diffEditCost = diffEditCost;
    List<Diff> diffs = dmp.diff(oldText, newText);

    cleanupDiffs(dmp, diffs);

    final textSpans = List<TextSpan>.empty(growable: true);

    final commonWords = List<String>.empty(growable: true);

    for (int i = 0; i < diffs.length; i++) {
      var commonText = '';
      if (diffs[i].operation == 0) {
        if (i == diffs.length - 1) {
          // lui
          final startText = diffs[i].text.startsWith(' ');
          if (!startText) {
            for (int j = i; j > 0; j--) {
              final index = j - 1;
              final diff = diffs[index];
              if (diff.operation == 1) {
                if (diff.text.endsWith('')) {
                  final a =
                      diff.text.split(' ').last + diffs[i].text.split(' ').last;
                  commonWords.add(a);
                }
                break;
              }
            }
            for (int j = i; j > 0; j--) {
              final index = j - 1;
              final diff = diffs[index];
              if (diff.operation == -1) {
                if (diff.text.endsWith('')) {
                  final a =
                      diff.text.split(' ').last + diffs[i].text.split(' ').last;
                  commonWords.add(a);
                }
                break;
              }
            }
            for (int j = i; j > 0; j--) {
              final index = j - 1;
              final diff = diffs[index];
              if (diff.operation == 0) {
                if (!diff.text.endsWith(' ')) {
                  final a = diff.text.split(' ').last +
                      diffs[i].text.split(' ').first;

                  commonWords.add(a);
                }
                break;
              }
            }
          }
        } else if (i > 0) {
          // lui
          final startText = diffs[i].text.startsWith(' ');
          if (!startText) {
            for (int j = i; j > 0; j--) {
              final index = j - 1;
              final diff = diffs[index];
              if (diff.operation == 0) {
                if (diff.text.endsWith('')) {
                  final a = diff.text.split(' ').last +
                      diffs[i].text.split(' ').first;
                  commonText = commonText + a;
                }
                break;
              }
            }
          }

          // toi
          final endText = diffs[i].text.endsWith(' ');
          if (!endText) {
            if (i < diffs.length && diffs[i + 1].operation == -1) {
              commonWords.add(diffs[i].text.split(' ').last);
            }

            for (int j = i; j < diffs.length; j++) {
              final index = j + 1;
              if (index < diffs.length) {
                final diff = diffs[index];
                if (diff.operation == 1) {
                  if (diff.text.startsWith('')) {
                    final a = diffs[i].text.split(' ').last +
                        diff.text.split(' ').first;
                    commonWords.add(diffs[i].text.split(' ').last);
                    commonText = commonText + a;
                  }
                  break;
                }
              }
            }
          }
        } else {
          // tim kiem toi
          final endText = diffs[i].text.endsWith(' ');
          if (!endText) {
            for (int j = i; j < diffs.length; j++) {
              final index = j + 1;
              if (index < diffs.length) {
                final diff = diffs[index];
                if (diff.operation == 1) {
                  if (diff.text.startsWith('')) {
                    final a = diffs[i].text.split(' ').last +
                        diff.text.split(' ').first;
                    commonText = commonText + a;
                    break;
                  }
                }
              }
            }
          }
        }
      }
      if (diffs[i].operation == 1) {
        // lui ve 0
        final startText = diffs[i].text.startsWith(' ');
        final space = diffs[i].text.trim().isEmpty;
        if (!startText || space) {
          for (int j = i; j > 0; j--) {
            final index = j - 1;
            final diff = diffs[index];
            if (diff.operation == 0) {
              if (diff.text.endsWith('')) {
                final a =
                    diff.text.split(' ').last + diffs[i].text.split(' ').first;
                commonWords.add(diff.text.split(' ').last);
                commonText = commonText + a;
              }
              break;
            }
          }
        }
        // tien toi 0
        final endText = diffs[i].text.endsWith(' ');
        if (endText) {}
        for (int j = i; j < diffs.length; j++) {
          final index = j + 1;
          if (index < diffs.length) {
            final diff = diffs[index];
            if (diff.operation == 0) {
              if (diff.text.startsWith('')) {
                commonText = commonText + diff.text.split(' ').first;
              }
              break;
            }
          }
        }
      }
      // -1
      if (diffs[i].operation == -1) {
        // lui ve 0
        final startText = diffs[i].text.startsWith(' ');
        if (!startText) {
          for (int j = i; j > 0; j--) {
            final index = j - 1;
            final diff = diffs[index];
            if (diff.operation == 0) {
              if (!diff.text.endsWith(' ')) {
                final a =
                    diff.text.split(' ').last + diffs[i].text.split(' ').first;
                commonWords.add(diff.text.split(' ').last);
                commonText = commonText + a;
              } else {
                commonText = commonText + diffs[i].text;
              }
              break;
            }
          }
        }
        // tien toi 0
        final endText = diffs[i].text.endsWith(' ');
        if (endText) break;
        for (int j = i; j < diffs.length; j++) {
          final index = j + 1;
          if (index < diffs.length) {
            final diff = diffs[index];
            if (diff.operation == 0) {
              if (diff.text.startsWith(' ')) {
                commonText = commonText + diff.text.split(' ').first;
              } else {
                commonText = commonText + diffs[i].text;
              }
              break;
            }
          }
        }
      }
      if (commonText.isNotEmpty) commonWords.add(commonText);
    }

    final firstLine =
        beautifullTextSpans(oldText, commonWords, deletedTextStyle);

    final secondLine =
        beautifullTextSpans(newText, commonWords, addedTextStyle);

    return displayType == DisplayType.INLINE
        ? Column(
            children: [
              RichText(
                text: TextSpan(
                  text: '',
                  style: this.defaultTextStyle,
                  children: textSpans,
                ),
                textAlign: this.textAlign,
                textDirection: this.textDirection,
                softWrap: this.softWrap,
                overflow: this.overflow,
                maxLines: this.maxLines,
                textScaler: TextScaler.linear(this.textScaleFactor),
                locale: this.locale,
                strutStyle: this.strutStyle,
                textWidthBasis: this.textWidthBasis,
                textHeightBehavior: this.textHeightBehavior,
              ),
            ],
          )
        : Column(
            children: [
              RichText(
                text: TextSpan(
                  text: '',
                  style: this.defaultTextStyle,
                  children: firstLine,
                ),
                textAlign: this.textAlign,
                textDirection: this.textDirection,
                softWrap: this.softWrap,
                overflow: this.overflow,
                maxLines: this.maxLines,
                textScaler: TextScaler.linear(this.textScaleFactor),
                locale: this.locale,
                strutStyle: this.strutStyle,
                textWidthBasis: this.textWidthBasis,
                textHeightBehavior: this.textHeightBehavior,
              ),
              RichText(
                text: TextSpan(
                  text: '',
                  style: this.defaultTextStyle,
                  children: secondLine,
                ),
                textAlign: this.textAlign,
                textDirection: this.textDirection,
                softWrap: this.softWrap,
                overflow: this.overflow,
                maxLines: this.maxLines,
                textScaler: TextScaler.linear(this.textScaleFactor),
                locale: this.locale,
                strutStyle: this.strutStyle,
                textWidthBasis: this.textWidthBasis,
                textHeightBehavior: this.textHeightBehavior,
              ),
            ],
          );
  }

  TextStyle getTextStyleByDiffOperation(Diff diff) {
    switch (diff.operation) {
      case DIFF_INSERT:
        return addedTextStyle;

      case DIFF_DELETE:
        return deletedTextStyle;

      case DIFF_EQUAL:
        return defaultTextStyle;

      default:
        throw "Unknown diff operation. Diff operation should be one of: [DIFF_INSERT], [DIFF_DELETE] or [DIFF_EQUAL].";
    }
  }

  List<TextSpan> beautifullTextSpans(
      String text, List<String> commonWords, TextStyle style) {
    final textSpans = List<TextSpan>.empty(growable: true);
    final data = text.split(' ');

    for (int i = 0; i < data.length; i++) {
      var add = false;
      if (data[i].length > 1) {
        for (int j = 0; j < commonWords.length; j++) {
          final dataContains = data[i] == commonWords[j];
          // final wordContains = commonWords[j].text.contains(data[i]);
          // log('$j ${data[i]} ${commonWords[j].text} $dataContains');

          if (dataContains) {
            textSpans.add(TextSpan(text: data[i] + ' ', style: style));
            add = true;
            break;
          }
        }
      }
      if (add == false) textSpans.add(TextSpan(text: data[i] + ' '));
    }
    return textSpans;
  }

  void cleanupDiffs(DiffMatchPatch dmp, List<Diff> diffs) {
    switch (diffCleanupType) {
      case DiffCleanupType.SEMANTIC:
        dmp.diffCleanupSemantic(diffs);
        break;
      case DiffCleanupType.EFFICIENCY:
        dmp.diffCleanupEfficiency(diffs);
        break;
      case DiffCleanupType.NONE:
        // No clean up, do nothing.
        break;
      default:
        throw "Unknown DiffCleanupType. DiffCleanupType should be one of: [SEMANTIC], [EFFICIENCY] or [NONE].";
    }
  }
}
