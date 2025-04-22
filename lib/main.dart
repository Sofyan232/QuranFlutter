// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // Import provider
import 'dart:convert';
import 'dart:async';
import 'font_loader_service.dart';
// --- Models ---
// (Models: Surah, Ayah, SurahDetail remain the same as before)
// Represents a Surah in the list
class Surah {
  final int nomor;
  final String nama;
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;
  final String deskripsi; // Keep for model consistency, but won't display
  final Map<String, String> audioFull;

  Surah({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.deskripsi,
    required this.audioFull,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      nomor: json['nomor'] ?? 0,
      nama: json['nama'] ?? '',
      namaLatin: json['namaLatin'] ?? '',
      jumlahAyat: json['jumlahAyat'] ?? 0,
      tempatTurun: json['tempatTurun'] ?? '',
      arti: json['arti'] ?? '',
      deskripsi: json['deskripsi'] ?? '', // Parse but don't display
      audioFull: Map<String, String>.from(json['audioFull'] ?? {}),
    );
  }
}

// Represents a single Ayah (verse)
class Ayah {
  final int nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;
  final Map<String, String> audio;

  Ayah({
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    required this.audio,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      nomorAyat: json['nomorAyat'] ?? 0,
      teksArab: json['teksArab'] ?? '',
      teksLatin: json['teksLatin'] ?? '',
      teksIndonesia: json['teksIndonesia'] ?? '',
      audio: Map<String, String>.from(json['audio'] ?? {}),
    );
  }
}

// Represents the detailed information of a Surah
class SurahDetail {
  final int nomor;
  final String nama;
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;
  final String deskripsi; // Keep for model consistency
  final Map<String, String> audioFull;
  final List<Ayah> ayat;

  SurahDetail({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.deskripsi,
    required this.audioFull,
    required this.ayat,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    var listAyat = json['ayat'] as List? ?? [];
    List<Ayah> ayatList = listAyat.map((i) => Ayah.fromJson(i)).toList();

    return SurahDetail(
      nomor: json['nomor'] ?? 0,
      nama: json['nama'] ?? '',
      namaLatin: json['namaLatin'] ?? '',
      jumlahAyat: json['jumlahAyat'] ?? 0,
      tempatTurun: json['tempatTurun'] ?? '',
      arti: json['arti'] ?? '',
      deskripsi: json['deskripsi'] ?? '', // Parse but don't display
      audioFull: Map<String, String>.from(json['audioFull'] ?? {}),
      ayat: ayatList,
    );
  }
}


// --- API Service ---
// (ApiService remains the same as before)
class ApiService {
  final String _baseUrl = "https://equran.id/api/v2";

  Future<List<Surah>> getSurahList() async {
    try {
        final response = await http.get(Uri.parse('$_baseUrl/surat')).timeout(const Duration(seconds: 15)); // Add timeout

        if (response.statusCode == 200) {
        Map<String, dynamic> decodedBody = json.decode(response.body);
        if (decodedBody.containsKey('data') && decodedBody['data'] is List) {
            List<dynamic> data = decodedBody['data'];
            return data.map((json) => Surah.fromJson(json)).toList();
        } else {
            throw Exception('Invalid data format received from API');
        }
        } else {
        throw Exception('Failed to load surah list (Status code: ${response.statusCode})');
        }
    } on TimeoutException catch (_) {
         throw Exception('Request timed out. Please check your connection.');
    } catch (e) {
         // Re-throw other exceptions or handle them specifically
         throw Exception('Failed to load surah list: ${e.toString()}');
    }
  }

  Future<SurahDetail> getSurahDetail(int nomorSurah) async {
     try {
        final response = await http.get(Uri.parse('$_baseUrl/surat/$nomorSurah')).timeout(const Duration(seconds: 20)); // Add timeout

        if (response.statusCode == 200) {
        Map<String, dynamic> decodedBody = json.decode(response.body);
        if (decodedBody.containsKey('data') && decodedBody['data'] is Map<String, dynamic>) {
            return SurahDetail.fromJson(decodedBody['data']);
        } else {
            throw Exception('Invalid data format received from API for surah detail');
        }
        } else {
        throw Exception('Failed to load surah detail (Status code: ${response.statusCode})');
        }
    } on TimeoutException catch (_) {
         throw Exception('Request timed out. Please check your connection.');
    } catch (e) {
         throw Exception('Failed to load surah detail: ${e.toString()}');
    }
  }
}

// --- Providers (State Management) ---

// Manages Theme State
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
     if (_themeMode == ThemeMode.system) {
       // Access brightness from a context if possible, otherwise default to light
       // This might need adjustment depending on where it's called.
       // For simplicity here, we'll default to light if system is chosen initially.
       // A better approach might involve getting platform brightness initially.
       // final Brightness platformBrightness = MediaQuery.platformBrightnessOf(context);
       // return platformBrightness == Brightness.dark;
       return false; // Default assumption if system brightness unknown initially
     } else {
       return _themeMode == ThemeMode.dark;
     }
  }


  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      // TODO: Persist theme preference using shared_preferences
    }
  }
}

// Manages Settings State
class SettingsProvider extends ChangeNotifier {
  bool _showTranslation = true;
  double _arabicFontSize = 26.0; // Default Arabic font size

  bool get showTranslation => _showTranslation;
  double get arabicFontSize => _arabicFontSize;

  void toggleTranslation(bool value) {
    _showTranslation = value;
    notifyListeners();
    // TODO: Persist setting using shared_preferences
  }

  void setArabicFontSize(double size) {
    // Add constraints if needed (e.g., min/max size)
    if (size >= 16.0 && size <= 40.0) { // Example constraints
       _arabicFontSize = size;
       notifyListeners();
       // TODO: Persist setting using shared_preferences
    }
  }
}


// --- Main Application ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the Amiri font from a URL
  try {
    await FontLoaderService.loadFontFromUrl(
      fontUrl: 'https://example.com/fonts/Amiri-Regular.ttf', // Replace with actual URL
      fontFamily: 'Misbah',
    );
  } catch (e) {
    print('Failed to load font: $e');
    // Optionally, proceed with a fallback font
  }

  runApp(
    // Provide the state managers to the widget tree
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: QuranApp(),
    ),
  );
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Quran App',
      themeMode: themeProvider.themeMode, // Use theme mode from provider
      theme: ThemeData( // Light Theme
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto', // Default font for non-Arabic text
        appBarTheme: AppBarTheme(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white // Title/icon color
        ),
        cardTheme: CardTheme(
            elevation: 1.0,
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
        ),
        listTileTheme: ListTileThemeData(
            iconColor: Colors.green[800]
        ),
         sliderTheme: SliderThemeData( // Style slider for light theme
           activeTrackColor: Colors.green[600],
           inactiveTrackColor: Colors.green[100],
           thumbColor: Colors.green[700],
           overlayColor: Colors.green.withOpacity(0.2),
         ),
         switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.green[700];
              }
              return null; // Default thumb color
            }),
            trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
               if (states.contains(WidgetState.selected)) {
                 return Colors.green[300];
               }
               return null; // Default track color
            }),
         ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(secondary: Colors.amber),
      ),
      darkTheme: ThemeData( // Dark Theme
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[850],
            foregroundColor: Colors.white // Title/icon color
        ),
         cardTheme: CardTheme(
            elevation: 2.0,
            color: Colors.grey[800], // Darker cards
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
        ),
        listTileTheme: ListTileThemeData(
            iconColor: Colors.green[300]
        ),
        iconTheme: IconThemeData(color: Colors.green[300]), // Default icon color
        textTheme: ThemeData.dark().textTheme.apply( // Ensure text is readable
            bodyColor: Colors.grey[300],
            displayColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
            ),
        ),
         sliderTheme: SliderThemeData( // Style slider for dark theme
           activeTrackColor: Colors.green[600],
           inactiveTrackColor: Colors.grey[700],
           thumbColor: Colors.green[400],
           overlayColor: Colors.green.withOpacity(0.3),
         ),
         switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.green[400];
              }
              return Colors.grey[600]; // Thumb color when off
            }),
            trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
               if (states.contains(WidgetState.selected)) {
                 return Colors.green[800];
               }
               return Colors.grey[700]; // Track color when off
            }),
         ),
        // Adjust color scheme for dark mode
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green, brightness: Brightness.dark).copyWith(secondary: Colors.amberAccent),
      ),
      debugShowCheckedModeBanner: false,
      // Start with SurahListScreen, Settings access will be from there
      home: SurahListScreen(),
      // Define route for settings screen
      routes: {
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

// --- Screens ---

// Screen to display the list of Surahs
class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  _SurahListScreenState createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  Future<List<Surah>>? _surahListFuture; // Make nullable initially
  final ApiService _apiService = ApiService();
  List<Surah> _allSurahs = [];
  List<Surah> _filteredSurahs = [];
  final TextEditingController _searchController = TextEditingController();
  String? _errorMessage; // To store potential error messages

  @override
  void initState() {
    super.initState();
    _loadSurahs(); // Initial load
    _searchController.addListener(_filterSurahs);
  }

  // Load surahs from the API
  void _loadSurahs() {
    // Reset error message and set state to trigger FutureBuilder
    setState(() {
       _errorMessage = null;
       _surahListFuture = _apiService.getSurahList();
    });

    // Handle the future's result/error after it completes
    _surahListFuture?.then((surahs) {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _allSurahs = surahs;
          _filteredSurahs = surahs;
        });
      }
    }).catchError((error) {
       if (mounted) {
         setState(() {
             _errorMessage = error.toString(); // Store error message
         });
         print("Error loading surahs: $error");
       }
    });
  }

  // Filter surahs based on search input
  void _filterSurahs() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSurahs = _allSurahs.where((surah) {
        return surah.namaLatin.toLowerCase().contains(query) ||
               surah.arti.toLowerCase().contains(query) ||
               surah.nomor.toString().contains(query);
      }).toList();
    });
  }


  @override
  void dispose() {
    _searchController.removeListener(_filterSurahs);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme provider to access theme mode for styling search bar
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDarkMode; // Check if dark mode is active

    return Scaffold(
      appBar: AppBar(
        title: Text('Al-Quran (equran.id)'),
        actions: [
            // Settings Icon Button
            IconButton(
                icon: Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                },
            ),
            // Theme Toggle Icon Button
            IconButton(
                icon: Icon(themeProvider.themeMode == ThemeMode.light
                    ? Icons.dark_mode_outlined
                    : themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.brightness_auto_outlined // Icon for system mode
                 ),
                 tooltip: 'Toggle Theme',
                onPressed: () {
                    ThemeMode currentMode = themeProvider.themeMode;
                    ThemeMode nextMode;
                    if (currentMode == ThemeMode.light) {
                        nextMode = ThemeMode.dark;
                    } else if (currentMode == ThemeMode.dark) {
                        nextMode = ThemeMode.system; // Cycle: Light -> Dark -> System -> Light
                    } else {
                        nextMode = ThemeMode.light;
                    }
                    themeProvider.setThemeMode(nextMode);
                },
            ),
        ],
        bottom: PreferredSize(
           preferredSize: Size.fromHeight(kToolbarHeight),
           child: Padding(
             padding: const EdgeInsets.all(8.0),
             child: TextField(
               controller: _searchController,
               decoration: InputDecoration(
                 hintText: 'Cari Surah (Nama, Angka, Arti)...',
                 // Use theme-aware colors
                 prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                 filled: true,
                 fillColor: isDark ? Colors.grey[700] : Colors.white.withOpacity(0.9),
                 border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                 ),
                 contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                 hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
               ),
               style: TextStyle(color: isDark ? Colors.white : Colors.black), // Text input color
             ),
           ),
        ),
      ),
      body: _buildBody(), // Use helper method to build body
    );
  }

  // Helper method to build the body content based on state
  Widget _buildBody() {
     // If there's an error message, show it with a retry button
     if (_errorMessage != null) {
        return Center(
            child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Text('Error: $_errorMessage', textAlign: TextAlign.center),
                    SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: _loadSurahs, // Retry button
                        child: Text('Retry'),
                    )
                ],
            ),
            )
        );
     }

     // Use FutureBuilder only if the future is not null
     if (_surahListFuture == null) {
        // This state might occur briefly or if initial load fails immediately
        return Center(child: Text("Initializing..."));
     }

     // Use FutureBuilder to handle loading state
     return FutureBuilder<List<Surah>>(
        future: _surahListFuture,
        builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading indicator while waiting for data
            return Center(child: CircularProgressIndicator());
            }
            // Note: Error handling is now primarily done via _errorMessage state
            // else if (snapshot.hasError) { ... } // This part is less critical now

            else if (snapshot.hasData) {
            // Display the list of surahs if data is available
            if (_allSurahs.isEmpty) {
                // Handle case where API returns success but empty data
                return Center(child: Text('No Surahs found.'));
            }
            if (_filteredSurahs.isEmpty && _searchController.text.isNotEmpty) {
                return Center(child: Text('No Surahs found for "${_searchController.text}"'));
            }
            // If filtered list is empty but allSurahs is not, it means filtering is active
            // but nothing matches, or data is still being processed by the filter listener.
            // A loading indicator might be too flashy here, so showing the empty message is better.

            return ListView.builder(
                itemCount: _filteredSurahs.length,
                itemBuilder: (context, index) {
                final surah = _filteredSurahs[index];
                return Card(
                    // Card theme is applied globally
                    child: ListTile(
                    leading: CircleAvatar(
                        // Use theme colors
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                            surah.nomor.toString(),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold)
                        ),
                    ),
                    title: Text(surah.namaLatin, style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('${surah.arti} (${surah.jumlahAyat} ayat)'),
                    trailing: Text(
                        surah.nama,
                        // Use the specified Amiri font from assets
                        style: TextStyle(
                            fontFamily: 'Amiri', // Specify the font family declared in pubspec
                            fontSize: 18.0,
                            color: Theme.of(context).colorScheme.primary
                        )
                    ),
                    onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SurahDetailScreen(surah: surah),
                        ),
                        );
                    },
                    ),
                );
                },
            );
            } else {
            // Fallback for unexpected state (e.g., future completes with no data and no error)
            // This case is less likely with the new error handling but good to have.
            return Center(child: Text('No data available.'));
            }
        },
     );
  }
}

// Screen to display the details of a Surah
class SurahDetailScreen extends StatefulWidget {
  final Surah surah; // Receive the basic Surah info

  const SurahDetailScreen({super.key, required this.surah});

  @override
  _SurahDetailScreenState createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  Future<SurahDetail>? _surahDetailFuture; // Make nullable
  final ApiService _apiService = ApiService();
  String? _errorMessage; // For error handling

  @override
  void initState() {
    super.initState();
    _loadSurahDetail();
  }

  // Load surah details from the API
  void _loadSurahDetail() {
     setState(() {
         _errorMessage = null; // Reset error on retry/load
         _surahDetailFuture = _apiService.getSurahDetail(widget.surah.nomor);
     });
     // Handle potential errors when the future completes
     _surahDetailFuture?.catchError((error) {
        if (mounted) {
            setState(() {
                _errorMessage = error.toString();
            });
            print("Error loading detail: $error");
        }
     });
  }

  @override
  Widget build(BuildContext context) {
    // Access SettingsProvider
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.surah.namaLatin} (${widget.surah.nama})',
             style: TextStyle(fontFamily: 'Amiri', fontSize: 16) // Use Amiri for Arabic in title too
        ),
      ),
      body: _buildDetailBody(settingsProvider), // Use helper
    );
  }

  Widget _buildDetailBody(SettingsProvider settingsProvider) {
     // Show error if present
     if (_errorMessage != null) {
        return Center(
            child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Text('Error loading details: $_errorMessage', textAlign: TextAlign.center),
                    SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: _loadSurahDetail, // Retry button
                        child: Text('Retry'),
                    )
                ],
            ),
            )
        );
     }

     // Show loading or content using FutureBuilder
     if (_surahDetailFuture == null) {
        return Center(child: Text("Initializing detail view..."));
     }

     return FutureBuilder<SurahDetail>(
        future: _surahDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // Error handled by _errorMessage state now
          // else if (snapshot.hasError) { ... }

          else if (snapshot.hasData) {
            final surahDetail = snapshot.data!;
            return ListView(
              padding: EdgeInsets.all(12.0),
              children: [
                // Surah Header Info Card
                Card(
                  // elevation and margin handled by theme
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${surahDetail.namaLatin} (${surahDetail.nama})',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri' // Use Amiri for Arabic name here
                           ),
                        ),
                        SizedBox(height: 8),
                        Text('Arti: ${surahDetail.arti}'),
                        Text('Jumlah Ayat: ${surahDetail.jumlahAyat}'),
                        Text('Tempat Turun: ${surahDetail.tempatTurun}'),
                        SizedBox(height: 10),
                        // Bismillah display
                        if (surahDetail.nomor != 1 && surahDetail.nomor != 9)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Text(
                                'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
                                style: TextStyle(
                                    fontFamily: 'Amiri', // Use Amiri font
                                    fontSize: settingsProvider.arabicFontSize + 2, // Slightly larger Bismillah
                                    color: Theme.of(context).colorScheme.primary
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        // --- Description Removed ---
                        // Divider(height: 20, thickness: 1),
                        // Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold)),
                        // SizedBox(height: 4),
                        // SelectableText(
                        //    surahDetail.deskripsi, // This is removed
                        //    textAlign: TextAlign.justify,
                        //    style: TextStyle(color: Colors.grey[700])
                        // ),
                      ],
                    ),
                  ),
                ),

                // Ayah List Header (Optional)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                  child: Text(
                    "Ayat (${surahDetail.jumlahAyat})",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                // List of Ayahs
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: surahDetail.ayat.length,
                  itemBuilder: (context, index) {
                    final ayah = surahDetail.ayat[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0), // Increased vertical margin
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), // Adjusted padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                             // Ayah Number Row
                             Padding(
                               padding: const EdgeInsets.only(bottom: 12.0), // Space below number
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      child: Text(
                                          ayah.nomorAyat.toString(),
                                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)
                                      ),
                                   ),
                                   // Placeholder for potential actions (bookmark, share, audio)
                                   // Icon(Icons.more_vert, color: Colors.grey),
                                 ],
                               ),
                             ),
                            // Arabic Text
                            Text(
                              ayah.teksArab,
                              style: TextStyle(
                                  fontFamily: 'Misbah', // Use Amiri font
                                  fontSize: settingsProvider.arabicFontSize, // Use size from provider
                                  height: 1.9 // Adjust line height for readability
                               ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl, // Ensure right-to-left
                            ),
                            SizedBox(height: 16), // Increased spacing

                            // Indonesian Translation (Conditional)
                            if (settingsProvider.showTranslation) ...[ // Use collection-if
                               Divider(height: 20, thickness: 0.5), // Separator
                               Text(
                                '${ayah.nomorAyat}. ${ayah.teksIndonesia}',
                                style: TextStyle(fontSize: 15.0, height: 1.5),
                                textAlign: TextAlign.left,
                               ),
                               SizedBox(height: 8), // Space after translation
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          } else {
            return Center(child: Text('No details available.'));
          }
        },
      );
  }
}


// --- Settings Screen ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access providers
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    // Determine if the current theme is dark
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // --- Theme Settings ---
          Text('Theme', style: Theme.of(context).textTheme.titleLarge),
          RadioListTile<ThemeMode>(
            title: Text('Light'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
            secondary: Icon(Icons.light_mode_outlined),
          ),
          RadioListTile<ThemeMode>(
            title: Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
             secondary: Icon(Icons.dark_mode_outlined),
          ),
          RadioListTile<ThemeMode>(
            title: Text('System Default'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
             secondary: Icon(Icons.brightness_auto_outlined),
          ),

          Divider(height: 30, thickness: 1),

          // --- Display Settings ---
          Text('Display', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            title: Text('Show Translation'),
            subtitle: Text('Display Indonesian translation below Arabic text'),
            value: settingsProvider.showTranslation,
            onChanged: (value) => settingsProvider.toggleTranslation(value),
            secondary: Icon(Icons.translate),
          ),

          SizedBox(height: 16), // Spacing

          // Arabic Font Size Setting
          ListTile(
             title: Text('Arabic Font Size'),
             subtitle: Text('Adjust the size of the Arabic text'),
             leading: Icon(Icons.format_size), // Use leading instead of secondary for layout
          ),
          Slider(
            value: settingsProvider.arabicFontSize,
            min: 18.0, // Minimum readable size
            max: 40.0, // Maximum practical size
            divisions: 22, // (40-18) = 22 steps
            label: settingsProvider.arabicFontSize.round().toString(), // Show integer value
            onChanged: (value) {
              settingsProvider.setArabicFontSize(value);
            },
          ),
           // Display current font size value clearly
           Padding(
             padding: const EdgeInsets.only(right: 16.0), // Align to right
             child: Text(
                'Current Size: ${settingsProvider.arabicFontSize.toStringAsFixed(1)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
             ),
           ),

          // Add more settings here in the future (e.g., recitation choice, persistence info)
        ],
      ),
    );
  }
}