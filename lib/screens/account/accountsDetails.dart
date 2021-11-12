import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';

class AccountsDetails extends StatefulWidget {
  const AccountsDetails({Key key}) : super(key: key);

  @override
  _AccountsDetailsState createState() => _AccountsDetailsState();
}

class _AccountsDetailsState extends State<AccountsDetails> {
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
                          body: AccountsDetails())));
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
