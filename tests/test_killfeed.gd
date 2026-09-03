# SPDX-License-Identifier: GPL-2.0-or-later
extends GdUnitTestSuite


func test_kill_feed_line_for_a_plain_kill() -> void:
	assert_str(Killfeed.kill_feed_line("Bot1", "Bot2", false)).is_equal("Bot1 killed Bot2")


func test_kill_feed_line_for_a_headshot_kill() -> void:
	assert_str(Killfeed.kill_feed_line("Player", "Bot3", true)).is_equal("Player killed Bot3 (HS)")
