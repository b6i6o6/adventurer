use strict;
use warnings;
use HTML::TreeBuilder::XPath;

my ( $quest_id, $section, $name, $locale, $race, $class ) = @ARGV;

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

my $url = "http://$prefix.wowhead.com/quest=$quest_id";
my $root = HTML::TreeBuilder::XPath->new_from_url($url);

my $text = $root->findnodes("//*[contains(\@id, \'$section\')]");

$text =~ s/\.(\w)/\. $1/g;    # <br> do not generate spaces
$text =~ s/<race>/$race/g;
$text =~ s/<class>/$class/g;
$text =~ s/<name>/$name/g;

print "$text\n";
