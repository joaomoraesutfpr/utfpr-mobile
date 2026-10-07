import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pb.dart';
import 'form_screen.dart';

class DetailScreen extends StatefulWidget {
  final RecordModel request;
  const DetailScreen({super.key, required this.request});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late RecordModel _r;
  late Future<List<RecordModel>> _comments;

  bool get _isOwner => _r.data['user'] == pb.authStore.record?.id;

  @override
  void initState() {
    super.initState();
    _r = widget.request;
    _comments = _loadComments();
  }

  Future<List<RecordModel>> _loadComments() => pb
      .collection('comments')
      .getFullList(filter: 'request = "${_r.id}"', sort: 'created');

    void _reloadComments() {
    setState(() {
      _comments = _loadComments();
    });
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => FormScreen(existing: _r)));
    if (changed == true) {
      try {
        final fresh = await pb.collection('requests').getOne(_r.id);
        if (mounted) setState(() => _r = fresh);
      } catch (_) {}
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir solicitação'),
        content: const Text('Tem certeza que deseja excluir esta solicitação?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await pb.collection('requests').delete(_r.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) snack(context, 'Erro ao excluir: ${errMsg(e)}');
    }
  }

  Future<void> _addComment() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo comentário'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Escreva seu comentário'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar')),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ],
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    try {
      final user = pb.authStore.record!;
      await pb.collection('comments').create(body: {
        'text': c.text.trim(),
        'request': _r.id,
        'user': user.id,
        'userName': user.data['name']?.toString() ?? user.data['email']?.toString() ?? '',
      });
      _reloadComments();
    } catch (e) {
      if (mounted) snack(context, 'Erro ao comentar: ${errMsg(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _r.data['photo']?.toString() ?? '';
    final lat = (_r.data['latitude'] as num?)?.toDouble();
    final lng = (_r.data['longitude'] as num?)?.toDouble();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addComment,
        icon: const Icon(Icons.add_comment),
        label: const Text('Comentar'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Row(children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.pop(context)),
              const Spacer(),
              if (_isOwner) ...[
                IconButton(icon: const Icon(Icons.edit), tooltip: 'Editar', onPressed: _edit),
                IconButton(icon: const Icon(Icons.delete), tooltip: 'Excluir', onPressed: _delete),
              ],
            ]),
            if (photo.isNotEmpty)
              Image.network(fileUrl(_r, photo),
                  height: 260, width: double.infinity, fit: BoxFit.cover,
                  loadingBuilder: (c, child, p) => p == null
                      ? child
                      : const SizedBox(
                          height: 260, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(height: 120, child: Center(child: Icon(Icons.broken_image)))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_r.data['title']?.toString() ?? '',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Por ${_r.data['userName'] ?? ''} • ${fmtDate(_r)}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(_r.data['description']?.toString() ?? ''),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 4),
                  Text(lat == null || lng == null
                      ? 'Sem localização'
                      : 'Lat: ${lat.toStringAsFixed(6)}  Lng: ${lng.toStringAsFixed(6)}'),
                ]),
              ]),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Comentários', style: Theme.of(context).textTheme.titleMedium),
            ),
            FutureBuilder<List<RecordModel>>(
              future: _comments,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()));
                }
                if (snap.hasError) {
                  return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erro: ${errMsg(snap.error!)}'));
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Padding(
                      padding: EdgeInsets.all(16), child: Text('Nenhum comentário ainda.'));
                }
                return Column(
                  children: list
                      .map((c) => ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(c.data['text']?.toString() ?? ''),
                            subtitle: Text('${c.data['userName'] ?? ''} • ${fmtDate(c)}'),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
