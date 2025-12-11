import 'package:expandable/expandable.dart';
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
  late ExpandableController _controller;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _controller = ExpandableController(initialExpanded: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        child: ExpandableNotifier(
          controller: _controller,
          child: ExpandablePanel(
            theme: const ExpandableThemeData(
              tapHeaderToExpand: true,
              tapBodyToExpand: false,
              tapBodyToCollapse: false,
              headerAlignment: ExpandablePanelHeaderAlignment.center,
              hasIcon: true,
              expandIcon: Icons.keyboard_arrow_down,
              collapseIcon: Icons.keyboard_arrow_up,
              iconPadding: EdgeInsets.all(18),
            ),

            // ---------------- HEADER ----------------
            header: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Checkbox(
                    value: _isSelected,
                    onChanged: (v) {
                      setState(() => _isSelected = v ?? false);
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.allergyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- COLLAPSED ----------------
            collapsed: const SizedBox.shrink(),

            // ---------------- EXPANDED ----------------
            expanded: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final name in widget.alternativeNames ?? [])
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: Text(name, style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
