import 'package:flutter/material.dart';

class SettingsScreen2 extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen2> {
  bool darkMode = false;
  bool safety = false;
  bool weather = false;
  bool locationaccess = false;
  bool locationupdate = false;
  String selectedFontSize = 'Small';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffebeeef),
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Add back functionality here
          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Appearance',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 10),
            _buildContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xff193869),
                    value: darkMode,
                    onChanged: (value) {
                      setState(() {
                        darkMode = value;
                      });
                    },
                    title: const Text('Dark Mode',
                        style: TextStyle(fontSize: 11, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text('    Font Size:',
                          style:
                              TextStyle(fontSize: 11, fontFamily: 'Poppins')),
                      const SizedBox(width: 10),
                      _buildFontSizeOption(
                          'Small', selectedFontSize == 'Small'),
                      _buildFontSizeOption(
                          'Large', selectedFontSize == 'Large'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Notification',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 10),
            _buildContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xff193869),
                    value: safety,
                    onChanged: (value) {
                      setState(() {
                        safety = value;
                      });
                    },
                    title: const Text('safety alerts',
                        style: TextStyle(fontSize: 11, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    activeColor: const Color(0xff193869),
                    value: weather,
                    onChanged: (value) {
                      setState(() {
                        weather = value;
                      });
                    },
                    title: const Text('Weather Updates ',
                        style: TextStyle(fontSize: 12, fontFamily: 'Poppins')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 10),
            _buildContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xff193869),
                    value: locationaccess,
                    onChanged: (value) {
                      setState(() {
                        locationaccess = value;
                      });
                    },
                    title: const Text('Location Access',
                        style: TextStyle(fontSize: 11, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    activeColor: const Color(0xff193869),
                    value: locationupdate,
                    onChanged: (value) {
                      setState(() {
                        locationupdate = value;
                      });
                    },
                    title: const Text('Location Updates ',
                        style: TextStyle(fontSize: 11, fontFamily: 'Poppins')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Privacy & Security',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 10),
            _buildContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "setup lock",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Manage who can see your medical data",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Logout From All Devices",
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xffe87064),
                          fontFamily: 'Poppins'),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'General Settings',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 10),
            _buildContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Language",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Backup & Restore Data",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Default Actions for Emergency Situations",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'About & Support',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 10),
            _buildContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "About Follow Safe",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Terms & Conditions",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Privacy Policy",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Feedback",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15, bottom: 15, top: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
            width: double.infinity,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildFontSizeOption(String size, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: ChoiceChip(
        selectedColor: Color(0xff193869),
        disabledColor: Color(0xf0000000000),
        backgroundColor: Color(0xffebeeef),
        label: Text(
          size,
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        selected: isSelected,
        onSelected: (value) {
          setState(() {
            selectedFontSize = size;
          });
        },
      ),
    );
  }
}
