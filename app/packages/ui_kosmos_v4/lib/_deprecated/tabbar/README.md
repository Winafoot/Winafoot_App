### Add the following imports to your Dart code

```dart
import 'package:ui_kosmos_v4/ui_kosmos_v4.dart';
```

![picture/tabbar.gif](picture/tabbar.gif)
![picture/tabbar-with-point.gif](picture/tabbar-with-point.gif)
![picture/tabbar-homebutton.gif](picture/tabbar-homebutton.gif)


```dart
import 'package:animations/animations.dart';
import 'package:example/screens/home_with_all_widget.dart';
import 'package:example/screens/just_test_with_icon.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/////////////////////////////////////
////////// CONFIG TESTING ///////////
/////////////////////////////////////

bool withAppBar = false;
bool _tabBarWithCenterButton = true;
bool _tabBarWithPoint = true;

void main() {
  runApp(withAppBar ? const MyAppWithBottomBar() : const MyAppWithoutAppBar());
}

class MyAppWithBottomBar extends StatefulWidget {
  const MyAppWithBottomBar({Key? key}) : super(key: key);

  @override
  State<MyAppWithBottomBar> createState() => _MyAppWithBottomBarState();
}

class _MyAppWithBottomBarState extends State<MyAppWithBottomBar> {
  int idx = 0;

  void _changePage(int index) {
    setState(() {
      idx = index;
    });
  }

  final List<Widget> _pageList = [
    const HomeWithAllWidget(),
    const JustTestWithIcon(text: 'Market', iconData: Iconsax.shop),
    const JustTestWithIcon(text: 'Bag', iconData: Iconsax.bag_2),
    const JustTestWithIcon(text: 'Setting', iconData: Iconsax.setting_3),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Poppins'),
      home: Scaffold(
        floatingActionButtonLocation: _tabBarWithCenterButton ? FloatingActionButtonLocation.centerDocked : null,
        floatingActionButton: _tabBarWithCenterButton
  ? SizedBox(
      height: 50,
      child: FloatingActionButton(
        backgroundColor: const Color(0xFF02132B),
        elevation: 0,
        onPressed: () => print('Tap on plus'),
        child: const Icon(
          Iconsax.add,
          size: 29,
        ),
      ),
    )
  : null,
        bottomNavigationBar: BottomAppBar(
child: SizedBox(
  height: 77,
  child: Row(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      const Spacer(),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Iconsax.home,
              color: idx == 0 ? const Color(0xFF02132B) : const Color(0xFFB1B6BE),
            ),
            onPressed: () => _changePage(0),
          ),
          idx == 0 && _tabBarWithPoint
              ? Container(
                  height: 3,
                  width: 3,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF02132B)),
              )
              : const SizedBox(),
                  ],
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.shop,
                        color: idx == 1 ? const Color(0xFF02132B) : const Color(0xFFB1B6BE),
                      ),
                      onPressed: () => _changePage(1),
                    ),
                    idx == 1 && _tabBarWithPoint
                        ? Container(
                            height: 3,
                            width: 3,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF02132B)),
                          )
                        : const SizedBox(),
                  ],
                ),
                Spacer(flex: _tabBarWithCenterButton ? 2 : 1),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.bag_2,
                        color: idx == 2 ? const Color(0xFF02132B) : const Color(0xFFB1B6BE),
                      ),
                      onPressed: () => _changePage(2),
                    ),
                    idx == 2 && _tabBarWithPoint
                        ? Container(
                            height: 3,
                            width: 3,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF02132B)),
                          )
                        : const SizedBox(),
                  ],
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.setting_3,
                        color: idx == 3 ? const Color(0xFF02132B) : const Color(0xFFB1B6BE),
                      ),
                      onPressed: () => _changePage(3),
                    ),
                    idx == 3 && _tabBarWithPoint
                        ? Container(
                            height: 3,
                            width: 3,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF02132B)),
                          )
                        : const SizedBox(),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        body: PageTransitionSwitcher(
          transitionBuilder: (
            Widget child,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _pageList[idx],
        ),
      ),
    );
  }
}
```