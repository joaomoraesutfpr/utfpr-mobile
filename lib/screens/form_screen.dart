import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pb.dart';

/// Tela de cadastro (existing == null) ou edição de solicitação.
class FormScreen extends StatefulWidget {
  final RecordModel? existing;
  const FormScreen({super.key, this.existing});
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  XFile? _photo;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _title.text = widget.existing!.data['title']?.toString() ?? '';
      _desc.text = widget.existing!.data['description']?.toString() ?? '';
    }
  }

  Future<void> _takePhoto() async {
    try {
      final f = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1600);
      if (f != null) setState(() => _photo = f);
    } catch (e) {
      if (mounted) snack(context, 'Não foi possível abrir a câmera: $e');
    }
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Ative a localização do dispositivo.';
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      throw 'Permissão de localização negada.';
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _desc.text.trim().isEmpty) {
      snack(context, 'Informe título e descrição.');
      return;
    }
    if (!_editing && _photo == null) {
      snack(context, 'Tire uma foto para comprovar o ocorrido.');
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
      };
      final files = <http.MultipartFile>[];
      if (_photo != null) {
        files.add(await http.MultipartFile.fromPath('photo', _photo!.path));
      }
      if (_editing) {
        await pb.collection('requests').update(widget.existing!.id, body: body, files: files);
      } else {
        final pos = await _position();
        final user = pb.authStore.record!;
        body.addAll({
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'user': user.id,
          'userName': user.data['name']?.toString() ?? user.data['email']?.toString() ?? '',
        });
        await pb.collection('requests').create(body: body, files: files);
      }
      if (!mounted) return;
      Navigator.pop(context, true); // volta para a tela principal, que recarrega a lista
    } catch (e) {
      if (mounted) snack(context, 'Erro ao salvar: ${errMsg(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingPhoto = widget.existing?.data['photo']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(_editing ? 'Editar Solicitação' : 'Nova Solicitação'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            style: TextButton.styleFrom(
                backgroundColor: Colors.transparent, foregroundColor: Colors.black),
            child: _saving
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Cadastrar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Título', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _desc,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                  labelText: 'Descrição', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Tirar Foto'),
            ),
            const SizedBox(height: 16),
            if (_photo != null)
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_photo!.path), height: 240, fit: BoxFit.cover))
            else if (_editing && existingPhoto.isNotEmpty)
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(fileUrl(widget.existing!, existingPhoto),
                      height: 240, fit: BoxFit.cover)),
          ],
        ),
      ),
    );
  }
}
