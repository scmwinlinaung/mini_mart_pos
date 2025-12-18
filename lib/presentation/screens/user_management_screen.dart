import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/logic/user/user_cubit.dart';
import '../../data/models/auth.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import '../widgets/language_selector.dart';
import '../../core/constants/app_strings.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserCubit(),
      child: const UserManagementView(),
    );
  }
}

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        title: AppStrings.userManagement,
        actions: const [
          LanguageSelector(),
        ],
      ),
      body: Row(
        children: [
          // User Form
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const UserForm(),
            ),
          ),
          const SizedBox(width: 16),
          // User List
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const UserList(),
            ),
          ),
        ],
      ),
    );
  }
}

class UserForm extends StatelessWidget {
  const UserForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.isEditing ? AppStrings.editUser : AppStrings.addNewUser,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (state.isEditing)
                  IconButton(
                    onPressed: () => context.read<UserCubit>().clearForm(),
                    icon: const Icon(Icons.close),
                    tooltip: AppStrings.cancel,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    TextFormField(
                      initialValue: state.username,
                      onChanged: (value) => context.read<UserCubit>().updateUsername(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.username,
                        hintText: AppStrings.enterUsername,
                        border: const OutlineInputBorder(),
                        errorText: state.usernameError,
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      initialValue: state.fullName,
                      onChanged: (value) => context.read<UserCubit>().updateFullName(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.fullName,
                        hintText: AppStrings.enterFullName,
                        border: const OutlineInputBorder(),
                        errorText: state.fullNameError,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      initialValue: state.email,
                      onChanged: (value) => context.read<UserCubit>().updateEmail(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.email,
                        hintText: AppStrings.enterEmail,
                        border: const OutlineInputBorder(),
                        errorText: state.emailError,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      initialValue: state.phone,
                      onChanged: (value) => context.read<UserCubit>().updatePhone(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.phoneNumber,
                        hintText: AppStrings.enterPhoneNumber,
                        border: const OutlineInputBorder(),
                        errorText: state.phoneError,
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Role
                    DropdownButtonFormField<Role>(
                      value: state.selectedRole,
                      onChanged: (role) => context.read<UserCubit>().updateRole(role!),
                      decoration: InputDecoration(
                        labelText: AppStrings.role,
                        hintText: AppStrings.selectRole,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.work),
                      ),
                      items: state.availableRoles.map((role) {
                        return DropdownMenuItem<Role>(
                          value: role,
                          child: Text(role.name.toUpperCase()),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Active Status (only for editing)
                    if (state.isEditing) ...[
                      SwitchListTile(
                        title: const Text(AppStrings.active),
                        subtitle: const Text(AppStrings.activeUserDescription),
                        value: state.isActive,
                        onChanged: (value) => context.read<UserCubit>().updateIsActive(value),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Password
                    TextFormField(
                      initialValue: state.password,
                      onChanged: (value) => context.read<UserCubit>().updatePassword(value),
                      obscureText: !state.showPassword,
                      decoration: InputDecoration(
                        labelText: state.isEditing ? AppStrings.newPassword : AppStrings.password,
                        hintText: state.isEditing ? AppStrings.enterNewPassword : AppStrings.enterPassword,
                        border: const OutlineInputBorder(),
                        errorText: state.passwordError,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () => context.read<UserCubit>().togglePasswordVisibility(),
                          icon: Icon(
                            state.showPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      // Only required for new users
                      validator: state.isEditing ? null : (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.passwordRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    if (!state.isEditing || state.password.isNotEmpty)
                      TextFormField(
                        initialValue: state.confirmPassword,
                        onChanged: (value) => context.read<UserCubit>().updateConfirmPassword(value),
                        obscureText: !state.showPassword,
                        decoration: InputDecoration(
                          labelText: AppStrings.confirmPassword,
                          hintText: AppStrings.enterConfirmPassword,
                          border: const OutlineInputBorder(),
                          errorText: state.confirmPasswordError,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => context.read<UserCubit>().togglePasswordVisibility(),
                            icon: Icon(
                              state.showPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : () => context.read<UserCubit>().saveUser(),
                        child: state.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(state.isEditing ? AppStrings.update : AppStrings.save),
                      ),
                    ),

                    // Error Message
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.read<UserCubit>().clearError(),
                              icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class UserList extends StatelessWidget {
  const UserList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Text(
                AppStrings.users,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              // Refresh Button
              IconButton(
                onPressed: () => context.read<UserCubit>().loadUsers(),
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.refresh,
              ),
            ],
          ),
        ),
        // User Table
        Expanded(
          child: BlocBuilder<UserCubit, UserState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state.users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noUsersFound,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.addFirstUser,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 16,
                  columns: [
                    DataColumn(
                      label: Text(AppStrings.fullName),
                    ),
                    DataColumn(
                      label: Text(AppStrings.username),
                    ),
                    DataColumn(
                      label: Text(AppStrings.email),
                    ),
                    DataColumn(
                      label: Text(AppStrings.role),
                    ),
                    DataColumn(
                      label: Text(AppStrings.status),
                    ),
                    DataColumn(
                      label: Text(AppStrings.actions),
                    ),
                  ],
                  rows: state.users.map((user) {
                    return DataRow(
                      color: MaterialStateProperty.all(
                        user.isActive ? Colors.white : Colors.grey.shade100,
                      ),
                      cells: [
                        DataCell(Text(user.fullName)),
                        DataCell(Text(user.username)),
                        DataCell(
                          user.email != null && user.email!.isNotEmpty
                              ? Text(user.email!)
                              : Text(
                                  AppStrings.notProvided,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getRoleColor(user.role).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              user.role.name.toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: user.isActive ? Colors.green.shade200 : Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              user.isActive ? AppStrings.active : AppStrings.inactive,
                              style: TextStyle(
                                color: user.isActive ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit Button
                              IconButton(
                                onPressed: () => context.read<UserCubit>().selectUser(user),
                                icon: const Icon(Icons.edit),
                                tooltip: AppStrings.edit,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              // Activate/Deactivate Button
                              IconButton(
                                onPressed: () {
                                  if (user.isActive) {
                                    _showDeactivateConfirmation(context, user);
                                  } else {
                                    context.read<UserCubit>().activateUser(user.id);
                                  }
                                },
                                icon: Icon(
                                  user.isActive ? Icons.block : Icons.check_circle,
                                  color: user.isActive ? Colors.orange : Colors.green,
                                ),
                                tooltip: user.isActive ? AppStrings.deactivate : AppStrings.activate,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.admin:
        return Colors.purple;
      case Role.manager:
        return Colors.blue;
      case Role.cashier:
        return Colors.green;
    }
  }

  void _showDeactivateConfirmation(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppStrings.deactivateUser),
          content: Text(AppStrings.deactivateUserConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<UserCubit>().deleteUser(user.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: Text(AppStrings.deactivate),
            ),
          ],
        );
      },
    );
  }
}