#!/usr/bin/perl

# script irssi ajoutant des outils Mountyhall sur un chan IRC.
# auteur : Krooh Tong Halaï (78402).
# date de dernière mise à jour : 11/12/2013

################################################################
# TODO list
#
# feature : ajouter la date au message s’il ne date pas du jour même
#
# bug : si quelqu’un se connecte avec un nick en [xyz], la recherche
# de matching de nick interprète à tort les parenthèses et match le
# premier nick contenant l’un des caractères x, y ou z.
################################################################

use strict;
use Irssi;
use POSIX;
# use Encode qw(encode decode);
# my $enc = 'utf-8'; # This script is stored as UTF-8
use feature 'switch';

my $mh_dir = "Terminalcity/Mountyhall/";
my @vip_chans = ("#mb3", "#testouille", "#plan_krapo");
my @active_chans = ("#mb3", "#testouille", "#mountyhall", "#verticaledesuniques", "#plan_krapo");
my $chan = "#MB3";        # the channel in which the script is active.
my ($server, $nick);
my %colors = ('NORMAL' => "\017",
              'BOLD' => "\002",
              'UNDERLINED' => "\037",
              'RED' => "\00320",
              'GREEN' => "\00309",
              'YELLOW' => "\00340",
              'WHITE' => "\00300",
              'GRAY' => "\00315");
my @fatigue_values = (4, 6, 8, 11, 14, 18, 23, 29, 37, 47, 59, 74, 93, 117);
my @members = ("zhou", "ruk", "kra", "tougne", "jinz", "moriss", "acete", "babass", "nano");
my %messages = ();

sub calculate_lvl {
    my ($lvl_att, $px) = @_;
    my $lvl_def = ($px + 2 * $lvl_att - 10) / 3;
    my $result = int($lvl_def);

    my $prefix = $px < 1 ? "<": "";

    say(color('BOLD', "niveau de la cible : $prefix $result"));
}

sub calculate_malus_blessures {
    my ($pv_actuel, $pv_total) = @_;
    my $malus = int(250 * ($pv_total - $pv_actuel) / $pv_total);
    say(color('BOLD', "$malus minutes de malus"));
}

sub calculate_mm {
    my ($rm, $sr) = @_;
    my $mm;
    if ($sr < 50) {
        $mm = int(50 * $rm / $sr);
    } else {
        $mm = int($rm * (100 - $sr) / 50);
    }
    say(color('BOLD', "MM de l'attaquant : $mm"));
}

sub calculate_rm {
    my ($mm, $sr) = @_;
    my $rm;
    if ($sr < 50) {
        $rm = int($mm * $sr / 50);
    } else {
        $rm = int(50 * $mm / (100 - $sr));
    }
    say(color('BOLD', "RM du défenseur : $rm"));
}

sub calculate_px {
    my ($lvl_att, $lvl_def) = @_;
    my $px = (10 + 2 * ($lvl_def - $lvl_att) + $lvl_def);
    my $result = $px > 0 ? int($px) : 0;
    say(color('BOLD', "gain en PX : $result"));
}

sub calculate_sr {
    my ($mm, $rm) = @_;
    my $sr = 0;
    if ($rm >= $mm) {
        $sr = 100 - ($mm / $rm)*50;
    } else {
        $sr = ($rm / $mm)*50;
    }
    my $result = int($sr);
    if ($sr < 10) {
        $result = 10;
    }
    if ($sr > 90) {
        $result = 90;
    }
    say(color('BOLD', "seuil de résistance : $result"));
}

sub calculate_taco {
    # TODO
    my ($nbr_dice_att, $bonus_att, $nbr_dice_def, $bonus_def) = @_;
    return
}

sub call_random {
    my ($call_avg, $nbr_dice, $nbr_facets, $has_bonus, $oper, $bonus) = @_;
    $nbr_dice = $nbr_dice ? $nbr_dice : 1;
    my ($moyenne, $value);
    if ($call_avg) {
        $value = ($nbr_dice * ($nbr_facets + 1))/2;
        $moyenne = "moyenne : ";
    } else {
        $value = 0;
        for (my $i=0; $i < $nbr_dice; $i++) {
            $value += get_random(0, $nbr_facets);
        }
    }
    if ($has_bonus) {
        $bonus =~ tr/,/\./;
        if ($oper eq "+") {
            $value += $bonus;
        } elsif ($oper eq "-") {
            $value -= $bonus;
        } elsif ($oper eq "*") {
            $value *= $bonus;
        } elsif ($oper eq "/") {
            $value /= $bonus;
        }
    }
    say(color('BOLD', "$moyenne$value"));
}

sub color {
    my ($color_name, $text) = @_;
    return $colors{$color_name} . $text . $colors{'NORMAL'};
}

sub display_am {
    my ($fatigue, $total) = @_;
    if ($fatigue) {
        my $nouvelle_fatigue = floor($fatigue/1.25);
        if ($nouvelle_fatigue ~~ @fatigue_values) {
            $total = $total . color('BOLD', " → ") . color('GREEN', $nouvelle_fatigue);
        } else {
            $total = $total . color('BOLD', " → ") . color('RED', $nouvelle_fatigue);
        }
        if ($nouvelle_fatigue > 4) {
            return display_am($nouvelle_fatigue, $total);
        }
        return say($total);
    }
    my $result = "valeurs optimales : ";
    foreach (@fatigue_values) {
        $result.=$_ . " ← ";
    }
    ;
    say(color('BOLD', substr($result, 0, -5)));
}

sub display_urls {
    say_private("Adresse de connexion alternative :");
    say_private(color('UNDERLINED', "http://mh.fr.nf/"));
    say_private("Interface Tactique :");
    say_private(color('UNDERLINED', "http://trolls.ratibus.net/bzh/index.php"));
    say_private("Bestiaire :");
    say_private(color('UNDERLINED', "http://www.mountyhall.com/Forum/display_topic_threads.php?ForumID=17&TopicID=154621&highlight="));
    say_private("À montrer à sa copine :");
    say_private(color('UNDERLINED', "http://www.maceo.fr/tonptithall/"));
    say_private("Localisation des cultures sauvages de champignons (forum MH) :");
    say_private(color('UNDERLINED', "http://www.mountyhall.com/Forum/display_topic_threads.php?ThreadID=2477338#2477338"));
    say_private("Documentation sur les oghams et les runes :");
    say_private(color('UNDERLINED', "http://www.mountyhall.com/Forum/display_topic_threads.php?ThreadID=2484866&highlight=sort%20ogham#2484866"));
}

sub display_help {
    say_private("Commandes disponibles :");
    say_private("!XDY +Z → lance X dés à Y faces (+Z, bonus ou malus facultatif)");
    say_private("!!XDY +Z → moyenne du lancé");
    say_private("!random → équivalent à !1D100");
    say_private("!X MM Y RM → donne le seuil de résistance de la cible (en %)");
    say_private("!X MM Y % → donne la RM de la cible");
    say_private("!X RM Y % → donne la MM de la cible");
    say_private("!px X Y → donne le gain en PX pour le kill d'un lvl Y par un lvl X");
    say_private("!lvl X Y → donne le niveau de la cible pour un kill à Y PX par un lvl X");
    say_private("!pv X/Y → donne le malus de blessures en minutes (X PV restants sur Y PV max)");
    say_private("!X → donne le nom du Trõll numéro X");
    say_private("!troll nom → affiche les infos du Trõll nom[…]");
    say_private("!troll %nom → affiche les infos du Trõll […]nom[…]");
    say_private("!guilde nom → affiche les infos de la guilde nom[…]");
    say_private("!guilde %nom → affiche les infos de la guilde […]nom>[…]");
    say_private("!tr <texte> → Traduit la phrase en langue Trõlle.");
    say_private("!am → donne la liste des valeurs optimales de la fatigue.");
    say_private("!am X → donne la liste des valeurs suivantes de la fatigue jusqu’à 4.");
    say_private("!url → affiche des liens utiles");
    if(lc($chan) ~~ @vip_chans) {
        say_private("!msg <nom> <msg> → laisse un message au joueur <nom> pour sa prochaine connexion");
        say_private("!msg all <msg> → laisse un message à tous les absents");
    }
    update_public_files();
}

sub display_troll_infos {
    my ($search) = @_;
    my $matches = 0;
    my @trolls;
    if ($search =~ /\d{1,6}/) {
        push(@trolls, find_troll($search));
    } else {
        @trolls = find_trolls($search);
    }
    foreach (@trolls) {
        if ($_) {
            $matches++;
            if ($matches > 10) {
                say(color('BOLD', "seuls les 10 premiers résultats sont affichés."));
                return;
            }
            my ($troll_num, $name, $race, $level, $kills, $deaths, $flies, $guilde_num, $rank_num) = split(/;/);
            if ($race eq "Darkling") {
                $race = "Da";
            } else {
                $race = substr($race, 0, 1);
            }
            my $guild_rank = "";
            my $guilde = get_guild_name($guilde_num);
            if ($guilde) {
                $guild_rank .= "- $guilde";
            }
            my $rank = get_rank($guilde_num, $rank_num);
            if ($rank) {
                $guild_rank .= " [ $rank ]";
            }
            say(color('BOLD', "$name ($troll_num), $race$level ($flies Bzz) $guild_rank\n")); # (http://games.mountyhall.com/mountyhall/View/PJView.php?ai_IDPJ=$troll_num)\n");
        } else {
            say (color('BOLD', "$search : aucun résultat."));
        }
    }
}

sub display_guilde_infos {
    my $matches = 0;
    foreach (find_guilds(@_)) {
        $matches++;
        if ($matches > 10) {
            say(color('BOLD', "seuls les 10 premiers résultats sont affichés."));
            return;
        }
        my ($num, $name, $nbre_membres) = split(/;/);
        say(color('BOLD', "$name ($nbre_membres membres)\n")); # (http://games.mountyhall.com/mountyhall/View/AllianceView.php?ai_IDAlliance=$num)\n");
    }
}

sub display_pending_messages {
    if (!%messages) {
        return say(color('BOLD', "Pas de messages."));
    }
    foreach my $key (keys %messages) {
        say(color('BOLD', "Messages pour $key :"));
        foreach (@{$messages{$key}}) {
            say(color('BOLD', " * $_"));
        }
    }
}

sub find_dests {
    my ($nickname) = @_;
    my @dests = ();
    foreach my $key (keys %messages) {
        if ($nickname =~ m/$key/i || $key =~ m/$nickname/i) {
            push(@dests, $key);
        }
    }
    return @dests;
}

sub find_guild {
    my ($num) = @_;
    open(FILE_GUILD, $mh_dir . "Public_Guildes.txt");
    while (<FILE_GUILD>) {
        my $guild_num = split(/;/);
        if ($guild_num eq $num) {
            return $_;
        }
    }
}

sub find_guilds {
    my ($search) = @_;
    my @guilds;
    open(FILE_GUILD, $mh_dir . "Public_Guildes.txt");
    while (<FILE_GUILD>) {
        my ($num, $name) = split(/;/);
        if ($search =~ /([%\*]?)([^%\*]+)([%\*]?)/) {
            if (($1 && $name =~ /$2/i) || $name =~ /^$2/i) {
                push(@guilds, $_);
            }
        }
    }
    return @guilds;
}

sub find_troll {
    my ($num) = @_;
    open(FILE_TROLL, $mh_dir . "Public_Trolls2.txt");
    while (<FILE_TROLL>) {
        my ($troll_num) = split(/;/);
        if ($troll_num eq $num) {
            return $_;
        }
    }
}

sub find_trolls {
    my ($search) = @_;
    my @trolls;
    open(FILE_TROLL, $mh_dir . "Public_Trolls2.txt");
    while (<FILE_TROLL>) {
        my ($num, $name) = split(/;/);
        if ($search =~ /([%\*]?)([^%\*]+)([%\*]?)/) {
            if (($1 && $name =~ /$2/i) || $name =~ /^$2/i) {
                push(@trolls, $_);
            }
        }
    }
    return @trolls;
}

sub get_guild_name {
    my ($guilde_num_param) = @_;
    open(FILE_GUILD, $mh_dir . "Public_Guildes.txt");
    while (<FILE_GUILD>) {
        my ($guilde_num, $guilde_name) = split(/;/);
        if ($guilde_num eq $guilde_num_param) {
            return $guilde_name;
        }
    }
}

sub get_random {
    my ($min, $max) = @_;
    return int(rand($max - $min)) + 1 + $min ;
}

sub get_rank {
    my ($guilde_num_param, $rank_num_param) = @_;
    open(FILE_GUILD_RANK, $mh_dir . "Public_GuildesRangs.txt");
    while (<FILE_GUILD_RANK>) {
        my ($guilde_num, $rank_num, $rank) = split(/;/);
        if ($guilde_num eq $guilde_num_param && $rank_num eq $rank_num_param) {
            return $rank;
        }
    }
}

sub leave_message {
    my ($dest, $msg) = @_;
    my $count=0;
    foreach my $key (keys %messages) {
        foreach (@{ $messages{$key}}) {
            $count++;
        }
    }
    if ($count > 100) {
        return say(color('BOLD', "Trop de messages stockés pour le moment."));
    }

    my @nicks = ();
    foreach ($server->channel_find($chan)->nicks()) {
        push(@nicks, $_->{nick});
    }
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    if (length($min) eq 1) {
        $min = "0$min";
    }
    if ($dest eq "all") {
        foreach my $member (@members) {
            unless (grep(/$member/i, @nicks)){
                push( @{ $messages{ $member } }, "$msg ($nick, à $hour" . "h$min)" );
            }
        }
        say("ok, on leur dira.");
    } else {
        if (grep(/$dest/i, @nicks)) {
            say("dis-lui directement, il est connecté !");
        } else {
            push( @{ $messages{ $dest } }, "$msg ($nick, à $hour" . "h$min)" );
            say("ok, on lui dira.");
        }
    }
}

sub say {
    $server->command("MSG $chan $nick: @_");
}

sub say_private {
    $server->command("MSG $nick @_");
}

sub sig_join {
    my ($_server, $channel, $nickname, $address) = @_;
    if (lc($channel) ~~ @vip_chans) {
        $server = $_server;
        $chan = $channel;
        $nick = $nickname;
        my @dests = find_dests($nick);
        foreach my $dest (@dests) {
            my @list = @{$messages{$dest}} if $dest;
            foreach (@list) {
                say(color('BOLD', $_));
            }
            delete $messages{$dest};
        }
    }
}

sub sig_own_public {
    my ($_server, $msg, $target) = @_;
    if ($msg =~ /^!/) {
        if ($target eq "#testouille") {
            sig_public($_server, $msg, "Duncan", "", $target);
        } else {
            sig_public($_server, $msg, "KTH", "", $target);
        }
    }
}

sub sig_public {
    my ($_server, $msg, $nickname, $address, $target) = @_;
    if(lc($target) ~~ @active_chans) {
        # if (lc($target) eq "#mb3" || lc($target) eq "#testouille" || lc($target) eq "#mountyhall") {
        $chan = $target;
        $server = $_server;
        $nick = $nickname;
        given (lc($msg)) {
            when (/^!(help|aide)/) { display_help() }
            when (/^!url*$/) { display_urls() }
            when (/^!random$/) { call_random('', '', 100) }
            when (/^!(!?)(\d*)d(\d+)(\s*([\+\-\*\/])\s*(\d+([,\.]?\d+)?))?$/) { call_random($1, $2, $3, $4, $5, $6) }
            when (/^!pv\s+(\d+)[\/\s+](\d+)\s*$/) { calculate_malus_blessures($1, $2) }
            when (/^!px\s+(\d+)\s+(\d+)\s*$/) { calculate_px($1, $2) }
            when (/^!lvl\s+(\d+)\s+(\d+)\s*$/) { calculate_lvl($1, $2) }
            when (/^!(\d+)\s*mm\s*(\d+)\s*rm\s*$/) { calculate_sr($1, $2) }
            when (/^!mm\s*(\d+)\s*rm\s*(\d+)\s*$/) { calculate_sr($1, $2) }
            when (/^!(\d*)\s*rm\s*(\d+)\s*mm\s*$/) { calculate_sr($2, $1) }
            when (/^!rm\s*(\d+)\s*mm\s*(\d*)\s*$/) { calculate_sr($2, $1) }
            when (/^!(\d*)\s*mm\s*(\d+)\s*(%|sr)\s*$/) { calculate_rm($1, $2) }
            when (/^!mm\s*(\d+)\s*(%|sr)\s*(\d*)\s*$/) { calculate_rm($1, $2) }
            when (/^!(\d*)\s*(%|sr)\s*(\d+)\s*mm\s*$/) { calculate_rm($3, $1) }
            when (/^!(%|sr)\s*(\d+)\s*mm\s*(\d*)\s*$/) { calculate_rm($3, $1) }
            when (/^!(\d*)\s*rm\s*(\d+)\s*(%|sr)\s*$/) { calculate_mm($1, $2) }
            when (/^!rm\s*(\d+)\s*(%|sr)\s*(\d*)\s*$/) { calculate_mm($1, $2) }
            when (/^!(\d*)\s*(%|sr)\s*(\d+)\s*rm\s*$/) { calculate_mm($3, $1) }
            when (/^!(%|sr)\s*(\d+)\s*rm\s*(\d*)\s*$/) { calculate_mm($3, $1) }
            when (/^!(\d{1,6})$/) { display_troll_infos($1) }
            when (/^!troll\s(.+)$/) {display_troll_infos($1) }
            when (/^!guilde?(\s)+(.+)$/) { display_guilde_infos($2) }
            when (/^!tr\s+(.+)$/) { translate($1) }
            when (/^!am(\s+(\d+)\s*)?$/) { display_am($2) }
            when (/^!msg\s+(\S+)\s+(.+)$/) { leave_message($1, $2) }
            when (/^!msg\s?liste?\s*$/) { display_pending_messages() }
            when (/^!update/) {
                if ($nick eq "KTH" || $nick eq "Duncan" || $nick eq "Krooh_Tong_Halai") {
                    update_public_files();
                    say(color('BOLD', "fichiers mis à jour."));
                }
            }
            default { }
        }
    }
}

sub translate {
    my ($s) = @_;
    $s =~ tr/a/\x{00E0}/;
    $s =~ tr/e/\x{00E9}/;
    $s =~ tr/i/\x{00EF}/;
    $s =~ tr/o/\x{00F5}/;
    $s =~ tr/u/\x{00FB}/;
    $s =~ s/y/\x{00B0}y\x{00B0}/;
    $s =~ tr/A/\x{00C0}/;
    $s =~ tr/E/\x{00C9}/;
    $s =~ tr/I/\x{00CF}/;
    $s =~ tr/O/\x{00D5}/;
    $s =~ tr/U/\x{00DB}/;
    $s =~ s/Y/\x{00B0}Y\x{00B0}/;
    say("$s");
}

sub update_public_files {
    `wget -nd -q "ftp://ftp.mountyhall.com/Public_Trolls2.txt"; mv Public_Trolls2.txt $mh_dir`;
    `wget -nd -q "ftp://ftp.mountyhall.com/Public_Guildes.txt"; mv Public_Guildes.txt $mh_dir`;
    `wget -nd -q "ftp://ftp.mountyhall.com/Public_GuildesRangs.txt"; mv Public_GuildesRangs.txt $mh_dir`;
    `wget -nd -q "ftp://ftp.mountyhall.com/Public_Equipement.txt"; mv Public_Equipement.txt $mh_dir`;
}

Irssi::signal_add("message public", "sig_public");
Irssi::signal_add("message own_public", "sig_own_public");
Irssi::signal_add("message join", "sig_join");
