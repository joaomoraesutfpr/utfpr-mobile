import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pb.dart';
import 'detail_screen.dart';
import 'form_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<RecordModel>> _future;

  Future<List<RecordModel>> _load() =>
      pb.collection('requests').getFullList(sort: '-created');

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

    void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _go(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _reload();
  }

  void _logout() {
    pb.authStore.clear();
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: kDarkBlue,
          foregroundColor: Colors.white,
          title: const Text('Solicitações Públicas'),
          leading: IconButton(
              icon: const Icon(Icons.logout), tooltip: 'Sair', onPressed: _logout),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Adicionar',
              onPressed: () => _go(const FormScreen()),
            ),
          ],
        ),
        body: FutureBuilder<List<RecordModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Erro ao carregar: ${errMsg(snap.error!)}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _reload, child: const Text('Tentar novamente')),
                  ]),
                ),
              );
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const Center(child: Text('Ainda não há solicitações realizadas'));
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = items[i];
                  return ListTile(
                    title: Text(r.data['title']?.toString() ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(fmtDate(r)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _go(DetailScreen(request: r)),
                  );
                },
              ),
            );
          },
        ),
      );
}
