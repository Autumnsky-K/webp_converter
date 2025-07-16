import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// A custom Cupertino-style license page.
class CustomLicensePage extends StatefulWidget {
  const CustomLicensePage({super.key});

  @override
  State<CustomLicensePage> createState() => _CustomLicensePageState();
}

class _CustomLicensePageState extends State<CustomLicensePage> {
  final List<LicenseEntry> _licenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  /// Loads the licenses from the [LicenseRegistry] and de-duplicates them.
  void _loadLicenses() async {
    // Use a map to de-duplicate licenses by package name.
    final Map<String, LicenseEntry> licenseMap = {};

    await for (final license in LicenseRegistry.licenses) {
      final packageName = license.packages.join(', ');
      // Keep only the first license found for each package.
      if (!licenseMap.containsKey(packageName)) {
        licenseMap[packageName] = license;
      }
    }

    final uniqueLicenses = licenseMap.values.toList();
    // Sort the unique licenses alphabetically.
    uniqueLicenses.sort((a, b) => a.packages.join(', ').toLowerCase().compareTo(b.packages.join(', ').toLowerCase()));

    if (mounted) {
      setState(() {
        _licenses.addAll(uniqueLicenses);
        _loading = false;
      });
    }
  }

  void _showLicenseDetail(LicenseEntry license) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => _LicenseDetailPage(license: license),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Licenses'),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView.builder(
                itemCount: _licenses.length,
                itemBuilder: (context, index) {
                  final license = _licenses[index];
                  final packageName = license.packages.join(', ');
                  return _CupertinoListTile(
                    title: Text(packageName),
                    onTap: () => _showLicenseDetail(license),
                  );
                },
              ),
      ),
    );
  }
}

/// A detail page that displays the full license text.
class _LicenseDetailPage extends StatelessWidget {
  final LicenseEntry license;

  const _LicenseDetailPage({required this.license});

  @override
  Widget build(BuildContext context) {
    final packageName = license.packages.join(', ');
    final paragraphs = license.paragraphs.map((p) => p.text).join('\n\n');

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(packageName),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Text(paragraphs),
        ),
      ),
    );
  }
}

/// A simple, self-contained Cupertino-style list tile.
class _CupertinoListTile extends StatelessWidget {
  final Widget title;
  final VoidCallback? onTap;

  const _CupertinoListTile({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: CupertinoColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: title),
            const Icon(CupertinoIcons.forward, color: CupertinoColors.tertiaryLabel),
          ],
        ),
      ),
    );
  }
}
