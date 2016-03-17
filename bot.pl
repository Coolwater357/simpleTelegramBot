#!/usr/local/bin/perl
use warnings;
use strict;
require 5.020;
BEGIN
{
  use constant TRUE    => 1;
  use constant FALSE   => 0;
  use constant DEBUG   => 'DEBUG:   ';
}
use feature qw( say signatures );
no warnings "experimental::signatures";
#add missing Perl modules with sudo cpan ModuleName e.g. cpan JSON::Parse
use File::Basename;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use WWW::Mechanize;
use JSON::Parse 'parse_json';

my $debug = FALSE;
GetOptions(
'debug!' => \$debug,
'help'   => \&printUsage,
) || printUsage();

my $telegramToken = '123456789:ABCDEFGhijklmNOP2435HkT45fcssdsaaAA'; ## set to a valid token
my $telegramUrl = "https://api.telegram.org/bot$telegramToken";
say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> telegramUrl=$telegramUrl" if ($debug);
my $telegramOffset = ''; # offset for getting updates
my $telegramTimeout = 10; # seconds of timeout
my $loopSleepTime = 10; # seconds between checks to server

while (TRUE)
{
    say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> telegramOffset = $telegramOffset" if ($debug);
    my $request = WWW::Mechanize->new();
    my $updates = $request->get("$telegramUrl/getUpdates?timeout=$telegramTimeout&offset=$telegramOffset");
    if ($updates->is_success)
    {
        my $response = $request->response();
        parse($response);
    }
    else
    {
        warn $updates->status_line;
    }

    say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> sleeping for $loopSleepTime seconds..."  if ($debug);
    sleep $loopSleepTime;
}

sub parse($res)
{
    say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> code=".$res->code." content=".$res->content if ($debug);
    my $json = parse_json($res->content);
    if (ref($json) eq "HASH")
    {
        my %json = %$json;
        if ($debug)
        {
            foreach my $item (sort keys %json)
            {
                say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> key=$item value=$json{$item}";
            }
        }
        my $result = $json{'result'};
        my @results = @$result;
        foreach my $result (@results)
        {
            my %results = %{$result};
            if ($debug)
            {
                foreach my $key (keys %results)
                {
                    say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> result key=$key value=$results{$key}";
                }
            }
            $telegramOffset = $results{'update_id'};
            $telegramOffset++;

            my %message = %{$results{'message'}};
            if ($debug)
            {
                foreach my $key (keys %message)
                {
                    say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> message key=$key value=$message{$key}";
                }
            }
            my $messageText = $message{'text'};

            my %chat = %{$message{'chat'}};
            if ($debug)
            {
                foreach my $key (keys %chat)
                {
                    say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> chat key=$key value=$chat{$key}";
                }
            }
            my $firstName = $chat{'first_name'};
            my $chatId = $chat{'id'};
            respond($chatId, $messageText, $firstName, $debug);
        }
    }
}

sub respond($chatId, $messageText, $firstName, $debug=FALSE)
{
    say STDERR DEBUG.basename(__FILE__).":".__LINE__."=> messageText=$messageText" if ($debug);

    my $reply = "Hello $firstName you sent: $messageText";
    my $request = WWW::Mechanize->new();
    my $update = $request->get("$telegramUrl/sendMessage?parse_mode=Markdown&chat_id=$chatId&text=$reply");
    unless ($update->is_success)
    {
        warn $update->status_line;
    }
}

__END__

=pod

=head1 NAME

bot.pl - simple Telegram bot to start learning with

=head1 SYNOPSIS

bot.pl [options]

=head1 OPTIONS

 Note: Options are case-insensitive and can be shortened as long they remain unique.

 -debug
  Programmer option

 -help
  Print this and exit

=cut

