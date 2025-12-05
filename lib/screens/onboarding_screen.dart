import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchpoint/screens/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
PageController _pageController = PageController();
int _currentPage = 0;


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
    SizedBox(height: 80,),
    //logo
    Image.asset('assets/images/matchpoint_logo_final.png', height: 200,),
    //title
    Text(
      "MatchPoint",
      style: GoogleFonts.audiowide(
        fontSize: 28,
        color: Colors.black,
      ),
    ),
  // PAGEVIEW PLACEHOLDER
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children:  [
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height*0.38,
                      child:Image.asset('assets/images/image1_onboarding.jpg', fit: BoxFit.contain),
                      ),

                      SizedBox(height: 20,),

                      //title
                      Text("Book Courts Easily",textAlign: TextAlign.center,style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),),

                      //subtitle
                      Text("Find and book nearby sports courts in just a few taps!", textAlign: TextAlign.center,style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),)
                    ],
                  ),

                  //page2
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height*0.38,
                      child:Image.asset('assets/images/image2_onboarding.png', fit: BoxFit.contain),
                      ),

                      SizedBox(height: 20,),

                      //title
                      Text("Real-time Availability",textAlign: TextAlign.center,style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),),

                      //subtitle
                      Text("Check which courts are free and reserve instantly.", textAlign: TextAlign.center,style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),)
                    ],
                  ),
                  //page3
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height*0.38,
                      child:Image.asset('assets/images/image3_onboarding.jpg', fit: BoxFit.contain),
                      ),

                      SizedBox(height: 20,),

                      //title
                      Text("Play With Friends",textAlign: TextAlign.center,style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),),

                      //subtitle
                      Text("Invite your friends and enjoy the game together.", textAlign: TextAlign.center,style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),)
                    ],
                  )
                ],
              ),
            ),
SizedBox(height: 16,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
          List.generate(3, (index)=>AnimatedContainer(
          duration: Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 9,
            width: _currentPage == index ? 18:8,
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.blueAccent : Colors.blueGrey,
              borderRadius: BorderRadius.circular(10),
          ),
          ),
          ), 
        ),

        Padding(
  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
  child: ElevatedButton(
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    },
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      backgroundColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
      ),

    ),
    child: const Text(
      "Get Started",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ),
),

const SizedBox(height: 30),
        ]
      ),
    ),
    );
  
  }
}