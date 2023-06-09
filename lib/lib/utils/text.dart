extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');

  String removeDiacritics() {
    var withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String str = this;
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }

    return str;
  }

  /// Remove spaces and special characters
  String removeSpecialCharacters() {
    var withDia = ' _-+';

    String str = this;
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], "");
    }

    return str;
  }

  String get beautified {
    var beautifiedStr = '';
    for (var i = 0; i < length; i++) {
      beautifiedStr += substring(i, i + 1);
      if (i % 4 == 3) {
        beautifiedStr += '    ';
      }
      if (i % 16 == 15) {
        beautifiedStr += '\n';
      }
    }
    return beautifiedStr;
  }
}
