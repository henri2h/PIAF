import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../router.gr.dart';

@RoutePage()
class DesktopWelcomePage extends StatelessWidget {
  const DesktopWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(4);

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 80, left: 30.0, right: 30, bottom: 60),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset("assets/piaf.jpg",
                            width: 60, height: 60)),
                  ),
                  Text("Welcome",
                      style: Theme.of(context).textTheme.displayLarge),
                ],
              ),
            ),
            ListTile(
              leading: Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(radius)),
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.login,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )),
              title: const Text("Sign In",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  const Text("Connect using your existing MATRIX account"),
              trailing: const Icon(Icons.navigate_next),
              onTap: () async {
                await context.pushRoute(MobileLoginRoute());
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(radius)),
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.person_add,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )),
              title: const Text("Create an account",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                  "Create an account on the MATRIX server of your choice"),
              trailing: const Icon(Icons.navigate_next),
              onTap: () async {
                await context.pushRoute(const MobileCreateAccountRoute());
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(radius)),
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.explore,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )),
              title: const Text("Explore",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Explore the public rooms and pages"),
              trailing: const Icon(Icons.navigate_next),
              onTap: () async {
                await context.pushRoute(const MobileExploreRoute());
              },
            ),
          ],
        ),
      ),
    );
  }
}
