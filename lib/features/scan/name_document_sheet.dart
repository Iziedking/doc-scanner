import 'package:flutter/material.dart';

import '../../core/format.dart';

/// A bottom sheet to name a freshly scanned document. Returns the name or
/// null. The suggested default reads like a name, not a timestamp dump.
Future<String?> showNameDocumentSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _NameDocumentSheet(),
  );
}

/// Stateful so the TextEditingController is disposed with the sheet route
/// instead of leaking one per scan.
class _NameDocumentSheet extends StatefulWidget {
  const _NameDocumentSheet();

  @override
  State<_NameDocumentSheet> createState() => _NameDocumentSheetState();
}

class _NameDocumentSheetState extends State<_NameDocumentSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: 'Scan ${formatDate(DateTime.now())}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Name this document',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
