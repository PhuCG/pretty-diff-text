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
  final DiffType diffType;

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
    ),
    this.diffTimeout = 1.0,
    this.diffCleanupType = DiffCleanupType.SEMANTIC,
    this.diffEditCost = 1,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.displayType = DisplayType.INLINE,
    this.diffType = DiffType.CHARACTER,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DiffMatchPatch dmp = DiffMatchPatch();
    dmp.diffTimeout = diffTimeout;
    List<Diff> diffs = dmp.diff(oldText, newText, false);
    cleanupDiffs(dmp, diffs);

    List<Diff> diffsByType;
    switch (diffType) {
      case DiffType.CHARACTER:
        diffsByType = diffs;
      case DiffType.WORD:
        diffsByType = diffByWord(diffs);
    }

    final inLineText = List<TextSpan>.empty(growable: true);
    final addLine = List<TextSpan>.empty(growable: true);
    final deleteLine = List<TextSpan>.empty(growable: true);

    diffsByType.forEach((cdiff) {
      inLineText.add(
        TextSpan(text: cdiff.text, style: getTextStyleByDiffOperation(cdiff)),
      );
      if (cdiff.operation == 0) {
        addLine.add(TextSpan(text: cdiff.text, style: defaultTextStyle));
        deleteLine.add(TextSpan(text: cdiff.text, style: defaultTextStyle));
      }
      if (cdiff.operation == 1)
        addLine.add(TextSpan(text: cdiff.text, style: addedTextStyle));
      if (cdiff.operation == -1)
        deleteLine.add(TextSpan(text: cdiff.text, style: deletedTextStyle));
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('In line by ${diffType.name}',
            style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        RichText(
          text: TextSpan(
            text: '',
            style: this.defaultTextStyle,
            children: inLineText,
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
        Text('Compare line by ${diffType.name}',
            style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        RichText(
          text: TextSpan(
            text: '',
            style: this.defaultTextStyle,
            children: deleteLine,
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
            children: addLine,
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

  List<Diff> diffByWord(List<Diff> diffs) {
    final diffs_part = List<Diff>.empty(growable: true);

    for (int i = 0; i < diffs.length; i++) {
      final cdiff = diffs[i];
      final length = cdiff.text.trim().length;

      final stated = cdiff.text.startsWith(' ');
      final ended = cdiff.text.endsWith(' ');

      if (length == 0 || stated && ended) {
        // just Space " "
        diffs_part.add(cdiff);
      } else {
        final started = cdiff.text.indexOf(' ');
        if (started != -1) {
          List<String> strings = cdiff.text.trim().split(' ');
          if (strings.length > 1) {
            List<String> parts = cdiff.text.split(' ');
            final a = cdiff.text.indexOf(' ');
            final b = cdiff.text.lastIndexOf(' ');
            if (parts.length <= 2) {
              String first = cdiff.text.substring(0, a + 1);
              if (first.isNotEmpty) {
                diffs_part.add(Diff(cdiff.operation, first));
              }
              if (parts.last.isNotEmpty) {
                String last = cdiff.text.substring(a + 1, cdiff.text.length);
                diffs_part.add(Diff(cdiff.operation, last));
              }
            } else {
              String first = cdiff.text.substring(0, a);
              if (first.isNotEmpty) {
                diffs_part.add(Diff(cdiff.operation, first));
              }
              if (a != b) {
                String middle = cdiff.text.substring(a, b + 1);
                diffs_part.add(Diff(cdiff.operation, middle));
              }
              if (parts.last.isNotEmpty) {
                String last = cdiff.text.substring(b + 1, cdiff.text.length);
                diffs_part.add(Diff(cdiff.operation, last));
              }
            }
          } else {
            diffs_part.add(cdiff);
          }
        } else {
          diffs_part.add(cdiff);
        }
      }
    }

    final diffByWords = List<Diff>.empty(growable: true);

    List<Diff> mergeCharater(List<Diff> diffs) {
      final addWord = StringBuffer('');
      final deleteWord = StringBuffer('');

      for (int i = 0; i < diffs.length; i++) {
        final cdiff = diffs[i];
        if (cdiff.operation == 0) {
          addWord.write(cdiff.text);
          deleteWord.write(cdiff.text);
        }
        if (cdiff.operation == 1) addWord.write(cdiff.text);
        if (cdiff.operation == -1) deleteWord.write(cdiff.text);
      }
      final dDiff = Diff(-1, '$deleteWord');
      final aDiff = Diff(1, '$addWord');
      return [dDiff, aDiff];
    }

    for (int j = 0; j < diffs_part.length; j++) {
      var addDiffs = <Diff>[];
      final cdiff = diffs_part[j];
      if (cdiff.text.endsWith(' ')) {
        diffByWords.add(cdiff);
      } else {
        var nIndex = j + 1;
        if (nIndex < diffs_part.length) {
          final nDiff = diffs_part[nIndex];
          if (nDiff.text.startsWith(' ')) {
            diffByWords.add(cdiff);
          } else {
            addDiffs.add(cdiff);
            while (true) {
              if (nIndex < diffs_part.length) {
                final nDiff = diffs_part[nIndex];
                if (nDiff.text.startsWith(' ')) break;
                addDiffs.add(nDiff);
                nIndex++;
                if (nDiff.text.endsWith(' ')) break;
              } else {
                break;
              }
            }
            diffByWords.addAll(mergeCharater(addDiffs));
            j = nIndex - 1;
          }
        } else {
          diffByWords.add(cdiff);
        }
      }
    }
    return diffByWords;
  }
}
