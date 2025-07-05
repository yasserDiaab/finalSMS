import 'package:flutter/material.dart';

class ParentSave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor:
            const Color(0xFF12C2E9), // جعل الخلفية بنفس لون التدرج اللوني
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width, // يملأ العرض بالكامل
            height: MediaQuery.of(context).size.height, // يملأ الارتفاع بالكامل
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF12C2E9), Color(0xFF3BCA92)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // الصورة في المنتصف
                Positioned(
                  top: 160,
                  left: 25,
                  right: 25,
                  child: Image.asset(
                    "assets/images/family.png",
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  top: 50,
                  right: 20,
                  child: Image.asset(
                    "assets/images/sun.png",
                    width: 200, // زيادة حجم الشمس
                    height: 200, // زيادة حجم الشمس
                  ),
                ),

                const Positioned(
                  bottom: 180,
                  left: 40,
                  right: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Do not Worry!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Your parent will save you soon",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 100,
                  left: 100,
                  right: 100,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(65, 219, 142, 1),
                            Color.fromRGBO(2, 95, 104, 1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.black, width: 2)),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            "Ok",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
