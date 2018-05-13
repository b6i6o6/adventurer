#!/usr/bin/env perl
use strict;
use warnings;
my ( $type, $id, $locale, $name, $race, $class, $gender ) = @ARGV;

if ( !$type or !$id ) {
    die "Please specify a resource type and id.\n"
}

if ( !$name ) {
    $name = 'Adventurer';
}
if ( !$locale ) {
    $locale = 'enUS';
}
if ( !$race ) {
    $race = 'adventurer';
}
if ( !$class ) {
    $class = 'adventurer';
}
if ( !$gender ) {
    $gender = 'male';
}

my $folder_name;
my $column;
my $table;
my $where = " id = $id";
if ( $type eq 'npc') {
    $folder_name = 'npc';
    $where = " entry = $id";

    if ( $locale eq 'enUS') {

        $column = "name";
        $table = "creature_template";

    } else {

        $column = "name";
        $table = "creature_template_locale";

    }

} elsif ( $type eq 'broadcast_text') {
    $folder_name = 'broadcast_text';

    if ( $locale eq 'enUS') {

        $column = "COALESCE(
            NULLIF(maletext, ''),
            NULLIF(femaletext, '')
        )";
        $table = "broadcast_text";

    } else {

        $column = "COALESCE(
            NULLIF(maletext_lang, ''),
            NULLIF(femaletext_lang, '')
        )";
        $table = "broadcast_text_locale";

    }

} elsif ( $type eq 'quest_name' ) {
    $folder_name = 'quest_name';

    if ( $locale eq 'enUS') {

        $column = "logtitle";
        $table = "quest_template";

    } else {

        $column = "logtitle";
        $table = "quest_template_locale";

    }

} elsif ( $type eq 'quest_starter' ) {
    $folder_name = 'quest_starter';

    if ( $locale eq 'enUS') {

        $column = "TRIM(ct.name)";
        $table = "creature_queststarter cq
            JOIN creature_template ct ON ct.entry=cq.id
        ";
        $where = "cq.quest = $id"

    } else {

        $column = "TRIM(ct.name)";
        $table = "creature_queststarter cq
            JOIN creature_template_locale ct ON ct.entry=cq.id
        ";
        $where = "cq.quest = $id"

    }

} elsif ( $type eq 'quest_ender' ) {
    $folder_name = 'quest_ender';

    if ( $locale eq 'enUS') {

        $column = "TRIM(ct.name)";
        $table = "creature_questender cq
            JOIN creature_template ct ON ct.entry=cq.id
        ";
        $where = "cq.quest = $id"

    } else {

        $column = "TRIM(ct.name)";
        $table = "creature_questender cq
            JOIN creature_template_locale ct ON ct.entry=cq.id
        ";
        $where = "cq.quest = $id"

    }

} elsif ( $type eq 'quest_description' ) {
    $folder_name = 'quest_description';

    if ( $locale eq 'enUS') {

        $column = "questdescription";
        $table = "quest_template";

    } else {

        $column = "questdescription";
        $table = "quest_template_locale";

    }

} elsif ( $type eq 'quest_progress' ) {
    $folder_name = 'quest_progress';

    if ( $locale eq 'enUS') {

        $column = "completiontext";
        $table = "quest_request_items";

    } else {

        $column = "completiontext";
        $table = "quest_request_items_locale";

    }

} elsif ( $type eq 'quest_completion' ) {
    $folder_name = 'quest_completion';

    if ( $locale eq 'enUS') {

        $column = "rewardtext";
        $table = "quest_offer_reward";

    } else {

        $column = "rewardtext";
        $table = "quest_offer_reward_locale";

    }

} else {
    die "Unrecognized resource type $type";
}

if ( $locale ne 'enUS' ) {
    $where .= " AND locale=\'$locale\'";
}

my $cache_folder = "./Cache/$locale/$folder_name";
my $filename = "$cache_folder/$id";
system("mkdir -p $cache_folder") unless(-d $cache_folder);

my $file;
my $text;

if ( -e $filename ) {
    open($file, '<', $filename) or die "Could not open file '$filename' $!";
    $text = <$file>;

} else {
    $text = `psql -t -A -P "footer=off" -c "
        SELECT $column
        FROM $table
        WHERE $where;
    " world`;

    if ( $? ) {
        die "Error fetching $type $id";
    }

    $text =~ s/^\s+|\s+$//g;
    $text =~ s/\n+/ /g;
    $text =~ s/\$B\$B/ /gi;
    $text =~ s/</\$<\$/g;
    $text =~ s/>/\$>\$/g;

    if ( $text eq '' ) {
        die "Nothing was found for $type $id";
    }

    open($file, '>', $filename) or die "Could not open file '$filename' $!";
    print $file "$text";

}

close $file;

$text =~ s/\$r/$race/gi;
$text =~ s/\$c/$class/gi;
$text =~ s/\$n/$name/gi;
if ( $gender eq 'male' ) {
    $text =~ s/\$g([\w']*):([\w']*)(?::[\w']?)?;/$1/gi;
} else {
    $text =~ s/\$g([\w']*):([\w']*)(?::[\w']?)?;/$2/gi;
}

print "$text";
