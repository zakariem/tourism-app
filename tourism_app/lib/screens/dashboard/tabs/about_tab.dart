import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/providers/enhanced_user_behavior_provider.dart';
import 'package:tourism_app/services/app_statistics_service.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatefulWidget {
  const AboutTab({Key? key}) : super(key: key);

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(languageProvider, isTablet),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : (isTablet ? 40 : 24),
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeroSection(languageProvider, isTablet, isMobile),
                    const SizedBox(height: 32),
                    _buildAboutSection(languageProvider, isTablet, isMobile),
                    const SizedBox(height: 32),
                    _buildFeaturesGrid(languageProvider, isTablet, isMobile),
                    const SizedBox(height: 32),
                    _buildStatsSection(languageProvider, isTablet, isMobile),
                    const SizedBox(height: 32),
                    _buildUserActivitySection(
                        languageProvider, isTablet, isMobile),
                    const SizedBox(height: 32),
                    _buildTeamSection(languageProvider, isTablet, isMobile),
                    const SizedBox(height: 32),
                    _buildContactSection(languageProvider, isTablet, isMobile),
                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(LanguageProvider languageProvider, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 280 : 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
                const Color(0xFF1E40AF),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated background pattern
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      width: isTablet ? 100 : 80,
                      height: isTablet ? 100 : 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.travel_explore_rounded,
                        size: isTablet ? 50 : 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      languageProvider.getText('about'),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isTablet ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageProvider.currentLanguage == 'en'
                          ? 'Discover Somalia with us'
                          : 'Soomaaliya nala baadh',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Curved bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
      LanguageProvider languageProvider, bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isTablet ? 140 : 120,
            height: isTablet ? 140 : 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              size: isTablet ? 70 : 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            languageProvider.getText('app_name'),
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 36 : 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(
      LanguageProvider languageProvider, bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isTablet ? 64 : 56,
                height: isTablet ? 64 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: isTablet ? 32 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  languageProvider.getText('about_app'),
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            languageProvider.currentLanguage == 'en'
                ? 'Welcome to our comprehensive Tourism App designed specifically for exploring the rich cultural heritage and breathtaking landscapes of Somalia. Our platform connects travelers with authentic experiences, from ancient historical sites to pristine beaches, vibrant markets, and sacred religious landmarks.'
                : 'Ku soo dhaweeyaw barnaamijkeenna dalxiiska ee dhamaystiran oo gaar ahaan loo sameeyay si loo baadho dhaxalka dhaqanka qani ah iyo muuqaalada soo jiidashada leh ee Soomaaliya. Goobteennu waxay ku xiraysaa dalxiisayaasha khibradaha dhabta ah, laga bilaabo goobaha taariikhiga ah ee qadiimiga ah ilaa xeebaha nadiifka ah, suuqyada firfircoon, iyo calaamadaha diinta ee quduuska ah.',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: isTablet ? 18 : 16,
              height: 1.7,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(
      LanguageProvider languageProvider, bool isTablet, bool isMobile) {
    final features = [
      {
        'icon': Icons.location_on_rounded,
        'title': languageProvider.currentLanguage == 'en'
            ? 'Discover Places'
            : 'Baadh Meelaha',
        'description': languageProvider.currentLanguage == 'en'
            ? 'Explore amazing tourist destinations across Somalia'
            : 'Baadh meelaha dalxiiska ee cajiibka ah ee Soomaaliya',
        'color': const Color(0xFFEF4444),
      },
      {
        'icon': Icons.favorite_rounded,
        'title': languageProvider.currentLanguage == 'en'
            ? 'Save Favorites'
            : 'Kaydi Kuwa Aad Jeceshahay',
        'description': languageProvider.currentLanguage == 'en'
            ? 'Keep track of your favorite places and create wishlists'
            : 'La soco meelaha aad jeceshahay oo samee liisaska rabitaankaaga',
        'color': const Color(0xFFEC4899),
      },
      {
        'icon': Icons.smart_toy_rounded,
        'title': languageProvider.currentLanguage == 'en'
            ? 'AI Assistant'
            : 'Caawimaadka AI',
        'description': languageProvider.currentLanguage == 'en'
            ? 'Get personalized recommendations from our smart AI'
            : 'Ka hel talooyinka gaarka ah caawimaadkeenna caqliga ah',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.language_rounded,
        'title': languageProvider.currentLanguage == 'en'
            ? 'Multi-language'
            : 'Luuqado Badan',
        'description': languageProvider.currentLanguage == 'en'
            ? 'Available in English and Somali languages'
            : 'Waxaa lagu heli karaa luuqadaha Ingiriisiga iyo Soomaaliga',
        'color': const Color(0xFF10B981),
      },
    ];

    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isTablet ? 64 : 56,
                height: isTablet ? 64 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.orange.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: isTablet ? 32 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  languageProvider.currentLanguage == 'en'
                      ? 'Key Features'
                      : 'Sifooyinka Muhiimka ah',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 2),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 3.5 : (isTablet ? 3.2 : 3.0),
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _buildFeatureCard(
                icon: feature['icon'] as IconData,
                title: feature['title'] as String,
                description: feature['description'] as String,
                color: feature['color'] as Color,
                isTablet: isTablet,
                isMobile: isMobile,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isTablet,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 56 : 48,
            height: isTablet ? 56 : 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 14 : 13,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
      LanguageProvider languageProvider, bool isTablet, bool isMobile) {
    return Consumer2<EnhancedUserBehaviorProvider, AuthProvider>(
      builder: (context, enhancedUserBehavior, authProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: AppStatisticsService.getAppStatistics(
            userBehavior: enhancedUserBehavior,
            authProvider: authProvider,
          ),
          builder: (context, snapshot) {
            final stats = snapshot.hasData
                ? [
                    {
                      'number': '${snapshot.data!['totalPlaces']}',
                      'label': languageProvider.currentLanguage == 'en'
                          ? 'Tourist Places'
                          : 'Meelaha Dalxiiska',
                      'icon': Icons.place_rounded,
                      'color': const Color(0xFF3B82F6),
                    },
                    {
                      'number': '${snapshot.data!['categoriesCount']}',
                      'label': languageProvider.currentLanguage == 'en'
                          ? 'Categories'
                          : 'Qaybaha',
                      'icon': Icons.category_rounded,
                      'color': const Color(0xFF10B981),
                    },
                    {
                      'number': '2',
                      'label': languageProvider.currentLanguage == 'en'
                          ? 'Languages'
                          : 'Luuqadaha',
                      'icon': Icons.language_rounded,
                      'color': const Color(0xFFEF4444),
                    },
                    {
                      'number': '${snapshot.data!['favoritesCount']}',
                      'label': languageProvider.currentLanguage == 'en'
                          ? 'Favorites'
                          : 'Jecelka',
                      'icon': Icons.favorite_rounded,
                      'color': const Color(0xFF8B5CF6),
                    },
                  ]
                : [
                    {
                      'number': '...',
                      'label': languageProvider.currentLanguage == 'en'
                          ? 'Tourist Places'
                          : 'Meelaha Dalxiiska',
                      'icon': Icons.place_rounded,
                      'color': const Color(0xFF3B82F6),
                    },
                    {
                      'number': '...',
                      'label': languageProvider.currentLanguage == 'en'
                          ? 'Categories'
                          : 'Qaybaha',
                      'icon': Icons.category_rounded,
                      'color': const Color(0xFF10B981),
                    },
                    {
                      'number': '...',
                      'label': languageProvider.currentLanguage == 'en'
                          ? 'Languages'
                          : 'Luuqadaha',
                      'icon': Icons.language_rounded,
                      'color': const Color(0xFFEF4444),
                    },
                    {
                      'number': '24/7',
                      'label': languageProvider.currentLanguage == 'en'
                          ? 'Support'
                          : 'Taageero',
                      'icon': Icons.support_agent_rounded,
                      'color': const Color(0xFF8B5CF6),
                    },
                  ];

            return Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.primary.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    languageProvider.currentLanguage == 'en'
                        ? 'App Statistics'
                        : 'Tirakoobka App-ka',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isMobile ? 1.2 : 1.0,
                      ),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final stat = stats[index];
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      (stat['color'] as Color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  stat['icon'] as IconData,
                                  color: stat['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                stat['number'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: stat['color'] as Color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stat['label'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 14 : 12,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserActivitySection(
      LanguageProvider languageProvider, bool isTablet, bool isMobile) {
    return Consumer<EnhancedUserBehaviorProvider>(
      builder: (context, enhancedUserBehavior, child) {
        final categoryInteractions = enhancedUserBehavior.categoryInteractions;
        final totalClicks = categoryInteractions.values.fold(0, (sum, count) => sum + count);

        if (totalClicks == 0) {
          return const SizedBox.shrink(); // Hide if no activity
        }

        final activityStats = [
          {
            'number': '${categoryInteractions['beach'] ?? 0}',
            'label': languageProvider.currentLanguage == 'en'
                ? 'Beach Visits'
                : 'Booqashada Xeebaha',
            'icon': Icons.beach_access_rounded,
            'color': const Color(0xFF06B6D4),
          },
          {
            'number': '${categoryInteractions['historical'] ?? 0}',
            'label': languageProvider.currentLanguage == 'en'
                ? 'Historical Sites'
                : 'Meelaha Taariikhiga',
            'icon': Icons.account_balance_rounded,
            'color': const Color(0xFF8B5CF6),
          },
          {
            'number': '${categoryInteractions['cultural'] ?? 0}',
            'label': languageProvider.currentLanguage == 'en'
                ? 'Cultural Places'
                : 'Meelaha Dhaqanka',
            'icon': Icons.museum_rounded,
            'color': const Color(0xFF10B981),
          },
          {
            'number': '${categoryInteractions['religious'] ?? 0}',
            'label': languageProvider.currentLanguage == 'en'
                ? 'Religious Sites'
                : 'Meelaha Diinta',
            'icon': Icons.mosque_rounded,
            'color': const Color(0xFFEF4444),
          },
        ];

        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF06B6D4).withOpacity(0.05),
                const Color(0xFF8B5CF6).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF06B6D4).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.currentLanguage == 'en'
                              ? 'Your Activity'
                              : 'Waxqabadkaaga',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          languageProvider.currentLanguage == 'en'
                              ? 'Total interactions: $totalClicks'
                              : 'Wadarta falgalka: $totalClicks',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 16 : 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 1.2 : 1.0,
                ),
                itemCount: activityStats.length,
                itemBuilder: (context, index) {
                  final stat = activityStats[index];
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (stat['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            stat['icon'] as IconData,
                            color: stat['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          stat['number'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: stat['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 14 : 12,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamSection(
      LanguageProvider languageProvider, bool isTablet, bool isMobile) {
    final teamMembers = [
      {
        'name': 'Hassan Mohamed Zubeyr',
        'role': 'Lead Developer',
        'email': 'hassan@gmail.com',
        'color': const Color(0xFF3B82F6),
        'icon': Icons.code_rounded,
      },
      {
        'name': 'Mohamed Abdikhadir Gelle',
        'role': 'ML Engineer',
        'email': 'mohamed@gmail.com',
        'color': const Color(0xFF10B981),
        'icon': Icons.psychology_rounded,
      },
      {
        'name': 'Mohamed Abdullahi Ali',
        'role': 'UI/UX Designer',
        'email': 'abdullahi@gmail.com',
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.design_services_rounded,
      },
      {
        'name': 'Libaan Abdi Ibraahim',
        'role': 'Content Writer',
        'email': 'libaan@gmail.com',
        'color': const Color(0xFFEF4444),
        'icon': Icons.edit_rounded,
      },
    ];

    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isTablet ? 64 : 56,
                height: isTablet ? 64 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade400,
                      Colors.indigo.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.group_rounded,
                  color: Colors.white,
                  size: isTablet ? 32 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  languageProvider.getText('developer_team'),
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 2),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 4.0 : (isTablet ? 3.5 : 3.2),
            ),
            itemCount: teamMembers.length,
            itemBuilder: (context, index) {
              final member = teamMembers[index];
              return _buildTeamMemberCard(
                name: member['name'] as String,
                role: member['role'] as String,
                email: member['email'] as String,
                color: member['color'] as Color,
                icon: member['icon'] as IconData,
                isTablet: isTablet,
                isMobile: isMobile,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard({
    required String name,
    required String role,
    required String email,
    required Color color,
    required IconData icon,
    required bool isTablet,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: isTablet ? 72 : 64,
                height: isTablet ? 72 : 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.split(' ').map((n) => n[0]).take(2).join(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isTablet ? 22 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                    fontSize: isTablet ? 14 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(
      LanguageProvider languageProvider, bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.contact_support_rounded,
            size: isTablet ? 64 : 56,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            languageProvider.currentLanguage == 'en'
                ? 'Get in Touch'
                : 'Nala Soo Xiriir',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            languageProvider.currentLanguage == 'en'
                ? 'Have questions or feedback? We\'d love to hear from you!'
                : 'Ma haysaa su\'aalo ama ra\'yi? Waan jeclaan lahayn inaan ka maqalno!',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: _buildContactButton(
              icon: Icons.phone_rounded,
              label: 'WhatsApp',
              isTablet: isTablet,
              onTap: _launchWhatsApp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Launch WhatsApp with the specified number
  void _launchWhatsApp() async {
    const phoneNumber = '+252619071794';
    const whatsappUrl = 'https://wa.me/$phoneNumber';

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication);
      } else {
        // Fallback to phone dialer if WhatsApp is not available
        const phoneUrl = 'tel:$phoneNumber';
        if (await canLaunchUrl(Uri.parse(phoneUrl))) {
          await launchUrl(Uri.parse(phoneUrl));
        }
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }


}
