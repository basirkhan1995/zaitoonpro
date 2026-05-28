import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../../Features/Other/cover.dart';
import '../../../../../../Features/Other/responsive.dart';
import '../../../../../../Features/Other/utils.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        tablet: _Desktop(),
        mobile: _Desktop(),
        desktop: _Desktop());
  }
}

class _Desktop extends StatefulWidget {
  @override
  State<_Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<_Desktop> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();

    setState(() {
      _version = "${info.version} + ${info.buildNumber}";
    });
  }

  Widget _teamCard({
    required String image,
    required String name,
    required String role,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: .08),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: .04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              image,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 16),

          /// NAME
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          /// ROLE
          Text(
            role,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 14),

          /// DESCRIPTION
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: .75),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /// LOGO
                      Center(
                        child: SizedBox(
                          width: 130,
                          height: 130,
                          child: Image.asset(
                            "assets/images/zaitoonLogo.png",
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// APP TITLE
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.zPetroleum,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      /// VERSION
                      Center(
                        child: Text(
                          _version,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),

                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              /// CONTACT SECTION
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: .08),
                  ),
                ),
                child: Column(
                  children: [

                    /// WHATSAPP
                    InkWell(
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      onTap: () {
                        Utils.launchWhatsApp(
                          phoneNumber: '+93792496200',
                        );
                      },
                      child: Row(
                        children: [

                          ZCover(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 4,
                            ),
                            color: theme.colorScheme.surface,
                            child: Icon(
                              FontAwesomeIcons.whatsapp,
                              color: theme.colorScheme.primary,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Text(
                            "WhatsApp",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// PHONE
                    Row(
                      children: [

                        ZCover(
                          padding: const EdgeInsets.symmetric(
                            vertical: 3,
                            horizontal: 4,
                          ),
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Icons.phone,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Text(
                          "93792496200",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// WEBSITE
                    Row(
                      children: [

                        ZCover(
                          padding: const EdgeInsets.symmetric(
                            vertical: 3,
                            horizontal: 4,
                          ),
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Icons.language_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Text(
                          "www.zaitoonsoft.com",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// EMAIL
                    Row(
                      children: [

                        ZCover(
                          padding: const EdgeInsets.symmetric(
                            vertical: 3,
                            horizontal: 4,
                          ),
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Icons.email,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Text(
                          "basirkhan.hashemi@gmail.com",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// TEAM TITLE
              Text(
                "Our Team",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              /// TEAM SUBTITLE
              Text(
                "Meet the talented people behind Zaitoon Software solutions.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .7),
                ),
              ),

              const SizedBox(height: 28),

              /// TEAM MEMBERS
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [

                  _teamCard(
                    image: "assets/images/ataie.png",
                    name: "Ghufran Ataie",
                    role: "Senior Software Developer",
                    description:
                    "Builds APIs, designs database architectures, develops accounting systems, and manages backend financial and business operation solutions.",
                  ),

                  _teamCard(
                    image: "assets/images/basir.jpeg",
                    name: "Basir Hashimi",
                    role: "Software & App Developer",
                    description:
                    "Builds cross-platform mobile, tablet, and desktop applications with modern UI, scalable architecture, and integrated database solutions.",
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}


