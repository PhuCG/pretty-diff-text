import 'dart:math' as math;

void main() {
  String sentence1 = "Hi nice meet you";
  String sentence2 = "Hi nice to meet you";

  correctSentence(sentence1, sentence2);
}

void correctSentence(String incorrect, String correct) {
  var words1 = incorrect.split(' ');
  var words2 = correct.split(' ');

  for (var i = 0; i < words1.length; i++) {
    if (i >= words2.length || words1[i] != words2[i]) {
      String correction = words2[i];
      // Check if the next word in the correct sentence matches the current incorrect word
      if (i + 1 < words2.length && words1[i] == words2[i + 1]) {
        correction += " ${words2[i + 1]}";
      }
      print("Câu sai: '${words1[i]}'");
      print("Sửa đúng: '$correction'");
      return;
    }
  }

  // In case the incorrect sentence is missing words at the end
  if (words1.length < words2.length) {
    print("Câu sai: '' (thiếu từ)");
    print("Sửa đúng: '${words2.sublist(words1.length).join(' ')}'");
  }
}
