import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lcbc_athletica_booker/dbsettings.dart';
import 'package:lcbc_athletica_booker/helpers.dart';
import 'package:lcbc_athletica_booker/screens/home.dart';
import 'package:provider/provider.dart';

import '../sioapi.dart';

class LoginForm extends StatefulWidget {
  final Function(String, String) onSubmit;

  const LoginForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final textControllerUsername = TextEditingController();
  final textControllerPassword = TextEditingController();
  late FocusNode pwFocusNode;

  @override
  void initState() {
    super.initState();
    pwFocusNode = FocusNode();
  }

  void submit() {
    widget.onSubmit(
        textControllerUsername.value.text, textControllerPassword.value.text);
  }

  @override
  void dispose() {
    textControllerUsername.dispose();
    textControllerPassword.dispose();
    pwFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(
              child: TextFormField(
            controller: textControllerUsername,
            decoration: const InputDecoration(
              labelText: 'SIO Username',
            ),
            autocorrect: false,
            readOnly: false,
            onFieldSubmitted: (_) => pwFocusNode.requestFocus(),
          )),
        ]),
        Row(children: [
          Expanded(
              child: TextFormField(
            controller: textControllerPassword,
            decoration: const InputDecoration(
              labelText: 'SIO Password',
            ),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            readOnly: false,
            focusNode: pwFocusNode,
            onFieldSubmitted: (_) => submit(),
          )),
          TextButton(onPressed: () => submit(), child: const Text("Submit"))
        ])
      ],
    );
    ;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _State {
  getPassword,
  getToken,
}

class _LoginScreenState extends State<LoginScreen> {
  _State state = _State.getPassword;
  String password = "";
  String username = "";

  Widget _getCurrentItem() {
    switch (state) {
      case _State.getPassword:
        return LoginForm(
          onSubmit: (u, p) => {
            setState(() {
              password = p;
              username = u;
              state = _State.getToken;
            }),
          },
        );
      case _State.getToken:
        return FutureBuilder<String>(
          future: fetchAccessToken(username: username, password: password),
          builder: (context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              // save to db
              (() async {
                final dbs = context.read<DbSettings>();
                await dbs.setStr(DbSettings.ACCESS_TOKEN_STR, snapshot.data!);
                replacePage(context, const HomeScreen());
              })();
              return const Text("yay");
            }
            if (snapshot.hasError) {
              Timer(
                  const Duration(seconds: 2),
                  () => {
                        setState(() {
                          password = "";
                          username = "";
                          state = _State.getPassword;
                        })
                      });
              return Text(snapshot.error.toString());
            }
            return const CircularProgressIndicator();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LaScaffold(
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return SlideTransition(
                          child: child,
                          position: Tween<Offset>(
                                  begin: Offset(1.5, 0), end: Offset(0, 0))
                              .animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOutSine)));
                    },
                    child: _getCurrentItem()))));
  }
}
