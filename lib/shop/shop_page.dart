import 'package:flutter/material.dart';
import '../services/game_data_service.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  // Mock Products
  bool _isAdRemoved = false;
  int _userPoints = 0;
  List<String> _ownedThemes = [];

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'cyberpunk',
      'name': 'Cyberpunk',
      'price': 0,
      'colors': [Color(0xFF0F172A), Color(0xFF06B6D4)],
      'icon': '⚡',
    },
    {
      'id': 'korean',
      'name': '오색무늬 (Korean)',
      'price': 1000,
      'colors': [Color(0xFFC62828), Color(0xFF1565C0)],
      'icon': '🇰🇷',
    },
    {
      'id': 'western',
      'name': 'Western',
      'price': 1500,
      'colors': [Color(0xFF5D4037), Color(0xFFA1887F)],
      'icon': '🤠',
    },
    {
      'id': 'tropical',
      'name': 'Tropical',
      'price': 2000,
      'colors': [Color(0xFF2E7D32), Color(0xFF81C784)],
      'icon': '🌴',
    },
    {
      'id': 'space',
      'name': 'Space',
      'price': 3000,
      'colors': [Color(0xFF311B92), Color(0xFF673AB7)],
      'icon': '🌌',
    },
    {
      'id': 'isometric',
      'name': '3D Isometric',
      'price': 5000,
      'colors': [Color(0xFF607D8B), Color(0xFF90A4AE)],
      'icon': '🧊',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _isAdRemoved = GameDataService.isAdRemoved();
      _userPoints = GameDataService.getPoints();
      _ownedThemes = GameDataService.getOwnedThemes();
    });
  }

  // Mock Purchase
  void _purchaseAdRemoval(bool isPermanent) async {
    // 실제 결제 로직 연동 부분 (현재는 Mock)
    bool success = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛒 결제 확인'),
        content: Text(isPermanent 
          ? '광고 제거 (영구) - 9,900원\n결제하시겠습니까?' 
          : '광고 제거 (월간) - 2,500원\n구독하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('결제 (Mock)'),
          ),
        ],
      ),
    );

    if (success) {
      await GameDataService.removeAds();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 결제 완료! 광고가 제거되었습니다.')),
        );
      }
    }
  }

  void _purchaseTheme(String themeId, int price) async {
    if (_userPoints < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 포인트가 부족합니다! 열심히 게임을 플레이해보세요.')),
      );
      return;
    }

    bool success = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎨 테마 구매'),
        content: Text('포인트 $price P를 사용하여\n테마를 구매하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('구매'),
          ),
        ],
      ),
    );

    if (success) {
      await GameDataService.addPoints(-price);
      await GameDataService.addTheme(themeId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ 테마 구매 완료!')),
        );
      }
    }
  }

  void _selectTheme(String themeId) async {
    await GameDataService.setTheme(themeId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎨 테마가 적용되었습니다.')),
      );
    }
    setState(() {}); // UI 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text('STORE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: Row(
                children: [
                  const Text('P ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                  Text(
                    '$_userPoints',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Subscription / Ads
              const Text(
                '💎 PREMIUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_isAdRemoved)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'PREMIUM ACTIVATED',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildProductCard(
                        title: '광고 제거 (영구)',
                        price: '₩9,900',
                        icon: Icons.block,
                        color: const Color(0xFFE17055),
                        onTap: () => _purchaseAdRemoval(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProductCard(
                        title: '월간 구독',
                        price: '₩2,500/월',
                        icon: Icons.calendar_today,
                        color: const Color(0xFF00B894),
                        onTap: () => _purchaseAdRemoval(false),
                      ),
                    ),
                  ],
                ),
  
              const SizedBox(height: 32),
  
              // 2. Themes
              const Text(
                '🎨 THEMES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _themes.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final theme = _themes[index];
                    final isOwned = _ownedThemes.contains(theme['id']);
                    final isSelected = GameDataService.getSelectedTheme() == theme['id'];
  
                    return _buildThemeCard(theme, isOwned, isSelected);
                  },
                ),
              ),
  
               const SizedBox(height: 32),
  
              // 3. Gold / Items (Placeholder)
              const Text(
                '🎒 ITEMS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
               const SizedBox(height: 12),
               Container(
                 padding: const EdgeInsets.all(24),
                 width: double.infinity,
                 decoration: BoxDecoration(
                   color: Colors.white.withValues(alpha: 0.05),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                 ),
                 child: const Column(
                   children: [
                     Icon(Icons.construction, color: Colors.grey, size: 40),
                     SizedBox(height: 8),
                      Text(
                        'Coming Soon',
                         style: TextStyle(color: Colors.grey),
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

  Widget _buildProductCard({
    required String title,
    required String price,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme, bool isOwned, bool isSelected) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme['colors'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: isSelected 
          ? Border.all(color: Colors.white, width: 3)
          : null,
      ),
      child: Stack(
        children: [
          // Theme Preview
          Center(
            child: Text(
              theme['icon'],
              style: const TextStyle(fontSize: 48),
            ),
          ),
          
          // Info Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isSelected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'SELECTED',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else if (isOwned)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _selectTheme(theme['id']),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white,
                           foregroundColor: Colors.black,
                           padding: const EdgeInsets.symmetric(vertical: 0),
                           visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Equip', style: TextStyle(fontSize: 12)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _purchaseTheme(theme['id'], theme['price']),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFFFD700),
                           foregroundColor: Colors.black,
                           padding: const EdgeInsets.symmetric(vertical: 0),
                           visualDensity: VisualDensity.compact,
                        ),
                        child: Text('${theme['price']} P', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
