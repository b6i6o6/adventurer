#!/usr/bin/env perl
use strict;
use warnings;

my $npc_id = shift @ARGV or die "Specify an npc_id";
my $text_snippet = join(' ', @ARGV);

my $type;
if ( !$type) {
    $type = 'says';
}

my $filename = '.lookup_cache';
my $offset = 5;

my $result = `psql -t -P "footer=off" -c "
    SELECT id
    FROM broadcast_text bt
    WHERE bt.maletext ILIKE '%$text_snippet%'
    OR bt.femaletext ILIKE '%$text_snippet%';
" world`;

my @ids = $result =~ /([\d]+)/g;

my $nb_matches = () = @ids;
if ( $nb_matches == 0 ) {
    die "No match for \"$text_snippet\"";
}
if ( $nb_matches > 5 ) {
    die "Too many matches ($nb_matches) for \"$text_snippet\"";
}

my $min_id;
my $max_id;
my @subsets = ();
for my $id (@ids) {
    $min_id = $id-$offset;
    $max_id = $id+$offset;
    push(@subsets, "(id >= $min_id AND id <= $max_id)");
}

my @matches = ();

for my $where (@subsets) {
    my $match = `psql -t -P "footer=off" -c "
        SELECT
            CONCAT(
                '\\$type',
                '{',
                $npc_id,
                '}{',
                bt.id,
                '}  % ',
                COALESCE(
                    NULLIF(bt.maletext, ''),
                    NULLIF(bt.femaletext, '')
                )
            )
        FROM broadcast_text bt
        JOIN creature_template c ON c.entry=$npc_id
        WHERE $where
        ORDER BY id
    " world`;

    $match =~ s/ \\/\\/g;
    $match =~ s/\$B\$B/ /g;
    push (@matches, $match);
}

my $cache = join("\n", @matches);

open(my $file, '>', $filename) or die "Could not open file '$filename' $!";
print $file "$cache";
close $file;

system("cat $filename | less -I -j5 +/\"$text_snippet\"");

# If the database was not missing a lot of creature_text records, this would do:
# my $result = `psql -t -P "footer=off" -c "
#     SELECT
#     CONCAT(
#         '\\',
#         CASE ct.type
#             WHEN 12 THEN 'says'
#             WHEN 14 THEN 'yells'
#             WHEN 15 THEN 'whispers'
#             WHEN 16 then 'emotes'
#             WHEN 41 then 'emotes'
#             WHEN 42 THEN 'whispers'
#         END,
#         '{',
#         ct.creatureid,
#         '}{',
#         ct.broadcasttextid,
#         '}  % ',
#         TRIM(c.name),
#         ': ',
#         COALESCE(
#             NULLIF(bt.maletext, ''),
#             NULLIF(bt.femaletext, '')
#         )
#     )
#     FROM creature_text ct
#     JOIN creature_template c ON c.entry=ct.creatureid
#     JOIN broadcast_text bt ON bt.id=ct.broadcasttextid
#     WHERE ct.creatureid=$npc_id
#     ORDER BY ct.broadcasttextid;
# " world`;
