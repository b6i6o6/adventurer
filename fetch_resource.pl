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
my $table;
my $column;
my $where = " id = $id";
if ( $type eq 'quest' ) {
    $folder_name = 'quest_description';

    if ( $locale eq 'enUS') {

        $table = "quest_template";
        $column = "questdescription";

    } else {

        $table = "quest_template_locale";
        $column = "questdescription";
    }

} elsif ( $type eq 'npc') {
    $folder_name = 'npc';
    $where = " entry = $id";

    if ( $locale eq 'enUS') {

        $table = "creature_template";
        $column = "name";

    } else {

        $table = "creature_template_locale";
        $column = "name";
    }
} elsif ( $type eq 'broadcast_text') {
    $folder_name = 'broadcast_text';

    if ( $locale eq 'enUS') {

        $table = "broadcast_text";
        $column = "COALESCE(
            NULLIF(maletext, ''),
            NULLIF(femaletext, '')
        )";

    } else {

        $table = "broadcast_text_locale";
        $column = "COALESCE(
            NULLIF(maletext_lang, ''),
            NULLIF(femaletext_lang, '')
        )";


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
    $text = `psql -t -P "footer=off" -c "
        SELECT $column
        FROM $table
        WHERE $where;
    " world`;

    if ( $? ) {
        die "Error fetching $type $id";
    }

    $text =~ s/^\s+|\s+$//g;
    $text =~ s/\$B\$B/ /g;
    $text =~ s/</\$<\$/g;
    $text =~ s/>/\$>\$/g;

    if ( $text eq '' ) {
        die "Nothing was found for $type $id";
    }

    open($file, '>', $filename) or die "Could not open file '$filename' $!";
    print $file "$text";

}

close $file;

$text =~ s/\$r/$race/g;
$text =~ s/\$c/$class/g;
$text =~ s/\$n/$name/g;
if ( $gender eq 'male' ) {
    $text =~ s/\$g(\w*):(\w*):r;/$1/g;
} else {
    $text =~ s/\$g(\w*):(\w*):r;/$2/g;
}

print "$text";
