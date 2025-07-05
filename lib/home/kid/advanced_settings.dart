import 'package:flutter/material.dart';

class AdvancedSettings extends StatefulWidget {
  @override
  _AdvancedSettingsState createState() => _AdvancedSettingsState();
}

class _AdvancedSettingsState extends State<AdvancedSettings> {
  Color selectedColor = Colors.blue;
  bool isDarkMode = false;
  String kidName = "Sarah Wijaya";
  bool overrideSilentMode = false;
  bool vibrationAlerts = false;
  bool visualAlerts = false;
  bool darkMode = false;
  bool weather = false;
  bool safety = false;
  bool locationaccess = false;
  bool locationupdate = false;
  String selectedFontSize = 'Small';
  String timeFrame = '0:20';

  List<String> predefinedMessages = ['I\'m in danger'];

  Map<String, bool> checkboxStates = {
    '"I\'m in danger"': false,
  };

  TextEditingController otherMessageController = TextEditingController();
  final TextEditingController timeFrameController =
      TextEditingController(text: '0:20');

  double vibrationIntensity = 0.5;

  void _showTimeFrameDialog() {
    TextEditingController minutesController = TextEditingController();
    TextEditingController secondsController = TextEditingController();

    List<String> timeParts = timeFrame.split(':');
    if (timeParts.length < 2) {
      minutesController.text = timeFrame;
      secondsController.text = '00';
    } else {
      minutesController.text = timeParts[0];
      secondsController.text = timeParts[1];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Time Frame'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minutesController,
                decoration: const InputDecoration(
                    labelText: 'Minutes',
                    labelStyle: TextStyle(
                        color: Color(0xff193869), fontFamily: 'Poppins'),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xff193869)))),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: secondsController,
                decoration: const InputDecoration(
                    labelText: 'Seconds',
                    labelStyle: TextStyle(
                        color: Color(0xff193869), fontFamily: 'Poppins'),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xff193869)))),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Color(0xff193869), fontFamily: 'Poppins')),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  timeFrame =
                      '${minutesController.text}:${secondsController.text.padLeft(2, '0')}';
                  timeFrameController.text = timeFrame;
                });
                Navigator.of(context).pop();
              },
              child: const Text('OK',
                  style: TextStyle(
                      color: Color(0xff193869), fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

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
            bottom: 0, // يمتد إلى أسفل الشاشة
            width: MediaQuery.of(context).size.width, // يأخذ العرض بالكامل
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text('Timer Frame',
                      style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
                  const SizedBox(height: 10),
                  _buildContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: timeFrameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _showTimeFrameDialog,
                            ),
                          ),
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Predefined Message',
                      style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
                  const SizedBox(height: 10),
                  _buildContainer(
                    child: Column(
                      children: [
                        ...predefinedMessages.map((message) {
                          return CheckboxListTile(
                            value: checkboxStates[message] ?? false,
                            onChanged: (value) {
                              setState(() {
                                checkboxStates[message] = value!;
                              });
                            },
                            title: Text(message),
                          );
                        }).toList(),
                        TextFormField(
                          controller: otherMessageController,
                          decoration: InputDecoration(
                            hintText: 'Other',
                            border: const UnderlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (otherMessageController.text.isNotEmpty) {
                                  setState(() {
                                    predefinedMessages
                                        .add(otherMessageController.text);
                                    checkboxStates[
                                        otherMessageController.text] = false;
                                    otherMessageController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          onFieldSubmitted: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                predefinedMessages.add(value);
                                checkboxStates[value] = false;
                                otherMessageController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Primary Emergency Contacts',
                      style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
                  const SizedBox(height: 10),
                  _buildContainer(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildContactIcon('Mum', 'assets/images/man.jpeg'),
                          _buildContactIcon('Dad', 'assets/images/man.jpeg'),
                          _buildContactIcon('Mum', 'assets/images/man.jpeg'),
                          _buildContactIcon('Dad', 'assets/images/man.jpeg'),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.add_circle,
                                color: Color(0xff193869), size: 40),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: SwitchListTile(
                      activeColor: const Color(0xff193869),
                      value: overrideSilentMode,
                      onChanged: (value) {
                        setState(() {
                          overrideSilentMode = value;
                        });
                      },
                      title: const Text('Override Silent Mode',
                          style:
                              TextStyle(fontSize: 11, fontFamily: 'Poppins')),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContainer(
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: const Color(0xff193869),
                          value: vibrationAlerts,
                          onChanged: (value) {
                            setState(() {
                              vibrationAlerts = value;
                            });
                          },
                          title: const Text('Vibration Alerts',
                              style: TextStyle(
                                  fontSize: 11, fontFamily: 'Poppins')),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              const Text(
                                'Intensity Level',
                                style: TextStyle(
                                    fontSize: 11, fontFamily: 'Poppins'),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 60,
                                  child: Slider(
                                    value: vibrationIntensity,
                                    onChanged: (value) {
                                      setState(() {
                                        vibrationIntensity = value;
                                      });
                                    },
                                    min: 0.0,
                                    max: 10.0,
                                    divisions: 100,
                                    label:
                                        vibrationIntensity.toStringAsFixed(1),
                                    activeColor: const Color(0xff193869),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SwitchListTile(
                          activeColor: const Color(0xff193869),
                          value: visualAlerts,
                          onChanged: (value) {
                            setState(() {
                              visualAlerts = value;
                            });
                          },
                          title: const Text('Visual Alerts',
                              style: TextStyle(
                                  fontSize: 11, fontFamily: 'Poppins')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Notification',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
                              style: TextStyle(
                                  fontSize: 11, fontFamily: 'Poppins')),
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
                              style: TextStyle(
                                  fontSize: 12, fontFamily: 'Poppins')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Location',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
                              style: TextStyle(
                                  fontSize: 11, fontFamily: 'Poppins')),
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
                              style: TextStyle(
                                  fontSize: 11, fontFamily: 'Poppins')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Privacy & Security',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
                  const Text('General Settings',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
                  const Text('About & Support',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
          ),
        ],
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

  Widget _buildContactIcon(String name, String image) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                backgroundImage: AssetImage(image)),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(String size, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: ChoiceChip(
        selectedColor: const Color(0xff193869),
        disabledColor: const Color(0xf0000000000),
        backgroundColor: const Color(0xffebeeef),
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
