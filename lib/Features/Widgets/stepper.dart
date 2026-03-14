import 'package:flutter/material.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';

class StepItem {
  final String title;
  final Widget content;
  final IconData? icon;

  const StepItem({
    required this.title,
    required this.content,
    this.icon,
  });
}

class CustomStepper extends StatefulWidget {
  final List<StepItem> steps;
  final Axis direction;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onFinish;
  final bool Function(int currentStep, int requestedStep)? onStepChanged;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;
  final bool isLoading; // Add this

  const CustomStepper({
    super.key,
    required this.steps,
    this.direction = Axis.horizontal,
    this.activeColor,
    this.inactiveColor,
    this.onFinish,
    this.onStepChanged,
    required this.currentStep,
    this.onStepTapped,
    this.isLoading = false
  });

  @override
  State<CustomStepper> createState() => _CustomStepperState();
}

class _CustomStepperState extends State<CustomStepper> {
  // Helper method to get safe current step (within bounds)
  int get _safeCurrentStep {
    if (widget.steps.isEmpty) return 0;
    return widget.currentStep.clamp(0, widget.steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isHorizontal = widget.direction == Axis.horizontal;
    final currentStep = _safeCurrentStep; // Use safe current step
    final isLoading = widget.isLoading; // Get loading state

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step headers
          isHorizontal ? Row(
            textDirection: Directionality.of(context),
            children: _buildSteps(context),
          ) : Column(children: _buildSteps(context)),
          const SizedBox(height: 8),
          // Current step content
          Expanded(
            child: widget.steps.isNotEmpty
                ? widget.steps[currentStep].content
                : Center(
              child: Text(
                tr.noDataFound,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ZOutlineButton(
                  width: 120,
                  height: 40,
                  isActive: false,
                  onPressed: currentStep > 0 && !isLoading ? _goPrevious : null,
                  label: Text(tr.previous),
                ),
                ZOutlineButton(
                  width: 120,
                  height: 40,
                  isActive: true,
                  onPressed: !isLoading ? _goNext : null,
                  label: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  )
                      : Text(
                    currentStep < widget.steps.length - 1 ? tr.next : tr.finish,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goNext() {
    if (widget.steps.isEmpty || widget.isLoading) return; // Don't allow if loading

    final currentStep = _safeCurrentStep;

    if (currentStep < widget.steps.length - 1) {
      final nextStep = currentStep + 1;
      final allowNavigation = widget.onStepChanged?.call(currentStep, nextStep) ?? true;

      if (allowNavigation) {
        widget.onStepTapped?.call(nextStep);
      }
    } else {
      widget.onFinish?.call();
    }
  }

  void _goPrevious() {
    if (widget.steps.isEmpty || widget.isLoading) return; // Don't allow if loading

    final currentStep = _safeCurrentStep;

    if (currentStep > 0) {
      final prevStep = currentStep - 1;
      final allowNavigation = widget.onStepChanged?.call(currentStep, prevStep) ?? true;

      if (allowNavigation) {
        widget.onStepTapped?.call(prevStep);
      }
    }
  }

  List<Widget> _buildSteps(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[];
    final currentStep = _safeCurrentStep;

    for (int i = 0; i < widget.steps.length; i++) {
      final isActive = i <= currentStep;
      final isCompleted = i < currentStep;

      items.add(
        InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            final allowNavigation = widget.onStepChanged?.call(currentStep, i) ?? true;
            if (allowNavigation) {
              widget.onStepTapped?.call(i);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isActive
                      ? widget.activeColor ?? theme.colorScheme.primary
                      : widget.inactiveColor ??
                      theme.colorScheme.outline.withValues(alpha: .3),
                  child: widget.steps[i].icon != null
                      ? Icon(
                    widget.steps[i].icon,
                    size: 16,
                    color: theme.colorScheme.surface,
                  )
                      : Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.steps[i].title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive
                        ? widget.activeColor ?? theme.colorScheme.primary
                        : widget.inactiveColor ??
                        theme.colorScheme.outline.withValues(alpha: .6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Separator line
      if (i != widget.steps.length - 1) {
        items.add(
          Expanded(
            child: Container(
              height: widget.direction == Axis.horizontal ? 2 : 30,
              width: widget.direction == Axis.horizontal ? double.infinity : 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? widget.activeColor ?? theme.colorScheme.primary
                    : widget.inactiveColor ??
                    theme.colorScheme.outline.withValues(alpha: .2),

              ),
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  void didUpdateWidget(covariant CustomStepper oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset if steps changed and current step is out of bounds
    if (widget.steps.length != oldWidget.steps.length) {
      // This could trigger a rebuild, but that's okay
    }
  }
}