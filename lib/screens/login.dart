import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/screens/home/screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LoginTitle(),
          LoginCard(),
        ],
      )),
    );
  }
}

class LoginTitle extends StatelessWidget {
  const LoginTitle({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(50),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Mines'Trix",
            style: TextStyle(fontSize: 50, fontWeight: FontWeight.w800)),
        Text("An alternative social media based on MATRIX",
            style: TextStyle(fontSize: 30))
      ]),
    );
  }
}

class LoginCard extends StatefulWidget {
  LoginCard({Key key}) : super(key: key);
  @override
  LoginCardState createState() => LoginCardState();
}

class LoginCardState extends State<LoginCard> {
  final TextEditingController _usernameController = TextEditingController(),
      _passwordController = TextEditingController(),
      _domainController = TextEditingController();

  String _errorText;
  bool _isLoading = false;

  void _loginAction(Client client) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await client.checkHomeserver(_domainController.text);
      await client.login(
          user: _usernameController.text, password: _passwordController.text, initialDeviceDisplayName: client.clientName);
    } catch (error) {
      setState(() => _errorText = error.toString());
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).sclient;
    return SizedBox(
        child: Container(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(children: <Widget>[
                  LoginInput(
                      name: "userid",
                      icon: Icons.account_circle,
                      tController: _usernameController),
                  LoginInput(
                      name: "password",
                      icon: Icons.lock_outline,
                      tController: _passwordController,
                      obscureText:true),
                  LoginInput(
                      name: "server url",
                      icon: Icons.language,
                      tController: _domainController,
                      errorText: _errorText),
                  RaisedButton(
                      child: _isLoading
                          ? LinearProgressIndicator()
                          : Text('Login'),
                      onPressed:
                          _isLoading ? null : () => _loginAction(client)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton.extended(
                      label: Text("Login"),
                      onPressed: () {
                        changePage(context);
                      },
                      icon: const Icon(Icons.login),
                    ),
                  ),
                ]))));
  }

  void changePage(BuildContext context) {
    print(_usernameController.text);
    print(_passwordController.text);
    print(_domainController.text);
    if (2 == 3)
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ));
  }
}

class LoginInput extends StatelessWidget {
  const LoginInput(
      {Key key, this.name, this.icon, this.tController, this.errorText, this.obscureText = false})
      : super(key: key);
  final String name;
  final IconData icon;
  final TextEditingController tController;
  final String errorText;
  final bool obscureText;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: tController,
        obscureText: obscureText,
        decoration: InputDecoration(
          errorText: errorText,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          filled: true,
          icon: Icon(icon),
          labelText: name,
        ),
      ),
    );
  }
}
