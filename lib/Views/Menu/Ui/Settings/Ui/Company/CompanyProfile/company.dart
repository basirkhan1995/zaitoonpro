import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/bloc/company_profile_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/Company/CompanyProfile/model/com_model.dart';
import 'dart:typed_data';
import '../../../../../../../Features/Other/crop.dart';
import '../../../../../../../Features/Other/sections.dart';
import '../../../../../../../Features/Other/utils.dart';
import '../../../../../../../Features/Widgets/button.dart';
import '../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../../../../../../Auth/bloc/auth_bloc.dart';
import '../../../../../../Auth/models/login_model.dart';

class CompanySettingsView extends StatelessWidget {
  const CompanySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _MobileCompanyForm(),
      tablet: _TabletCompanyForm(),
      desktop: _DesktopCompanyForm(),
    );
  }
}

// Base form widget that contains all the logic
class _BaseCompanyForm extends StatefulWidget {
  final bool isMobile;
  final bool isTablet;

  const _BaseCompanyForm({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  State<_BaseCompanyForm> createState() => _BaseCompanyFormState();
}

class _BaseCompanyFormState extends State<_BaseCompanyForm> with SingleTickerProviderStateMixin {
  final TextEditingController businessName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController comDetails = TextEditingController();
  final TextEditingController website = TextEditingController();
  final TextEditingController phone2 = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController province = TextEditingController();
  final TextEditingController baseCurrency = TextEditingController();
  final TextEditingController comFb = TextEditingController();
  final TextEditingController comInsta = TextEditingController();
  final TextEditingController comWhatsApp = TextEditingController();
  final TextEditingController comZipCode = TextEditingController();
  final TextEditingController comLocalCcy = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController comLicense = TextEditingController();

  CompanySettingsModel? loadedCompany;
  bool isUpdateMode = false;
  Uint8List _companyLogo = Uint8List(0);
  int? comId;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  Future<void> _pickLogoImage() async {
    final bloc = context.read<CompanyProfileBloc>();

    final imageBytes = await Utils.pickImage();
    if (imageBytes == null || imageBytes.isEmpty) return;

    try {
      if (!mounted) return;
      final croppedBytes = await showImageCropper(
        context: context,
        imageBytes: imageBytes,
      );

      if (!mounted || croppedBytes == null || croppedBytes.isEmpty) return;

      setState(() => _companyLogo = croppedBytes);
      bloc.add(UploadCompanyLogoEvent(croppedBytes));
    } catch (e) {
      debugPrint('Image crop failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    businessName.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    comDetails.dispose();
    website.dispose();
    phone2.dispose();
    city.dispose();
    province.dispose();
    baseCurrency.dispose();
    comFb.dispose();
    comInsta.dispose();
    comWhatsApp.dispose();
    comZipCode.dispose();
    comLocalCcy.dispose();
    country.dispose();
    comLicense.dispose();
    super.dispose();
  }

  void _initializeData() {
    final state = context.read<CompanyProfileBloc>().state;
    if (state is CompanyProfileLoadedState) {
      _updateControllers(state);
    }
  }

  void _updateControllers(CompanyProfileLoadedState state) {
    setState(() {
      businessName.text = state.company.comName ?? "";
      address.text = state.company.addName ?? "";
      email.text = state.company.comEmail ?? "";
      phone.text = state.company.comPhone ?? "";
      website.text = state.company.comWebsite ?? "";
      comDetails.text = state.company.comDetails ?? "";
      comWhatsApp.text = state.company.comWhatsapp ?? "";
      comInsta.text = state.company.comInsta ?? "";
      comFb.text = state.company.comFb ?? "";
      comLicense.text = state.company.comLicenseNo ?? "";
      comZipCode.text = state.company.addZipCode ?? "";
      city.text = state.company.addCity ?? "";
      province.text = state.company.addProvince ?? "";
      country.text = state.company.addCountry ?? "";
      loadedCompany = state.company;
      comLocalCcy.text = state.company.comLocalCcy ?? "";

      final base64Logo = state.company.comLogo;
      if (base64Logo != null && base64Logo.isNotEmpty) {
        try {
          _companyLogo = base64Decode(base64Logo);
        } catch (e) {
          _companyLogo = Uint8List(0);
        }
      }
    });
  }

  void _cancelUpdate() {
    final state = context.read<CompanyProfileBloc>().state;
    if (state is CompanyProfileLoadedState) {
      _updateControllers(state);
    }
    setState(() {
      isUpdateMode = false;
    });
  }

  void _updateCompanyProfile() {
    context.read<CompanyProfileBloc>().add(UpdateCompanyProfileEvent(
      CompanySettingsModel(
        comName: businessName.text,
        comWebsite: website.text,
        comEmail: email.text,
        comDetails: comDetails.text,
        comId: 1,
        addCity: city.text,
        addName: address.text,
        addProvince: province.text,
        comFb: comFb.text,
        comInsta: comInsta.text,
        comPhone: phone.text,
        comSlogan: comDetails.text,
        comWhatsapp: comWhatsApp.text,
        addCountry: country.text,
        addZipCode: comZipCode.text,
        comLicenseNo: comLicense.text,
        comAddress: loadedCompany?.comAddress,
      ),
    ));
  }

  Widget _buildHeader(LoginData login, AppLocalizations locale, CompanyProfileLoadedState state) {
    if (widget.isMobile) {
      // Mobile header - stacked layout
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .09),
                    ),
                  ),
                  child: (_companyLogo.isEmpty)
                      ? Image.asset("assets/images/zaitoonLogo.png", fit: BoxFit.cover)
                      : Image.memory(_companyLogo, fit: BoxFit.cover),
                ),
                if (isUpdateMode)
                  Positioned(
                    top: 60,
                    left: 60,
                    child: IconButton(
                      onPressed: _pickLogoImage,
                      icon: Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary)),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Company info
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                state.company.comName ?? "",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (state.company.comEmail != null && state.company.comEmail!.isNotEmpty)
                Text(state.company.comEmail ?? ""),
              if (state.company.comPhone != null && state.company.comPhone!.isNotEmpty)
                Text(state.company.comPhone ?? ""),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          if (login.hasPermission(108) ?? false)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isUpdateMode)
                  ZOutlineButton(
                    icon: Icons.edit,
                    label: Text(locale.edit),
                    onPressed: () {
                      setState(() {
                        isUpdateMode = true;
                      });
                    },
                  ),
                if (isUpdateMode) ...[
                  Expanded(
                    child: ZOutlineButton(

                      backgroundHover: Theme.of(context).colorScheme.error,
                      label: Text(locale.cancel),
                      onPressed: _cancelUpdate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZButton(

                      label: Text(locale.saveChanges),
                      onPressed: _updateCompanyProfile,
                    ),
                  ),
                ],
              ],
            ),
        ],
      );
    } else {
      // Desktop/Tablet header - row layout
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    width: widget.isTablet ? 100 : 120,
                    height: widget.isTablet ? 100 : 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .09),
                      ),
                    ),
                    child: (_companyLogo.isEmpty)
                        ? Image.asset("assets/images/zaitoonLogo.png", fit: BoxFit.cover)
                        : Image.memory(_companyLogo, fit: BoxFit.cover),
                  ),
                  if (isUpdateMode)
                    Positioned(
                      top: widget.isTablet ? 70 : 82,
                      left: widget.isTablet ? 70 : 82,
                      child: IconButton(
                        onPressed: _pickLogoImage,
                        icon: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.primary)),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.company.comName ?? "",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (state.company.comEmail != null && state.company.comEmail!.isNotEmpty)
                    Text(state.company.comEmail ?? ""),
                  if (state.company.comPhone != null && state.company.comPhone!.isNotEmpty)
                    Text(state.company.comPhone ?? ""),
                ],
              ),
            ],
          ),
          if (login.hasPermission(108) ?? false)
            Row(
              children: [
                if (!isUpdateMode)
                  ZOutlineButton(
                    icon: Icons.edit,
                    label: Text(locale.edit),
                    onPressed: () {
                      setState(() {
                        isUpdateMode = true;
                      });
                    },
                  ),
                if (isUpdateMode) ...[
                  ZOutlineButton(
                    width: widget.isTablet ? 100 : 110,
                    icon: Icons.clear,
                    backgroundHover: Theme.of(context).colorScheme.error,
                    label: Text(locale.cancel),
                    onPressed: _cancelUpdate,
                  ),
                  const SizedBox(width: 8),
                  ZButton(
                    width: widget.isTablet ? 110 : 120,
                    label: Text(locale.saveChanges),
                    onPressed: _updateCompanyProfile,
                  ),
                ],
              ],
            ),
        ],
      );
    }
  }

  Widget _buildFormField(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthenticatedState) {
      return const SizedBox();
    }
    final login = authState.loginData;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<CompanyProfileBloc, CompanyProfileState>(
          listener: (context, state) {
            if (state is CompanyProfileErrorState) {
              Utils.showOverlayMessage(
                  context, message: state.message, isError: true);
            }

            if (state is CompanyProfileLoadedState) {
              _updateControllers(state);

              if (isUpdateMode) {
                setState(() {
                  isUpdateMode = false;
                });
                Utils.showOverlayMessage(
                    context, message: "Successfully updated", isError: false);
              }
            }
          },
          builder: (context, state) {
            if (state is CompanyProfileLoadingState) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is CompanyProfileErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(state.message),
                  ],
                ),
              );
            }

            if (state is CompanyProfileLoadedState) {
              loadedCompany = state.company;

              // Determine responsive values
              final double leftPanelWidth = widget.isMobile
                  ? 0
                  : (widget.isTablet ? 180 : 250);
              final bool isStacked = widget.isMobile;
              final EdgeInsets contentPadding = widget.isMobile
                  ? const EdgeInsets.all(12)
                  : const EdgeInsets.all(16);

              return SingleChildScrollView(
                controller: _scrollController,
                padding: contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(login, locale, state),
                    const SizedBox(height: 5),
                    Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: .3)),
                    const SizedBox(height: 5),

                    // Address Section
                    SectionFormLayout(
                      title: AppLocalizations.of(context)!.address,
                      subtitle: locale.addressHint,
                      leftPanelWidth: leftPanelWidth,
                      isStacked: isStacked,
                      formFields: [
                        _buildFormField(
                          ZTextFieldEntitled(
                            readOnly: !isUpdateMode,
                            controller: address,
                            title: locale.address,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return locale.required(locale.address);
                              }
                              return null;
                            },
                          ),
                        ),
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: city,
                              title: locale.city,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: province,
                              title: locale.province,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: country,
                              title: locale.country,
                            ),
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: city,
                                  title: locale.city,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: province,
                                  title: locale.province,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: country,
                                  title: locale.country,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: phone,
                              title: locale.mobile1,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: comWhatsApp,
                              title: locale.whatsApp,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: phone,
                                  title: locale.mobile1,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: comWhatsApp,
                                  title: locale.whatsApp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),
                    Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: .3)),
                    const SizedBox(height: 5),

                    // Social Media Section
                    SectionFormLayout(
                      title: AppLocalizations.of(context)!.socialMedia,
                      subtitle: AppLocalizations.of(context)!.profileHint,
                      leftPanelWidth: leftPanelWidth,
                      isStacked: isStacked,
                      formFields: [
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: website,
                              title: AppLocalizations.of(context)!.website,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: email,
                              title: AppLocalizations.of(context)!.email,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: website,
                                  title: AppLocalizations.of(context)!.website,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: email,
                                  title: AppLocalizations.of(context)!.email,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: comFb,
                              title: AppLocalizations.of(context)!.facebook,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: comInsta,
                              title: AppLocalizations.of(context)!.instagram,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: comFb,
                                  title: AppLocalizations.of(context)!.facebook,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: comInsta,
                                  title: AppLocalizations.of(context)!.instagram,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),
                    Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: .3)),
                    const SizedBox(height: 5),

                    // Company Details Section
                    SectionFormLayout(
                      title: AppLocalizations.of(context)!.comDetails,
                      subtitle: locale.addressHint,
                      leftPanelWidth: leftPanelWidth,
                      isStacked: isStacked,
                      formFields: [
                        if (widget.isMobile) ...[
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: true,
                              isEnabled: false,
                              controller: comLicense,
                              title: locale.comLicense,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: !isUpdateMode,
                              controller: comZipCode,
                              title: locale.zipCode,
                            ),
                          ),
                          _buildFormField(
                            ZTextFieldEntitled(
                              readOnly: true,
                              isEnabled: false,
                              controller: comLocalCcy,
                              title: locale.baseCurrency,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: true,
                                  isEnabled: false,
                                  controller: comLicense,
                                  title: locale.comLicense,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: !isUpdateMode,
                                  controller: comZipCode,
                                  title: locale.zipCode,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  readOnly: true,
                                  isEnabled: false,
                                  controller: comLocalCcy,
                                  title: locale.baseCurrency,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                        _buildFormField(
                          ZTextFieldEntitled(
                            readOnly: !isUpdateMode,
                            controller: comDetails,
                            keyboardInputType: TextInputType.multiline,
                            title: locale.comDetails,
                          ),
                        ),
                      ],
                    ),

                    // Add bottom padding for better scrolling
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}

// Mobile Form
class _MobileCompanyForm extends StatelessWidget {
  const _MobileCompanyForm();

  @override
  Widget build(BuildContext context) {
    return const _BaseCompanyForm(
      isMobile: true,
      isTablet: false,
    );
  }
}

// Tablet Form
class _TabletCompanyForm extends StatelessWidget {
  const _TabletCompanyForm();

  @override
  Widget build(BuildContext context) {
    return const _BaseCompanyForm(
      isMobile: false,
      isTablet: true,
    );
  }
}

// Desktop Form
class _DesktopCompanyForm extends StatelessWidget {
  const _DesktopCompanyForm();

  @override
  Widget build(BuildContext context) {
    return const _BaseCompanyForm(
      isMobile: false,
      isTablet: false,
    );
  }
}