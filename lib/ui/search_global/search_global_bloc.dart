import 'dart:io';

import 'package:code/data/_shared_prefs.dart';
import 'package:code/data/api/remote/result.dart';
import 'package:code/data/in_memory_data.dart';
import 'package:code/domain/channel/channel_model.dart';
import 'package:code/domain/channel/i_channel_repository.dart';
import 'package:code/domain/file/file_model.dart';
import 'package:code/domain/file/i_file_repository.dart';
import 'package:code/domain/message/message_model.dart';
import 'package:code/domain/team/i_team_repository.dart';
import 'package:code/domain/team/team_model.dart';
import 'package:code/domain/user/i_user_repository.dart';
import 'package:code/domain/user/user_model.dart';
import 'package:code/rtc/rtc_manager.dart';
import 'package:code/ui/_base/bloc_base.dart';
import 'package:code/ui/_base/bloc_error_handler.dart';
import 'package:code/ui/_base/bloc_loading.dart';
import 'package:code/ui/home/home_ui_model.dart';
import 'package:code/ui/task/task_ui_model.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:rxdart/subjects.dart';
import 'package:code/utils/extensions.dart';

import '../../enums.dart';

class SearchGlobalBloC extends BaseBloC with LoadingBloC, ErrorHandlerBloC {
  final ITeamRepository _iTeamRepository;
  final SharedPreferencesManager _prefs;
  final IFileRepository _iFileRepository;
  final IChannelRepository _iChannelRepository;
  final InMemoryData inMemoryData;
  final IUserRepository _iUserRepository;

  SearchGlobalBloC(this._iTeamRepository, this._prefs, this._iFileRepository,
      this._iChannelRepository, this.inMemoryData, this._iUserRepository);

  @override
  void dispose() {
    _messagesController.close();
    _filesController.close();
    _membersController.close();
    _tasksController.close();
    _pageTabController.close();
    _createChatController.close();
    _tasksUIController.close();
    _pageTabTaskController.close();
    popToHome.close();
    disposeLoadingBloC();
    disposeErrorHandlerBloC();
  }

  BehaviorSubject<SearchMembersModel?> _membersController =
      new BehaviorSubject();

  Stream<SearchMembersModel?> get membersResult => _membersController.stream;

  BehaviorSubject<SearchFilesModel?> _filesController = new BehaviorSubject();

  Stream<SearchFilesModel?> get filesResult => _filesController.stream;

  BehaviorSubject<SearchMessagesModel?> _messagesController =
      new BehaviorSubject();

  Stream<SearchMessagesModel?> get messagesResult => _messagesController.stream;

  BehaviorSubject<SearchTasksModel> _tasksController = new BehaviorSubject();

  Stream<SearchTasksModel> get tasksResult => _tasksController.stream;

  BehaviorSubject<int> _pageTabController = new BehaviorSubject();

  Stream<int> get pageTabResult => _pageTabController.stream;

  BehaviorSubject<bool> _createChatController = new BehaviorSubject();

  Stream<bool> get createChatResult => _createChatController.stream;

  BehaviorSubject<TaskUIModel> _tasksUIController = new BehaviorSubject();

  Stream<TaskUIModel> get tasksUIResult => _tasksUIController.stream;

  BehaviorSubject<int> _pageTabTaskController = new BehaviorSubject();

  Stream<int> get pageTabTaskResult => _pageTabTaskController.stream;

  BehaviorSubject<bool> popToHome = new BehaviorSubject();

  String currentTeamId = "";
  int offsetChanel = 0;
  int offsetMember = 0;
  int offsetFile = 0;
  int offsetTask = 0;
  int offsetMessage = 0;
  String currentQuery = "";
  TaskUIModel? taskUIModel;
  int totalTasks = 0;
  int maxLoad = 25;
  bool isLoadingMessages = false;
  bool isLoadingMembers = false;
  bool isLoadingFiles = false;
  bool isLoadingTasks = false;
  int minPixelsToPullRefresh = -100;
  CancelToken? messageCancelToken;
  CancelToken? taskCancelToken;
  CancelToken? fileCancelToken;
  CancelToken? memberCancelToken;

  void initViewData() async {
    taskUIModel = TaskUIModel(
        taskSort: TaskSort.newest,
        milestone: null,
        author: null,
        allTasks: {},
        closedOffset: 0,
        openOffset: 0,
        labels: [],
        assignee: null,
        openList: [],
        closedList: []);
    currentTeamId = await _prefs.getStringValue(_prefs.currentTeamId);
    _pageTabController.sinkAddSafe(1);
  }

  void searchByQuery(String query) {
    currentQuery = query;
    if (query.trim().isNotEmpty == true){
      loadMessages(replace: true);
      loadFiles(replace: true);
      loadMembers(replace: true);
      loadTasks(replace: true);
    }
  }

  void changePageTab(int tab) async {
    _pageTabController.sinkAddSafe(tab);
    // if (tab == 1 &&
    //     (_messagesController.value?.list ?? []).isEmpty &&
    //     currentQuery.isNotEmpty) loadMessages();
    // if (tab == 2 &&
    //     (_filesController.value?.list ?? []).isEmpty &&
    //     currentQuery.isNotEmpty) loadFiles();
    // if (tab == 3 &&
    //     (_membersController.value?.list ?? []).isEmpty &&
    //     currentQuery.isNotEmpty) loadMembers();
    // if (tab == 4 &&
    //     (_tasksController.value?.list ?? []).isEmpty &&
    //     currentQuery.isNotEmpty) loadTasks();
  }

  Future<void> loadMessages({bool replace = false}) async {
    messageCancelToken?.cancel();
    offsetMessage = !replace ? offsetMessage += maxLoad : 0;
    isLoadingMessages = true;
    final res = await _iTeamRepository.searchMessages(currentTeamId,
        offset: offsetMessage,
        query: currentQuery,
        max: maxLoad, onCancelToken: (token) => messageCancelToken = token);
    if (res is ResultSuccess<SearchMessagesModel>) {
      if (offsetMessage == 0)
        _messagesController.sinkAddSafe(res.value);
      else {
        final obj = _messagesController.valueOrNull ?? SearchMessagesModel();
        obj.list.addAll(res.value.list);
        _messagesController.sinkAddSafe(obj);
      }
    } else
      showErrorMessage(res);
    isLoadingMessages = false;
  }

  Future<void> loadFiles({bool replace = false}) async {
    fileCancelToken?.cancel();
    offsetFile = !replace ? offsetFile += maxLoad : 0;
    isLoadingFiles = true;
    final res = await _iTeamRepository.searchFiles(currentTeamId,
        offset: offsetFile, query: currentQuery, max: maxLoad, onCancelToken: (token) => fileCancelToken = token);
    if (res is ResultSuccess<SearchFilesModel>) {
      if (offsetFile == 0)
        _filesController.sinkAddSafe(res.value);
      else {
        final obj = _filesController.valueOrNull ?? SearchFilesModel();
        obj.list.addAll(res.value.list);
        _filesController.sinkAddSafe(obj);
      }
    } else
      showErrorMessage(res);
    isLoadingFiles = false;
  }

  Future<void> loadMembers({bool replace = false}) async {
    memberCancelToken?.cancel();
    offsetMember = !replace ? offsetMember += maxLoad : 0;
    isLoadingMembers = true;
    final res = await _iTeamRepository.searchMembers(currentTeamId,
        offset: offsetMember, query: currentQuery, max: maxLoad, onCancelToken: (token) => memberCancelToken = token);
    if (res is ResultSuccess<SearchMembersModel>) {
      if (offsetMember == 0)
        _membersController.sinkAddSafe(res.value);
      else {
        final obj = _membersController.valueOrNull ?? SearchMembersModel();
        obj.list.addAll(res.value.list);
        _membersController.sinkAddSafe(obj);
      }
    } else
      showErrorMessage(res);
    isLoadingMembers = false;
  }

  Future<void> loadTasks({bool replace = false}) async {
    taskCancelToken?.cancel();
    offsetTask = !replace ? offsetTask += 40 : 0;
    if (offsetTask == 0) taskUIModel?.allTasks.clear();
    isLoadingTasks = true;
    final res = await _iTeamRepository.searchTasks(currentTeamId,
        offset: offsetTask, query: currentQuery, max: 40, onCancelToken: (token) => taskCancelToken = token);
    if (res is ResultSuccess<SearchTasksModel>) {
      _tasksController.sinkAddSafe(res.value);
      totalTasks = res.value.total;
      res.value.list.forEach((element) {
        taskUIModel?.allTasks[element.id] = element;
      });

      taskUIModel?.openList = taskUIModel?.opened() ?? [];
      taskUIModel?.openTotal = taskUIModel?.openList.length ?? 0;
      taskUIModel?.openTotalFiltered = taskUIModel?.openTotal ?? 0;

      taskUIModel?.closedList = taskUIModel?.closed() ?? [];
      taskUIModel?.closedTotal = taskUIModel?.closedList.length ?? 0;
      taskUIModel?.closedTotalFiltered = taskUIModel?.closedTotal ?? 0;

      _tasksUIController.sinkAddSafe(taskUIModel!);
    } else
      showErrorMessage(res);
    isLoadingTasks = false;
  }

  void downloadFile(FileModel fileModel) async {
    isLoading = true;
    final res = await _iFileRepository.downloadFile(fileModel);
    if (res is ResultSuccess<File>) {
      await OpenFile.open(res.value.path);
    }
    isLoading = false;
  }

  void create1x1Message(MemberModel memberModel) async {
    isLoading = true;
    final res = await _iChannelRepository.create1x1Channel(memberModel);
    if (res is ResultSuccess<ChannelModel>) {
      _createChatController.sinkAddSafe(true);
      changeChannelAutoController.sinkAddSafe(
          ChannelCreatedUI(members: [memberModel], channelModel: res.value));
    }
    // else
    //   showErrorMessage(res);
    isLoading = false;
  }

  void onMessageTap(MessageModel messageModel) async {
    String teamId = await _prefs.getStringValue(_prefs.currentTeamId);
    final res = await _iChannelRepository.getChannel(teamId, messageModel.cid);
    if (res is ResultSuccess<ChannelModel>) {
      popToHome.sinkAddSafe(true);
      changeChannelAutoController.sinkAddSafe(ChannelCreatedUI(
          members: [],
          channelModel: res.value,
          lastReadMessage: messageModel,
      fromSearchMessage: true));
    } else
      showErrorMessage(res);
  }

  void onMentionClicked(String username) async {
    if (username != 'channel' &&
        username != 'all' &&
        username != inMemoryData.currentMember!.profile?.name) {
      final membersInMemory = inMemoryData.getMembers(
          excludeMe: true, teamId: inMemoryData.currentTeam!.id);
      final memberIsInMemory = membersInMemory.firstWhereOrNull(
          (element) => element.profile?.name == username);
      if (memberIsInMemory == null) {
        final membersQuery = await _iUserRepository.getTeamMembers(
            inMemoryData.currentTeam!.id,
            max: 1,
            offset: 0,
            action: "search",
            active: true,
            query: username);
        if (membersQuery is ResultSuccess<MemberWrapperModel> &&
            membersQuery.value.list.isNotEmpty &&
            membersQuery.value.list[0].profile?.name == username) {
          final member = membersQuery.value.list[0];
          final res = await _iChannelRepository.create1x1Channel(member);
          if (res is ResultSuccess<ChannelModel>) {
            popToHome.sinkAddSafe(true);
            changeChannelAutoController.sinkAddSafe(
                ChannelCreatedUI(members: [member], channelModel: res.value));
          } else {
            //showErrorMessage(res);
          }
        }
      } else {
        final res =
            await _iChannelRepository.create1x1Channel(memberIsInMemory);
        if (res is ResultSuccess<ChannelModel>) {
          popToHome.sinkAddSafe(true);
          changeChannelAutoController.sinkAddSafe(ChannelCreatedUI(
              members: [memberIsInMemory], channelModel: res.value));
        } else {
          //showErrorMessage(res);
        }
      }
    }
  }

  Future<ChannelModel?> getChannelFromId(String cid) async {
    final res = await _iChannelRepository.getChannel(currentTeamId, cid);
    if(res is ResultSuccess<ChannelModel>)
      return res.value;
    return null;
  }

  int currentTaskTab = 1;

  void changeTaskPageTab(int tab) async {
    currentTaskTab = tab;
    _pageTabTaskController.sinkAddSafe(tab);
  }

//  void loadChannels({bool replace = false}) async {
//    final res = await _iTeamRepository.searchChannels(currentTeamId,
//        offset: offsetChanel, query: currentQuery, max: 100);
//    if (res is ResultSuccess<SearchChannelsModel>) {
//      totalChannel = res.value.total;
//      _channelsController.sinkAddSafe(res.value.list);
//    }
//  }
}
