import 'package:flutter/material.dart';

class GestureableAppBar extends StatelessWidget implements PreferredSizeWidget {

    final VoidCallback onTap;
    final AppBar child;

    const GestureableAppBar({
        Key key,
        this.onTap,
        this.child
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: onTap,
            child: child
        );
    }

    @override
    Size get preferredSize => Size.fromHeight(kToolbarHeight);
}