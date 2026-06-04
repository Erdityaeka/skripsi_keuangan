import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/AI Analisis/ai_screen.dart';
import 'package:skripsi_keuangan/Screens/Grafik/grafik_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/profile_screens.dart';
import 'package:skripsi_keuangan/Screens/Home/home_screens.dart';
import 'package:skripsi_keuangan/Screens/transaksi/transaksi_screens.dart';

import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedTabIndex = 0;

  final FirestoreService firestore = FirestoreService();

  void _onNavBarTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiScreen()),
      );
      return;
    }

    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> listPage = <Widget>[
      const HomeScreens(),
      TransaksiScreens(showBackButton: false),
      Container(),
      GrafikScreens(),
      const ProfileScreens(),
    ];

    final List<BottomNavigationBarItem> bottomNavBarItems =
        <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.home_filled),
            ),
            label: 'Home',
          ),

          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.post_add),
            ),
            label: 'Transaksi',
          ),

          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bottomTerpilih,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text("AI", style: putihBold14)),
              ),
            ),
            label: "",
          ),

          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.leaderboard),
            ),
            label: 'Grafik',
          ),

          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: firestore.getJumlahTagihanPenting(),
              builder: (context, snapshot) {
                final jumlah = snapshot.data ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.person),

                      if (jumlah > 0)
                        Positioned(
                          right: -8,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: rednotif,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text('$jumlah', style: putihBold10),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            label: 'Profile',
          ),
        ];

    final BottomNavigationBar bottomNavBar = BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: putih,
      items: bottomNavBarItems,
      currentIndex: _selectedTabIndex,
      unselectedItemColor: bottomTidakTerpilih,
      selectedItemColor: bottomTerpilih,
      onTap: _onNavBarTapped,
      selectedLabelStyle: bottomTerpilihBold14,
      unselectedLabelStyle: bottomTidakTerpilihBold14,
    );

    return Scaffold(
      body: listPage[_selectedTabIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: hitam, width: 1)),
        ),
        child: bottomNavBar,
      ),
    );
  }
}
