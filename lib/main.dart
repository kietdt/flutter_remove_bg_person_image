import 'package:flutter/material.dart';
import 'package:flutter_remove_bg_person/feature/remove_bg_person_image/remove_bg_person_image.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final TextEditingController controller = TextEditingController();

  String? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Put the url here",
                  errorText: error,
                ),
              ),
              const SizedBox(height: 20),
              Builder(builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    String url = controller.text;

                    if (url.trim().isEmpty) {
                      setState(() {
                        error = "Please add the URL";
                      });
                      return;
                    }

                    Uri uri = Uri.parse(url);

                    var isValid = await canLaunchUrl(uri);

                    if (isValid) {
                      setState(() {
                        error = null;
                      });

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) {
                              return RemoveBgPersonImage(
                                url: uri,
                              );
                            },
                          ),
                        );
                      }
                    } else {
                      setState(() {
                        error = "The url is not valid";
                      });
                    }
                  },
                  child: const Text("Remove background"),
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}
