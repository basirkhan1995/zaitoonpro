import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branch/branch_tab.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/Branches/model/branch_model.dart';

class BranchDetailsView extends StatelessWidget {
  final BranchModel branch;
  const BranchDetailsView({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileBranchDetails(branch: branch),
      tablet: _TabletBranchDetails(branch: branch),
      desktop: _DesktopBranchDetails(branch: branch),
    );
  }
}

// Base class to share common functionality
class _BaseBranchDetails extends StatelessWidget {
  final BranchModel branch;
  final bool isMobile;
  final bool isTablet;

  const _BaseBranchDetails({
    required this.branch,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    if (isMobile) {
      // Mobile full-screen details view
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          margin: EdgeInsets.zero,
          color: theme.surface,
          child: Column(
            children: [
              // Header with branch info
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primary,
                      theme.primary.withValues(alpha: .8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch.brcName ?? "",
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "ID: ${branch.brcId}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: .8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick info chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (branch.brcPhone != null && branch.brcPhone!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    branch.brcPhone!,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  branch.addCity ?? "",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Branch Tabs
              Expanded(
                child: BranchTabsView(selectedBranch: branch),
              ),
            ],
          ),
        ),
      );
    } else if (isTablet) {
      // Tablet dialog - medium size
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        insetPadding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.7,
          height: MediaQuery.sizeOf(context).height * 0.8,
          decoration: BoxDecoration(
            color: theme.surface,
          ),
          child: Column(
            children: [
              // Tablet header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primary,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.brcName ?? "",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "ID: ${branch.brcId}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: .8),
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (branch.brcPhone != null && branch.brcPhone!.isNotEmpty)
                                Text(
                                  branch.brcPhone!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: .8),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Branch Tabs
              Expanded(
                child: BranchTabsView(selectedBranch: branch),
              ),
            ],
          ),
        ),
      );
    } else {
      // Desktop dialog
      return Padding(
        padding: const EdgeInsets.all(15.0),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.all(10),
          clipBehavior: Clip.antiAlias,
          titlePadding: EdgeInsets.zero,
          actionsPadding: EdgeInsets.zero,
          content: Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            width: MediaQuery.sizeOf(context).width * .4,
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: BranchTabsView(selectedBranch: branch),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

// Mobile View
class _MobileBranchDetails extends StatelessWidget {
  final BranchModel branch;

  const _MobileBranchDetails({required this.branch});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchDetails(
      branch: branch,
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet View
class _TabletBranchDetails extends StatelessWidget {
  final BranchModel branch;

  const _TabletBranchDetails({required this.branch});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchDetails(
      branch: branch,
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop View
class _DesktopBranchDetails extends StatelessWidget {
  final BranchModel branch;

  const _DesktopBranchDetails({required this.branch});

  @override
  Widget build(BuildContext context) {
    return _BaseBranchDetails(
      branch: branch,
      isMobile: false,
      isTablet: false,
    );
  }
}