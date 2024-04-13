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
    int levenshteinDistance = dmp.diff_levenshtein(diffs);
    dmp.diffEditCost = levenshteinDistance;
    cleanupDiffs(dmp, diffs);

    final textSpans0 = List<TextSpan>.empty(growable: true);
    final textSpans1 = List<TextSpan>.empty(growable: true);
    final textSpans11 = List<TextSpan>.empty(growable: true);

    final textSpan = List<String>.empty(growable: true);

    //with 1 and -1
    String detected_word(String character, index) {
      var word = '';

      // Special case " "
      // Example workout -> work out
      if (character.trim().isEmpty) {
        for (int j = index - 1; j > -1; j--) {
          final diff = diffs[j];
          if (diff.operation == 0) {
            if (!diff.text.endsWith(' ')) {
              word = diff.text.split(' ').last + character;
            }
            break;
          }
        }

        for (int j = index + 1; j < diffs.length; j++) {
          final diff = diffs[j];
          if (diff.operation == 0) {
            if (!diff.text.startsWith(' ')) {
              if (word.isEmpty) word = character;
              word = word + diff.text.split(' ').first;
            }
            break;
          }
        }
        // add word without space
        textSpan.add(word.replaceAll(" ", ''));
        return word;
      }

      // kiem tra lui
      var startWord = '';
      final started = character.startsWith(' ');
      if (!started) {
        // ko khoảng trắng ở đầu
        for (int j = index - 1; j > -1; j--) {
          final diff = diffs[j];
          if (diff.operation == 0) {
            if (!diff.text.endsWith(' ')) {
              // Special case with 's'
              final firstCharacter = character.split(' ').first;
              if (firstCharacter == 's') {
                textSpan.add(diff.text.split(' ').last);
              }
              // kha nang
              word = diff.text.split(' ').last + character;
              startWord = diff.text.split(' ').last;
            }
            break;
          }
        }
      }

      var endWord = '';
      final ended = character.endsWith(' ');
      if (!ended) {
        // ko khoảng trắng ở cuối
        for (int j = index + 1; j < diffs.length; j++) {
          final diff = diffs[j];
          if (diff.operation == 0) {
            if (!diff.text.startsWith(' ')) {
              // kha nang
              if (word.isEmpty) word = character;
              word = word + diff.text.split(' ').first;
              endWord = diff.text.split(' ').first;
            }

            break;
          }
        }
      }

      if (word.isEmpty) return character;
      if (startWord.isNotEmpty && endWord.isNotEmpty) {
        final newWord = startWord + endWord;
        textSpan.add(newWord);
      }
      return word;
    }

    diffs.forEach((element) {
      textSpans0.add(TextSpan(
          text: element.text, style: getTextStyleByDiffOperation(element)));

      switch (element.operation) {
        case DIFF_INSERT:
          final index = diffs.indexOf(element);
          final word = detected_word(element.text, index);
          textSpan.add(word);
          textSpans1.add(TextSpan(text: element.text, style: addedTextStyle));

        case DIFF_DELETE:
          final index = diffs.indexOf(element);
          final word = detected_word(element.text, index);
          textSpan.add(word);
          textSpans11
              .add(TextSpan(text: element.text, style: deletedTextStyle));

        case DIFF_EQUAL:
          textSpans11.add(TextSpan(text: element.text));
          textSpans1.add(TextSpan(text: element.text));
      }
    });

    log(textSpan.toString());

    return displayType == DisplayType.INLINE
        ? Column(
            children: [
              RichText(
                text: TextSpan(
                  text: '',
                  style: this.defaultTextStyle,
                  children: textSpans0,
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
                  children: textSpans11,
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
                  children: textSpans1,
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

class TextData {
  // final TextSpan textSpan;
  final String textSpan;
  final int index;

  TextData(this.textSpan, this.index);
}
