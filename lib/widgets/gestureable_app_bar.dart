import 'package:flutter/material.dart';

class GestureableAppBar extends StatelessWidget implements PreferredSizeWidget {
    final VoidCallback onTap;
    final AppBar appBar;

    const GestureableAppBar({
        Key key,
        this.onTap,
        this.appBar
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: onTap,
            child: appBar
        );
    }

    @override
    Size get preferredSize => Size.fromHeight(kToolbarHeight);
}