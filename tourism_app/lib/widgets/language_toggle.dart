import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/enhanced_user_behavior_provider.dart';
import 'package:tourism_app/utils/app_colors.dart';

class LanguageToggle extends StatelessWidget {
  final bool showLabel;
  final Color? iconColor;
  final double size;

  const LanguageToggle({
    Key? key,
    this.showLabel = false,
    this.iconColor,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final userBehaviorProvider = Provider.of<EnhancedUserBehaviorProvider>(context);
    final isEnglish = languageProvider.currentLanguage == 'en';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final newLang = isEnglish ? 'so' : 'en';
          languageProvider.setLanguage(newLang);
          
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flag Icon
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: iconColor ?? AppColors.primary,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.asset(
                    isEnglish ? 'assets/flags/so.png' : 'assets/flags/gp.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      isEnglish ? Icons.flag : Icons.flag_outlined,
                      color: iconColor ?? AppColors.primary,
                      size: size * 0.8,
                    ),
                  ),
                ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(
                  isEnglish ? 'SO' : 'EN',
                  style: TextStyle(
                    color: iconColor ?? AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
