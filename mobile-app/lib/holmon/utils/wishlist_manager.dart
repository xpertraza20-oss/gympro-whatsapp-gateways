import 'package:shared_preferences/shared_preferences.dart';

class WishlistManager {
  static final WishlistManager instance = WishlistManager._internal();
  WishlistManager._internal();

  final List<String> _likedIds = [];
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final list = _prefs?.getStringList('liked_product_ids');
    if (list != null) {
      _likedIds.clear();
      _likedIds.addAll(list);
    }
  }

  bool isLiked(String productId) {
    return _likedIds.contains(productId);
  }

  Future<void> toggleLike(String productId) async {
    if (_likedIds.contains(productId)) {
      _likedIds.remove(productId);
    } else {
      _likedIds.add(productId);
    }
    await _prefs?.setStringList('liked_product_ids', _likedIds);
  }

  List<String> get likedIds => _likedIds;
}
