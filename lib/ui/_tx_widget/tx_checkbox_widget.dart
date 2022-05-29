import 'package:code/_res/R.dart';
import 'package:code/ui/_tx_widget/tx_text_widget.dart';
import 'package:flutter/material.dart';

class TXCheckBoxWidget extends StatelessWidget {
  final String? text;
  final bool value;
  final ValueChanged<bool>? onChange;
  final bool leading;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final bool removeCheckboxExtraPadding;

  TXCheckBoxWidget({
    this.text,
    this.onChange,
    this.value = false,
    this.leading = false,
    this.removeCheckboxExtraPadding = false,
    this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChange!(!value);
      },
      child: Container(
        padding: padding,
        child: leading ? leadingWidget() : trailingWidget(),
      ),
    );
  }

  Widget trailingWidget() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: removeCheckboxExtraPadding
            ? <Widget>[
                Expanded(
                  child: TXTextWidget(
                    text: text ?? '',
                    color: textColor ?? R.color.primaryColor,
                  ),
                ),
                SizedBox.fromSize(
                  child: Checkbox(
                    onChanged: (value) {
                      onChange!(value!);
                    },
                    value: value,
                  ),
                  size: Size(kRadialReactionRadius, kRadialReactionRadius),
                ),
              ]
            : <Widget>[
                Expanded(
                  child: TXTextWidget(
                    text: text ?? '',
                    color: textColor ?? R.color.primaryColor,
                  ),
                ),
                Checkbox(
                  onChanged: (value) {
                    onChange!(value!);
                  },
                  value: value,
                )
              ],
      );

  Widget leadingWidget() => Row(
        children: removeCheckboxExtraPadding
            ? <Widget>[
                SizedBox.fromSize(
                  child: Container(
                    child: Checkbox(
                      onChanged: (value) {
                        onChange!(value!);
                      },
                      value: value,
                    ),
                  ),
                  size: Size(kRadialReactionRadius, kRadialReactionRadius),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: TXTextWidget(
                    text: text ?? '',
                    color: textColor ?? R.color.primaryColor,
                  ),
                ),
              ]
            : <Widget>[
                Container(
                  child: Checkbox(
                    onChanged: (value) {
                      onChange!(value!);
                    },
                    value: value,
                  ),
                ),
                Expanded(
                  child: TXTextWidget(
                    text: text ?? '',
                    color: textColor ?? R.color.primaryColor,
                  ),
                ),
              ],
      );
}
