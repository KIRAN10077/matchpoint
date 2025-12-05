import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchpoint/screens/home_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // form key and controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
 
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE1FBFF),
              Color(0xFFCFFFE1),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 120),
      Image.asset(
        'assets/images/matchpoint_logo_final.png',
        height: 160,
      ),
      const SizedBox(height: 10),
      Text(
        "MatchPoint",
        style: GoogleFonts.audiowide(
          fontSize: 32,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 30),
    Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Sign Up (tappable, goes to register later)
    Text(
      "Sign Up",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black54,
      ),
    ),
    const SizedBox(width: 25),

    // Log In (active)
    Column(
      children: [
        const Text(
          "Log In",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Container(
          height: 2,
          width: 60,
          margin: const EdgeInsets.only(top: 4),
          color: Colors.blueAccent,
        ),
      ],
    ),
  ],
),
const SizedBox(height: 30),

Form(
  key: _formKey,
  child: Column(
    children: [
      //Email
      TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
            labelText: "Email",
            hintText: "Enter your email",
            prefixIcon: Icon(Icons.email),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
   ),
 ),
),
SizedBox(height: 16,),
    // Password
    TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: "Password",
        hintText: "Enter your password",
        prefixIcon: const Icon(Icons.lock),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    ),
    SizedBox(height: 2,),

    // Forgot password
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          //
        },
        child: const Text(
          "Forgot Password?",
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue,
          ),
        ),
      ),
    ),

    SizedBox(height: 30,),
    
    ElevatedButton(
   onPressed: () {
     Navigator.pushReplacement(
       context,
       MaterialPageRoute(builder: (_) => const HomeScreen()),
     );
   },
   style: ElevatedButton.styleFrom(
     padding: const EdgeInsets.symmetric(vertical: 14),
     backgroundColor: Colors.blueAccent, // TEMP — matches your gradient theme later
     shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(14),
     ),
   ),
   child: const Text(
     "Sign In",
     style: TextStyle(
       fontSize: 18,
       fontWeight: FontWeight.w600,
       color: Colors.white,
     ),
   ),
 ),
 
 const SizedBox(height: 20),


    ],
    )
  )
          ],
        )
      ),
    );
  }
}