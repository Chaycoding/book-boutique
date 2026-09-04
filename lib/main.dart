import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'book.dart'; 
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
late Isar isar;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  
  isar = await Isar.open(
    [SavedBookSchema],
    directory: dir.path,
  );
  await dotenv.load(fileName: '.env');
  runApp(const BookBoutiqueApp());
}


class AppColors {
  static const primary = Color(0xFF9333EA);      
  static const primaryLight = Color(0xFFA855F7); 
  static const primaryPale = Color(0xFFF3E8FF);  
  static const surface = Color(0xFFFAF5FF);      
  static const textDark = Color(0xFF6B21A8);
  static const textMuted = Color(0xFFA855F7);
  static const danger = Color(0xFFF43F5E);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}
class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

Widget shimmerBox() {
  return Shimmer.fromColors(
    baseColor: AppColors.primaryPale,
    highlightColor: Colors.white,
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  );
}

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.manropeTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: baseTextTheme.copyWith(
      headlineSmall: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
      titleMedium: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMuted),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, height: 1.5, color: AppColors.textDark),
      labelSmall: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryPale,
      selectedColor: AppColors.primaryLight,
      labelStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

Route _premiumRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
      return FadeTransition(opacity: fade, child: ScaleTransition(scale: scale, child: child));
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class BookBoutiqueApp extends StatelessWidget {
  const BookBoutiqueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Boutique',
      theme: buildAppTheme(),
      home: const MainNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  @override
  _MainNavigatorState createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  Key _homeKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          ),
        ),
        child: Stack(
          children: [
            Offstage(offstage: _selectedIndex != 0, child: HomeScreen(key: _homeKey)),
            Offstage(offstage: _selectedIndex != 1, child: const BookSearchScreen()),
            if (_selectedIndex == 2) const BookshelfScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) _homeKey = UniqueKey(); 
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF3E8FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded, color: AppColors.primaryLight),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded, color: Color(0xFFA855F7)),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_rounded, color: Color(0xFFA855F7)),
            label: 'My Books',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  // This fetches the live count of  saved books
 Future<Map<String, int>> _getLibraryStats() async {
    final ownCount = await isar.savedBooks.filter().categoryEqualTo('Own It').count();
    final wantCount = await isar.savedBooks.filter().categoryEqualTo('Want It').count();
    
    return {
      'own': ownCount,
      'want': wantCount,
    };
  }
  
Future<List<SavedBook>> _getReadingNow() async {
  return await isar.savedBooks.filter()
      .categoryEqualTo('Own It')
      .and()
      .statusEqualTo('Reading')
      .findAll();
}
Future<List<SavedBook>> _getToBeRead() async {
  return await isar.savedBooks.filter()
      .categoryEqualTo('Own It')
      .and()
      .statusEqualTo('Not Started')
      .findAll();
}

Widget _buildBookShelf(BuildContext context, String title, Future<List<SavedBook>> future) {
  return FutureBuilder<List<SavedBook>>(
    future: future,
    builder: (context, snapshot) {
      final books = snapshot.data ?? [];
      if (books.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, _premiumRoute(BookDetailScreen(book: book)))
    .then((_) => setState(() {})),
                    child: SizedBox(
                      width: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Hero(
                          tag: 'book-cover-${book.id}',
                          child: book.coverUrl.isNotEmpty
                              ? CachedNetworkImage(imageUrl: book.coverUrl, fit: BoxFit.cover, height: 190, width: 110, memCacheWidth: 200)
                              : Container(height: 190, width: 110, color: Colors.white, child: const Icon(Icons.book, size: 40, color: Color(0xFFE9D5FF))),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
  // A sleek, premium banner for curated genres
 Widget _buildCuratedBanner(BuildContext context, String title, String subtitle, IconData icon, List<Color> gradient, String query) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: [
        BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
      ]
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          // Navigate to a new screen to show the results for this category
          Navigator.push(
  context,
  _premiumRoute(CategorySearchScreen(categoryTitle: title, query: query)),
 );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Afternoon ✨', style: Theme.of(context).textTheme.titleMedium),
const SizedBox(height: 8),
Text('Welcome to your\nBook Boutique.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 34, height: 1.1)),
             
              const SizedBox(height: 32),
              
              // Quote Card
                            // Reading Goal
              const _ReadingGoalCard(),
              const SizedBox(height: 32),
              
              // Live Library Stats Dashboard
              const Text('Your Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF9333EA))),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, int>>(
                future: _getLibraryStats(),
                builder: (context, snapshot) {
                  final ownCount = snapshot.data?['own'] ?? 0;
                  final wantCount = snapshot.data?['want'] ?? 0;
                  
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.bookmark_added_rounded, color: Color(0xFF7E22CE)),
                              const SizedBox(height: 12),
                              Text('$ownCount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF9333EA))),
                              const Text('Books Owned', style: TextStyle(color: Color(0xFFA855F7), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg),boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E)),
                              const SizedBox(height: 12),
                              Text('$wantCount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF9333EA))),
                              const Text('Wishlist', style: TextStyle(color: Color(0xFFA855F7), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),

                            const SizedBox(height: 32),

              _buildBookShelf(context, 'Reading Right Now 📖', _getReadingNow()),
              _buildBookShelf(context, 'To Be Read 📚', _getToBeRead()),

              // Curated Showcase Banners
             

              // Curated Showcase Banners
              const Text('Curated For You', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF9333EA))),
              const SizedBox(height: 16),
              
              _buildCuratedBanner(
  context,
  'Trending Fiction', 
  'Bestselling novels and stories.', 
  Icons.auto_stories_rounded,  
  [const Color(0xFFE11D48), const Color(0xFFFB7185)],
  'subject:fiction'
),
_buildCuratedBanner(
  context,
  'Science & Technology', 
  'Discoveries and innovations.', 
  Icons.science_rounded,  
  [const Color(0xFFE11D48), const Color(0xFFFB7185)],
  'subject:science'
),
_buildCuratedBanner(
  context,
  'Self-Improvement', 
  'Habits, focus, and growth.', 
  Icons.trending_up_rounded, 
  [const Color(0xFFE11D48), const Color(0xFFFB7185)],
  'subject:self-help'
),
              const SizedBox(height: 20),
            ],
          )
        )
      )
    );
  }
}
class _ReadingGoalCard extends StatefulWidget {
  const _ReadingGoalCard();

  @override
  State<_ReadingGoalCard> createState() => _ReadingGoalCardState();
}

class _ReadingGoalCardState extends State<_ReadingGoalCard> {
  int _goal = 12;
  int _finished = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt('reading_goal') ?? 12;
    final finished = await isar.savedBooks.filter().statusEqualTo('Finished').count();
    if (mounted) setState(() { _goal = goal; _finished = finished; _loading = false; });
  }

  Future<void> _editGoal() async {
    final controller = TextEditingController(text: _goal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Reading Goal'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Books to read this year')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reading_goal', result);
      setState(() => _goal = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 150);
    final progress = _goal > 0 ? (_finished / _goal).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: _editGoal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFC084FC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Reading Goal', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text('$_finished of $_goal books finished', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress, minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// --- UPDATED: Search Screen (Made transparent to show gradient) ---
class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({Key? key}) : super(key: key);

  @override
  _BookSearchScreenState createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _books = [];
  bool _isLoading = false;

  Future<void> _searchBooks() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _isLoading = true);

    final query = Uri.encodeComponent(_searchController.text);
    final apiKey =  dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';
    final url = 'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=12&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _books = data['items'] ?? []);
      }
    } catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No internet connection. Please try again.'), backgroundColor: Colors.grey, duration: Duration(seconds: 3)),
    );
  }
} finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBook(Map book, String category) async {
    final title = book['title'] ?? 'Unknown';
    
    // Check if the book already exists in this category
    final existingBook = await isar.savedBooks.filter()
        .titleEqualTo(title)
        .and()
        .categoryEqualTo(category)
        .findFirst();

    if (existingBook == null) {
      final newBook = SavedBook()
  ..title = title
  ..author = book['authors']?[0] ?? 'Unknown Author'
  ..coverUrl = book['imageLinks']?['thumbnail'] ?? ''
  ..category = category
  ..description = book['description'] ?? ''
  ..publisher = book['publisher'] ?? ''
  ..pageCount = book['pageCount'] ?? 0;

      await isar.writeTxn(() async {
        await isar.savedBooks.put(newBook);
      });

      if (mounted) {
        final displayCategory = category == 'Want It' ? 'Wishlist' : category;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to $displayCategory! ✨'), backgroundColor: const Color(0xFFA855F7), duration: const Duration(seconds: 2)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already saved this book!'), backgroundColor: Colors.grey, duration: Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Search', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF9333EA))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Find a specific book...',
                        hintStyle: const TextStyle(color: Color(0xFFD8B4FE)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _searchBooks(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _searchBooks,
                    backgroundColor: const Color(0xFFA855F7),
                    elevation: 2,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.search, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
  child: _isLoading
      ? GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.48, crossAxisSpacing: 16, mainAxisSpacing: 16,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => shimmerBox(),
        )
      : _books.isEmpty
          ? const Center(child: Text('Type a title or topic to begin!', style: TextStyle(color: Color(0xFFC084FC))))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.48, crossAxisSpacing: 16, mainAxisSpacing: 16,
              ),
              itemCount: _books.length,
              itemBuilder: (context, index)  {
                          final book = _books[index]['volumeInfo'];
                          final coverUrl = book['imageLinks']?['thumbnail'] ?? '';
                          return Card(
                             clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 3, child: Container(color: Colors.white, child: coverUrl.isNotEmpty
    ? CachedNetworkImage(
        imageUrl: coverUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE9D5FF))),
        errorWidget: (context, url, error) => const Icon(Icons.book, size: 50, color: Color(0xFFE9D5FF)),
      )
    : const Icon(Icons.book, size: 50, color: Color(0xFFE9D5FF)))),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(book['title'] ?? 'Unknown', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(book['authors']?[0] ?? 'Unknown Author', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.deepPurpleAccent)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(child: TextButton(onPressed: () => _saveBook(book, 'Own It'), style: TextButton.styleFrom(backgroundColor: const Color(0xFFFAF5FF), padding: EdgeInsets.zero), child: const Text('Own', style: TextStyle(color: Color(0xFF7E22CE), fontSize: 11)))),
                                            const SizedBox(width: 4),
                                            Expanded(child: ElevatedButton(onPressed: () => _saveBook(book, 'Want It'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7), elevation: 0, padding: EdgeInsets.zero), child: const Text('Wishlist', style: TextStyle(color: Colors.white, fontSize: 11)))),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
enum SortOption { title, author }
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({Key? key}) : super(key: key);

  @override
  _BookshelfScreenState createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  // Track the current sorting choice, defaulting to title
  SortOption _currentSortOption = SortOption.title;
Future<void> _exportLibrary() async {
  final allBooks = await isar.savedBooks.where().findAll();
  final jsonList = allBooks.map((b) => {
    'title': b.title,
    'author': b.author,
    'coverUrl': b.coverUrl,
    'category': b.category,
    'description': b.description,
    'publisher': b.publisher,
    'pageCount': b.pageCount,
    'status': b.status,
  }).toList();

  final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/book_boutique_backup.json');
  await file.writeAsString(jsonString);

  await Share.shareXFiles([XFile(file.path)], text: 'My Book Boutique library backup');
}

Future<void> _importLibrary() async {
  final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
  if (files.isEmpty) return;

  final file = File(files.first.path!);
  final content = await file.readAsString();
  final List<dynamic> jsonList = json.decode(content);

  int added = 0, skipped = 0;

  await isar.writeTxn(() async {
    for (final item in jsonList) {
      final title = item['title'] ?? '';
      final category = item['category'] ?? 'Own It';
      final existing = await isar.savedBooks.filter().titleEqualTo(title).and().categoryEqualTo(category).findFirst();
      if (existing == null) {
        final book = SavedBook()
          ..title = title
          ..author = item['author'] ?? 'Unknown Author'
          ..coverUrl = item['coverUrl'] ?? ''
          ..category = category
          ..description = item['description'] ?? ''
          ..publisher = item['publisher'] ?? ''
          ..pageCount = item['pageCount'] ?? 0
          ..status = item['status'] ?? 'Not Started';
        await isar.savedBooks.put(book);
        added++;
      } else {
        skipped++;
      }
    }
  });

  if (mounted) {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $added books ($skipped already existed)')),
    );
  }
}
  // ... keep your existing _loadAllBooks and _removeBook methods here ...
  Future<Map<String, List<SavedBook>>> _loadAllBooks() async {
    final ownItBooks = await isar.savedBooks.filter().categoryEqualTo('Own It').findAll();
    final wantItBooks = await isar.savedBooks.filter().categoryEqualTo('Want It').findAll();
    
    return {
      'Own It': ownItBooks,
      'Want It': wantItBooks,
    };
  }
  
  Future<void> _cycleStatus(SavedBook book) async {
  const order = ['Not Started', 'Reading', 'Finished'];
  final next = order[(order.indexOf(book.status) + 1) % order.length];
  await isar.writeTxn(() async {
    book.status = next;
    await isar.savedBooks.put(book);
  });
  setState(() {});
}

  Future<void> _removeBook(SavedBook book, String category) async {
    await isar.writeTxn(() async {
      await isar.savedBooks.delete(book.id); // Deletes using the Isar auto-increment ID
    });
    
    setState(() {}); // Refreshes the UI
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book removed! 🗑️'), backgroundColor: Color(0xFF9333EA), duration: Duration(seconds: 2)),
      );
    }
  }

Widget _buildBookGrid(List<SavedBook> books, String category, {bool showSort = false}) {
  List<SavedBook> displayedBooks = List.from(books);
    // 2. Apply the chosen sorting logic
    if (showSort) {
      if (_currentSortOption == SortOption.title) {
  displayedBooks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
} else if (_currentSortOption == SortOption.author) {
  displayedBooks.sort((a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
}
    }

    return Column(
      children: [
        // 3. Display the Sort Dropdown if showSort is true
        if (showSort && displayedBooks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.sort_rounded, color: Color(0xFFA855F7), size: 20),
                const SizedBox(width: 8),
                DropdownButton<SortOption>(
                  value: _currentSortOption,
                  underline: const SizedBox(), // Removes the default underline
                  style: const TextStyle(color: Color(0xFF7E22CE), fontWeight: FontWeight.w600, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  items: const [
                    DropdownMenuItem(value: SortOption.title, child: Text('Sort by Title')),
                    DropdownMenuItem(value: SortOption.author, child: Text('Sort by Author')),
                  ],
                  onChanged: (SortOption? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentSortOption = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
        // 4. Display the Grid
        Expanded(
          child: displayedBooks.isEmpty
              ? Center(child: Text("It's empty in here! Go save some books.", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.6, crossAxisSpacing: 16, mainAxisSpacing: 16,
                  ),
                  itemCount: displayedBooks.length,
                  itemBuilder: (context, index) {
                    final book = displayedBooks[index];
final coverUrl = book.coverUrl;
                    
                    return GestureDetector(                                // <-- NEW: wraps the old return
        onTap: () => Navigator.push(
  context,
  _premiumRoute(BookDetailScreen(book: book)),
).then((_) => setState(() {})),
        child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
  flex: 3,
  child: Hero(
  tag: 'book-cover-${book.id}',
  child: coverUrl.isNotEmpty
      ? CachedNetworkImage(
          imageUrl: coverUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE9D5FF))),
          errorWidget: (context, url, error) => const Icon(Icons.book, size: 50, color: Color(0xFFE9D5FF)),
        )
      : const Icon(Icons.book, size: 50, color: Color(0xFFE9D5FF)),
),
),
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12, color: Colors.black87)),
Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall,),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
  top: 4, left: 4,
  child: GestureDetector(
    onTap: () => _cycleStatus(book),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(book.status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF7E22CE))),
    ),
  ),
),
                          Positioned(
                            top: 4, right: 4,
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFF43F5E), size: 20),
                                constraints: const BoxConstraints(), padding: const EdgeInsets.all(8),
                                onPressed: () => _removeBook(book, category),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),);
                  },
                ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('My Library 📚', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
          actions: [
            IconButton(icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary), tooltip: 'Import backup', onPressed: _importLibrary),
            IconButton(icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary), tooltip: 'Export backup', onPressed: _exportLibrary),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
           labelColor: AppColors.textDark, unselectedLabelColor: AppColors.primaryLight, indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Own It'), Tab(text: 'Wishlist')],
          ),
        ),
        body: FutureBuilder<Map<String, List<SavedBook>>>(
  future: _loadAllBooks(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
    final data = snapshot.data ?? {'Own It': <SavedBook>[], 'Want It': <SavedBook>[]};
return TabBarView(
  children: [
    _buildBookGrid(data['Own It']!, 'Own It', showSort: false), 
    _buildBookGrid(data['Want It']!, 'Want It', showSort: true), 
  ],
);
          },
        ),
      ),
    );
  }
}
class CategorySearchScreen extends StatefulWidget {
  final String categoryTitle;
  final String query;

  const CategorySearchScreen({Key? key, required this.categoryTitle, required this.query}) : super(key: key);

  @override
  _CategorySearchScreenState createState() => _CategorySearchScreenState();
}

class _CategorySearchScreenState extends State<CategorySearchScreen> {
  // Note: Copy your _books list, _isLoading boolean, and _searchBooks logic here.
  // Update the url in _searchBooks to use widget.query: 
  // final url = 'https://www.googleapis.com/books/v1/volumes?q=${widget.query}&maxResults=12&key=$apiKey';
  
  // Call your search function inside initState() so it loads immediately:
  @override
  void initState() {
    super.initState();
    // _fetchCategoryBooks(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        backgroundColor: const Color(0xFFFAF5FF),
      ),
      // Use the same GridView.builder from your BookSearchScreen here
      body: const Center(child: Text("Results will appear here")), 
    );
  }
}


class BookDetailScreen extends StatefulWidget {
  final SavedBook book;
  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.book.status;
  }

  Future<void> _setStatus(String newStatus) async {
    await isar.writeTxn(() async {
      widget.book.status = newStatus;
      await isar.savedBooks.put(widget.book);
    });
    setState(() => _status = newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFA855F7),
            expandedHeight: 280,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFFC084FC)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 40),
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: ClipRRect(
  borderRadius: BorderRadius.circular(AppRadius.sm),
  child: Hero(
    tag: 'book-cover-${book.id}',
    child: book.coverUrl.isNotEmpty
        ? CachedNetworkImage(imageUrl: book.coverUrl, fit: BoxFit.cover, memCacheWidth: 300)
        : Container(width: 120, color: Colors.white, child: const Icon(Icons.book, size: 50, color: Color(0xFFE9D5FF))),
  ),
),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('by ${book.author}', style: const TextStyle(fontSize: 15, color: Color(0xFFA855F7), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),

                  // Status selector
                  Row(
                    children: ['Not Started', 'Reading', 'Finished'].map((s) {
                      final selected = _status == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s, style: TextStyle(fontSize: 12, color: selected ? Colors.white : const Color(0xFF7E22CE), fontWeight: FontWeight.w600)),
                          selected: selected,
                          selectedColor: const Color(0xFFA855F7),
                          backgroundColor: const Color(0xFFF3E8FF),
                          onSelected: (_) => _setStatus(s),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Metadata row
                  if (book.publisher.isNotEmpty || book.pageCount > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (book.publisher.isNotEmpty)
                            Column(
                              children: [
                                const Icon(Icons.business_rounded, color: Color(0xFF7E22CE), size: 20),
                                const SizedBox(height: 4),
                                Text(book.publisher, style: const TextStyle(fontSize: 11, color: Color(0xFFA855F7)), textAlign: TextAlign.center),
                              ],
                            ),
                          if (book.pageCount > 0)
                            Column(
                              children: [
                                const Icon(Icons.menu_book_rounded, color: Color(0xFF7E22CE), size: 20),
                                const SizedBox(height: 4),
                                Text('${book.pageCount} pages', style: const TextStyle(fontSize: 11, color: Color(0xFFA855F7))),
                              ],
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  if (book.description.isNotEmpty) ...[
                    const Text('About this book', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9333EA))),
                    const SizedBox(height: 8),
                    Text(book.description, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF6B21A8))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}