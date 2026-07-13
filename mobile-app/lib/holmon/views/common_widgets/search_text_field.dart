import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/holmon/views/search_screen.dart';

class SearchTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? textEditingController;
  final argument;
  final bool? enabled;
  final bool readOnly;
  final bool? autoFocus;

  const SearchTextField(
      {super.key,
      required this.hint,
      this.textEditingController,
      this.argument,
      this.enabled,
      required this.readOnly,
      this.autoFocus});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onTap: readOnly ? () => Get.to(() => const SearchScreen()) : null,
      controller: textEditingController,
      textAlignVertical: TextAlignVertical.center,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autoFocus ?? false,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(
            style: BorderStyle.solid,
            color: Color.fromARGB(255, 219, 219, 219),
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        hintText: hint, // Use the current value
        hintStyle: TextStyle(
          fontSize: 14,
          color: Get.theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          CupertinoIcons.search,
          color: Theme.of(context).primaryColor,
        ),
        suffixIcon: textEditingController != null
            ? IconButton(
                onPressed: textEditingController?.clear,
                icon: Icon(Icons.clear),
              )
            : null,
      ),
    );
  }
}
