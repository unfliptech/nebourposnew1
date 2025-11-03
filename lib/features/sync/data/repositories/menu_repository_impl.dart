import '../../domain/repositories/menu_repository.dart';
import '../datasources/local/menu_local_ds.dart';
import '../datasources/remote/menu_remote_ds.dart';
import '../models/item_model.dart';

class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl(this._remote, this._local);

  final MenuRemoteDataSource _remote;
  final MenuLocalDataSource _local;

  @override
  Future<List<ItemModel>> pull() async {
    final items = await _remote.fetchMenu();
    await _local.saveMenu(items);
    return items;
  }

  @override
  Future<void> push(List<ItemModel> items) async {
    await _local.saveMenu(items);
    // TODO: push to remote when available.
  }
}
