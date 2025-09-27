import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/voice_note_settings_provider.dart';
import 'package:msbridge/core/models/voice_note_settings_model.dart';
import 'package:msbridge/widgets/custom_snackbar.dart';

class VoiceNoteSettingsScreen extends StatefulWidget {
  const VoiceNoteSettingsScreen({super.key});

  @override
  State<VoiceNoteSettingsScreen> createState() =>
      _VoiceNoteSettingsScreenState();
}

class _VoiceNoteSettingsScreenState extends State<VoiceNoteSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Voice Note Settings',
        backbutton: true,
        showTitle: true,
      ),
      body: Consumer<VoiceNoteSettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Format Information Card
                _buildFormatInfoCard(context, settings),
                const SizedBox(height: 24),

                // Audio Quality Section
                _buildSectionHeader(
                  context,
                  'Audio Quality',
                  LineIcons.volumeUp,
                  'Configure recording quality and file size',
                ),
                const SizedBox(height: 16),

                // Quality Presets
                _buildQualityPresets(context, settingsProvider),
                const SizedBox(height: 24),

                // Advanced Settings
                _buildSectionHeader(
                  context,
                  'Advanced Settings',
                  LineIcons.cog,
                  'Fine-tune recording parameters',
                ),
                const SizedBox(height: 16),

                _buildAdvancedSettings(context, settingsProvider, settings),
                const SizedBox(height: 24),

                // General Settings
                _buildSectionHeader(
                  context,
                  'General',
                  LineIcons.userCog,
                  'General voice note preferences',
                ),
                const SizedBox(height: 16),

                _buildGeneralSettings(context, settingsProvider, settings),
                const SizedBox(height: 24),

                // Reset Button
                _buildResetButton(context, settingsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormatInfoCard(
      BuildContext context, VoiceNoteSettingsModel settings) {
    final theme = Theme.of(context);
    final currentFormat = settings.encoder;
    final fileExtension = currentFormat.getFileExtension();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LineIcons.infoCircle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Current Recording Format',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '.$fileExtension',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentFormat.displayName,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        currentFormat.description,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can change the recording format in the Advanced Settings below. Different formats offer different quality and file size trade-offs.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityPresets(
      BuildContext context, VoiceNoteSettingsProvider provider) {
    final theme = Theme.of(context);
    final currentPreset = provider.getCurrentQualityPreset();

    return Column(
      children: AudioQuality.values.map((quality) {
        final isSelected = currentPreset == quality;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => provider.applyQualityPreset(quality),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LineIcons.checkCircle : LineIcons.circle,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quality.displayName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            quality.description,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${quality.sampleRate}Hz',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedSettings(BuildContext context,
      VoiceNoteSettingsProvider provider, VoiceNoteSettingsModel settings) {
    return Column(
      children: [
        // Audio Encoder
        _buildSettingTile(
          context,
          'Audio Format',
          'Choose the audio compression format',
          '${settings.encoder.displayName} (.${settings.encoder.getFileExtension()})',
          () => _showEncoderDialog(context, provider),
          LineIcons.file,
        ),

        const SizedBox(height: 12),

        // Sample Rate
        _buildSettingTile(
          context,
          'Sample Rate',
          'Audio samples per second (Hz)',
          '${settings.sampleRate} Hz',
          () => _showSampleRateDialog(context, provider),
          LineIcons.signal,
        ),

        const SizedBox(height: 12),

        // Bit Rate
        if (settings.encoder != VoiceNoteAudioEncoder.flac &&
            settings.encoder != VoiceNoteAudioEncoder.wav)
          _buildSettingTile(
            context,
            'Bit Rate',
            'Audio quality and file size balance',
            '${settings.bitRate ~/ 1000} kbps',
            () => _showBitRateDialog(context, provider),
            LineIcons.signal,
          ),

        if (settings.encoder != VoiceNoteAudioEncoder.flac &&
            settings.encoder != VoiceNoteAudioEncoder.wav)
          const SizedBox(height: 12),

        // Number of Channels
        _buildSettingTile(
          context,
          'Channels',
          'Mono (1) or Stereo (2) recording',
          settings.numChannels == 1 ? 'Mono' : 'Stereo',
          () => _showChannelsDialog(context, provider),
          LineIcons.volumeUp,
        ),
      ],
    );
  }

  Widget _buildGeneralSettings(
    BuildContext context,
    VoiceNoteSettingsProvider provider,
    VoiceNoteSettingsModel settings,
  ) {
    return Column(
      children: [
        // Auto Save
        _buildToggleTile(
          context,
          'Auto Save',
          'Automatically save voice notes after recording',
          settings.autoSaveEnabled,
          (value) => provider.updateAutoSave(value),
          LineIcons.save,
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    VoidCallback onTap,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LineIcons.chevronRight,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(
      BuildContext context, VoiceNoteSettingsProvider provider) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showResetDialog(context, provider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LineIcons.redo,
                  color: theme.colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reset to Defaults',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEncoderDialog(
      BuildContext context, VoiceNoteSettingsProvider provider) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Audio Format',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: VoiceNoteAudioEncoder.values.map((encoder) {
                    final isSelected = provider.settings.encoder == encoder;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            provider.updateEncoder(encoder);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? LineIcons.checkCircle
                                      : LineIcons.circle,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            encoder.displayName,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '.${encoder.getFileExtension()}',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        encoder.description,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSampleRateDialog(
      BuildContext context, VoiceNoteSettingsProvider provider) {
    final theme = Theme.of(context);
    final sampleRates = [22050, 44100, 48000, 96000];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Sample Rate',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...sampleRates.map((rate) {
              final isSelected = provider.settings.sampleRate == rate;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      provider.updateSampleRate(rate);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? LineIcons.checkCircle
                                : LineIcons.circle,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$rate Hz',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            rate <= 22050
                                ? 'Low'
                                : rate <= 44100
                                    ? 'Medium'
                                    : 'High',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showBitRateDialog(
      BuildContext context, VoiceNoteSettingsProvider provider) {
    final theme = Theme.of(context);
    final bitRates = [64000, 128000, 192000, 256000, 320000];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Bit Rate',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...bitRates.map((rate) {
              final isSelected = provider.settings.bitRate == rate;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      provider.updateBitRate(rate);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? LineIcons.checkCircle
                                : LineIcons.circle,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${rate ~/ 1000} kbps',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            rate <= 64000
                                ? 'Low'
                                : rate <= 128000
                                    ? 'Medium'
                                    : 'High',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showChannelsDialog(
      BuildContext context, VoiceNoteSettingsProvider provider) {
    final theme = Theme.of(context);
    final channels = [1, 2];
    final channelNames = ['Mono', 'Stereo'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Audio Channels',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...channels.asMap().entries.map((entry) {
              final index = entry.key;
              final channel = entry.value;
              final isSelected = provider.settings.numChannels == channel;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      provider.updateNumChannels(channel);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? LineIcons.checkCircle
                                : LineIcons.circle,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              channelNames[index],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '$channel channel${channel > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(
      BuildContext context, VoiceNoteSettingsProvider provider) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LineIcons.redo,
                color: theme.colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reset Settings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all voice note settings to their default values? This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.resetToDefaults();
              Navigator.of(context).pop();
              CustomSnackBar.show(
                context,
                'Settings reset to defaults',
                SnackBarType.success,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(
              'Reset',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
