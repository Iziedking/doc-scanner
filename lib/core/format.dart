/// Tiny date formatting, so the app does not pull in a localization package
/// for one label. English month abbreviations match the app's locale for now.
const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "8 Jul 2026"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
