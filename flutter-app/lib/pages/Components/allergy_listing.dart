import 'package:flutter/material.dart';

class AllergyListingWidget extends StatelessWidget {
  const AllergyListingWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onChanged,
  });

  // The full allergy data map from your JSON assets (keys like 'stof', 'synoniemen', etc.)
  final Map<String, dynamic> item;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  void _showDetails(BuildContext context) {
    final String stof = (item['stof'] ?? '').toString();
    final String cas = (item['cas'] ?? '').toString();
    final String concentratie = item['concentratie']?.toString() ?? '';
    final List<dynamic> synoniemenRaw =
        (item['synoniemen'] as List<dynamic>?) ?? [];
    final List<dynamic> kruisreactiesRaw =
        (item['kruisreacties'] as List<dynamic>?) ?? [];
    final List<dynamic> vaakGebruikRaw =
        (item['vaak voorkomende gebruiken/rol'] as List<dynamic>?) ?? [];
    final List<dynamic> bronnenRaw = (item['bronnen'] as List<dynamic>?) ?? [];

    // Convert items to safe strings
    final List<String> synoniemen = synoniemenRaw
        .map((s) => s.toString())
        .toList();
    final List<String> kruisreacties = kruisreactiesRaw
        .map((s) => s.toString())
        .toList();
    final List<String> bronnen = bronnenRaw.map((s) => s.toString()).toList();
    final List<String> vaakGebruik = vaakGebruikRaw
        .map((s) => s.toString())
        .toList();

    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final width = MediaQuery.of(context).size.width * 0.95;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title and close
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stof,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Short info row (cas, concentratie)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (cas.isNotEmpty)
                        Chip(
                          label: Text('CAS: $cas'),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (concentratie.isNotEmpty)
                        Chip(
                          label: Text('Concentratie: $concentratie%'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Expandable sections
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExpansionSection(
                            context,
                            title: 'Synoniemen',
                            emptyLabel: 'Geen synoniemen beschikbaar',
                            children: synoniemen.map((s) => Text(s)).toList(),
                          ),

                          const SizedBox(height: 8),

                          _buildExpansionSection(
                            context,
                            title: 'Kruisreacties',
                            emptyLabel: 'Geen kruisreacties bekend',
                            children: kruisreacties
                                .map((s) => Text(s))
                                .toList(),
                          ),

                          const SizedBox(height: 8),

                          _buildExpansionSection(
                            context,
                            title: 'Vaak voorkomende gebruiken / rol',
                            emptyLabel: 'Geen gebruiksinformatie',
                            children: vaakGebruik.map((s) => Text(s)).toList(),
                          ),

                          const SizedBox(height: 8),

                          _buildExpansionSection(
                            context,
                            title: 'Bronnen',
                            emptyLabel: 'Geen bronnen',
                            children: bronnen.map((s) => Text(s)).toList(),
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

  // Small helper to create an expansion tile with a pleasant style.
  Widget _buildExpansionSection(
    BuildContext context, {
    required String title,
    required String emptyLabel,
    required List<Widget> children,
  }) {
    final bool hasContent = children.isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 2,
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          children: hasContent
              ? children
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Align(alignment: Alignment.centerLeft, child: w),
                      ),
                    )
                    .toList()
              : [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      emptyLabel,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String stof = (item['stof'] ?? '').toString();
    final List<dynamic> synoniemenRaw =
        (item['synoniemen'] as List<dynamic>?) ?? [];
    final String subtitle = synoniemenRaw.isNotEmpty
        ? synoniemenRaw.take(3).map((s) => s.toString()).join(', ')
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context),
        child: Container(
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
              children: [
                // Name + small subtitle (first few synonyms)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stof,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Switch (selection)
                Switch.adaptive(
                  value: isSelected,
                  onChanged: onChanged,
                  activeTrackColor: const Color(0xFFED260E),
                  inactiveTrackColor: theme.disabledColor,
                  inactiveThumbColor: theme.canvasColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
