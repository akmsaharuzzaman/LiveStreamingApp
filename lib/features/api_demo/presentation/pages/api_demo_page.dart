import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../injection/injection.dart';
import '../../../../core/network/api_example_bloc.dart';

class ApiDemoPage extends StatelessWidget {
  const ApiDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocProvider(
        create: (context) => getIt<ApiExampleBloc>(),
        child: const ApiDemoBody(),
      ),
    );
  }
}

class ApiDemoBody extends StatefulWidget {
  const ApiDemoBody({super.key});

  @override
  State<ApiDemoBody> createState() => _ApiDemoBodyState();
}

class _ApiDemoBodyState extends State<ApiDemoBody> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApiExampleBloc, ApiExampleState>(
      listener: (context, state) {
        if (state is ApiExampleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is ApiExampleSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLoginSection(context, state),
                const SizedBox(height: 24),
                _buildApiCallsSection(context, state),
                const SizedBox(height: 24),
                _buildFileUploadSection(context, state),
                const SizedBox(height: 24),
                _buildFormDataSection(context, state),
                const SizedBox(height: 24),
                _buildResponseSection(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginSection(BuildContext context, ApiExampleState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authentication',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state is ApiExampleLoading
                  ? null
                  : () {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();
                      if (email.isNotEmpty && password.isNotEmpty) {
                        context.read<ApiExampleBloc>().add(
                          LoginEvent(email, password),
                        );
                      }
                    },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiCallsSection(BuildContext context, ApiExampleState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Calls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: state is ApiExampleLoading
                      ? null
                      : () {
                          context.read<ApiExampleBloc>().add(
                            const GetUserProfileEvent(),
                          );
                        },
                  child: const Text('Get User Profile'),
                ),
                ElevatedButton(
                  onPressed: state is ApiExampleLoading
                      ? null
                      : () {
                          context.read<ApiExampleBloc>().add(
                            const UpdateUserProfileEvent({
                              'name': 'John Doe',
                              'email': 'john@example.com',
                              'phone': '+1234567890',
                            }),
                          );
                        },
                  child: const Text('Update Profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection(BuildContext context, ApiExampleState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File Upload',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (state is FileUploadProgress) ...[
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: 8),
              Text(
                'Upload Progress: ${(state.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: state is ApiExampleLoading
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null && result.files.isNotEmpty) {
                            final file = File(result.files.first.path!);
                            if (context.mounted) {
                              context.read<ApiExampleBloc>().add(
                                UploadFileEvent(
                                  file,
                                  fieldName: 'profile_picture',
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Upload Single File'),
                ),
                ElevatedButton(
                  onPressed: state is ApiExampleLoading
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final files = result.files
                                .map((file) => File(file.path!))
                                .toList();
                            if (context.mounted) {
                              context.read<ApiExampleBloc>().add(
                                UploadMultipleFilesEvent(files),
                              );
                            }
                          }
                        },
                  child: const Text('Upload Multiple Files'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormDataSection(BuildContext context, ApiExampleState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state is ApiExampleLoading
                  ? null
                  : () {
                      final name = _nameController.text.trim();
                      final message = _messageController.text.trim();
                      if (name.isNotEmpty && message.isNotEmpty) {
                        context.read<ApiExampleBloc>().add(
                          SendFormDataEvent({
                            'name': name,
                            'message': message,
                            'subject': 'Contact Form',
                            'timestamp': DateTime.now().toIso8601String(),
                          }),
                        );
                      }
                    },
              child: const Text('Send Form Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseSection(ApiExampleState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (state is ApiExampleLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('Loading...')),
            ] else if (state is ApiExampleSuccess) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              Text(
                state.message,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.data != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Response Data:\n${state.data.toString()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ] else if (state is ApiExampleError) ...[
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                state.message,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const Icon(Icons.info, color: Colors.blue, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Ready to make API calls',
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
