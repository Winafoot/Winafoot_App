extension StringUtils on String {
  String autoCapitalize() {
    final tmp = trim();
    if (tmp.isEmpty) return tmp;
    return tmp[0].toUpperCase() + tmp.substring(1);
  }
}
