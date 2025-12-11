import 'package:flutter/material.dart';

class AllergyListingWidget extends StatefulWidget {
  const AllergyListingWidget({
    super.key,
    this.allergyName = "Example allergy",
    required this.alternativeNames,
  });

  final String allergyName;
  final List<String>? alternativeNames;

  @override
  State<AllergyListingWidget> createState() => _AllergyListingWidgetState();
}

class _AllergyListingWidgetState extends State<AllergyListingWidget> {
  bool _isSelected = false;

  void _showAlternatives() {
    if (widget.alternativeNames == null || widget.alternativeNames!.isEmpty)
      return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.6;
        final width = MediaQuery.of(context).size.width * 0.9;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: width,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x1A000000),
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.allergyName} - Synonyms',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final name in widget.alternativeNames!)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x1A000000),
              offset: Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Only the text is tappable
              Expanded(
                child: GestureDetector(
                  onTap: _showAlternatives,
                  child: Text(
                    widget.allergyName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Switch.adaptive(
                value: _isSelected,
                onChanged: (newValue) {
                  setState(() {
                    _isSelected = newValue;
                  });
                },
                activeTrackColor: const Color(0xFFED260E),
                inactiveTrackColor: theme.disabledColor,
                inactiveThumbColor: theme.canvasColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
