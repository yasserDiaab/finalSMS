import 'package:flutter/material.dart';
import 'package:pro/login/login.dart';
import 'package:pro/widgets/login_button.dart';
import 'package:pro/widgets/overlappingimage.dart';
// import 'package:graduationproject1/components/CustomButton.dart';
// import 'package:graduationproject1/components/CustomImage.dart';
// import 'package:graduationproject1/views/LOGIN/LogIn.dart';
// import 'package:graduationproject1/views/LOGIN/SignUp.dart';

class Splach3 extends StatelessWidget {
  const Splach3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(
            height: 30,
          ),
          const Padding(
            padding: EdgeInsets.all(18),
            child: SizedBox(
              width: double.infinity,
              height: 300, // Adjusted the height for proper display
              child: SizedBox(
                child: OverlappingImages(
                  photo1: 'assets/images/img5.png',
                  photo2: 'assets/images/img6.png',
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 35,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 35,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 35,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xff193869),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(
                height: 20,
              )
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Add your medical information',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Poppins',
                color: Color(
                  0xff212429,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              'store important medical information, such as allergies, medications, and medical conditions, which can be accessed by first responders during an emerge',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Color(
                  0xff212429,
                ),
              ),
              maxLines: 4,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          LoginButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return FollowSafeAuthScreen();
                    },
                  ),
                );
              },
              label: 'Log in',
              Color1: const Color(0xff193869),
              color2: Colors.white,
              color3: const Color(0Xff193869)),
          const SizedBox(
            height: 5,
          ),
          LoginButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return FollowSafeAuthScreen();
                    },
                  ),
                );
              },
              label: 'Sign Up',
              Color1: const Color(0xff193869),
              color2: Colors.white,
              color3: const Color(0xff193869))
        ],
      ),
    );
  }
}
