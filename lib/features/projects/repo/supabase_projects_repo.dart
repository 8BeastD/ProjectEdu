import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectsRepo {
  ProjectsRepo._();
  static final instance = ProjectsRepo._();

  SupabaseClient get _client => Supabase.instance.client;

  // ---------- PROJECTS ----------
  Future<List<Map<String, dynamic>>> listProjects() async {
    final res = await _client
        .from('projects')
        .select('id,name,description,max_group_size,max_teachers_per_group,allow_cross_group_requests,deadlines,status')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> getProject(String id) async {
    final res = await _client.from('projects').select('*').eq('id', id).single();
    return Map<String, dynamic>.from(res);
  }

  Future<void> upsertProjectSettings({
    required String projectId,
    required int maxGroupSize,
    required int maxTeachersPerGroup,
    required bool allowCrossGroupRequests,
    required Map<String, dynamic> deadlines,
  }) async {
    await _client.rpc('coordinator_update_project_settings', params: {
      'p_project_id': projectId,
      'p_max_group_size': maxGroupSize,
      'p_max_teachers_per_group': maxTeachersPerGroup,
      'p_allow_cross_group_requests': allowCrossGroupRequests,
      'p_deadlines': deadlines,
    });
  }

  // ---------- GROUPS ----------
  Future<Map<String, dynamic>> createGroup({
    required String projectId,
    required String groupName,
  }) async {
    final res = await _client.rpc('create_group', params: {
      'p_project_id': projectId,
      'p_group_name': groupName,
    });
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> getGroup(String groupId) async {
    final res = await _client
        .from('groups')
        .select('id,name,status,project_id,created_by,teacher_status,teacher_decision_at,teacher_decided_by')
        .eq('id', groupId)
        .single();
    return Map<String, dynamic>.from(res);
  }

  Future<List<Map<String, dynamic>>> groupMembers(String groupId) async {
    final res = await _client
        .from('group_members')
        .select('user_id, role_in_group, joined_at, profile:directory_people(full_name,email,role)')
        .eq('group_id', groupId)
        .order('joined_at');
    return List<Map<String, dynamic>>.from(res);
  }

  // NEW: public helper to list groups by project (no private client exposure)
  Future<List<Map<String, dynamic>>> listGroupsByProject(String projectId) async {
    final res = await _client
        .from('groups')
        .select('id,name,status,created_at')
        .eq('project_id', projectId)
        .neq('status', 'rejected')
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> requestJoin(String groupId) async {
    await _client.rpc('request_join_group', params: {'p_group_id': groupId});
  }

  Future<void> approveJoinRequest({
    required String requestId,
    required bool approve,
  }) async {
    await _client.rpc('teacher_review_join_request', params: {
      'p_request_id': requestId,
      'p_approve': approve,
    });
  }

  Future<void> teacherApproveGroup({
    required String groupId,
    required bool approve,
    String? remarks,
  }) async {
    await _client.rpc('teacher_approve_group', params: {
      'p_group_id': groupId,
      'p_approve': approve,
      'p_remarks': remarks ?? '',
    });
  }

  // ---------- PROPOSALS ----------
  Future<String> submitProposal({
    required String groupId,
    required String title,
    required String abstractText,
    String? fileUrl,
  }) async {
    final res = await _client
        .from('proposals')
        .insert({
      'group_id': groupId,
      'title': title,
      'abstract': abstractText,
      'file_url': fileUrl,
      'status': 'submitted',
    })
        .select('id')
        .single();
    return res['id'] as String;
  }

  Future<List<Map<String, dynamic>>> teacherPendingGroups() async {
    final res = await _client.rpc('teacher_pending_groups');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> teacherPendingJoinRequests() async {
    final res = await _client.rpc('teacher_pending_join_requests');
    return List<Map<String, dynamic>>.from(res as List);
  }
}
