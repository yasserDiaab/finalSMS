import 'package:flutter/material.dart';
import 'package:pro/home/kid/phone_kid.dart';

class KidSettingsScreen extends StatefulWidget {
  @override
  _KidSettingsScreenState createState() => _KidSettingsScreenState();
}

class _KidSettingsScreenState extends State<KidSettingsScreen> {
  Color selectedColor = Colors.blue;
  bool isDarkMode = false;
  String kidName = "Sarah Wijaya";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 165),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3BE489), Color(0xFF00C2E0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, size: 18),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "Settings",
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: ClipOval(
                child: Image.asset(
                  "assets/images/girl.png",
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Appearance",
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("   Theme",
                              style: TextStyle(
                                  fontFamily: "Poppins", fontSize: 13)),
                          const SizedBox(width: 100),
                          for (var color in [
                            Colors.blue,
                            Colors.pink,
                            Colors.yellow,
                            Colors.purple
                          ])
                            GestureDetector(
                                onTap: () {
                                  setState(() => selectedColor = color);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == color
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ))
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text("Dark mode",
                            style:
                                TextStyle(fontFamily: "Poppins", fontSize: 13)),
                        value: isDarkMode,
                        onChanged: (value) =>
                            setState(() => isDarkMode = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Edit your name",
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(kidName,
                        style: const TextStyle(
                            fontFamily: "Poppins", fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 15),
                      onPressed: () => _showEditNameDialog(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Parent Control",
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: const Text("Advanced Settings",
                        style: TextStyle(fontFamily: "Poppins", fontSize: 13)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const PhoneVerificationScreen();
                      }));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    TextEditingController nameController = TextEditingController(text: kidName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name", style: TextStyle(fontFamily: "Poppins")),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(fontFamily: "Poppins")),
          ),
          TextButton(
            onPressed: () {
              setState(() => kidName = nameController.text);
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(fontFamily: "Poppins")),
          ),
        ],
      ),
    );
  }
}
