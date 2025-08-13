import 'package:flutter/material.dart';
import 'package:msbridge/theme/colors.dart';

class ColorShowcase extends StatelessWidget {
  const ColorShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Color Showcase'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Vibrant Color Collection',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our collection of beautiful colors and gradients',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Gradient Showcase
            _buildSectionTitle(context, 'Gradient Backgrounds'),
            const SizedBox(height: 16),
            _buildGradientShowcase(context),
            const SizedBox(height: 32),

            // Accent Colors
            _buildSectionTitle(context, 'Accent Colors'),
            const SizedBox(height: 16),
            _buildAccentColorShowcase(context),
            const SizedBox(height: 32),

            // Glass Effects
            _buildSectionTitle(context, 'Glass Effects'),
            const SizedBox(height: 16),
            _buildGlassEffectShowcase(context),
            const SizedBox(height: 32),

            // Theme Preview
            _buildSectionTitle(context, 'Theme Previews'),
            const SizedBox(height: 16),
            _buildThemePreviewShowcase(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildGradientShowcase(BuildContext context) {
    return Column(
      children: [
        _buildGradientCard(
          context,
          'Cyber Gradient',
          AppColors.cyberGradient,
          Icons.psychology,
        ),
        const SizedBox(height: 16),
        _buildGradientCard(
          context,
          'Neon Gradient',
          AppColors.neonGradient,
          Icons.electric_bolt,
        ),
        const SizedBox(height: 16),
        _buildGradientCard(
          context,
          'Aurora Gradient',
          AppColors.auroraGradient,
          Icons.nights_stay,
        ),
        const SizedBox(height: 16),
        _buildGradientCard(
          context,
          'Sunset Gradient',
          AppColors.sunsetGradient,
          Icons.wb_sunny,
        ),
      ],
    );
  }

  Widget _buildGradientCard(
    BuildContext context,
    String title,
    List<Color> colors,
    IconData icon,
  ) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentColorShowcase(BuildContext context) {
    final accentColors = [
      {'name': 'Neon Green', 'color': AppColors.neonGreen, 'icon': Icons.eco},
      {'name': 'Hot Pink', 'color': AppColors.hotPink, 'icon': Icons.favorite},
      {
        'name': 'Electric Cyan',
        'color': AppColors.electricCyan,
        'icon': Icons.flash_on
      },
      {
        'name': 'Cosmic Purple',
        'color': AppColors.cosmicPurple,
        'icon': Icons.space_bar
      },
      {
        'name': 'Golden Orange',
        'color': AppColors.goldenOrange,
        'icon': Icons.wb_sunny
      },
      {
        'name': 'Tropical Green',
        'color': AppColors.tropicalGreen,
        'icon': Icons.park
      },
      {'name': 'Ice Blue', 'color': AppColors.iceBlue, 'icon': Icons.ac_unit},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: accentColors.length,
      itemBuilder: (context, index) {
        final item = accentColors[index];
        return _buildAccentColorCard(
          context,
          item['name'] as String,
          item['color'] as Color,
          item['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildAccentColorCard(
    BuildContext context,
    String name,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassEffectShowcase(BuildContext context) {
    return Column(
      children: [
        _buildGlassCard(
          context,
          'Glass White',
          AppColors.glassWhite,
          Icons.auto_fix_high,
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
          context,
          'Glass Black',
          AppColors.glassBlack,
          Icons.auto_fix_high,
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
          context,
          'Glass Primary',
          AppColors.glassPrimary,
          Icons.auto_fix_high,
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
          context,
          'Glass Secondary',
          AppColors.glassSecondary,
          Icons.auto_fix_high,
        ),
      ],
    );
  }

  Widget _buildGlassCard(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreviewShowcase(BuildContext context) {
    final themes = [
      {'name': 'Cyber Dark', 'theme': AppThemes.cyberDarkTheme},
      {'name': 'Neon Punk', 'theme': AppThemes.neonPunkTheme},
      {'name': 'Aurora Borealis', 'theme': AppThemes.auroraBorealisTheme},
      {'name': 'Cosmic Void', 'theme': AppThemes.cosmicVoidTheme},
    ];

    return Column(
      children: themes.map((themeData) {
        final theme = themeData['theme'] as ThemeData;
        final name = themeData['name'] as String;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildThemeColorDot(theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    _buildThemeColorDot(theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    _buildThemeColorDot(theme.colorScheme.surface),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeColorDot(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
