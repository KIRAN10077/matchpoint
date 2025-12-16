import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchpoint/screens/dashboard_screen.dart';
import 'package:matchpoint/screens/login_screen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // form key and controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
 
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
              Color.fromARGB(255, 145, 240, 211),
              Color.fromARGB(255, 108, 238, 158),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
      Image.asset(
        'assets/images/matchpoint_logo_final.png',
        height: 100,
      ),
      const SizedBox(height: 10),
      Text(
        "MatchPoint",
        style: GoogleFonts.audiowide(
          fontSize: 32,
          color: const Color.fromARGB(255, 0, 0, 0),
        ),
      ),
      const SizedBox(height: 30),
    Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Sign Up (tappable, goes to register later)
    Column(
      children: [
        Text(
          "Sign Up",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
    const SizedBox(width: 25),

    // Log In (inactive)
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
        
      ],
    ),
  ],
),
const SizedBox(height: 30),

Padding(
  padding: const EdgeInsets.all(16.0),
  child: Form(
    key: _formKey,
    child: Column(
      children: [
        //name
        TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
              labelText: "Name",
              hintText: "Enter your name",
              prefixIcon: Icon(Icons.person),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
     ),
   ),
  ),
  SizedBox(height: 16,),
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
          labelText: "Create a Password",
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
      SizedBox(height: 16,),
    // Confirm password
      TextFormField(
        controller: _confirmpasswordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: "Confirm Password",
          hintText: "Confirm your password",
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
  
  
      SizedBox(height: 40,),
      
      ElevatedButton(
     onPressed: () {
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(builder: (_) => const DashboardScreen()),
       );
     },
     style: ElevatedButton.styleFrom(
       padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 70),
       backgroundColor: Colors.blueAccent, 
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(14),
       ),
     ),
     child: const Text(
       "Sign Up",
       style: TextStyle(
         fontSize: 24,
         fontWeight: FontWeight.w600,
         color: Colors.white,
       ),
     ),
   ),
   
   const SizedBox(height: 20),
  
  //alreadyy have  an  account?????
  Row(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
       const Text(
         "Already own an account? ",
         style: TextStyle(fontSize: 14),
       ),
       GestureDetector(
         onTap: () {
         Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
         },
         child: const Text(
           "Log in here",
           style: TextStyle(
             color: Colors.blue,
             fontSize: 14,
             fontWeight: FontWeight.w600,
           ),
         ),
       ),
     ],
  ),
  
      ],
     )
    ),
)
          ],
        )
      ),
    );
  }
}