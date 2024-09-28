import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smarthome_channel',
      'SmartHome Channel',
      channelDescription: 'This channel is used for SmartHome notifications.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<int, bool> switchStates = {};
  bool isLightOn = false;
  String _weather = 'Yükleniyor...';
  List<List> room1 = [
    ['arac', 'Garaj Kapısı', 1],
    ['kapı', 'Ev Kapısı', 2],
    ['gaz', 'Gaz Uyarısı', 3],
    ['yangın', 'Ateş Uyarısı', 4],
    ['hırsız', 'Güvenlik', 5],
    ['gece', 'Gece Ayarı', 6],
  ];
  List<List> room2 = [
    ['lamp', 'Işık', 7],
    ['fan', 'Klima', 8],
    ['tv', 'TV', 9],
    ['speaker', 'Hoparlör', 10],
    ['window', 'Pencere', 11],
  ];
  List<List> room3 = [
    ['lamp', 'Işık', 12],
    ['window', 'Pencere', 13],
  ];
  List<List> room4 = [
    ['lamp', 'Işık', 14],
  ];
  List<List> room5 = [
    ['lamp', 'Işık', 15],
  ];
  List<List> room6 = [
    ['sulama', 'Sulama Ayarı', 16],
  ];

  Timer? timer;
  Timer? timerTimp;
  Timer? timerStatusServer;
  int roomNumber = 1;
  int statusServerbool = -11;
  String timp = '0';
  String ntimp = '0';

  @override
  void initState() {
    super.initState();

    listenToGasAlert();
    listenToAtesAlert();
    listenToGuvenlikAlert();

    _checkFirebaseSwitchStates(); // Uygulama başlatıldığında Firebase'den switch durumunu kontrol et
    _listenToFirebaseSwitchStates(); // Firebase'deki değişiklikleri dinle

    DatabaseReference sicaklikRef =
        FirebaseDatabase.instance.reference().child('sensor').child('sicaklik');

    sicaklikRef.onValue.listen((event) {
      var snapshot = event.snapshot;
      var sicaklikValue = snapshot.value;

      if (sicaklikValue != null) {
        double sicaklik;
        if (sicaklikValue is int) {
          // Gelen değer int ise, onu double'a çevirin
          sicaklik = sicaklikValue.toDouble();
        } else if (sicaklikValue is double) {
          // Gelen değer zaten double ise, doğrudan kullanabilirsiniz
          sicaklik = sicaklikValue;
        } else {
          // Diğer tüm durumlarda, sıcaklık değerini varsayılan olarak 0 olarak ayarlayabilirsiniz veya uygun bir hata işlemi gerçekleştirebilirsiniz
          print('Sıcaklık değeri geçersiz: $sicaklikValue');
          return;
        }

        setState(() {
          timp = sicaklik.round().toString(); // Yuvarlama işlemi
        });
      } else {
        setState(() {
          timp =
              '0'; // Firebase'den sıcaklık değeri alınamadığında 0 olarak ayarla
        });
      }
    }, onError: (error) {
      // Hata durumunda işlemleri
      print('Sıcaklık değeri alınamadı: $error');
    });

    DatabaseReference nemRef =
        FirebaseDatabase.instance.reference().child('sensor').child('nem');

    nemRef.onValue.listen((event) {
      var snapshot = event.snapshot;
      var nemValue = snapshot.value;

      if (nemValue != null) {
        double nem;
        if (nemValue is int) {
          // Gelen değer int ise, onu double'a çevirin
          nem = nemValue.toDouble();
        } else if (nemValue is double) {
          // Gelen değer zaten double ise, doğrudan kullanabilirsiniz
          nem = nemValue;
        } else {
          // Diğer tüm durumlarda, sıcaklık değerini varsayılan olarak 0 olarak ayarlayabilirsiniz veya uygun bir hata işlemi gerçekleştirebilirsiniz
          print('nem değeri geçersiz: $nemValue');
          return;
        }

        setState(() {
          ntimp = nem.round().toString(); // Yuvarlama işlemi
        });
      } else {
        setState(() {
          ntimp =
              '0'; // Firebase'den sıcaklık değeri alınamadığında 0 olarak ayarla
        });
      }
    }, onError: (error) {
      // Hata durumunda işlemleri
      print('nem değeri alınamadı: $error');
    });

    setDateTime();
    setDateTime();
    Timer.periodic(Duration(seconds: 1), (Timer t) => setDateTime());

    // Açılış ekranında animasyon eklemek için
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Stack(
            children: [
              // Arka plan için Container
              Container(
                color: Color.fromARGB(
                    255, 57, 62, 70), // Arkaplan rengi ve opaklık
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
              // Ortadaki animasyon
              Center(
                child: Lottie.asset(
                  'assets/Animation.json', // Lottie animasyon dosyasının yolu
                  width: 200, // Genişlik ve yüksekliği ayarlayın
                  height: 200,
                  fit: BoxFit.cover, // İstenen uyarlama türünü seçin
                ),
              ),
            ],
          );
        },
      );

      // İşlem tamamlandığında animasyon'u kapatmak için
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pop(context); // Dialog'u kapat
      });
    });
    _checkLocationPermission();
  }

  void listenToGasAlert() {
    DatabaseReference gasAlertRef = FirebaseDatabase.instance
        .reference()
        .child('sensor')
        .child('gaz_uyari');

    gasAlertRef.onValue.listen((event) {
      // Verinin null kontrolü ve tür dönüşümü
      var value = event.snapshot.value;

      // Verinin null olup olmadığını ve bool türüne uygun olup olmadığını kontrol edin
      bool isGasAlert = false;
      if (value != null) {
        if (value is bool) {
          isGasAlert = value;
        } else if (value is int) {
          // Bazı durumlarda, veritabanındaki boolean değerler 0 veya 1 olarak saklanabilir
          isGasAlert = value == 1;
        } else if (value is String) {
          // Veritabanında 'true' veya 'false' olarak saklanmış olabilir
          isGasAlert = value.toLowerCase() == 'true';
        }
      }

      if (isGasAlert && (switchStates[3] ?? false)) {
        NotificationService.showNotification(
            "Gaz Uyarısı!", "Dikkat! Gaz sızıntısı tespit edildi!");
      }
    });
  }

  void listenToAtesAlert() {
    FirebaseDatabase.instance
        .reference()
        .child('sensor')
        .child('ates_uyari')
        .onValue
        .listen((event) {
      // Verinin null kontrolü ve tür dönüşümü
      var value = event.snapshot.value;

      // Verinin null olup olmadığını ve bool türüne uygun olup olmadığını kontrol edin
      bool isAtesAlert = false;
      if (value != null) {
        if (value is bool) {
          isAtesAlert = value;
        } else if (value is int) {
          // Bazı durumlarda, veritabanındaki boolean değerler 0 veya 1 olarak saklanabilir
          isAtesAlert = value == 1;
        } else if (value is String) {
          // Veritabanında 'true' veya 'false' olarak saklanmış olabilir
          isAtesAlert = value.toLowerCase() == 'true';
        }
      }

      if (isAtesAlert && (switchStates[4] ?? false)) {
        NotificationService.showNotification(
            "Ateş Uyarısı!", "Dikkat! Evinizde ateş tespit edildi!");
      }
    });
  }

  void listenToGuvenlikAlert() {
    FirebaseDatabase.instance
        .reference()
        .child('sensor')
        .child('guvenlik_uyari')
        .onValue
        .listen((event) {
      // Verinin null kontrolü ve tür dönüşümü
      var value = event.snapshot.value;

      // Verinin null olup olmadığını ve bool türüne uygun olup olmadığını kontrol edin
      bool isGuvenlikAlert = false;
      if (value != null) {
        if (value is bool) {
          isGuvenlikAlert = value;
        } else if (value is int) {
          // Bazı durumlarda, veritabanındaki boolean değerler 0 veya 1 olarak saklanabilir
          isGuvenlikAlert = value == 1;
        } else if (value is String) {
          // Veritabanında 'true' veya 'false' olarak saklanmış olabilir
          isGuvenlikAlert = value.toLowerCase() == 'true';
        }
      }

      if (isGuvenlikAlert && (switchStates[5] ?? false)) {
        NotificationService.showNotification(
            "Güvenlik Uyarısı!", "Dikkat! Evinizde hareket tespit edildi.");
      }
    });
  }

  void _checkFirebaseSwitchStates() {
    for (var room in [room1, room2, room3, room4, room5, room6]) {
      for (var device in room) {
        _checkFirebaseSwitchState(device[2]);
      }
    }
  }

  void _listenToFirebaseSwitchStates() {
    for (var room in [room1, room2, room3, room4, room5, room6]) {
      for (var device in room) {
        _listenToFirebaseSwitchState(device[2]);
      }
    }
  }

  void _checkFirebaseSwitchState(int pin) {
    DatabaseReference switchRef = FirebaseDatabase.instance
        .reference()
        .child('switches')
        .child(pin.toString());
    switchRef
        .once()
        .then((snapshot) {
          bool switchState = (snapshot.snapshot.value as Map)['state'];
          setState(() {
            switchStates[pin] = switchState;
          });
        } as FutureOr Function(DatabaseEvent value))
        .catchError((error) {
      // Hata durumunda işlemleri
      print('Firebase switch durumu alınamadı: $error');
    });
  }

  void _listenToFirebaseSwitchState(int pin) {
    DatabaseReference switchRef = FirebaseDatabase.instance
        .reference()
        .child('switches')
        .child(pin.toString());
    switchRef.onValue.listen((event) {
      bool switchState = (event.snapshot.value as Map)['state'];
      setState(() {
        // Firebase'den alınan switch durumunu kullanarak yerel durumu güncelle
        switchStates[pin] = switchState;
      });
    }, onError: (error) {
      // Hata durumunda işlemleri
      print('Firebase switch durumu alınamadı: $error');
    });
  }

  // Kullanıcının konum iznini kontrol etmek için metod
  void _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Konum izni verilmemişse, izin isteği gönder
      _requestLocationPermission();
    } else if (permission == LocationPermission.deniedForever) {
      // Kullanıcı kalıcı olarak izin vermeyi reddettiği için, kullanıcıyı ayarlara yönlendir
      // ve izni manuel olarak açmasını iste.
      print('Konum izni kalıcı olarak reddedildi.');
    } else {
      // Konum izni verildi, konumu alabiliriz.
      _getLocationAndWeather();
    }
  }

  // Kullanıcıdan konum izni istemek için metod
  void _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Kullanıcı tekrar izin vermeyi reddetti.
      print('Konum izni reddedildi.');
    } else if (permission == LocationPermission.deniedForever) {
      // Kullanıcı kalıcı olarak izin vermeyi reddettiği için, kullanıcıyı ayarlara yönlendir
      // ve izni manuel olarak açmasını iste.
      print('Konum izni kalıcı olarak reddedildi.');
    } else {
      // Kullanıcı izin verdi.
      // Şimdi konum verisini alabiliriz.
      _getLocationAndWeather();
    }
  }

  // Kullanıcının konumunu almak için metod
  void _getLocationAndWeather() async {
    try {
      // Mevcut konumu al
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Konumu aldıktan sonra hava durumu bilgisini al
      _getWeather(position.latitude, position.longitude);
    } catch (e) {
      print('Konum alınamadı: $e');
    }
  }

  // Hava durumu bilgilerini almak için metod
  void _getWeather(double latitude, double longitude) async {
    try {
      // OpenWeatherMap API anahtarı
      String apiKey = '17638793cdc00fc1f76b3732b11838c5';
      // API'den hava durumu verilerini almak için URL
      String apiUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';
      // HTTP GET isteği yaparak hava durumu verilerini al
      http.Response response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // JSON verisini çözümle
        Map<String, dynamic> weatherData = jsonDecode(response.body);

        // Hava durumu verilerinden sıcaklık bilgisini al
        double temperature = weatherData['main']['temp'];

        int roundedTemperature =
            temperature.round(); // En yakın tam sayıya yuvarlama

        setState(() {
          _weather = 'Yükleniyor...'; // Hava durumu bilgisini güncelle
          _weather =
              '$roundedTemperature °C'; // Yuvarlanmış sıcaklık değerini kullanarak hava durumu bilgisini güncelle // Hava durumu bilgisini güncelle
        });
      } else {
        // Sunucudan geçerli bir yanıt alınamadığında hatayı yazdır
        print('Hava durumu verileri alınamadı: ${response.statusCode}');
        print('Sunucu yanıtı: ${response.body}');
      }
    } catch (e) {
      // Hata durumunda hatayı yazdır
      print('Hata: $e');
      setState(() {
        _weather = 'Unknown'; // Hava durumu bilgisini güncelle
      });
    }
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // İzin kontrolü yapılır
    LocationPermission permission = await Geolocator.checkPermission();

    // İzin verilmediyse, kullanıcıdan izin talep edilir
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // İzin verilmediyse hata mesajı gösterilir
    if (permission == LocationPermission.denied) {
      print('Kullanıcı konum iznini reddetti.');
      return;
    }

    // İzin verildiyse, konum bilgisine erişim sağlanır
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Konum bilgisine erişim sağlayabilirsiniz
      // Bu noktada konum bilgisi alınabilir
    }
  }

  @override
  void dispose() {
    timer!.cancel();
    timerTimp!.cancel();
    timerStatusServer!.cancel();
    super.dispose();
  }

  String time = '';
  String date = '';
  String nameDay = '';

  setDateTime() {
    DateTime now = DateTime.now().toUtc().add(Duration(hours: 3));
    setState(() {
      time = DateFormat('Hms').format(now);
      date = DateFormat('dd/MM/yyyy').format(now);
      nameDay = DateFormat('EEEE', 'tr_TR').format(now); // Türkçe gün ismi
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: Color.fromARGB(255, 57, 62, 70),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 0, 173, 181),
                        borderRadius: BorderRadius.circular(16)),
                    width: MediaQuery.of(context).size.width,
                    height: 110,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Image.asset('assets/sun.png'),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Hava Durumu',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 17),
                            ),
                            10.ph,
                            Text(
                              _weather,
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22),
                            )
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              time,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w100),
                            ),
                            Text(
                              nameDay,
                            ),
                            Text(
                              date,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  10.ph,
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 0, 173, 181),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Ev Sıcaklığı',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 10),
                            Image.asset('assets/timp.png'),
                            SizedBox(width: 5),
                            Text(
                              // ignore: unnecessary_null_comparison
                              timp == null ? '0 °C' : '$timp °C',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 255, 255,
                                      255)), // metin boyutunu ayarla
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Ev Nem Oranı',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 10),
                            Image.asset('assets/timp.png'),
                            SizedBox(width: 5),
                            Text(
                              // ignore: unnecessary_null_comparison
                              ntimp == null ? '0 %' : '$ntimp %',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white), // metin boyutunu ayarla
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  10.ph,
                  Expanded(
                    flex: 10,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 3 / 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: roomNumber == 1
                          ? room1.length
                          : roomNumber == 2
                              ? room2.length
                              : roomNumber == 3
                                  ? room3.length
                                  : roomNumber == 4
                                      ? room4.length
                                      : roomNumber == 5
                                          ? room5.length
                                          : room6.length,
                      itemBuilder: (context, index) {
                        var data = roomNumber == 1
                            ? room1
                            : roomNumber == 2
                                ? room2
                                : roomNumber == 3
                                    ? room3
                                    : roomNumber == 4
                                        ? room4
                                        : roomNumber == 5
                                            ? room5
                                            : room6;

                        return card(
                          data[index][2],
                          data[index][0],
                          data[index][1],
                        );
                      },
                    ),
                  ),
                  104.ph,
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 113,
                color: Color.fromARGB(255, 57, 62, 70),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    50.pw,
                    buttonroom(
                      'Ev Ayarları',
                      () {
                        setState(() {
                          if (roomNumber != 1) {
                            roomNumber = 1;
                          }
                        });
                      },
                      'assets/home.png', // Oturma Odası için resim yolu
                      active: roomNumber == 1,
                    ),
                    50.pw,
                    buttonroom(
                      'Oturma Odası',
                      () {
                        setState(() {
                          if (roomNumber != 2) {
                            roomNumber = 2;
                          }
                        });
                      },
                      'assets/oturma.png', // Oturma Odası için resim yolu
                      active: roomNumber == 2,
                    ),
                    50.pw,
                    buttonroom(
                      'Mutfak',
                      () {
                        setState(() {
                          if (roomNumber != 3) {
                            roomNumber = 3;
                          }
                        });
                      },
                      'assets/mutfak.png', // Oturma Odası için resim yolu
                      active: roomNumber == 3,
                    ),
                    50.pw,
                    buttonroom(
                      'Yatak Odası',
                      () {
                        setState(() {
                          if (roomNumber != 4) {
                            roomNumber = 4;
                          }
                        });
                      },
                      'assets/yatak.png', // Oturma Odası için resim yolu
                      active: roomNumber == 4,
                    ),
                    50.pw,
                    buttonroom(
                      'Banyo / WC',
                      () {
                        setState(() {
                          if (roomNumber != 5) {
                            roomNumber = 5;
                          }
                        });
                      },
                      'assets/wc.png', // Oturma Odası için resim yolu
                      active: roomNumber == 5,
                    ),
                    50.pw,
                    buttonroom(
                      'Arka Bahçe',
                      () {
                        setState(() {
                          if (roomNumber != 6) {
                            roomNumber = 6;
                          }
                        });
                      },
                      'assets/bahce.png', // Oturma Odası için resim yolu
                      active: roomNumber == 6,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width *
                  0.01, // Ekranın sol kenarından %5 uzaklıkta
              top: 0.85 *
                  MediaQuery.of(context)
                      .size
                      .height, // Ekranın yüksekliğinin %45'inde
              child: Image.asset('assets/left.png'),
            ),
            Positioned(
              right: MediaQuery.of(context).size.width *
                  0.01, // Ekranın sağ kenarından %5 uzaklıkta
              top: 0.85 *
                  MediaQuery.of(context)
                      .size
                      .height, // Ekranın yüksekliğinin %45'inde
              child: Image.asset('assets/right.png'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buttonroom(String title, Function() onTap, String imagePath,
      {bool active = false}) {
    return Container(
      padding: const EdgeInsets.only(right: 50),
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: active ? 1 : 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(imagePath), // Odaya ait resim burada kullanılacak
              Text(
                title,
                style: TextStyle(
                  color:
                      active ? Color.fromARGB(255, 0, 173, 181) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Map type_dvice = {
    'sulama': [
      Color.fromARGB(255, 255, 255, 255),
      'Sulama Ayarı',
      'sulama.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'gece': [
      Color.fromARGB(255, 255, 255, 255),
      'Gece Ayarı',
      'gece.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'arac': [
      Color.fromARGB(255, 255, 255, 255),
      'Garaj Kapısı',
      'arac.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'kapı': [
      Color.fromARGB(255, 255, 255, 255),
      'Ev Kapısı',
      'room.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'hırsız': [
      Color.fromARGB(255, 255, 255, 255),
      'Güvenlik',
      'hırsız.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'yangın': [
      Color.fromARGB(255, 255, 255, 255),
      'Ateş Uyarısı',
      'yangın.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'gaz': [
      Color.fromARGB(255, 255, 255, 255),
      'GAZ Uyarısı',
      'gaz.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'fan': [
      Color.fromARGB(255, 255, 255, 255),
      'Fan',
      'fan.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'lamp': [
      Color.fromARGB(255, 255, 255, 255),
      'Bed Lamp',
      'lamp.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'speaker': [
      Color.fromARGB(255, 255, 255, 255),
      'Speaker',
      'speaker.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'tv': [
      Color.fromARGB(255, 255, 255, 255),
      'TV',
      'tv.png',
      Color.fromARGB(255, 0, 0, 0),
    ],
    'window': [
      Color.fromARGB(255, 255, 255, 255),
      'Window',
      'window.png',
      Color.fromARGB(255, 0, 0, 0),
    ]
  };
  Widget card(int pin, String type, String title) {
    bool isSwitchActive = switchStates[pin] ?? false;
    Color iconColor = isSwitchActive
        ? Colors.white
        : Colors.black; // Switch durumuna göre ikon rengini belirle

    Color textColor = isSwitchActive
        ? Colors.white
        : Colors.black; // Switch durumuna göre metin rengini belirle

    return InkWell(
      child: Padding(
        padding: EdgeInsets.all(1.0), // Dilediğiniz boşluk miktarını belirleyin
        child: Container(
          width: 163.5,
          height: 163.5,
          decoration: BoxDecoration(
            color: isSwitchActive
                ? Color.fromARGB(225, 24, 30, 38)
                : Color.fromARGB(255, 238, 238, 238),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/' + type_dvice[type][2],
                color: iconColor,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 25.0),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    activeColor: Color.fromARGB(255, 1, 206, 216),
                    value: isSwitchActive,
                    onChanged: (value) {
                      setState(() {
                        switchStates[pin] = value;
                        updateSwitchState(pin, value);
                      });
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void updateSwitchState(int pin, bool newState) {
    DatabaseReference dbRef = FirebaseDatabase.instance.reference();
    dbRef.child('switches').child(pin.toString()).set({'state': newState});
  }
}

extension EmptyPadding on num {
  SizedBox get ph => SizedBox(height: toDouble());
  SizedBox get pw => SizedBox(width: toDouble());
}
