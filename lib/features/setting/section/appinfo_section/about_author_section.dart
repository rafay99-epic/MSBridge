import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:msbridge/core/api/about_author_api.dart';

class AboutAuthorSection extends StatefulWidget {
  const AboutAuthorSection({super.key});

  @override
  State<AboutAuthorSection> createState() => _AboutAuthorSectionState();
}

class _AboutAuthorSectionState extends State<AboutAuthorSection>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? authorData;
  bool isLoading = true;
  String? errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchAuthorData();
  }

  Future<void> _fetchAuthorData() async {
    try {
      // Use the centralized API service
      final authorDataResult = await AboutAuthorApiService.fetchAuthorData();

      setState(() {
        authorData = authorDataResult;
        isLoading = false;
      });

      // Log successful data fetch
      FlutterBugfender.log(
          'AboutAuthor: Data fetched successfully from API service');
    } on AboutAuthorApiException catch (e) {
      // Handle API-specific errors
      FlutterBugfender.sendCrash(
          'AboutAuthor: API service error - ${e.message}',
          StackTrace.current.toString());
      FlutterBugfender.error('AboutAuthor: API service error - ${e.message}');
      FirebaseCrashlytics.instance
          .log('AboutAuthor: API service error - ${e.message}');

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    } catch (e) {
      FlutterBugfender.sendCrash('Unexpected error in About Author UI: $e',
          StackTrace.current.toString());
      FlutterBugfender.error('Unexpected error in About Author UI: $e');
      // Handle any other unexpected errors
      FlutterBugfender.log(
          'AboutAuthor: Unexpected error in UI - ${e.toString()}');

      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again later.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (isLoading) {
      return _buildLoadingState(theme);
    }

    if (errorMessage != null) {
      return _buildErrorState(theme);
    }

    if (authorData == null) {
      return _buildErrorState(theme);
    }

    return _buildAuthorContent(theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading author information...',
              style: GoogleFonts.poppins(
                color: theme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Icon(
              LineIcons.exclamationTriangle,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load author information',
              style: GoogleFonts.poppins(
                color: theme.colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Log retry attempt
                FirebaseCrashlytics.instance
                    .log('AboutAuthor: User initiated retry for author data');
                _fetchAuthorData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(theme),
          const SizedBox(height: 24),
          _buildAboutSection(theme),
          const SizedBox(height: 24),
          _buildTechStackSection(theme),
          const SizedBox(height: 24),
          _buildWorkExperienceSection(theme),
          const SizedBox(height: 24),
          _buildTestimonialsSection(theme),
          const SizedBox(height: 24),
          _buildServicesSection(theme),
          const SizedBox(height: 24),
          _buildSocialLinksSection(theme),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    final name = authorData!['name'] ?? 'Unknown';
    final jobTitle = authorData!['jobTitle'] ?? '';
    final position = authorData!['position'] ?? '';
    final tagLine = authorData!['tag_line'] ?? '';
    final avatar = authorData!['avator'] ?? '';

    // Handle avatar URL properly
    final isValidAvatarUrl = avatar.isNotEmpty &&
        (avatar.startsWith('http://') || avatar.startsWith('https://'));
    final fullAvatarUrl =
        isValidAvatarUrl ? avatar : 'https://www.rafay99.com$avatar';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: isValidAvatarUrl || avatar.startsWith('/')
                    ? NetworkImage(fullAvatarUrl)
                    : null,
                backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                child: (isValidAvatarUrl || avatar.startsWith('/'))
                    ? null
                    : Icon(
                        LineIcons.user,
                        size: 40,
                        color: theme.colorScheme.secondary,
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        height: 1.2,
                      ),
                    ),
                    if (jobTitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        jobTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (position.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        position,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (tagLine.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              tagLine,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    final about = authorData!['about'] ?? {};
    final whoAmI = about['whoAmI'] ?? '';
    final lifeBeyondCode = about['lifeBeyondCode'] ?? '';
    final continuousLearning = about['continuousLearning'] ?? '';

    return _buildSectionCard(
      theme,
      title: 'About Me',
      icon: LineIcons.user,
      children: [
        if (whoAmI.isNotEmpty) _buildAboutItem(theme, 'Who I Am', whoAmI),
        if (lifeBeyondCode.isNotEmpty)
          _buildAboutItem(theme, 'Life Beyond Code', lifeBeyondCode),
        if (continuousLearning.isNotEmpty)
          _buildAboutItem(theme, 'Continuous Learning', continuousLearning),
      ],
    );
  }

  Widget _buildAboutItem(ThemeData theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.6,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTechStackSection(ThemeData theme) {
    final techStack = authorData!['techStack'] ?? [];

    return _buildSectionCard(
      theme,
      title: 'Tech Stack',
      icon: LineIcons.code,
      children: [
        // Introduction section
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LineIcons.lightbulb,
                size: 24,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'My technical expertise spans across multiple domains, from mobile development to cloud infrastructure.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...techStack
            .map<Widget>((category) => _buildTechCategory(theme, category))
            .toList(),
      ],
    );
  }

  Widget _buildTechCategory(ThemeData theme, Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(category['category'] ?? ''),
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category['category'] ?? '',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontSize: 20,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: (category['tools'] as List<dynamic>).map<Widget>((tool) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.secondary.withValues(alpha: 0.12),
                      theme.colorScheme.secondary.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getToolIcon(tool.toString()),
                      size: 16,
                      color: theme.colorScheme.secondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tool.toString(),
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.1,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'app development':
        return LineIcons.tablet;
      case 'frontend development':
        return LineIcons.code;
      case 'backend development':
        return LineIcons.database;
      case 'cloud computing':
        return LineIcons.cloud;
      case 'scripting':
        return LineIcons.terminal;
      default:
        return LineIcons.code;
    }
  }

  IconData _getToolIcon(String tool) {
    switch (tool.toLowerCase()) {
      case 'flutter':
      case 'android':
      case 'ios':
        return LineIcons.tablet;
      case 'react':
      case 'javascript':
      case 'typescript':
      case 'nextjs':
      case 'astro':
        return LineIcons.code;
      case 'tailwindcss':
      case 'css':
        return LineIcons.palette;
      case 'nodejs':
      case 'express':
        return LineIcons.rocket;
      case 'mongodb':
      case 'postgresql':
      case 'sqlite':
      case 'sql':
        return LineIcons.database;
      case 'firebase':
      case 'supabase':
      case 'aws':
      case 'vercel':
      case 'netlify':
        return LineIcons.cloud;
      case 'git':
      case 'bash':
      case 'powershell':
      case 'python':
        return LineIcons.terminal;
      default:
        return LineIcons.cog;
    }
  }

  Widget _buildWorkExperienceSection(ThemeData theme) {
    final workExperience = authorData!['workExperience'] ?? [];

    return _buildSectionCard(
      theme,
      title: 'Work Experience',
      icon: LineIcons.briefcase,
      children: workExperience
          .map<Widget>((job) => _buildJobCard(theme, job))
          .toList(),
    );
  }

  Widget _buildJobCard(ThemeData theme, Map<String, dynamic> job) {
    final companyName = job['companyName'] ?? '';
    final position = job['position'] ?? '';
    final employmentTime = job['employmentTime'] ?? '';
    final roles = job['roles'] ?? [];
    final toolsUsed = job['toolsUsed'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      position,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.secondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employmentTime,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Key Responsibilities:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            ...roles
                .map<Widget>((role) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LineIcons.check,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              role.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
          if (toolsUsed.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Technologies Used:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: toolsUsed
                  .map<Widget>((tool) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          tool.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.secondary,
                            height: 1.2,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(ThemeData theme) {
    final testimonials = authorData!['testimonials'] ?? [];

    return _buildSectionCard(
      theme,
      title: 'Client Testimonials',
      icon: LineIcons.comments,
      children: testimonials
          .take(2)
          .map<Widget>(
              (testimonial) => _buildTestimonialCard(theme, testimonial))
          .toList(),
    );
  }

  Widget _buildTestimonialCard(
      ThemeData theme, Map<String, dynamic> testimonial) {
    final name = testimonial['name'] ?? '';
    final position = testimonial['position'] ?? '';
    final company = testimonial['company'] ?? '';
    final testimonialText = testimonial['testimonial'] ?? '';
    final rating = testimonial['rating'] ?? 0;
    final project = testimonial['project'] ?? '';
    final technologies = testimonial['technologies'] ?? [];

    // Handle avatar URL properly
    final avatarUrl = testimonial['avatar'] ?? '';
    final isValidAvatarUrl = avatarUrl.isNotEmpty &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage:
                    isValidAvatarUrl ? NetworkImage(avatarUrl) : null,
                backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                child: isValidAvatarUrl
                    ? null
                    : Icon(
                        LineIcons.user,
                        size: 30,
                        color: theme.colorScheme.secondary,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '$position at $company',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (index) => Icon(
                          index < rating ? LineIcons.star : LineIcons.starAlt,
                          size: 20,
                          color: index < rating
                              ? Colors.amber
                              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            testimonialText,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.justify,
          ),
          if (project.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Project: $project',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
                height: 1.3,
              ),
            ),
          ],
          if (technologies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: technologies
                  .map<Widget>((tech) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tech.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.secondary,
                            height: 1.2,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesSection(ThemeData theme) {
    final services = authorData!['services'] ?? [];

    return _buildSectionCard(
      theme,
      title: 'Services I Offer',
      icon: LineIcons.cogs,
      children: services
          .map<Widget>((service) => _buildServiceCard(theme, service))
          .toList(),
    );
  }

  Widget _buildServiceCard(ThemeData theme, Map<String, dynamic> service) {
    final title = service['title'] ?? '';
    final description = service['description'] ?? '';
    final features = service['features'] ?? [];
    final technologies = service['technologies'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getServiceIcon(title),
                  size: 24,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Key Features:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            ...features
                .map<Widget>((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LineIcons.check,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
          if (technologies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Technologies:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: technologies
                  .map<Widget>((tech) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          tech.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.secondary,
                            height: 1.2,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getServiceIcon(String title) {
    switch (title.toLowerCase()) {
      case 'mobile app development':
        return LineIcons.tablet;
      case 'web development':
        return LineIcons.globe;
      case 'full-stack solutions':
        return LineIcons.code;
      case 'cloud & devops':
        return LineIcons.cloud;
      default:
        return LineIcons.cogs;
    }
  }

  Widget _buildSocialLinksSection(ThemeData theme) {
    final socialLinks = authorData!['socialLinks'] ?? {};

    return _buildSectionCard(
      theme,
      title: 'Connect With Me',
      icon: LineIcons.share,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (socialLinks['twitter'] != null)
              _buildSocialButton(
                  theme, 'Twitter', socialLinks['twitter'], LineIcons.twitter),
            if (socialLinks['linkedin'] != null)
              _buildSocialButton(theme, 'LinkedIn', socialLinks['linkedin'],
                  LineIcons.linkedin),
            if (socialLinks['github'] != null)
              _buildSocialButton(
                  theme, 'GitHub', socialLinks['github'], LineIcons.github),
            if (socialLinks['upwork'] != null)
              _buildSocialButton(
                  theme, 'Upwork', socialLinks['upwork'], LineIcons.briefcase),
            if (socialLinks['youtube'] != null)
              _buildSocialButton(
                  theme, 'YouTube', socialLinks['youtube'], LineIcons.youtube),
            if (socialLinks['whatsNumber'] != null)
              _buildSocialButton(
                  theme,
                  'WhatsApp',
                  'https://wa.me/${socialLinks['whatsNumber']}',
                  LineIcons.comment),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
      ThemeData theme, String label, String url, IconData icon) {
    // Validate URL format
    try {
      Uri.parse(url);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Invalid URL format detected: $url', StackTrace.current.toString());
      FlutterBugfender.error('Invalid URL format detected: $url');
      FlutterBugfender.log('AboutAuthor: Invalid URL format detected: $url');

      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      // Log URL launch attempt
      FirebaseCrashlytics.instance
          .log('AboutAuthor: Attempting to launch URL: $url');

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        FirebaseCrashlytics.instance
            .log('AboutAuthor: URL launched successfully: $url');
      } else {
        // Fallback: try to launch without mode specification
        FlutterBugfender.log('AboutAuthor: Fallback URL launch attempt: $url');
        await launchUrl(uri);
      }
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to launch URL: $url, Error: $e',
          StackTrace.current.toString());
      FlutterBugfender.error('Failed to launch URL: $url, Error: $e');
      FlutterBugfender.log(
          'AboutAuthor: Failed to launch URL: $url, Error: $e');
    }
  }
}
