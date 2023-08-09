import 'dart:io';

import 'package:chat_app/widgets/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = false;
  final _formKey = GlobalKey<FormState>();
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredname = '';
  File? _selectedImage;
  var _isAuthenticating = false;
  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogin && _selectedImage == null) {
      return;
    }
    _formKey.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        //login with email adn password
        final userCredential = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        //create new user

        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_image')
            .child('${userCredential.user!.uid}.png');
        await storageRef.putFile(_selectedImage!);
        final url = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc('${userCredential.user!.uid}')
            .set({
          'username': _enteredname,
          'image_url': url,
          'email': '${userCredential.user!.email}'
        });
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authrntication falied')));
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: SingleChildScrollView(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(
                  top: 30, bottom: 20, left: 20, right: 20),
              width: 200,
              child: Image.asset('assets/chat.png'),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLogin)
                        UserImagePicker(
                          onPickImage: (pickedImage) {
                            _selectedImage = pickedImage;
                          },
                        ),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'E-mail', icon: Icon(Icons.email)),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email addres';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _enteredEmail = newValue!;
                        },
                        textCapitalization: TextCapitalization
                            .none, //turn off the CApitalization for the first caracter
                      ),
                      if (!_isLogin)
                        TextFormField(
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                              labelText: 'Username', icon: Icon(Icons.person)),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length < 4) {
                              return 'Plase enter at least 4 characters';
                            }
                          },
                          onSaved: (newValue) {
                            _enteredname = newValue!;
                          },
                        ),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Password', icon: Icon(Icons.lock)),
                        obscureText: true,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              value.trim().length < 6) {
                            return 'Password must be at least 6 chacracters long';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _enteredPassword = newValue!;
                        },
                        textCapitalization: TextCapitalization
                            .none, //turn off the CApitalization for the first caracter
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      if (_isAuthenticating) CircularProgressIndicator(),
                      if (!_isAuthenticating)
                        ElevatedButton(
                            onPressed: () {
                              _submit();
                            },
                            child: Text(_isLogin ? 'Login' : 'SingUp')),
                      if (!_isAuthenticating)
                        TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(_isLogin
                                ? 'Create an account'
                                : 'I already have an account'))
                    ],
                  )),
            )),
          )
        ])),
      ),
    );
  }
}
