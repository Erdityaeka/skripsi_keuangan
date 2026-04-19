import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/transaksi/edit_transaksi.dart';
import 'package:skripsi_keuangan/Screens/transaksi/tambah_transaksi.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class TransaksiScreens extends StatefulWidget {
  //memebriukan opsi button pada appbar
  final bool showBackButton;
  const TransaksiScreens({super.key, required this.showBackButton});

  @override
  State<TransaksiScreens> createState() => _TransaksiScreensState();
}

class _TransaksiScreensState extends State<TransaksiScreens> {
  bool _isPasswordVisible = false;
  String? Bank;

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
            child: Column(
              children: [
                cardtransaksi(),
                const SizedBox(height: 20),
                cardBank(),
                const SizedBox(height: 50),
                listTransaksi(),
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // posisi tombol di kanan bawah
    );
  }

  // ui appbar
  PreferredSizeWidget _buildAppbar(context) {
    return AppBar(
      backgroundColor: whiteBold.color,
      automaticallyImplyLeading: false, // matikan otomatis
      leading: widget.showBackButton
          ? IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back, color: red),
            )
          : null,
      title: Text('Transaksi', style: redBold20),
      centerTitle: true,

      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  // ui card transaksi
  Widget cardtransaksi() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: redblack,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 21.0, right: 15, left: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pemasukan', style: greenBold15),
                const SizedBox(height: 5),
                Text(
                  'Rp. 1.000.000',
                  style: whiteReguler,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pemasukan', style: yellowBold15),
                  const SizedBox(height: 5),
                  Text(
                    'Rp. 1.000.000',
                    style: whiteReguler,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Total', style: whiteBold),
                      const SizedBox(width: 5),
                      IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    _isPasswordVisible ? 'Rp. 1.000.000' : '••••••••',
                    style: whiteReguler,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ui card bank dengan dropdown
  Widget cardBank() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.keyboard_arrow_left_outlined, color: white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Januari', style: whiteBold),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: Bank,
                    hint: Text('SEMUA', style: whiteReguler),
                    isDense: true,
                    dropdownColor: red,
                    icon: Icon(Icons.arrow_drop_down, color: white, size: 18),
                    onChanged: (String? newValue) {
                      setState(() {
                        Bank = newValue;
                      });
                    },
                    items:
                        <String>[
                          'SEMUA',
                          'Bank BCA',
                          'Bank Mandiri',
                          'Bank BNI',
                          'Bank BTN',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: whiteReguler,
                            ), // hanya teks, tanpa ikon
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Icon(Icons.keyboard_arrow_right_outlined, color: white),
          ],
        ),
      ),
    );
  }

  // ui list transaksi
  Widget listTransaksi() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('15, Maret, 2026', style: redReguler12),
                    Text('Rp. 1.000.000', style: greenBold12),
                    Text('Rp. 1.000.000', style: yellowBold12),
                  ],
                ),
              ),
              Divider(
                color: red, // warna garis
                thickness: 1, // ketebalan garis
                indent: 0, // jarak kiri
                endIndent: 0,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditTransaksi()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40, // lebar lingkaran
                          height: 40, // tinggi lingkaran
                          decoration: BoxDecoration(
                            color: green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.call_made, color: white, size: 24),
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ayam Goreng',
                              style: redBold15,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Makanan',
                              style: redReguler12,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Bank BCA',
                              style: redReguler12,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          'Rp. 1.000.000',
                          style: greenBold12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditTransaksi()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40, // lebar lingkaran
                          height: 40, // tinggi lingkaran
                          decoration: BoxDecoration(
                            color: yellow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.call_made, color: white, size: 24),
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ikan Goreng',
                              style: redBold15,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Makanan',
                              style: redReguler12,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Bank BCA',
                              style: redReguler12,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          'Rp. 1.000.000',
                          style: yellowBold12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TambahTransaksi()),
        );
      },
      backgroundColor: red,
      child: Icon(Icons.add, color: white),
    );
  }
}
