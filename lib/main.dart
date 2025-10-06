import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(CinemaApp());
}

class CinemaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rạp Chiếu Phim',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.light,
      ),
      home: MainScreen(),
    );
  }
}

// Model cho Phim
class Movie {
  final int id;
  final String title;
  final String genre;
  final int duration;
  final String poster;
  final String description;
  final List<Showtime> showtimes;

  Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.duration,
    required this.poster,
    required this.description,
    required this.showtimes,
  });
}

// Model cho Suất chiếu
class Showtime {
  final String time;
  final String room;
  final double price;

  Showtime({
    required this.time,
    required this.room,
    required this.price,
  });
}

// Model cho Vé
class Ticket {
  final int? id;
  final String movieTitle;
  final String showtime;
  final String seat;
  final double price;
  final String status; // đang giữ chỗ, đã thanh toán, đã xem, đã hủy
  final DateTime bookingDate;

  Ticket({
    this.id,
    required this.movieTitle,
    required this.showtime,
    required this.seat,
    required this.price,
    required this.status,
    required this.bookingDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'movieTitle': movieTitle,
      'showtime': showtime,
      'seat': seat,
      'price': price,
      'status': status,
      'bookingDate': bookingDate.toIso8601String(),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      movieTitle: map['movieTitle'],
      showtime: map['showtime'],
      seat: map['seat'],
      price: map['price'],
      status: map['status'],
      bookingDate: DateTime.parse(map['bookingDate']),
    );
  }
}

// Database Helper
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cinema.db');
    return await openDatabase(
      path,
      version: 2, // tăng version khi thay đổi schema
      onCreate: (db, version) async {
        // Bảng vé
        await db.execute(
          'CREATE TABLE tickets('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'movieTitle TEXT, showtime TEXT, seat TEXT, '
          'price REAL, status TEXT, bookingDate TEXT)',
        );

        // Bảng phim
        await db.execute(
          'CREATE TABLE movies('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'title TEXT, genre TEXT, duration INTEGER, '
          'poster TEXT, description TEXT)',
        );

        // Bảng suất chiếu
        await db.execute(
          'CREATE TABLE showtimes('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'movieId INTEGER, time TEXT, room TEXT, price REAL, '
          'FOREIGN KEY(movieId) REFERENCES movies(id) ON DELETE CASCADE)',
        );
      },
      // Nếu muốn nâng cấp DB
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE movies('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'title TEXT, genre TEXT, duration INTEGER, '
            'poster TEXT, description TEXT)',
          );
          await db.execute(
            'CREATE TABLE showtimes('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'movieId INTEGER, time TEXT, room TEXT, price REAL, '
            'FOREIGN KEY(movieId) REFERENCES movies(id) ON DELETE CASCADE)',
          );
        }
      },
    );
  }

    // Thêm phim
  Future<int> insertMovie(Movie movie) async {
    final db = await database;
    final movieId = await db.insert('movies', {
      'title': movie.title,
      'genre': movie.genre,
      'duration': movie.duration,
      'poster': movie.poster,
      'description': movie.description,
    });

    // Thêm suất chiếu
    for (var s in movie.showtimes) {
      await db.insert('showtimes', {
        'movieId': movieId,
        'time': s.time,
        'room': s.room,
        'price': s.price,
      });
    }

    return movieId;
  }

  // Lấy toàn bộ phim
  Future<List<Movie>> getMovies() async {
    final db = await database;
    final moviesMap = await db.query('movies');

    List<Movie> movies = [];
    for (var m in moviesMap) {
      final showtimesMap = await db.query(
        'showtimes',
        where: 'movieId = ?',
        whereArgs: [m['id']],
      );

      List<Showtime> showtimes = showtimesMap.map((s) {
        return Showtime(
          time: s['time'] as String,
          room: s['room'] as String,
          price: (s['price'] as num).toDouble(),
        );
      }).toList();

      movies.add(
        Movie(
          id: m['id'] as int,
          title: m['title'] as String,
          genre: m['genre'] as String,
          duration: m['duration'] as int,
          poster: m['poster'] as String,
          description: m['description'] as String,
          showtimes: showtimes,
        ),
      );
    }
    return movies;
  }

  // Xoá phim
  Future<int> deleteMovie(int id) async {
    final db = await database;
    return await db.delete('movies', where: 'id = ?', whereArgs: [id]);
  }

  // Cập nhật phim
  Future<int> updateMovie(Movie movie) async {
    final db = await database;
    await db.update(
      'movies',
      {
        'title': movie.title,
        'genre': movie.genre,
        'duration': movie.duration,
        'poster': movie.poster,
        'description': movie.description,
      },
      where: 'id = ?',
      whereArgs: [movie.id],
    );

    // Xóa suất cũ và thêm lại
    await db.delete('showtimes', where: 'movieId = ?', whereArgs: [movie.id]);
    for (var s in movie.showtimes) {
      await db.insert('showtimes', {
        'movieId': movie.id,
        'time': s.time,
        'room': s.room,
        'price': s.price,
      });
    }

    return movie.id;
  }

  Future<int> insertTicket(Ticket ticket) async {
    Database db = await database;
    return await db.insert('tickets', ticket.toMap());
  }

  Future<List<Ticket>> getTickets() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tickets', orderBy: 'bookingDate DESC');
    return List.generate(maps.length, (i) => Ticket.fromMap(maps[i]));
  }

  Future<int> updateTicket(Ticket ticket) async {
    Database db = await database;
    return await db.update(
      'tickets',
      ticket.toMap(),
      where: 'id = ?',
      whereArgs: [ticket.id],
    );
  }

  Future<int> deleteTicket(int id) async {
    Database db = await database;
    return await db.delete(
      'tickets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<void> updateAllPosters() async {
    final db = await database;

    // Map phimId → poster mới
    final newPosters = {
      1: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQyigtEP7shCN1Lfx6SLMc6sa_6A444sEziOQ&s", // Frozen 2
      2: "https://m.media-amazon.com/images/M/MV5BMjMxNjY2MDU1OV5BMl5BanBnXkFtZTgwNzY1MTUwNTM@._V1_.jpg", // Avengers
      3: "https://upload.wikimedia.org/wikipedia/en/e/e1/Spider-Man_PS4_cover.jpg", // Spider-Man
      4: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRxkAp-UQJV3AeqakST2qqQGTyIRJs98CHLwQ&s", // Black Panther
      5: "https://m.media-amazon.com/images/M/MV5BNjgwNzAzNjk1Nl5BMl5BanBnXkFtZTgwMzQ2NjI1OTE@._V1_FMjpg_UX1000_.jpg", // Doctor Strange
      6: "https://upload.wikimedia.org/wikipedia/en/4/4e/Captain_Marvel_%28film%29_poster.jpg", // Captain Marvel
      7: "https://m.media-amazon.com/images/M/MV5BOTJhOTMxMmItZmE0Ny00MDc3LWEzOGEtOGFkMzY4MWYyZDQ0XkEyXkFqcGc@._V1_FMjpg_UX1000_.jpg", // Guardians of the Galaxy
      8: "https://m.media-amazon.com/images/M/MV5BMTczNTI2ODUwOF5BMl5BanBnXkFtZTcwMTU0NTIzMw@@._V1_FMjpg_UX1000_.jpg", // Iron Man
      9: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRP3SSGWeuoxe6hrm8h0Ok8F9Vv0NTz0XXLZA&s", // Thor: Ragnarok
      10: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRjJeJxCc1GgLtvHYfjp66IolA612jS3JSXZQ&s", // The Lion King
    };

    for (var entry in newPosters.entries) {
      await db.update(
        'movies',
        {'poster': entry.value},
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }

    print("✅ Đã cập nhật poster cho 10 phim");
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),   // Trang phim
    HistoryScreen() // Trang lịch sử
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _selectedIndex == 0 ? 'Phim Đang Chiếu' : 'Lịch Sử Đặt Vé',
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: "Phim",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Lịch sử",
          ),
        ],
      ),
    );
  }
}


// Màn hình chính
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> movies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final dbMovies = await DatabaseHelper().getMovies();
    await DatabaseHelper().updateAllPosters();

    if (dbMovies.isEmpty) {
      for (var m in sampleMovies) {
        await DatabaseHelper().insertMovie(m);
      }
      final newMovies = await DatabaseHelper().getMovies();
      setState(() => movies = newMovies);
    } else {
      setState(() => movies = dbMovies);
    }
  }

  void printAllMovies() async {
    final db = await DatabaseHelper().database;
    final data = await db.query('movies');
    print("📦 Danh sách phim trong DB:");
    for (var row in data) {
      print(row);
    }
  }

  final List<Movie> sampleMovies = [
    Movie(
      id: 1,
      title: 'Frozen 2',
      genre: 'Hoạt hình, Phiêu lưu',
      duration: 103,
      poster: '🎬',
      description: 'Elsa và Anna tiếp tục cuộc phiêu lưu mới để khám phá nguồn gốc sức mạnh của Elsa.',
      showtimes: [
        Showtime(time: '19:30', room: 'IMAX', price: 85000),
        Showtime(time: '21:00', room: 'Phòng 2', price: 70000),
      ],
    ),
    Movie(
      id: 2,
      title: 'Avengers',
      genre: 'Sci-fi, Hành động',
      duration: 180,
      poster: '🦸',
      description: 'Biệt đội siêu anh hùng hội tụ để chống lại kẻ thù mạnh nhất.',
      showtimes: [
        Showtime(time: '19:00', room: 'Phòng 3', price: 70000),
        Showtime(time: '22:00', room: 'Phòng 1', price: 75000),
      ],
    ),
    Movie(
      id: 3,
      title: 'Spider-Man',
      genre: 'Hành động, Phiêu lưu',
      duration: 148,
      poster: '🕷️',
      description: 'Peter Parker đối mặt với những thử thách mới trong vai trò người nhện.',
      showtimes: [
        Showtime(time: '18:00', room: 'Phòng 4', price: 65000),
        Showtime(time: '20:30', room: 'IMAX', price: 90000),
      ],
    ),
    Movie(
      id: 4,
      title: 'Black Panther',
      genre: 'Hành động, Viễn tưởng',
      duration: 134,
      poster: '🐆',
      description: 'T’Challa trở về Wakanda để trở thành nhà vua và đối mặt với kẻ thù nguy hiểm.',
      showtimes: [
        Showtime(time: '17:30', room: 'Phòng 5', price: 75000),
        Showtime(time: '20:00', room: 'IMAX', price: 95000),
      ],
    ),
    Movie(
      id: 5,
      title: 'Doctor Strange',
      genre: 'Hành động, Kỳ ảo',
      duration: 126,
      poster: '🌀',
      description: 'Stephen Strange tìm đến phép thuật để cứu lấy bản thân và thế giới.',
      showtimes: [
        Showtime(time: '18:15', room: 'Phòng 2', price: 70000),
        Showtime(time: '21:00', room: 'Phòng 3', price: 80000),
      ],
    ),
    Movie(
      id: 6,
      title: 'Captain Marvel',
      genre: 'Hành động, Viễn tưởng',
      duration: 124,
      poster: '✨',
      description: 'Carol Danvers trở thành một trong những anh hùng mạnh nhất vũ trụ.',
      showtimes: [
        Showtime(time: '19:00', room: 'Phòng 1', price: 70000),
        Showtime(time: '21:30', room: 'IMAX', price: 95000),
      ],
    ),
    Movie(
      id: 7,
      title: 'Guardians of the Galaxy',
      genre: 'Phiêu lưu, Hài hước',
      duration: 121,
      poster: '🚀',
      description: 'Một nhóm dị nhân vũ trụ hợp sức để cứu lấy thiên hà khỏi kẻ xấu.',
      showtimes: [
        Showtime(time: '18:00', room: 'Phòng 6', price: 70000),
        Showtime(time: '20:45', room: 'Phòng 4', price: 80000),
      ],
    ),
    Movie(
      id: 8,
      title: 'Iron Man',
      genre: 'Hành động, Khoa học viễn tưởng',
      duration: 126,
      poster: '🤖',
      description: 'Tony Stark trở thành siêu anh hùng Iron Man sau khi chế tạo bộ giáp sắt.',
      showtimes: [
        Showtime(time: '17:00', room: 'Phòng 3', price: 65000),
        Showtime(time: '19:45', room: 'IMAX', price: 90000),
      ],
    ),
    Movie(
      id: 9,
      title: 'Thor: Ragnarok',
      genre: 'Hành động, Phiêu lưu',
      duration: 130,
      poster: '⚡',
      description: 'Thor phải cứu Asgard khỏi sự hủy diệt của nữ thần Hela.',
      showtimes: [
        Showtime(time: '16:30', room: 'Phòng 2', price: 65000),
        Showtime(time: '20:00', room: 'Phòng 5', price: 80000),
      ],
    ),
    Movie(
      id: 10,
      title: 'The Lion King',
      genre: 'Hoạt hình, Phiêu lưu',
      duration: 118,
      poster: '🦁',
      description: 'Câu chuyện về Simba trên hành trình trở thành vua của xứ sở Pride Lands.',
      showtimes: [
        Showtime(time: '15:30', room: 'Phòng 1', price: 60000),
        Showtime(time: '18:30', room: 'Phòng 4', price: 70000),
      ],
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];

        return Card(
          margin: EdgeInsets.all(10),
          child: SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poster
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: Image.network(
                      movie.poster,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Nội dung
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          movie.title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text('Suất chiếu: ${movie.showtimes[0].time}, ${movie.showtimes[0].room}'),
                      ],
                    ),
                  ),
                ),
                // Nút Chi tiết
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(movie: movie),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'Chi tiết',
                    style: TextStyle(fontSize: 12),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// Màn hình chi tiết phim
class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final Ticket? ticketToChange;

  MovieDetailScreen({required this.movie, this.ticketToChange});

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  String? selectedShowtime;
  String? selectedRoom;
  double? selectedPrice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(widget.movie.poster, width: 200, height: 300)
            ),
            SizedBox(height: 20),
            Text(
              'Tên: ${widget.movie.title}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Thể loại: ${widget.movie.genre}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Thời lượng: ${widget.movie.duration} phút',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Suất chiếu:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...widget.movie.showtimes.map((showtime) {
              return RadioListTile<String>(
                title: Text('${showtime.time} - ${showtime.room}'),
                subtitle: Text('Giá vé: ${showtime.price.toStringAsFixed(0)} VNĐ'),
                value: '${showtime.time}|${showtime.room}|${showtime.price}',
                groupValue: selectedShowtime != null
                    ? '$selectedShowtime|$selectedRoom|$selectedPrice'
                    : null,
                onChanged: (value) {
                  setState(() {
                    selectedShowtime = showtime.time;
                    selectedRoom = showtime.room;
                    selectedPrice = showtime.price;
                  });
                },
              );
            }).toList(),
            SizedBox(height: 20),
            Text(
              'Mô tả:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.movie.description,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: Text('Quay lại'),
                ),
                ElevatedButton(
                  onPressed: selectedShowtime != null
                      ? () {
                          _bookTicket(context);
                        }
                      : null,
                  child: Text(widget.ticketToChange != null ? 'Đổi suất' : 'Đặt vé'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bookTicket(BuildContext context) async {
    if (selectedShowtime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn suất chiếu')),
      );
      return;
    }

    // Nếu đang đổi suất chiếu
    if (widget.ticketToChange != null) {
      final updatedTicket = Ticket(
        id: widget.ticketToChange!.id,
        movieTitle: widget.movie.title,
        showtime: '$selectedShowtime - $selectedRoom',
        seat: widget.ticketToChange!.seat,
        price: selectedPrice!,
        status: 'đang giữ chỗ',
        bookingDate: DateTime.now(),
      );

      await DatabaseHelper().updateTicket(updatedTicket);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đổi suất chiếu thành công!')),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    // Đặt vé mới
    showDialog(
      context: context,
      builder: (context) => BookingDialog(
        movieTitle: widget.movie.title,
        showtime: '$selectedShowtime - $selectedRoom',
        price: selectedPrice!,
      ),
    );
  }
}

// Dialog đặt vé
class BookingDialog extends StatefulWidget {
  final String movieTitle;
  final String showtime;
  final double price;

  BookingDialog({
    required this.movieTitle,
    required this.showtime,
    required this.price,
  });

  @override
  _BookingDialogState createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final TextEditingController seatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Đặt vé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Phim: ${widget.movieTitle}'),
          Text('Suất: ${widget.showtime}'),
          Text('Giá: ${widget.price.toStringAsFixed(0)} VNĐ'),
          SizedBox(height: 20),
          TextField(
            controller: seatController,
            decoration: InputDecoration(
              labelText: 'Số ghế (VD: A1, B5)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (seatController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Vui lòng nhập số ghế')),
              );
              return;
            }

            final ticket = Ticket(
              movieTitle: widget.movieTitle,
              showtime: widget.showtime,
              seat: seatController.text,
              price: widget.price,
              status: 'đang giữ chỗ',
              bookingDate: DateTime.now(),
            );

            await DatabaseHelper().insertTicket(ticket);

            Navigator.pop(context);
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đặt vé thành công!')),
            );
          },
          child: Text('Xác nhận'),
        ),
      ],
    );
  }
}

// Màn hình lịch sử vé
class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Ticket> tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final loadedTickets = await DatabaseHelper().getTickets();
    setState(() {
      tickets = loadedTickets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tickets.isEmpty
          ? Center(child: Text('Chưa có vé nào'))
          : ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(
                      ticket.movieTitle,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Suất: ${ticket.showtime}'),
                        Text('Ghế: ${ticket.seat}'),
                        Text('Giá: ${ticket.price.toStringAsFixed(0)} VNĐ'),
                        Text(
                          'Trạng thái: ${ticket.status}',
                          style: TextStyle(
                            color: _getStatusColor(ticket.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'change') {
                          _changeShowtime(context, ticket);
                        } else if (value == 'status') {
                          _changeStatus(context, ticket);
                        } else if (value == 'cancel') {
                          await _cancelTicket(context, ticket);
                        }
                      },
                      itemBuilder: (context) => [
                        if (ticket.status != 'đã hủy' && ticket.status != 'đã xem')
                          PopupMenuItem(
                            value: 'change',
                            child: Text('Đổi suất chiếu'),
                          ),
                        if (ticket.status != 'đã hủy' && ticket.status != 'đã xem')
                          PopupMenuItem(
                            value: 'status',
                            child: Text('Đổi trạng thái'),
                          ),
                        if (ticket.status == 'đang giữ chỗ')
                          PopupMenuItem(
                            value: 'cancel',
                            child: Text('Hủy vé'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'đang giữ chỗ':
        return Colors.orange;
      case 'đã thanh toán':
        return Colors.green;
      case 'đã xem':
        return Colors.blue;
      case 'đã hủy':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  void _changeShowtime(BuildContext context, Ticket ticket) async {
    // Lấy toàn bộ phim từ DB
    final movies = await DatabaseHelper().getMovies();

    if (movies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa có dữ liệu phim trong hệ thống')),
      );
      return;
    }

    // Tìm phim có cùng title với vé
    final movie = movies.firstWhere(
      (m) => m.title == ticket.movieTitle,
      orElse: () => movies[0], // fallback
    );

    // Mở MovieDetailScreen với ticketToChange
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(
          movie: movie,
          ticketToChange: ticket,
        ),
      ),
    ).then((_) => _loadTickets()); // refresh lại danh sách vé sau khi đổi
  }

  void _changeStatus(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi trạng thái vé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Đang giữ chỗ'),
              onTap: () => _updateStatus(context, ticket, 'đang giữ chỗ'),
            ),
            ListTile(
              title: Text('Đã thanh toán'),
              onTap: () => _updateStatus(context, ticket, 'đã thanh toán'),
            ),
            ListTile(
              title: Text('Đã xem'),
              onTap: () => _updateStatus(context, ticket, 'đã xem'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, Ticket ticket, String newStatus) async {
    final updatedTicket = Ticket(
      id: ticket.id,
      movieTitle: ticket.movieTitle,
      showtime: ticket.showtime,
      seat: ticket.seat,
      price: ticket.price,
      status: newStatus,
      bookingDate: ticket.bookingDate,
    );

    await DatabaseHelper().updateTicket(updatedTicket);
    Navigator.pop(context);
    _loadTickets();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật trạng thái thành $newStatus')),
    );
  }

  Future<void> _cancelTicket(BuildContext context, Ticket ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận hủy vé'),
        content: Text('Bạn có chắc chắn muốn hủy vé này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Có'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedTicket = Ticket(
        id: ticket.id,
        movieTitle: ticket.movieTitle,
        showtime: ticket.showtime,
        seat: ticket.seat,
        price: ticket.price,
        status: 'đã hủy',
        bookingDate: ticket.bookingDate,
      );

      await DatabaseHelper().updateTicket(updatedTicket);
      _loadTickets();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hủy vé thành công')),
      );
    }
  }
}