import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cypher_sheet/components/box.dart';
import 'package:cypher_sheet/components/text.dart';
import 'package:cypher_sheet/proto/character.pb.dart';
import 'package:cypher_sheet/state/providers/import.dart';
import 'package:cypher_sheet/state/providers/storage.dart';
import 'package:cypher_sheet/state/providers/style.dart';
import 'package:cypher_sheet/state/storage/file.dart';
import 'package:cypher_sheet/state/storage/storage.dart';
import 'package:cypher_sheet/views/import_character_selection.dart';
import 'package:cypher_sheet/views/scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cypher_sheet/state/observer.dart';
import 'package:cypher_sheet/views/characters.dart';
import 'package:cypher_sheet/views/character_sheet/view.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uri_to_file/uri_to_file.dart';

void main() async {
  late CharacterStorage storage;
  if (kIsWeb) {
    throw UnsupportedError("Web is not supported");
  } else {
    storage = LocalCharacterStorage();
  }
  runApp(ProviderScope(
    overrides: [
      storageProvider.overrideWith((ref) => storage),
    ],
    observers: [Persister(storage)],
    child: const CypherSheetApp(),
  ));
}

class CypherSheetApp extends ConsumerStatefulWidget {
  const CypherSheetApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CypherSheetAppState();
}

class _CypherSheetAppState extends ConsumerState<CypherSheetApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb && Platform.isAndroid) {
      // For sharing coming from outside the app while the app is in the memory
      _intentDataStreamSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen((List<SharedMediaFile> value) {
        log("received media stream");
        importMediaFile(value);
      }, onError: (err) {
        log("getIntentDataStream error: $err");
      });

      // For sharing coming from outside the app while the app is closed
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((List<SharedMediaFile> value) {
        log("received initial media");
        importMediaFile(value);
      });
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isAndroid) {
      _intentDataStreamSubscription.cancel();
    }
    super.dispose();
  }

  void importMediaFile(List<SharedMediaFile> value) {
    if (value.isEmpty) {
      log("Empty list of files");
      return;
    }
    if (value.length != 1) {
      log("Can't open more than one file");
      return;
    }
    log("opening shared media: ${value.first.path}");
    importUri(value.first.path);
  }

  void importUri(String? uri) {
    if (uri == null) {
      log("Empty uri");
      return;
    }

    if (uri.startsWith("content://")) {
      importContentUri(uri);
      return;
    }

    final file = File(uri);
    importFile(file);
  }

  void importContentUri(String uri) async {
    try {
      File file = await toFile(uri);
      importFile(file);
    } on UnsupportedError catch (e) {
      log(e.message ?? "$e");
    } on IOException catch (e) {
      log("$e");
    } catch (e) {
      log("$e");
    }
  }

  void importFile(File file) {
    if (ref.read(importActiveProvider)) {
      log("import already ongoing, skipping");
      return;
    }
    ref.read(importActiveProvider.notifier).state = true;

    final raw = file.readAsBytesSync();
    final obj = SharedObject.fromBuffer(raw);
    file.deleteSync();
    ref.read(importObjectProvider.notifier).state = obj;
    ReceiveSharingIntent.instance.reset();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color.fromRGBO(25, 25, 25, 1),
      colorScheme: ThemeData.dark(useMaterial3: true).colorScheme.copyWith(
            primary: ref.watch(colorProvider) ??
                const Color.fromRGBO(75, 149, 236, 1.0),
            surface: const Color.fromARGB(255, 52, 52, 52),
            surfaceVariant: const Color.fromRGBO(87, 87, 87, 1),
            surfaceTint: const Color.fromARGB(255, 30, 30, 30),
            error: const Color.fromARGB(255, 189, 73, 73),
            onSurface: Colors.white,
          ),
    );

    const charactersView = CharactersView();
    final routes = {
      "/": (context) => charactersView,
      routeCharacters: (context) => charactersView,
      routeCharacter: (context) => const CharacterSheetView(),
      routeImportSelectCharacter: (context) =>
          const ImportCharacterSelectionView(),
    };

    return MaterialApp(
      title: 'Cypher Sheet',
      theme: baseTheme.copyWith(
          appBarTheme: AppBarTheme.of(context).copyWith(
            backgroundColor: baseTheme.scaffoldBackgroundColor,
          ),
          textTheme: GoogleFonts.robotoTextTheme(baseTheme.textTheme).copyWith(
            displayLarge: TextStyle(
                color: baseTheme.colorScheme.primary,
                fontSize: 40,
                letterSpacing: 0.0),
            displayMedium: const TextStyle(fontSize: 22),
            displaySmall:
                TextStyle(color: baseTheme.colorScheme.primary, fontSize: 16),
            bodyLarge: const TextStyle(fontSize: 30, height: 1),
            bodyMedium: const TextStyle(fontSize: 26, height: .94),
            bodySmall: const TextStyle(fontSize: 20, height: 1),
            labelLarge: const TextStyle(
                fontSize: 18, height: 1, fontWeight: FontWeight.w400),
            labelMedium: const TextStyle(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w400,
            ),
            labelSmall: const TextStyle(fontSize: 12, height: 1),
          ),
          buttonTheme: baseTheme.buttonTheme.copyWith(
            alignedDropdown: false,
          )),
      initialRoute: "/characters",
      onGenerateRoute: (settings) {
        final route = routes[settings.name];
        if (route == null) {
          log("route not found: $settings");
          return MaterialPageRoute(builder: (_) => const UnknownPage());
        }
        return MaterialPageRoute(
          settings: settings,
          builder: route,
        );
      },
      routes: routes,
    );
  }
}

const String routeCharacters = "/characters";
const String routeCharacter = "/character";
const String routeImportSelectCharacter = "/import/select_character";

class UnknownPage extends StatelessWidget {
  const UnknownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
        body: Column(
      children: [
        const AppText("Unknown Page"),
        const AppText(
            "This should not happen, please report the issue to app-feedback@kwiesmueller.dev"),
        AppBox(
            onTap: () {
              Navigator.of(context).pushReplacementNamed(routeCharacters);
            },
            child: const AppText("Back to start"))
      ],
    ));
  }
}
