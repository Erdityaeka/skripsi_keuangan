import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skripsi_keuangan/Screens/AI%20Analisis/ai_screen.dart';
import 'package:skripsi_keuangan/Screens/Profile/profile_screens.dart';
import 'package:skripsi_keuangan/Screens/home_screens.dart';
import 'package:skripsi_keuangan/Screens/transaksi/transaksi_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class TombolNav extends StatefulWidget {
  const TombolNav({super.key});

  @override
  State<TombolNav> createState() => _TombolNavState();
}

class _TombolNavState extends State<TombolNav> {
  int _selectedTabIndex = 0;

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Daftar halaman untuk setiap tab
    final List<Widget> listPage = <Widget>[
      const HomeScreens(),
      const TransaksiScreens(showBackButton: false),
      Container(),
      Container(),
      const ProfileScreens(),
    ];

    // Daftar item navigasi bawah
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
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 15),
              child: GestureDetector(
                onTap: () {
                  // Aksi ketika ikon AI ditekan
                  // Misalnya, navigasi ke halaman AI
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiScreen()),
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(
                      255,
                      255,
                      255,
                      255,
                    ), // warna background bulat
                    shape: BoxShape.circle, // bentuk bulat
                  ),
                  child: Center(child: Text("AI", style: redBold14)),
                ),
              ),
            ),
            label: "", // label di bawah icon
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

    // BottomNavigationBar
    final BottomNavigationBar bottomNavBar = BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: redBold20.color,
      items: bottomNavBarItems,
      currentIndex: _selectedTabIndex,
      unselectedItemColor: greyReguler.color, // Warna yang benar
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
      body: Center(child: listPage[_selectedTabIndex]),
      bottomNavigationBar: bottomNavBar, // Tambahkan di sini
    );
  }
}
