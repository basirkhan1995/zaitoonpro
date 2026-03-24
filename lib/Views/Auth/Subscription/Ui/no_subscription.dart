import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

class NoSubscriptionView extends StatelessWidget {
  final bool isExpired;

  const NoSubscriptionView({
    super.key,
    this.isExpired = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileContent(isExpired: isExpired),
      tablet: _TabletContent(isExpired: isExpired),
      desktop: _DesktopContent(isExpired: isExpired),
    );
  }
}

// Mobile Version
class _MobileContent extends StatelessWidget {
  final bool isExpired;

  const _MobileContent({required this.isExpired});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.subscriptionTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _MessageCard(isExpired: isExpired),
      ),
    );
  }
}

// Tablet Version
class _TabletContent extends StatelessWidget {
  final bool isExpired;

  const _TabletContent({required this.isExpired});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.subscriptionTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: 600,
            child: _MessageCard(isExpired: isExpired),
          ),
        ),
      ),
    );
  }
}

// Desktop Version
class _DesktopContent extends StatelessWidget {
  final bool isExpired;

  const _DesktopContent({required this.isExpired});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.subscriptionTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SizedBox(
            width: 600,
            child: _MessageCard(isExpired: isExpired),
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final bool isExpired;

  const _MessageCard({required this.isExpired});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isExpired
              ? colorScheme.error.withValues(alpha: .3)
              : colorScheme.primary.withValues(alpha: .3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isExpired
                  ? colorScheme.error.withValues(alpha: .1)
                  : colorScheme.primary.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpired
                  ? Icons.timer_off_rounded
                  : Icons.info_outline_rounded,
              size: 80,
              color: isExpired ? colorScheme.error : colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            isExpired ? tr.subscriptionExpired : tr.noSubscription,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isExpired ? colorScheme.error : colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Message
          Text(
            isExpired
                ? tr.subscriptionExpiredContact
                : tr.noSubscriptionContact,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.outline,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Contact Information
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: .2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Zaitoon Technology',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'info@zaitoonsoft.com',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+93792496200',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.language_outlined,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'www.zaitoonsoft.com',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}