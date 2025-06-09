import 'package:flutter/material.dart';
import 'package:phone_drop/Module/home.dart';
import 'package:phone_drop/data/Notifier.dart';
import 'package:phone_drop/Module/receiver.dart';
import 'package:phone_drop/Module/sender.dart';
import 'package:phone_drop/nav.dart';

List<Widget> widgetList = [Home(), Receiver(), Sender()];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: isDarkModeNotifier,
              builder:
                  (BuildContext context, dynamic isDarkMode, Widget? child) {
                    return Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    );
                  },
            ),
            onPressed: () {
              isDarkModeNotifier.value = !isDarkModeNotifier.value;
            },
          ),
        ],
      ),

      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (BuildContext context, int selectedPage, Widget? child) {
          return widgetList[selectedPage];
        },
      ),

      bottomNavigationBar: NavBar(),
    );
  }
}
