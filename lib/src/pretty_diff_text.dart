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
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DiffMatchPatch dmp = DiffMatchPatch();
    dmp.diffTimeout = diffTimeout;
    List<Diff> diffs = dmp.diff(oldText, newText, false);

    cleanupDiffs(dmp, diffs);

    final newDiffs = List<Diff>.empty(growable: true);

    for (int i = 0; i < diffs.length; i++) {
      final cdiff = diffs[i];
      final length = cdiff.text.trim().length;

      final stated = cdiff.text.startsWith(' ');
      final ended = cdiff.text.endsWith(' ');

      if (length == 0 || stated && ended) {
        // just Space " "
        newDiffs.add(cdiff);
      } else {
        final started = cdiff.text.indexOf(' ');
        if (started != -1) {
          List<String> parts = cdiff.text.split(' ');

          if (parts.length > 1) {
            String first = parts.first;
            if (first.isNotEmpty) {
              if (parts.last.isEmpty) first += " ";
              newDiffs.add(Diff(cdiff.operation, first));
            }

            if (parts.length > 2) {
              String middle =
                  ' ' + parts.sublist(1, parts.length - 1).join(' ');
              if (parts.last.isEmpty) middle += " ";
              newDiffs.add(Diff(cdiff.operation, middle));
            }
            if (parts.last.isNotEmpty) {
              String last = ' ' + parts.last;
              newDiffs.add(Diff(cdiff.operation, last));
            }
          } else {
            newDiffs.add(cdiff);
          }
        } else {
          newDiffs.add(cdiff);
        }
      }
    }

    final newWords = List<Diff>.empty(growable: true);

    List<Diff> mergeCharater(List<Diff> diffs) {
      final aBuffer = StringBuffer('');
      final dBuffer = StringBuffer('');

      for (int i = 0; i < diffs.length; i++) {
        final cdiff = diffs[i];
        if (cdiff.operation == 0) {
          aBuffer.write(cdiff.text);
          dBuffer.write(cdiff.text);
        }
        if (cdiff.operation == 1) aBuffer.write(cdiff.text);
        if (cdiff.operation == -1) dBuffer.write(cdiff.text);
      }
      final dDiff = Diff(-1, '$dBuffer');
      final aDiff = Diff(1, '$aBuffer');
      return [dDiff, aDiff];
    }

    for (int j = 0; j < newDiffs.length; j++) {
      var addDiffs = <Diff>[];
      final cdiff = newDiffs[j];
      if (cdiff.text.endsWith(' ')) {
        newWords.add(cdiff);
      } else {
        var nIndex = j + 1;
        if (nIndex < newDiffs.length) {
          final nDiff = newDiffs[nIndex];
          if (nDiff.text.startsWith(' ')) {
            newWords.add(cdiff);
          } else {
            addDiffs.add(cdiff);
            while (true) {
              if (nIndex < newDiffs.length) {
                final nDiff = newDiffs[nIndex];
                if (nDiff.text.startsWith(' ')) break;
                addDiffs.add(nDiff);
                nIndex++;
              } else {
                break;
              }
            }
            newWords.addAll(mergeCharater(addDiffs));
            j = nIndex - 1;
          }
        } else {
          //Todo Last with first space
          newWords.add(cdiff);
        }
      }
    }

    final textSpans = List<TextSpan>.empty(growable: true);
    final textSpans_add_merge = List<TextSpan>.empty(growable: true);
    final textSpans_delete_merge = List<TextSpan>.empty(growable: true);
    newWords.forEach((cdiff) {
      textSpans.add(
        TextSpan(text: cdiff.text, style: getTextStyleByDiffOperation(cdiff)),
      );

      if (cdiff.operation == 0) {
        textSpans_add_merge.add(TextSpan(
          text: cdiff.text,
          style: defaultTextStyle,
        ));
        textSpans_delete_merge.add(TextSpan(
          text: cdiff.text,
          style: defaultTextStyle,
        ));
      }
      if (cdiff.operation == 1)
        textSpans_add_merge.add(TextSpan(
          text: cdiff.text,
          style: addedTextStyle,
        ));
      if (cdiff.operation == -1)
        textSpans_delete_merge.add(TextSpan(
          text: cdiff.text,
          style: deletedTextStyle,
        ));
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('In line by word', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
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
        SizedBox(height: 12),
        Text('Compare line by word',
            style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        RichText(
          text: TextSpan(
            text: '',
            style: this.defaultTextStyle,
            children: textSpans_delete_merge,
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
            children: textSpans_add_merge,
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
