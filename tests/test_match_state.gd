# SPDX-License-Identifier: GPL-2.0-or-later
#
# MatchState is an autoload (a live singleton for the whole test run), so
# every test resets its mutable state in before_test/after_test rather than
# assuming a fresh instance — leaving round_over or friendly_fire_enabled set
# from one test would silently break unrelated tests (including real
# weapon-fire tests elsewhere in the suite) that run later in the same
# process. Signal connections are disconnected at the end of each test for
# the same reason: a lambda left connected to a long-lived singleton would
# keep firing on every later test's kills/restarts for the rest of the run.
extends GdUnitTestSuite


func before_test() -> void:
	MatchState.score_limit = 30
	MatchState.time_limit_seconds = 600.0
	MatchState.friendly_fire_enabled = false
	MatchState.result_display_seconds = 5.0
	MatchState.clear_radius = 1.5
	MatchState.team_a_score = 0
	MatchState.team_b_score = 0
	MatchState.time_remaining = MatchState.time_limit_seconds
	MatchState.round_over = false


func after_test() -> void:
	before_test()


func test_register_kill_increments_the_shooters_team_score() -> void:
	var scores := []
	var on_score_changed := func(a, b): scores.append([a, b])
	MatchState.score_changed.connect(on_score_changed)

	MatchState.register_kill(Team.A, Team.B)
	assert_int(MatchState.team_a_score).is_equal(1)
	assert_int(MatchState.team_b_score).is_equal(0)

	MatchState.register_kill(Team.B, Team.A)
	assert_int(MatchState.team_a_score).is_equal(1)
	assert_int(MatchState.team_b_score).is_equal(1)

	assert_int(scores.size()).is_equal(2)
	MatchState.score_changed.disconnect(on_score_changed)


func test_register_kill_does_not_score_a_team_kill_either_way() -> void:
	MatchState.register_kill(Team.A, Team.A)
	assert_int(MatchState.team_a_score).is_equal(0)
	assert_int(MatchState.team_b_score).is_equal(0)


func test_register_kill_is_ignored_once_the_round_is_over() -> void:
	MatchState.round_over = true
	MatchState.register_kill(Team.A, Team.B)
	assert_int(MatchState.team_a_score).is_equal(0)


func test_register_kill_emits_kill_confirmed_with_names_and_headshot_flag() -> void:
	var kills := []
	var on_kill_confirmed := func(shooter, victim, was_headshot): kills.append([shooter, victim, was_headshot])
	MatchState.kill_confirmed.connect(on_kill_confirmed)

	MatchState.register_kill(Team.A, Team.B, "Bot1", "Bot2", true)

	assert_int(kills.size()).is_equal(1)
	assert_array(kills[0]).is_equal(["Bot1", "Bot2", true])
	MatchState.kill_confirmed.disconnect(on_kill_confirmed)


func test_register_kill_does_not_emit_kill_confirmed_for_a_team_kill() -> void:
	var kills := []
	var on_kill_confirmed := func(shooter, victim, was_headshot): kills.append([shooter, victim, was_headshot])
	MatchState.kill_confirmed.connect(on_kill_confirmed)

	MatchState.register_kill(Team.A, Team.A, "Bot1", "Bot2", false)

	assert_int(kills.size()).is_equal(0)
	MatchState.kill_confirmed.disconnect(on_kill_confirmed)


func test_register_kill_does_not_emit_kill_confirmed_once_the_round_is_over() -> void:
	MatchState.round_over = true
	var kills := []
	var on_kill_confirmed := func(shooter, victim, was_headshot): kills.append([shooter, victim, was_headshot])
	MatchState.kill_confirmed.connect(on_kill_confirmed)

	MatchState.register_kill(Team.A, Team.B, "Bot1", "Bot2", false)

	assert_int(kills.size()).is_equal(0)
	MatchState.kill_confirmed.disconnect(on_kill_confirmed)


func test_reaching_score_limit_ends_the_round_for_the_scoring_team() -> void:
	MatchState.score_limit = 2
	var winners := []
	var on_round_ended := func(winning_team_id): winners.append(winning_team_id)
	MatchState.round_ended.connect(on_round_ended)

	MatchState.register_kill(Team.B, Team.A)
	assert_bool(MatchState.round_over).is_false()
	MatchState.register_kill(Team.B, Team.A)

	assert_bool(MatchState.round_over).is_true()
	assert_int(winners.size()).is_equal(1)
	assert_int(winners[0]).is_equal(Team.B)
	MatchState.round_ended.disconnect(on_round_ended)


func test_time_running_out_ends_the_round_for_the_higher_score() -> void:
	MatchState.team_a_score = 5
	MatchState.team_b_score = 2
	MatchState.time_remaining = 0.1

	var winners := []
	var on_round_ended := func(winning_team_id): winners.append(winning_team_id)
	MatchState.round_ended.connect(on_round_ended)
	MatchState._process(1.0)

	assert_bool(MatchState.round_over).is_true()
	assert_int(winners[0]).is_equal(Team.A)
	MatchState.round_ended.disconnect(on_round_ended)


func test_time_running_out_with_equal_scores_is_a_draw() -> void:
	MatchState.team_a_score = 3
	MatchState.team_b_score = 3
	MatchState.time_remaining = 0.1

	var winners := []
	var on_round_ended := func(winning_team_id): winners.append(winning_team_id)
	MatchState.round_ended.connect(on_round_ended)
	MatchState._process(1.0)

	assert_int(winners[0]).is_equal(-1)
	MatchState.round_ended.disconnect(on_round_ended)


func test_restart_round_resets_scores_timer_and_round_over_flag() -> void:
	MatchState.team_a_score = 10
	MatchState.team_b_score = 7
	MatchState.round_over = true
	MatchState.time_remaining = 0.0

	var restarted := [false]
	var on_round_restarted := func(): restarted[0] = true
	MatchState.round_restarted.connect(on_round_restarted)
	MatchState.restart_round()

	assert_int(MatchState.team_a_score).is_equal(0)
	assert_int(MatchState.team_b_score).is_equal(0)
	assert_bool(MatchState.round_over).is_false()
	assert_float(MatchState.time_remaining).is_equal(MatchState.time_limit_seconds)
	assert_bool(restarted[0]).is_true()
	MatchState.round_restarted.disconnect(on_round_restarted)


func test_restart_round_respawns_combatants_at_their_own_teams_spawn_points() -> void:
	var team_a_marker: Marker3D = auto_free(Marker3D.new())
	add_child(team_a_marker)
	team_a_marker.global_position = Vector3(5.0, 0.0, 5.0)
	team_a_marker.add_to_group(Team.spawn_group_name(Team.A))

	var team_b_marker: Marker3D = auto_free(Marker3D.new())
	add_child(team_b_marker)
	team_b_marker.global_position = Vector3(-5.0, 0.0, -5.0)
	team_b_marker.add_to_group(Team.spawn_group_name(Team.B))

	var bot: Bot = auto_free((load("res://scenes/bots/bot.tscn") as PackedScene).instantiate())
	add_child(bot)
	bot.team_id = Team.B
	bot.global_position = Vector3(100.0, 0.0, 100.0)
	bot.health.apply_damage(bot.health.max_health)
	assert_bool(bot.is_alive()).is_false()

	MatchState.restart_round()

	assert_bool(bot.is_alive()).is_true()
	assert_vector(bot.global_position).is_equal_approx(team_b_marker.global_position, Vector3(0.01, 0.01, 0.01))
