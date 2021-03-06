import 'dart:convert';
import 'dart:html';

import 'package:firebase_web/firebase.dart' as fb;
import 'package:firebase_web/src/assets/assets.dart';

main() async {
  //Use for firebase package development only
  await config();

  try {
    fb.initializeApp(
        apiKey: apiKey,
        authDomain: authDomain,
        databaseURL: databaseUrl,
        storageBucket: storageBucket);

    PhoneAuthApp();
  } on fb.FirebaseJsNotLoadedException catch (e) {
    print(e);
  }
}

class PhoneAuthApp {
  final fb.Auth auth;
  final FormElement registerForm, verificationForm;
  final InputElement _phoneElement,
      _codeElement,
      _registerSubmit,
      _verifySubmit;
  final AnchorElement logout;
  final TableElement authInfo;
  final ParagraphElement error;

  fb.RecaptchaVerifier verifier;
  fb.ConfirmationResult confirmationResult;

  PhoneAuthApp()
      : this.auth = fb.auth(),
        this.logout = querySelector("#logout_btn"),
        this.error = querySelector(".error"),
        this.authInfo = querySelector("#auth_info"),
        this._phoneElement = querySelector("#phone"),
        this._codeElement = querySelector("#code"),
        this.registerForm = querySelector("#register_form"),
        this.verificationForm = querySelector("#verification_form"),
        this._registerSubmit = querySelector('#register'),
        this._verifySubmit = querySelector('#verify') {
    logout.onClick.listen((e) {
      e.preventDefault();
      auth.signOut();
      _resetVerifier();
    });

    this.registerForm.onSubmit.listen((e) {
      e.preventDefault();
      var phoneValue = _phoneElement.value.trim();
      _registerUser(phoneValue);
    });

    this.verificationForm.onSubmit.listen((e) {
      e.preventDefault();
      var codeValue = _codeElement.value.trim();
      _verifyUser(codeValue);
    });

    // After opening
    if (auth.currentUser != null) {
      _setLayout(auth.currentUser);
    } else {
      _initVerifier();
    }

    // When auth state changes
    auth.onAuthStateChanged.listen(_setLayout);
  }

  _initVerifier() {
    // This is anonymous recaptcha - size must be defined
    verifier = fb.RecaptchaVerifier("register", {
      "size": "invisible",
      "callback": (resp) {
        print("reCAPTCHA solved, allow signInWithPhoneNumber.");
      },
      "expired-callback": () {
        print("Response expired. Ask user to solve reCAPTCHA again.");
      }
    });

    // Use this if you want to use recaptcha widget directly
    //verifier = new fb.RecaptchaVerifier("recaptcha-container")..render();
  }

  _resetVerifier() {
    verifier.clear();
    _initVerifier();
  }

  _registerUser(String phone) async {
    if (phone.isNotEmpty) {
      try {
        _registerSubmit.disabled = _phoneElement.disabled = true;
        error.text = 'Signing in...';
        confirmationResult = await auth.signInWithPhoneNumber(phone, verifier);
        error.text = '';
        verificationForm.style.display = "block";
        registerForm.style.display = "none";
      } catch (e, stack) {
        window.console.error(e);
        window.console.error(stack);
        error.text = e.toString();
      } finally {
        _registerSubmit.disabled = _phoneElement.disabled = false;
      }
    } else {
      error.text = "Please fill correct phone number.";
    }
  }

  _verifyUser(String code) async {
    if (code.isNotEmpty && confirmationResult != null) {
      try {
        _verifySubmit.disabled = _codeElement.disabled = true;
        error.text = 'Verifying...';
        await confirmationResult.confirm(code);
        error.text = '';
      } catch (e, stack) {
        window.console.error(e);
        window.console.error(stack);
        error.text = e.toString();
      } finally {
        _verifySubmit.disabled = _codeElement.disabled = false;
      }
    } else {
      error.text = "Please fill correct verification code.";
    }
  }

  void _setLayout(fb.User user) {
    if (user != null) {
      registerForm.style.display = "none";
      verificationForm.style.display = "none";
      logout.style.display = "block";
      _phoneElement.value = "";
      _codeElement.value = "";
      error.text = "";
      authInfo.style.display = "block";

      var data = <String, dynamic>{
        "email": user.email,
        "emailVerified": user.emailVerified,
        "isAnonymous": user.isAnonymous,
        "phoneNumber": user.phoneNumber,
        "metadata.creationTime": user.metadata.creationTime,
        "metadata.lastSignInTime": user.metadata.lastSignInTime
      };

      data.forEach((k, v) {
        if (v != null) {
          var row = authInfo.addRow();

          row.addCell()
            ..text = k
            ..classes.add("header");
          row.addCell().text = "$v";
        }
      });

      print("User.toJson:");
      print(const JsonEncoder.withIndent(' ').convert(user));
    } else {
      registerForm.style.display = "block";
      authInfo.style.display = "none";
      logout.style.display = "none";
      authInfo.children.clear();
    }
  }
}
