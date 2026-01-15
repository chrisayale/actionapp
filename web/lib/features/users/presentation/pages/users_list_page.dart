import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_colors.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  String _searchQuery = '';
  String _selectedRole = 'all'; // 'all', 'user', 'admin'

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des utilisateurs',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gérez les utilisateurs de votre plateforme',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 24),
          
          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textTertiaryLight,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textTertiaryLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(
                          'Tous les rôles',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'user',
                        child: Text(
                          'Utilisateurs',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text(
                          'Administrateurs',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value ?? 'all';
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 24),
          
          // Users Grid/List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellowPrimary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur: ${snapshot.error}',
                            style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: AppColors.textTertiaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun utilisateur trouvé',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter users
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = (data['email'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();
                  final displayName = (data['displayName'] ?? '').toString().toLowerCase();
                  final role = data['role'] ?? 'user';
                  
                  // Search filter
                  final matchesSearch = _searchQuery.isEmpty ||
                      email.contains(_searchQuery) ||
                      displayName.contains(_searchQuery);
                  
                  // Role filter
                  final matchesRole = _selectedRole == 'all' || role == _selectedRole;
                  
                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppColors.textTertiaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun résultat trouvé',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Responsive grid
                if (isMobile) {
                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(context, filteredDocs[index], isMobile);
                    },
                  );
                }

                // Grid view for desktop/tablet
                final crossAxisCount = isTablet ? 2 : 3;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(context, filteredDocs[index], isMobile);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, DocumentSnapshot doc, bool isMobile) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = doc.id;
    final email = data['email'] ?? data['phoneNumber'] ?? 'N/A';
    final displayName = data['displayName'] ?? 'Non renseigné';
    final role = data['role'] ?? 'user';
    final isActive = data['isActive'] ?? true;
    final photoUrl = data['photoUrl'];
    
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserActions(context, userId, data),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? AppColors.borderLight : AppColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with avatar and status
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.yellowPrimary,
                            AppColors.yellowDark,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.yellowPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: photoUrl != null && photoUrl.toString().isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                photoUrl.toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.inter(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: GoogleFonts.inter(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                    ),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.success : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'Actif' : 'Inactif',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // User Info
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'admin'
                        ? AppColors.yellowPrimary.withOpacity(0.1)
                        : AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: role == 'admin'
                          ? AppColors.yellowPrimary.withOpacity(0.3)
                          : AppColors.info.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                        size: 12,
                        color: role == 'admin' ? AppColors.yellowPrimary : AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          role == 'admin' ? 'Admin' : 'User',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: role == 'admin' ? AppColors.yellowPrimary : AppColors.info,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // View details button
                    IconButton(
                      icon: Icon(
                        Icons.visibility_rounded,
                        color: AppColors.info,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showUserDetails(context, userId, data),
                      tooltip: 'Voir les détails',
                    ),
                    // Quick toggle active
                    IconButton(
                      icon: Icon(
                        isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                        color: isActive ? AppColors.success : AppColors.textTertiaryLight,
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _toggleUserActive(userId, !isActive),
                      tooltip: isActive ? 'Désactiver' : 'Activer',
                    ),
                    // More actions
                    IconButton(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondaryLight,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showUserActions(context, userId, data),
                      tooltip: 'Plus d\'actions',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleUserActive(String userId, bool newStatus) async {
    try {
      await FirebaseService.firestore.collection('users').doc(userId).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Utilisateur activé' : 'Utilisateur désactivé',
            ),
            backgroundColor: newStatus ? AppColors.success : AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showUserActions(BuildContext context, String userId, Map<String, dynamic> userData) {
    final isActive = userData['isActive'] ?? true;
    final role = userData['role'] ?? 'user';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Text(
                'Actions utilisateur',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  // Toggle Active
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.error : AppColors.success).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                        color: isActive ? AppColors.error : AppColors.success,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      isActive ? 'Désactiver l\'utilisateur' : 'Activer l\'utilisateur',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      isActive
                          ? 'L\'utilisateur ne pourra plus se connecter'
                          : 'L\'utilisateur pourra se connecter',
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleUserActive(userId, !isActive);
                    },
                  ),
                  
                  // Change Role
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.yellowPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.yellowPrimary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Modifier le rôle',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Rôle actuel: ${role == 'admin' ? 'Administrateur' : 'Utilisateur'}',
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeRoleDialog(context, userId, role);
                    },
                  ),
                  
                  // Edit User
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: AppColors.info,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Modifier l\'utilisateur',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Modifier les informations',
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditUserDialog(context, userId, userData);
                    },
                  ),
                  
                  // Delete User
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Supprimer l\'utilisateur',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Cette action est irréversible',
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, userId, userData['displayName'] ?? userData['email'] ?? 'cet utilisateur');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, String userId, String currentRole) {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Modifier le rôle',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Voulez-vous changer le rôle de cet utilisateur de "${currentRole == 'admin' ? 'Administrateur' : 'Utilisateur'}" à "${newRole == 'admin' ? 'Administrateur' : 'Utilisateur'}" ?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _changeUserRole(userId, newRole);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellowPrimary,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirmer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    try {
      await FirebaseService.firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rôle modifié avec succès',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showEditUserDialog(BuildContext context, String userId, Map<String, dynamic> userData) {
    final displayNameController = TextEditingController(text: userData['displayName'] ?? '');
    final emailController = TextEditingController(text: userData['email'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Modifier l\'utilisateur',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: 'Nom d\'affichage',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateUser(userId, {
                'displayName': displayNameController.text.trim(),
                'email': emailController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellowPrimary,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Enregistrer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseService.firestore.collection('users').doc(userId).update(updates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur modifié avec succès'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Supprimer l\'utilisateur',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "$userName" ? Cette action est irréversible.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseService.firestore.collection('users').doc(userId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur supprimé avec succès'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showUserDetails(BuildContext context, String userId, Map<String, dynamic> userData) {
    final email = userData['email'] ?? userData['phoneNumber'] ?? 'N/A';
    final displayName = userData['displayName'] ?? 'Non renseigné';
    final role = userData['role'] ?? 'user';
    final isActive = userData['isActive'] ?? true;
    final photoUrl = userData['photoUrl'];
    final phoneNumber = userData['phoneNumber'] ?? 'Non renseigné';
    final gender = userData['gender'] ?? 'Non renseigné';
    final dateOfBirth = userData['dateOfBirth'];
    final createdAt = userData['createdAt'] as Timestamp?;
    final updatedAt = userData['updatedAt'] as Timestamp?;
    final lastLoginAt = userData['lastLoginAt'] as Timestamp?;
    final profileComplete = userData['profileComplete'] ?? false;
    
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email[0].toUpperCase();

    String formatDate(Timestamp? timestamp) {
      if (timestamp == null) return 'Non renseigné';
      try {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        return 'Non renseigné';
      }
    }

    String formatDateTime(Timestamp? timestamp) {
      if (timestamp == null) return 'Non renseigné';
      try {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return 'Non renseigné';
      }
    }

    showDialog(
      context: context,
      barrierColor: AppColors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Header with Gradient
              Container(
                padding: const EdgeInsets.fromLTRB(32, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(AppColors.yellowPrimary, AppColors.white, 0.15) ?? AppColors.yellowLight,
                      AppColors.white,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Avatar with Ring
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.yellowPrimary,
                                AppColors.yellowDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.yellowPrimary.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: photoUrl != null && photoUrl.toString().isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    photoUrl.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          initial,
                                          style: GoogleFonts.inter(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.inter(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                        ),
                        // Status indicator ring
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.success : AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isActive ? AppColors.success : AppColors.error).withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.alternate_email_rounded,
                                size: 16,
                                color: AppColors.textTertiaryLight,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  email,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.success.withOpacity(0.12)
                                      : AppColors.error.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.success.withOpacity(0.3)
                                        : AppColors.error.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive ? AppColors.success : AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActive ? 'Actif' : 'Inactif',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isActive ? AppColors.success : AppColors.error,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: role == 'admin'
                                      ? AppColors.yellowPrimary.withOpacity(0.12)
                                      : AppColors.info.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: role == 'admin'
                                        ? AppColors.yellowPrimary.withOpacity(0.3)
                                        : AppColors.info.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                      size: 14,
                                      color: role == 'admin' ? AppColors.yellowPrimary : AppColors.info,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      role == 'admin' ? 'Administrateur' : 'Utilisateur',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: role == 'admin' ? AppColors.yellowPrimary : AppColors.info,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Profile Complete Badge
                              if (profileComplete)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.success.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Profil complet',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
              
              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.yellowPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.yellowPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Informations personnelles',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                        iconColor: AppColors.info,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: phoneNumber,
                        iconColor: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.wc_rounded,
                        label: 'Genre',
                        value: gender == 'M' ? 'Masculin' : gender == 'F' ? 'Féminin' : gender,
                        iconColor: AppColors.warning,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.cake_outlined,
                        label: 'Date de naissance',
                        value: formatDate(dateOfBirth),
                        iconColor: AppColors.yellowPrimary,
                      ),
                      const SizedBox(height: 32),
                      
                      // Account Information Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_circle_outlined,
                              color: AppColors.info,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Informations du compte',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date de création',
                        value: formatDateTime(createdAt),
                        iconColor: AppColors.info,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.update_outlined,
                        label: 'Dernière mise à jour',
                        value: formatDateTime(updatedAt),
                        iconColor: AppColors.warning,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.login_outlined,
                        label: 'Dernière connexion',
                        value: formatDateTime(lastLoginAt),
                        iconColor: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.fingerprint_outlined,
                        label: 'ID Utilisateur',
                        value: userId,
                        iconColor: AppColors.textSecondaryLight,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Premium Footer
              Container(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondaryLight,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showUserEstablishments(context, userId, displayName);
                      },
                      icon: const Icon(Icons.store_rounded, size: 18),
                      label: Text(
                        'Établissements',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        side: BorderSide(
                          color: AppColors.info.withOpacity(0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Fermer',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showUserActions(context, userId, userData);
                          },
                          icon: const Icon(Icons.settings_rounded, size: 18),
                          label: Text(
                            'Actions',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellowPrimary,
                            foregroundColor: AppColors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadowColor: AppColors.yellowPrimary.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.15),
                  iconColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiaryLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: isMonospace ? 0.5 : 0,
                    fontFeatures: isMonospace ? [const FontFeature.tabularFigures()] : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserEstablishments(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      barrierColor: AppColors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(32, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.info.withOpacity(0.1),
                      AppColors.white,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: AppColors.info,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Établissements',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Établissements liés à $userName',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.firestore
                      .collection('establishments')
                      .where('userId', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erreur: ${snapshot.error}',
                                style: GoogleFonts.inter(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.store_outlined,
                                  size: 48,
                                  color: AppColors.textTertiaryLight,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Aucun établissement',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cet utilisateur n\'a pas encore créé d\'établissement',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final establishments = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(32),
                      itemCount: establishments.length,
                      itemBuilder: (context, index) {
                        final doc = establishments[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Sans nom';
                        final address = data['address'] ?? 'Adresse non renseignée';
                        final phone = data['phone'] ?? 'Non renseigné';
                        final email = data['email'] ?? 'Non renseigné';
                        final category = data['category'] ?? 'Non renseigné';
                        final isActive = data['isActive'] ?? true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.info,
                                                AppColors.info.withOpacity(0.7),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.info.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.store_rounded,
                                            color: AppColors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimaryLight,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isActive
                                                          ? AppColors.success.withOpacity(0.12)
                                                          : AppColors.error.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: isActive
                                                            ? AppColors.success.withOpacity(0.3)
                                                            : AppColors.error.withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: BoxDecoration(
                                                            color: isActive ? AppColors.success : AppColors.error,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          isActive ? 'Actif' : 'Inactif',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: isActive ? AppColors.success : AppColors.error,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                category,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondaryLight,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildEstablishmentInfo(
                                            icon: Icons.location_on_outlined,
                                            value: address,
                                            iconColor: AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildEstablishmentInfo(
                                            icon: Icons.phone_outlined,
                                            value: phone,
                                            iconColor: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (email.isNotEmpty && email != 'Non renseigné') ...[
                                      const SizedBox(height: 12),
                                      _buildEstablishmentInfo(
                                        icon: Icons.email_outlined,
                                        value: email,
                                        iconColor: AppColors.info,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondaryLight,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Fermer',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstablishmentInfo({
    required IconData icon,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
