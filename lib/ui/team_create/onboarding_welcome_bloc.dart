import 'package:code/data/_shared_prefs.dart';
import 'package:code/domain/account/i_account_repository.dart';
import 'package:code/domain/common_db/i_common_dao.dart';
import 'package:code/ui/_base/bloc_base.dart';
import 'package:code/ui/_base/bloc_error_handler.dart';
import 'package:code/ui/_base/bloc_loading.dart';
import 'package:rxdart/rxdart.dart';
import 'package:code/utils/extensions.dart';

class OnboardingWelcomeBloC extends BaseBloC
    with LoadingBloC, ErrorHandlerBloC {
  final SharedPreferencesManager _prefs;
  final ICommonDao _iCommonDao;
  final IAccountRepository _iAccountRepository;

  OnboardingWelcomeBloC(this._prefs,
      this._iCommonDao, this._iAccountRepository);

  BehaviorSubject<bool> _logoutController = new BehaviorSubject();

  Stream<bool> get logoutResult => _logoutController.stream;

  BehaviorSubject<String> _userEmailController = new BehaviorSubject();

  Stream<String> get userEmailResult => _userEmailController.stream;

  @override
  void dispose() {
    _userEmailController.close();
    disposeLoadingBloC();
    disposeErrorHandlerBloC();
  }

  void init() async {
    _userEmailController.sinkAddSafe(await _prefs.getStringValue(_prefs.email));
  }

  void logout() async {
//    await _prefs.setStringValue(_prefs.password, "");
    isLoading = true;
    try {
      //await _ifcmFeature.deactivateToken();
      //_irtcManager.sendWssPresence(UserPresence.offline);
      await _iAccountRepository.logout();
      await _prefs.setStringValue(_prefs.userId, "");
      await _prefs.setStringValue(_prefs.email, "");
      await _prefs.setStringValue(_prefs.accessToken, "");
      await _prefs.setStringValue(_prefs.refreshToken, "");
      await _prefs.setStringValue(_prefs.wss, "");
      await _prefs.setStringValue(_prefs.currentChatId, "");
      await _prefs.setStringValue(_prefs.currentTeamId, "");
      await _prefs.setStringValue(_prefs.currentTeamName, "");
      await _prefs.setStringValue(_prefs.currentTeamCname, "");
      await _prefs.setStringValue(_prefs.displayName, "");
      await _prefs.setBoolValue(_prefs.audioMuted, false);
      await _prefs.setBoolValue(_prefs.videoMuted, false);
      await _prefs.setBoolValue(_prefs.dontShowAgain, false);
      await _iCommonDao.cleanDB();
      _logoutController.sinkAddSafe(true);
    } catch (ex) {
      _logoutController.sinkAddSafe(true);
    }
    isLoading = false;
  }
}
