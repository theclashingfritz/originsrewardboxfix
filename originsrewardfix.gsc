#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_challenges;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_unitrigger;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/zm_tomb_utility;
#include maps/mp/_utility;
#include common_scripts/utility;

//#using_animtree( "fxanim_props_dlc4" );

main()
{
    // Only replace functions if we're playing Origins.
    if(GetDvar( "mapname" ) == "zm_tomb")
    {
        // Replace the functions we changed with the new ones with our patches.
        //replaceFunc( maps/mp/zombies/_zm_challenges::init, ::init_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::onplayerconnect, ::onplayerconnect_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::onplayerspawned, ::onplayerspawned_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::stats_init, ::stats_init_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::player_stats_init, ::player_stats_init_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::team_stats_init, ::team_stats_init_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::get_stat, ::get_stat_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::increment_stat, ::increment_stat_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::set_stat, ::set_stat_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::check_stat_complete, ::check_stat_complete_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::stat_reward_available, ::stat_reward_available_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::player_has_unclaimed_team_reward, ::player_has_unclaimed_team_reward_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::board_init, ::board_init_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::box_init, ::box_init_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::update_box_prompt, ::update_box_prompt_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::get_reward_category, ::get_reward_category_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::get_reward_stat, ::get_reward_stat_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::spawn_reward, ::spawn_reward_patch );
        replaceFunc( maps/mp/zombies/_zm_challenges::devgui_award_challenge, ::devgui_award_challenge_patch );
        
        replaceFunc( maps/mp/zm_tomb_challenges::one_inch_punch_watch_for_death, ::one_inch_punch_watch_for_death_patch );
    }
}

// _zm_challenges patches.

init_patch()
{
	level._challenges = spawnstruct();
	stats_init();
	level.a_m_challenge_boards = [];
	level.a_uts_challenge_boxes = [];
	a_m_challenge_boxes = getentarray( "challenge_box", "targetname" );
	array_thread( a_m_challenge_boxes, ::box_init );
	onplayerconnect_callback( ::onplayerconnect_patch );
	n_bits = getminbitcountfornum( 14 );
	registerclientfield( "toplayer", "challenge_complete_1", 14000, 1, "int" );
	registerclientfield( "toplayer", "challenge_complete_2", 14000, 1, "int" );
	registerclientfield( "toplayer", "challenge_complete_3", 14000, 1, "int" );
	registerclientfield( "toplayer", "challenge_complete_4", 14000, 1, "int" );
/#
	level thread challenges_devgui();
#/
}

onplayerconnect_patch() {
    assert(isplayer(self), "self was not player on onplayerconnect in _zm_challenges!");
 
    // Get and set our player index if we don't have one.
    if ( !isDefined( self.playerIndex ) )
    {
        self.playerIndex = get_open_player_index() - 1;
    }
    
    foreach ( s_stat in level._challenges.a_players[ self.playerIndex ].a_stats )
    {
        s_stat.b_display_tag = 1;
        foreach ( m_board in level.a_m_challenge_boards )
        {
            // We only show the tag for the box we're supposed to use!
            if (m_board.m_index > 0 && self.playerIndex > 3) {
                m_board showpart( s_stat.str_medal_tag );
            } else if (m_board.m_index <= 0 && self.playerIndex <= 3) {
                m_board showpart( s_stat.str_medal_tag );
            }
            m_board hidepart( s_stat.str_glow_tag );
        }
    }
    
    // Create our thread which spawns the player.
    self thread onplayerspawned_patch();
}

onplayerspawned_patch()
{
	self endon( "disconnect" );

    // Get and set our player index if we don't have one.
    if ( !isDefined( self.playerIndex ) )
    {
        self.playerIndex = get_open_player_index() - 1;
    }
    
    // Create a stub which contains our player index
    // and character index, Then reinitalize our stats.
    player_stub = spawnstruct();
    player_stub.playerIndex = self.playerIndex;
    player_stub.characterindex = self.characterindex;
    player_stats_init( player_stub );

	for ( ;; )
	{
		self waittill( "spawned_player" );
        
        foreach ( s_stat in level._challenges.a_players[ self.playerIndex ].a_stats )
		{
			while ( s_stat.b_medal_awarded && !s_stat.b_reward_claimed )
			{
                foreach ( m_board in level.a_m_challenge_boards )
				{
					self setclientfieldtoplayer( s_stat.s_parent.cf_complete, 1 );
				}
			}
		}
        foreach ( s_stat in level._challenges.s_team.a_stats )
		{
			while ( s_stat.b_medal_awarded && s_stat.a_b_player_rewarded[ self.playerIndex ] )
			{
                foreach ( m_board in level.a_m_challenge_boards )
				{
					self setclientfieldtoplayer( s_stat.s_parent.cf_complete, 1 );
				}
			}
		}
        
        self iprintln("Running Origins Reward Box Fix v1.0.0.");
        if (self.playerIndex > 4)
        {
            self iprintln("You are player " + (self.playerIndex + 1) + "!, Use the reward box at generator 6 for your rewards.");
        }
        else 
        {
            self iprintln("You are player " + (self.playerIndex + 1) + "!, Use the reward box in spawn for your rewards.");
        }
	}
}

stats_init_patch()
{
	level._challenges.a_stats = [];
	if ( isDefined( level.challenges_add_stats ) )
	{
		[[ level.challenges_add_stats ]]();
	}
    foreach ( stat in level._challenges.a_stats )
	{
		if ( isDefined( stat.fp_init_stat ) )
		{
			level thread [[ stat.fp_init_stat ]]();
		}
	}
	level._challenges.a_players = [];
	i = 0;
    // While we support up to 8 players for rewards now...
    // It's spilt between the two original boxes.
    // One at spawn, And one at Chruch.
	while ( i < 8 )
	{
        player_stub = spawnstruct();
        player_stub.playerIndex = i;
        player_stub.characterindex = i % 4;
		player_stats_init( player_stub );
		i++;
	}
	team_stats_init();
}

player_stats_init_patch( plyer )
{
    n_index = plyer.playerIndex;
    char_index = plyer.characterindex;

	a_characters = array( "d", "n", "r", "t" );
    str_character = a_characters[ char_index ];
    
    // Define the array position if it doesn't exist.
	if ( !isDefined( level._challenges.a_players[ n_index ] ) )
	{
		level._challenges.a_players[ n_index ] = spawnstruct();
		level._challenges.a_players[ n_index ].a_stats = [];
	}
    
	s_player_set = level._challenges.a_players[ n_index ];
	n_challenge_index = 1;
    foreach ( s_challenge in level._challenges.a_stats )
	{
		if ( !s_challenge.b_team )
		{
			if ( !isDefined( s_player_set.a_stats[ s_challenge.str_name ] ) )
			{
				s_player_set.a_stats[ s_challenge.str_name ] = spawnstruct();
			}
			s_stat = s_player_set.a_stats[ s_challenge.str_name ];
			s_stat.s_parent = s_challenge;
			s_stat.n_value = 0;
			s_stat.b_medal_awarded = 0;
			s_stat.b_reward_claimed = 0;
			s_stat.str_medal_tag = "j_" + str_character + "_medal_0" + n_challenge_index;
			s_stat.str_glow_tag = "j_" + str_character + "_glow_0" + n_challenge_index;
			s_stat.b_display_tag = 0;
			n_challenge_index++;
		}
	}
	s_player_set.n_completed = 0;
	s_player_set.n_medals_held = 0;
}

team_stats_init_patch( n_index )
{
	if ( !isDefined( level._challenges.s_team ) )
	{
		level._challenges.s_team = spawnstruct();
		level._challenges.s_team.a_stats = [];
	}
	s_team_set = level._challenges.s_team;
    foreach ( s_challenge in level._challenges.a_stats )
	{
		if ( s_challenge.b_team )
		{
			if ( !isDefined( s_team_set.a_stats[ s_challenge.str_name ] ) )
			{
				s_team_set.a_stats[ s_challenge.str_name ] = spawnstruct();
			}
			s_stat = s_team_set.a_stats[ s_challenge.str_name ];
			s_stat.s_parent = s_challenge;
			s_stat.n_value = 0;
			s_stat.b_medal_awarded = 0;
			s_stat.b_reward_claimed = 0;
            // We need to support up to 8 people getting the reward.
			s_stat.a_b_player_rewarded = array( 0, 0, 0, 0, 0, 0, 0, 0 );
			s_stat.str_medal_tag = "j_g_medal";
			s_stat.str_glow_tag = "j_g_glow";
			s_stat.b_display_tag = 1;
		}
	}
	s_team_set.n_completed = 0;
	s_team_set.n_medals_held = 0;
}

get_stat_patch( str_stat, player )
{
	s_parent_stat = level._challenges.a_stats[ str_stat ];

	assert( isDefined( s_parent_stat ), "Challenge stat: " + str_stat + " does not exist" );


	if ( !s_parent_stat.b_team )
	{
		assert( isDefined( player ), "Challenge stat: " + str_stat + " is a player stat, but no player passed in" );
	}

	if ( s_parent_stat.b_team )
	{
		s_stat = level._challenges.s_team.a_stats[ str_stat ];
	}
	else
	{
		s_stat = level._challenges.a_players[ player.playerIndex ].a_stats[ str_stat ];
	}
	return s_stat;
}

increment_stat_patch( str_stat, n_increment )
{
	if ( !isDefined( n_increment ) )
	{
		n_increment = 1;
	}
	s_stat = get_stat_patch( str_stat, self );
	if ( !s_stat.b_medal_awarded )
	{
		s_stat.n_value += n_increment;
		check_stat_complete_patch( s_stat );
	}
}

set_stat_patch( str_stat, n_set )
{
	s_stat = get_stat_patch( str_stat, self );
	if ( !s_stat.b_medal_awarded )
	{
		s_stat.n_value = n_set;
		check_stat_complete_patch( s_stat );
	}
}

check_stat_complete_patch( s_stat )
{
	if ( s_stat.b_medal_awarded )
	{
		return 1;
	}
	if ( s_stat.n_value >= s_stat.s_parent.n_goal )
	{
		s_stat.b_medal_awarded = 1;
		if ( s_stat.s_parent.b_team )
		{
			s_team_stats = level._challenges.s_team;
			s_team_stats.n_completed++;
			s_team_stats.n_medals_held++;
			a_players = get_players();
            foreach ( player in a_players )
			{
				player setclientfieldtoplayer( s_stat.s_parent.cf_complete, 1 );
				player playsound( "evt_medal_acquired" );
				wait_network_frame();
			}
		}
		else 
        {
            s_player_stats = level._challenges.a_players[ self.playerIndex ];
            s_player_stats.n_completed++;
            s_player_stats.n_medals_held++;
            self playsound( "evt_medal_acquired" );
            self setclientfieldtoplayer( s_stat.s_parent.cf_complete, 1 );
        }
        foreach ( m_board in level.a_m_challenge_boards )
		{
            if ( isplayer( self ) ) 
            {
                // We only show the tag for the box we're supposed to use!
                if (m_board.m_index > 0 && self.playerIndex > 3) {
                    m_board showpart( s_stat.str_glow_tag );
                }
                if (m_board.m_index <= 0 && self.playerIndex <= 3) {
                    m_board showpart( s_stat.str_glow_tag );
                }
            }
            else
            {
                m_board showpart( s_stat.str_glow_tag );
            }
		}
		if ( isplayer( self ) )
		{
			if ( ( level._challenges.a_players[ self.playerIndex ].n_completed + level._challenges.s_team.n_completed ) == level._challenges.a_stats.size )
			{
				self notify( "all_challenges_complete" );
			}
		}
        else
        {
            foreach ( player in get_players() )
            {
                if ( isDefined( player.characterindex ) )
                {
                    if ( ( level._challenges.a_players[ player.playerIndex ].n_completed + level._challenges.s_team.n_completed ) == level._challenges.a_stats.size )
                    {
                        player notify( "all_challenges_complete" );
                    }
                }
            }
        }
		wait_network_frame();
	}
}

stat_reward_available_patch( stat, player )
{
	if ( isstring( stat ) )
	{
		s_stat = get_stat_patch( stat, player );
	}
	else
	{
		// Originally this would just be set as the passed stat.
        // But in the new system. We need to get the players stat
        // instead.
        s_stat = get_stat_patch( stat.s_parent.str_name, player );
	}
	if ( !s_stat.b_medal_awarded )
	{
		return 0;
	}
	if ( s_stat.b_reward_claimed )
	{
		return 0;
	}
	if ( s_stat.s_parent.b_team && s_stat.a_b_player_rewarded[player.playerIndex] )
	{
		return 0;
	}
	return 1;
}

player_has_unclaimed_team_reward_patch()
{
    foreach ( s_stat in level._challenges.s_team.a_stats )
	{
		if ( s_stat.b_medal_awarded && !s_stat.a_b_player_rewarded[ self.playerIndex ] )
		{
			return 1;
		}
	}
	return 0;
}

board_init_patch( m_board )
{
	self.m_board = m_board;
	a_challenges = getarraykeys( level._challenges.a_stats );
	a_characters = array( "d", "n", "r", "t" );
	m_board.a_s_medal_tags = [];
    m_board.m_index = level.a_m_challenge_boards.size;
	b_team_hint_added = 0;
    for ( i = 0; i < level._challenges.a_players.size; i++ )
	{
        s_set = level._challenges.a_players[i];
		str_character = a_characters[ i % 4 ];
		n_challenge_index = 1;
        foreach ( s_stat in s_set.a_stats )
		{
			str_medal_tag = "j_" + str_character + "_medal_0" + n_challenge_index;
			str_glow_tag = "j_" + str_character + "_glow_0" + n_challenge_index;
			s_tag = spawnstruct();
			s_tag.v_origin = m_board gettagorigin( str_medal_tag );
			s_tag.s_stat = s_stat;
			s_tag.n_character_index = i % 4;
			s_tag.str_medal_tag = str_medal_tag;
			m_board.a_s_medal_tags[ m_board.a_s_medal_tags.size ] = s_tag;
			m_board hidepart( str_medal_tag );
			m_board hidepart( str_glow_tag );
			n_challenge_index++;
		}
	}
    foreach ( s_stat in level._challenges.s_team.a_stats )
	{
		str_medal_tag = "j_g_medal";
		str_glow_tag = "j_g_glow";
		s_tag = spawnstruct();
		s_tag.v_origin = m_board gettagorigin( str_medal_tag );
		s_tag.s_stat = s_stat;
		s_tag.n_character_index = 4;
		s_tag.str_medal_tag = str_medal_tag;
		m_board.a_s_medal_tags[m_board.a_s_medal_tags.size] = s_tag;
		m_board hidepart( str_glow_tag );
		b_team_hint_added = 1;
	}
	level.a_m_challenge_boards[ level.a_m_challenge_boards.size ] = m_board;
}

box_init_patch()
{
	self useanimtree( -1 );
	s_unitrigger_stub = spawnstruct();
	s_unitrigger_stub.origin = self.origin + ( 0, 0, 0 );
	s_unitrigger_stub.angles = self.angles;
	s_unitrigger_stub.radius = 64;
	s_unitrigger_stub.script_length = 64;
	s_unitrigger_stub.script_width = 64;
	s_unitrigger_stub.script_height = 64;
	s_unitrigger_stub.cursor_hint = "HINT_NOICON";
	s_unitrigger_stub.hint_string = &"";
	s_unitrigger_stub.script_unitrigger_type = "unitrigger_box_use";
	s_unitrigger_stub.prompt_and_visibility_func = ::box_prompt_and_visiblity;
	s_unitrigger_stub ent_flag_init( "waiting_for_grab" );
	s_unitrigger_stub ent_flag_init( "reward_timeout" );
	s_unitrigger_stub.b_busy = 0;
	s_unitrigger_stub.m_box = self;
	s_unitrigger_stub.b_disable_trigger = 0;
	if ( isDefined( self.script_string ) )
	{
		s_unitrigger_stub.str_location = self.script_string;
	}
	if ( isDefined( s_unitrigger_stub.m_box.target ) )
	{
		s_unitrigger_stub.m_board = getent( s_unitrigger_stub.m_box.target, "targetname" );
		s_unitrigger_stub board_init_patch( s_unitrigger_stub.m_board );
	}
	unitrigger_force_per_player_triggers( s_unitrigger_stub, 1 );
	level.a_uts_challenge_boxes[ level.a_uts_challenge_boxes.size ] = s_unitrigger_stub;
	maps/mp/zombies/_zm_unitrigger::register_static_unitrigger( s_unitrigger_stub, ::box_think );
}

update_box_prompt_patch( player )
{
	self endon("kill_trigger");
	player endon("death_or_disconnect");
	str_hint = &"";
	str_old_hint = &"";
	m_board = self.stub.m_board;
	self sethintstring(str_hint);
	while(1)
	{
		s_hint_tag = undefined;
		b_showing_stat = 0;
		self.b_can_open = 0;
		if(self.stub.b_busy) 
        {
            if(self.stub ent_flag("waiting_for_grab") || !isDefined( self.stub.player_using ) && self.stub.player_using == player)
			{
				str_hint = &"ZM_TOMB_CH_G";
			}
			else
			{
				str_hint = &"";
			}
		}
		else
		{
			str_hint = &"";
			player.s_lookat_stat = undefined;
			n_closest_dot = 0.996;
			v_eye_origin = player getplayercamerapos();
			v_eye_direction = AnglesToForward(player getplayerangles());
			foreach(s_tag in m_board.a_s_medal_tags)
			{
				if(!s_tag.s_stat.b_display_tag)
				{
					continue;
				}
				v_tag_origin = s_tag.v_origin;
				v_eye_to_tag = vectornormalize(v_tag_origin - v_eye_origin);
				n_dot = vectordot(v_eye_to_tag, v_eye_direction);
				if(n_dot > n_closest_dot)
				{
					n_closest_dot = n_dot;
					str_hint = s_tag.s_stat.s_parent.str_hint;
					s_hint_tag = s_tag;
					b_showing_stat = 1;
					self.b_can_open = 0;
					if(s_tag.n_character_index == player.characterindex || s_tag.n_character_index == 4)
					{
						player.s_lookat_stat = s_tag.s_stat;
						if(stat_reward_available_patch(s_tag.s_stat, player))
						{
							str_hint = &"ZM_TOMB_CH_S";
							b_showing_stat = 0;
							self.b_can_open = 1;
						}
					}
				}
			}
			if(str_hint == &"")
			{
				s_player = level._challenges.a_players[player.playerIndex];
				s_team = level._challenges.s_team;
				if(s_player.n_medals_held > 0 || player player_has_unclaimed_team_reward_patch())
				{
					str_hint = &"ZM_TOMB_CH_O";
					self.b_can_open = 1;
				}
				else
				{
					str_hint = &"ZM_TOMB_CH_V";
				}
			}
		}
		if(str_old_hint != str_hint)
		{
			str_old_hint = str_hint;
			self.stub.hint_string = str_hint;
			if(isdefined(s_hint_tag))
			{
				str_name = s_hint_tag.s_stat.s_parent.str_name;
				n_character_index = s_hint_tag.n_character_index;
				if(n_character_index != 4)
				{
                    s_player_stat = level._challenges.a_players[player.playerIndex].a_stats[str_name];
				}
			}
			self sethintstring(self.stub.hint_string);
		}
		wait(0.1);
	}
}

get_reward_category_patch( player, s_select_stat )
{
	if ( isDefined( s_select_stat ) || s_select_stat.s_parent.b_team && level._challenges.s_team.n_medals_held > 0 )
	{
		return level._challenges.s_team;
	}
	if ( level._challenges.a_players[ player.playerIndex ].n_medals_held > 0 )
	{
		return level._challenges.a_players[ player.playerIndex ];
	}
	return undefined;
}

get_reward_stat_patch( s_category )
{
    foreach(s_stat in s_category.a_stats)
	{
		if ( s_stat.b_medal_awarded && !s_stat.b_reward_claimed )
		{
			if(s_stat.s_parent.b_team && s_stat.a_b_player_rewarded[self.playerIndex])
			{
				continue;
			}
			return s_stat;
		}
	}
	return undefined;
}

spawn_reward_patch( player, s_select_stat )
{
	if ( isDefined( player ) )
	{
		player endon( "death_or_disconnect" );
		if ( isDefined( s_select_stat ) )
		{
			s_category = get_reward_category( player, s_select_stat );
			if ( stat_reward_available( s_select_stat, player ) )
			{
				s_stat = s_select_stat;
			}
		}
		if ( !isDefined( s_stat ) )
		{
			s_category = get_reward_category( player );
			s_stat = player get_reward_stat_patch( s_category );
		}
		if ( self [[ s_stat.s_parent.fp_give_reward ]]( player, s_stat ) )
		{
			if ( isDefined( s_stat.s_parent.cf_complete ) )
			{
				player setclientfieldtoplayer( s_stat.s_parent.cf_complete, 0 );
			}
			if ( s_stat.s_parent.b_team )
			{
				s_stat.a_b_player_rewarded[ player.playerIndex ] = 1;
				a_players = get_players();
                foreach ( player in a_players )
				{
					if ( !s_stat.a_b_player_rewarded[ player.playerIndex ] )
					{
						return;
					}
				}
			}
			s_stat.b_reward_claimed = 1;
			s_category.n_medals_held--;

		}
	}
}

devgui_award_challenge_patch( n_index )
{
/#
	if ( n_index == 4 )
	{
		s_team_stats = level._challenges.s_team;
		s_team_stats.n_completed = 1;
		s_team_stats.n_medals_held = 1;
		a_keys = getarraykeys( level._challenges.s_team.a_stats );
		s_stat = level._challenges.s_team.a_stats[ a_keys[ 0 ] ];
		s_stat.b_medal_awarded = 1;
		s_stat.b_reward_claimed = 0;
        foreach ( player in a_players )
		{
			s_stat.a_b_player_rewarded[ player.playerIndex ] = 0;
			player setclientfieldtoplayer( s_stat.s_parent.cf_complete, 1 );
		}
        foreach ( m_board in level.a_m_challenge_boards )
		{
            m_board showpart( s_stat.str_glow_tag );
		}
	}
	else
    {
    a_keys = getarraykeys( level._challenges.a_players[ 0 ].a_stats );
    }
	a_players = get_players();
    foreach ( player in a_players )
	{
		s_player_data = level._challenges.a_players[ player.playerIndex ];
		s_player_data.n_completed++;
		s_player_data.n_medals_held++;
		s_stat = s_player_data.a_stats[ a_keys[ n_index - 1 ] ];
		s_stat.b_medal_awarded = 1;
		s_stat.b_reward_claimed = 0;
		player setclientfieldtoplayer( s_stat.s_parent.cf_complete, 1 );
        foreach ( m_board in level.a_m_challenge_boards )
		{
            // We only show the tag for the box we can use!
            if (m_board.m_index > 0 && player.playerIndex > 3) {
                m_board showpart( s_stat.str_glow_tag );
            }
            if (m_board.m_index <= 0 && player.playerIndex <= 3) {
                m_board showpart( s_stat.str_glow_tag );
            }
		}
	}
#/
}

// zm_tomb_challenges patches.

one_inch_punch_watch_for_death_patch( s_stat )
{
	self endon( "disconnect" );
	self waittill( "bled_out" );
	if ( s_stat.b_reward_claimed )
	{
		s_stat.b_reward_claimed = 0;
	}
	s_stat.a_b_player_rewarded[ self.playerIndex ] = 0;
}

// Utility functions

get_open_player_index()
{
	players = get_players();
	open_player_index = 0;
	for ( i = 0; i < players.size; i++ )
	{
		if ( is_player_valid( players[ i ] ) )
		{
			open_player_index += 1;
		} 
        else 
        {
            // We ran into a open spot! Take it!
            return open_player_index;
        }
	}
    // No spot but the last option was valid.
	return open_player_index;
}