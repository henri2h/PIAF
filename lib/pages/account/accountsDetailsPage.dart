import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';

class AccountsDetailsPage extends StatefulWidget {
  const AccountsDetailsPage({Key key}) : super(key: key);

  @override
  _AccountsDetailsPageState createState() => _AccountsDetailsPageState();
}

class _AccountsDetailsPageState extends State<AccountsDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        H1Title("Accounts"),
        ListTile(
            title: Text("Private account", style: TextStyle(fontSize: 22)),
            trailing: Icon(Icons.arrow_forward, size: 22),
            leading: Icon(Icons.person, size: 22),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Scaffold(
                          appBar: AppBar(title: Text("My accounts")),
                          body: AccountsDetailsPage())));
            }),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: OutlinedButton(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Text("Create a public account"),
              ),
              onPressed: () {}),
        )
      ],
    );
  }
}
