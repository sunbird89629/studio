import 'package:flutter/material.dart';

class FluentFormDivider extends StatelessWidget {
  const FluentFormDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 8),
        Divider(),
        SizedBox(height: 8),
      ],
    );
  }
}

class FluentFormHeader extends StatelessWidget {
  const FluentFormHeader(this.header, {this.style, super.key});

  final String header;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: style ?? Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class FluentFormSeparator extends StatelessWidget {
  const FluentFormSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 8);
  }
}
