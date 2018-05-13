use strict;
use warnings;
use HTML::TreeBuilder::XPath;

my ( $id, $section, $locale, $name, $race, $class ) = @ARGV;

if ( !$locale ) {
    $locale = 'enUS';
}
if ( !$name ) {
    $name = 'Adventurer';
}
if ( !$race ) {
    $race = 'adventurer';
}
if ( !$class ) {
    $class = 'adventurer';
}

my $prefix = 'www';
my $name_tag = '<name>';
my $race_tag = '<race>';
my $class_tag = '<class>';

if ( $locale eq 'frFR' ) {
    $prefix = 'fr';
    $class_tag = '<classe>';
} elsif ( $locale eq 'itIT') {
   $prefix = 'it';
} elsif ( $locale eq 'deDE') {
    $prefix = 'de';
    $class_tag = '<Klasse>';
} elsif ( $locale eq 'ptBR') {
    $prefix = 'pt';
} elsif ( $locale eq 'ruRU') {
    $prefix = 'ru';
} elsif ( $locale eq 'koKR') {
    $prefix = 'ko';
} elsif ( $locale eq 'esES' or $locale eq 'esMX') {
    $prefix = 'es';
    $class_tag = '<clase>';
} elsif ( $locale eq 'zhCN' or $locale eq 'znTW') {
    $prefix = 'cn';
}

my $folder_name;
if ( $section eq 'progress' ) {
    $folder_name = 'quest_progress';

} elsif ( $section eq 'completion' ) {
    $folder_name = 'quest_completion';

} elsif ( $section eq 'itemflavor') {
    $folder_name = 'itemflavor';

} elsif ( $section eq 'itemuse') {
    $folder_name = 'itemuse';

} else {
    die "Unrecognized section $section";
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
    my $type;
    if ( $section eq 'quest' ) {
        $type = 'quest';
    } else {
        $type = 'item';
    }
    my $url = "http://$prefix.wowhead.com/$type=$id";
    my $root = HTML::TreeBuilder::XPath->new_from_url($url);

    if ( $type eq 'quest' ) {
        $text = $root->findnodes("//*[contains(\@id, \'$section\')]");
        $text =~ s/([^\w' ])(\w)/$1 $2/g; # <br> do not generate spaces

    } elsif ( $type eq 'item' ) {
        if ( $section eq 'itemflavor' ) {
            $text = $root->findnodes("//*[\@class='q']");

        } elsif ( $section eq 'itemuse' ) {
            $text = $root->findnodes("//a[\@class='q2']");
        }

        $text =~ s/^"|"$//g;
        $text =~ s/^(\w)/\l$1/g;
        $text =~ s/.$//g;
    }

    if ( "$text" eq '' ) {
        die "Nothing was found for $section $id";
    }

    open($file, '>', $filename) or die "Could not open file '$filename' $!";
    print $file "$text";

}

close $file;


$text =~ s/$race_tag/$race/g;
$text =~ s/$class_tag/$class/g;
$text =~ s/$name_tag/$name/g;

print "$text";
