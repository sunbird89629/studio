import 'package:flutter/material.dart';

class NavigationBreadcrumbs extends StatelessWidget {
  const NavigationBreadcrumbs({
    super.key,
    required this.breadcrumbs,
    this.onTap,
  });

  final List<String> breadcrumbs;

  final void Function(List<String> breadcrumbs)? onTap;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (var i = 0; i < breadcrumbs.length; i++) {
      final breadcrumb = breadcrumbs[i];

      widgets.add(
        BreadcrumbButton(
          breadcrumb: breadcrumb,
          onPressed: () => onTap?.call(breadcrumbs.sublist(0, i + 1)),
        ),
      );

      if (i < breadcrumbs.length - 1) {
        widgets.add(const BreadcrumbSeparator());
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: widgets,
        ),
      ),
    );
  }
}

class BreadcrumbButton extends StatelessWidget {
  const BreadcrumbButton({
    super.key,
    this.onPressed,
    required this.breadcrumb,
  });

  final String breadcrumb;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        breadcrumb,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class BreadcrumbSeparator extends StatelessWidget {
  const BreadcrumbSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_right,
      size: 16,
    );
  }
}
