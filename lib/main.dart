import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

// Initialize Firebase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCWlrbD3celRsAH4XkSKR5SSBMa27Sr_I8",
      authDomain: "car-wash-login--otp.firebaseapp.com",
      projectId: "car-wash-login--otp",
      storageBucket: "car-wash-login--otp.firebasestorage.app",
      messagingSenderId: "533494688138",
      appId: "1:533494688138:web:a14d925defb43a4ca30073",
      measurementId: "G-JKHYBN284K",
    ),
  );
  
  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // Configure FCM
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  String? token = await messaging.getToken();
  print("FCM Token: $token");
  
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'speedwash_channel',
            'SpeedWash Notifications',
            channelDescription: 'Car wash booking updates',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    }
  });
  
  runApp(SpeedWashApp());
}

class SpeedWashApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeedWash Premium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFD92323),
        primaryColorDark: Color(0xFFB91C1C),
        scaffoldBackgroundColor: Color(0xFFF2F4F8),
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

// 1. SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD92323),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_car_wash,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'SpeedWash',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Premium Doorstep Service',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// 2. MAIN HOME SCREEN
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  PageController _pageController = PageController();
  FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  late Razorpay _razorpay;

  final List<Widget> _screens = [
    HomeView(),
    BookBikeScreen(),
    BookCarScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Payment Success: ${response.paymentId}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Successful! Booking confirmed.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFD92323),
        unselectedItemColor: Color(0xFFBBBBBB),
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.two_wheeler),
            label: 'Bike',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Car',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF25D366),
        child: Icon(Icons.chat, color: Colors.white),
        onPressed: () async {
          const url = 'https://wa.me/918927646785';
          if (await canLaunch(url)) {
            await launch(url);
          }
        },
      ),
    );
  }
}

// 3. HOME VIEW
class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Map<String, dynamic>> slides = [
    {
      'title': '50% OFF\nFirst Wash',
      'subtitle': 'Premium Doorstep Service',
      'color': Colors.black,
    },
    {
      'title': 'Bike Wash\n₹99 Only',
      'subtitle': 'With Monthly Plan',
      'color': Color(0xFF111111),
    },
  ];

  List<Map<String, dynamic>> services = [
    {
      'icon': Icons.two_wheeler,
      'title': 'Bike Wash',
      'subtitle': 'Starts ₹99 (Monthly)',
      'highlight': false,
      'save': 'SAVE ₹197',
    },
    {
      'icon': Icons.directions_car,
      'title': 'Car Wash',
      'subtitle': 'Starts ₹299 (Monthly)',
      'highlight': true,
      'save': 'SAVE UP TO ₹897',
    },
  ];

  List<Map<String, dynamic>> features = [
    {'icon': Icons.home, 'label': 'Doorstep'},
    {'icon': Icons.security, 'label': 'Pro Staff'},
    {'icon': Icons.water_drop, 'label': 'Less Water'},
    {'icon': Icons.battery_full, 'label': 'Own Power'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SpeedWash',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Hello Guest',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        // Open location picker
                      },
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Color(0xFFD92323)),
                          SizedBox(width: 4),
                          Text(
                            'Locate Me',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD92323),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Refer Banner
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1e1e1e), Color(0xFF3a3a3a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFFFC107), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refer & Get ₹100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFC107),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Friend gets 50% OFF their first wash!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle referral
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFC107),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 14, color: Colors.black),
                      SizedBox(width: 5),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Slider
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: slides.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: slides[index]['color'],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slides[index]['title'],
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        slides[index]['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          if (index == 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BookCarScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BookBikeScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD92323),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(index == 0 ? 'Book Now' : 'View Plans'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20),

          // Services Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(height: 15),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                return ServiceCard(service: services[index]);
              },
            ),
          ),

          SizedBox(height: 20),

          // Features
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Why Choose Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(height: 15),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(features[index]['icon'], color: Color(0xFFD92323)),
                      SizedBox(width: 10),
                      Text(
                        features[index]['label'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 40),

          // Footer
          Container(
            padding: EdgeInsets.all(30),
            color: Color(0xFF111111),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () async {
                        const url = 'https://wa.me/918927646785';
                        if (await canLaunch(url)) {
                          await launch(url);
                        }
                      },
                      icon: Icon(Icons.chat, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.facebook, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Terms',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Text(' | ', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Privacy',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '© 2024 SpeedWash Premium',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Service Card Widget
class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;

  ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (service['title'] == 'Car Wash') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookCarScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookBikeScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: service['highlight'] ? Color(0xFFFFF9F9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: service['highlight'] 
              ? Border.all(color: Color(0xFFD92323), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    service['save'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFFF4F6F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service['icon'],
                  size: 30,
                  color: Color(0xFFD92323),
                ),
              ),
              SizedBox(height: 10),
              Text(
                service['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Text(
                service['subtitle'],
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  if (service['title'] == 'Car Wash') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookCarScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookBikeScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: service['highlight'] ? Color(0xFFD92323) : Colors.transparent,
                  foregroundColor: service['highlight'] ? Colors.white : Colors.black,
                  side: service['highlight'] ? null : BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: Size(double.infinity, 40),
                ),
                child: Text(
                  service['title'] == 'Car Wash' ? 'Book Car Wash' : 'Book Bike Wash',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. BOOK CAR SCREEN (Wizard)
class BookCarScreen extends StatefulWidget {
  @override
  _BookCarScreenState createState() => _BookCarScreenState();
}

class _BookCarScreenState extends State<BookCarScreen> {
  int _currentStep = 0;
  String _selectedCarType = 'hatchback';
  String _selectedService = 'exterior';
  String _selectedPlan = 'monthly';
  String _selectedDate = 'today';
  String? _selectedTime;
  TextEditingController _modelController = TextEditingController();
  TextEditingController _numberController = TextEditingController();
  TextEditingController _addressController = TextEditingController();

  Map<String, Map<String, Map<String, int>>> carPrices = {
    'hatchback': {
      'exterior': {'single': 299, 'monthly': 899},
      'full': {'single': 399, 'monthly': 1299},
    },
    'sedan': {
      'exterior': {'single': 399, 'monthly': 1199},
      'full': {'single': 499, 'monthly': 1499},
    },
    'suv': {
      'exterior': {'single': 599, 'monthly': 1499},
      'full': {'single': 799, 'monthly': 2499},
    },
  };

  List<String> carTypes = ['hatchback', 'sedan', 'suv'];
  List<String> services = ['exterior', 'full'];
  List<String> timeSlots = ['9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Car Wash Booking'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepCircle(0, 'Vehicle'),
                  _buildStepCircle(1, 'Details'),
                  _buildStepCircle(2, 'Checkout'),
                ],
              ),
            ),

            // Steps
            _currentStep == 0 ? _buildStep1() :
            _currentStep == 1 ? _buildStep2() : _buildStep3(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convenience Fee: FREE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '₹${_getPrice()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD92323),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentStep < 2) {
                  setState(() {
                    _currentStep++;
                  });
                } else {
                  _initiatePayment();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD92323),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text(
                _currentStep == 2 ? 'Pay & Book' : 'Next Step',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, String label) {
    bool isActive = stepNumber == _currentStep;
    bool isCompleted = stepNumber < _currentStep;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFFD92323) : 
                   isCompleted ? Color(0xFF2E7D32) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Color(0xFFD92323) : 
                     isCompleted ? Color(0xFF2E7D32) : Color(0xFFF0F0F0),
              width: 2,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: Color(0xFFD92323).withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: Center(
            child: isCompleted 
                ? Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    (stepNumber + 1).toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Color(0xFFCCCCCC),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Color(0xFFD92323) : Colors.grey,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Select Car Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              marginBottom: 15,
            ),
          ),
          
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: carTypes.length,
            itemBuilder: (context, index) {
              String type = carTypes[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCarType = type;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedCarType == type ? Color(0xFFFFF5F5) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedCarType == type ? Color(0xFFD92323) : Color(0xFFEEEEEE),
                      width: _selectedCarType == type ? 2 : 1,
                    ),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _selectedCarType == type ? Color(0xFFD92323) : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: 25),
          
          Text(
            '2. Select Service & Plan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              marginBottom: 15,
            ),
          ),
          
          // Service Toggle
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedService = 'exterior';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedService == 'exterior' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Exterior Only',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedService == 'exterior' ? Colors.black : Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedService = 'full';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedService == 'full' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Ext + Interior',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedService == 'full' ? Colors.black : Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Plan Cards
          _buildPlanCard('monthly', true),
          SizedBox(height: 15),
          _buildPlanCard('single', false),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String plan, bool isPopular) {
    int price = carPrices[_selectedCarType]![_selectedService]![plan]!;
    bool isSelected = _selectedPlan == plan;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (isPopular ? Color(0xFFD92323) : Color(0xFFD92323)) : Color(0xFFEEEEEE),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected && isPopular ? [
            BoxShadow(
              color: Color(0xFFD92323).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ] : [],
        ),
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFC107),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'MOST POPULAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  SizedBox(height: isPopular ? 8 : 0),
                  Text(
                    plan == 'monthly' ? 'Monthly Subscription' : 'One Time Wash',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    plan == 'monthly' ? '4 Washes • Effective ₹${(price/4).round()}/wash' : 'Deep Clean',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (plan == 'monthly') ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🎁 4x Free Air Freshener',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '₹$price',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD92323),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle & Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              marginBottom: 15,
            ),
          ),
          
          _buildTextField(Icons.directions_car, 'Car Model Name', _modelController),
          SizedBox(height: 15),
          _buildTextField(Icons.format_list_numbered, 'Vehicle Number', _numberController),
          SizedBox(height: 15),
          
          // Location Box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFEEEEEE)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFFD92323)),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Click GPS Icon ->',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Open map picker
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.gps_fixed, color: Color(0xFFD92323)),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 15),
          _buildTextField(Icons.location_pin, 'Full Address (e.g. House No.)', _addressController),
          
          SizedBox(height: 25),
          Text(
            'Select Date & Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              marginBottom: 15,
            ),
          ),
          
          // Date Toggle
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = 'today';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedDate == 'today' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Today',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedDate == 'today' ? Colors.black : Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = 'tomorrow';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedDate == 'tomorrow' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Tomorrow',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedDate == 'tomorrow' ? Colors.black : Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Time Slots
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2,
            ),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              String time = timeSlots[index];
              bool isSelected = _selectedTime == time;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTime = time;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.black : Color(0xFFE0E0E0),
                      width: 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ] : [],
                  ),
                  child: Center(
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: 20),
          
          // Water Check
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: false,
                  onChanged: (value) {},
                  activeColor: Color(0xFFD92323),
                ),
                Expanded(
                  child: Text(
                    'Can you provide 1-2 buckets of water?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    int price = _getPrice();
    
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFFAFAFA),
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _selectedPlan == 'monthly' ? 'Monthly Subscription' : 'One Time Wash',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.directions_car),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vehicle',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _modelController.text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _numberController.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      Divider(height: 1, color: Color(0xFFEEEEEE)),
                      
                      SizedBox(height: 20),
                      
                      _buildBillRow('Item Total', '₹$price'),
                      _buildBillRow('Convenience Fee', 'FREE'),
                      _buildBillRow('First Order (50%)', '- ₹${(price * 0.5).round()}'),
                      
                      SizedBox(height: 20),
                      
                      // Tip Section
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFDDDDDD), style: BorderStyle.dashed),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Tip your washer (Optional)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF555555),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTipButton(10),
                                SizedBox(width: 10),
                                _buildTipButton(30),
                                SizedBox(width: 10),
                                _buildTipButton(50),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      Divider(height: 1, color: Color(0xFFEEEEEE)),
                      
                      SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To Pay',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF555555),
                                ),
                              ),
                              Text(
                                'Incl. of all taxes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${((price * 0.5) + 0).round()}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD92323),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEEEEEE)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: label.contains('-') ? Color(0xFF166534) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipButton(int amount) {
    return Container(
      width: 45,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFDDDDDD)),
      ),
      child: Center(
        child: Text(
          '₹$amount',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  int _getPrice() {
    return carPrices[_selectedCarType]![_selectedService]![_selectedPlan]!;
  }

  void _initiatePayment() async {
    int price = ((_getPrice() * 0.5) + 0).round();
    
    var options = {
      'key': 'YOUR_RAZORPAY_KEY', // Replace with actual key
      'amount': price * 100, // amount in paise
      'name': 'SpeedWash',
      'description': 'Car Wash Booking',
      'prefill': {
        'contact': '9876543210',
        'email': 'customer@email.com'
      },
      'theme': {
        'color': '#D92323'
      }
    };
    
    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: $e');
    }
  }
}

// 5. BOOK BIKE SCREEN (Similar to Car)
class BookBikeScreen extends StatefulWidget {
  @override
  _BookBikeScreenState createState() => _BookBikeScreenState();
}

class _BookBikeScreenState extends State<BookBikeScreen> {
  int _currentStep = 0;
  String _selectedPlan = 'monthly';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bike Wash Booking'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepCircle(0, 'Plan'),
                  _buildStepCircle(1, 'Details'),
                  _buildStepCircle(2, 'Checkout'),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      marginBottom: 15,
                    ),
                  ),
                  
                  _buildBikePlanCard('monthly', 'Monthly Subscription', '4 Washes • ₹99/wash', '₹399', true),
                  SizedBox(height: 15),
                  _buildBikePlanCard('single', 'Single Wash', 'One time deep clean', '₹149', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepCircle(int stepNumber, String label) {
    // Same as car screen
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFFF0F0F0), width: 2),
          ),
          child: Center(
            child: Text(
              (stepNumber + 1).toString(),
              style: TextStyle(color: Color(0xFFCCCCCC)),
            ),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildBikePlanCard(String plan, String title, String subtitle, String price, bool isPopular) {
    bool isSelected = _selectedPlan == plan;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (isPopular ? Color(0xFFD92323) : Color(0xFFD92323)) : Color(0xFFEEEEEE),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFC107),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'MOST POPULAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  SizedBox(height: isPopular ? 8 : 0),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD92323),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. ACCOUNT SCREEN
class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFD92323),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile
            Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(Icons.person, size: 30, color: Color(0xFFCCCCCC)),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Guest User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      // Show login modal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD92323),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: Size(120, 40),
                    ),
                    child: Text('Login Now'),
                  ),
                ],
              ),
            ),
            
            // Sections
            _buildSection('Refer & Earn', [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFDDDDDD), style: BorderStyle.dashed),
                ),
                child: Center(
                  child: Text(
                    'Login to start earning rewards!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
            ]),
            
            _buildSection('Active Memberships', [
              Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFF0F0F0)),
                ),
                child: Center(
                  child: Text(
                    'No Active Plans',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
            ]),
            
            _buildSection('Live Tracking', [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'No Active Orders',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                    SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: 0.25,
                      backgroundColor: Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ]),
            
            _buildSection('Order History', [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No Past Orders',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
            ]),
            
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}