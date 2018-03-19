#!/usr/bin/env perl
my ( $section, $name ) = @ARGV;
my $quest_data = <STDIN>;

if ( lc $section eq 'debug' ) {
    print ( "$quest_data\n" );
    exit;
}

if ( !$name) {
    $name = 'Adventurer';
}

my $target_regex = qr/ *?= *[^\w]*(?:[\w ]*\|)*([\w '"]+)[^\w]/;
my $section_regex_start = qr/== */;
my $section_regex_end = qr/ *==[€]*([^(==)]*?)[€\s]*(?:==|{{rfg-section}})/;

my $type;
my $target;
if ( $section eq 'Description' or $section =~ m/Quote/ ) {
    $type = 'quest';
    $target = 'start';
    unless ( $quest_data =~ /$target${target_regex}/ ) {
        $target = 'name';
    }
} elsif ( $section eq 'Completion' or $section eq 'Progress' ) {
    $type = 'quest';
    $target = 'end';
    unless ( $quest_data =~ /$target${target_regex}/ ) {
        $target = 'start';
    }
    unless ( $quest_data =~ /${section_regex_start}$section${section_regex_end}/ ) {
        $section = 'Completed';
    }
} elsif ($section eq 'Dialogue' ) {
    $type = 'gossip';
    $target = 'end';
    unless ( $quest_data =~ /$target${target_regex}/ ) {
        $target = 'start';
    }
    unless ( $quest_data =~ /$target${target_regex}/ ) {
        $target = 'name';
    }
    unless ( $quest_data =~ /${section_regex_start}$section${section_regex_end}/ ) {
        $section = 'Quotes';
    }
} else {
    $type = 'event';
}

my ( $quest_text ) = $quest_data =~ /${section_regex_start}$section${section_regex_end}/;
my ( $quest_point ) = $quest_data =~ /$target${target_regex}/;

$quest_text =~ s/\[+([^\[\]]*\|)*([^\[\]]*)]+/\2/g;     # [[template||H|name]]
$quest_text =~ s/<race>/adventurer/g;                   # <race>
$quest_text =~ s/<class>/adventurer/g;                  # <class>
$quest_text =~ s/<name>/$name/g;                        # <name>

if ( $name eq 'debug' ) {
    print ( "$quest_text\n" );
    exit;
}

if ( $type eq 'event' ) {
    # Match and format in-game event
    while ( $quest_text =~ /:[{']+(?:text\|)?(?:([^€]*?)\|)?(?:([^€]*?)\|)?(?:'''(.*?)''')?([^€]*?)['}]+(?:€|$)/g) {
        $3 =~ s/{+([^{}]*\|)*([^{}]*)}+/\2/g;               # {{template||H|name}}
        if ( $1 and $2 ) {                                  # {{text|action|npc|text}}
            print ( $2 . ' ' . $1 . 's: ' . $4 . "\n\n");
        } elsif ( $3 ) {                                    # {{text|action|text}}
            print ( $3 . ' ' . $4 . "\n\n");
        } else {                                            # text
            print ( $4 . "\n\n");
        }
    }
} elsif ( $type eq 'gossip' ) {
    my $action;
    # while ( $quest_text =~ /[:]?(?:{{(gossip)[^\w]*)?([^€}]*)(?:''}})?€+/g) {
    # while ( $quest_text =~ /[:]?(?:'')?(?:{{(gossip)[^\w]*)?([^€}]*)(?:(?:'')?}})?(?:'')?€+/g) {
    while ( $quest_text =~ /(?:^|€)(?:[:]|(?:(?:'')?(?:{{(gossip)[^\w]*)))([^€}]*)(?:(?:'')?}})?(?:'')?€+?/g) {
        my $text = $2;
        if ( $text ) {
            if ( $text =~ m/^<.*>$/ ) {
                print "\n\n";
                $action = 'emote';
                $text =~ s/[€]*<//g;                        # [\n]*<emote>
                $text =~ s/>[€]*//g;                        # <emote>[\n]*
            } elsif ( $1 eq 'gossip' ) {
                if ( $action ne 'You say' ) {
                    print "\n\n";
                    $action = 'You say';
                    print ( $action . ': ' );
                }
            } else {
                if ( $action ne $quest_point . ' says') {
                    print "\n\n";
                    $action = $quest_point . ' says';
                    print ( $action . ': ' );
                }
            }
            $text =~ s/<br>/ /g;
            print ( $text );
        }
    }
    print "\n\n";
} else {
    # Format quest text
    $dialogue_prefix = $quest_point =~ s/(.*)/\1 says: /r;
    # $dialogue_prefix =~ s/(.*)/\\textbf{\1}/;

    $quest_text =~ s/{+([^{}]*\|)*([^{}]*)}+/\2/g;          # {{template||H|name}}
    $quest_text =~ s/^([^<])/$dialogue_prefix\1/;           # <prefix><text>
    $quest_text =~ s/([^>])€€([^<])/\1 \2/g;                # newlines to spaces
    $quest_text =~ s/[€]*</€€/g;                            # [\n]<action>
    $quest_text =~ s/>€€/€€$dialogue_prefix/g;              # <action>\n\n<prefix>
    $quest_text =~ tr/€/\n/;
    print ($quest_text);
}
