#!/usr/bin/env perl
use strict;
use warnings;
my ( $resource, $id, $locale, $name, $race, $class, $gender ) = @ARGV;

if ( !$resource or !$id ) {
    die "Please specify a resource and id.\n"
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

my $column;
my $table;
my $where = " id = $id";
if ( $resource eq 'npc') {
    $where = " entry = $id";

    if ( $locale eq 'enUS') {

        $column = "name";
        $table = "creature_template";

    } else {

        $column = "name";
        $table = "creature_template_locale";

    }

} elsif ( $resource eq 'broadcast_text') {

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

} elsif ( $resource eq 'quest_name' ) {

    if ( $locale eq 'enUS') {

        $column = "logtitle";
        $table = "quest_template";

    } else {

        $column = "logtitle";
        $table = "quest_template_locale";

    }

} elsif ( $resource eq 'quest_starter' ) {

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

} elsif ( $resource eq 'quest_ender' ) {

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

} elsif ( $resource eq 'quest_description' ) {

    if ( $locale eq 'enUS') {

        $column = "questdescription";
        $table = "quest_template";

    } else {

        $column = "questdescription";
        $table = "quest_template_locale";

    }

} elsif ( $resource eq 'quest_progress' ) {

    if ( $locale eq 'enUS') {

        $column = "completiontext";
        $table = "quest_request_items";

    } else {

        $column = "completiontext";
        $table = "quest_request_items_locale";

    }

} elsif ( $resource eq 'quest_completion' ) {

    if ( $locale eq 'enUS') {

        $column = "rewardtext";
        $table = "quest_offer_reward";

    } else {

        $column = "rewardtext";
        $table = "quest_offer_reward_locale";

    }

} else {
    die "Unrecognized resource type $resource";
}

if ( $locale ne 'enUS' ) {
    $where .= " AND locale=\'$locale\'";
}

my $cache_folder = "./Cache/$locale/$resource";
system("mkdir -p $cache_folder") unless(-d $cache_folder);
my $filename = "$cache_folder/$id";

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
        die "Error fetching $resource $id";
    }

    # Pre-substitutions
    $text =~ s/^\s+|\s+$//g;
    $text =~ s/\n+/ /g;
    $text =~ s/\$B\$B/ /gi;
    $text =~ s/</\$<\$/g;
    $text =~ s/>/\$>\$/g;

    if ( $text eq '' ) {
        die "Nothing was found for $resource $id";
    }

    open($file, '>', $filename) or die "Could not open file '$filename' $!";
    print $file "$text";

}

close $file;

my $character_folder = "./Cache/$name/$resource";
system("mkdir -p $character_folder") unless(-d $character_folder);
my $character_filename = "$character_folder/$id";

# Post-substitutions
$text =~ s/\$r/$race/gi;
$text =~ s/\$c/$class/gi;
$text =~ s/\$n/$name/gi;
if ( $gender eq 'male' ) {
    $text =~ s/\$g([\w']*):([\w']*)(?::[\w']?)?;/$1/gi;
} else {
    $text =~ s/\$g([\w']*):([\w']*)(?::[\w']?)?;/$2/gi;
}

open(my $character_file, '>', $character_filename) or die "Could not open file '$character_filename' $!";
print $character_file "$text";
close $file;

print "$text";
