import 'package:flutter/material.dart';
import 'package:phone_drop/data/Notifier.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (BuildContext context, int selectedPage, Widget? child) {
        return NavigationBar(
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
              selectedIcon: Icon(
                Icons.home_rounded,
                color: Colors.blue,
              ),
            ),
            NavigationDestination(
              icon: Icon(Icons.call_received_rounded),
              label: 'Receiver',
              selectedIcon: Icon(
                Icons.call_received_rounded,
                color: Colors.blue,
              ),
            ),
            NavigationDestination(
              icon: Icon(Icons.send_rounded),
              label: 'Sender',
              selectedIcon: Icon(Icons.send_rounded, color: Colors.blue),
            ),
          ],
          onDestinationSelected: (int value) {
            selectedPageNotifier.value = value;
          },
          selectedIndex: selectedPage,
        );
      },
    );
  }
}
