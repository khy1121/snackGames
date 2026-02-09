import 'package:flutter/material.dart';
import '../dice/dice_theme.dart';
import '../services/game_data_service.dart';

class ThemeShopDialog extends StatefulWidget {
  const ThemeShopDialog({super.key});

  @override
  State<ThemeShopDialog> createState() => _ThemeShopDialogState();
}

class _ThemeShopDialogState extends State<ThemeShopDialog> {
  late String _selectedThemeId;
  late List<String> _ownedThemes;
  late int _userPoints;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _selectedThemeId = GameDataService.getSelectedTheme();
      _ownedThemes = GameDataService.getOwnedThemes();
      _userPoints = GameDataService.getPoints();
    });
  }

  void _handleThemeAction(DiceThemeData theme) {
    final isOwned = _ownedThemes.contains(theme.id);
    final isSelected = _selectedThemeId == theme.id;

    if (isSelected) return; // Already equipped

    if (isOwned) {
      // Equip
      GameDataService.setTheme(theme.id);
      _refreshData();
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${theme.name} Applied!')),
      );
    } else {
      // Buy
      if (_userPoints >= theme.price) {
        GameDataService.addPoints(-theme.price);
        GameDataService.addTheme(theme.id);
        
        // Auto equip after buy
        GameDataService.setTheme(theme.id);
        
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${theme.name} Purchased & Applied!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough points! Play more games to earn points.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = DiceTheme.getAllThemes();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: 600,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'Theme Shop',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$_userPoints P',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            // Theme Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final theme = themes[index];
                  final isOwned = _ownedThemes.contains(theme.id);
                  final isSelected = _selectedThemeId == theme.id;
                  
                  return _buildThemeCard(theme, isOwned, isSelected);
                },
              ),
            ),
            
            // Close Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(DiceThemeData theme, bool isOwned, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        gradient: theme.backgroundGradient,
        borderRadius: BorderRadius.circular(16),
        border: isSelected 
            ? Border.all(color: Colors.greenAccent, width: 3)
            : Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Mini Board Representation
                 Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.boardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                 ),
                 // Theme Icon / Dice Preview
                 Container(
                   width: 40,
                   height: 40,
                   decoration: BoxDecoration(
                     color: theme.diceColors[0],
                     borderRadius: BorderRadius.circular(8),
                   ),
                 ),
                 if (isSelected)
                   const Positioned(
                     top: 8,
                     right: 8,
                     child: Icon(Icons.check_circle, color: Colors.greenAccent),
                   ),
              ],
            ),
          ),
          
          // Info Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  theme.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleThemeAction(theme),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected 
                          ? Colors.grey 
                          : isOwned ? const Color(0xFF6C5CE7) : const Color(0xFF00B894),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    child: Text(
                      isSelected ? 'Equipped' : isOwned ? 'Equip' : '${theme.price} P',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
