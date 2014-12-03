#!/usr/bin/perl -w
#
# msgconvert:
# Convert .MSG files (made by Outlook (Express)) to multipart MIME messages.
#
# Requires these Debian packages to work:
#
#   sudo apt-get install libemail-outlook-message-perl libemail-sender-perl
#
use Email::Outlook::Message;

my $infile = $ARGV[0];
my $outfile = $ARGV[1];
my $msg = new Email::Outlook::Message($infile, '');
my $mail = $msg->to_email_mime;
open OUT, ">:utf8", $outfile or die "Can't open $outfile for writing: $!";
binmode(OUT, ":utf8");
print OUT $mail->as_string;
close OUT;

exit 0;
