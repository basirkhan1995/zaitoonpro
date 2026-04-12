import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaitoonpro/Features/Other/desktop_form_nav.dart';
import 'package:zaitoonpro/Features/Other/image_helper.dart';
import 'package:zaitoonpro/Features/Other/responsive.dart';
import 'package:zaitoonpro/Features/Other/toast.dart';
import 'package:zaitoonpro/Features/Other/utils.dart';
import 'package:zaitoonpro/Features/Other/zform_dialog.dart';
import 'package:zaitoonpro/Features/Widgets/outline_button.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Individuals/bloc/individuals_bloc.dart';
import '../../../../../../../Features/Other/crop.dart';
import '../../../../../../../Features/Widgets/textfield_entitled.dart';
import '../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import 'package:flutter/services.dart';
import '../model/individual_model.dart';

class IndividualAddEditView extends StatelessWidget {
  final IndividualsModel? model;

  const IndividualAddEditView({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _Mobile(model: model),
      tablet: _Tablet(model: model),
      desktop: _Desktop(model: model),
    );
  }
}

class _Mobile extends StatefulWidget {
  final IndividualsModel? model;

  const _Mobile({this.model});

  @override
  State<_Mobile> createState() => _MobileState();
}
class _MobileState extends State<_Mobile> {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController province = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController nationalId = TextEditingController();
  final TextEditingController zipCode = TextEditingController();
  Uint8List? selectedImageBytes;

  String gender = "Male";
  int mailingValue = 1;
  bool isMailingAddress = true;
  String? imageName;
  final formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      firstName.text = m.perName ?? "";
      imageName = m.imageProfile ?? "";
      lastName.text = m.perLastName ?? "";
      phone.text = m.perPhone ?? "";
      nationalId.text = m.perEnidNo ?? "";
      city.text = m.addCity ?? "";
      province.text = m.addProvince ?? "";
      country.text = m.addCountry ?? "";
      zipCode.text = m.addZipCode?.toString() ?? "";
      address.text = m.addName ?? "";
      gender = m.perGender ?? "Male";
      email.text = m.perEmail ?? "";
      mailingValue = m.addMailing ?? 1;
      isMailingAddress = mailingValue == 1;
    }
  }

  @override
  void dispose() {
    country.dispose();
    city.dispose();
    zipCode.dispose();
    address.dispose();
    nationalId.dispose();
    province.dispose();
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    email.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isEdit = widget.model != null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(isEdit ? locale.update : locale.newKeyword),
      ),
      body: BlocConsumer<IndividualsBloc, IndividualsState>(
        listener: (context, state) {
          if (state is IndividualSuccessState) {
            Navigator.of(context).pop();
          }
          if (state is IndividualErrorState) {
            Utils.showOverlayMessage(
              context,
              title: locale.errorTitle,
              message: state.message,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image Section (for edit mode)
                  if (isEdit) ...[
                    Center(
                      child: GestureDetector(
                        onTap: () => pickAndCropImage(widget.model!.perId!),
                        child: Stack(
                          children: [
                            ImageHelper.stakeholderProfile(
                              imageName: imageName,
                              localImageBytes: selectedImageBytes,
                              size: 120,
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: .3),
                                width: 2,
                              ),
                              shapeStyle: ShapeStyle.circle,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Personal Information Section
                  _buildSectionTitle(locale.personalInfo, context),
                  const SizedBox(height: 12),

                  // First & Last Name
                  Column(
                    children: [
                      ZTextFieldEntitled(
                        controller: firstName,
                        isRequired: true,
                        title: locale.firstName,
                        onSubmit: (_) => onSubmit(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return locale.required(locale.firstName);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ZTextFieldEntitled(
                        controller: lastName,
                        isRequired: true,
                        title: locale.lastName,
                        onSubmit: (_) => onSubmit(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return locale.required(locale.lastName);
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Email
                  ZTextFieldEntitled(
                    controller: email,
                    validator: (value) => Utils.validateEmail(email: value, context: context),
                    title: locale.email,
                    onSubmit: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 16),

                  // Gender Selection with better mobile UX
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            locale.gender,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: .2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      gender = "Male";
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: gender == "Male"
                                          ? colorScheme.primary.withValues(alpha: .1)
                                          : null,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      border: Border(
                                        right: BorderSide(
                                          color: colorScheme.outline.withValues(alpha: .2),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.male,
                                          size: 20,
                                          color: gender == "Male"
                                              ? colorScheme.primary
                                              : colorScheme.outline,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          locale.male,
                                          style: TextStyle(
                                            color: gender == "Male"
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                            fontWeight: gender == "Male"
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (gender == "Male") ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      gender = "Female";
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: gender == "Female"
                                          ? colorScheme.primary.withValues(alpha: .1)
                                          : null,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.female,
                                          size: 20,
                                          color: gender == "Female"
                                              ? colorScheme.primary
                                              : colorScheme.outline,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          locale.female,
                                          style: TextStyle(
                                            color: gender == "Female"
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                            fontWeight: gender == "Female"
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (gender == "Female") ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact Information Section
                  _buildSectionTitle(locale.contactInfo, context),
                  const SizedBox(height: 12),

                  // Phone & National ID
                  Row(
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: phone,
                          inputFormat: [FilteringTextInputFormatter.digitsOnly],
                          title: locale.cellNumber,
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: nationalId,
                          inputFormat: [FilteringTextInputFormatter.digitsOnly],
                          title: locale.nationalId,
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Address Information Section
                  _buildSectionTitle(locale.address, context),
                  const SizedBox(height: 12),

                  // Address
                  ZTextFieldEntitled(
                    controller: address,
                    title: locale.address,
                    onSubmit: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 16),

                  // City & Province
                  Row(
                    children: [
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: city,
                          title: locale.city,
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ZTextFieldEntitled(
                          controller: province,
                          title: locale.province,
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Country & Zip Code
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: ZTextFieldEntitled(
                          controller: country,
                          title: locale.country,
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ZTextFieldEntitled(
                          controller: zipCode,
                          title: locale.zipCode,
                          inputFormat: [FilteringTextInputFormatter.digitsOnly],
                          onSubmit: (_) => onSubmit(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Mailing Address Card
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: .1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isMailingAddress,
                          onChanged: (value) {
                            setState(() {
                              isMailingAddress = value ?? true;
                              mailingValue = isMailingAddress ? 1 : 0;
                            });
                          },
                          activeColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.address,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                locale.isMilling,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Submit Button (full width for better mobile UX)
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ZOutlineButton(
                      onPressed: onSubmit,
                      isActive: true,
                      label: state is IndividualLoadingState
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                          : Text(
                        isEdit ? locale.update : locale.create,
                      ),

                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void pickAndCropImage(int perId) async {
    final bloc = context.read<IndividualsBloc>();

    final imageBytes = await Utils.pickImage();
    if (imageBytes == null || imageBytes.isEmpty) return;

    try {
      Uint8List? croppedBytes;
      if (mounted) {
        croppedBytes = await showImageCropper(
          context: context,
          imageBytes: imageBytes,
        );
      }

      if (!mounted || croppedBytes == null || croppedBytes.isEmpty) return;

      setState(() => selectedImageBytes = croppedBytes);
      bloc.add(UploadIndProfileImageEvent(perId: perId, image: croppedBytes));
    } catch (e) {
      debugPrint("Image crop failed: $e");
      if (mounted) {
        Utils.showOverlayMessage(
          context,
          title: AppLocalizations.of(context)!.errorTitle,
          message: "Failed to crop image",
          isError: true,
        );
      }
    }
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = IndividualsModel(
      perId: widget.model?.perId,
      perName: firstName.text,
      perLastName: lastName.text,
      perPhone: phone.text,
      perEnidNo: nationalId.text,
      perGender: gender,
      perDoB: DateTime.now(),
      perEmail: email.text,
      addName: address.text,
      addMailing: mailingValue,
      addZipCode: zipCode.text,
      addProvince: province.text,
      addCountry: country.text,
      addId: widget.model?.perAddress,
      addCity: city.text,
    );

    final bloc = context.read<IndividualsBloc>();

    if (widget.model == null) {
      bloc.add(AddIndividualEvent(data));
    } else {
      bloc.add(EditIndividualEvent(data));
    }
  }
}

class _Tablet extends StatefulWidget {
  final IndividualsModel? model;

  const _Tablet({this.model});

  @override
  State<_Tablet> createState() => _TabletState();
}
class _TabletState extends State<_Tablet> {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController province = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController nationalId = TextEditingController();
  final TextEditingController zipCode = TextEditingController();
  Uint8List? selectedImageBytes;

  String gender = "Male";
  int mailingValue = 1;
  bool isMailingAddress = true;
  String? imageName;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      firstName.text = m.perName ?? "";
      imageName = m.imageProfile ?? "";
      lastName.text = m.perLastName ?? "";
      phone.text = m.perPhone ?? "";
      nationalId.text = m.perEnidNo ?? "";
      city.text = m.addCity ?? "";
      province.text = m.addProvince ?? "";
      country.text = m.addCountry ?? "";
      zipCode.text = m.addZipCode?.toString() ?? "";
      address.text = m.addName ?? "";
      gender = m.perGender ?? "Male";
      email.text = m.perEmail ?? "";
      mailingValue = m.addMailing ?? 1;
      isMailingAddress = mailingValue == 1;
    }
  }

  @override
  void dispose() {
    country.dispose();
    city.dispose();
    zipCode.dispose();
    address.dispose();
    nationalId.dispose();
    province.dispose();
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isEdit = widget.model != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: .2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? locale.update : locale.newKeyword,
                    style: theme.textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(locale.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onSubmit,
                        icon: context.watch<IndividualsBloc>().state
                        is IndividualLoadingState
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                            : const Icon(Icons.check),
                        label: Text(isEdit ? locale.update : locale.create),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: BlocConsumer<IndividualsBloc, IndividualsState>(
                listener: (context, state) {
                  if (state is IndividualSuccessState) {
                    Navigator.of(context).pop();
                  }
                },
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Image (for edit)
                          if (isEdit)
                            Center(
                              child: GestureDetector(
                                onTap: () => pickAndCropImage(widget.model!.perId!),
                                child: Stack(
                                  children: [
                                    ImageHelper.stakeholderProfile(
                                      imageName: imageName,
                                      localImageBytes: selectedImageBytes,
                                      size: 100,
                                      border: Border.all(
                                        color: colorScheme.outline.withValues(alpha: .3),
                                      ),
                                      shapeStyle: ShapeStyle.circle,
                                    ),
                                    const Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.blue,
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (isEdit) const SizedBox(height: 20),

                          // Personal Info
                          Text(
                           "personalInformation",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  controller: firstName,
                                  isRequired: true,
                                  title: locale.firstName,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return locale.required(locale.firstName);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  controller: lastName,
                                  isRequired: true,
                                  title: locale.lastName,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return locale.required(locale.lastName);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Email
                          ZTextFieldEntitled(
                            controller: email,
                            validator: (value) => Utils.validateEmail(
                              email: value,
                              context: context,
                            ),
                            title: locale.email,
                          ),
                          const SizedBox(height: 12),

                          // Gender
                          // Alternative using SegmentedButton (Material 3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locale.gender,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment<String>(
                                      value: "Male",
                                      label: Text("Male"),
                                      icon: Icon(Icons.male),
                                    ),
                                    ButtonSegment<String>(
                                      value: "Female",
                                      label: Text("Female"),
                                      icon: Icon(Icons.female),
                                    ),
                                  ],
                                  selected: {gender},
                                  onSelectionChanged: (Set<String> newSelection) {
                                    setState(() {
                                      gender = newSelection.first;
                                    });
                                  },
                                  showSelectedIcon: false,
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contact Info
                          Text(
                            "contactInformation",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  controller: phone,
                                  inputFormat: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  title: locale.cellNumber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  controller: nationalId,
                                  inputFormat: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  title: locale.nationalId,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Address Info
                          Text(
                            locale.address,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),

                          ZTextFieldEntitled(
                            controller: address,
                            title: locale.address,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: ZTextFieldEntitled(
                                  controller: city,
                                  title: locale.city,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ZTextFieldEntitled(
                                  controller: province,
                                  title: locale.province,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: ZTextFieldEntitled(
                                  controller: country,
                                  title: locale.country,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ZTextFieldEntitled(
                                  controller: zipCode,
                                  title: locale.zipCode,
                                  inputFormat: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Mailing Address
                          Row(
                            children: [
                              Checkbox(
                                value: isMailingAddress,
                                onChanged: (value) {
                                  setState(() {
                                    isMailingAddress = value ?? true;
                                    mailingValue = isMailingAddress ? 1 : 0;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(locale.isMilling),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pickAndCropImage(int perId) async {
    final bloc = context.read<IndividualsBloc>();

    final imageBytes = await Utils.pickImage();
    if (imageBytes == null || imageBytes.isEmpty) return;

    try {
      Uint8List? croppedBytes;
      if (mounted) {
        croppedBytes = await showImageCropper(
          context: context,
          imageBytes: imageBytes,
        );
      }

      if (!mounted || croppedBytes == null || croppedBytes.isEmpty) return;

      setState(() => selectedImageBytes = croppedBytes);
      bloc.add(UploadIndProfileImageEvent(perId: perId, image: croppedBytes));
    } catch (e) {
      debugPrint("Image crop failed: $e");
    }
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = IndividualsModel(
      perId: widget.model?.perId,
      perName: firstName.text,
      perLastName: lastName.text,
      perPhone: phone.text,
      perEnidNo: nationalId.text,
      perGender: gender,
      perDoB: DateTime.now(),
      perEmail: email.text,
      addName: address.text,
      addMailing: mailingValue,
      addZipCode: zipCode.text,
      addProvince: province.text,
      addCountry: country.text,
      addId: widget.model?.perAddress,
      addCity: city.text,
    );

    final bloc = context.read<IndividualsBloc>();

    if (widget.model == null) {
      bloc.add(AddIndividualEvent(data));
    } else {
      bloc.add(EditIndividualEvent(data));
    }
  }
}

class _Desktop extends StatefulWidget {
  final IndividualsModel? model;

  const _Desktop({this.model});

  @override
  State<_Desktop> createState() => _DesktopState();
}
class _DesktopState extends State<_Desktop> {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController province = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController nationalId = TextEditingController();
  final TextEditingController zipCode = TextEditingController();
  Uint8List? selectedImageBytes;

  String gender = "Male";
  int mailingValue = 1;
  bool isMailingAddress = true;
  String? imageName;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Pre-fill for edit mode
    if (widget.model != null) {
      final m = widget.model!;
      firstName.text = m.perName ?? "";
      imageName = m.imageProfile ?? "";
      lastName.text = m.perLastName ?? "";
      phone.text = m.perPhone ?? "";
      nationalId.text = m.perEnidNo ?? "";
      city.text = m.addCity ?? "";
      province.text = m.addProvince ?? "";
      country.text = m.addCountry ?? "";
      zipCode.text = m.addZipCode?.toString() ?? "";
      address.text = m.addName ?? "";
      gender = m.perGender ?? "Male";
      email.text = m.perEmail ?? "";
      mailingValue = m.addMailing ?? 1;
      isMailingAddress = mailingValue == 1;
    }
  }

  @override
  void dispose() {
    country.dispose();
    city.dispose();
    zipCode.dispose();
    address.dispose();
    nationalId.dispose();
    province.dispose();
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final theme = Theme.of(context).colorScheme;

    final isEdit = widget.model != null;

    return ZFormDialog(
      icon: Icons.add,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      width: MediaQuery.of(context).size.width * .5,
      title: isEdit ? locale.update : locale.newKeyword,
      actionLabel:
      (context.watch<IndividualsBloc>().state is IndividualLoadingState)
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.surface,
        ),
      )
          : Text(isEdit ? locale.update : locale.create),
      onAction: onSubmit,
      child: FormNavigation(
        child: Form(
          key: formKey,
          child: BlocConsumer<IndividualsBloc, IndividualsState>(
            listener: (context, state) {
              if (state is IndividualSuccessState) {
                Navigator.of(context).pop();
              }if(state is IndividualErrorState){
                ToastManager.show(context: context, title: locale.operationFailedTitle, message: state.message, type: ToastType.error);
              }if(state is IndividualSuccessImageState){
                ToastManager.show(context: context, title: locale.successTitle, message: locale.successMessage, type: ToastType.success);
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    if (isEdit)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ImageHelper.stakeholderProfile(
                            imageName: imageName,
                            localImageBytes: selectedImageBytes,
                            size: 115,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
                            ),
                            shapeStyle: ShapeStyle.roundedRectangle,
                            showCameraIcon: true,

                            onCameraTap: () => pickAndCropImage(widget.model!.perId!),
                            onImageTap: () => ImageHelper.showImageViewer(
                              context: context,
                              imageName: imageName,
                              localImageBytes: selectedImageBytes,
                              heroTag: 'profile_image_${widget.model!.perId}',
                            ),
                          )
                        ],
                      ),
                    const SizedBox(height: 5),
                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: firstName,
                            isRequired: true,
                            title: locale.firstName,
                            onSubmit: (_) => onSubmit(),
                            validator: (value) {
                              if (value.isEmpty) {
                                return locale.required(locale.firstName);
                              }
                              return null;
                            },
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: lastName,
                            isRequired: true,
                            title: locale.lastName,
                            onSubmit: (_) => onSubmit(),
                            validator: (value) {
                              if (value.isEmpty) {
                                return locale.required(locale.lastName);
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                
                    ZTextFieldEntitled(
                      controller: email,
                      validator: (value) =>
                          Utils.validateEmail(email: value, context: context),
                      title: locale.email,
                      onSubmit: (_) => onSubmit(),
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: phone,
                            inputFormat: [FilteringTextInputFormatter.digitsOnly],
                            title: locale.cellNumber,
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                        Expanded(
                          child: ZTextFieldEntitled(
                            controller: nationalId,
                            inputFormat: [FilteringTextInputFormatter.digitsOnly],
                            title: locale.nationalId,
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                      ],
                    ),
                    ZTextFieldEntitled(
                      controller: address,
                      title: locale.address,
                      onSubmit: (_) => onSubmit(),
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ZTextFieldEntitled(
                            controller: city,
                            title: locale.city,
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: ZTextFieldEntitled(
                            controller: province,
                            title: locale.province,
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: ZTextFieldEntitled(
                            controller: country,
                            title: locale.country,
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ZTextFieldEntitled(
                            controller: zipCode,
                            title: locale.zipCode,
                            inputFormat: [FilteringTextInputFormatter.digitsOnly],
                            onSubmit: (_) => onSubmit(),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.gender,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<String>(
                                segments: [
                                  ButtonSegment<String>(
                                    value: "Male",
                                    label: Text(AppLocalizations.of(context)!.male),
                                    icon: Icon(Icons.male),
                                  ),
                                  ButtonSegment<String>(
                                    value: "Female",
                                    label: Text(AppLocalizations.of(context)!.female),
                                    icon: Icon(Icons.female),
                                  ),
                                ],
                                selected: {gender},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    gender = newSelection.first;
                                  });
                                },
                                showSelectedIcon: false,

                                style: ButtonStyle(
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2.0),
                                    ),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Checkbox(
                          visualDensity: const VisualDensity(horizontal: -4),
                          value: isMailingAddress,
                          onChanged: (value) {
                            setState(() {
                              isMailingAddress = value ?? true;
                              mailingValue = isMailingAddress ? 1 : 0;
                            });
                          },
                        ),
                        Text(locale.isMilling),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void pickAndCropImage(int perId) async {
    final bloc = context.read<IndividualsBloc>();

    final imageBytes = await Utils.pickImage();
    if (imageBytes == null || imageBytes.isEmpty) return;

    try {
      Uint8List? croppedBytes;
      if (mounted) {
        croppedBytes = await showImageCropper(
          context: context,
          imageBytes: imageBytes,
        );
      }

      if (!mounted || croppedBytes == null || croppedBytes.isEmpty) return;

      setState(() => selectedImageBytes = croppedBytes);
      bloc.add(UploadIndProfileImageEvent(perId: perId, image: croppedBytes));
    } catch (e) {
      debugPrint("Image crop failed: $e");
    }
  }

  void onSubmit() {
    if (!formKey.currentState!.validate()) return;

    final data = IndividualsModel(
      perId: widget.model?.perId,
      perName: firstName.text,
      perLastName: lastName.text,
      perPhone: phone.text,
      perEnidNo: nationalId.text,
      perGender: gender,
      perDoB: DateTime.now(),
      perEmail: email.text,
      addName: address.text,
      addMailing: mailingValue,
      addZipCode: zipCode.text,
      addProvince: province.text,
      addCountry: country.text,
      addId: widget.model?.perAddress,
      addCity: city.text,
    );

    final bloc = context.read<IndividualsBloc>();

    if (widget.model == null) {
      bloc.add(AddIndividualEvent(data));
    } else {
      bloc.add(EditIndividualEvent(data));
    }
  }
}