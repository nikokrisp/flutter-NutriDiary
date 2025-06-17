import 'package:flutter/material.dart';
import 'package:flutter_nutridiary/screens/daily_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../providers/page_index_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_navbar.dart';
import '../screens/checker_screen.dart';
import '../screens/favorite_screen.dart';
import '../screens/insight_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late PageIndexProvider _pageIndexProvider;
  final PageController _pageController = PageController(initialPage: 2);
  VoidCallback? _pageIndexListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pageIndexListener == null) {
      _pageIndexProvider = Provider.of<PageIndexProvider>(context, listen: false);
      _pageIndexListener = () {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_pageIndexProvider.currentIndex);
        }
      };
      _pageIndexProvider.addListener(_pageIndexListener!);
    }
  }

  @override
  void dispose() {
    if (_pageIndexListener != null) {
      _pageIndexProvider.removeListener(_pageIndexListener!);
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final pageIndexProvider = Provider.of<PageIndexProvider>(context);

    AppBar appBar = AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/pastel fruit background.avif'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: RichText(
        text: TextSpan(
          children: [
            // "Nutri" — Pacifico, red-orange
            TextSpan(
              text: 'Nutri',
              style: GoogleFonts.pacifico(
                fontSize: 42,
                color: const Color(0xFFF94144), // Vibrant fruity red
                height: 1.1,
              ),
            ),
            // "Diary" — Lato Bold, blueberry slate
            TextSpan(
              text: 'Diary',
              style: GoogleFonts.lato(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF577590), // Cool contrast
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            padding: EdgeInsets.only(left: 10),
            icon: Icon(Icons.menu_rounded,
              shadows: [
                Shadow(
                  color: Color(0xFFFFD166),
                  blurRadius: 12,
                ),
              ], 
              size: 40, 
              color: Color(0xFFF4A261)),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        },
      ),
      centerTitle: true,
      toolbarHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * 0.065,
    );

    return DefaultTabController(
      length: 4,
      initialIndex: pageIndexProvider.currentIndex,
      child: Scaffold(
        backgroundColor: appState.isDarkMode ? Colors.black : Colors.white,
        drawer: AppDrawer(
          onAboutTap: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: const Color.fromARGB(236, 44, 60, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '   About Us',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '''
NutryDiary adalah aplikasi yang dikembangkan untuk membantu pengguna memahami informasi gizi makanan dengan cepat dan mudah. Dengan tiga fitur utama—Nutri-Checker, Your Food, dan Insight—aplikasi ini memberikan kemudahan dalam mencari data gizi, menyimpan daftar makanan favorit, serta mendapatkan edukasi dan fakta menarik seputar makanan.

Kami percaya bahwa kesadaran akan pola makan merupakan langkah penting menuju hidup yang lebih sehat. Melalui NutryDiary, kami ingin mendorong pengguna untuk membuat keputusan yang lebih baik terkait konsumsi makanan sehari-hari.

NutryDiary dirancang tidak hanya untuk individu, tetapi juga untuk memberikan manfaat bagi masyarakat luas, tenaga kesehatan, dunia pendidikan, dan pengembang teknologi. Meskipun masih memiliki keterbatasan dalam cakupan data dan fitur, kami berkomitmen untuk terus mengembangkan aplikasi ini sebagai solusi inovatif dalam meningkatkan kesadaran gizi di era digital.
                            ''',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        appBar: appBar,
        body: Stack(
          children: [
            Selector<PageIndexProvider, int>(
              selector: (_, provider) => provider.currentIndex,
              builder: (context, currentIndex, child) {
                double alignmentX = -1; // interval from -1 to 1 (there's 4 pages so -1, -.33, .33, 1)
                alignmentX += (currentIndex * (2/3));
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('images/transparent_BG.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment(alignmentX < 1.0 ? alignmentX : 1, 0),
                    ),
                  ),
                );
              },
            ),
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                pageIndexProvider.setIndex(index);
              },
              children: const [
                CheckerScreen(),
                DailyScreen(),
                FavoriteScreen(),
                InsightScreen(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: pageIndexProvider.currentIndex,
          onTap: (index) {
            pageIndexProvider.setIndex(index);
          },
        ),
      ),
    );
  }
}