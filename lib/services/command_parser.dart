import 'package:flutter/foundation.dart';

enum VoiceCommand {
  stop,
  resume,
  next,
  previous,
  favorite,
  help,
  recentlyPlayed,
  searchQuery,
}

@immutable
class CommandParseResult {
  final VoiceCommand command;
  final String? query;

  const CommandParseResult({required this.command, this.query});

  factory CommandParseResult.stop() => const CommandParseResult(command: VoiceCommand.stop);
  factory CommandParseResult.resume() => const CommandParseResult(command: VoiceCommand.resume);
  factory CommandParseResult.next() => const CommandParseResult(command: VoiceCommand.next);
  factory CommandParseResult.previous() => const CommandParseResult(command: VoiceCommand.previous);
  factory CommandParseResult.favorite() => const CommandParseResult(command: VoiceCommand.favorite);
  factory CommandParseResult.help() => const CommandParseResult(command: VoiceCommand.help);
  factory CommandParseResult.recentlyPlayed() => const CommandParseResult(command: VoiceCommand.recentlyPlayed);
  factory CommandParseResult.searchQuery(String query) => CommandParseResult(
        command: VoiceCommand.searchQuery,
        query: query,
      );

  @override
  String toString() => 'CommandParseResult(command: $command, query: $query)';
}

/// Simple command parser for Marathi and mixed Marathi-English speech commands.
///
/// Normalizes input:
/// - Trims leading/trailing spaces
/// - Converts English to lowercase
/// - Handles common variations of commands
///
/// Usage:
/// ```dart
/// final result = CommandParser.parse('थांबवा');
/// if (result.command == VoiceCommand.stop) { ... }
/// ```
class CommandParser {
  CommandParser._();

  // Stop commands (Marathi and English)
  static const Set<String> _stopCommands = {
    'थांबवा',
    'थांबव',
    'बंद करा',
    'बंद',
    'stop',
    'pause',
    'थांब',
    'हो',
  };

  // Resume commands
  static const Set<String> _resumeCommands = {
    'सुरू करा',
    'पुन्हा सुरू करा',
    'resume',
    'play',
    'चालू करा',
    'सुरू',
  };

  // Next commands
  static const Set<String> _nextCommands = {
    'पुढचे',
    'पुढचा',
    'next',
    'next song',
    'पुढे',
  };

  // Previous commands
  static const Set<String> _previousCommands = {
    'मागचे',
    'मागचा',
    'previous',
    'back',
    'मागे',
  };

  // Favorite commands
  static const Set<String> _favoriteCommands = {
    'हे जतन करा',
    'जतन करा',
    'आवडते मध्ये टाका',
    'फेवरेट मध्ये टाका',
    'save this',
    'add favorite',
    'save',
  };

  // Help commands
  static const Set<String> _helpCommands = {
    'मदत',
    'कसे वापरायचे',
    'help',
    'help me',
  };

  // Recently played commands
  static const Set<String> _recentCommands = {
    'अलीकडे ऐकलेले लावा',
    'अलीकडे ऐकलेले',
    'recent',
    'recently played',
    'मागील',
  };

  /// Parses spoken text and returns the corresponding command.
  ///
  /// Returns [CommandParseResult] with:
  /// - Appropriate [VoiceCommand] enum
  /// - Original query for searchQuery command
  static CommandParseResult parse(String text) {
    if (text.isEmpty) {
      return CommandParseResult.searchQuery(text);
    }

    // Normalize: trim and lowercase English letters
    final normalized = _normalize(text);

    // Check exact matches first (most common case)
    if (_isStopCommand(normalized)) {
      return CommandParseResult.stop();
    }
    if (_isResumeCommand(normalized)) {
      return CommandParseResult.resume();
    }
    if (_isNextCommand(normalized)) {
      return CommandParseResult.next();
    }
    if (_isPreviousCommand(normalized)) {
      return CommandParseResult.previous();
    }
    if (_isFavoriteCommand(normalized)) {
      return CommandParseResult.favorite();
    }
    if (_isHelpCommand(normalized)) {
      return CommandParseResult.help();
    }
    if (_isRecentCommand(normalized)) {
      return CommandParseResult.recentlyPlayed();
    }

    // Not a recognized command - treat as search query
    return CommandParseResult.searchQuery(text.trim());
  }

  /// Normalizes input by trimming spaces and converting English to lowercase
  static String _normalize(String text) {
    return text.trim().toLowerCase();
  }

  static bool _isStopCommand(String normalized) {
    return _stopCommands.any((cmd) => normalized == cmd || normalized.startsWith('$cmd '));
  }

  static bool _isResumeCommand(String normalized) {
    return _resumeCommands.any((cmd) => normalized == cmd || normalized.startsWith('$cmd '));
  }

  static bool _isNextCommand(String normalized) {
    return _nextCommands.any((cmd) => normalized == cmd || normalized.startsWith('$cmd '));
  }

  static bool _isPreviousCommand(String normalized) {
    return _previousCommands.any((cmd) => normalized == cmd || normalized.startsWith('$cmd '));
  }

  static bool _isFavoriteCommand(String normalized) {
    return _favoriteCommands.any((cmd) => normalized == cmd || normalized.startsWith('$cmd '));
  }

  static bool _isHelpCommand(String normalized) {
    return _helpCommands.any((cmd) => normalized == cmd || normalized.startsWith('$cmd '));
  }

  static bool _isRecentCommand(String normalized) {
    return _recentCommands.any((cmd) => normalized == cmd || normalized.startsWith('$cmd '));
  }

  /// Test function with example inputs and outputs.
  /// Can be called from debug mode to verify parsing.
  static void runTestExamples() {
    final examples = [
      // Stop commands
      ('थांबवा', VoiceCommand.stop),
      ('बंद करा', VoiceCommand.stop),
      ('stop', VoiceCommand.stop),
      ('pause', VoiceCommand.stop),
      // Resume commands
      ('सुरू करा', VoiceCommand.resume),
      ('पुन्हा सुरू करा', VoiceCommand.resume),
      ('resume', VoiceCommand.resume),
      ('play', VoiceCommand.resume),
      // Next commands
      ('पुढचे', VoiceCommand.next),
      ('next', VoiceCommand.next),
      ('next song', VoiceCommand.next),
      // Previous commands
      ('मागचे', VoiceCommand.previous),
      ('previous', VoiceCommand.previous),
      ('back', VoiceCommand.previous),
      // Favorite commands
      ('हे जतन करा', VoiceCommand.favorite),
      ('save this', VoiceCommand.favorite),
      ('add favorite', VoiceCommand.favorite),
      // Help commands
      ('मदत', VoiceCommand.help),
      ('कसे वापरायचे', VoiceCommand.help),
      ('help', VoiceCommand.help),
      // Search queries (not commands)
      ('शिवाय स्टोरी', VoiceCommand.searchQuery),
      ('महानुभव', VoiceCommand.searchQuery),
      ('play latest news', VoiceCommand.searchQuery),
      // Mixed Marathi-English
      ('play shivaji', VoiceCommand.searchQuery),
    ];

    int passed = 0;
    int failed = 0;

    for (final example in examples) {
      final result = parse(example.$1);
      if (result.command == example.$2) {
        debugPrint('✓ "${example.$1}" -> ${example.$2}');
        passed++;
      } else {
        debugPrint('✗ "${example.$1}" expected ${example.$2} but got ${result.command}');
        failed++;
      }
    }

    debugPrint('\nResults: $passed passed, $failed failed');
  }
}