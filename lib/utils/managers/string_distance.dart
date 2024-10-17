/// Implementation from https://en.wikipedia.org/wiki/Levenshtein_distance
int levenstheinDistance(String a, String b) {
  var distances = List<List>.generate(
      a.length + 1,
      (i) => List<int>.generate(b.length + 1, (j) {
            if (i == 0) return j;
            if (j == 0) return i;
            return 0;
          }, growable: false),
      growable: false);

  for (var i = 1; i < distances.length; i++) {
    for (var j = 1; j < distances[0].length; j++) {
      var substitutionCost = 0;

      if (a[i - 1] != b[j - 1]) {
        substitutionCost = 1;
      }

      var minVal = distances[i - 1][j - 1] + substitutionCost;

      var newVal = distances[i - 1][j] + 1;
      if (newVal < minVal) minVal = newVal;

      newVal = distances[i][j - 1] + 1;
      if (newVal < minVal) minVal = newVal;

      distances[i][j] = minVal;
    }
  }

  return distances[distances.length - 1][distances[0].length - 1];
}
