import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skripsi_keuangan/Screens/AI Analisis/ai_screen.dart';
import 'package:skripsi_keuangan/Screens/Grafik/grafik_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/profile_screens.dart';
import 'package:skripsi_keuangan/Screens/Home/home_screens.dart';
import 'package:skripsi_keuangan/Screens/transaksi/transaksi_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedTabIndex = 0;

  void _onNavBarTapped(int index) {
    // 🔥 KHUSUS AI (INDEX 2)
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiScreen()),
      );
      return; // 🔥 PENTING: jangan ubah index
    }

    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 AI DIHAPUS DARI LIST
    final List<Widget> listPage = <Widget>[
      const HomeScreens(),
      TransaksiScreens(showBackButton: false),
      Container(), // dummy (index 2)
      GrafikScreens(),
      const ProfileScreens(),
    ];

    final List<BottomNavigationBarItem> bottomNavBarItems =
        <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Icon(Icons.home_filled),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Icon(Icons.post_add),
            ),
            label: 'Transaksi',
          ),

          // 🔥 AI BUTTON (TANPA GestureDetector)
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text("AI", style: redBold14)),
              ),
            ),
            label: "",
          ),

          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Icon(Icons.leaderboard),
            ),
            label: 'Grafik',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ];

    final BottomNavigationBar bottomNavBar = BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: redBold20.color,
      items: bottomNavBarItems,
      currentIndex: _selectedTabIndex,
      unselectedItemColor: greyReguler.color,
      selectedItemColor: Colors.white,
      onTap: _onNavBarTapped,
      selectedLabelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.white,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: greyReguler.color,
      ),
    );

    return Scaffold(
      body: listPage[_selectedTabIndex],
      bottomNavigationBar: bottomNavBar,
    );
  }
}
