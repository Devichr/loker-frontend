import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;  // Tambahkan import untuk socket_io_client

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: const SafeArea(
        child: Column(
          children: [
            HeaderSection(),
            SizedBox(height: 16.0),
            LokerListSection(),
            Spacer(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(18.0),
      decoration: const BoxDecoration(
        color: Color(0xFF007AFF),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage:
                NetworkImage('https://via.placeholder.com/50'),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Loker Berbasis IOT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50),
              Text(
                "STMIK MARDIRA INDONESIA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Loker {
  final String lokerId;
  final String status;

  Loker({required this.lokerId, required this.status});

  factory Loker.fromJson(Map<String, dynamic> json) {
    return Loker(
      lokerId: json['loker_id'].toString(),
      status: json['status'],
    );
  }
}

class LokerListSection extends StatefulWidget {
  const LokerListSection({Key? key}) : super(key: key);

  @override
  _LokerListSectionState createState() => _LokerListSectionState();
}

class _LokerListSectionState extends State<LokerListSection> {
  List<Loker> lokers = [];
  bool isLoading = true;
  bool hasError = false;
  late IO.Socket socket;  // Deklarasikan Socket.io

  @override
  void initState() {
    super.initState();
    fetchLokers();
    connectSocket();  // Hubungkan ke Socket.io saat inisialisasi
  }

  Future<void> fetchLokers() async {
    try {
      final response = await http.get(Uri.parse('https://yourlock.vercel.app/api/lokers'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          lokers = data.map((json) => Loker.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  // Fungsi untuk menghubungkan ke WebSocket
  void connectSocket() {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('loker-status-changed', (data) {
      setState(() {
        final updatedLoker = Loker.fromJson(data);
        final index = lokers.indexWhere((loker) => loker.lokerId == updatedLoker.lokerId);
        if (index != -1) {
          lokers[index] = updatedLoker;
        } else {
          lokers.add(updatedLoker);  // Jika loker baru, tambahkan ke list
        }
      });
    });
  }

  @override
  void dispose() {
    socket.dispose();  // Pastikan untuk menutup koneksi WebSocket saat widget dibuang
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? const Center(
                    child: Text(
                      "Gagal memuat data.",
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  )
                : lokers.isEmpty
                    ? const Center(
                        child: Text(
                          "Tidak ada data loker.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Loker Tersedia",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ...lokers.map((loker) => LokerItem(
                                icon: loker.status == "Occupied"
                                    ? Icons.lock
                                    : Icons.lock_open,
                                name: loker.lokerId,
                                status: loker.status,
                              )),
                        ],
                      ),
      ),
    );
  }
}

class LokerItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String status;

  const LokerItem({
    super.key,
    required this.icon,
    required this.name,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Text(
            status,
            style: TextStyle(
              color: status == "Occupied" ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Text(
        "Made With Love",
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}
