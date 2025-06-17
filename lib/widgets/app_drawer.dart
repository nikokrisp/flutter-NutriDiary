import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nutridiary/providers/app_state_provider.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onAboutTap;
  const AppDrawer({super.key, this.onAboutTap});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    return Drawer(
      width: MediaQuery.of(context).size.width * .65,
      backgroundColor: const Color.fromARGB(255, 35, 48, 0),
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            opacity: 0.25,
            image: AssetImage('images/fruity background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                  Color.fromARGB(200, 141, 182, 0), // vibrant grass green
                  Color.fromARGB(210, 117, 148, 23), // olive green
                  Color.fromARGB(224, 89, 127, 7), // darker moss/leaf green
                  Color.fromARGB(235, 79, 107, 2), // your base dark green
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: appState.profilePictureUrl != null
                        ? NetworkImage(appState.profilePictureUrl!)
                        : const NetworkImage('https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg'),
                  ),
                  Text(
                    appState.profileUsername ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.terrain_outlined, color: Color.fromARGB(255, 231, 231, 231)),
              title: const Text("Dark Theme", style: TextStyle(color: Color.fromARGB(255, 194, 194, 194))),
              trailing: Switch(
                value: appState.isDarkMode,
                onChanged: (value) {
                  appState.toggleTheme(value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Color.fromARGB(255, 231, 231, 231)),
              title: const Text("About Us", style: TextStyle(color: Color.fromARGB(255, 194, 194, 194))),
              onTap: onAboutTap ?? () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color.fromARGB(255, 231, 231, 231)),
              title: const Text("Logout", style: TextStyle(color: Color.fromARGB(255, 194, 194, 194))),
              onTap: () {
                appState.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
