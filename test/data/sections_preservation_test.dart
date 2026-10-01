import 'dart:convert';
import 'dart:io';

import 'package:aldhakereen/data/data_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards how a section survives document replacement.
///
/// The reported bug: the prophets tree doorway vanished from the home page
/// and never showed in the drawer; only right after clearing the app data it
/// was visible for a few seconds. The section ships in the bundle, but a
/// cloud document fetched before it shipped (or a cached copy of that older
/// document) replaced the device document as a whole, and both the drawer
/// (driven by `sections`) and the home card (which needs non-empty entries)
/// lost it. These tests drive the real [DataManager] entry points and require
/// the section to survive every adoption path — and to self-heal afterwards.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> treeDescriptor() => <String, dynamic>{
        'title': 'شجرة الأنبياء والأئمة',
        'icon': 'account_tree',
        'color': '0xFFD4AF37',
        'visible_home': true,
        'home_card': true,
      };

  List<dynamic> treeItems(String marker) => <dynamic>[
        <String, dynamic>{
          'id': '1',
          'title': 'شجرة النسب من آدم إلى خاتم الأنبياء $marker',
          'content': 'آدم $marker',
        },
        <String, dynamic>{
          'id': '2',
          'title': 'الأئمة الاثني عشر $marker',
          'content': 'الأئمة $marker',
        },
      ];

  /// A document that never carried the tree section — the shape of a cloud copy
  /// published before the section shipped.
  String documentWithoutTree({String marker = 'cloud'}) {
    return jsonEncode(<String, dynamic>{
      'sections': <String, dynamic>{
        'quran': <String, dynamic>{'title': 'القرآن الكريم'},
      },
      'content': <String, dynamic>{
        'quran': <dynamic>[],
        'sync_marker': <dynamic>[
          <String, dynamic>{'title': marker},
        ],
      },
    });
  }

  String documentWithTree() {
    return jsonEncode(<String, dynamic>{
      'sections': <String, dynamic>{'prophets_tree': treeDescriptor()},
      'content': <String, dynamic>{
        'prophets_tree': treeItems('cloud'),
      },
    });
  }

  late Directory directory;
  late File cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sections_sync_test');
    cache = File('${directory.path}/content.json');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DataManager.appBuildOverride = () async => '1.0.60+900';
    DataManager.getLocalFileOverride = () async => cache;
    DataManager.httpClient = null;
    DataManager.bundleRefresh = null;
    addTearDown(() async {
      DataManager.bundleRefresh = null;
      DataManager.appBuildOverride = null;
      DataManager.getLocalFileOverride = null;
      DataManager.httpClient = null;
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
  });

  group('cloud sync', () {
    test('an older document cannot hide a section the device carries',
        () async {
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{'prophets_tree': treeDescriptor()},
        'content': <String, dynamic>{
          'prophets_tree': treeItems('device'),
          'device_marker': <dynamic>[
            <String, dynamic>{'title': 'device'},
          ],
        },
      });

      final client = MockClient(
        (request) async => http.Response.bytes(
          utf8.encode(documentWithoutTree(marker: 'cloud')),
          200,
        ),
      );

      expect(await DataManager.syncCloudData(client: client), isTrue);

      // The rest of the incoming document is adopted as usual ...
      expect(
        DataManager.getDB()!['content']['sync_marker'][0]['title'],
        'cloud',
      );
      // ... but the section keeps its descriptor and its entries, which is
      // what the drawer and the home doorway are rendered from.
      expect(DataManager.getSections().containsKey('prophets_tree'), isTrue);
      expect(DataManager.getItems('prophets_tree'), hasLength(2));
      expect(
        DataManager.getItems('prophets_tree')[0]['title'],
        contains('device'),
      );

      // The merged document is what gets persisted, so the next launch starts
      // with the section instead of re-downloading its disappearance.
      final persisted =
          jsonDecode(await cache.readAsString()) as Map<String, dynamic>;
      expect(
        (persisted['sections'] as Map).containsKey('prophets_tree'),
        isTrue,
      );
      expect(
        (persisted['content'] as Map)['prophets_tree'],
        hasLength(2),
      );
    });

    test('a document that carries the section still updates it', () async {
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{'prophets_tree': treeDescriptor()},
        'content': <String, dynamic>{
          'prophets_tree': <dynamic>[
            <String, dynamic>{'id': '1', 'title': 'قديمة'},
          ],
        },
      });

      final client = MockClient(
        (request) async => http.Response.bytes(
          utf8.encode(documentWithTree()),
          200,
        ),
      );

      expect(await DataManager.syncCloudData(client: client), isTrue);
      final items = DataManager.getItems('prophets_tree');
      expect(items, hasLength(2));
      expect(items[0]['title'].toString(), contains('cloud'));
    });

    test('an empty section list on the device is refilled from the cloud',
        () async {
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{'prophets_tree': treeDescriptor()},
        'content': <String, dynamic>{'prophets_tree': <dynamic>[]},
      });

      final client = MockClient(
        (request) async => http.Response.bytes(
          utf8.encode(documentWithTree()),
          200,
        ),
      );

      expect(await DataManager.syncCloudData(client: client), isTrue);
      expect(DataManager.getItems('prophets_tree'), hasLength(2));
    });
  });

  group('installed build refresh', () {
    test('restores a section that the cached document lost', () async {
      // A device whose cache adopted an older cloud document: no descriptor,
      // no entries. The installed build still ships both.
      await cache.writeAsString(documentWithoutTree(marker: 'cached'));

      await DataManager.loadContent();
      expect(DataManager.getSections().containsKey('prophets_tree'), isFalse);

      await DataManager.bundleRefresh;

      expect(DataManager.getSections().containsKey('prophets_tree'), isTrue);
      expect(DataManager.getItems('prophets_tree'), isNotEmpty);
      // The cached content is otherwise untouched.
      expect(
        DataManager.getDB()!['content']['sync_marker'][0]['title'],
        'cached',
      );
      // And the restored section is persisted, so it survives the next boot
      // even before a successful cloud sync.
      final persisted =
          jsonDecode(await cache.readAsString()) as Map<String, dynamic>;
      expect(
        (persisted['sections'] as Map).containsKey('prophets_tree'),
        isTrue,
      );
    });
  });
}
