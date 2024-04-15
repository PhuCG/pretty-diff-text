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
    this.addedTextStyle = const TextStyle(
      color: Colors.green,
      backgroundColor: Color.fromARGB(255, 181, 216, 181),
    ),
    this.deletedTextStyle = const TextStyle(
      color: Colors.red,
      backgroundColor: Color.fromARGB(255, 253, 183, 183),
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
    List<Diff> diffs = dmp.diff(oldText, newText, false);
    dmp.diffEditCost = diffEditCost;
    cleanupDiffs(dmp, diffs);

    final textSpans_delete = List<TextSpan>.empty(growable: true);
    final textSpans_add = List<TextSpan>.empty(growable: true);

    List<TextSpan> merge_diff(Diff diff, TextStyle style) {
      final index = diffs.indexOf(diff);
      final ended = diff.text.endsWith(' ');
      final textSpan = <TextSpan>[];

      var nStyle = defaultTextStyle;
      if (diff.operation == -1 || diff.operation == 1) nStyle = style;

      if (ended) {
        if (index == 0) {
          textSpan.add(TextSpan(text: diff.text, style: nStyle));
        } else {
          final nIndex = index - 1;
          final nDiff = diffs[nIndex];
          final nEnded = nDiff.text.endsWith(' ');
          if (nEnded) {
            textSpan.add(TextSpan(text: diff.text, style: nStyle));
          } else {
            final currentDiffs = diff.text.split(" ");
            textSpan.add(TextSpan(text: currentDiffs.first, style: style));
            if (currentDiffs.length > 1) {
              for (int i = 1; i < currentDiffs.length; i++) {
                textSpan.add(TextSpan(text: " ", style: nStyle));
                textSpan.add(TextSpan(text: currentDiffs[i], style: nStyle));
              }
            }
          }
        }

        return textSpan;
      } else {
        if (index == diffs.length - 1) {
          final currentDiffs = diff.text.split(" ");
          if (currentDiffs.length > 1) {
            var j = 0;
            if (index != 0) {
              final pIndex = index - 1;
              final pDiff = diffs[pIndex];
              final pEnded = pDiff.text.endsWith(' ');
              if (pEnded == false) {
                j = 1;
                textSpan.add(TextSpan(text: currentDiffs.first, style: style));
                textSpan.add(TextSpan(text: " ", style: nStyle));
              }
            }
            for (int i = j; i < currentDiffs.length - 1; i++) {
              textSpan.add(TextSpan(text: currentDiffs[i], style: nStyle));
              textSpan.add(TextSpan(text: " ", style: nStyle));
            }
          }
          textSpan.add(TextSpan(text: currentDiffs.last, style: nStyle));
        } else {
          final nIndex = index + 1;
          final nDiff = diffs[nIndex];
          final nStarted = nDiff.text.startsWith(' ');
          if (nStarted) {
            final currentDiffs = diff.text.split(" ");
            if (currentDiffs.length > 1) {
              var j = 0;
              if (index != 0) {
                final pIndex = index - 1;
                final pDiff = diffs[pIndex];
                final pEnded = pDiff.text.endsWith(' ');
                if (pEnded == false) {
                  j = 1;
                  textSpan
                      .add(TextSpan(text: currentDiffs.first, style: style));
                  textSpan.add(TextSpan(text: " ", style: nStyle));
                }
              }
              for (int i = j; i < currentDiffs.length - 1; i++) {
                textSpan.add(TextSpan(text: currentDiffs[i], style: nStyle));
                textSpan.add(TextSpan(text: " ", style: nStyle));
              }
            }
            textSpan.add(TextSpan(text: diff.text, style: nStyle));
          } else {
            final currentDiffs = diff.text.split(" ");
            if (currentDiffs.length > 1) {
              var j = 0;
              if (index != 0) {
                final pIndex = index - 1;
                final pDiff = diffs[pIndex];
                final pEnded = pDiff.text.endsWith(' ');
                if (pEnded == false) {
                  j = 1;
                  textSpan
                      .add(TextSpan(text: currentDiffs.first, style: style));
                  textSpan.add(TextSpan(text: " ", style: nStyle));
                }
              }
              for (int i = j; i < currentDiffs.length - 1; i++) {
                textSpan.add(TextSpan(text: currentDiffs[i], style: nStyle));
                textSpan.add(TextSpan(text: " ", style: nStyle));
              }
            }
            textSpan.add(TextSpan(text: currentDiffs.last, style: style));
          }
        }

        return textSpan;
      }
    }

    for (int index = 0; index < diffs.length; index++) {
      final diff = diffs[index];
      if (diff.operation == -1) continue;

      textSpans_add.addAll(merge_diff(diff, addedTextStyle));
    }

    for (int index = 0; index < diffs.length; index++) {
      final diff = diffs[index];
      if (diff.operation == 1) continue;
      textSpans_delete.addAll(merge_diff(diff, deletedTextStyle));
    }

    return Column(
      children: [
        RichText(
          text: TextSpan(
            text: '',
            style: this.defaultTextStyle,
            children: textSpans_delete,
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
        SizedBox(height: 12),
        RichText(
          text: TextSpan(
            text: '',
            style: this.defaultTextStyle,
            children: textSpans_add,
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
