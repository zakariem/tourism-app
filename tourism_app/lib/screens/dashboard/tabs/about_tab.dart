import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/widgets/language_toggle.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getText('about')),
        automaticallyImplyLeading: false,
        actions: [
          const LanguageToggle(
            showLabel: true,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.travel_explore,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    languageProvider.getText('app_name'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // About App Section
            Text(
              languageProvider.getText('about_app'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              languageProvider.currentLanguage == 'en'
                  ? 'Welcome to our Tourism App! This application is designed to help visitors explore the beautiful tourist destinations in Somalia. Discover historical sites, cultural landmarks, religious places, and stunning beaches across the country.'
                  : 'Ku soo dhaweeyay App-ka Dalxiiska! Barnaamijkan wuxuu loo sameeyay si uu uga caawiyo martida inay wax ka baran meelaha dalxiiska ee Soomaaliya. Waxaad aragtaa meelaha taariikhiga ah, meelaha dhaqanka, meelaha diiniga ah, iyo xeebaha quruxsan ee dalka.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Developer Team Section
            Text(
              languageProvider.getText('developer_team'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTeamMember(
              context,
              'Hassan Mohamed Zubeyr',
              'Lead Developer',
              'hassan@gmail.com',
            ),
            const SizedBox(height: 16),
            _buildTeamMember(
              context,
              'Mohamed Abdikhadir Gelle',
              'Machine Learning Engineer',
              'mohamed@gmail.com',
            ),
            const SizedBox(height: 16),
            _buildTeamMember(
              context,
              'Mohamed Abdullahi Ali',
              'UI/UX Designer',
              'abdullahi@gmail.com',
            ),
            const SizedBox(height: 16),
            _buildTeamMember(
              context,
              'Libaan Abdi Ibraahim',
              'Content Writer',
              'libaan@gmail.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMember(
    BuildContext context,
    String name,
    String role,
    String email,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                name[0],
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
