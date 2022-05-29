import 'package:code/data/_shared_prefs.dart';
import 'package:code/data/api/remote/result.dart';
import 'package:code/domain/account/i_account_repository.dart';
import 'package:code/domain/common_db/i_common_dao.dart';
import 'package:code/domain/team/i_team_repository.dart';
import 'package:code/domain/team/team_model.dart';
import 'package:code/rtc/rtc_model.dart';
import 'package:code/ui/_base/bloc_base.dart';
import 'package:code/ui/_base/bloc_error_handler.dart';
import 'package:code/ui/_base/bloc_loading.dart';
import 'package:code/utils/extensions.dart';
import 'package:rxdart/subjects.dart';

class TeamBloC extends BaseBloC with LoadingBloC, ErrorHandlerBloC {
  final ITeamRepository _iTeamRepository;
  final SharedPreferencesManager _prefs;
  final ICommonDao _iCommonDao;
  final IAccountRepository _iAccountRepository;

  TeamBloC(this._iTeamRepository, this._prefs, this._iCommonDao, this._iAccountRepository);

  BehaviorSubject<List<TeamModel>> _teamsController = new BehaviorSubject.seeded([]);

  Stream<List<TeamModel>> get teamsResult => _teamsController.stream;

  BehaviorSubject<bool> _hideLeadingController = new BehaviorSubject();

  Stream<bool> get hideLeadingResult => _hideLeadingController.stream;

  void loadData({RTCMemberDisabledEnabledModel? memberDisabled}) async {
    isLoading = true;
    final currentMemberId = await _prefs.getStringValue(_prefs.userId);
    String currentTeamId = await _prefs.getStringValue(_prefs.currentTeamId);
    if (memberDisabled != null &&
        !memberDisabled.enable &&
        memberDisabled.tid == currentTeamId &&
        memberDisabled.uid == currentMemberId) {
      await _prefs.setStringValue(_prefs.currentTeamId, "");
      await _prefs.setStringValue(_prefs.currentTeamName, "");
      await _prefs.setStringValue(_prefs.currentChatId, "");
      currentTeamId = "";
      _hideLeadingController.sinkAddSafe(true);
    }
    final teamsRes = await _iTeamRepository.getTeams();
    if (teamsRes is ResultSuccess<List<TeamModel>>) {
      if (currentTeamId.isEmpty && teamsRes.value.isNotEmpty) {
        currentTeamId = teamsRes.value[0].id;
        await _prefs.setStringValue(_prefs.currentTeamId, teamsRes.value[0].id);
        await _prefs.setStringValue(
            _prefs.currentTeamName, teamsRes.value[0].name);
      }
      if (memberDisabled != null && !memberDisabled.enable) {
        teamsRes.value
            .removeWhere((element) => element.id == memberDisabled.tid);
      }
      teamsRes.value.forEach((element) {
        element.isSelected = element.id == currentTeamId;
      });
      loadUnreadMessages(teamsRes.value);
      _teamsController.sinkAddSafe(teamsRes.value);
    }
    isLoading = false;
  }

  void doOnTeamUpdated(RTCTeamUpdated value) async {
    if(value.title?.isNotEmpty == true || value.name?.isNotEmpty == true) {
      final teams = _teamsController.valueOrNull ?? [];
      teams.forEach((element) {
        if(element.id == value.tid) {
          if(value.title?.isNotEmpty == true) {
            element.title = value.title ?? "";
          }
          if(value.name?.isNotEmpty == true) {
            element.name = value.name ?? "";
          }
        }
      });
      _teamsController.sinkAddSafe(teams);
    }
  }

  void doOnTeamDisabled(String tid) async {
    final currentTeamId = await _prefs.getStringValue(_prefs.currentTeamId);
    if (currentTeamId == tid) {
      final currentUserId = await _prefs.getStringValue(_prefs.userId);
      loadData(
          memberDisabled: RTCMemberDisabledEnabledModel(
              enable: false, tid: currentTeamId, uid: currentUserId));
    } else {
      final currentTeams = _teamsController.valueOrNull ?? [];
      currentTeams.removeWhere((element) => element.id == tid);
      _teamsController.sinkAddSafe(currentTeams);
      _iTeamRepository.getTeams();
    }
  }

  void doOnMemberDisabledEnabled(RTCMemberDisabledEnabledModel model) async {
    final currentUserId = await _prefs.getStringValue(_prefs.userId);
    final currentTeamId = await _prefs.getStringValue(_prefs.currentTeamId);
    if (currentUserId == model.uid &&
        currentTeamId == model.tid &&
        !model.enable) {
      loadData(memberDisabled: model);
    } else if (currentUserId == model.uid && currentTeamId != model.tid) {
      if (model.enable) {
        isLoading = true;
        final currentTeams = _teamsController.valueOrNull ?? [];
        final newTeam = await _iTeamRepository.getTeam(model.tid);
        if (newTeam is ResultSuccess<TeamModel>) {
          newTeam.value.isSelected = false;
          currentTeams.add(newTeam.value);
        }
        loadUnreadMessages(currentTeams);
        _teamsController.sinkAddSafe(currentTeams);
        isLoading = false;
      } else {
        final currentTeams = _teamsController.valueOrNull ?? [];
        currentTeams.removeWhere((element) => element.id == model.tid);
        _teamsController.sinkAddSafe(currentTeams);
        _iTeamRepository.getTeams();
      }
    }
  }

  void loadUnreadMessages(List<TeamModel> teams) async {
    teams.forEach((t) async {
      final res = await _iTeamRepository.teamMessagesUnreadCount(t.id);
      if (res is ResultSuccess<int>) {
        t.unreadMessagesCount = res.value;
        _teamsController.sinkAddSafe(teams);
      }
    });
  }

  Future<bool> logout() async {
    try {
      isLoading = true;
      //await _prefs.setStringValue(_prefs.password, "");
      //await _ifcmFeature.deactivateToken();
      //_irtcManager.sendWssPresence(UserPresence.offline);
      await _iAccountRepository.logout();
      await _prefs.setStringValue(_prefs.userId, "");
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
      isLoading = false;
      return true;
    } catch (ex) {
      isLoading = false;
      return true;
    }
  }

  @override
  void dispose() {
    _teamsController.close();
    _hideLeadingController.close();
    disposeLoadingBloC();
    disposeErrorHandlerBloC();
  }
}
