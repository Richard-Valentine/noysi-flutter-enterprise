import 'package:code/_res/R.dart';
import 'package:code/data/_shared_prefs.dart';
import 'package:code/data/api/remote/remote_constants.dart';
import 'package:code/data/api/remote/result.dart';
import 'package:code/data/in_memory_data.dart';
import 'package:code/domain/channel/channel_model.dart';
import 'package:code/domain/channel/i_channel_repository.dart';
import 'package:code/domain/single_selection_model.dart';
import 'package:code/domain/team/i_team_repository.dart';
import 'package:code/domain/team/team_model.dart';
import 'package:code/ui/_base/bloc_base.dart';
import 'package:code/ui/_base/bloc_error_handler.dart';
import 'package:code/ui/_base/bloc_form_validator.dart';
import 'package:code/ui/_base/bloc_loading.dart';
import 'package:code/ui/invite_people/invite_peoploe_new_model_ui.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:code/utils/extensions.dart';

class InvitePeopleBloC extends BaseBloC
    with LoadingBloC, ErrorHandlerBloC, FormValidatorBloC {
  final SharedPreferencesManager _prefs;
  final IChannelRepository _iChannelRepository;
  final ITeamRepository _iTeamRepository;
  final InMemoryData inMemoryData;

  InvitePeopleBloC(this._prefs, this._iChannelRepository, this._iTeamRepository,
      this.inMemoryData);

  @override
  void dispose() {
    _initController.close();
    _invitationsSentController.close();
    disposeLoadingBloC();
    disposeErrorHandlerBloC();
  }

  BehaviorSubject<List<String>> _invitationsSentController =
      new BehaviorSubject();

  Stream<List<String>> get invitationsSentResult =>
      _invitationsSentController.stream;

  BehaviorSubject<InvitePeopleModelUI> _initController = new BehaviorSubject();

  Stream<InvitePeopleModelUI> get initResult => _initController.stream;

  void get refreshData => _initController.sinkAddSafe(invitePeopleModelUI!);

  String teamName = "";
  String teamId = "";
  InvitePeopleModelUI? invitePeopleModelUI;
  late bool inviteMembers;

  void initViewData(bool inviteMembers) async {
    this.inviteMembers = inviteMembers;
    teamId = await _prefs.getStringValue(_prefs.currentTeamId);

    List<SingleSelectionModel> languages =
        SingleSelectionModel.getLanguagesNames("es");
    invitePeopleModelUI = InvitePeopleModelUI(
        languageInvitations: languages,
        languageInvitationSelected: languages[0],
        singleInvitation: true,
        invitationMessage: "",
        inviteMany: false,
        invitePeopleEmailNameList: [
          InvitePeopleEmailNameModelUI(
            emailController: TextEditingController(),
            nameController: TextEditingController(),
          )
        ]);
    final groups = inMemoryData
        .getChannels()
        .where((element) => element.isPrivateGroup)
        .toList();
    groups.sort((c1, c2) => c1.titleFixed.toLowerCase().trim().compareTo(c2.titleFixed.toLowerCase().trim()));
    invitePeopleModelUI?.groups =
        invitePeopleModelUI!.groupsToSingleSelectionModel(groups, 0);

    _initController.sinkAddSafe(invitePeopleModelUI!);
  }

  void loadGroups() async {
    isLoading = true;
    final res = await _iChannelRepository.getChannels(teamId, type: RemoteConstants.group);
    if (res is ResultSuccess<List<ChannelModel>>) {
      invitePeopleModelUI?.groups =
          invitePeopleModelUI!.groupsToSingleSelectionModel(res.value, 0);
      if (res.value.isNotEmpty)
        invitePeopleModelUI?.selectedGroup = invitePeopleModelUI!.groups![0];
      _initController.sinkAddSafe(invitePeopleModelUI!);
    } else
      showErrorMessage(res);
    isLoading = false;
  }

  void invite(String body) async {
    final group =
        invitePeopleModelUI?.groups?.firstWhere((element) => element.isSelected);
    if (!inviteMembers && group?.index == 0) {
      invitePeopleModelUI?.groupRequired = true;
      _initController.sinkAddSafe(invitePeopleModelUI!);
    } else {
      final List<InvitationsMailModel> mails = [];

      invitePeopleModelUI?.invitePeopleEmailNameList.forEach((element) {
        mails.add(InvitationsMailModel(
            email: element.emailController.text,
            user: element.nameController.text));
      });

      final language = invitePeopleModelUI?.languageInvitations
          .firstWhere((element) => element.isSelected);

      isLoading = true;
      final res = await _iTeamRepository.invite(
          teamId,
          InvitationTeamModel(
              body: body,
              invitations: mails,
              cid: group != null && group.index > 0 ? group.id : "",
              role: inviteMembers ? "Member" : "Guest",
              language: language?.id,
              sendDate: DateTime.now().toUtc()));
      if (res is ResultSuccess<List<String>>) {
        _invitationsSentController.sinkAddSafe(res.value);
      } else{
        if((res as ResultError).code == 409){
          showErrorMessageFromString(R.string.needToVerifyAccountToInvite);
        }
      }
      isLoading = false;
    }
  }

  void addInvitationPeople() async {
    final data = _initController.valueOrNull;
    if(data != null) {
      data.invitePeopleEmailNameList.add(InvitePeopleEmailNameModelUI(
        emailController: TextEditingController(),
        nameController: TextEditingController(),
      ));
      _initController.sinkAddSafe(data);
    }
  }

  void removeInvitationPeople(InvitePeopleEmailNameModelUI model) async {
    final data = _initController.valueOrNull;
    if(data != null) {
      data.invitePeopleEmailNameList.remove(model);
      _initController.sinkAddSafe(data);
    }
  }
}
