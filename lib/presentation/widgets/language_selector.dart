import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_mart_pos/core/bloc/language/language_event.dart';
import 'package:mini_mart_pos/core/bloc/language/language_state.dart';
import '../../core/bloc/language/language_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/language_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return DropdownButton<AppLanguage>(
          value: state.currentLanguage,
          onChanged: (AppLanguage? newLanguage) {
            if (newLanguage != null) {
              context.read<LanguageBloc>().add(ChangeLanguage(newLanguage));
            }
          },
          items: AppLanguage.values.map((language) {
            return DropdownMenuItem<AppLanguage>(
              value: language,
              child: Row(
                children: [
                  Text(
                    LanguageService.getLanguageFlag(language),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LanguageService.getLanguageDisplayName(language),
                    style: LanguageService.getTextStyle(
                      const TextStyle(fontSize: 14),
                      language,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          underline: Container(
            height: 2,
            color: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }
}

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return SegmentedButton<AppLanguage>(
          segments: [
            ButtonSegment(
              value: AppLanguage.english,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇬🇧'),
                  const SizedBox(width: 4),
                  Text(
                    'EN',
                    style: LanguageService.getTextStyle(
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      AppLanguage.english,
                    ),
                  ),
                ],
              ),
              icon: const Icon(Icons.language, size: 16),
            ),
            ButtonSegment(
              value: AppLanguage.myanmar,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇲🇲'),
                  const SizedBox(width: 4),
                  Text(
                    'မြ',
                    style: LanguageService.getTextStyle(
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      AppLanguage.myanmar,
                    ),
                  ),
                ],
              ),
              icon: const Icon(Icons.language, size: 16),
            ),
          ],
          selected: {state.currentLanguage},
          onSelectionChanged: (Set<AppLanguage> selection) {
            final newLanguage = selection.first;
            // Change language immediately
            context.read<LanguageBloc>().add(ChangeLanguage(newLanguage));

            // Force immediate UI update
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                // This ensures immediate rebuild
                (context as Element).markNeedsBuild();
              }
            });
          },
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        );
      },
    );
  }
}

class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return AlertDialog(
          title: LocalizedText(AppStrings.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLanguage.values.map((language) {
              return RadioListTile<AppLanguage>(
                title: Row(
                  children: [
                    Text(
                      LanguageService.getLanguageFlag(language),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LanguageService.getLanguageDisplayName(language),
                      style: LanguageService.getTextStyle(
                        const TextStyle(fontSize: 16),
                        language,
                      ),
                    ),
                  ],
                ),
                value: language,
                groupValue: state.currentLanguage,
                onChanged: (AppLanguage? value) {
                  if (value != null) {
                    context.read<LanguageBloc>().add(ChangeLanguage(value));
                    Navigator.of(context).pop();
                  }
                },
                activeColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: LocalizedText(AppStrings.cancel),
            ),
          ],
        );
      },
    );
  }
}

class LanguageSettingsCard extends StatelessWidget {
  const LanguageSettingsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: LocalizedText(
              AppStrings.language,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              state.getLanguageDisplayName(),
              style: LanguageService.getTextStyle(
                TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                state.currentLanguage,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const LanguageSelectorDialog(),
              );
            },
          ),
        );
      },
    );
  }
}

class LocalizedText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const LocalizedText(
    this.textKey, {
    Key? key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        // Rebuild immediately when state changes
        if (state.isLoading) {
          return Text(
            textKey, // Show the key while loading
            style: style ?? Theme.of(context).textTheme.bodyMedium,
            textAlign: textAlign,
            overflow: overflow,
            maxLines: maxLines,
          );
        }

        final text = state.getString(textKey);
        final textStyle = LanguageService.getTextStyle(
          style ?? Theme.of(context).textTheme.bodyMedium ?? TextStyle(),
          state.currentLanguage,
        );

        return Text(
          text,
          style: textStyle,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
        );
      },
    );
  }
}

// Extension methods for easy access to translations
extension BuildContextExtension on BuildContext {
  String getString(String key) {
    return read<LanguageBloc>().getString(key);
  }

  AppLanguage get currentLanguage {
    return read<LanguageBloc>().state.currentLanguage;
  }

  bool isMyanmarLanguage() {
    return currentLanguage == AppLanguage.myanmar;
  }

  bool isEnglishLanguage() {
    return currentLanguage == AppLanguage.english;
  }

  TextStyle getTextStyle(TextStyle style) {
    return LanguageService.getTextStyle(style, currentLanguage);
  }
}
