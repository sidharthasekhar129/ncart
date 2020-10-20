
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(LoginPage());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoggedIn = false;
  bool isLoggedIn2 = false;

  //for facebook
  var profileData;
  //for google
  String name;
  String email;
  String imageUrl;

  var facebookLogin = FacebookLogin();


  void onLoginStatusChanged(bool isLoggedIn, {profileData}) {
    setState(() {
      this.isLoggedIn = isLoggedIn;
      this.profileData = profileData;
    });
  }
  void onGoogleLoginStatusChanged(bool isLoggedIn, String name,String email,String url) {
    setState(() {
      this.isLoggedIn2 = isLoggedIn;
      this.name = name;
      this.email = email;
      this.imageUrl = url;

    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       home:
        Scaffold(
         appBar: AppBar(
          title: Text("Login"),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              onPressed: () => facebookLogin.isLoggedIn
                  .then((isLoggedIn) => isLoggedIn ? _logout() : {}),
            ),
          ],
         ),
          body: Container(
           child:  Center(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isLoggedIn
                      ? _displayUserData(profileData)
                      : _displayLoginButton(),
                  SizedBox(
                    height: 25,
                  ),
                  isLoggedIn2 ?
                      Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              imageUrl,
                            ),
                            radius: 60,
                            backgroundColor: Colors.transparent,
                          ),
                          Text(
                            name,
                            style: TextStyle(
                                fontSize: 25,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold),
                          ),
                          Padding(

                            padding: EdgeInsets.all(15),
                            child: Text(

                              email,
                              style: TextStyle(

                                  fontSize: 25,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 40),
                          RaisedButton(
                            onPressed: () {
                              signOutGoogle();
                              this.setState(() {
                                isLoggedIn2=false;
                              });
                            //  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) {return LoginPage2();}), ModalRoute.withName('/'));
                            },
                            color: Colors.deepPurple,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Sign Out',
                                style: TextStyle(fontSize: 25, color: Colors.white),
                              ),
                            ),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40)),
                          )
                        ],
                      ):
                      RaisedButton(

                        child: Container(
                          alignment: Alignment.center,
                          width: 200,
                            height: 30,
                            child: Text("Google Signin",style: TextStyle(fontSize: 17,),)),
                        onPressed:  () => signInWithGoogle(),
                        color: Colors.lightBlue,
                        textColor: Colors.white,

                        padding: EdgeInsets.fromLTRB(9, 9, 9, 9),
                        splashColor: Colors.grey,
                      )
                ],
              )
            )
          ),
        ),
      ),
    );
  }

  void initiateFacebookLogin() async {
    var facebookLoginResult =
    await facebookLogin.logInWithReadPermissions(['email']);

    switch (facebookLoginResult.status) {
      case FacebookLoginStatus.error:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.cancelledByUser:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.loggedIn:
        var graphResponse = await http.get(
            'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult
                .accessToken.token}');

        var profile = json.decode(graphResponse.body);
        print(profile.toString());

        onLoginStatusChanged(true, profileData: profile);
        break;
    }
  }

  _displayUserData(profileData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 200.0,
          width: 200.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.fill,
              image: NetworkImage(
                profileData['picture']['data']['url'],
              ),
            ),
          ),
        ),
        SizedBox(height: 28.0),
        Text(
          "Logged in as: ${profileData['name']}",
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
      ],
    );
  }
 
  _displayLoginButton() {
    return
      RaisedButton(

        child: Container(
            alignment: Alignment.center,
            width: 200,
            height: 30,
            child: Text("Facebook Signin",style: TextStyle(fontSize: 17,),)),
        onPressed: () => initiateFacebookLogin(),
        color: Colors.lightBlue,
        textColor: Colors.white,

        padding: EdgeInsets.fromLTRB(9, 9, 9, 9),
        splashColor: Colors.grey,
      );
 
  }

  _logout() async {
    await facebookLogin.logOut();
    onLoginStatusChanged(false);
    print("Logged out");
  }


  Future<String> signInWithGoogle() async {
  //  await Firebase.initializeApp();

    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
    await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult =
    await _auth.signInWithCredential(credential);
    final User user = authResult.user;

    if (user != null) {
      // Checking if email and name is null
      assert(user.email != null);
      assert(user.displayName != null);
      assert(user.photoURL != null);
      onGoogleLoginStatusChanged(true,user.displayName,user.email,user.photoURL);


      // Only taking the first part of the name, i.e., First Name
      if (name.contains(" ")) {
        name = name.substring(0, name.indexOf(" "));
      }

      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final User currentUser = _auth.currentUser;
      assert(user.uid == currentUser.uid);

      print('signInWithGoogle succeeded: $user');

      return '$user';
    }

    return null;
  }

  Future<void> signOutGoogle() async {
    await googleSignIn.signOut();

    print("User Signed Out");
  }
}