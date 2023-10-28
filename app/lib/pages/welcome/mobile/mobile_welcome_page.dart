import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../router.gr.dart';

@RoutePage()
class MobileWelcomePage extends StatelessWidget {
  const MobileWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 80.0, horizontal: 30),
                child: ListView(
                  children: [
                    Text(
                      "MinesTRIX",
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      "A privacy focused social media based on MATRIX",
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 60),
              child: FilledButton(
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Sign In",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                )),
                onPressed: () async {
                  await context.pushRoute(MobileLoginRoute());
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}