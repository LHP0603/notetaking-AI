import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/tier.dart';
import '../../domain/repositories/admin_repository.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';

class EditUserSheet extends StatefulWidget {
  final User user;

  const EditUserSheet({super.key, required this.user});

  @override
  State<EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late int _tierId;
  late String _role;
  late bool _isActive;
  late Future<List<Tier>> _tiersFuture;

  @override
  void initState() {
    super.initState();
    _tierId = widget.user.tierId;
    _role = widget.user.role.value;
    _isActive = widget.user.isActive;
    // Fetch tiers directly from repository to avoid disturbing AdminBloc UserLoaded state
    _tiersFuture = _fetchTiers();
  }

  Future<List<Tier>> _fetchTiers() async {
    // Access repository from Bloc
    final repo = context.read<AdminBloc>().adminRepository;
    final result = await repo.getTiers();
    return result.fold(
      (failure) => [], // Handle error gracefully or show empty
      (tiers) => tiers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1C2128),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Edit User Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.user.email,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Tier Dropdown
              _buildLabel('Subscription Tier'),
              const SizedBox(height: 8),
              FutureBuilder<List<Tier>>(
                future: _tiersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tiers = snapshot.data ?? [];

                  // Create menu items from fetched tiers
                  final List<DropdownMenuItem<int>> menuItems =
                      tiers.map((tier) {
                        return DropdownMenuItem(
                          value: tier.tierId,
                          child: Text('${tier.name} (Tier ${tier.tierId})'),
                        );
                      }).toList();

                  // Ensure current _tierId is in the list
                  final bool tierExists = tiers.any((t) => t.tierId == _tierId);

                  if (!tierExists) {
                    menuItems.add(
                      DropdownMenuItem(
                        value: _tierId,
                        child: Text(
                          _tierId == 0
                              ? 'Free Plan (Tier 0)'
                              : 'Current Tier (ID $_tierId)',
                          style: const TextStyle(color: Colors.amberAccent),
                        ),
                      ),
                    );
                  }

                  // Sort items by ID for better UX
                  menuItems.sort(
                    (a, b) => (a.value ?? 0).compareTo(b.value ?? 0),
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282E39),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _tierId,
                        dropdownColor: const Color(0xFF282E39),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                        ),
                        isExpanded: true,
                        items: menuItems,
                        onChanged: (val) {
                          if (val != null) setState(() => _tierId = val);
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Role Dropdown
              _buildLabel('User Role'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF282E39),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _role,
                    dropdownColor: const Color(0xFF282E39),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                    ),
                    isExpanded: true,
                    items:
                        ['USER', 'ADMIN'].map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _role = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Active Status
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF282E39),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: const Text(
                    'Account Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _isActive ? 'User can log in' : 'User access suspended',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: const Color(0xFF3B82F6),
                  tileColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    context.read<AdminBloc>().add(
      UpdateUserEvent(
        userId: widget.user.id,
        tierId: _tierId,
        role: _role,
        isActive: _isActive,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
