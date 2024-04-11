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
    final commonWords = List<Diff>.empty(growable: true);

    for (int i = 0; i < diffs.length; i++) {
      if (diffs[i].operation == -1) {
        textSpans
            .add(TextSpan(text: diffs[i].text + ' ', style: deletedTextStyle));
        for (int a = i; a > 0; a--) {
          final index = a - 1;
          if (index > -1 && diffs[index].operation == 0) {
            final a1 = diffs[index].text.split(' ').last + diffs[i].text;
            if (diffs[index].text.split(' ').last.length > 1) {
              commonWords.add(Diff(-1, diffs[index].text.split(' ').last));
              if (a1.length > diffs[index].text.split(' ').last.length) {
                commonWords.add(Diff(-1, a1));
              }
            } else {
              commonWords.add(Diff(-1, a1));
            }
            break;
          }
        }
      }

      if (diffs[i].operation == 0) textSpans.add(TextSpan(text: diffs[i].text));

      if (diffs[i].operation == 1) {
        if (diffs[i].text.contains(' ')) {
          textSpans.add(TextSpan(text: diffs[i].text, style: addedTextStyle));
          commonWords.add(Diff(1, diffs[i].text));
        } else {
          textSpans.add(TextSpan(text: diffs[i].text, style: addedTextStyle));

          var newText = diffs[i].text;

          for (int a = i; a > 0; a--) {
            final index = a - 1;
            if (index > -1 && diffs[index].operation == 0) {
              final a1 = diffs[index].text.split(' ').last + diffs[i].text;

              if (diffs[index].text.split(' ').last.length > 1) {
                // commonWords.add(Diff(1, diffs[index].text.split(' ').last));
                newText = diffs[index].text.split(' ').last + newText;
                if (a1.length > diffs[index].text.split(' ').last.length) {
                  commonWords.add(Diff(-1, a1));
                }
              } else {
                commonWords.add(Diff(1, a1));
              }
              break;
            }
          }

          for (int b = i; b < diffs.length; b++) {
            final index = b + 1;
            if (index < diffs.length - 1 && diffs[index].operation == 0) {
              var a1 = diffs[index].text.split(' ').first;
              log(a1);
              if (a1.isNotEmpty) {
                newText = newText + a1;
                a1 = a1 + diffs[index].text;
                // commonWords.add(Diff(1, a1));
                break;
              }
            }
          }
          commonWords.add(Diff(1, newText));
        }
      }
    }

    final newCommonWords = List<Diff>.empty(growable: true);

    commonWords.forEach((element) {
      final list = element.text.split(' ');
      if (list.length == 1) {
        newCommonWords.add(element);
      } else {
        list.forEach((e) {
          if (e.isNotEmpty) newCommonWords.add(Diff(element.operation, e));
        });
      }
    });

    final firstLine = beautifullTextSpans(
      oldText,
      newCommonWords,
      deletedTextStyle,
    );

    final secondLine = beautifullTextSpans(
      newText,
      newCommonWords,
      addedTextStyle,
    );

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
      String text, List<Diff> commonWords, TextStyle style) {
    final textSpans = List<TextSpan>.empty(growable: true);
    final data = text.split(' ');

    for (int i = 0; i < data.length; i++) {
      var add = false;
      if (data[i].length > 1) {
        for (int j = 0; j < commonWords.length; j++) {
          final dataContains = data[i] == commonWords[j].text;
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
